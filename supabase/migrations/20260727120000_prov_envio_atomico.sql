-- =====================================================================
-- Blindaje del portal de proveedores (jul-27-2026).
-- Caso Lindo Mar: envíos que llegan incompletos (solo Camarón fresco) sin
-- rastro de qué intentó mandar el proveedor.
--
-- 1) proveedor_envios: bitácora en el servidor de cada envío (qué llegó,
--    qué se guardó, qué falló). Sin esto no hay forma de diagnosticar.
-- 2) prov_guardar_precios: UN solo RPC atómico que guarda TODO el envío
--    en una transacción. O entra todo o no entra nada — la captura
--    parcial deja de ser posible por construcción.
-- 3) prov_set_camaron v2: ya NO borra todo el histórico del producto;
--    solo reemplaza lo capturado HOY (TZ Mazatlán). El borrado total
--    destruía la comparativa de días pasados (y la evidencia forense).
-- 4) prov_set_precio v3: exige producto activo y deja bitácora (las
--    ligas con bundle viejo en caché siguen funcionando, pero visibles).
-- Idempotente.
-- =====================================================================

-- ---------------------------------------------------------------------
-- BLOQUE 1: bitácora de envíos
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.proveedor_envios (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  proveedor_id uuid REFERENCES public.proveedores(id) ON DELETE SET NULL,
  fuente text NOT NULL,
  payload jsonb NOT NULL,
  resultado jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.proveedor_envios ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "envios_admin_select" ON public.proveedor_envios;
CREATE POLICY "envios_admin_select" ON public.proveedor_envios
  FOR SELECT TO authenticated USING (true);
-- Sin policy de INSERT: solo escriben las funciones SECURITY DEFINER.

CREATE INDEX IF NOT EXISTS proveedor_envios_prov_fecha_idx
  ON public.proveedor_envios (proveedor_id, created_at DESC);

-- ---------------------------------------------------------------------
-- BLOQUE 2: prov_guardar_precios — envío atómico completo
-- p_normales = [{"producto_id":"...","precio":168}, ...]
-- p_gramajes = [{"producto_id":"...","filas":[{"gramaje":"16g","precio":85}]}, ...]
-- Devuelve {"ok":true,"guardados":N} o {"ok":false,"error":"..."}.
-- Todo corre en UNA transacción: si algo truena, no se guarda nada
-- (pero la bitácora del intento fallido SÍ queda, vía subtransacción).
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.prov_guardar_precios(
  p_token text, p_normales jsonb DEFAULT '[]'::jsonb, p_gramajes jsonb DEFAULT '[]'::jsonb
)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $atomico$
DECLARE
  v_prov public.proveedores;
  v_item jsonb; v_fila jsonb;
  v_prod uuid; v_precio numeric;
  v_hoy date := (now() AT TIME ZONE 'America/Mazatlan')::date;
  v_guardados int := 0;
BEGIN
  SELECT * INTO v_prov FROM public.proveedores WHERE token = p_token AND activo;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'error', 'LIGA_INVALIDA');
  END IF;

  BEGIN  -- subtransacción: si truena, el handler conserva la bitácora
    -- Productos normales: un precio de hoy por producto (append al histórico)
    FOR v_item IN SELECT * FROM jsonb_array_elements(COALESCE(p_normales, '[]'::jsonb)) LOOP
      v_prod := (v_item->>'producto_id')::uuid;
      v_precio := NULLIF(v_item->>'precio', '')::numeric;
      IF v_precio IS NULL OR v_precio <= 0 THEN
        RAISE EXCEPTION 'PRECIO_INVALIDO';
      END IF;
      IF NOT EXISTS (
        SELECT 1 FROM public.proveedor_productos
        WHERE id = v_prod AND proveedor_id = v_prov.id AND activo
      ) THEN
        RAISE EXCEPTION 'PRODUCTO_AJENO';
      END IF;
      INSERT INTO public.proveedor_precios (proveedor_producto_id, precio)
      VALUES (v_prod, v_precio);
      v_guardados := v_guardados + 1;
    END LOOP;

    -- Productos por gramaje: reemplaza SOLO lo de hoy, conserva el histórico
    FOR v_item IN SELECT * FROM jsonb_array_elements(COALESCE(p_gramajes, '[]'::jsonb)) LOOP
      v_prod := (v_item->>'producto_id')::uuid;
      IF NOT EXISTS (
        SELECT 1 FROM public.proveedor_productos
        WHERE id = v_prod AND proveedor_id = v_prov.id AND activo AND por_gramaje
      ) THEN
        RAISE EXCEPTION 'PRODUCTO_AJENO';
      END IF;
      DELETE FROM public.proveedor_precios
      WHERE proveedor_producto_id = v_prod
        AND (created_at AT TIME ZONE 'America/Mazatlan')::date = v_hoy;
      FOR v_fila IN SELECT * FROM jsonb_array_elements(COALESCE(v_item->'filas', '[]'::jsonb)) LOOP
        v_precio := NULLIF(v_fila->>'precio', '')::numeric;
        IF v_precio IS NOT NULL AND v_precio > 0 THEN
          INSERT INTO public.proveedor_precios (proveedor_producto_id, precio, gramaje)
          VALUES (v_prod, v_precio, NULLIF(trim(v_fila->>'gramaje'), ''));
          v_guardados := v_guardados + 1;
        END IF;
      END LOOP;
    END LOOP;

    IF v_guardados = 0 THEN
      RAISE EXCEPTION 'ENVIO_VACIO';
    END IF;

    INSERT INTO public.proveedor_envios (proveedor_id, fuente, payload, resultado)
    VALUES (v_prov.id, 'atomico',
            jsonb_build_object('normales', p_normales, 'gramajes', p_gramajes),
            jsonb_build_object('ok', true, 'guardados', v_guardados));
    RETURN jsonb_build_object('ok', true, 'guardados', v_guardados);

  EXCEPTION WHEN OTHERS THEN
    INSERT INTO public.proveedor_envios (proveedor_id, fuente, payload, resultado)
    VALUES (v_prov.id, 'atomico',
            jsonb_build_object('normales', p_normales, 'gramajes', p_gramajes),
            jsonb_build_object('ok', false, 'error', SQLERRM));
    RETURN jsonb_build_object('ok', false, 'error', SQLERRM);
  END;
END $atomico$;

REVOKE ALL ON FUNCTION public.prov_guardar_precios(text, jsonb, jsonb) FROM public;
GRANT EXECUTE ON FUNCTION public.prov_guardar_precios(text, jsonb, jsonb) TO anon, authenticated;

-- ---------------------------------------------------------------------
-- BLOQUE 3: prov_set_camaron v2 — deja de borrar el histórico completo
-- (solo reemplaza lo de HOY) y deja bitácora. Sigue existiendo para
-- bundles viejos en caché.
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.prov_set_camaron(p_token text, p_producto_id uuid, p_items jsonb)
RETURNS boolean
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $camaron$
DECLARE
  v_prov_id uuid; v_item jsonb; v_precio numeric;
  v_hoy date := (now() AT TIME ZONE 'America/Mazatlan')::date;
BEGIN
  SELECT id INTO v_prov_id FROM public.proveedores WHERE token = p_token AND activo;
  IF v_prov_id IS NULL THEN RETURN false; END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.proveedor_productos
    WHERE id = p_producto_id AND proveedor_id = v_prov_id AND activo
  ) THEN RETURN false; END IF;

  -- Reemplaza SOLO lo capturado hoy; el histórico de otros días se queda.
  DELETE FROM public.proveedor_precios
  WHERE proveedor_producto_id = p_producto_id
    AND (created_at AT TIME ZONE 'America/Mazatlan')::date = v_hoy;
  FOR v_item IN SELECT * FROM jsonb_array_elements(COALESCE(p_items, '[]'::jsonb)) LOOP
    v_precio := NULLIF(v_item->>'precio', '')::numeric;
    IF v_precio IS NOT NULL AND v_precio > 0 THEN
      INSERT INTO public.proveedor_precios (proveedor_producto_id, precio, gramaje)
      VALUES (p_producto_id, v_precio, NULLIF(trim(v_item->>'gramaje'), ''));
    END IF;
  END LOOP;

  INSERT INTO public.proveedor_envios (proveedor_id, fuente, payload, resultado)
  VALUES (v_prov_id, 'legacy_camaron',
          jsonb_build_object('producto_id', p_producto_id, 'items', p_items),
          jsonb_build_object('ok', true));
  RETURN true;
END $camaron$;

-- ---------------------------------------------------------------------
-- BLOQUE 4: prov_set_precio v3 — exige producto activo y deja bitácora.
-- Sigue existiendo para bundles viejos en caché.
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.prov_set_precio(p_token text, p_producto_id uuid, p_precio numeric)
RETURNS boolean
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $precio$
DECLARE v_prov_id uuid;
BEGIN
  SELECT id INTO v_prov_id FROM public.proveedores WHERE token = p_token AND activo;
  IF v_prov_id IS NULL THEN RETURN false; END IF;
  IF p_precio IS NULL OR p_precio <= 0 THEN RETURN false; END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.proveedor_productos
    WHERE id = p_producto_id AND proveedor_id = v_prov_id AND activo
  ) THEN RETURN false; END IF;

  INSERT INTO public.proveedor_precios (proveedor_producto_id, precio)
  VALUES (p_producto_id, p_precio);
  INSERT INTO public.proveedor_envios (proveedor_id, fuente, payload, resultado)
  VALUES (v_prov_id, 'legacy_precio',
          jsonb_build_object('producto_id', p_producto_id, 'precio', p_precio),
          jsonb_build_object('ok', true));
  RETURN true;
END $precio$;

SELECT pg_notify('pgrst', 'reload schema');
