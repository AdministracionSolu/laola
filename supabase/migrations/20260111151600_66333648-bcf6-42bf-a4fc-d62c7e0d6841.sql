-- Agregar columnas para desglose de tarjetas
ALTER TABLE public.cortes_caja 
ADD COLUMN tarjetas_banregio numeric DEFAULT 0,
ADD COLUMN tarjetas_mercadopago numeric DEFAULT 0,
ADD COLUMN tarjetas_haycash numeric DEFAULT 0;

-- Comentarios para documentación
COMMENT ON COLUMN public.cortes_caja.tarjetas_banregio IS 'Cobros con terminal Banregio';
COMMENT ON COLUMN public.cortes_caja.tarjetas_mercadopago IS 'Cobros con MercadoPago';
COMMENT ON COLUMN public.cortes_caja.tarjetas_haycash IS 'Cobros con HayCash';