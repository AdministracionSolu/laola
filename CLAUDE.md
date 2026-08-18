# La Ola — reglas del repo

Restaurante de mariscos, varias sucursales. Repo de Lovable: el push a `main`
sincroniza el frontend, **nada más**.

## Antes de tocar nada

```sh
bash scripts/verificar-realidad.sh          # sólo este proyecto
bash ~/bin/verificar-todo.sh                # la ronda por todos
```

La ronda completa corre sola cada mañana y deja el reporte en
`~/verificaciones/ultima.txt`.

## Migraciones (IMPORTANTE)

Lovable **NO** aplica las migraciones automáticamente en este repo. Por eso,
siempre que escriba una migración:

1. La divido en **bloques pequeños e independientes** (una tabla / un ALTER / un
   bucket / una policy / una función por bloque), en orden de ejecución.
2. Se los **paso a Diego en el chat** para que él los corra a mano en el SQL
   Editor de Supabase. No basta con dejar el archivo `.sql` en el repo.
3. El archivo `.sql` en `supabase/migrations/` queda igual como registro, pero la
   fuente de verdad para aplicarla es lo que le paso en el chat.

**Y por eso hay que verificar, no suponer.** Al 18-ago-2026 había dos
migraciones commiteadas que nunca se aplicaron: `20260811120000_horarios_archivos`
y el puente POS de Soft Restaurant completo (`20260815120000`, seis tablas). El
verificador las encontró preguntándole a la base; desde el repo se veían
idénticas a las aplicadas.

## Lo que no se puede verificar solo

No hay Management API para este proyecto: la cuenta no tiene privilegios sobre
`ctoeckcgrqihsxjefmwg`. Se le pregunta a PostgREST, que sí distingue **tablas**
(404 si no existe) y **columnas** (400), pero **no funciones**: responde el mismo
404 para una función ausente que para una que existe con otros argumentos. Para
las funciones hace falta SQL, y para eso hace falta Diego.

## Cuidado con la llave anónima

Las pantallas de `/centro-de-operaciones/*` las usa el personal **con la llave
anónima**, sin sesión. Eso las hace cómodas y también deja abiertas las tablas
que leen: al 18-ago un anónimo podía listar `reservaciones` completa —272 filas
con `nombre_cliente` y `telefono`—, además de `pedidos`, `pedidos_detalle` y
`recepciones`.

Cerrarlo **no es un REVOKE**: rompería la operación del día. El patrón correcto
ya existe en este mismo repo — Compras y el Checador validan un PIN y entran por
RPC (`compras_validar_pin`, `checar_pin`, `impl_validar_pin`). Migrar esas
pantallas a ese patrón es el trabajo pendiente.

## Otras cosas que se pagaron caro

- **El día rueda a las 4 AM**: `cortes_caja.fecha_venta` la pone un trigger. Un
  corte de la madrugada pertenece al día anterior.
- **Nunca `length === 10` sobre el teléfono crudo** para decidir si es válido:
  hay tres archivos espejo con la normalización y hay que tocarlos juntos.
- **Dos líneas de WhatsApp**: proveedores (la vieja) y lealtad. La de lealtad se
  quemó por mandar un primer mensaje en frío — de ahí salió el goteo.
