-- ============================================================
-- LEALTAD v2 — Por VISITAS (mientras resolvemos captura de montos)
--
-- Se monta sobre lealtad_clientes (v1). Agrega:
--   - Conteo de visitas y niveles (Nuevo/Frecuente/Oro/Platino).
--   - Tarjeta de sellos: cada N visitas = una recompensa.
--   - Historial de cada visita (anti-tranza): sucursal, día, hora, origen.
--   - Anti-fraude: tope de visitas por teléfono por día de negocio.
--
-- El cashback en DINERO queda pendiente hasta resolver cómo capturar el
-- monto del ticket. Aquí todo es por número de visitas.
--
-- Día de negocio: corte 4 AM CDMX (laola_fecha_negocio, ya existe).
-- ============================================================


-- ============================================================
-- BLOQUE 1 — Contadores en el cliente
-- ============================================================
ALTER TABLE public.lealtad_clientes
  ADD COLUMN IF NOT EXISTS visitas_total int NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS recompensas_usadas int NOT NULL DEFAULT 0;


-- ============================================================
-- BLOQUE 2 — Catálogo de niveles (editable en el admin)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.lealtad_niveles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre text NOT NULL,
  min_visitas int NOT NULL,        -- desde cuántas visitas acumuladas aplica
  beneficio text,                  -- descripción del beneficio del nivel
  color text NOT NULL DEFAULT '#0ea5e9',
  orden int NOT NULL DEFAULT 0,
  activo boolean NOT NULL DEFAULT true
);

ALTER TABLE public.lealtad_niveles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "todos_leen_niveles" ON public.lealtad_niveles;
CREATE POLICY "todos_leen_niveles" ON public.lealtad_niveles
  FOR SELECT TO anon, authenticated USING (true);
DROP POLICY IF EXISTS "staff_edita_niveles" ON public.lealtad_niveles;
CREATE POLICY "staff_edita_niveles" ON public.lealtad_niveles
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Seed de arranque (solo si está vacío)
INSERT INTO public.lealtad_niveles (nombre, min_visitas, beneficio, color, orden)
SELECT * FROM (VALUES
  ('Nuevo',      0,  'Bienvenido a La Ola',                     '#94a3b8', 1),
  ('Frecuente',  5,  '10% en tu cumpleaños',                    '#0ea5e9', 2),
  ('Oro',        15, 'Bebida de cortesía al llegar a Oro',      '#f59e0b', 3),
  ('Platino',    30, 'Postre de cortesía y atención prioritaria','#a855f7', 4)
) AS v(nombre, min_visitas, beneficio, color, orden)
WHERE NOT EXISTS (SELECT 1 FROM public.lealtad_niveles);


-- ============================================================
-- BLOQUE 3 — Configuración (una sola fila)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.lealtad_config (
  id int PRIMARY KEY DEFAULT 1 CHECK (id = 1),
  meta_visitas int NOT NULL DEFAULT 10,        -- visitas por recompensa (sellos)
  tope_visitas_dia int NOT NULL DEFAULT 1,     -- anti-fraude: visitas/día por teléfono
  recompensa_texto text NOT NULL DEFAULT 'Bebida o postre de cortesía',
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.lealtad_config ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "todos_leen_config" ON public.lealtad_config;
CREATE POLICY "todos_leen_config" ON public.lealtad_config
  FOR SELECT TO anon, authenticated USING (true);
DROP POLICY IF EXISTS "staff_edita_config" ON public.lealtad_config;
CREATE POLICY "staff_edita_config" ON public.lealtad_config
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

INSERT INTO public.lealtad_config (id) VALUES (1) ON CONFLICT (id) DO NOTHING;


-- ============================================================
-- BLOQUE 4 — Historial de visitas (el "track record" anti-tranza)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.lealtad_visitas (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  cliente_id uuid NOT NULL REFERENCES public.lealtad_clientes(id) ON DELETE CASCADE,
  sucursal_id uuid REFERENCES public.sucursales(id),
  fecha_negocio date NOT NULL,
  origen text NOT NULL DEFAULT 'qr',   -- 'qr' (auto-registro) | 'caja'
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS lealtad_visitas_cliente_idx ON public.lealtad_visitas (cliente_id, created_at DESC);
CREATE INDEX IF NOT EXISTS lealtad_visitas_dia_idx ON public.lealtad_visitas (fecha_negocio, sucursal_id);

ALTER TABLE public.lealtad_visitas ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "staff_lee_visitas" ON public.lealtad_visitas;
CREATE POLICY "staff_lee_visitas" ON public.lealtad_visitas
  FOR SELECT TO authenticated USING (true);
-- anon NO toca directo: entra por la RPC.


-- ============================================================
-- BLOQUE 5 — Helper: nivel actual + siguiente
-- ============================================================
CREATE OR REPLACE FUNCTION public.lealtad_perfil_json(p_cliente public.lealtad_clientes)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SET search_path = public
AS $$
DECLARE
  v_meta   int;
  v_nivel  record;
  v_sig    record;
  v_gan    int;
  v_disp   int;
  v_prog   int;
BEGIN
  SELECT meta_visitas INTO v_meta FROM lealtad_config WHERE id = 1;
  v_meta := GREATEST(1, COALESCE(v_meta, 10));

  -- nivel actual: el de mayor min_visitas que ya alcanzó
  SELECT nombre, beneficio, color INTO v_nivel
  FROM lealtad_niveles
  WHERE activo AND min_visitas <= p_cliente.visitas_total
  ORDER BY min_visitas DESC LIMIT 1;

  -- siguiente nivel: el más cercano por encima
  SELECT nombre, min_visitas INTO v_sig
  FROM lealtad_niveles
  WHERE activo AND min_visitas > p_cliente.visitas_total
  ORDER BY min_visitas ASC LIMIT 1;

  v_gan  := floor(p_cliente.visitas_total::numeric / v_meta)::int;  -- recompensas ganadas
  v_disp := GREATEST(0, v_gan - p_cliente.recompensas_usadas);       -- disponibles
  v_prog := p_cliente.visitas_total % v_meta;                        -- sellos del ciclo

  RETURN jsonb_build_object(
    'nombre', p_cliente.nombre,
    'telefono', p_cliente.telefono,
    'visitas_total', p_cliente.visitas_total,
    'nivel', COALESCE(v_nivel.nombre, 'Nuevo'),
    'nivel_beneficio', v_nivel.beneficio,
    'nivel_color', COALESCE(v_nivel.color, '#94a3b8'),
    'siguiente_nivel', v_sig.nombre,
    'faltan_siguiente_nivel', CASE WHEN v_sig.nombre IS NULL THEN NULL ELSE v_sig.min_visitas - p_cliente.visitas_total END,
    'meta_visitas', v_meta,
    'sellos', v_prog,
    'faltan_recompensa', CASE WHEN v_prog = 0 AND p_cliente.visitas_total > 0 THEN 0 ELSE v_meta - v_prog END,
    'recompensas_disponibles', v_disp
  );
END;
$$;


-- ============================================================
-- BLOQUE 6 — RPC pública: registrar una VISITA (o alta si es nuevo)
-- Devuelve status:
--   'necesita_registro' -> el teléfono no existe y no mandaron nombre
--   'registrado'        -> alta nueva (cuenta como visita 1)
--   'ok'                -> visita sumada
--   'ya_hoy'            -> ya tenía su visita del día (no suma, anti-fraude)
-- ============================================================
CREATE OR REPLACE FUNCTION public.lealtad_visita(
  p_telefono text,
  p_sucursal_codigo text DEFAULT NULL,
  p_nombre text DEFAULT NULL,
  p_cumpleanos date DEFAULT NULL,
  p_consentimiento boolean DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_tel    text;
  v_cli    lealtad_clientes%ROWTYPE;
  v_suc_id uuid;
  v_fecha  date := laola_fecha_negocio(now());
  v_hoy    int;
  v_tope   int;
  v_status text;
BEGIN
  v_tel := regexp_replace(COALESCE(p_telefono, ''), '\D', '', 'g');
  IF char_length(v_tel) <> 10 THEN
    RAISE EXCEPTION 'TELEFONO_INVALIDO';
  END IF;

  IF p_sucursal_codigo IS NOT NULL THEN
    SELECT id INTO v_suc_id FROM sucursales
    WHERE upper(prefijo_folio) = upper(trim(p_sucursal_codigo)) LIMIT 1;
  END IF;

  SELECT * INTO v_cli FROM lealtad_clientes WHERE telefono = v_tel;

  -- ¿Nuevo? Si no mandaron nombre, pedimos registro.
  IF NOT FOUND THEN
    IF NULLIF(trim(COALESCE(p_nombre, '')), '') IS NULL THEN
      RETURN jsonb_build_object('status', 'necesita_registro');
    END IF;
    IF p_consentimiento IS NOT TRUE THEN
      RAISE EXCEPTION 'CONSENTIMIENTO_REQUERIDO';
    END IF;
    INSERT INTO lealtad_clientes (
      telefono, nombre, cumpleanos, sucursal_captacion_id, sucursal_captacion_codigo,
      consentimiento_marketing, consentimiento_at, activo, visitas_total, ultima_visita
    ) VALUES (
      v_tel, trim(p_nombre), p_cumpleanos, v_suc_id, upper(trim(p_sucursal_codigo)),
      true, now(), true, 1, now()
    ) RETURNING * INTO v_cli;

    INSERT INTO lealtad_visitas (cliente_id, sucursal_id, fecha_negocio, origen)
    VALUES (v_cli.id, v_suc_id, v_fecha, 'qr');

    v_status := 'registrado';
    RETURN jsonb_build_object('status', v_status) || lealtad_perfil_json(v_cli);
  END IF;

  -- Cliente existente. Anti-fraude: ¿ya registró su(s) visita(s) de hoy?
  SELECT tope_visitas_dia INTO v_tope FROM lealtad_config WHERE id = 1;
  v_tope := GREATEST(1, COALESCE(v_tope, 1));
  SELECT count(*) INTO v_hoy FROM lealtad_visitas
  WHERE cliente_id = v_cli.id AND fecha_negocio = v_fecha;

  IF v_hoy >= v_tope THEN
    v_status := 'ya_hoy';
    RETURN jsonb_build_object('status', v_status) || lealtad_perfil_json(v_cli);
  END IF;

  -- Suma la visita
  INSERT INTO lealtad_visitas (cliente_id, sucursal_id, fecha_negocio, origen)
  VALUES (v_cli.id, v_suc_id, v_fecha, 'qr');

  UPDATE lealtad_clientes
  SET visitas_total = visitas_total + 1,
      ultima_visita = now(),
      activo = true
  WHERE id = v_cli.id
  RETURNING * INTO v_cli;

  RETURN jsonb_build_object('status', 'ok') || lealtad_perfil_json(v_cli);
END;
$$;

GRANT EXECUTE ON FUNCTION public.lealtad_visita(text, text, text, date, boolean) TO anon, authenticated;


-- ============================================================
-- BLOQUE 7 — RPC pública: consultar perfil por teléfono (solo lectura)
-- ============================================================
CREATE OR REPLACE FUNCTION public.lealtad_consultar(p_telefono text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_tel text;
  v_cli lealtad_clientes%ROWTYPE;
BEGIN
  v_tel := regexp_replace(COALESCE(p_telefono, ''), '\D', '', 'g');
  SELECT * INTO v_cli FROM lealtad_clientes WHERE telefono = v_tel;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('status', 'no_existe');
  END IF;
  RETURN jsonb_build_object('status', 'ok') || lealtad_perfil_json(v_cli);
END;
$$;

GRANT EXECUTE ON FUNCTION public.lealtad_consultar(text) TO anon, authenticated;


-- ============================================================
-- BLOQUE 8 — RPC staff: canjear una recompensa (en caja)
-- ============================================================
CREATE OR REPLACE FUNCTION public.lealtad_canjear(p_telefono text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_tel  text;
  v_cli  lealtad_clientes%ROWTYPE;
  v_meta int;
  v_disp int;
BEGIN
  v_tel := regexp_replace(COALESCE(p_telefono, ''), '\D', '', 'g');
  SELECT * INTO v_cli FROM lealtad_clientes WHERE telefono = v_tel;
  IF NOT FOUND THEN RAISE EXCEPTION 'CLIENTE_NO_ENCONTRADO'; END IF;

  SELECT GREATEST(1, meta_visitas) INTO v_meta FROM lealtad_config WHERE id = 1;
  v_disp := GREATEST(0, floor(v_cli.visitas_total::numeric / v_meta)::int - v_cli.recompensas_usadas);
  IF v_disp <= 0 THEN RAISE EXCEPTION 'SIN_RECOMPENSAS'; END IF;

  UPDATE lealtad_clientes SET recompensas_usadas = recompensas_usadas + 1
  WHERE id = v_cli.id RETURNING * INTO v_cli;

  RETURN jsonb_build_object('status', 'ok') || lealtad_perfil_json(v_cli);
END;
$$;

GRANT EXECUTE ON FUNCTION public.lealtad_canjear(text) TO authenticated;
