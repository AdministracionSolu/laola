-- ============================================================
-- FACTURACIÓN v8 — un ticket sólo se factura UNA vez por sucursal
-- El folio del ticket se repite entre sucursales (cada POS lleva su
-- propia numeración: hoy mismo el 42808 existe en CER y en VAL), así
-- que el candado es por (sucursal, folio), nunca global.
-- Una solicitud RECHAZADA libera el folio: es el caso real de quien se
-- equivoca de sucursal, la contadora rechaza y el cliente reintenta.
--
-- Piezas:
--   1. factura_ticket_norm()  — normaliza el folio (0154 = 154 = "154 ")
--   2. ticket_folio_norm      — columna generada, imposible de saltar
--   3. índice único parcial   — la garantía dura, aun con dos envíos a la vez
--   4. factura_solicitar v8   — avisa bonito: TICKET_YA_USADO
--   5. factura_ticket_disponible() — el front pregunta ANTES de subir la foto
--      (el bucket no da DELETE: una foto de más se queda ahí para siempre)
--
-- Se aplica en BLOQUES, en este orden. Verificado el 19-ago-2026: no hay
-- duplicados vivos en la tabla, el índice entra limpio.
-- ============================================================

-- ---------- BLOQUE 1: normalizador del folio ----------
-- IMMUTABLE porque lo usan una columna generada y un índice.
-- Sin qualifiers: con search_path = '' sigue viéndose pg_catalog (implícito).
CREATE OR REPLACE FUNCTION public.factura_ticket_norm(p_folio text)
RETURNS text
LANGUAGE sql
IMMUTABLE
PARALLEL SAFE
SET search_path = ''
AS $norm$
  SELECT CASE
           WHEN d = '' THEN NULL
           -- Folio numérico: los ceros a la izquierda no hacen otro ticket.
           WHEN d ~ '^[0-9]+$' THEN COALESCE(NULLIF(ltrim(d, '0'), ''), '0')
           ELSE d
         END
  FROM (
    SELECT regexp_replace(upper(COALESCE(p_folio, '')), '[^A-Z0-9]', '', 'g') AS d
  ) s;
$norm$;

-- ---------- BLOQUE 2: columna generada con el folio normalizado ----------
ALTER TABLE public.factura_solicitudes
  ADD COLUMN IF NOT EXISTS ticket_folio_norm text
  GENERATED ALWAYS AS (public.factura_ticket_norm(ticket_folio)) STORED;

-- ---------- BLOQUE 3: el candado ----------
-- Parcial: las rechazadas no ocupan el folio.
CREATE UNIQUE INDEX IF NOT EXISTS factura_solicitudes_ticket_unico_idx
  ON public.factura_solicitudes (sucursal_codigo, ticket_folio_norm)
  WHERE estado <> 'rechazada' AND ticket_folio_norm IS NOT NULL;

-- ---------- BLOQUE 4: RPC de solicitud v8 ----------
-- Misma firma que v7 → CREATE OR REPLACE basta (sin DROP ni GRANT).
CREATE OR REPLACE FUNCTION public.factura_solicitar(
  p_rfc text,
  p_razon_social text,
  p_regimen_fiscal text,
  p_codigo_postal text,
  p_uso_cfdi text,
  p_email text,
  p_telefono text,
  p_forma_pago text,
  p_ticket_foto_path text,
  p_sucursal_codigo text DEFAULT NULL,
  p_ticket_folio text DEFAULT NULL,
  p_ticket_total numeric DEFAULT NULL,
  p_ticket_fecha date DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $fac$
DECLARE
  v_rfc text;
  v_cp text;
  v_email text;
  v_tel text;
  v_foto text;
  v_suc_id uuid;
  v_suc_codigo text;
  v_tz text;
  v_hoy date;
  v_consecutivo integer;
  v_folio text;
  v_ticket_norm text;
  v_constraint text;
BEGIN
  v_rfc := upper(regexp_replace(COALESCE(p_rfc, ''), '\s', '', 'g'));
  IF char_length(v_rfc) < 12 OR char_length(v_rfc) > 13
     OR v_rfc !~ '^[A-ZÑ&]{3,4}[0-9]{6}[A-Z0-9]{3}' THEN
    RAISE EXCEPTION 'RFC_INVALIDO';
  END IF;

  v_cp := regexp_replace(COALESCE(p_codigo_postal, ''), '\D', '', 'g');
  IF char_length(v_cp) <> 5 THEN
    RAISE EXCEPTION 'CP_INVALIDO';
  END IF;

  v_email := lower(trim(COALESCE(p_email, '')));
  IF v_email !~ '^[^@[:space:]]+@[^@[:space:]]+[.][^@[:space:]]+' THEN
    RAISE EXCEPTION 'EMAIL_INVALIDO';
  END IF;

  v_tel := regexp_replace(COALESCE(p_telefono, ''), '\D', '', 'g');
  IF char_length(v_tel) <> 10 THEN
    RAISE EXCEPTION 'TELEFONO_INVALIDO';
  END IF;

  IF NULLIF(trim(COALESCE(p_razon_social,'')), '') IS NULL THEN
    RAISE EXCEPTION 'RAZON_SOCIAL_REQUERIDA';
  END IF;
  IF NULLIF(trim(COALESCE(p_regimen_fiscal,'')), '') IS NULL THEN
    RAISE EXCEPTION 'REGIMEN_REQUERIDO';
  END IF;
  IF NULLIF(trim(COALESCE(p_uso_cfdi,'')), '') IS NULL THEN
    RAISE EXCEPTION 'USO_CFDI_REQUERIDO';
  END IF;
  IF NULLIF(trim(COALESCE(p_forma_pago,'')), '') IS NULL THEN
    RAISE EXCEPTION 'FORMA_PAGO_REQUERIDA';
  END IF;

  IF NULLIF(trim(COALESCE(p_ticket_folio,'')), '') IS NULL THEN
    RAISE EXCEPTION 'TICKET_REQUERIDO';
  END IF;
  IF p_ticket_total IS NULL OR p_ticket_total <= 0 THEN
    RAISE EXCEPTION 'TOTAL_REQUERIDO';
  END IF;
  IF p_ticket_fecha IS NULL THEN
    RAISE EXCEPTION 'FECHA_REQUERIDA';
  END IF;

  -- Foto del ticket: obligatoria.
  v_foto := NULLIF(trim(COALESCE(p_ticket_foto_path,'')), '');
  IF v_foto IS NULL THEN
    RAISE EXCEPTION 'FOTO_REQUERIDA';
  END IF;

  -- Sucursal: obligatoria y del catálogo (ya no hay caída a 'GEN').
  v_suc_codigo := upper(NULLIF(trim(COALESCE(p_sucursal_codigo, '')), ''));
  IF v_suc_codigo IS NULL THEN
    RAISE EXCEPTION 'SUCURSAL_REQUERIDA';
  END IF;

  SELECT id, zona_horaria INTO v_suc_id, v_tz
  FROM sucursales WHERE upper(prefijo_folio) = v_suc_codigo LIMIT 1;

  IF v_suc_id IS NULL THEN
    RAISE EXCEPTION 'SUCURSAL_INVALIDA';
  END IF;

  -- Candado de mes en curso: la fecha del ticket debe caer entre el día 1
  -- del mes actual y hoy (zona horaria de la sucursal).
  v_hoy := (now() AT TIME ZONE COALESCE(v_tz, 'America/Mexico_City'))::date;
  IF p_ticket_fecha > v_hoy
     OR p_ticket_fecha < date_trunc('month', v_hoy)::date THEN
    RAISE EXCEPTION 'FECHA_FUERA_DE_MES';
  END IF;

  -- Un ticket, una factura: mismo folio en la MISMA sucursal ya no pasa.
  -- (El índice único es la garantía; esto es para avisar bonito y para no
  -- quemar un consecutivo de folio de seguimiento en balde.)
  v_ticket_norm := public.factura_ticket_norm(p_ticket_folio);
  IF EXISTS (
    SELECT 1 FROM factura_solicitudes
    WHERE sucursal_codigo = v_suc_codigo
      AND ticket_folio_norm IS NOT NULL
      AND ticket_folio_norm = v_ticket_norm
      AND estado <> 'rechazada'
  ) THEN
    RAISE EXCEPTION 'TICKET_YA_USADO';
  END IF;

  -- Consecutivo del día en la zona horaria de la sucursal.
  INSERT INTO factura_folios (sucursal_codigo, fecha, ultimo)
  VALUES (v_suc_codigo, v_hoy, 1)
  ON CONFLICT (sucursal_codigo, fecha) DO UPDATE SET ultimo = factura_folios.ultimo + 1;

  SELECT ultimo INTO v_consecutivo
  FROM factura_folios
  WHERE sucursal_codigo = v_suc_codigo AND fecha = v_hoy;

  v_folio := 'FAC-' || v_suc_codigo || '-' || to_char(v_hoy, 'YYMMDD')
             || '-' || lpad(v_consecutivo::text, 3, '0');

  BEGIN
    INSERT INTO factura_solicitudes (
      folio_solicitud, sucursal_id, sucursal_codigo,
      rfc, razon_social, regimen_fiscal, codigo_postal, uso_cfdi, email, telefono, forma_pago,
      ticket_folio, ticket_total, ticket_fecha, ticket_foto_path, estado
    ) VALUES (
      v_folio, v_suc_id, v_suc_codigo,
      v_rfc, trim(p_razon_social), trim(p_regimen_fiscal), v_cp, trim(p_uso_cfdi), v_email, v_tel, trim(p_forma_pago),
      trim(p_ticket_folio), p_ticket_total, p_ticket_fecha, v_foto, 'pendiente'
    );
  EXCEPTION WHEN unique_violation THEN
    -- Dos envíos del mismo ticket al mismo tiempo: gana el primero.
    GET STACKED DIAGNOSTICS v_constraint = PG_EXCEPTION_CONSTRAINT;
    IF v_constraint = 'factura_solicitudes_ticket_unico_idx' THEN
      RAISE EXCEPTION 'TICKET_YA_USADO';
    END IF;
    RAISE;
  END;

  RETURN jsonb_build_object('ok', true, 'folio', v_folio);
END;
$fac$;

-- ---------- BLOQUE 5: consulta previa (antes de subir la foto) ----------
CREATE OR REPLACE FUNCTION public.factura_ticket_disponible(
  p_sucursal_codigo text,
  p_ticket_folio text
)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $disp$
  SELECT NOT EXISTS (
    SELECT 1 FROM public.factura_solicitudes s
    WHERE s.sucursal_codigo = upper(NULLIF(trim(COALESCE(p_sucursal_codigo, '')), ''))
      AND s.ticket_folio_norm IS NOT NULL
      AND s.ticket_folio_norm = public.factura_ticket_norm(p_ticket_folio)
      AND s.estado <> 'rechazada'
  );
$disp$;

REVOKE ALL ON FUNCTION public.factura_ticket_disponible(text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.factura_ticket_disponible(text, text) TO anon, authenticated;
