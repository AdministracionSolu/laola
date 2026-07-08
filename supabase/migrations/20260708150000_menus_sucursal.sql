-- ============================================================
-- MENÚS POR SUCURSAL — QR estable + PDF cambiable desde el dashboard
-- Cada sucursal guarda la URL de su menú (PDF). El QR apunta a una ruta
-- estable /menu/s/<codigo> que redirige a esa URL; así el QR impreso no
-- cambia aunque se reemplace el PDF. Las contadoras/dueño actualizan el
-- menú desde Herramientas (sube PDF al bucket 'menus' o pega una URL).
-- ============================================================

-- URL del menú vigente de la sucursal (PDF público o liga externa).
ALTER TABLE public.sucursales
  ADD COLUMN IF NOT EXISTS menu_url text;

-- ---------- Bucket público para los PDFs de menú ----------
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('menus', 'menus', true, 20971520, ARRAY['application/pdf'])  -- 20 MB, solo PDF
ON CONFLICT (id) DO UPDATE
  SET public = EXCLUDED.public,
      file_size_limit = EXCLUDED.file_size_limit,
      allowed_mime_types = EXCLUDED.allowed_mime_types;

-- Lectura pública (el menú se abre desde el QR sin login).
DROP POLICY IF EXISTS "menus_lee_publico" ON storage.objects;
CREATE POLICY "menus_lee_publico" ON storage.objects
  FOR SELECT TO anon, authenticated
  USING (bucket_id = 'menus');

-- Solo el staff autenticado sube / reemplaza / borra menús.
DROP POLICY IF EXISTS "menus_admin_sube" ON storage.objects;
CREATE POLICY "menus_admin_sube" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'menus');

DROP POLICY IF EXISTS "menus_admin_actualiza" ON storage.objects;
CREATE POLICY "menus_admin_actualiza" ON storage.objects
  FOR UPDATE TO authenticated
  USING (bucket_id = 'menus') WITH CHECK (bucket_id = 'menus');

DROP POLICY IF EXISTS "menus_admin_borra" ON storage.objects;
CREATE POLICY "menus_admin_borra" ON storage.objects
  FOR DELETE TO authenticated
  USING (bucket_id = 'menus');

-- ---------- RPC para fijar el menú (staff autenticado) ----------
-- sucursales solo tiene policy de SELECT; el UPDATE va por esta función
-- SECURITY DEFINER para no abrir toda la tabla a escritura.
CREATE OR REPLACE FUNCTION public.sucursal_set_menu(
  p_sucursal_id uuid,
  p_menu_url text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $fn$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'NO_AUTORIZADO';
  END IF;
  UPDATE sucursales
     SET menu_url = NULLIF(trim(COALESCE(p_menu_url, '')), '')
   WHERE id = p_sucursal_id;
END;
$fn$;

GRANT EXECUTE ON FUNCTION public.sucursal_set_menu(uuid, text) TO authenticated;
