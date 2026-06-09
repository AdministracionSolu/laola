# Pedidos en línea (cliente final) — laola.mx

Módulo de pedidos web para clientes finales: **recoger en sucursal** o **reparto propio**,
pago **únicamente contra entrega** (efectivo o terminal física). Independiente del sistema
interno de pedidos a proveedores (`pedidos` / `pedidos_detalle`, que no se tocaron).

## Mapa del módulo

| Pieza | Ruta |
|---|---|
| SQL consolidado (pegar en SQL Editor) | `db/pedidos-en-linea-consolidado.sql` |
| Migraciones individuales | `supabase/migrations/20260609120000…120200_*.sql` |
| Menú fuente (CSV) | `db/seed/menu_seed.csv` |
| SQL del menú (generado) | `db/seed/menu_seed.sql` |
| Script de seed | `scripts/seed-menu.ts` |
| Cliente (público) | `/ordenar`, `/ordenar/:slugSucursal`, `/pedido/:token` |
| Panel staff | `/pedidos-en-linea` (dentro del gate de sucursal de `/pedidos`) |
| Código cliente | `src/pages/Ordenar.tsx`, `src/pages/SeguimientoPedido.tsx`, `src/components/pedidos-en-linea/` |
| Código panel | `src/pages/PanelPedidosEnLinea.tsx`, `src/components/panel-pedidos-en-linea/` |
| Lógica compartida | `src/lib/pedidosEnLinea.ts`, `src/hooks/useCarrito.ts`, `src/hooks/useMenuEnLinea.ts`, `src/hooks/useAlertaNuevoPedido.ts` |

## 1. Cómo aplicar el SQL (Lovable / Supabase)

Las migraciones de este repo **no se aplican solas** (proyecto gestionado por Lovable).
Camino recomendado:

1. Abre el proyecto en Lovable → backend (Supabase) → **SQL Editor**.
2. Pega el contenido completo de **`db/pedidos-en-linea-consolidado.sql`** y ejecútalo.
   - Es **idempotente**: si algo falla a la mitad, corrígelo y vuelve a correr el archivo completo.
   - Incluye: tablas + RLS + realtime + RPCs + configuración de sucursales + horarios/zonas
     placeholder + **todo el menú con precios por sucursal** (220 items, 298 variantes, 912 precios).
3. Pide a Lovable regenerar `src/integrations/supabase/types.ts` (o corre
   `supabase gen types`). No es bloqueante: el front usa un cliente tipado a mano mientras tanto.

Alternativa por partes: correr las 3 migraciones de `supabase/migrations/` en orden y
después `db/seed/menu_seed.sql`.

## 2. Cómo correr el seed del menú (alternativa al SQL)

Si prefieres sembrar el menú vía API (mismo resultado que `menu_seed.sql`):

```bash
SUPABASE_URL="https://<proyecto>.supabase.co" \
SUPABASE_SERVICE_ROLE_KEY="<service-role-key>" \
npx tsx scripts/seed-menu.ts
```

- La service key va **solo por variable de entorno** (nunca en el repo).
- Idempotente: correrlo dos veces no duplica (upsert por nombre de categoría/item/variante).
- El upsert de precios **no toca `disponible`**: no pisa los "agotados" que haya marcado el staff.
- ¿Cambió el CSV? Regenera el SQL con `node --experimental-strip-types scripts/seed-menu.ts --sql`
  (o `npx tsx scripts/seed-menu.ts --sql`) y reconstruye el consolidado si lo usas.

## 3. Acceso del panel de staff

El panel `/pedidos-en-linea` vive dentro del flujo interno (`/pedidos` → PIN de sucursal) y
**además requiere sesión de Supabase** (correo + contraseña, se recuerda en el dispositivo).
Razón: las tablas de pedidos contienen datos de clientes (teléfono, dirección) y su RLS solo
permite acceso al rol `authenticated`; el PIN por dispositivo no protege la API.

- Sirve cualquier usuario de Supabase Auth (por ejemplo el de admin ya existente), o crea
  un usuario `staff@laola.mx` en Supabase → Authentication → Users.
- **PENDIENTE documentado:** el sistema interno no asigna usuario→sucursal (solo PIN por
  dispositivo), así que cualquier usuario autenticado puede ver/operar todas las sucursales.
  El panel filtra por la sucursal elegida en el dispositivo. Si más adelante se quiere
  aislamiento real por sucursal, hay que crear una tabla `usuario_sucursal` y endurecer las
  políticas RLS `staff_*`.

## 4. Ciclo de estados del pedido

```
                 ┌────────────────────────── cancelado (requiere motivo) ◄─────────┐
                 │            ▲                  ▲                ▲                 │
  cliente        │            │                  │                │                 │
  ordena ──► nuevo ──► confirmado ──► preparando ──► listo ──┬──► en_reparto ──► entregado
  (RPC)                                                      │     (solo reparto)
                                                             └──► entregado (recoger)
```

- `nuevo → confirmado → preparando → listo` aplica a ambos tipos.
- `recoger`: `listo → entregado`. `reparto`: `listo → en_reparto → entregado`.
- Cualquier estado no final puede pasar a `cancelado` con motivo
  ('Cliente no localizable', 'Sin insumos', 'Fuera de zona', 'Otro').
- Trigger en DB: pone `confirmado_at` / `listo_at` / `entregado_at` + `updated_at`, y al
  entrar a `confirmado` / `listo` / `en_reparto` inserta una fila en `notificaciones_pedido`
  (fase 2: un worker externo con Evolution API las consumirá para WhatsApp; este build solo
  las escribe).

## 5. Seguridad (resumen)

- El cliente **jamás manda precios**: `crear_pedido_en_linea` (SECURITY DEFINER) recalcula
  todo con precios de DB, valida sucursal activa/horario/pausa, disponibilidad por item,
  alcohol, teléfono (normaliza +52 → 10 dígitos), zona + pedido mínimo, y limita a
  **3 pedidos por teléfono por hora**.
- Folio `VAL-001…` por día y sucursal vía `folios_secuencia` con upsert atómico (no MAX+1);
  la fecha del folio usa la **zona horaria de la sucursal** (Tepic = America/Mazatlan,
  Zapopan = America/Mexico_City — columna nueva `sucursales.zona_horaria`).
- `anon`: SELECT solo en catálogo/zonas activas/horarios; **cero acceso directo** a
  `pedidos_en_linea*` (solo las RPCs `crear_pedido_en_linea` y `obtener_pedido_por_token`).
  Nota: `menu_variante_sucursal` expone también filas `disponible=false` (sin datos sensibles)
  para poder marcar "agotado" en el carrito del cliente.
- `authenticated` (staff): acceso completo a pedidos y catálogo + UPDATE en `sucursales`
  (toggles operativos).
- Realtime habilitado en `pedidos_en_linea` (panel staff). La página pública de seguimiento
  usa **polling cada 10 s** vía RPC (anon no puede suscribirse a la tabla por RLS — decisión
  deliberada para no exponer pedidos de otros clientes).

## 6. Checklist de salida a producción

- [ ] Aplicar `db/pedidos-en-linea-consolidado.sql` en el SQL Editor.
- [ ] **Validar los precios del CSV** con el dueño (en particular las notas `VALIDAR` del CSV:
      Empanada La Ola en Solares, Mini pastel de brownie en Brisas, Agua fresca en Brisas,
      Zarandeados fuera de Del Valle). Las notas `VALIDAR` no se muestran al cliente
      (el seed las recorta de la descripción).
- [ ] Capturar **zonas de reparto reales** por sucursal (panel → Configuración → Zonas).
      Las 2 'ZONA PENDIENTE' del seed están inactivas; edítalas o bórralas.
- [ ] Capturar **horarios reales** (el seed deja 11:00–21:00 todos los días).
- [ ] Capturar **teléfono de contacto** por sucursal (`sucursales.telefono_contacto`) — se usa
      en tarjetas, fallbacks de error y página de seguimiento. Hoy está vacío (la UI lo oculta).
- [ ] Crear/confirmar usuario de Supabase Auth para el staff e iniciar sesión en las tablets.
- [ ] Probar un pedido de punta a punta por sucursal (sonido del panel incluido: el navegador
      necesita una interacción previa para reproducir audio).
- [ ] Activar el **toggle "Recibir pedidos en línea"** por sucursal (panel → Configuración).
      Todo nace apagado: nadie puede ordenar hasta este paso.
- [ ] Alcohol: dejar `venta_alcohol_en_linea` apagado hasta confirmar permisos por municipio.
- [ ] Cuando Lovable regenere `types.ts`, opcionalmente migrar `src/lib/pedidosEnLinea.ts`
      al cliente tipado oficial.

## 7. Decisiones y colisiones documentadas

- **`db/` no existía**: el snapshot real está en `supabase/SCHEMA_SNAPSHOT.sql`; se leyó ese.
  Se creó `db/` para el seed y el consolidado, como pedía la especificación.
- **Nombres de sucursales** en DB: `Del Valle`, `Las Brisas`, `Cervecería`, `Solares`
  (verificados contra el snapshot). Prefijos: VAL, BRI, CER, SOL. Slugs públicos:
  `del-valle`, `las-brisas`, `cerveceria`, `solares`.
- **Sin colisión de tablas**: el sistema interno usa `pedidos`/`pedidos_detalle`; este módulo
  usa `pedidos_en_linea`/`pedidos_en_linea_items` y catálogo `menu_*` propio (los insumos
  internos viven en `insumos`/`insumo_sucursal`).
- **Zona horaria por sucursal**: Solares (Zapopan) va una hora adelante de Tepic; el horario
  y el folio diario se calculan con `sucursales.zona_horaria` tanto en la RPC como en el front.
- **Descripciones "Marisa"** (Pastel red velvet / Gelatina de cajeta en Solares) vienen así
  del CSV; se muestran tal cual. Editar en `menu_items.descripcion` si no se desea.
- **Carrito por sucursal**: vive en localStorage ligado a la sucursal; cambiar de sucursal
  pide confirmación y lo vacía (los precios difieren).
- **Tipos de Supabase**: `types.ts` es generado por Lovable y aún no conoce las tablas nuevas;
  `src/lib/pedidosEnLinea.ts` expone un cliente con tipos manuales para no tocar ese archivo.

## 8. Criterios de aceptación — estado

El SQL no se pudo ejecutar desde este entorno (no hay acceso directo a la base del proyecto;
restricción conocida de Lovable). Lo verificable en código/build quedó verificado; lo que
depende de la base queda garantizado por diseño y debe confirmarse al aplicar el SQL:

1. Flujo completo Valle (ceviche grande + tostadas, reparto) → implementado de punta a punta
   (menú → carrito → checkout → RPC → `/pedido/:token`). ✔ código / ⏳ probar con DB
2. Precios distintos por sucursal → siempre de `menu_variante_sucursal`; el seed tiene
   Ceviche de camarón Grande 400g = $398 (Valle) y Mediano 300g = $312 (Solares). ✔
3. Item sin precio en una sucursal no aparece en su menú (sin fila = no existe). ✔
4. INSERT directo como `anon` a `pedidos_en_linea` → sin política, RLS lo rechaza. ✔
5. Precio manipulado desde el cliente → el cliente ni siquiera manda precios; la RPC los lee
   de DB. ✔
6. Panel recibe en <2 s vía Realtime + suena (publication + suscripción filtrada + Web Audio
   + título parpadeante; respaldo de refetch cada 30 s). ✔ código / ⏳ probar con DB
7. "Agotado" quita el item del menú público (filtro `disponible` + refetch 60 s; la RPC lo
   rechaza al instante aunque el cliente tenga el carrito abierto, y el carrito lo marca). ✔
8. Pausa bloquea pedidos con mensaje claro y se reactiva sola (validación server-side por
   timestamp; sin cron necesario). ✔
9. Cuarto pedido del mismo teléfono en una hora → `LIMITE_PEDIDOS`. ✔
10. `npm run build` pasa limpio; `tsc --noEmit` pasa; eslint sin errores en los archivos
    nuevos (los avisos restantes del repo son preexistentes). ✔
