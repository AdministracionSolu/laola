-- =====================================================================
-- Feature 3 — Proveedores, productos y precios (compra estratégica)
-- Self-service por token (sin login) aislado vía RPCs SECURITY DEFINER.
-- Idempotente.
-- =====================================================================

-- ---------------------------------------------------------------------
-- Tablas
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.proveedores (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre     text NOT NULL,
  categoria  text,
  contacto   text,
  telefono   text,
  token      text NOT NULL UNIQUE DEFAULT replace(gen_random_uuid()::text, '-', ''),
  activo     boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.proveedor_productos (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  proveedor_id uuid NOT NULL REFERENCES public.proveedores(id) ON DELETE CASCADE,
  nombre       text NOT NULL,
  unidad       text DEFAULT 'kg',
  insumo_id    uuid REFERENCES public.insumos(id) ON DELETE SET NULL,  -- mapeo opcional
  activo       boolean NOT NULL DEFAULT true,
  created_at   timestamptz NOT NULL DEFAULT now(),
  UNIQUE (proveedor_id, nombre)
);

CREATE TABLE IF NOT EXISTS public.proveedor_precios (
  id                    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  proveedor_producto_id uuid NOT NULL REFERENCES public.proveedor_productos(id) ON DELETE CASCADE,
  precio                numeric NOT NULL,
  created_at            timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_prov_precios_prod
  ON public.proveedor_precios (proveedor_producto_id, created_at DESC);

-- ---------------------------------------------------------------------
-- RLS: sin acceso directo para anon (los proveedores entran por RPC).
--      Lectura interna para authenticated (panel admin); gestión solo admin.
-- ---------------------------------------------------------------------
ALTER TABLE public.proveedores         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.proveedor_productos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.proveedor_precios   ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "lectura interna proveedores" ON public.proveedores;
CREATE POLICY "lectura interna proveedores" ON public.proveedores
  FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "admin gestiona proveedores" ON public.proveedores;
CREATE POLICY "admin gestiona proveedores" ON public.proveedores
  FOR ALL TO authenticated
  USING (has_role(auth.uid(), 'admin'::app_role))
  WITH CHECK (has_role(auth.uid(), 'admin'::app_role));

DROP POLICY IF EXISTS "lectura interna prov_productos" ON public.proveedor_productos;
CREATE POLICY "lectura interna prov_productos" ON public.proveedor_productos
  FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "admin gestiona prov_productos" ON public.proveedor_productos;
CREATE POLICY "admin gestiona prov_productos" ON public.proveedor_productos
  FOR ALL TO authenticated
  USING (has_role(auth.uid(), 'admin'::app_role))
  WITH CHECK (has_role(auth.uid(), 'admin'::app_role));

DROP POLICY IF EXISTS "lectura interna prov_precios" ON public.proveedor_precios;
CREATE POLICY "lectura interna prov_precios" ON public.proveedor_precios
  FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "admin gestiona prov_precios" ON public.proveedor_precios;
CREATE POLICY "admin gestiona prov_precios" ON public.proveedor_precios
  FOR ALL TO authenticated
  USING (has_role(auth.uid(), 'admin'::app_role))
  WITH CHECK (has_role(auth.uid(), 'admin'::app_role));

-- ---------------------------------------------------------------------
-- RPCs self-service por token (aislamiento por proveedor)
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.prov_catalogo(p_token text)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE v_prov public.proveedores; v_result jsonb;
BEGIN
  SELECT * INTO v_prov FROM public.proveedores WHERE token = p_token AND activo;
  IF NOT FOUND THEN RETURN NULL; END IF;
  SELECT jsonb_build_object(
    'proveedor', jsonb_build_object('nombre', v_prov.nombre, 'categoria', v_prov.categoria),
    'productos', COALESCE((
      SELECT jsonb_agg(jsonb_build_object(
        'id', pp.id,
        'nombre', pp.nombre,
        'unidad', pp.unidad,
        'precio_vigente', (SELECT pr.precio FROM public.proveedor_precios pr
                           WHERE pr.proveedor_producto_id = pp.id
                           ORDER BY pr.created_at DESC LIMIT 1),
        'precio_fecha', (SELECT pr.created_at FROM public.proveedor_precios pr
                         WHERE pr.proveedor_producto_id = pp.id
                         ORDER BY pr.created_at DESC LIMIT 1)
      ) ORDER BY pp.nombre)
      FROM public.proveedor_productos pp
      WHERE pp.proveedor_id = v_prov.id AND pp.activo
    ), '[]'::jsonb)
  ) INTO v_result;
  RETURN v_result;
END $$;

CREATE OR REPLACE FUNCTION public.prov_set_precio(p_token text, p_producto_id uuid, p_precio numeric)
RETURNS boolean
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE v_prov_id uuid;
BEGIN
  SELECT id INTO v_prov_id FROM public.proveedores WHERE token = p_token AND activo;
  IF v_prov_id IS NULL THEN RETURN false; END IF;
  IF p_precio IS NULL OR p_precio < 0 THEN RETURN false; END IF;
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

CREATE OR REPLACE FUNCTION public.prov_add_producto(p_token text, p_nombre text, p_unidad text)
RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE v_prov_id uuid; v_id uuid;
BEGIN
  SELECT id INTO v_prov_id FROM public.proveedores WHERE token = p_token AND activo;
  IF v_prov_id IS NULL THEN RETURN NULL; END IF;
  IF p_nombre IS NULL OR length(trim(p_nombre)) = 0 THEN RETURN NULL; END IF;
  INSERT INTO public.proveedor_productos (proveedor_id, nombre, unidad)
  VALUES (v_prov_id, trim(p_nombre), COALESCE(NULLIF(trim(p_unidad), ''), 'kg'))
  ON CONFLICT (proveedor_id, nombre) DO UPDATE SET activo = true
  RETURNING id INTO v_id;
  RETURN v_id;
END $$;

-- anon ejecuta los RPC (cada uno valida el token internamente).
REVOKE ALL ON FUNCTION public.prov_catalogo(text) FROM public;
REVOKE ALL ON FUNCTION public.prov_set_precio(text, uuid, numeric) FROM public;
REVOKE ALL ON FUNCTION public.prov_add_producto(text, text, text) FROM public;
GRANT EXECUTE ON FUNCTION public.prov_catalogo(text) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.prov_set_precio(text, uuid, numeric) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.prov_add_producto(text, text, text) TO anon, authenticated;

-- ---------------------------------------------------------------------
-- Seed de proveedores (idempotente por teléfono)
-- ---------------------------------------------------------------------
INSERT INTO public.proveedores (nombre, categoria, contacto, telefono)
SELECT n.nombre, n.categoria, n.contacto, n.telefono
FROM (VALUES
  ('El Charal',             'Marisco', 'Marielena Villela Acosta', '311 688 45 02'),
  ('Lindo Mar',             'Marisco', NULL,                        '311 270 35 26'),
  ('Camarinay',             'Marisco', 'Miguel Durán',              '311 122 67 27'),
  ('La Sierra Pescadería',  'Marisco', 'Antonio Santana "Chepe"',   '311 212 15 90'),
  ('Callo de Hacha Sonora', 'Marisco', 'Amin E. Mondad',            '311 142 54 39'),
  ('El Pollo',              'Marisco', NULL,                        '311 250 71 40'),
  ('Proveedor Ostión',      'Marisco', 'Juana',                     '311 340 92 79'),
  ('Madenay',               'Marisco', 'Efraín',                    '311 269 56 19'),
  ('Berkins',               'Carnes',  NULL,                        '311 211 35 07'),
  ('Dumy',                  'Carnes',  NULL,                        '311 847 89 51'),
  ('Proveedor Pizzas',      'Pizzas',  'Mario',                     '311 246 01 08')
) AS n(nombre, categoria, contacto, telefono)
WHERE NOT EXISTS (SELECT 1 FROM public.proveedores p WHERE p.telefono = n.telefono);

-- ---------------------------------------------------------------------
-- Seed de productos por proveedor (mapeo a insumo interno donde es claro)
-- ---------------------------------------------------------------------
INSERT INTO public.proveedor_productos (proveedor_id, nombre, unidad, insumo_id)
SELECT p.id, x.prod, x.unidad,
       (SELECT i.id FROM public.insumos i WHERE i.nombre = x.insumo_match LIMIT 1)
FROM (VALUES
  -- El Charal
  ('311 688 45 02', 'Camarón 21/25',            'kg', 'CAMARON 21-25'),
  ('311 688 45 02', 'Camarón 31/35',            'kg', 'CAMARON 31-35'),
  ('311 688 45 02', 'Camarón 61/70',            'kg', 'CAMARON 61-70'),
  ('311 688 45 02', 'Atún steak',               'kg',  NULL),
  ('311 688 45 02', 'Atún ahumado tipo Marlin', 'kg', 'MARLIN AHUMADO K.'),
  ('311 688 45 02', 'Pulpo 2-4',                'kg', 'PULPO 2-4'),
  -- Lindo Mar
  ('311 270 35 26', 'Camarón 19g',              'kg',  NULL),
  ('311 270 35 26', 'Camarón fresco',           'kg',  NULL),
  -- Camarinay
  ('311 122 67 27', 'Camarón 21-25',            'kg', 'CAMARON 21-25'),
  ('311 122 67 27', 'Camarón 31-35',            'kg', 'CAMARON 31-35'),
  ('311 122 67 27', 'Camarón 51-60',            'kg',  NULL),
  ('311 122 67 27', 'Medallón',                 'pz', 'ATÚN MEDALLON pz'),
  ('311 122 67 27', 'Marlin',                   'kg', 'MARLIN AHUMADO K.'),
  -- La Sierra Pescadería
  ('311 212 15 90', 'Róbalo',                   'kg', 'ROBALO (filete)'),
  ('311 212 15 90', 'Sierra',                   'kg', 'SIERRA'),
  -- Callo de Hacha Sonora
  ('311 142 54 39', 'Callo de hacha',           'kg', 'CALLO DE HACHA'),
  -- El Pollo
  ('311 250 71 40', 'Camarón seco',             'kg', 'CAMARON SECO K.'),
  -- Proveedor Ostión (Juana)
  ('311 340 92 79', 'Ostión',                   'bolsa', 'BOLSAS OSTIÓN'),
  -- Madenay
  ('311 269 56 19', 'Camarón',                  'kg',  NULL),
  -- Berkins
  ('311 211 35 07', 'Carnes y cortes',          'kg',  NULL),
  -- Dumy
  ('311 847 89 51', 'Cubos de pechuga precocinado 2kg (Pelgrims)', 'pz', NULL),
  -- Proveedor Pizzas (Mario)
  ('311 246 01 08', 'Pizzas',                   'pz', 'PIZZAS')
) AS x(telefono, prod, unidad, insumo_match)
JOIN public.proveedores p ON p.telefono = x.telefono
ON CONFLICT (proveedor_id, nombre) DO NOTHING;

-- Forzar a PostgREST a refrescar el esquema (ver tablas/funciones nuevas)
NOTIFY pgrst, 'reload schema';
