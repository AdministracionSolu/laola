-- Agregar columnas para Rappi y Uber (solo usadas por Solares)
ALTER TABLE public.cortes_caja 
ADD COLUMN rappi numeric DEFAULT 0,
ADD COLUMN uber numeric DEFAULT 0;

COMMENT ON COLUMN public.cortes_caja.rappi IS 'Cobros a través de Rappi (solo Solares)';
COMMENT ON COLUMN public.cortes_caja.uber IS 'Cobros a través de Uber (solo Solares)';