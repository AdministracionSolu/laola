-- ============================================================
-- Gracias automático a proveedores al capturar sus precios.
-- Primer precio del día por proveedor → WhatsApp vía Makatea
-- (edge function laola-gracias, ya desplegada). Candado 1×/día.
-- Reusa integracion_makatea (puente ya configurado).
-- ============================================================

-- BLOQUE 1 — Candado: un gracias por proveedor por día
CREATE TABLE IF NOT EXISTS public.prov_gracias_enviados (
  proveedor_id uuid NOT NULL REFERENCES public.proveedores(id) ON DELETE CASCADE,
  fecha        date NOT NULL,
  PRIMARY KEY (proveedor_id, fecha)
);
ALTER TABLE public.prov_gracias_enviados ENABLE ROW LEVEL SECURITY;

-- BLOQUE 2 — Función + trigger
CREATE OR REPLACE FUNCTION public.trg_precio_gracias()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_cfg  integracion_makatea%ROWTYPE;
  v_prov proveedores%ROWTYPE;
  v_hoy  date := (now() AT TIME ZONE 'America/Mexico_City')::date;
BEGIN
  SELECT p.* INTO v_prov
  FROM proveedores p
  JOIN proveedor_productos pp ON pp.proveedor_id = p.id
  WHERE pp.id = NEW.proveedor_producto_id;
  IF NOT FOUND OR v_prov.telefono IS NULL THEN RETURN NEW; END IF;

  -- candado: solo el primer precio del día de este proveedor
  INSERT INTO prov_gracias_enviados (proveedor_id, fecha)
  VALUES (v_prov.id, v_hoy) ON CONFLICT DO NOTHING;
  IF NOT FOUND THEN RETURN NEW; END IF;

  SELECT * INTO v_cfg FROM integracion_makatea WHERE id = 1 AND activo;
  IF NOT FOUND THEN RETURN NEW; END IF;

  PERFORM net.http_post(
    url     := v_cfg.base_url || '/functions/v1/laola-gracias',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-laola-secret', v_cfg.secreto
    ),
    body    := jsonb_build_object('nombre', v_prov.nombre, 'telefono', v_prov.telefono),
    timeout_milliseconds := 10000
  );
  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS precios_gracias ON public.proveedor_precios;
CREATE TRIGGER precios_gracias
  AFTER INSERT ON public.proveedor_precios
  FOR EACH ROW EXECUTE FUNCTION public.trg_precio_gracias();
