-- ============================================================
-- LEALTAD v4 — CICLO DE RECOMPENSAS EN LOOP + AÑO NATURAL
--
-- Sobre v3 (folio + nombre estructurado). Cambios:
--   1) Ciclo: cada 3 visitas = 1 recompensa. 4 recompensas escalonadas
--      que rotan en loop (1→2→3→4→1→...). Catálogo editable.
--   2) Vigencia por AÑO NATURAL: visitas y canjes se derivan filtrando
--      por el año de fecha_negocio. El 1 de enero todo arranca en cero
--      solo (no hay job de reset). Recompensas no canjeadas caducan
--      el 31-dic.
--   3) Regalo de bienvenida (una vez, de por vida, NO se resetea):
--      balazo + bebida al inscribirse.
--   4) Canje SELF-SERVE del cliente: botón "Canjear" deja registro en
--      lealtad_canjes para empatar a diario contra el comandero.
--      La ELECCIÓN entre opciones (michelada vs limonada) se hace en
--      el comandero, NO aquí: La Ola solo muestra qué toca.
--   5) Intentos rechazados (folio_usado / ya_hoy) se guardan en
--      lealtad_intentos para la pestaña Anomalías.
--   6) meta_visitas pasa a 3; tope 1 visita/día por teléfono = regla dura.
--
-- Niveles (Nuevo/Frecuente/Oro/Platino) siguen siendo DE POR VIDA.
-- ============================================================


-- ============================================================
-- BLOQUE 1 — Catálogo del ciclo de recompensas
-- ============================================================
CREATE TABLE IF NOT EXISTS public.lealtad_recompensas (
  posicion   int PRIMARY KEY CHECK (posicion BETWEEN 1 AND 20),
  titulo     text NOT NULL,        -- lo que ve el cliente ("Michelada o limonada")
  activo     boolean NOT NULL DEFAULT true,
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.lealtad_recompensas ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "todos_leen_recompensas" ON public.lealtad_recompensas;
CREATE POLICY "todos_leen_recompensas" ON public.lealtad_recompensas
  FOR SELECT TO anon, authenticated USING (true);
DROP POLICY IF EXISTS "staff_edita_recompensas" ON public.lealtad_recompensas;
CREATE POLICY "staff_edita_recompensas" ON public.lealtad_recompensas
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

INSERT INTO public.lealtad_recompensas (posicion, titulo) VALUES
  (1, 'Michelada o limonada'),
  (2, 'Postre de la casa o taco gobernador'),
  (3, 'Cubeta de cerveza nacional (media) o paté de camarón mediano'),
  (4, 'Tostada La Ola')
ON CONFLICT (posicion) DO NOTHING;


-- ============================================================
-- BLOQUE 2 — Historial de canjes (el registro para empatar vs comandero)
-- posicion 0 = regalo de bienvenida; 1..N = posición del ciclo.
-- ============================================================
CREATE TABLE IF NOT EXISTS public.lealtad_canjes (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  cliente_id    uuid NOT NULL REFERENCES public.lealtad_clientes(id) ON DELETE CASCADE,
  posicion      int NOT NULL CHECK (posicion BETWEEN 0 AND 20),
  titulo        text NOT NULL,     -- snapshot del catálogo al momento del canje
  sucursal_id   uuid REFERENCES public.sucursales(id),
  fecha_negocio date NOT NULL,
  origen        text NOT NULL DEFAULT 'cliente' CHECK (origen IN ('cliente', 'staff')),
  created_at    timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS lealtad_canjes_dia_idx ON public.lealtad_canjes (fecha_negocio, sucursal_id);
CREATE INDEX IF NOT EXISTS lealtad_canjes_cliente_idx ON public.lealtad_canjes (cliente_id, created_at DESC);

ALTER TABLE public.lealtad_canjes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "staff_lee_canjes" ON public.lealtad_canjes;
CREATE POLICY "staff_lee_canjes" ON public.lealtad_canjes
  FOR SELECT TO authenticated USING (true);
-- anon NO toca directo: entra por RPC.


-- ============================================================
-- BLOQUE 3 — Bienvenida (una vez de por vida) + intentos rechazados
-- ============================================================
ALTER TABLE public.lealtad_clientes
  ADD COLUMN IF NOT EXISTS bienvenida_canjeada_at timestamptz;

CREATE TABLE IF NOT EXISTS public.lealtad_intentos (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  telefono      text NOT NULL,
  folio_norm    text,
  sucursal_id   uuid REFERENCES public.sucursales(id),
  motivo        text NOT NULL,     -- 'ya_hoy' | 'folio_usado'
  fecha_negocio date NOT NULL,
  created_at    timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS lealtad_intentos_tel_idx ON public.lealtad_intentos (telefono, created_at DESC);
CREATE INDEX IF NOT EXISTS lealtad_intentos_dia_idx ON public.lealtad_intentos (fecha_negocio);

ALTER TABLE public.lealtad_intentos ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "staff_lee_intentos" ON public.lealtad_intentos;
CREATE POLICY "staff_lee_intentos" ON public.lealtad_intentos
  FOR SELECT TO authenticated USING (true);

-- meta del ciclo: 3 visitas por recompensa; tope diario 1 = regla dura
UPDATE public.lealtad_config SET meta_visitas = 3, tope_visitas_dia = 1, updated_at = now() WHERE id = 1;


-- ============================================================
-- BLOQUE 4 — Perfil v4 (todo el ciclo se deriva POR AÑO NATURAL)
-- ============================================================
CREATE OR REPLACE FUNCTION public.lealtad_perfil_json(p_cliente public.lealtad_clientes)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SET search_path = public
AS $$
DECLARE
  v_meta     int;
  v_nivel    record;
  v_sig      record;
  v_anio     int := EXTRACT(YEAR FROM laola_fecha_negocio(now()))::int;
  v_vis_anio int;
  v_can_anio int;
  v_gan      int;
  v_disp     int;
  v_prog     int;
  v_pos      int;
  v_rec      record;
  v_recs     jsonb;
  v_n_recs   int;
BEGIN
  SELECT GREATEST(1, COALESCE(meta_visitas, 3)) INTO v_meta FROM lealtad_config WHERE id = 1;
  v_meta := COALESCE(v_meta, 3);

  -- Nivel (de por vida, sobre visitas_total)
  SELECT nombre, beneficio, color INTO v_nivel
  FROM lealtad_niveles
  WHERE activo AND min_visitas <= p_cliente.visitas_total
  ORDER BY min_visitas DESC LIMIT 1;

  SELECT nombre, min_visitas INTO v_sig
  FROM lealtad_niveles
  WHERE activo AND min_visitas > p_cliente.visitas_total
  ORDER BY min_visitas ASC LIMIT 1;

  -- Ciclo del AÑO en curso
  SELECT count(*) INTO v_vis_anio FROM lealtad_visitas
  WHERE cliente_id = p_cliente.id AND EXTRACT(YEAR FROM fecha_negocio)::int = v_anio;

  SELECT count(*) INTO v_can_anio FROM lealtad_canjes
  WHERE cliente_id = p_cliente.id AND posicion > 0
    AND EXTRACT(YEAR FROM fecha_negocio)::int = v_anio;

  v_gan  := floor(v_vis_anio::numeric / v_meta)::int;
  v_disp := GREATEST(0, v_gan - v_can_anio);
  v_prog := v_vis_anio % v_meta;

  -- Recompensa que toca: posición (canjes del año % total activas) + 1,
  -- mapeada sobre el catálogo activo ordenado (aguanta huecos).
  SELECT count(*) INTO v_n_recs FROM lealtad_recompensas WHERE activo;
  IF v_n_recs > 0 THEN
    SELECT posicion, titulo INTO v_rec
    FROM (
      SELECT posicion, titulo, row_number() OVER (ORDER BY posicion) AS rn
      FROM lealtad_recompensas WHERE activo
    ) t
    WHERE t.rn = (v_can_anio % v_n_recs) + 1;
  END IF;

  RETURN jsonb_build_object(
    'nombre', p_cliente.nombre,
    'primer_nombre', COALESCE(p_cliente.primer_nombre, split_part(p_cliente.nombre, ' ', 1)),
    'telefono', p_cliente.telefono,
    'visitas_total', p_cliente.visitas_total,
    'nivel', COALESCE(v_nivel.nombre, 'Nuevo'),
    'nivel_beneficio', v_nivel.beneficio,
    'nivel_color', COALESCE(v_nivel.color, '#94a3b8'),
    'siguiente_nivel', v_sig.nombre,
    'faltan_siguiente_nivel', CASE WHEN v_sig.nombre IS NULL THEN NULL ELSE v_sig.min_visitas - p_cliente.visitas_total END,
    'anio', v_anio,
    'visitas_anio', v_vis_anio,
    'meta_visitas', v_meta,
    'sellos', v_prog,
    'faltan_recompensa', CASE WHEN v_disp > 0 THEN 0 ELSE v_meta - v_prog END,
    'recompensas_disponibles', v_disp,
    'recompensa_posicion', v_rec.posicion,
    'recompensa_titulo', v_rec.titulo,
    'bienvenida_disponible', (p_cliente.bienvenida_canjeada_at IS NULL)
  );
END;
$$;


-- ============================================================
-- BLOQUE 5 — lealtad_visita: igual que v3 + log de intentos rechazados
-- ============================================================
CREATE OR REPLACE FUNCTION public.lealtad_visita(
  p_telefono         text,
  p_sucursal_codigo  text DEFAULT NULL,
  p_folio            text DEFAULT NULL,
  p_primer_nombre    text DEFAULT NULL,
  p_segundo_nombre   text DEFAULT NULL,
  p_apellido_paterno text DEFAULT NULL,
  p_apellido_materno text DEFAULT NULL,
  p_cumpleanos       date DEFAULT NULL,
  p_consentimiento   boolean DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_tel        text;
  v_folio_norm text;
  v_cli        lealtad_clientes%ROWTYPE;
  v_prev       lealtad_visitas%ROWTYPE;
  v_suc_id     uuid;
  v_fecha      date := laola_fecha_negocio(now());
  v_hoy        int;
  v_tope       int;
  v_nombre     text;
BEGIN
  v_tel := regexp_replace(COALESCE(p_telefono, ''), '\D', '', 'g');
  IF char_length(v_tel) <> 10 THEN
    RAISE EXCEPTION 'TELEFONO_INVALIDO';
  END IF;

  v_folio_norm := upper(regexp_replace(COALESCE(p_folio, ''), '\s', '', 'g'));
  IF v_folio_norm = '' THEN
    RAISE EXCEPTION 'FOLIO_REQUERIDO';
  END IF;
  IF char_length(v_folio_norm) > 40 THEN
    RAISE EXCEPTION 'FOLIO_INVALIDO';
  END IF;

  IF p_sucursal_codigo IS NOT NULL THEN
    SELECT id INTO v_suc_id FROM sucursales
    WHERE upper(prefijo_folio) = upper(trim(p_sucursal_codigo)) LIMIT 1;
  END IF;

  -- ¿El folio ya se usó hoy en esta sucursal?
  SELECT * INTO v_prev FROM lealtad_visitas
  WHERE COALESCE(sucursal_id::text, '') = COALESCE(v_suc_id::text, '')
    AND fecha_negocio = v_fecha
    AND folio_norm = v_folio_norm
  LIMIT 1;

  IF FOUND THEN
    SELECT * INTO v_cli FROM lealtad_clientes WHERE telefono = v_tel;
    IF FOUND AND v_cli.id = v_prev.cliente_id THEN
      RETURN jsonb_build_object('status', 'ya_hoy') || lealtad_perfil_json(v_cli);
    END IF;
    -- OTRO teléfono intentó usar un folio ya registrado: evidencia de anomalía
    INSERT INTO lealtad_intentos (telefono, folio_norm, sucursal_id, motivo, fecha_negocio)
    VALUES (v_tel, v_folio_norm, v_suc_id, 'folio_usado', v_fecha);
    RETURN jsonb_build_object('status', 'folio_usado');
  END IF;

  SELECT * INTO v_cli FROM lealtad_clientes WHERE telefono = v_tel;

  -- ---------- Cliente NUEVO ----------
  IF NOT FOUND THEN
    IF NULLIF(trim(COALESCE(p_primer_nombre, '')), '') IS NULL
       OR NULLIF(trim(COALESCE(p_apellido_paterno, '')), '') IS NULL
       OR NULLIF(trim(COALESCE(p_apellido_materno, '')), '') IS NULL THEN
      RETURN jsonb_build_object('status', 'necesita_registro');
    END IF;

    IF p_cumpleanos IS NULL THEN
      RAISE EXCEPTION 'CUMPLE_REQUERIDO';
    END IF;
    IF p_consentimiento IS NOT TRUE THEN
      RAISE EXCEPTION 'CONSENTIMIENTO_REQUERIDO';
    END IF;

    v_nombre := btrim(regexp_replace(
      concat_ws(' ',
        trim(p_primer_nombre),
        NULLIF(trim(COALESCE(p_segundo_nombre, '')), ''),
        trim(p_apellido_paterno),
        trim(p_apellido_materno)),
      '\s+', ' ', 'g'));

    INSERT INTO lealtad_clientes (
      telefono, nombre, primer_nombre, segundo_nombre, apellido_paterno, apellido_materno,
      cumpleanos, sucursal_captacion_id, sucursal_captacion_codigo,
      consentimiento_marketing, consentimiento_at, activo, visitas_total, ultima_visita
    ) VALUES (
      v_tel, v_nombre, trim(p_primer_nombre), NULLIF(trim(COALESCE(p_segundo_nombre, '')), ''),
      trim(p_apellido_paterno), trim(p_apellido_materno),
      p_cumpleanos, v_suc_id, upper(trim(p_sucursal_codigo)),
      true, now(), true, 1, now()
    ) RETURNING * INTO v_cli;

    INSERT INTO lealtad_visitas (cliente_id, sucursal_id, fecha_negocio, origen, folio, folio_norm)
    VALUES (v_cli.id, v_suc_id, v_fecha, 'qr', trim(p_folio), v_folio_norm);

    RETURN jsonb_build_object('status', 'registrado') || lealtad_perfil_json(v_cli);
  END IF;

  -- ---------- Cliente EXISTENTE ----------
  SELECT tope_visitas_dia INTO v_tope FROM lealtad_config WHERE id = 1;
  v_tope := GREATEST(1, COALESCE(v_tope, 1));
  SELECT count(*) INTO v_hoy FROM lealtad_visitas
  WHERE cliente_id = v_cli.id AND fecha_negocio = v_fecha;

  IF v_hoy >= v_tope THEN
    -- Regla dura: 1 folio por teléfono por día. Guardamos el intento.
    INSERT INTO lealtad_intentos (telefono, folio_norm, sucursal_id, motivo, fecha_negocio)
    VALUES (v_tel, v_folio_norm, v_suc_id, 'ya_hoy', v_fecha);
    RETURN jsonb_build_object('status', 'ya_hoy') || lealtad_perfil_json(v_cli);
  END IF;

  IF v_cli.primer_nombre IS NULL AND NULLIF(trim(COALESCE(p_primer_nombre, '')), '') IS NOT NULL
     AND NULLIF(trim(COALESCE(p_apellido_paterno, '')), '') IS NOT NULL THEN
    UPDATE lealtad_clientes SET
      primer_nombre    = trim(p_primer_nombre),
      segundo_nombre   = NULLIF(trim(COALESCE(p_segundo_nombre, '')), ''),
      apellido_paterno = trim(p_apellido_paterno),
      apellido_materno = NULLIF(trim(COALESCE(p_apellido_materno, '')), ''),
      cumpleanos       = COALESCE(cumpleanos, p_cumpleanos)
    WHERE id = v_cli.id;
  END IF;

  INSERT INTO lealtad_visitas (cliente_id, sucursal_id, fecha_negocio, origen, folio, folio_norm)
  VALUES (v_cli.id, v_suc_id, v_fecha, 'qr', trim(p_folio), v_folio_norm);

  UPDATE lealtad_clientes
  SET visitas_total = visitas_total + 1,
      ultima_visita = now(),
      activo = true
  WHERE id = v_cli.id
  RETURNING * INTO v_cli;

  RETURN jsonb_build_object('status', 'ok') || lealtad_perfil_json(v_cli);
END;
$$;


-- ============================================================
-- BLOQUE 6 — RPC pública: canje SELF-SERVE del cliente
-- El cliente pulsa "Ya lo canjeé" frente al mesero. Deja registro
-- en lealtad_canjes para empatar contra el comandero.
-- ============================================================
CREATE OR REPLACE FUNCTION public.lealtad_canjear_cliente(
  p_telefono        text,
  p_sucursal_codigo text DEFAULT NULL
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
  v_anio   int  := EXTRACT(YEAR FROM laola_fecha_negocio(now()))::int;
  v_meta   int;
  v_vis    int;
  v_can    int;
  v_disp   int;
  v_n_recs int;
  v_rec    record;
BEGIN
  v_tel := regexp_replace(COALESCE(p_telefono, ''), '\D', '', 'g');
  SELECT * INTO v_cli FROM lealtad_clientes WHERE telefono = v_tel;
  IF NOT FOUND THEN RAISE EXCEPTION 'CLIENTE_NO_ENCONTRADO'; END IF;

  IF p_sucursal_codigo IS NOT NULL THEN
    SELECT id INTO v_suc_id FROM sucursales
    WHERE upper(prefijo_folio) = upper(trim(p_sucursal_codigo)) LIMIT 1;
  END IF;

  SELECT GREATEST(1, COALESCE(meta_visitas, 3)) INTO v_meta FROM lealtad_config WHERE id = 1;

  SELECT count(*) INTO v_vis FROM lealtad_visitas
  WHERE cliente_id = v_cli.id AND EXTRACT(YEAR FROM fecha_negocio)::int = v_anio;
  SELECT count(*) INTO v_can FROM lealtad_canjes
  WHERE cliente_id = v_cli.id AND posicion > 0
    AND EXTRACT(YEAR FROM fecha_negocio)::int = v_anio;

  v_disp := GREATEST(0, floor(v_vis::numeric / v_meta)::int - v_can);
  IF v_disp <= 0 THEN RAISE EXCEPTION 'SIN_RECOMPENSAS'; END IF;

  SELECT count(*) INTO v_n_recs FROM lealtad_recompensas WHERE activo;
  IF v_n_recs = 0 THEN RAISE EXCEPTION 'SIN_CATALOGO'; END IF;

  SELECT posicion, titulo INTO v_rec
  FROM (
    SELECT posicion, titulo, row_number() OVER (ORDER BY posicion) AS rn
    FROM lealtad_recompensas WHERE activo
  ) t
  WHERE t.rn = (v_can % v_n_recs) + 1;

  INSERT INTO lealtad_canjes (cliente_id, posicion, titulo, sucursal_id, fecha_negocio, origen)
  VALUES (v_cli.id, v_rec.posicion, v_rec.titulo, v_suc_id, v_fecha, 'cliente');

  RETURN jsonb_build_object('status', 'canjeado', 'canje_titulo', v_rec.titulo, 'canje_posicion', v_rec.posicion)
    || lealtad_perfil_json(v_cli);
END;
$$;

GRANT EXECUTE ON FUNCTION public.lealtad_canjear_cliente(text, text) TO anon, authenticated;


-- ============================================================
-- BLOQUE 7 — RPC pública: canje del regalo de BIENVENIDA (una vez)
-- ============================================================
CREATE OR REPLACE FUNCTION public.lealtad_canjear_bienvenida(
  p_telefono        text,
  p_sucursal_codigo text DEFAULT NULL
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
BEGIN
  v_tel := regexp_replace(COALESCE(p_telefono, ''), '\D', '', 'g');
  SELECT * INTO v_cli FROM lealtad_clientes WHERE telefono = v_tel;
  IF NOT FOUND THEN RAISE EXCEPTION 'CLIENTE_NO_ENCONTRADO'; END IF;
  IF v_cli.bienvenida_canjeada_at IS NOT NULL THEN RAISE EXCEPTION 'BIENVENIDA_YA_CANJEADA'; END IF;

  IF p_sucursal_codigo IS NOT NULL THEN
    SELECT id INTO v_suc_id FROM sucursales
    WHERE upper(prefijo_folio) = upper(trim(p_sucursal_codigo)) LIMIT 1;
  END IF;

  UPDATE lealtad_clientes SET bienvenida_canjeada_at = now()
  WHERE id = v_cli.id RETURNING * INTO v_cli;

  INSERT INTO lealtad_canjes (cliente_id, posicion, titulo, sucursal_id, fecha_negocio, origen)
  VALUES (v_cli.id, 0, 'Bienvenida: balazo + bebida', v_suc_id, v_fecha, 'cliente');

  RETURN jsonb_build_object('status', 'canjeado', 'canje_titulo', 'Bienvenida: balazo + bebida', 'canje_posicion', 0)
    || lealtad_perfil_json(v_cli);
END;
$$;

GRANT EXECUTE ON FUNCTION public.lealtad_canjear_bienvenida(text, text) TO anon, authenticated;


-- ============================================================
-- BLOQUE 8 — Canje de STAFF pasa a registrar en lealtad_canjes
-- (misma firma que v2; ahora deriva por año y deja registro)
-- ============================================================
CREATE OR REPLACE FUNCTION public.lealtad_canjear(p_telefono text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_tel    text;
  v_cli    lealtad_clientes%ROWTYPE;
  v_anio   int := EXTRACT(YEAR FROM laola_fecha_negocio(now()))::int;
  v_fecha  date := laola_fecha_negocio(now());
  v_meta   int;
  v_vis    int;
  v_can    int;
  v_disp   int;
  v_n_recs int;
  v_rec    record;
BEGIN
  v_tel := regexp_replace(COALESCE(p_telefono, ''), '\D', '', 'g');
  SELECT * INTO v_cli FROM lealtad_clientes WHERE telefono = v_tel;
  IF NOT FOUND THEN RAISE EXCEPTION 'CLIENTE_NO_ENCONTRADO'; END IF;

  SELECT GREATEST(1, COALESCE(meta_visitas, 3)) INTO v_meta FROM lealtad_config WHERE id = 1;

  SELECT count(*) INTO v_vis FROM lealtad_visitas
  WHERE cliente_id = v_cli.id AND EXTRACT(YEAR FROM fecha_negocio)::int = v_anio;
  SELECT count(*) INTO v_can FROM lealtad_canjes
  WHERE cliente_id = v_cli.id AND posicion > 0
    AND EXTRACT(YEAR FROM fecha_negocio)::int = v_anio;

  v_disp := GREATEST(0, floor(v_vis::numeric / v_meta)::int - v_can);
  IF v_disp <= 0 THEN RAISE EXCEPTION 'SIN_RECOMPENSAS'; END IF;

  SELECT count(*) INTO v_n_recs FROM lealtad_recompensas WHERE activo;
  IF v_n_recs = 0 THEN RAISE EXCEPTION 'SIN_CATALOGO'; END IF;

  SELECT posicion, titulo INTO v_rec
  FROM (
    SELECT posicion, titulo, row_number() OVER (ORDER BY posicion) AS rn
    FROM lealtad_recompensas WHERE activo
  ) t
  WHERE t.rn = (v_can % v_n_recs) + 1;

  INSERT INTO lealtad_canjes (cliente_id, posicion, titulo, sucursal_id, fecha_negocio, origen)
  VALUES (v_cli.id, v_rec.posicion, v_rec.titulo, NULL, v_fecha, 'staff');

  RETURN jsonb_build_object('status', 'ok', 'canje_titulo', v_rec.titulo) || lealtad_perfil_json(v_cli);
END;
$$;
