-- ============================================================
-- BLINDAJE DEL FOLIO (lealtad v5)
--
-- Dos huecos que tenía la v4:
--
--   1. El folio solo era único POR DÍA. Con guardar un ticket y
--      volver a teclear el mismo folio mañana, contaba otra visita.
--      Ahora un folio se consume UNA VEZ por sucursal, con ventana
--      de 180 días (por si el punto de venta reinicia su contador).
--
--   2. Cualquier cosa pasaba como folio: "1", "AAA", "1234".
--      Ahora tiene que parecer folio: al menos 4 dígitos, y se
--      rechazan los inventados de teclado (todos los dígitos
--      iguales o secuencias corridas tipo 1234 / 4321).
--
-- Todo rechazo queda en lealtad_intentos, que es lo que alimenta la
-- pestaña de Anomalías. Motivos nuevos: 'folio_invalido' y
-- 'folio_repetido'.
--
-- Lo que NO resuelve esto: un folio inventado que sí parezca folio
-- (196814 cuando el real era 196813). Para eso hace falta capturar
-- el folio de cierre en el corte y validar contra el rango. Va aparte.
-- ============================================================


-- ============================================================
-- BLOQUE 1 — Índice para buscar folios usados por sucursal
-- ============================================================
CREATE INDEX IF NOT EXISTS lealtad_visitas_folio_suc_idx
  ON public.lealtad_visitas (sucursal_id, folio_norm, fecha_negocio DESC);


-- ============================================================
-- BLOQUE 2 — ¿Esto parece un folio de ticket?
-- Devuelve NULL si está bien, o el motivo del rechazo.
-- ============================================================
CREATE OR REPLACE FUNCTION public.lealtad_folio_sospechoso(p_folio_norm text)
RETURNS text
LANGUAGE plpgsql
IMMUTABLE
SET search_path = public
AS $$
DECLARE
  v_digitos text := regexp_replace(COALESCE(p_folio_norm, ''), '\D', '', 'g');
  v_asc     text := '01234567890123456789';
  v_desc    text := '98765432109876543210';
BEGIN
  -- Un ticket real trae número. Menos de 4 dígitos no es folio.
  IF char_length(v_digitos) < 4 THEN RETURN 'muy_corto'; END IF;

  -- 1111, 000000, 55555: teclado, no ticket.
  IF v_digitos ~ ('^(' || substr(v_digitos, 1, 1) || ')+$') THEN RETURN 'repetido'; END IF;

  -- 1234, 123456, 4321: secuencia corrida.
  IF position(v_digitos in v_asc) > 0 OR position(v_digitos in v_desc) > 0 THEN
    RETURN 'secuencia';
  END IF;

  RETURN NULL;
END;
$$;

REVOKE ALL ON FUNCTION public.lealtad_folio_sospechoso(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.lealtad_folio_sospechoso(text) TO anon, authenticated;


-- ============================================================
-- BLOQUE 3 — lealtad_visita v5
-- Igual que v4 salvo las dos validaciones nuevas del folio.
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
  v_mal        text;
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

  -- NUEVO: ¿tiene forma de folio de ticket?
  v_mal := lealtad_folio_sospechoso(v_folio_norm);
  IF v_mal IS NOT NULL THEN
    INSERT INTO lealtad_intentos (telefono, folio_norm, sucursal_id, motivo, fecha_negocio)
    VALUES (v_tel, v_folio_norm, v_suc_id, 'folio_invalido', v_fecha);
    RETURN jsonb_build_object('status', 'folio_invalido');
  END IF;

  -- ¿El folio ya se usó HOY en esta sucursal?
  SELECT * INTO v_prev FROM lealtad_visitas
  WHERE COALESCE(sucursal_id::text, '') = COALESCE(v_suc_id::text, '')
    AND fecha_negocio = v_fecha
    AND folio_norm = v_folio_norm
  LIMIT 1;

  IF FOUND THEN
    -- Mismo cliente el mismo día: es doble tap, le mostramos su progreso.
    SELECT * INTO v_cli FROM lealtad_clientes WHERE telefono = v_tel;
    IF FOUND AND v_cli.id = v_prev.cliente_id THEN
      RETURN jsonb_build_object('status', 'ya_hoy') || lealtad_perfil_json(v_cli);
    END IF;
    INSERT INTO lealtad_intentos (telefono, folio_norm, sucursal_id, motivo, fecha_negocio)
    VALUES (v_tel, v_folio_norm, v_suc_id, 'folio_usado', v_fecha);
    RETURN jsonb_build_object('status', 'folio_usado');
  END IF;

  -- NUEVO: ¿ese folio ya se consumió ANTES en esta sucursal?
  -- Un ticket vale una vez, no una por día. Ventana de 180 días por si
  -- el punto de venta reinicia su contador.
  IF EXISTS (
    SELECT 1 FROM lealtad_visitas
    WHERE COALESCE(sucursal_id::text, '') = COALESCE(v_suc_id::text, '')
      AND folio_norm = v_folio_norm
      AND fecha_negocio >= v_fecha - 180
  ) THEN
    INSERT INTO lealtad_intentos (telefono, folio_norm, sucursal_id, motivo, fecha_negocio)
    VALUES (v_tel, v_folio_norm, v_suc_id, 'folio_repetido', v_fecha);
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
