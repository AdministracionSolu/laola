#!/bin/bash
# ============================================================================
# verificar-realidad.sh — ¿lo que está escrito sigue siendo cierto?
# ============================================================================
# En La Ola, Lovable NO aplica las migraciones: se le pasan a Diego en bloques
# para que las corra a mano en el SQL Editor. Un archivo `.sql` commiteado aquí
# **no prueba nada** — puede llevar semanas en el repo sin existir en la base, y
# desde el código se ve idéntico. Este script es el que nota la diferencia.
#
# No hay Management API para este proyecto (la cuenta no tiene privilegios), así
# que se le pregunta a PostgREST, que contesta 404 cuando una tabla no existe y
# 400 cuando una columna no existe. Eso sí es fiable.
#
# Lo que NO se puede verificar así: si una FUNCIÓN existe. PostgREST responde
# exactamente el mismo 404 para una función ausente y para una que existe con
# otros argumentos, así que preguntarlo sólo daría falsas alarmas. Para las
# funciones hace falta SQL, y para eso hace falta Diego.
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
codigo() { curl -s -o /dev/null -m 25 -w "%{http_code}" "$URL/rest/v1/$1" -H "apikey: $ANON"; }

echo "La Ola · verificación de realidad · $(date '+%Y-%m-%d %H:%M')"

# ---------------------------------------------------------------------------
tema "1. La base responde"
if [ "$(codigo 'sucursales?select=id&limit=1')" = "200" ]; then ok "PostgREST contesta"
else mal "no pude hablarle a la base ($URL)"; fi

# ---------------------------------------------------------------------------
tema "2. Las tablas y columnas de las últimas migraciones existen"
pendientes=0
for archivo in $(ls "$REPO/supabase/migrations"/*.sql 2>/dev/null | tail -10); do
  faltan=""
  for tb in $(grep -oiE "CREATE TABLE (IF NOT EXISTS )?(public\.)?[a-z_0-9]+" "$archivo" | tr 'A-Z' 'a-z' | sed -E 's/.*(exists |table )(public\.)?//' | sort -u); do
    [ "$(codigo "$tb?select=*&limit=1")" = "404" ] && faltan="$faltan tabla:$tb"
  done
  # ALTER TABLE x ADD COLUMN y  →  se pregunta por la columna en su tabla
  while read -r tabla columna; do
    [ -z "$tabla" ] && continue
    [ "$(codigo "$tabla?select=$columna&limit=1")" = "400" ] && faltan="$faltan $tabla.$columna"
  done < <(grep -oiE "ALTER TABLE (IF EXISTS )?(public\.)?[a-z_0-9]+[[:space:]]+ADD COLUMN (IF NOT EXISTS )?[a-z_0-9]+" "$archivo" \
           | tr 'A-Z' 'a-z' | sed -E 's/alter table (if exists )?(public\.)?//; s/[[:space:]]+add column (if not exists )?/ /' | sort -u)
  [ -n "$faltan" ] && { mal "$(basename "$archivo") NO está aplicada — falta:$faltan"; pendientes=$((pendientes+1)); }
done
if [ "$pendientes" = "0" ]; then
  ok "las últimas 10 migraciones están aplicadas"
else
  printf "      → se le pasan a Diego en bloques para el SQL Editor; el archivo solo no sirve\n"
fi

# ---------------------------------------------------------------------------
tema "3. El anónimo sólo ve lo que debe"
# El menú público y la liga del proveedor están abiertos a propósito. Lo demás
# es operación interna y no tiene por qué asomarse.
for tabla in pedidos pedidos_detalle cortes_caja recepciones colaboradores reservaciones proveedor_productos; do
  c=$(codigo "$tabla?select=*&limit=1")
  case "$c" in
    404) printf "      → %s: no existe\n" "$tabla" ;;
    200) filas=$(curl -s -m 25 "$URL/rest/v1/$tabla?select=*&limit=1" -H "apikey: $ANON" | head -c 3)
         if [ "$filas" = "[]" ]; then ok "$tabla: el anónimo no ve filas"
         else mal "$tabla: el ANÓNIMO PUEDE LEERLA"; fi ;;
    *)   ok "$tabla: cerrada al anónimo ($c)" ;;
  esac
done

# ---------------------------------------------------------------------------
echo
[ $HALLAZGOS -eq 0 ] && printf "%sTodo cuadra.%s\n" "$V" "$F" || printf "%s%s cosa(s) que revisar.%s\n" "$R" "$HALLAZGOS" "$F"
exit $(( HALLAZGOS > 0 ? 1 : 0 ))
