-- =====================================================================
-- Baja del proveedor Henderson (ago-2026).
-- Ya no se le compra, pero SÍ se conserva su histórico de precios.
-- Por eso no se borra el renglón: se desactiva el proveedor y sus
-- productos. Con activo = false su liga /proveedor/henderson deja de
-- responder (prov_catalogo exige `AND activo`), sale de las listas de
-- pedido y del conteo de "quién ya reportó precio".
-- Además se borran los precios capturados de hoy en adelante.
-- Idempotente.
-- =====================================================================

UPDATE public.proveedores
SET activo = false
WHERE token = 'henderson' OR nombre = 'Henderson';

UPDATE public.proveedor_productos pp
SET activo = false
FROM public.proveedores p
WHERE p.id = pp.proveedor_id
  AND (p.token = 'henderson' OR p.nombre = 'Henderson');

DELETE FROM public.proveedor_precios pr
USING public.proveedor_productos pp, public.proveedores p
WHERE pr.proveedor_producto_id = pp.id
  AND pp.proveedor_id = p.id
  AND (p.token = 'henderson' OR p.nombre = 'Henderson')
  AND pr.created_at >= timestamptz '2026-08-05 00:00:00-06';

NOTIFY pgrst, 'reload schema';
