-- Crear enum para tipo de corte
CREATE TYPE public.tipo_corte AS ENUM ('momento', 'cierre');

-- Crear tabla de sucursales
CREATE TABLE public.sucursales (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  nombre TEXT NOT NULL,
  direccion TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Insertar las 4 sucursales
INSERT INTO public.sucursales (nombre, direccion) VALUES
  ('Del Valle', 'Av. Cuauhtémoc 1234, Del Valle, CDMX'),
  ('Insurgentes', 'Insurgentes Sur 567, Roma, CDMX'),
  ('Las Brisas', 'Blvd. Las Brisas 890, Acapulco'),
  ('Solares', 'Av. Solares 234, Guadalajara');

-- Crear tabla de cortes de caja
CREATE TABLE public.cortes_caja (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  sucursal_id UUID NOT NULL REFERENCES public.sucursales(id) ON DELETE CASCADE,
  tipo_corte public.tipo_corte NOT NULL,
  corte_x DECIMAL(12,2) NOT NULL DEFAULT 0,
  tarjetas DECIMAL(12,2) NOT NULL DEFAULT 0,
  efectivo DECIMAL(12,2) NOT NULL DEFAULT 0,
  total DECIMAL(12,2) NOT NULL DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Habilitar RLS en ambas tablas
ALTER TABLE public.sucursales ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cortes_caja ENABLE ROW LEVEL SECURITY;

-- Políticas para sucursales: todos pueden leer (para el dropdown)
CREATE POLICY "Cualquiera puede ver sucursales"
ON public.sucursales
FOR SELECT
USING (true);

-- Políticas para cortes_caja: cualquiera puede insertar (cajeras sin login)
CREATE POLICY "Cualquiera puede insertar cortes"
ON public.cortes_caja
FOR INSERT
WITH CHECK (true);

-- Solo usuarios autenticados pueden ver cortes (admin)
CREATE POLICY "Solo autenticados pueden ver cortes"
ON public.cortes_caja
FOR SELECT
TO authenticated
USING (true);

-- Crear tabla de roles de usuario (para admin)
CREATE TYPE public.app_role AS ENUM ('admin', 'user');

CREATE TABLE public.user_roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  role public.app_role NOT NULL,
  UNIQUE (user_id, role)
);

ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;

-- Función para verificar roles (evita recursión en RLS)
CREATE OR REPLACE FUNCTION public.has_role(_user_id UUID, _role public.app_role)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.user_roles
    WHERE user_id = _user_id
      AND role = _role
  )
$$;

-- Política para que admins vean roles
CREATE POLICY "Admins pueden ver roles"
ON public.user_roles
FOR SELECT
TO authenticated
USING (public.has_role(auth.uid(), 'admin') OR user_id = auth.uid());

-- Índices para mejor rendimiento
CREATE INDEX idx_cortes_sucursal ON public.cortes_caja(sucursal_id);
CREATE INDEX idx_cortes_fecha ON public.cortes_caja(created_at DESC);
CREATE INDEX idx_cortes_tipo ON public.cortes_caja(tipo_corte);