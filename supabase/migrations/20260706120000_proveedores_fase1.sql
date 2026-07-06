-- =====================================================================
-- Fase 1 Proveedores — ligas legibles + el proveedor ya NO crea productos.
-- No toca proveedor_productos ni proveedor_precios (las listas ya son las
-- finales). Idempotente.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1) Tokens legibles (slug) para TODOS los proveedores.
--    Los 3 nuevos ya tienen slug (henderson, capitalcamaronera, guamuchilito).
--    Aquí se les da slug a los 11 originales, que tenían token aleatorio.
--    Idempotente: solo actualiza si el token difiere del slug destino.
-- ---------------------------------------------------------------------
UPDATE public.proveedores p
SET token = s.slug
FROM (VALUES
  ('El Charal',             'el-charal'),
  ('Lindo Mar',             'lindo-mar'),
  ('Camarinay',             'camarinay'),
  ('La Sierra Pescadería',  'la-sierra'),
  ('Callo de Hacha Sonora', 'callo-de-hacha'),
  ('El Pollo',              'el-pollo'),
  ('Proveedor Ostión',      'ostion'),
  ('Madenay',               'madenay'),
  ('Berkins',               'berkins'),
  ('Dumy',                  'dumy'),
  ('Proveedor Pizzas',      'pizzas')
) AS s(nombre, slug)
WHERE p.nombre = s.nombre
  AND p.token IS DISTINCT FROM s.slug
  -- No pisar un slug que ya pertenezca a OTRO proveedor (seguridad ante UNIQUE).
  AND NOT EXISTS (
    SELECT 1 FROM public.proveedores q
    WHERE q.token = s.slug AND q.id <> p.id
  );

-- ---------------------------------------------------------------------
-- 2) Retirar prov_add_producto: el proveedor solo sube precios; los
--    productos los administra el dueño desde el panel autenticado.
-- ---------------------------------------------------------------------
REVOKE ALL ON FUNCTION public.prov_add_producto(text, text, text) FROM anon, authenticated;
DROP FUNCTION IF EXISTS public.prov_add_producto(text, text, text);

NOTIFY pgrst, 'reload schema';
