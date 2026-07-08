-- ============================================================
-- FACTURACIÓN v3 — foto del ticket (opcional)
-- El cliente puede subir una foto de su ticket junto con sus datos fiscales.
-- La imagen vive en un bucket privado; solo las contadoras (authenticated)
-- pueden verla. El público sube vía policy de storage, pero no lee.
-- ============================================================

-- Ruta del objeto en el bucket 'factura-tickets' (ej. VAL/uuid.jpg)
ALTER TABLE public.factura_solicitudes
  ADD COLUMN IF NOT EXISTS ticket_foto_path text;

-- ---------- Bucket privado para las fotos ----------
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'factura-tickets', 'factura-tickets', false, 10485760,  -- 10 MB
  ARRAY['image/jpeg','image/png','image/webp','image/heic','image/heif']
)
ON CONFLICT (id) DO UPDATE
  SET public = EXCLUDED.public,
      file_size_limit = EXCLUDED.file_size_limit,
      allowed_mime_types = EXCLUDED.allowed_mime_types;

-- El público (anon) puede SUBIR su foto, pero no leer ni listar.
DROP POLICY IF EXISTS "factura_tickets_sube" ON storage.objects;
CREATE POLICY "factura_tickets_sube" ON storage.objects
  FOR INSERT TO anon, authenticated
  WITH CHECK (bucket_id = 'factura-tickets');

-- Las contadoras (authenticated) leen las fotos para timbrar.
DROP POLICY IF EXISTS "factura_tickets_lee" ON storage.objects;
CREATE POLICY "factura_tickets_lee" ON storage.objects
  FOR SELECT TO authenticated
  USING (bucket_id = 'factura-tickets');

-- ---------- RPC de solicitud (nueva firma: + foto) ----------
DROP FUNCTION IF EXISTS public.factura_solicitar(text, text, text, text, text, text, text, text, text, text, numeric, date);

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

  -- Datos del consumo (obligatorios)
  IF NULLIF(trim(COALESCE(p_ticket_folio,'')), '') IS NULL THEN
    RAISE EXCEPTION 'TICKET_REQUERIDO';
  END IF;
  IF p_ticket_total IS NULL OR p_ticket_total <= 0 THEN
    RAISE EXCEPTION 'TOTAL_REQUERIDO';
  END IF;
  IF p_ticket_fecha IS NULL THEN
    RAISE EXCEPTION 'FECHA_REQUERIDA';
  END IF;

  -- Foto del ticket (opcional). Puede quedar NULL.
  v_foto := NULLIF(trim(COALESCE(p_ticket_foto_path,'')), '');

  v_suc_codigo := upper(trim(COALESCE(p_sucursal_codigo, 'GEN')));
  SELECT id INTO v_suc_id FROM sucursales WHERE upper(prefijo_folio) = v_suc_codigo LIMIT 1;

  -- Folio consecutivo diario por sucursal. Se parte el upsert y la lectura en
  -- dos sentencias: 'INSERT ... RETURNING ... INTO' pone dos INTO en una misma
  -- sentencia y algunos runners de SQL lo rechazan (42601).
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

GRANT EXECUTE ON FUNCTION public.factura_solicitar(text, text, text, text, text, text, text, text, text, text, text, numeric, date)
  TO anon, authenticated;
