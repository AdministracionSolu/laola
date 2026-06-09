-- Correcciones de auditoría (no rota credenciales).
-- 1) prov_set_precio: rechazar precio <= 0 (un $0 ganaba como "más barato").
-- 2) insumo_sucursal: columna updated_at + trigger para rastro de cambios.
-- Idempotente: se puede correr varias veces sin error.

-- ---------------------------------------------------------------------------
-- 1) prov_set_precio: precio debe ser estrictamente mayor a 0
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.prov_set_precio(p_token text, p_producto_id uuid, p_precio numeric)
RETURNS boolean
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE v_prov_id uuid;
BEGIN
  SELECT id INTO v_prov_id FROM public.proveedores WHERE token = p_token AND activo;
  IF v_prov_id IS NULL THEN RETURN false; END IF;
  -- Precio inválido: nulo o menor/igual a cero (antes permitía 0 = "más barato").
  IF p_precio IS NULL OR p_precio <= 0 THEN RETURN false; END IF;
  -- El producto DEBE pertenecer a ese proveedor (aislamiento).
  IF NOT EXISTS (
    SELECT 1 FROM public.proveedor_productos
    WHERE id = p_producto_id AND proveedor_id = v_prov_id
  ) THEN
    RETURN false;
  END IF;
  INSERT INTO public.proveedor_precios (proveedor_producto_id, precio)
  VALUES (p_producto_id, p_precio);
  RETURN true;
END $$;

-- ---------------------------------------------------------------------------
-- 2) insumo_sucursal.updated_at + trigger
-- ---------------------------------------------------------------------------
ALTER TABLE public.insumo_sucursal
  ADD COLUMN IF NOT EXISTS updated_at timestamptz NOT NULL DEFAULT now();

CREATE OR REPLACE FUNCTION public.touch_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_insumo_sucursal_updated_at ON public.insumo_sucursal;
CREATE TRIGGER trg_insumo_sucursal_updated_at
  BEFORE UPDATE ON public.insumo_sucursal
  FOR EACH ROW
  EXECUTE FUNCTION public.touch_updated_at();
