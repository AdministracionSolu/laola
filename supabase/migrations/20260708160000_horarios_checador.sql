-- ============================================================
-- HORARIOS DE PERSONAL + CHECADOR
--
-- Dos módulos que comparten el catálogo de personal:
--
--  1. HORARIOS (dashboard admin /admin/horarios)
--     - empleados: alta de personal por área (mesero / cocina / caja)
--     - catalogo_turnos: turnos con nombre reutilizables por sucursal
--       (Matutino / Vespertino / Nocturno...) para llenar rápido
--     - turnos: la plantilla semanal. UN empleado puede tener VARIOS turnos
--       el MISMO día (turno partido / hasta 3) y turnos distintos cada día.
--       El turno lleva la SUCURSAL -> un empleado puede rotar entre sucursales.
--     - turno_excepciones: overrides por fecha (extender un día una sucursal,
--       descanso, cambio de horario puntual).
--
--  2. CHECADOR (Centro de Operaciones /centro-de-operaciones/checador)
--     - Corre en el dispositivo FÍSICO de la sucursal (ya está detrás del PIN
--       de sucursal del OperacionesLayout). El mesero NO checa desde su celular.
--     - La hora la pone el SERVIDOR (now()), no el cliente -> no se falsea.
--     - Cada quien marca con su NOMBRE + PIN personal (evita que otro cheque
--       por él). El alta de asistencia entra por RPC SECURITY DEFINER; el
--       público (anon) NO toca las tablas directamente.
--     - Al marcar entrada se compara contra el turno del día y se calcula el
--       retardo en minutos.
--
-- Convención dia_semana: 0=Domingo ... 6=Sábado  (igual que EXTRACT(DOW) y que
-- horarios_sucursal ya existente). OJO: horarios_sucursal es el horario de
-- APERTURA del restaurante para pedidos en línea; esto es OTRA cosa (personal).
--
-- Día de negocio: corte a las 4 AM hora CDMX (igual que cortes/fecha_venta).
-- ============================================================


-- ============================================================
-- BLOQUE 1 — Personal
-- ============================================================
CREATE TABLE IF NOT EXISTS public.empleados (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre text NOT NULL,
  area text NOT NULL CHECK (area IN ('mesero', 'cocina', 'caja')),
  -- PIN personal de 4 dígitos para el checador. Único por persona (no global).
  pin text CHECK (pin IS NULL OR (char_length(pin) = 4 AND pin !~ '[^0-9]')),
  -- Sucursal "de casa" para agrupar en el roster. La asignación real de trabajo
  -- vive en turnos (por eso puede rotar). Opcional.
  sucursal_principal_id uuid REFERENCES public.sucursales(id) ON DELETE SET NULL,
  telefono text,
  orden int NOT NULL DEFAULT 0,   -- orden de despliegue dentro de su área
  activo boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS empleados_activo_idx ON public.empleados (activo, area, orden);

ALTER TABLE public.empleados ENABLE ROW LEVEL SECURITY;

-- Admin (authenticated): control total.
DROP POLICY IF EXISTS "staff_todo_empleados" ON public.empleados;
CREATE POLICY "staff_todo_empleados" ON public.empleados
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
-- anon: SIN acceso directo (usa las RPCs del checador). No se otorga policy.


-- ============================================================
-- BLOQUE 2 — Catálogo de turnos con nombre (reutilizables)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.catalogo_turnos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  sucursal_id uuid REFERENCES public.sucursales(id) ON DELETE CASCADE, -- NULL = aplica a todas
  nombre text NOT NULL,                 -- 'Matutino', 'Vespertino', 'Nocturno'
  hora_entrada time NOT NULL,
  hora_salida time NOT NULL,
  color text NOT NULL DEFAULT '#0ea5e9',
  orden int NOT NULL DEFAULT 0,
  activo boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS catalogo_turnos_suc_idx ON public.catalogo_turnos (sucursal_id, orden);

ALTER TABLE public.catalogo_turnos ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "staff_todo_catalogo_turnos" ON public.catalogo_turnos;
CREATE POLICY "staff_todo_catalogo_turnos" ON public.catalogo_turnos
  FOR ALL TO authenticated USING (true) WITH CHECK (true);


-- ============================================================
-- BLOQUE 3 — Plantilla semanal (turnos asignados)
-- Varias filas por (empleado, sucursal, dia) = turno partido / hasta 3.
-- ============================================================
CREATE TABLE IF NOT EXISTS public.turnos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  empleado_id uuid NOT NULL REFERENCES public.empleados(id) ON DELETE CASCADE,
  sucursal_id uuid NOT NULL REFERENCES public.sucursales(id) ON DELETE CASCADE,
  dia_semana int NOT NULL CHECK (dia_semana BETWEEN 0 AND 6), -- 0=Dom
  hora_entrada time NOT NULL,
  hora_salida time NOT NULL,
  -- Referencia opcional al catálogo (solo para pintar nombre/color en la UI).
  catalogo_turno_id uuid REFERENCES public.catalogo_turnos(id) ON DELETE SET NULL,
  activo boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS turnos_empleado_idx ON public.turnos (empleado_id, dia_semana);
CREATE INDEX IF NOT EXISTS turnos_sucursal_idx ON public.turnos (sucursal_id, dia_semana);

ALTER TABLE public.turnos ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "staff_todo_turnos" ON public.turnos;
CREATE POLICY "staff_todo_turnos" ON public.turnos
  FOR ALL TO authenticated USING (true) WITH CHECK (true);


-- ============================================================
-- BLOQUE 4 — Excepciones por fecha
-- empleado_id NULL = aplica a toda la sucursal ese día (ej. extender horario).
-- ============================================================
CREATE TABLE IF NOT EXISTS public.turno_excepciones (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  fecha date NOT NULL,
  sucursal_id uuid NOT NULL REFERENCES public.sucursales(id) ON DELETE CASCADE,
  empleado_id uuid REFERENCES public.empleados(id) ON DELETE CASCADE,
  tipo text NOT NULL CHECK (tipo IN ('extension', 'descanso', 'cambio', 'cierre')),
  hora_entrada time,
  hora_salida time,
  nota text,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS turno_excepciones_idx ON public.turno_excepciones (sucursal_id, fecha);

ALTER TABLE public.turno_excepciones ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "staff_todo_excepciones" ON public.turno_excepciones;
CREATE POLICY "staff_todo_excepciones" ON public.turno_excepciones
  FOR ALL TO authenticated USING (true) WITH CHECK (true);


-- ============================================================
-- BLOQUE 5 — Asistencias (checador). Una fila por sesión de trabajo.
-- ============================================================
CREATE TABLE IF NOT EXISTS public.asistencias (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  empleado_id uuid NOT NULL REFERENCES public.empleados(id) ON DELETE CASCADE,
  sucursal_id uuid NOT NULL REFERENCES public.sucursales(id) ON DELETE CASCADE,
  fecha_negocio date NOT NULL,          -- día de negocio (corte 4 AM CDMX)
  entrada_at timestamptz NOT NULL DEFAULT now(),
  salida_at timestamptz,
  turno_entrada time,                   -- el horario que le tocaba (para retardo)
  minutos_retardo int,                  -- NULL si no tenía turno programado
  nota text,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS asistencias_dia_idx ON public.asistencias (sucursal_id, fecha_negocio);
CREATE INDEX IF NOT EXISTS asistencias_empleado_idx ON public.asistencias (empleado_id, fecha_negocio);
-- A lo más UNA sesión abierta por empleado a la vez.
CREATE UNIQUE INDEX IF NOT EXISTS asistencias_una_abierta_idx
  ON public.asistencias (empleado_id) WHERE salida_at IS NULL;

ALTER TABLE public.asistencias ENABLE ROW LEVEL SECURITY;
-- Admin lee/edita todo. El registro (anon) entra por RPC, no directo.
DROP POLICY IF EXISTS "staff_todo_asistencias" ON public.asistencias;
CREATE POLICY "staff_todo_asistencias" ON public.asistencias
  FOR ALL TO authenticated USING (true) WITH CHECK (true);


-- ============================================================
-- BLOQUE 6 — Helper: día de negocio (corte 4 AM CDMX)
-- ============================================================
CREATE OR REPLACE FUNCTION public.laola_fecha_negocio(p_ts timestamptz DEFAULT now())
RETURNS date
LANGUAGE sql
STABLE
AS $$
  SELECT CASE
    WHEN EXTRACT(HOUR FROM (p_ts AT TIME ZONE 'America/Mexico_City')) < 4
      THEN ((p_ts AT TIME ZONE 'America/Mexico_City') - INTERVAL '1 day')::date
    ELSE (p_ts AT TIME ZONE 'America/Mexico_City')::date
  END;
$$;


-- ============================================================
-- BLOQUE 7 — RPC: lista de empleados para el kiosco (sin exponer PIN)
-- Devuelve el roster de la sucursal (quienes tienen turno ahí) + estado.
-- ============================================================
CREATE OR REPLACE FUNCTION public.checador_listar(p_sucursal_id uuid)
RETURNS TABLE (
  empleado_id uuid,
  nombre text,
  area text,
  orden int,
  estado text,             -- 'dentro' | 'fuera'
  entrada_at timestamptz
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT e.id, e.nombre, e.area, e.orden,
         CASE WHEN a.id IS NULL THEN 'fuera' ELSE 'dentro' END AS estado,
         a.entrada_at
  FROM empleados e
  -- sesión abierta (dentro) — la que quede, sin importar la sucursal donde entró
  LEFT JOIN LATERAL (
    SELECT ax.id, ax.entrada_at FROM asistencias ax
    WHERE ax.empleado_id = e.id AND ax.salida_at IS NULL
    ORDER BY ax.entrada_at DESC LIMIT 1
  ) a ON true
  -- roster de la sucursal: tiene al menos un turno asignado ahí
  WHERE e.activo
    AND EXISTS (
      SELECT 1 FROM turnos t
      WHERE t.empleado_id = e.id AND t.sucursal_id = p_sucursal_id AND t.activo
    )
  ORDER BY
    CASE e.area WHEN 'mesero' THEN 1 WHEN 'cocina' THEN 2 WHEN 'caja' THEN 3 ELSE 4 END,
    e.orden, e.nombre;
$$;


-- ============================================================
-- BLOQUE 8 — RPC: checar entrada/salida (toggle)
-- Valida PIN, estampa hora del servidor, calcula retardo contra el turno.
-- ============================================================
CREATE OR REPLACE FUNCTION public.checar(
  p_empleado_id uuid,
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
  v_abierta    asistencias%ROWTYPE;
  v_fecha      date := laola_fecha_negocio(now());
  v_dow        int;
  v_ahora_hora time := (now() AT TIME ZONE 'America/Mexico_City')::time;
  v_turno_ent  time;
  v_retardo    int;
  v_min_trab   int;
BEGIN
  SELECT * INTO v_emp FROM empleados WHERE id = p_empleado_id AND activo;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'EMPLEADO_NO_ENCONTRADO';
  END IF;

  IF v_emp.pin IS NULL OR v_emp.pin <> COALESCE(p_pin, '') THEN
    RAISE EXCEPTION 'PIN_INCORRECTO';
  END IF;

  -- ¿ya tiene una sesión abierta? -> es SALIDA
  SELECT * INTO v_abierta FROM asistencias
  WHERE empleado_id = p_empleado_id AND salida_at IS NULL
  ORDER BY entrada_at DESC LIMIT 1;

  IF FOUND THEN
    UPDATE asistencias SET salida_at = now()
    WHERE id = v_abierta.id;
    v_min_trab := GREATEST(0, (EXTRACT(EPOCH FROM (now() - v_abierta.entrada_at)) / 60)::int);
    RETURN jsonb_build_object(
      'ok', true,
      'tipo', 'salida',
      'nombre', v_emp.nombre,
      'hora', to_char(now() AT TIME ZONE 'America/Mexico_City', 'HH24:MI'),
      'minutos_trabajados', v_min_trab
    );
  END IF;

  -- No hay sesión abierta -> es ENTRADA. Busca el turno del día más cercano.
  v_dow := EXTRACT(DOW FROM v_fecha)::int;

  -- 1) ¿hay excepción de horario para hoy? (empleado o toda la sucursal)
  SELECT hora_entrada INTO v_turno_ent
  FROM turno_excepciones
  WHERE sucursal_id = p_sucursal_id
    AND fecha = v_fecha
    AND (empleado_id = p_empleado_id OR empleado_id IS NULL)
    AND tipo IN ('extension', 'cambio')
    AND hora_entrada IS NOT NULL
  ORDER BY empleado_id NULLS LAST, abs(EXTRACT(EPOCH FROM (hora_entrada - v_ahora_hora)))
  LIMIT 1;

  -- 2) si no hubo excepción, toma el turno de la plantilla más cercano a la hora actual
  IF v_turno_ent IS NULL THEN
    SELECT hora_entrada INTO v_turno_ent
    FROM turnos
    WHERE empleado_id = p_empleado_id
      AND sucursal_id = p_sucursal_id
      AND dia_semana = v_dow
      AND activo
    ORDER BY abs(EXTRACT(EPOCH FROM (hora_entrada - v_ahora_hora)))
    LIMIT 1;
  END IF;

  IF v_turno_ent IS NOT NULL THEN
    v_retardo := GREATEST(0, (EXTRACT(EPOCH FROM (v_ahora_hora - v_turno_ent)) / 60)::int);
  END IF;

  INSERT INTO asistencias (empleado_id, sucursal_id, fecha_negocio, entrada_at, turno_entrada, minutos_retardo)
  VALUES (p_empleado_id, p_sucursal_id, v_fecha, now(), v_turno_ent, v_retardo);

  RETURN jsonb_build_object(
    'ok', true,
    'tipo', 'entrada',
    'nombre', v_emp.nombre,
    'hora', to_char(now() AT TIME ZONE 'America/Mexico_City', 'HH24:MI'),
    'turno', CASE WHEN v_turno_ent IS NULL THEN NULL ELSE to_char(v_turno_ent, 'HH24:MI') END,
    'minutos_retardo', v_retardo
  );
END;
$$;


-- ============================================================
-- BLOQUE 9 — Grants
-- ============================================================
GRANT EXECUTE ON FUNCTION public.checador_listar(uuid) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.checar(uuid, text, uuid) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.laola_fecha_negocio(timestamptz) TO anon, authenticated;
