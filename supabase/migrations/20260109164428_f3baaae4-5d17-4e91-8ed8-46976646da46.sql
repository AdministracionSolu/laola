-- Agregar columna fecha_venta a cortes_caja
ALTER TABLE public.cortes_caja 
ADD COLUMN fecha_venta date;

-- Función para calcular fecha de venta
-- Si el corte se registra antes de las 4:00 AM hora CDMX, pertenece al día anterior
CREATE OR REPLACE FUNCTION public.calcular_fecha_venta()
RETURNS TRIGGER AS $$
DECLARE
  hora_cdmx timestamp with time zone;
  hora_corte integer;
BEGIN
  -- Convertir created_at a hora CDMX
  hora_cdmx := NEW.created_at AT TIME ZONE 'America/Mexico_City';
  hora_corte := EXTRACT(HOUR FROM hora_cdmx);
  
  -- Si es antes de las 4 AM, asignar al día anterior
  IF hora_corte < 4 THEN
    NEW.fecha_venta := (hora_cdmx - INTERVAL '1 day')::date;
  ELSE
    NEW.fecha_venta := hora_cdmx::date;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = public;

-- Trigger para calcular automáticamente en INSERT
CREATE TRIGGER trigger_calcular_fecha_venta
BEFORE INSERT ON public.cortes_caja
FOR EACH ROW
EXECUTE FUNCTION public.calcular_fecha_venta();

-- Actualizar registros existentes con la misma lógica
UPDATE public.cortes_caja 
SET fecha_venta = CASE 
  WHEN EXTRACT(HOUR FROM created_at AT TIME ZONE 'America/Mexico_City') < 4 
  THEN (created_at AT TIME ZONE 'America/Mexico_City' - INTERVAL '1 day')::date
  ELSE (created_at AT TIME ZONE 'America/Mexico_City')::date
END;

-- Hacer la columna NOT NULL después de actualizar
ALTER TABLE public.cortes_caja 
ALTER COLUMN fecha_venta SET NOT NULL;