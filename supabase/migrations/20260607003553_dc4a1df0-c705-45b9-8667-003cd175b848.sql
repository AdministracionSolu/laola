
ALTER TABLE public.sucursales ADD COLUMN IF NOT EXISTS pin text;
ALTER TABLE public.pedidos ADD COLUMN IF NOT EXISTS enviado_at timestamptz;
ALTER TABLE public.pedidos_detalle ADD COLUMN IF NOT EXISTS cantidad_sugerida numeric;

CREATE TABLE IF NOT EXISTS public.insumo_sucursal (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  insumo_id uuid NOT NULL REFERENCES public.insumos(id) ON DELETE CASCADE,
  sucursal_id uuid NOT NULL REFERENCES public.sucursales(id) ON DELETE CASCADE,
  nivel_par numeric,
  costo numeric,
  unidad text,
  orden integer NOT NULL DEFAULT 0,
  activo boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (insumo_id, sucursal_id)
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.insumo_sucursal TO authenticated;
GRANT SELECT ON public.insumo_sucursal TO anon;
GRANT ALL ON public.insumo_sucursal TO service_role;

ALTER TABLE public.insumo_sucursal ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Cualquiera puede ver insumo_sucursal" ON public.insumo_sucursal FOR SELECT USING (true);
CREATE POLICY "Solo admins pueden modificar insumo_sucursal" ON public.insumo_sucursal FOR ALL USING (has_role(auth.uid(), 'admin'::app_role)) WITH CHECK (has_role(auth.uid(), 'admin'::app_role));

CREATE TRIGGER update_insumo_sucursal_updated_at BEFORE UPDATE ON public.insumo_sucursal FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
