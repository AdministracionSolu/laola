-- Tabla para registros de contadoras (verificación de ingresos por plataforma)
CREATE TABLE public.verificaciones_plataforma (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  sucursal_id UUID NOT NULL REFERENCES public.sucursales(id) ON DELETE CASCADE,
  fecha_inicio DATE NOT NULL,
  fecha_fin DATE NOT NULL,
  cantidad_reportada NUMERIC NOT NULL DEFAULT 0,
  cantidad_sistema NUMERIC NOT NULL DEFAULT 0,
  diferencia NUMERIC NOT NULL DEFAULT 0,
  tiene_discrepancia BOOLEAN NOT NULL DEFAULT false,
  registrado_por TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Habilitar RLS
ALTER TABLE public.verificaciones_plataforma ENABLE ROW LEVEL SECURITY;

-- Políticas RLS
CREATE POLICY "Cualquiera puede crear verificaciones" 
ON public.verificaciones_plataforma 
FOR INSERT 
WITH CHECK (true);

CREATE POLICY "Cualquiera puede ver verificaciones" 
ON public.verificaciones_plataforma 
FOR SELECT 
USING (true);

CREATE POLICY "Solo admins pueden eliminar verificaciones" 
ON public.verificaciones_plataforma 
FOR DELETE 
USING (has_role(auth.uid(), 'admin'::app_role));