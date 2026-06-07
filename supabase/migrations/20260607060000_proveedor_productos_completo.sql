-- =====================================================================
-- TODOS los proveedores con el 100% de los productos (lista completa).
-- El admin depura por proveedor desde el panel (quitar = desactivar).
-- Idempotente: limpia y resiembra parejo. Correr en SQL editor.
-- =====================================================================

-- 1) Limpiar productos actuales (resembramos igual para todos).
DELETE FROM public.proveedor_productos;

-- 2) Lista completa (26 productos) a CADA proveedor.
INSERT INTO public.proveedor_productos (proveedor_id, nombre, unidad, insumo_id, activo)
SELECT p.id, x.prod, x.unidad,
       (SELECT i.id FROM public.insumos i WHERE i.nombre = x.insumo_match LIMIT 1),
       true
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
    ('Atún steak', 'kg', NULL),
    ('Marlin / Atún ahumado', 'kg', 'MARLIN AHUMADO K.'),
    ('Róbalo chico', 'kg', 'ROBALO (chicharrón)'),
    ('Róbalo filete', 'kg', 'ROBALO (filete)'),
    ('Sierra', 'kg', 'SIERRA'),
    ('Callo de hacha', 'kg', 'CALLO DE HACHA'),
    ('Ostión', 'bolsa', 'BOLSAS OSTIÓN'),
    ('Pescado p/sarandear', 'pz', 'PESCADO P/SARANDEAR'),
    ('Filete de res', 'kg', 'FILETE DE RES'),
    ('Costilla de cerdo', 'kg', 'COSTILLA DE CERDO'),
    ('Alitas', 'kg', 'ALITAS'),
    ('Boneless', 'kg', 'BONELESS'),
    ('Cubos de pechuga', 'pz', NULL),
    ('Pizzas', 'pz', 'PIZZAS')
) AS x(prod, unidad, insumo_match)
CROSS JOIN public.proveedores p
ON CONFLICT (proveedor_id, nombre) DO NOTHING;

NOTIFY pgrst, 'reload schema';
