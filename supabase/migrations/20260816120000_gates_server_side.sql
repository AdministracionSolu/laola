-- Barrido de seguridad 2026-08 · Eje 4
-- Mueve al servidor los dos "candados" que hoy se comparan en el cliente con la
-- clave hardcodeada en el bundle:
--   - HerramientasDialog: CLAVE_HERRAMIENTAS = "Coctel Danilo"
--   - Contadoras:         PIN_CONTADORAS    = "8534"
-- Se guardan en config_app (sin políticas: solo funciones SECURITY DEFINER las
-- leen) y se validan por RPC, igual que pin_compras / pin_implementacion.
--
-- IMPORTANTE (Diego): sustituye los valores placeholder por los reales ANTES de
-- que esta rama llegue a producción. No dejes el valor viejo ("Coctel Danilo" /
-- "8534"): ya son públicos por estar en el repo/bundle.

-- BLOQUE 1 — semillas de config (cambia el valor)
INSERT INTO public.config_app (clave, valor) VALUES
  ('clave_herramientas', 'CAMBIAR_ESTA_CLAVE'),
  ('pin_contadoras',     'CAMBIAR_ESTE_PIN')
ON CONFLICT (clave) DO NOTHING;

-- BLOQUE 2 — RPC de herramientas
CREATE OR REPLACE FUNCTION public.herramientas_validar_clave(p_clave text)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.config_app
    WHERE clave = 'clave_herramientas' AND valor = p_clave
  );
$$;

-- BLOQUE 3 — RPC de contadoras
CREATE OR REPLACE FUNCTION public.contadoras_validar_pin(p_pin text)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.config_app
    WHERE clave = 'pin_contadoras' AND valor = p_pin
  );
$$;

-- BLOQUE 4 — permisos de ejecución
REVOKE ALL ON FUNCTION public.herramientas_validar_clave(text) FROM public;
REVOKE ALL ON FUNCTION public.contadoras_validar_pin(text) FROM public;
GRANT EXECUTE ON FUNCTION public.herramientas_validar_clave(text) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.contadoras_validar_pin(text) TO anon, authenticated;
