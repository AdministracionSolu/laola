-- Agregar campos cobradas y por_cobrar a la tabla cortes_caja
ALTER TABLE public.cortes_caja 
ADD COLUMN cobradas numeric NOT NULL DEFAULT 0,
ADD COLUMN por_cobrar numeric NOT NULL DEFAULT 0;