# La Ola — reglas del repo

## Migraciones (IMPORTANTE)
Lovable **NO** aplica las migraciones automáticamente en este repo. Por eso, siempre que escriba una migración:

1. La divido en **bloques pequeños e independientes** (una tabla / un ALTER / un bucket / una policy / una función por bloque), en orden de ejecución.
2. Se los **paso a Diego en el chat** para que él los corra a mano en el SQL Editor de Supabase. No basta con dejar el archivo `.sql` en el repo.
3. El archivo `.sql` en `supabase/migrations/` queda igual como registro, pero la fuente de verdad para aplicarla es lo que le paso en el chat.
