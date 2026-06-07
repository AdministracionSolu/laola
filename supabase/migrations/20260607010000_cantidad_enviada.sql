-- =====================================================================
-- Cantidad que el ADMIN declara que realmente envía a la sucursal.
-- El admin (quien llama al proveedor) captura esto en el concentrado;
-- luego se contrasta contra lo que la sucursal dice que recibió (fugas).
-- =====================================================================
ALTER TABLE public.pedidos_detalle ADD COLUMN IF NOT EXISTS cantidad_enviada numeric;
