-- ============================================================
-- PROGRAMA DE LEALTAD — Registro de clientes
-- El cliente escanea un QR por sucursal -> /lealtad?suc=VAL -> formulario.
-- El alta entra por una RPC SECURITY DEFINER (el público NO toca la tabla).
-- Un teléfono = un perfil, unificado entre las 4 sucursales.
-- Las comunicaciones (bienvenida, cumpleaños, promos) las opera Makatea,
-- que jala esta lista; aquí solo se capta y se reporta.
-- ============================================================

-- ---------- 1. Tabla ----------
CREATE TABLE IF NOT EXISTS public.lealtad_clientes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  telefono text NOT NULL UNIQUE CHECK (telefono ~ '^[0-9]{10}$'),
  nombre text NOT NULL,
  cumpleanos date, -- opcional (enriquecimiento)
  -- Dónde se captó al cliente. Se fija en el PRIMER registro y no se sobrescribe
  -- si vuelve a escanear otro QR: es atribución, no fragmenta el perfil.
  sucursal_captacion_id uuid REFERENCES public.sucursales(id),
  sucursal_captacion_codigo text,
  consentimiento_marketing boolean NOT NULL DEFAULT false,
  consentimiento_at timestamptz,
  activo boolean NOT NULL DEFAULT true, -- false = baja / opt-out
  ultima_visita timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS lealtad_clientes_sucursal_idx
  ON public.lealtad_clientes (sucursal_captacion_id, created_at DESC);
CREATE INDEX IF NOT EXISTS lealtad_clientes_created_idx
  ON public.lealtad_clientes (created_at DESC);

-- updated_at automático
CREATE OR REPLACE FUNCTION public.lealtad_touch_updated_at()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS trg_lealtad_touch ON public.lealtad_clientes;
CREATE TRIGGER trg_lealtad_touch
  BEFORE UPDATE ON public.lealtad_clientes
  FOR EACH ROW EXECUTE FUNCTION public.lealtad_touch_updated_at();

-- ---------- 2. RLS ----------
ALTER TABLE public.lealtad_clientes ENABLE ROW LEVEL SECURITY;

-- Público (anon): CERO acceso directo. Solo se registra vía la RPC de abajo.
-- Staff (authenticated): lee y actualiza (dashboard + dar de baja).
DROP POLICY IF EXISTS "staff_lee_lealtad" ON public.lealtad_clientes;
CREATE POLICY "staff_lee_lealtad" ON public.lealtad_clientes
  FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "staff_actualiza_lealtad" ON public.lealtad_clientes;
CREATE POLICY "staff_actualiza_lealtad" ON public.lealtad_clientes
  FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

-- ---------- 3. RPC de registro (público) ----------
-- Da de alta o actualiza un cliente por teléfono. Idempotente: si el teléfono
-- ya existe, NO duplica ni cambia la sucursal de captación original.
CREATE OR REPLACE FUNCTION public.lealtad_registrar(
  p_nombre text,
  p_telefono text,
  p_sucursal_codigo text DEFAULT NULL,
  p_cumpleanos date DEFAULT NULL,
  p_consentimiento boolean DEFAULT true
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_tel text;
  v_nombre text;
  v_suc_id uuid;
  v_suc_nombre text;
  v_nuevo boolean;
BEGIN
  -- Normaliza teléfono a 10 dígitos
  v_tel := regexp_replace(COALESCE(p_telefono, ''), '\D', '', 'g');
  IF v_tel !~ '^[0-9]{10}$' THEN
    RAISE EXCEPTION 'TELEFONO_INVALIDO';
  END IF;

  v_nombre := NULLIF(trim(COALESCE(p_nombre, '')), '');
  IF v_nombre IS NULL THEN
    RAISE EXCEPTION 'NOMBRE_REQUERIDO';
  END IF;

  IF p_consentimiento IS NOT TRUE THEN
    RAISE EXCEPTION 'CONSENTIMIENTO_REQUERIDO';
  END IF;

  -- Resuelve la sucursal por su prefijo de folio (VAL, BRI, CER, SOL)
  IF p_sucursal_codigo IS NOT NULL THEN
    SELECT id, nombre INTO v_suc_id, v_suc_nombre
    FROM sucursales
    WHERE upper(prefijo_folio) = upper(trim(p_sucursal_codigo))
    LIMIT 1;
  END IF;

  INSERT INTO lealtad_clientes (
    telefono, nombre, cumpleanos,
    sucursal_captacion_id, sucursal_captacion_codigo,
    consentimiento_marketing, consentimiento_at, activo
  ) VALUES (
    v_tel, v_nombre, p_cumpleanos,
    v_suc_id, upper(trim(p_sucursal_codigo)),
    true, now(), true
  )
  ON CONFLICT (telefono) DO UPDATE SET
    nombre = EXCLUDED.nombre,
    -- solo completa el cumpleaños si aún no lo teníamos
    cumpleanos = COALESCE(lealtad_clientes.cumpleanos, EXCLUDED.cumpleanos),
    -- reactiva si se había dado de baja y vuelve a registrarse
    activo = true,
    consentimiento_marketing = true,
    consentimiento_at = COALESCE(lealtad_clientes.consentimiento_at, now())
    -- sucursal_captacion_* NO se toca: se conserva la del primer registro
  RETURNING (xmax = 0) INTO v_nuevo;

  -- Si no había sucursal previa y ahora llegó una, la fija (primer dato disponible)
  IF v_suc_id IS NOT NULL THEN
    UPDATE lealtad_clientes
    SET sucursal_captacion_id = v_suc_id,
        sucursal_captacion_codigo = upper(trim(p_sucursal_codigo))
    WHERE telefono = v_tel AND sucursal_captacion_id IS NULL;
  END IF;

  RETURN jsonb_build_object(
    'ok', true,
    'nuevo', COALESCE(v_nuevo, false),
    'nombre', v_nombre,
    'sucursal', v_suc_nombre
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.lealtad_registrar(text, text, text, date, boolean)
  TO anon, authenticated;
