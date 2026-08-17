-- ============================================================
-- Que el gracias a proveedores deje rastro cuando falla.
--
-- Capital Camaronera capturó precios casi a diario del 31-jul al 16-ago y
-- nunca recibió el agradecimiento: está guardado como "+52 1 311 227 6299" y
-- la edge exigía diez dígitos pelones, así que respondía 400. El candado del
-- día sí se escribía, la llamada se iba por pg_net y el error se quedaba en
-- net._http_response, que nadie mira y que además se purga solo.
--
-- La edge ya normaliza el teléfono (makatea-core, _shared/phone.ts). Esto es
-- lo otro que faltaba: poder ver desde el panel si el gracias salió o no.
--
-- Cuatro bloques independientes, en orden.
-- ============================================================

-- BLOQUE 1 — Guardar el id de la petición y la hora del intento
ALTER TABLE public.prov_gracias_enviados
  ADD COLUMN IF NOT EXISTS request_id bigint,
  ADD COLUMN IF NOT EXISTS created_at timestamptz NOT NULL DEFAULT now();


-- BLOQUE 2 — El trigger guarda el request_id que devuelve pg_net
CREATE OR REPLACE FUNCTION public.trg_precio_gracias()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_cfg  integracion_makatea%ROWTYPE;
  v_prov proveedores%ROWTYPE;
  v_hoy  date := (now() AT TIME ZONE 'America/Mazatlan')::date;
  v_req  bigint;
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

  -- El teléfono va tal como está capturado: normalizarlo es trabajo de la edge,
  -- que entiende lada, el 1 viejo de móvil y los separadores.
  SELECT net.http_post(
    url     := v_cfg.base_url || '/functions/v1/laola-gracias',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-laola-secret', v_cfg.secreto
    ),
    body    := jsonb_build_object('nombre', v_prov.nombre, 'telefono', v_prov.telefono),
    timeout_milliseconds := 10000
  ) INTO v_req;

  UPDATE prov_gracias_enviados
     SET request_id = v_req
   WHERE proveedor_id = v_prov.id AND fecha = v_hoy;

  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS precios_gracias ON public.proveedor_precios;
CREATE TRIGGER precios_gracias
  AFTER INSERT ON public.proveedor_precios
  FOR EACH ROW EXECUTE FUNCTION public.trg_precio_gracias();


-- BLOQUE 3 — El panel puede leer la bitácora (hoy la RLS la deja ciega
-- hasta para el admin, que es por lo que no se podía comprobar nada)
DROP POLICY IF EXISTS gracias_lectura_admin ON public.prov_gracias_enviados;
CREATE POLICY gracias_lectura_admin ON public.prov_gracias_enviados
  FOR SELECT TO authenticated USING (true);


-- BLOQUE 4 — Diagnóstico: quién recibió el gracias y con qué respuesta.
-- net._http_response no se ve por PostgREST y se purga sola a las horas, así
-- que se consulta por aquí el mismo día.
CREATE OR REPLACE FUNCTION public.prov_gracias_diagnostico(p_dias int DEFAULT 7)
RETURNS TABLE (
  fecha        date,
  proveedor    text,
  telefono     text,
  status       int,
  respuesta    text,
  error        text
)
LANGUAGE sql SECURITY DEFINER SET search_path = public, net
AS $$
  SELECT g.fecha,
         p.nombre,
         p.telefono,
         r.status_code,
         left(r.content, 300),
         r.error_msg
  FROM prov_gracias_enviados g
  JOIN proveedores p ON p.id = g.proveedor_id
  LEFT JOIN net._http_response r ON r.id = g.request_id
  WHERE g.fecha >= (now() AT TIME ZONE 'America/Mazatlan')::date - p_dias
  ORDER BY g.fecha DESC, p.nombre;
$$;

REVOKE ALL ON FUNCTION public.prov_gracias_diagnostico(int) FROM public;
GRANT EXECUTE ON FUNCTION public.prov_gracias_diagnostico(int) TO authenticated;
