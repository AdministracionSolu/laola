-- =====================================================================
-- Pizzas y bolsas de ostión se cuentan por pieza, no por kilo.
--
-- Las dos estaban en kg en las cuatro sucursales. La prueba de que no lo
-- son: en toda la historia capturada NO hay un solo decimal en ninguna de
-- las dos, ni en existencias ni en recepciones — nadie tiene 2.5 pizzas
-- ni recibe 3.5 bolsas. Con kg los botones + y - brincan de medio en
-- medio, que para esto no significa nada.
--
-- El ostión queda en 'bolsa' y no en 'pz' porque el insumo se llama
-- literalmente "BOLSAS OSTIÓN": lo que se cuenta son bolsas. Es un valor
-- que ya existe (Las Brisas lo usa en alitas).
-- =====================================================================

UPDATE public.insumo_sucursal
SET unidad = 'pz'
WHERE insumo_id = (SELECT id FROM public.insumos WHERE nombre = 'PIZZAS');

UPDATE public.insumo_sucursal
SET unidad = 'bolsa'
WHERE insumo_id = (SELECT id FROM public.insumos WHERE nombre = 'BOLSAS OSTIÓN');

-- Comprobación: 4 renglones 'pz' y 4 'bolsa'.
-- SELECT i.nombre, s.nombre AS sucursal, isu.unidad
-- FROM public.insumo_sucursal isu
-- JOIN public.insumos i ON i.id = isu.insumo_id
-- JOIN public.sucursales s ON s.id = isu.sucursal_id
-- WHERE i.nombre IN ('PIZZAS', 'BOLSAS OSTIÓN')
-- ORDER BY i.nombre, s.nombre;
