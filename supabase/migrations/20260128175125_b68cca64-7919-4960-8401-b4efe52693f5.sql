-- Modificar el trigger para que NO sobrescriba fecha_venta si ya viene con valor
-- (cuando el admin especifica una fecha personalizada)

CREATE OR REPLACE FUNCTION public.calcular_fecha_venta()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
DECLARE
  hora_cdmx timestamp with time zone;
  hora_corte integer;
BEGIN
  -- Si fecha_venta ya tiene valor (admin especificó fecha), no sobrescribir
  IF NEW.fecha_venta IS NOT NULL THEN
    RETURN NEW;
  END IF;
  
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
$function$;