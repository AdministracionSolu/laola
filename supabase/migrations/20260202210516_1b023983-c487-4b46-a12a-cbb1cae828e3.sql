-- Agregar columna de plataforma a verificaciones_plataforma
ALTER TABLE public.verificaciones_plataforma 
ADD COLUMN plataforma TEXT NOT NULL DEFAULT 'total';

-- Comentario para documentar los valores válidos: 'rappi', 'uber', 'total'