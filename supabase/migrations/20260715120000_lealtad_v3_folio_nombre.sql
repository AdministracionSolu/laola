-- ============================================================
-- LEALTAD v3 — Folio del ticket + nombre estructurado + nacimiento
--
-- Cambios sobre v2 (por visitas):
--   1) El QR va impreso en el TICKET (uno por sucursal). Para contar la
--      visita el cliente teclea el FOLIO de su ticket + su teléfono.
--      Blindaje: un folio solo cuenta UNA visita por sucursal por día de
--      negocio. Así un ticket real = una visita, y dos tickets reales del
--      mismo día = dos visitas, pero no se puede re-escanear el mismo.
--      (El folio del ticket físico NO vive en Supabase, así que se valida
--       por unicidad, no contra una tabla fuente.)
--   2) Nombre estructurado obligatorio: primer nombre (obl), segundo
--      nombre (opc), apellido paterno (obl), apellido materno (obl).
--      Evita nombres incompletos.
--   3) Fecha de nacimiento obligatoria (día/mes/año).
--
-- El tope de visitas/día por teléfono pasa a ser un cap suave anti-farmeo
-- (permite varios tickets al día), NO el control principal.
--
-- Día de negocio: corte 4 AM (laola_fecha_negocio, ya existe).
-- ============================================================


-- ============================================================
-- BLOQUE 1 — Nombre estructurado en el cliente
-- ============================================================
ALTER TABLE public.lealtad_clientes
  ADD COLUMN IF NOT EXISTS primer_nombre    text,
  ADD COLUMN IF NOT EXISTS segundo_nombre   text,
  ADD COLUMN IF NOT EXISTS apellido_paterno text,
  ADD COLUMN IF NOT EXISTS apellido_materno text;


-- ============================================================
-- BLOQUE 2 — Folio del ticket en el historial de visitas
-- ============================================================
ALTER TABLE public.lealtad_visitas
  ADD COLUMN IF NOT EXISTS folio      text,
  ADD COLUMN IF NOT EXISTS folio_norm text;

-- Un folio solo puede contar UNA visita por sucursal por día de negocio.
-- COALESCE para que sucursal NULL no se salte el candado (NULLS DISTINCT).
CREATE UNIQUE INDEX IF NOT EXISTS lealtad_visitas_folio_uniq
  ON public.lealtad_visitas (COALESCE(sucursal_id::text, ''), fecha_negocio, folio_norm)
  WHERE folio_norm IS NOT NULL;


-- ============================================================
-- BLOQUE 3 — Helper de perfil (agrega primer_nombre para el saludo)
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

  SELECT nombre, beneficio, color INTO v_nivel
  FROM lealtad_niveles
  WHERE activo AND min_visitas <= p_cliente.visitas_total
  ORDER BY min_visitas DESC LIMIT 1;

  SELECT nombre, min_visitas INTO v_sig
  FROM lealtad_niveles
  WHERE activo AND min_visitas > p_cliente.visitas_total
  ORDER BY min_visitas ASC LIMIT 1;

  v_gan  := floor(p_cliente.visitas_total::numeric / v_meta)::int;
  v_disp := GREATEST(0, v_gan - p_cliente.recompensas_usadas);
  v_prog := p_cliente.visitas_total % v_meta;

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
    'meta_visitas', v_meta,
    'sellos', v_prog,
    'faltan_recompensa', CASE WHEN v_prog = 0 AND p_cliente.visitas_total > 0 THEN 0 ELSE v_meta - v_prog END,
    'recompensas_disponibles', v_disp
  );
END;
$$;


-- ============================================================
-- BLOQUE 4 — RPC pública: registrar VISITA por FOLIO
-- (reemplaza la firma vieja de v2)
--
-- Devuelve status:
--   'necesita_registro' -> teléfono nuevo y no mandaron nombre completo
--   'registrado'        -> alta nueva (cuenta como visita 1)
--   'ok'                -> visita sumada
--   'ya_hoy'            -> tope diario alcanzado (o ya contó ESTE folio)
--   'folio_usado'       -> ese folio ya lo registró alguien más
-- Errores (RAISE): TELEFONO_INVALIDO, FOLIO_REQUERIDO, CUMPLE_REQUERIDO,
--                  CONSENTIMIENTO_REQUERIDO, NOMBRE_INCOMPLETO
-- ============================================================
DROP FUNCTION IF EXISTS public.lealtad_visita(text, text, text, date, boolean);

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
  -- Teléfono a 10 dígitos
  v_tel := regexp_replace(COALESCE(p_telefono, ''), '\D', '', 'g');
  IF char_length(v_tel) <> 10 THEN
    RAISE EXCEPTION 'TELEFONO_INVALIDO';
  END IF;

  -- Folio: limpia espacios y mayúsculas
  v_folio_norm := upper(regexp_replace(COALESCE(p_folio, ''), '\s', '', 'g'));
  IF v_folio_norm = '' THEN
    RAISE EXCEPTION 'FOLIO_REQUERIDO';
  END IF;
  IF char_length(v_folio_norm) > 40 THEN
    RAISE EXCEPTION 'FOLIO_INVALIDO';
  END IF;

  -- Sucursal (del QR)
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
    -- Si fue el MISMO cliente, le mostramos su progreso (doble tap, no error).
    SELECT * INTO v_cli FROM lealtad_clientes WHERE telefono = v_tel;
    IF FOUND AND v_cli.id = v_prev.cliente_id THEN
      RETURN jsonb_build_object('status', 'ya_hoy') || lealtad_perfil_json(v_cli);
    END IF;
    RETURN jsonb_build_object('status', 'folio_usado');
  END IF;

  -- Cliente por teléfono
  SELECT * INTO v_cli FROM lealtad_clientes WHERE telefono = v_tel;

  -- ---------- Cliente NUEVO ----------
  IF NOT FOUND THEN
    -- Sin nombre completo -> pedir registro (aún no consumimos el folio)
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
  -- Cap suave diario por teléfono (anti-farmeo).
  SELECT tope_visitas_dia INTO v_tope FROM lealtad_config WHERE id = 1;
  v_tope := GREATEST(1, COALESCE(v_tope, 1));
  SELECT count(*) INTO v_hoy FROM lealtad_visitas
  WHERE cliente_id = v_cli.id AND fecha_negocio = v_fecha;

  IF v_hoy >= v_tope THEN
    RETURN jsonb_build_object('status', 'ya_hoy') || lealtad_perfil_json(v_cli);
  END IF;

  -- Completa datos que falten (perfiles viejos sin nombre estructurado / sin cumple)
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

GRANT EXECUTE ON FUNCTION public.lealtad_visita(text, text, text, text, text, text, text, date, boolean)
  TO anon, authenticated;
