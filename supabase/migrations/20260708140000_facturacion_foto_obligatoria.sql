-- ============================================================
-- FACTURACIÓN v4 — foto del ticket obligatoria
-- Misma firma que v3; solo se agrega la validación FOTO_REQUERIDA.
-- CREATE OR REPLACE basta (no cambia la firma → no hace falta DROP ni GRANT).
-- ============================================================

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
  v_consecutivo integer;
  v_folio text;
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

  -- Foto del ticket: ahora obligatoria.
  v_foto := NULLIF(trim(COALESCE(p_ticket_foto_path,'')), '');
  IF v_foto IS NULL THEN
    RAISE EXCEPTION 'FOTO_REQUERIDA';
  END IF;

  v_suc_codigo := upper(trim(COALESCE(p_sucursal_codigo, 'GEN')));
  SELECT id INTO v_suc_id FROM sucursales WHERE upper(prefijo_folio) = v_suc_codigo LIMIT 1;

  INSERT INTO factura_folios (sucursal_codigo, fecha, ultimo)
  VALUES (v_suc_codigo, current_date, 1)
  ON CONFLICT (sucursal_codigo, fecha) DO UPDATE SET ultimo = factura_folios.ultimo + 1;

  SELECT ultimo INTO v_consecutivo
  FROM factura_folios
  WHERE sucursal_codigo = v_suc_codigo AND fecha = current_date;

  v_folio := 'FAC-' || v_suc_codigo || '-' || lpad(v_consecutivo::text, 5, '0');

  INSERT INTO factura_solicitudes (
    folio_solicitud, sucursal_id, sucursal_codigo,
    rfc, razon_social, regimen_fiscal, codigo_postal, uso_cfdi, email, telefono, forma_pago,
    ticket_folio, ticket_total, ticket_fecha, ticket_foto_path, estado
  ) VALUES (
    v_folio, v_suc_id, v_suc_codigo,
    v_rfc, trim(p_razon_social), trim(p_regimen_fiscal), v_cp, trim(p_uso_cfdi), v_email, v_tel, trim(p_forma_pago),
    trim(p_ticket_folio), p_ticket_total, p_ticket_fecha, v_foto, 'pendiente'
  );

  RETURN jsonb_build_object('ok', true, 'folio', v_folio);
END;
$fac$;
