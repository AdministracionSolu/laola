-- ============================================================
-- HORARIOS POR ROL CON HORAS + ROLES POR ÁREA
--
-- Hasta ahora los roles (Abre / Intermedio / Cierra) no llevaban horas
-- y toda área mostraba los 3. Diego definió los horarios reales del
-- piloto en Valle:
--  · Barra  = igual que meseros, pero SIN rol intermedio.
--  · Caja   = dos turnos: abre 10:00–18:00 y cierra 16:00–00:00.
--  · Cocina = su intermedio es 16:00–00:00 (igual al cierre de caja).
--
-- horarios_roles_def dice, por área (y opcionalmente por sucursal),
-- QUÉ roles existen y con qué horas. Si un área no tiene renglones,
-- todo sigue como hoy (3 roles, sin horas). La liga de captura
-- (/horario/:token) muestra solo los roles del área con sus horas.
-- ============================================================


-- ============================================================
-- BLOQUE 1 — Tabla de definición de roles por área
-- ============================================================
CREATE TABLE IF NOT EXISTS public.horarios_roles_def (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  sucursal_id  uuid REFERENCES public.sucursales(id) ON DELETE CASCADE, -- NULL = todas
  area         text NOT NULL,
  rol          text NOT NULL CHECK (rol IN ('abre', 'intermedio', 'cierra')),
  hora_entrada time,  -- NULL = el rol existe pero sin hora publicada
  hora_salida  time,
  activo       boolean NOT NULL DEFAULT true,
  updated_at   timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS horarios_roles_def_unico
  ON public.horarios_roles_def (COALESCE(sucursal_id, '00000000-0000-0000-0000-000000000000'::uuid), area, rol);

ALTER TABLE public.horarios_roles_def ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "staff_todo_horarios_roles_def" ON public.horarios_roles_def;
CREATE POLICY "staff_todo_horarios_roles_def" ON public.horarios_roles_def
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
-- anon: sin acceso directo; lo lee vía horarios_captura_info.


-- ============================================================
-- BLOQUE 2 — Seed del piloto en Valle
-- (meseros con sus 3 roles sin horas; barra igual pero sin intermedio;
--  caja 10–18 / 16–00; cocina con intermedio 16–00)
-- ============================================================
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


-- ============================================================
-- BLOQUE 3 — Ligas de captura de Valle (una por área del piloto)
-- ============================================================
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


-- ============================================================
-- BLOQUE 4 — horarios_captura_info ahora regresa los roles del área
-- (con horas). Si el área no tiene definición, regresa [] y el front
-- muestra los 3 roles como siempre.
-- ============================================================
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


-- ============================================================
-- BLOQUE 5 — horarios_captura_set valida que el rol exista en el área
-- (si el área tiene definición; barra ya no acepta 'intermedio')
-- ============================================================
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

  -- Si el área tiene roles definidos, el rol debe ser uno de ellos.
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

  -- Vaciar la celda (quita a quien estuviera en ese rol ese día).
  DELETE FROM turnos
  WHERE sucursal_id = v_liga.sucursal_id AND area = v_liga.area
    AND dia_semana = p_dia AND rol = p_rol;

  IF p_empleado_id IS NULL THEN
    RETURN jsonb_build_object('ok', true);
  END IF;

  -- La persona debe ser del área.
  PERFORM 1 FROM empleados
  WHERE id = p_empleado_id AND activo AND area = v_liga.area;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'EMPLEADO_INVALIDO';
  END IF;

  -- Una persona, un solo rol por día en esta área.
  DELETE FROM turnos
  WHERE empleado_id = p_empleado_id AND sucursal_id = v_liga.sucursal_id
    AND area = v_liga.area AND dia_semana = p_dia AND rol IS NOT NULL;

  INSERT INTO turnos (empleado_id, sucursal_id, dia_semana, rol, area, activo)
  VALUES (p_empleado_id, v_liga.sucursal_id, p_dia, p_rol, v_liga.area, true);

  RETURN jsonb_build_object('ok', true);
END;
$$;
