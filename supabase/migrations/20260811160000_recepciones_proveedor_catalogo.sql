-- =====================================================================
-- Recepciones · el proveedor deja de ser texto libre
--
-- Hoy `recepciones.proveedor` se teclea a mano y por eso el mismo proveedor
-- vive con varios nombres: "Miguel duran" es Marinay, "Chepe" es La Sierra,
-- "Marina y" es un dedazo, y "Dummy" sigue apareciendo un mes después de
-- darlo de baja. Así no se puede cruzar precio contra compra sin hacerlo a
-- mano cada vez.
--
--   1. Se agrega La Sierra Pescadería al catálogo (nunca estuvo dada de alta).
--   2. Tabla de alias: cada forma de teclear un nombre apunta a un proveedor.
--   3. `recepciones.proveedor_id` + relleno del histórico por alias.
--   4. El texto original se conserva en `proveedor`: no se pierde nada.
-- =====================================================================

-- ---- 1. El proveedor que faltaba -----------------------------------------
INSERT INTO public.proveedores (nombre, categoria, activo)
SELECT 'La Sierra Pescadería', 'Marisco', true
WHERE NOT EXISTS (
  SELECT 1 FROM public.proveedores WHERE nombre = 'La Sierra Pescadería'
);

-- ---- 2. Normalizador y tabla de alias ------------------------------------
CREATE OR REPLACE FUNCTION public.norm_proveedor(txt text)
RETURNS text
LANGUAGE sql IMMUTABLE
AS $$
  SELECT regexp_replace(
           upper(translate(coalesce(txt, ''),
                           'áéíóúüñÁÉÍÓÚÜÑ', 'aeiouunAEIOUUN')),
           '[^A-Z0-9]+', ' ', 'g')
$$;
-- Nota: el trim va aparte porque regexp_replace deja espacios en los bordes.

CREATE TABLE IF NOT EXISTS public.proveedor_alias (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  proveedor_id uuid NOT NULL REFERENCES public.proveedores(id) ON DELETE CASCADE,
  alias        text NOT NULL,
  alias_norm   text GENERATED ALWAYS AS (btrim(public.norm_proveedor(alias))) STORED,
  created_at   timestamptz NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS proveedor_alias_norm_uk ON public.proveedor_alias (alias_norm);

ALTER TABLE public.proveedor_alias ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS proveedor_alias_lectura ON public.proveedor_alias;
CREATE POLICY proveedor_alias_lectura ON public.proveedor_alias
  FOR SELECT TO anon, authenticated USING (true);
DROP POLICY IF EXISTS proveedor_alias_escritura ON public.proveedor_alias;
CREATE POLICY proveedor_alias_escritura ON public.proveedor_alias
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- El nombre propio de cada proveedor es su primer alias.
INSERT INTO public.proveedor_alias (proveedor_id, alias)
SELECT p.id, p.nombre FROM public.proveedores p
ON CONFLICT (alias_norm) DO NOTHING;

-- Alias confirmados por Diego el 11-ago-2026 + los dedazos que hay en la base.
INSERT INTO public.proveedor_alias (proveedor_id, alias)
SELECT p.id, v.alias
FROM (VALUES
  ('Marinay',              'Miguel Duran'),
  ('Marinay',              'Miguel Durán'),
  ('Marinay',              'Marina y'),
  ('La Sierra Pescadería', 'Chepe'),
  ('La Sierra Pescadería', 'La sierra'),
  ('El Charal',            'Charal')
) AS v(proveedor, alias)
JOIN public.proveedores p ON p.nombre = v.proveedor
ON CONFLICT (alias_norm) DO NOTHING;

-- ---- 3. La recepción apunta al proveedor ---------------------------------
ALTER TABLE public.recepciones
  ADD COLUMN IF NOT EXISTS proveedor_id uuid REFERENCES public.proveedores(id);

CREATE INDEX IF NOT EXISTS recepciones_proveedor_id_idx ON public.recepciones (proveedor_id);

COMMENT ON COLUMN public.recepciones.proveedor_id IS
  'Proveedor del catálogo. `proveedor` conserva el texto tal cual se capturó.';

-- ---- 4. Relleno del histórico --------------------------------------------
UPDATE public.recepciones r
SET proveedor_id = a.proveedor_id
FROM public.proveedor_alias a
WHERE r.proveedor_id IS NULL
  AND btrim(public.norm_proveedor(r.proveedor)) = a.alias_norm;

-- Lo que quedó sin resolver se revisa a mano; no se inventa nada:
--   SELECT proveedor, count(*) FROM recepciones
--   WHERE proveedor_id IS NULL GROUP BY 1 ORDER BY 2 DESC;
