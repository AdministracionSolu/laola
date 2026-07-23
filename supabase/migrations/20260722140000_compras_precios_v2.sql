-- ============================================================
-- compras_precios v2: devolver TODOS los productos activos con
-- precio, tengan o no mapeo manual a insumo (insumo_id).
--
-- Motivo: el mapeo producto→insumo se quitó de la UI de proveedores
-- y casi ningún producto lo tiene; "Dónde comprar" y "Ahorros" ahora
-- emparejan por NOMBRE (claveProducto en el front, igual que la
-- comparativa), usando insumo_id solo cuando existe. Sin este cambio
-- esas vistas salen casi vacías.
--
-- Mismo contrato de salida (insumo_id puede venir null).
-- ============================================================
CREATE OR REPLACE FUNCTION public.compras_precios(p_pin text)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  IF NOT (
    EXISTS (SELECT 1 FROM public.config_app WHERE clave = 'pin_compras' AND valor = p_pin)
    OR has_role(auth.uid(), 'admin')
  ) THEN
    RETURN NULL;
  END IF;
  RETURN COALESCE((
    SELECT jsonb_agg(jsonb_build_object(
      'insumo_id', pp.insumo_id,
      'proveedor', prov.nombre,
      'producto', pp.nombre,
      'unidad', pp.unidad,
      'precio', (SELECT pr.precio FROM public.proveedor_precios pr
                 WHERE pr.proveedor_producto_id = pp.id
                 ORDER BY pr.created_at DESC LIMIT 1)
    ))
    FROM public.proveedor_productos pp
    JOIN public.proveedores prov ON prov.id = pp.proveedor_id
    WHERE pp.activo
      AND EXISTS (SELECT 1 FROM public.proveedor_precios pr WHERE pr.proveedor_producto_id = pp.id)
  ), '[]'::jsonb);
END $$;

NOTIFY pgrst, 'reload schema';
