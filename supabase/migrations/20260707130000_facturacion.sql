-- ============================================================
-- FACTURACIÓN SELF-SERVE — Solicitudes de factura (quiosco)
-- El cliente escanea un QR por sucursal -> /factura?suc=VAL -> captura sus
-- datos fiscales y el ticket. La solicitud entra por una RPC SECURITY DEFINER
-- (el público NO toca la tabla). Las contadoras la gestionan y timbran en
-- Compact (CONTPAQi) o el PAC que corresponda; aquí queda todo cuadrado.
-- ============================================================

CREATE TABLE IF NOT EXISTS public.factura_solicitudes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  folio_solicitud text NOT NULL UNIQUE,   -- ej. FAC-VAL-000042 (para seguimiento)
  sucursal_id uuid REFERENCES public.sucursales(id),
  sucursal_codigo text,

  -- Datos fiscales del receptor (CFDI 4.0)
  rfc text NOT NULL,
  razon_social text NOT NULL,             -- exacta como en la constancia SAT
  regimen_fiscal text NOT NULL,           -- clave SAT c_RegimenFiscal (ej. 626)
  codigo_postal text NOT NULL,            -- domicilio fiscal receptor
  uso_cfdi text NOT NULL,                 -- clave SAT c_UsoCFDI (ej. G03)
  email text NOT NULL,

  -- Datos del consumo (para que la contadora ubique el ticket)
  ticket_folio text,
  ticket_total numeric(10,2),
  ticket_fecha date,

  -- Gestión
  estado text NOT NULL DEFAULT 'pendiente'
    CHECK (estado IN ('pendiente','timbrada','rechazada')),
  cfdi_uuid text,                         -- folio fiscal (UUID) una vez timbrada
  notas text,                             -- motivo de rechazo / observaciones

  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  timbrada_at timestamptz
);
CREATE INDEX IF NOT EXISTS factura_solicitudes_estado_idx
  ON public.factura_solicitudes (estado, created_at DESC);
CREATE INDEX IF NOT EXISTS factura_solicitudes_fecha_idx
  ON public.factura_solicitudes (created_at DESC);
CREATE INDEX IF NOT EXISTS factura_solicitudes_sucursal_idx
  ON public.factura_solicitudes (sucursal_id, created_at DESC);

-- Secuencia diaria de folios por sucursal (upsert atómico)
CREATE TABLE IF NOT EXISTS public.factura_folios (
  sucursal_codigo text NOT NULL,
  fecha date NOT NULL,
  ultimo integer NOT NULL DEFAULT 0,
  PRIMARY KEY (sucursal_codigo, fecha)
);

CREATE OR REPLACE FUNCTION public.factura_touch_updated_at()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at := now();
  IF NEW.estado = 'timbrada' AND OLD.estado IS DISTINCT FROM 'timbrada' THEN
    NEW.timbrada_at := now();
  END IF;
  RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS trg_factura_touch ON public.factura_solicitudes;
CREATE TRIGGER trg_factura_touch
  BEFORE UPDATE ON public.factura_solicitudes
  FOR EACH ROW EXECUTE FUNCTION public.factura_touch_updated_at();

-- ---------- RLS ----------
ALTER TABLE public.factura_solicitudes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.factura_folios ENABLE ROW LEVEL SECURITY; -- sin políticas: solo SECURITY DEFINER

-- Público: sin acceso directo. Contadoras (authenticated): leen y gestionan.
DROP POLICY IF EXISTS "staff_lee_facturas" ON public.factura_solicitudes;
CREATE POLICY "staff_lee_facturas" ON public.factura_solicitudes
  FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "staff_actualiza_facturas" ON public.factura_solicitudes;
CREATE POLICY "staff_actualiza_facturas" ON public.factura_solicitudes
  FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

-- ---------- RPC de solicitud (público) ----------
CREATE OR REPLACE FUNCTION public.factura_solicitar(
  p_rfc text,
  p_razon_social text,
  p_regimen_fiscal text,
  p_codigo_postal text,
  p_uso_cfdi text,
  p_email text,
  p_sucursal_codigo text DEFAULT NULL,
  p_ticket_folio text DEFAULT NULL,
  p_ticket_total numeric DEFAULT NULL,
  p_ticket_fecha date DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_rfc text;
  v_cp text;
  v_email text;
  v_suc_id uuid;
  v_suc_codigo text;
  v_consecutivo integer;
  v_folio text;
BEGIN
  v_rfc := upper(regexp_replace(COALESCE(p_rfc, ''), '\s', '', 'g'));
  IF v_rfc !~ '^[A-ZÑ&]{3,4}[0-9]{6}[A-Z0-9]{3}$' THEN
    RAISE EXCEPTION 'RFC_INVALIDO';
  END IF;

  v_cp := regexp_replace(COALESCE(p_codigo_postal, ''), '\D', '', 'g');
  IF v_cp !~ '^[0-9]{5}$' THEN
    RAISE EXCEPTION 'CP_INVALIDO';
  END IF;

  v_email := lower(trim(COALESCE(p_email, '')));
  IF v_email !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' THEN
    RAISE EXCEPTION 'EMAIL_INVALIDO';
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

  v_suc_codigo := upper(trim(COALESCE(p_sucursal_codigo, 'GEN')));
  SELECT id INTO v_suc_id FROM sucursales
  WHERE upper(prefijo_folio) = v_suc_codigo LIMIT 1;

  -- Folio consecutivo diario por sucursal
  INSERT INTO factura_folios (sucursal_codigo, fecha, ultimo)
  VALUES (v_suc_codigo, current_date, 1)
  ON CONFLICT (sucursal_codigo, fecha)
  DO UPDATE SET ultimo = factura_folios.ultimo + 1
  RETURNING ultimo INTO v_consecutivo;
  v_folio := 'FAC-' || v_suc_codigo || '-' || lpad(v_consecutivo::text, 5, '0');

  INSERT INTO factura_solicitudes (
    folio_solicitud, sucursal_id, sucursal_codigo,
    rfc, razon_social, regimen_fiscal, codigo_postal, uso_cfdi, email,
    ticket_folio, ticket_total, ticket_fecha, estado
  ) VALUES (
    v_folio, v_suc_id, v_suc_codigo,
    v_rfc, trim(p_razon_social), trim(p_regimen_fiscal), v_cp, trim(p_uso_cfdi), v_email,
    NULLIF(trim(COALESCE(p_ticket_folio,'')),''), p_ticket_total, p_ticket_fecha, 'pendiente'
  );

  RETURN jsonb_build_object('ok', true, 'folio', v_folio);
END;
$$;

GRANT EXECUTE ON FUNCTION public.factura_solicitar(text, text, text, text, text, text, text, text, numeric, date)
  TO anon, authenticated;
