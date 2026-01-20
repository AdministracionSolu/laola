-- Crear función para updated_at si no existe
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = public;

-- Tabla de zonas por sucursal
CREATE TABLE public.zonas_sucursal (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  sucursal_id UUID NOT NULL REFERENCES public.sucursales(id) ON DELETE CASCADE,
  nombre TEXT NOT NULL,
  capacidad INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Tabla de reservaciones
CREATE TABLE public.reservaciones (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  sucursal_id UUID NOT NULL REFERENCES public.sucursales(id) ON DELETE CASCADE,
  zona_id UUID NOT NULL REFERENCES public.zonas_sucursal(id) ON DELETE CASCADE,
  nombre_cliente TEXT NOT NULL,
  telefono TEXT,
  num_personas INTEGER NOT NULL DEFAULT 2,
  fecha DATE NOT NULL,
  hora TIME NOT NULL,
  notas TEXT,
  estado TEXT NOT NULL DEFAULT 'confirmada',
  registrado_por TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Habilitar RLS
ALTER TABLE public.zonas_sucursal ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reservaciones ENABLE ROW LEVEL SECURITY;

-- Políticas para zonas (todos pueden ver)
CREATE POLICY "Cualquiera puede ver zonas"
  ON public.zonas_sucursal FOR SELECT
  USING (true);

-- Políticas para reservaciones (todos pueden CRUD)
CREATE POLICY "Cualquiera puede ver reservaciones"
  ON public.reservaciones FOR SELECT
  USING (true);

CREATE POLICY "Cualquiera puede crear reservaciones"
  ON public.reservaciones FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Cualquiera puede actualizar reservaciones"
  ON public.reservaciones FOR UPDATE
  USING (true);

CREATE POLICY "Cualquiera puede eliminar reservaciones"
  ON public.reservaciones FOR DELETE
  USING (true);

-- Trigger para updated_at
CREATE TRIGGER update_reservaciones_updated_at
  BEFORE UPDATE ON public.reservaciones
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- Insertar las zonas iniciales
INSERT INTO public.zonas_sucursal (sucursal_id, nombre, capacidad)
SELECT id, 'Zona 1', 20 FROM public.sucursales WHERE nombre ILIKE '%valle%'
UNION ALL
SELECT id, 'Zona 2', 20 FROM public.sucursales WHERE nombre ILIKE '%valle%'
UNION ALL
SELECT id, 'Zona 3', 20 FROM public.sucursales WHERE nombre ILIKE '%valle%'
UNION ALL
SELECT id, 'VIP 1', 10 FROM public.sucursales WHERE nombre ILIKE '%valle%'
UNION ALL
SELECT id, 'VIP 2', 10 FROM public.sucursales WHERE nombre ILIKE '%valle%'
UNION ALL
SELECT id, 'VIP', 15 FROM public.sucursales WHERE nombre ILIKE '%cervecer%'
UNION ALL
SELECT id, 'Terraza', 30 FROM public.sucursales WHERE nombre ILIKE '%cervecer%'
UNION ALL
SELECT id, 'Salón principal', 40 FROM public.sucursales WHERE nombre ILIKE '%cervecer%'
UNION ALL
SELECT id, 'Zona general', 50 FROM public.sucursales WHERE nombre ILIKE '%brisas%'
UNION ALL
SELECT id, 'Zona general', 50 FROM public.sucursales WHERE nombre ILIKE '%solares%';