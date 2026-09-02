-- =====================================================================
-- Alitas y pescado para zarandear van en KILOS en las cuatro sucursales.
--
-- Confirmado con la operación el 2-sep-2026. Venían disparejos desde el
-- 29 de julio, cuando se dieron de alta a mano en Cervecería y Brisas y
-- se les tecleó otra unidad que la del sembrado original:
--   · Alitas              → 'bolsa' en Las Brisas, kg en las otras tres
--   · Pescado p/zarandear → 'pz' en Cervecería y Brisas, kg en Valle y Solares
--
-- El pescado se vende por pieza pero se COMPRA por kilo, y esta lista es
-- de compra. No hay historia que rehacer: las sucursales que lo tenían en
-- pieza o bolsa nunca capturaron en esos insumos un valor distinto de cero.
--
-- Se ponen las cuatro en kg (no sólo las disparejas) para que quede una
-- sola unidad aunque alguien haya tocado otra por su cuenta.
-- =====================================================================

UPDATE public.insumo_sucursal
SET unidad = 'kg'
WHERE insumo_id IN (
  SELECT id FROM public.insumos WHERE nombre IN ('ALITAS', 'PESCADO P/SARANDEAR')
);

-- Comprobación: 8 renglones, todos 'kg'.
-- SELECT i.nombre, s.nombre AS sucursal, isu.unidad
-- FROM public.insumo_sucursal isu
-- JOIN public.insumos i ON i.id = isu.insumo_id
-- JOIN public.sucursales s ON s.id = isu.sucursal_id
-- WHERE i.nombre IN ('ALITAS', 'PESCADO P/SARANDEAR')
-- ORDER BY i.nombre, s.nombre;
