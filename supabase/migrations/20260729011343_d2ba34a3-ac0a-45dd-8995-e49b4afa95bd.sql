-- =========================================================
-- MIGRACIÓN 1/3 — VIGILANTE DE CORTES v2
-- =========================================================
ALTER TABLE public.cortes_alertas_config
  ADD COLUMN IF NOT EXISTS hora_limite_finde time;

UPDATE public.cortes_alertas_config c SET
  hora_limite = CASE s.nombre
    WHEN 'Las Brisas' THEN '18:00'::time
    WHEN 'Solares'    THEN '18:30'::time
    ELSE '23:30'::time
  END,
  hora_limite_finde = CASE s.nombre
    WHEN 'Cervecería' THEN '02:00'::time
    ELSE NULL
  END,
  activo = true,
  updated_at = now()
FROM public.sucursales s
WHERE s.id = c.sucursal_id;

CREATE OR REPLACE FUNCTION public.vigilar_cortes()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_cfg      integracion_makatea%ROWTYPE;
  v_row      record;
  v_loc      timestamp;
  v_fecha    date;
  v_dow      int;
  v_lim      time;
  v_bt_ahora int;
  v_bt_lim   int;
  v_mensaje  text;
BEGIN
  SELECT * INTO v_cfg FROM integracion_makatea WHERE id = 1 AND activo;
  IF NOT FOUND OR v_cfg.base_url LIKE '%PON-AQUI%' THEN RETURN; END IF;

  FOR v_row IN
    SELECT c.sucursal_id, c.hora_limite, c.hora_limite_finde, s.nombre,
           COALESCE(s.zona_horaria, 'America/Mexico_City') AS tz
    FROM cortes_alertas_config c
    JOIN sucursales s ON s.id = c.sucursal_id
    WHERE c.activo
  LOOP
    v_loc   := now() AT TIME ZONE v_row.tz;
    v_fecha := (v_loc - interval '4 hours')::date;
    v_dow   := EXTRACT(DOW FROM v_fecha)::int;

    v_lim := CASE WHEN v_dow IN (5, 6) AND v_row.hora_limite_finde IS NOT NULL
                  THEN v_row.hora_limite_finde
                  ELSE v_row.hora_limite END;

    v_bt_ahora := ((EXTRACT(EPOCH FROM v_loc::time)::int - 14400) + 86400) % 86400;
    v_bt_lim   := ((EXTRACT(EPOCH FROM v_lim)::int - 14400) + 86400) % 86400;

    IF v_bt_ahora < v_bt_lim + 60 THEN CONTINUE; END IF;

    IF EXISTS (
      SELECT 1 FROM cortes_caja k
      WHERE k.sucursal_id = v_row.sucursal_id
        AND k.tipo_corte = 'cierre'
        AND k.fecha_venta = v_fecha
    ) THEN CONTINUE; END IF;

    BEGIN
      INSERT INTO cortes_alertas_enviadas (sucursal_id, fecha_negocio)
      VALUES (v_row.sucursal_id, v_fecha);
    EXCEPTION WHEN unique_violation THEN
      CONTINUE;
    END;

    v_mensaje := v_row.nombre || ': está pendiente cargar los datos del corte de cierre del '
      || to_char(v_fecha, 'DD/MM')
      || '. Favor de subirlo en el Centro de Operaciones.';

    PERFORM net.http_post(
      url     := v_cfg.base_url || '/functions/v1/laola-ops-alert',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'x-laola-secret', v_cfg.secreto
      ),
      body    := jsonb_build_object('mensaje', v_mensaje)
    );
  END LOOP;
END;
$$;

-- Reagenda el cron cada minuto. El unschedule se protege por si no existía.
DO $$
BEGIN
  BEGIN
    PERFORM cron.unschedule('vigilar-cortes');
  EXCEPTION WHEN OTHERS THEN
    NULL;
  END;
  PERFORM cron.schedule('vigilar-cortes', '* * * * *', $c$SELECT public.vigilar_cortes()$c$);
END $$;


-- =========================================================
-- MIGRACIÓN 2/3 — BITÁCORA DE CORTES
-- =========================================================
CREATE TABLE IF NOT EXISTS public.cortes_audit (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  corte_id    uuid NOT NULL,
  sucursal_id uuid,
  accion      text NOT NULL CHECK (accion IN ('editar', 'eliminar')),
  quien       text,
  antes       jsonb NOT NULL,
  despues     jsonb,
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_cortes_audit_corte ON public.cortes_audit (corte_id);
CREATE INDEX IF NOT EXISTS idx_cortes_audit_fecha ON public.cortes_audit (created_at DESC);

GRANT SELECT ON public.cortes_audit TO authenticated;
GRANT ALL ON public.cortes_audit TO service_role;

ALTER TABLE public.cortes_audit ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "staff_lee_cortes_audit" ON public.cortes_audit;
CREATE POLICY "staff_lee_cortes_audit" ON public.cortes_audit
  FOR SELECT TO authenticated USING (true);

CREATE OR REPLACE FUNCTION public.cortes_caja_audit()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_quien text := COALESCE(NULLIF(auth.jwt() ->> 'email', ''), 'sistema');
BEGIN
  IF TG_OP = 'DELETE' THEN
    INSERT INTO cortes_audit (corte_id, sucursal_id, accion, quien, antes, despues)
    VALUES (OLD.id, OLD.sucursal_id, 'eliminar', v_quien, to_jsonb(OLD), NULL);
    RETURN OLD;
  END IF;
  INSERT INTO cortes_audit (corte_id, sucursal_id, accion, quien, antes, despues)
  VALUES (OLD.id, OLD.sucursal_id, 'editar', v_quien, to_jsonb(OLD), to_jsonb(NEW));
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_cortes_caja_audit ON public.cortes_caja;
CREATE TRIGGER trg_cortes_caja_audit
  AFTER UPDATE OR DELETE ON public.cortes_caja
  FOR EACH ROW EXECUTE FUNCTION public.cortes_caja_audit();


-- =========================================================
-- MIGRACIÓN 3/3 — HORARIOS POR ROL CON HORAS
-- =========================================================
CREATE TABLE IF NOT EXISTS public.horarios_roles_def (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  sucursal_id  uuid REFERENCES public.sucursales(id) ON DELETE CASCADE,
  area         text NOT NULL,
  rol          text NOT NULL CHECK (rol IN ('abre', 'intermedio', 'cierra')),
  hora_entrada time,
  hora_salida  time,
  activo       boolean NOT NULL DEFAULT true,
  updated_at   timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS horarios_roles_def_unico
  ON public.horarios_roles_def (COALESCE(sucursal_id, '00000000-0000-0000-0000-000000000000'::uuid), area, rol);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.horarios_roles_def TO authenticated;
GRANT ALL ON public.horarios_roles_def TO service_role;

ALTER TABLE public.horarios_roles_def ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "staff_todo_horarios_roles_def" ON public.horarios_roles_def;
CREATE POLICY "staff_todo_horarios_roles_def" ON public.horarios_roles_def
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

INSERT INTO public.horarios_roles_def (sucursal_id, area, rol, hora_entrada, hora_salida)
SELECT s.id, v.area, v.rol, v.entrada::time, v.salida::time
FROM public.sucursales s
CROSS JOIN (VALUES
  ('mesero', 'abre',       NULL,    NULL),
  ('mesero', 'intermedio', NULL,    NULL),
  ('mesero', 'cierra',     NULL,    NULL),
  ('barman', 'abre',       NULL,    NULL),
  ('barman', 'cierra',     NULL,    NULL),
  ('caja',   'abre',       '10:00', '18:00'),
  ('caja',   'cierra',     '16:00', '00:00'),
  ('cocina', 'abre',       NULL,    NULL),
  ('cocina', 'intermedio', '16:00', '00:00'),
  ('cocina', 'cierra',     NULL,    NULL)
) AS v(area, rol, entrada, salida)
WHERE s.nombre = 'Valle'
ON CONFLICT DO NOTHING;

INSERT INTO public.horarios_ligas (sucursal_id, area, token)
SELECT s.id, v.area, v.token
FROM public.sucursales s
CROSS JOIN (VALUES
  ('mesero', 'valle-meseros'),
  ('cocina', 'valle-cocina'),
  ('caja',   'valle-caja'),
  ('barman', 'valle-barra')
) AS v(area, token)
WHERE s.nombre = 'Valle'
ON CONFLICT DO NOTHING;

CREATE OR REPLACE FUNCTION public.horarios_captura_info(p_token text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_liga horarios_ligas%ROWTYPE;
BEGIN
  SELECT * INTO v_liga FROM horarios_ligas WHERE token = p_token AND activo;
  IF NOT FOUND THEN
    RETURN NULL;
  END IF;

  RETURN jsonb_build_object(
    'sucursal', (SELECT nombre FROM sucursales WHERE id = v_liga.sucursal_id),
    'area', v_liga.area,
    'roles', COALESCE((
      SELECT jsonb_agg(
        jsonb_build_object('rol', d.rol, 'hora_entrada', d.hora_entrada, 'hora_salida', d.hora_salida)
        ORDER BY CASE d.rol WHEN 'abre' THEN 1 WHEN 'intermedio' THEN 2 ELSE 3 END
      )
      FROM horarios_roles_def d
      WHERE d.area = v_liga.area AND d.activo
        AND (
          d.sucursal_id = v_liga.sucursal_id
          OR (d.sucursal_id IS NULL AND NOT EXISTS (
            SELECT 1 FROM horarios_roles_def d2
            WHERE d2.area = v_liga.area AND d2.activo AND d2.sucursal_id = v_liga.sucursal_id
          ))
        )
    ), '[]'::jsonb),
    'equipo', COALESCE((
      SELECT jsonb_agg(jsonb_build_object('id', e.id, 'nombre', e.nombre) ORDER BY e.orden, e.nombre)
      FROM empleados e
      WHERE e.activo
        AND e.area = v_liga.area
        AND (e.sucursal_principal_id = v_liga.sucursal_id OR e.sucursal_principal_id IS NULL)
    ), '[]'::jsonb),
    'asignaciones', COALESCE((
      SELECT jsonb_agg(jsonb_build_object('dia', t.dia_semana, 'rol', t.rol, 'empleado_id', t.empleado_id))
      FROM turnos t
      WHERE t.sucursal_id = v_liga.sucursal_id
        AND t.area = v_liga.area
        AND t.rol IS NOT NULL
        AND t.activo
    ), '[]'::jsonb)
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.horarios_captura_set(
  p_token text,
  p_dia int,
  p_rol text,
  p_empleado_id uuid DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_liga horarios_ligas%ROWTYPE;
BEGIN
  SELECT * INTO v_liga FROM horarios_ligas WHERE token = p_token AND activo;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'LIGA_INVALIDA';
  END IF;
  IF p_dia IS NULL OR p_dia < 0 OR p_dia > 6 THEN
    RAISE EXCEPTION 'DIA_INVALIDO';
  END IF;
  IF p_rol IS NULL OR p_rol NOT IN ('abre', 'intermedio', 'cierra') THEN
    RAISE EXCEPTION 'ROL_INVALIDO';
  END IF;

  IF EXISTS (
    SELECT 1 FROM horarios_roles_def d
    WHERE d.area = v_liga.area AND d.activo
      AND (d.sucursal_id = v_liga.sucursal_id OR d.sucursal_id IS NULL)
  ) AND NOT EXISTS (
    SELECT 1 FROM horarios_roles_def d
    WHERE d.area = v_liga.area AND d.activo AND d.rol = p_rol
      AND (d.sucursal_id = v_liga.sucursal_id OR d.sucursal_id IS NULL)
  ) THEN
    RAISE EXCEPTION 'ROL_NO_DISPONIBLE';
  END IF;

  DELETE FROM turnos
  WHERE sucursal_id = v_liga.sucursal_id AND area = v_liga.area
    AND dia_semana = p_dia AND rol = p_rol;

  IF p_empleado_id IS NULL THEN
    RETURN jsonb_build_object('ok', true);
  END IF;

  PERFORM 1 FROM empleados
  WHERE id = p_empleado_id AND activo AND area = v_liga.area;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'EMPLEADO_INVALIDO';
  END IF;

  DELETE FROM turnos
  WHERE empleado_id = p_empleado_id AND sucursal_id = v_liga.sucursal_id
    AND area = v_liga.area AND dia_semana = p_dia AND rol IS NOT NULL;

  INSERT INTO turnos (empleado_id, sucursal_id, dia_semana, rol, area, activo)
  VALUES (p_empleado_id, v_liga.sucursal_id, p_dia, p_rol, v_liga.area, true);

  RETURN jsonb_build_object('ok', true);
END;
$$;