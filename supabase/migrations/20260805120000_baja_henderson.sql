-- =====================================================================
-- Baja del proveedor Henderson (ago-2026).
-- Ya no se le compra. Se elimina el proveedor; la FK ON DELETE CASCADE
-- borra sus productos, precios y agradecimientos. Los pedidos que lo
-- referencian conservan el registro con proveedor_id en NULL.
-- Idempotente.
-- =====================================================================

DELETE FROM public.proveedores
WHERE token = 'henderson' OR nombre = 'Henderson';

NOTIFY pgrst, 'reload schema';
