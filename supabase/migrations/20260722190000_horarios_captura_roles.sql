-- ============================================================
-- CAPTURA DE HORARIOS POR ROL (Abre / Intermedio / Cierra)
--
-- Modo de captura simple para que UNA persona por área suba el
-- horario semanal de su equipo desde el celular, sin login:
--
--  · El rol NO lleva horas (el equipo ya sabe qué significa cada
--    rol en su área). turnos.hora_entrada/salida pasan a nullable
--    y se agrega turnos.rol ('abre'|'intermedio'|'cierra') +
--    turnos.area (para separar meseros de barra, etc.).
--  · Quien no aparece en ningún rol un día, DESCANSA ese día
--    (derivado, no se captura).
--  · Regla: UNA persona por rol por día (y una persona no puede
--    tener dos roles el mismo día en la misma área).
--  · Acceso por liga con token legible (horarios_ligas), mismo
--    patrón que el portal de proveedores. RPCs SECURITY DEFINER;
--    anon NO toca las tablas directo.
--
-- El checador no se toca: un turno por rol tiene hora_entrada
-- NULL, así que simplemente no calcula retardo (queda NULL).
-- ============================================================


-- ============================================================
-- BLOQUE 1 — turnos: horas opcionales + rol + área
-- ============================================================
ALTER TABLE public.turnos ALTER COLUMN hora_entrada DROP NOT NULL;
ALTER TABLE public.turnos ALTER COLUMN hora_salida DROP NOT NULL;
ALTER TABLE public.turnos ADD COLUMN IF NOT EXISTS rol text;
ALTER TABLE public.turnos ADD COLUMN IF NOT EXISTS area text;
ALTER TABLE public.turnos DROP CONSTRAINT IF EXISTS turnos_rol_valido;
ALTER TABLE public.turnos ADD CONSTRAINT turnos_rol_valido
  CHECK (rol IS NULL OR rol IN ('abre', 'intermedio', 'cierra'));
-- Cada renglón es un turno por horas O un turno por rol.
ALTER TABLE public.turnos DROP CONSTRAINT IF EXISTS turnos_rol_o_horas;
ALTER TABLE public.turnos ADD CONSTRAINT turnos_rol_o_horas
  CHECK (rol IS NOT NULL OR (hora_entrada IS NOT NULL AND hora_salida IS NOT NULL));


-- ============================================================
-- BLOQUE 2 — Candado: UNA persona por rol por día (por área/sucursal)
-- ============================================================
CREATE UNIQUE INDEX IF NOT EXISTS turnos_rol_unico
  ON public.turnos (sucursal_id, area, dia_semana, rol)
  WHERE rol IS NOT NULL AND activo;
-- Y una persona no puede tener dos roles el mismo día en la misma área.
CREATE UNIQUE INDEX IF NOT EXISTS turnos_rol_persona_unica
  ON public.turnos (empleado_id, sucursal_id, area, dia_semana)
  WHERE rol IS NOT NULL AND activo;


-- ============================================================
-- BLOQUE 3 — Ligas de captura por área (token legible)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.horarios_ligas (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  token text NOT NULL UNIQUE,
  sucursal_id uuid NOT NULL REFERENCES public.sucursales(id) ON DELETE CASCADE,
  area text NOT NULL,
  activo boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (sucursal_id, area)
);

ALTER TABLE public.horarios_ligas ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "staff_todo_horarios_ligas" ON public.horarios_ligas;
CREATE POLICY "staff_todo_horarios_ligas" ON public.horarios_ligas
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
-- anon: SIN acceso directo (usa las RPCs). No se otorga policy.


-- ============================================================
-- BLOQUE 4 — RPC: info de la liga (equipo + asignaciones)
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
-- BLOQUE 5 — RPC: asignar / quitar persona en un rol de un día
-- p_empleado_id NULL = dejar la celda vacía.
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


-- ============================================================
-- BLOQUE 6 — Grants
-- ============================================================
GRANT EXECUTE ON FUNCTION public.horarios_captura_info(text) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.horarios_captura_set(text, int, text, uuid) TO anon, authenticated;
