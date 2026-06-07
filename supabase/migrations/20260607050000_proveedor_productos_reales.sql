-- =====================================================================
-- Dejar a cada proveedor con sus PRODUCTOS REALES (revierte la lista maestra).
-- Idempotente. Correr en el SQL editor.
-- =====================================================================

-- 1) Asegurar/actualizar los productos reales (nombre + unidad + mapeo a insumo).
INSERT INTO public.proveedor_productos (proveedor_id, nombre, unidad, insumo_id, activo)
SELECT p.id, x.prod, x.unidad,
       (SELECT i.id FROM public.insumos i WHERE i.nombre = x.insumo_match LIMIT 1),
       true
FROM (VALUES
    ('311 688 45 02', 'Camarón 21/25', 'kg', 'CAMARON 21-25'),
    ('311 688 45 02', 'Camarón 31/35', 'kg', 'CAMARON 31-35'),
    ('311 688 45 02', 'Camarón 61/70', 'kg', 'CAMARON 61-70'),
    ('311 688 45 02', 'Atún steak', 'kg', 'ATÚN MEDALLON pz'),
    ('311 688 45 02', 'Atún ahumado tipo Marlin', 'kg', 'MARLIN AHUMADO K.'),
    ('311 688 45 02', 'Pulpo 2-4', 'kg', 'PULPO 2-4'),
    ('311 270 35 26', 'Camarón 19g', 'kg', NULL),
    ('311 270 35 26', 'Camarón fresco', 'kg', NULL),
    ('311 122 67 27', 'Camarón 21-25', 'kg', 'CAMARON 21-25'),
    ('311 122 67 27', 'Camarón 31-35', 'kg', 'CAMARON 31-35'),
    ('311 122 67 27', 'Camarón 51-60', 'kg', NULL),
    ('311 122 67 27', 'Medallón', 'pz', 'ATÚN MEDALLON pz'),
    ('311 122 67 27', 'Marlin', 'kg', 'MARLIN AHUMADO K.'),
    ('311 212 15 90', 'Róbalo', 'kg', 'ROBALO (filete)'),
    ('311 212 15 90', 'Sierra', 'kg', 'SIERRA'),
    ('311 142 54 39', 'Callo de hacha', 'kg', 'CALLO DE HACHA'),
    ('311 250 71 40', 'Camarón seco', 'kg', 'CAMARON SECO K.'),
    ('311 340 92 79', 'Ostión', 'bolsa', 'BOLSAS OSTIÓN'),
    ('311 269 56 19', 'Camarón', 'kg', NULL),
    ('311 211 35 07', 'Carnes y cortes', 'kg', NULL),
    ('311 847 89 51', 'Cubos de pechuga precocinado 2kg (Pelgrims)', 'pz', NULL),
    ('311 246 01 08', 'Pizzas', 'pz', 'PIZZAS')
) AS x(telefono, prod, unidad, insumo_match)
JOIN public.proveedores p ON p.telefono = x.telefono
ON CONFLICT (proveedor_id, nombre)
  DO UPDATE SET unidad = EXCLUDED.unidad, insumo_id = EXCLUDED.insumo_id, activo = true;

-- 2) Borrar de cada proveedor todo lo que NO esté en su lista real (la inflación del seed maestro).
DELETE FROM public.proveedor_productos pp
USING public.proveedores p
WHERE pp.proveedor_id = p.id
  AND NOT EXISTS (
    SELECT 1 FROM (VALUES
    ('311 688 45 02', 'Camarón 21/25', 'kg', 'CAMARON 21-25'),
    ('311 688 45 02', 'Camarón 31/35', 'kg', 'CAMARON 31-35'),
    ('311 688 45 02', 'Camarón 61/70', 'kg', 'CAMARON 61-70'),
    ('311 688 45 02', 'Atún steak', 'kg', 'ATÚN MEDALLON pz'),
    ('311 688 45 02', 'Atún ahumado tipo Marlin', 'kg', 'MARLIN AHUMADO K.'),
    ('311 688 45 02', 'Pulpo 2-4', 'kg', 'PULPO 2-4'),
    ('311 270 35 26', 'Camarón 19g', 'kg', NULL),
    ('311 270 35 26', 'Camarón fresco', 'kg', NULL),
    ('311 122 67 27', 'Camarón 21-25', 'kg', 'CAMARON 21-25'),
    ('311 122 67 27', 'Camarón 31-35', 'kg', 'CAMARON 31-35'),
    ('311 122 67 27', 'Camarón 51-60', 'kg', NULL),
    ('311 122 67 27', 'Medallón', 'pz', 'ATÚN MEDALLON pz'),
    ('311 122 67 27', 'Marlin', 'kg', 'MARLIN AHUMADO K.'),
    ('311 212 15 90', 'Róbalo', 'kg', 'ROBALO (filete)'),
    ('311 212 15 90', 'Sierra', 'kg', 'SIERRA'),
    ('311 142 54 39', 'Callo de hacha', 'kg', 'CALLO DE HACHA'),
    ('311 250 71 40', 'Camarón seco', 'kg', 'CAMARON SECO K.'),
    ('311 340 92 79', 'Ostión', 'bolsa', 'BOLSAS OSTIÓN'),
    ('311 269 56 19', 'Camarón', 'kg', NULL),
    ('311 211 35 07', 'Carnes y cortes', 'kg', NULL),
    ('311 847 89 51', 'Cubos de pechuga precocinado 2kg (Pelgrims)', 'pz', NULL),
    ('311 246 01 08', 'Pizzas', 'pz', 'PIZZAS')
    ) AS x(telefono, prod, unidad, insumo_match)
    WHERE x.telefono = p.telefono AND x.prod = pp.nombre
  );

NOTIFY pgrst, 'reload schema';
