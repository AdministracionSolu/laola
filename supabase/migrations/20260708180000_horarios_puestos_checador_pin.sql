-- ============================================================
-- HORARIOS v2 — Puestos ampliados + Checador PIN-only
--
-- 1. Puestos: se agregan 'repartidor' y 'barman'. En la UI se agrupan
--    en 3 secciones: Meseros · Cocina · Caja/Repartidores/Barra.
-- 2. Checador PIN-only: en el monitor de cada sucursal la persona SOLO
--    teclea su PIN (ya no elige su nombre). Para eso el PIN debe ser
--    único entre el personal ACTIVO -> índice único parcial.
-- 3. RPCs: checar_pin (identifica por PIN y hace toggle entrada/salida)
--    y checador_estado (quién está dentro ahora en esa sucursal).
--
-- Excepciones: se quitó de la UI. La tabla turno_excepciones queda
-- (no estorba) pero ya no se usa.
-- ============================================================


-- ============================================================
-- BLOQUE 1 — Ampliar puestos (area)
-- ============================================================
ALTER TABLE public.empleados DROP CONSTRAINT IF EXISTS empleados_area_check;
ALTER TABLE public.empleados
  ADD CONSTRAINT empleados_area_check
  CHECK (area IN ('mesero', 'cocina', 'caja', 'repartidor', 'barman'));


-- ============================================================
-- BLOQUE 2 — PIN único entre personal activo
-- (el checador identifica SOLO por PIN, así que no puede repetirse).
-- ============================================================
CREATE UNIQUE INDEX IF NOT EXISTS empleados_pin_unico_activo
  ON public.empleados (pin)
  WHERE pin IS NOT NULL AND activo;


-- ============================================================
-- BLOQUE 3 — RPC: checar por PIN (toggle entrada/salida)
-- Identifica a la persona por su PIN (único entre activos), estampa la
-- hora del SERVIDOR y calcula el retardo contra su turno del día.
-- ============================================================
CREATE OR REPLACE FUNCTION public.checar_pin(
  p_pin text,
  p_sucursal_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_emp        empleados%ROWTYPE;
  v_count      int;
  v_abierta    asistencias%ROWTYPE;
  v_fecha      date := laola_fecha_negocio(now());
  v_dow        int;
  v_ahora_hora time := (now() AT TIME ZONE 'America/Mexico_City')::time;
  v_turno_ent  time;
  v_retardo    int;
  v_min_trab   int;
BEGIN
  IF p_pin IS NULL OR p_pin !~ '^[0-9]{4}$' THEN
    RAISE EXCEPTION 'PIN_INCORRECTO';
  END IF;

  -- ¿A quién pertenece el PIN? (debe ser exactamente una persona activa)
  SELECT count(*) INTO v_count FROM empleados WHERE pin = p_pin AND activo;
  IF v_count = 0 THEN
    RAISE EXCEPTION 'PIN_INCORRECTO';
  ELSIF v_count > 1 THEN
    RAISE EXCEPTION 'PIN_DUPLICADO';
  END IF;

  SELECT * INTO v_emp FROM empleados WHERE pin = p_pin AND activo;

  -- ¿Ya tiene una sesión abierta? -> es SALIDA (cierra la última, venga de
  -- la sucursal que venga: cubre rotación entre sucursales).
  SELECT * INTO v_abierta FROM asistencias
  WHERE empleado_id = v_emp.id AND salida_at IS NULL
  ORDER BY entrada_at DESC LIMIT 1;

  IF FOUND THEN
    UPDATE asistencias SET salida_at = now() WHERE id = v_abierta.id;
    v_min_trab := GREATEST(0, (EXTRACT(EPOCH FROM (now() - v_abierta.entrada_at)) / 60)::int);
    RETURN jsonb_build_object(
      'ok', true, 'tipo', 'salida', 'nombre', v_emp.nombre,
      'hora', to_char(now() AT TIME ZONE 'America/Mexico_City', 'HH24:MI'),
      'minutos_trabajados', v_min_trab
    );
  END IF;

  -- No hay sesión abierta -> es ENTRADA. Turno del día más cercano (para retardo).
  v_dow := EXTRACT(DOW FROM v_fecha)::int;
  SELECT hora_entrada INTO v_turno_ent
  FROM turnos
  WHERE empleado_id = v_emp.id
    AND sucursal_id = p_sucursal_id
    AND dia_semana = v_dow
    AND activo
  ORDER BY abs(EXTRACT(EPOCH FROM (hora_entrada - v_ahora_hora)))
  LIMIT 1;

  IF v_turno_ent IS NOT NULL THEN
    v_retardo := GREATEST(0, (EXTRACT(EPOCH FROM (v_ahora_hora - v_turno_ent)) / 60)::int);
  END IF;

  INSERT INTO asistencias (empleado_id, sucursal_id, fecha_negocio, entrada_at, turno_entrada, minutos_retardo)
  VALUES (v_emp.id, p_sucursal_id, v_fecha, now(), v_turno_ent, v_retardo);

  RETURN jsonb_build_object(
    'ok', true, 'tipo', 'entrada', 'nombre', v_emp.nombre,
    'hora', to_char(now() AT TIME ZONE 'America/Mexico_City', 'HH24:MI'),
    'turno', CASE WHEN v_turno_ent IS NULL THEN NULL ELSE to_char(v_turno_ent, 'HH24:MI') END,
    'minutos_retardo', v_retardo
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.checar_pin(text, uuid) TO anon, authenticated;


-- ============================================================
-- BLOQUE 4 — RPC: quién está DENTRO ahora en esta sucursal
-- (sesiones abiertas del día de negocio; para el monitor).
-- ============================================================
CREATE OR REPLACE FUNCTION public.checador_estado(p_sucursal_id uuid)
RETURNS TABLE (
  nombre text,
  area text,
  entrada_at timestamptz
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT e.nombre, e.area, a.entrada_at
  FROM asistencias a
  JOIN empleados e ON e.id = a.empleado_id
  WHERE a.sucursal_id = p_sucursal_id
    AND a.salida_at IS NULL
    AND a.fecha_negocio = laola_fecha_negocio(now())
  ORDER BY a.entrada_at DESC;
$$;

GRANT EXECUTE ON FUNCTION public.checador_estado(uuid) TO anon, authenticated;
