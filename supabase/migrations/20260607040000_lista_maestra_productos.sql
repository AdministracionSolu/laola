-- =====================================================================
-- Lista maestra de productos por categoría (precarga). Idempotente.
-- Cada proveedor arranca con todas las tallas de su categoría; el admin
-- recorta desde el panel. ON CONFLICT no duplica ni pisa lo existente.
-- =====================================================================

-- Mariscos (8 proveedores)
INSERT INTO public.proveedor_productos (proveedor_id, nombre, unidad, insumo_id)
SELECT p.id, x.prod, x.unidad,
       (SELECT i.id FROM public.insumos i WHERE i.nombre = x.insumo_match LIMIT 1)
FROM (VALUES
    ('Camarón 61/70', 'kg', 'CAMARON 61-70'),
    ('Camarón 31/35', 'kg', 'CAMARON 31-35'),
    ('Camarón 21/25', 'kg', 'CAMARON 21-25'),
    ('Camarón 51/60', 'kg', NULL),
    ('Camarón 19g', 'kg', NULL),
    ('Camarón vapor 25-30', 'kg', 'CAMARON VAPOR 25 a 30 gr'),
    ('Camarón 7-11', 'kg', 'CAMARON 7 A 11 GR'),
    ('Camarón 12-25', 'kg', 'CAMARON 12 - 25 GR'),
    ('Camarón seco', 'kg', 'CAMARON SECO K.'),
    ('Camarón fresco', 'kg', NULL),
    ('Pulpo 2-4', 'kg', 'PULPO 2-4'),
    ('Atún medallón', 'pz', 'ATÚN MEDALLON pz'),
    ('Marlin / Atún ahumado', 'kg', 'MARLIN AHUMADO K.'),
    ('Róbalo chico', 'kg', 'ROBALO (chicharrón)'),
    ('Róbalo filete', 'kg', 'ROBALO (filete)'),
    ('Sierra', 'kg', 'SIERRA'),
    ('Callo de hacha', 'kg', 'CALLO DE HACHA'),
    ('Ostión', 'bolsa', 'BOLSAS OSTIÓN'),
    ('Pescado p/sarandear', 'pz', 'PESCADO P/SARANDEAR')
) AS x(prod, unidad, insumo_match)
CROSS JOIN public.proveedores p
WHERE p.telefono IN ('311 688 45 02', '311 270 35 26', '311 122 67 27', '311 212 15 90', '311 142 54 39', '311 250 71 40', '311 340 92 79', '311 269 56 19')
ON CONFLICT (proveedor_id, nombre) DO NOTHING;

-- Carnes (Berkins, Dumy)
INSERT INTO public.proveedor_productos (proveedor_id, nombre, unidad, insumo_id)
SELECT p.id, x.prod, x.unidad,
       (SELECT i.id FROM public.insumos i WHERE i.nombre = x.insumo_match LIMIT 1)
FROM (VALUES
    ('Filete de res', 'kg', 'FILETE DE RES'),
    ('Costilla de cerdo', 'kg', 'COSTILLA DE CERDO'),
    ('Alitas', 'kg', 'ALITAS'),
    ('Boneless', 'kg', 'BONELESS'),
    ('Cubos de pechuga', 'pz', NULL)
) AS x(prod, unidad, insumo_match)
CROSS JOIN public.proveedores p
WHERE p.telefono IN ('311 211 35 07', '311 847 89 51')
ON CONFLICT (proveedor_id, nombre) DO NOTHING;

-- Pizzas (Mario)
INSERT INTO public.proveedor_productos (proveedor_id, nombre, unidad, insumo_id)
SELECT p.id, x.prod, x.unidad,
       (SELECT i.id FROM public.insumos i WHERE i.nombre = x.insumo_match LIMIT 1)
FROM (VALUES
    ('Pizzas', 'pz', 'PIZZAS')
) AS x(prod, unidad, insumo_match)
CROSS JOIN public.proveedores p
WHERE p.telefono IN ('311 246 01 08')
ON CONFLICT (proveedor_id, nombre) DO NOTHING;

NOTIFY pgrst, 'reload schema';
