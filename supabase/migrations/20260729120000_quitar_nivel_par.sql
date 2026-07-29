-- Quitar "nivel par": la operación no lo usa (conciliado con sucursal jul-2026).
-- El pedido lo captura el encargado a mano; ya no hay pedido sugerido por par.
-- NOTA: correr a mano en el SQL Editor (Lovable no aplica migraciones en este repo).

-- Bloque 1: tirar la columna
ALTER TABLE public.insumo_sucursal DROP COLUMN IF EXISTS nivel_par;

-- Bloque 2 (opcional, higiene): alinear unidades del catálogo con la lista
-- conciliada. El front ya manda con la unidad canónica de proteinas.ts, así
-- que esto solo deja la base pareja.
UPDATE public.insumos SET unidad = 'bolsa'
WHERE nombre ILIKE 'ALITAS%' OR nombre ILIKE 'BONELESS%'
   OR nombre ILIKE '%OSTION%' OR nombre ILIKE '%OSTIÓN%';

UPDATE public.insumos SET unidad = 'pz'
WHERE nombre ILIKE '%MEDALLON%' OR nombre ILIKE '%MEDALLÓN%'
   OR nombre ILIKE 'PIZZAS%' OR nombre ILIKE '%SARANDEAR%';
