-- =====================================================================
-- El medallón de atún se cuenta en PIEZAS, no en kilos.
--
-- El insumo se llama "ATÚN MEDALLON pz" pero está dado de alta en kg en
-- las cuatro sucursales. El catálogo del proveedor ya lo tiene en pz, y
-- de esa contradicción sale el lío del precio: Lindo Mar lo cotiza a $170
-- casi siempre, pero el 23, 25, 27 y 30 de agosto y el 1 de septiembre
-- entró como $34 — que es $170 ÷ 5. Alguien captura por pieza y otros por
-- paquete, y el comparador cree que el atún vale cinco veces menos.
--
-- Cambiar la unidad además hace que los botones + y - brinquen de uno en
-- uno en vez de medio en medio, que es lo correcto para piezas.
-- =====================================================================

-- updated_at lo pone solo el trigger update_insumo_sucursal_updated_at.
UPDATE public.insumo_sucursal
SET unidad = 'pz'
WHERE insumo_id = (SELECT id FROM public.insumos WHERE nombre = 'ATÚN MEDALLON pz');

-- Comprobación: deben salir las 4 sucursales en 'pz'.
-- SELECT s.nombre, isu.unidad
-- FROM public.insumo_sucursal isu
-- JOIN public.sucursales s ON s.id = isu.sucursal_id
-- WHERE isu.insumo_id = (SELECT id FROM public.insumos WHERE nombre = 'ATÚN MEDALLON pz');
