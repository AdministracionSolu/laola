#!/bin/bash
# ============================================================================
# verificar-realidad.sh — ¿lo que está escrito sigue siendo cierto?
# ============================================================================
# En La Ola, Lovable NO aplica las migraciones: se le pasan a Diego en bloques
# para que las corra a mano en el SQL Editor. Eso significa que un archivo
# `.sql` commiteado aquí **no prueba absolutamente nada**: puede llevar semanas
# en el repo sin que exista en la base, y desde el código se ve idéntico.
#
# Como tampoco hay Management API para este proyecto, el script no pregunta por
# information_schema: le pregunta a PostgREST, que contesta 404 cuando una tabla
# o una función no existe. Entra como el admin del panel, que es un usuario real
# de GoTrue, porque casi todas las policies son `TO authenticated`.
#
#     bash scripts/verificar-realidad.sh
#
# Sale 0 si todo cuadra, 1 si hay algo que revisar.
# ============================================================================
set -uo pipefail

REPO=$(cd "$(dirname "$0")/.." && pwd)
HALLAZGOS=0

if [ -t 1 ]; then V=$'\033[32m'; R=$'\033[31m'; B=$'\033[1m'; F=$'\033[0m'; else V=""; R=""; B=""; F=""; fi
ok()   { printf "  %s✓%s %s\n" "$V" "$F" "$1"; }
mal()  { printf "  %s✗%s %s\n" "$R" "$F" "$1"; HALLAZGOS=$((HALLAZGOS+1)); }
tema() { printf "\n%s%s%s\n" "$B" "$1" "$F"; }

URL=$(grep VITE_SUPABASE_URL "$REPO/.env" | cut -d'"' -f2)
ANON=$(grep VITE_SUPABASE_PUBLISHABLE_KEY "$REPO/.env" | cut -d'"' -f2)
# Las credenciales del admin viven en el propio login del panel: el PIN sólo
# dispara este signInWithPassword.
EMAIL=$(grep -oE 'ADMIN_EMAIL *= *"[^"]+"' "$REPO/src/pages/admin/Login.tsx" 2>/dev/null | cut -d'"' -f2)
PASS=$(grep -oE 'ADMIN_PASSWORD *= *"[^"]+"' "$REPO/src/pages/admin/Login.tsx" 2>/dev/null | cut -d'"' -f2)

echo "La Ola · verificación de realidad · $(date '+%Y-%m-%d %H:%M')"

# ---------------------------------------------------------------------------
tema "1. Se puede entrar como el panel"
TOKEN=$(curl -s -m 25 -X POST "$URL/auth/v1/token?grant_type=password" \
  -H "apikey: $ANON" -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASS\"}" \
  | python3 -c "import sys,json; print(json.load(sys.stdin).get('access_token',''))" 2>/dev/null)
if [ -n "$TOKEN" ]; then ok "sesión de $EMAIL abierta"
else mal "no pude entrar como $EMAIL — ¿cambió la contraseña del panel?"; TOKEN="$ANON"; fi

get()  { curl -s -o /dev/null -m 25 -w "%{http_code}" "$URL/rest/v1/$1" -H "apikey: $ANON" -H "Authorization: Bearer $TOKEN"; }
body() { curl -s -m 25 "$URL/rest/v1/$1" -H "apikey: $ANON" -H "Authorization: Bearer $TOKEN"; }
cuenta() { curl -s -m 25 -I "$URL/rest/v1/$1" -H "apikey: $ANON" -H "Authorization: Bearer $TOKEN" \
             -H "Prefer: count=exact" -H "Range: 0-0" | grep -i content-range | sed 's|.*/||' | tr -d '\r'; }

# ---------------------------------------------------------------------------
tema "2. Lo que crean las últimas migraciones existe de verdad"
pendientes=0
for archivo in $(ls "$REPO/supabase/migrations"/*.sql 2>/dev/null | tail -8); do
  faltan=""
  for tb in $(grep -oiE "CREATE TABLE (IF NOT EXISTS )?(public\.)?[a-z_0-9]+" "$archivo" | tr 'A-Z' 'a-z' | sed -E 's/.*(exists |table )(public\.)?//' | sort -u); do
    [ "$(get "$tb?select=*&limit=1")" = "404" ] && faltan="$faltan tabla:$tb"
  done
  for fn in $(grep -oiE "CREATE (OR REPLACE )?FUNCTION (public\.)?[a-z_0-9]+" "$archivo" | tr 'A-Z' 'a-z' | sed -E 's/.*function (public\.)?//' | sort -u); do
    codigo=$(curl -s -o /dev/null -m 25 -w "%{http_code}" -X POST "$URL/rest/v1/rpc/$fn" \
      -H "apikey: $ANON" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d '{}')
    [ "$codigo" = "404" ] && faltan="$faltan fn:$fn"
  done
  [ -n "$faltan" ] && { mal "$(basename "$archivo") NO está aplicada — falta:$faltan"; pendientes=$((pendientes+1)); }
done
[ "$pendientes" = "0" ] && ok "las últimas 8 migraciones están aplicadas"

# ---------------------------------------------------------------------------
tema "3. Lo que el panel llama sigue existiendo"
# Una función que se borra o se renombra no rompe el build: rompe la pantalla.
faltantes=""
for fn in $(grep -rhoE "rpc\(\"[a-z_]+\"|rpc\('[a-z_]+'" "$REPO/src" | sed -E "s/rpc\(['\"]//" | sort -u); do
  codigo=$(curl -s -o /dev/null -m 25 -w "%{http_code}" -X POST "$URL/rest/v1/rpc/$fn" \
    -H "apikey: $ANON" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d '{}')
  [ "$codigo" = "404" ] && faltantes="$faltantes $fn"
done
[ -z "$faltantes" ] && ok "todas las funciones que llama el panel existen" \
                    || mal "el panel llama funciones que no existen:$faltantes"

# ---------------------------------------------------------------------------
tema "4. La operación del día"
hoy=$(date -u +%Y-%m-%d)
cortes=$(cuenta "cortes_caja?select=id&fecha_venta=eq.$hoy")
printf "      → cortes de caja de hoy: %s\n" "${cortes:-?}"
pedidos=$(cuenta "pedidos?select=id&created_at=gte.${hoy}T00:00:00")
printf "      → pedidos en línea de hoy: %s\n" "${pedidos:-?}"

# ---------------------------------------------------------------------------
tema "5. El anónimo sólo ve lo que debe"
# El barrido de agosto cerró las tablas de operación al anónimo; el menú público
# y la liga de proveedor siguen abiertos a propósito.
for tabla in cortes_caja pedidos proveedor_productos; do
  codigo=$(curl -s -o /dev/null -m 25 -w "%{http_code}" "$URL/rest/v1/$tabla?select=*&limit=1" -H "apikey: $ANON")
  if [ "$codigo" = "200" ]; then
    filas=$(curl -s -m 25 "$URL/rest/v1/$tabla?select=*&limit=1" -H "apikey: $ANON" | head -c 3)
    [ "$filas" = "[]" ] && ok "$tabla: el anónimo no ve filas" || mal "$tabla: el ANÓNIMO PUEDE LEERLA"
  else
    ok "$tabla: cerrada al anónimo ($codigo)"
  fi
done

# ---------------------------------------------------------------------------
echo
[ $HALLAZGOS -eq 0 ] && printf "%sTodo cuadra.%s\n" "$V" "$F" || printf "%s%s cosa(s) que revisar.%s\n" "$R" "$HALLAZGOS" "$F"
exit $(( HALLAZGOS > 0 ? 1 : 0 ))
