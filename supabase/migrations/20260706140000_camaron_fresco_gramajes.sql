-- =====================================================================
-- Camarón fresco por gramaje (jul-2026).
-- El camarón fresco no tiene talla fija: el proveedor captura hasta 4
-- gramajes, cada uno con su precio. Se maneja como UN item "Camarón fresco"
-- marcado por_gramaje. Además: se quitan tallas por gramo sueltas y la
-- talla 12-25 (no existe), y se corrige "Atún medallón" -> "Medallón de atún".
-- Idempotente.
-- =====================================================================

-- 1) Columnas nuevas
ALTER TABLE public.proveedor_precios   ADD COLUMN IF NOT EXISTS gramaje text;
ALTER TABLE public.proveedor_productos ADD COLUMN IF NOT EXISTS por_gramaje boolean NOT NULL DEFAULT false;

-- 2) Corregir nombre "Atún medallón" -> "Medallón de atún" (evita choque unique)
UPDATE public.proveedor_productos AS t SET nombre = 'Medallón de atún'
WHERE t.nombre = 'Atún medallón'
  AND NOT EXISTS (
    SELECT 1 FROM public.proveedor_productos p2
    WHERE p2.proveedor_id = t.proveedor_id AND p2.nombre = 'Medallón de atún'
  );

-- 3) Quitar tallas por gramo sueltas y la 12-25 (se manejan en "Camarón fresco")
UPDATE public.proveedor_productos SET activo = false
WHERE nombre IN ('Camarón 19g', 'Camarón 7-11', 'Camarón 12-25', 'Camarón vapor 25-30');

-- 4) "Camarón fresco" es por gramaje
UPDATE public.proveedor_productos SET por_gramaje = true WHERE nombre = 'Camarón fresco';

-- 5) Asegurar "Camarón fresco" (por gramaje) a los proveedores que vendían
--    camarón por gramo, para que no se queden sin nada.
INSERT INTO public.proveedor_productos (proveedor_id, nombre, unidad, por_gramaje, activo)
SELECT DISTINCT pp.proveedor_id, 'Camarón fresco', 'kg', true, true
FROM public.proveedor_productos pp
WHERE pp.nombre IN ('Camarón 19g', 'Camarón 7-11', 'Camarón 12-25', 'Camarón vapor 25-30', 'Camarón fresco')
ON CONFLICT (proveedor_id, nombre) DO UPDATE SET activo = true, por_gramaje = true;

-- ---------------------------------------------------------------------
-- 6) prov_catalogo: ahora expone por_gramaje y, para esos, el set de gramajes.
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.prov_catalogo(p_token text)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE v_prov public.proveedores; v_result jsonb;
BEGIN
  SELECT * INTO v_prov FROM public.proveedores WHERE token = p_token AND activo;
  IF NOT FOUND THEN RETURN NULL; END IF;
  SELECT jsonb_build_object(
    'proveedor', jsonb_build_object('nombre', v_prov.nombre, 'categoria', v_prov.categoria),
    'productos', COALESCE((
      SELECT jsonb_agg(jsonb_build_object(
        'id', pp.id,
        'nombre', pp.nombre,
        'unidad', pp.unidad,
        'por_gramaje', pp.por_gramaje,
        'precio_vigente', CASE WHEN pp.por_gramaje THEN NULL ELSE
          (SELECT pr.precio FROM public.proveedor_precios pr
           WHERE pr.proveedor_producto_id = pp.id ORDER BY pr.created_at DESC LIMIT 1) END,
        'precio_fecha', (SELECT max(pr.created_at) FROM public.proveedor_precios pr
                         WHERE pr.proveedor_producto_id = pp.id),
        'gramajes', CASE WHEN pp.por_gramaje THEN COALESCE((
            SELECT jsonb_agg(jsonb_build_object('gramaje', pr.gramaje, 'precio', pr.precio) ORDER BY pr.created_at)
            FROM public.proveedor_precios pr WHERE pr.proveedor_producto_id = pp.id
          ), '[]'::jsonb) ELSE NULL END
      ) ORDER BY pp.nombre)
      FROM public.proveedor_productos pp
      WHERE pp.proveedor_id = v_prov.id AND pp.activo
    ), '[]'::jsonb)
  ) INTO v_result;
  RETURN v_result;
END $$;

-- ---------------------------------------------------------------------
-- 7) prov_set_camaron: reemplaza el set de gramajes+precios de un producto.
--    p_items = [{"gramaje":"19g","precio":180}, ...] (hasta 4)
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.prov_set_camaron(p_token text, p_producto_id uuid, p_items jsonb)
RETURNS boolean
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE v_prov_id uuid; v_item jsonb; v_precio numeric;
BEGIN
  SELECT id INTO v_prov_id FROM public.proveedores WHERE token = p_token AND activo;
  IF v_prov_id IS NULL THEN RETURN false; END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.proveedor_productos
    WHERE id = p_producto_id AND proveedor_id = v_prov_id
  ) THEN RETURN false; END IF;

  -- Reemplaza el set actual por lo recién capturado.
  DELETE FROM public.proveedor_precios WHERE proveedor_producto_id = p_producto_id;
  FOR v_item IN SELECT * FROM jsonb_array_elements(COALESCE(p_items, '[]'::jsonb)) LOOP
    v_precio := NULLIF(v_item->>'precio', '')::numeric;
    IF v_precio IS NOT NULL AND v_precio > 0 THEN
      INSERT INTO public.proveedor_precios (proveedor_producto_id, precio, gramaje)
      VALUES (p_producto_id, v_precio, NULLIF(trim(v_item->>'gramaje'), ''));
    END IF;
  END LOOP;
  RETURN true;
END $$;

REVOKE ALL ON FUNCTION public.prov_set_camaron(text, uuid, jsonb) FROM public;
GRANT EXECUTE ON FUNCTION public.prov_set_camaron(text, uuid, jsonb) TO anon, authenticated;

NOTIFY pgrst, 'reload schema';
