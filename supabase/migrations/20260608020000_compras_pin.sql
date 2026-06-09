-- =====================================================================
-- Área "Pedido del día / Compras" protegida por PIN (gerente en turno).
-- El PIN se guarda en config_app (cambiable). Función de precios protegida:
-- devuelve el proveedor más barato por insumo solo con PIN válido (o admin).
-- =====================================================================

CREATE TABLE IF NOT EXISTS public.config_app (
  clave text PRIMARY KEY,
  valor text
);
INSERT INTO public.config_app (clave, valor) VALUES ('pin_compras', '1278')
ON CONFLICT (clave) DO NOTHING;

ALTER TABLE public.config_app ENABLE ROW LEVEL SECURITY;
-- Sin políticas: solo las funciones SECURITY DEFINER leen la config.

-- Valida el PIN del área de compras.
CREATE OR REPLACE FUNCTION public.compras_validar_pin(p_pin text)
RETURNS boolean
LANGUAGE sql SECURITY DEFINER SET search_path = public
AS $$
  SELECT EXISTS (SELECT 1 FROM public.config_app WHERE clave = 'pin_compras' AND valor = p_pin);
$$;

-- Precios vigentes por insumo (para "dónde comprar"). Acceso con PIN válido
-- o si el que llama es admin autenticado.
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
    WHERE pp.insumo_id IS NOT NULL AND pp.activo
      AND EXISTS (SELECT 1 FROM public.proveedor_precios pr WHERE pr.proveedor_producto_id = pp.id)
  ), '[]'::jsonb);
END $$;

REVOKE ALL ON FUNCTION public.compras_validar_pin(text) FROM public;
REVOKE ALL ON FUNCTION public.compras_precios(text) FROM public;
GRANT EXECUTE ON FUNCTION public.compras_validar_pin(text) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.compras_precios(text) TO anon, authenticated;

NOTIFY pgrst, 'reload schema';
