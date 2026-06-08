-- =====================================================================
-- Liga de depuración (uso único): un token maestro permite listar TODOS los
-- proveedores con sus productos y eliminar los que no se van a preguntar.
-- Sin login; aislado vía RPCs SECURITY DEFINER que validan el token.
-- =====================================================================

CREATE TABLE IF NOT EXISTS public.config_depuracion (
  id    int PRIMARY KEY DEFAULT 1,
  token text NOT NULL DEFAULT replace(gen_random_uuid()::text, '-', ''),
  CONSTRAINT config_depuracion_una_fila CHECK (id = 1)
);
INSERT INTO public.config_depuracion (id) VALUES (1) ON CONFLICT (id) DO NOTHING;

ALTER TABLE public.config_depuracion ENABLE ROW LEVEL SECURITY;
-- Sin políticas: nadie lee/escribe directo; solo las funciones SECURITY DEFINER.

-- Marca de "ya revisado" por proveedor (para seguir el avance de la depuración).
ALTER TABLE public.proveedores ADD COLUMN IF NOT EXISTS depurado boolean NOT NULL DEFAULT false;

-- Listar todos los proveedores con sus productos.
CREATE OR REPLACE FUNCTION public.depurar_listar(p_token text)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.config_depuracion WHERE token = p_token) THEN
    RETURN NULL;
  END IF;
  RETURN COALESCE((
    SELECT jsonb_agg(jsonb_build_object(
      'id', pr.id,
      'nombre', pr.nombre,
      'categoria', pr.categoria,
      'depurado', pr.depurado,
      'productos', COALESCE((
        SELECT jsonb_agg(jsonb_build_object('id', pp.id, 'nombre', pp.nombre, 'unidad', pp.unidad)
                         ORDER BY pp.nombre)
        FROM public.proveedor_productos pp WHERE pp.proveedor_id = pr.id
      ), '[]'::jsonb)
    ) ORDER BY pr.categoria, pr.nombre)
    FROM public.proveedores pr
  ), '[]'::jsonb);
END $$;

-- Eliminar los productos marcados (por id).
CREATE OR REPLACE FUNCTION public.depurar_eliminar(p_token text, p_ids jsonb)
RETURNS int
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE n int;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.config_depuracion WHERE token = p_token) THEN
    RETURN -1;
  END IF;
  DELETE FROM public.proveedor_productos
  WHERE id IN (SELECT (jsonb_array_elements_text(p_ids))::uuid);
  GET DIAGNOSTICS n = ROW_COUNT;
  RETURN n;
END $$;

-- Marcar (o desmarcar) un proveedor como revisado.
CREATE OR REPLACE FUNCTION public.depurar_marcar(p_token text, p_proveedor_id uuid, p_depurado boolean)
RETURNS boolean
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.config_depuracion WHERE token = p_token) THEN
    RETURN false;
  END IF;
  UPDATE public.proveedores SET depurado = p_depurado WHERE id = p_proveedor_id;
  RETURN true;
END $$;

REVOKE ALL ON FUNCTION public.depurar_listar(text) FROM public;
REVOKE ALL ON FUNCTION public.depurar_eliminar(text, jsonb) FROM public;
REVOKE ALL ON FUNCTION public.depurar_marcar(text, uuid, boolean) FROM public;
GRANT EXECUTE ON FUNCTION public.depurar_listar(text) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.depurar_eliminar(text, jsonb) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.depurar_marcar(text, uuid, boolean) TO anon, authenticated;

NOTIFY pgrst, 'reload schema';
