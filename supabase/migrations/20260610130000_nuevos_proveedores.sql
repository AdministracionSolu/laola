-- =====================================================================
-- Nuevos proveedores + actualización de teléfono de El Charal.
-- Tokens FIJOS y legibles para poder compartir la liga de inmediato.
-- Idempotente: usa ON CONFLICT / WHERE NOT EXISTS.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1) Alta de proveedores (token fijo = liga /proveedor/<token>)
-- ---------------------------------------------------------------------
INSERT INTO public.proveedores (nombre, categoria, contacto, telefono, token)
VALUES
  ('Henderson',             'Carnes',  NULL, '+52 669 334 3166',   'henderson'),
  ('Capital Camaronera',    'Marisco', NULL, '+52 1 311 227 6299', 'capitalcamaronera'),
  ('Guamuchilito',          'Marisco', NULL, '311 137 3464',       'guamuchilito')
ON CONFLICT (token) DO UPDATE
  SET nombre    = EXCLUDED.nombre,
      categoria = EXCLUDED.categoria,
      telefono  = EXCLUDED.telefono,
      activo    = true;

-- ---------------------------------------------------------------------
-- 2) Actualizar el teléfono de El Charal (conserva su liga/token actual)
-- ---------------------------------------------------------------------
UPDATE public.proveedores
SET telefono = '311 103 4874'
WHERE nombre = 'El Charal';

-- ---------------------------------------------------------------------
-- 3) Productos por proveedor (mapeo a insumo interno donde es claro)
-- ---------------------------------------------------------------------
INSERT INTO public.proveedor_productos (proveedor_id, nombre, unidad, insumo_id, activo)
SELECT p.id, x.prod, x.unidad,
       (SELECT i.id FROM public.insumos i WHERE i.nombre = x.insumo_match LIMIT 1),
       true
FROM (VALUES
  -- Henderson
  ('henderson', 'Filete de Res',      'kg', 'FILETE DE RES'),
  ('henderson', 'Papas punta cáscara','kg',  NULL),
  ('henderson', 'Papa gajo',          'kg',  NULL),
  ('henderson', 'Medallón de atún',   'pz',  NULL),
  ('henderson', 'Nuggets',            'kg',  NULL),
  ('henderson', 'Molida',             'kg',  NULL),
  ('henderson', 'Sirloin',            'kg',  NULL),
  ('henderson', 'Diezmillo',          'kg',  NULL),
  ('henderson', 'Aros',               'kg',  NULL),
  ('henderson', 'Boneless',           'kg', 'BONELESS'),
  ('henderson', 'Alitas',             'kg', 'ALITAS'),
  ('henderson', 'Dedos de queso',     'kg',  NULL),
  -- Capital Camaronera (el proveedor define gramaje y precio en su liga)
  ('capitalcamaronera', 'Camarón fresco', 'kg', NULL),
  -- Guamuchilito (el proveedor define gramaje y precio en su liga)
  ('guamuchilito',      'Camarón fresco', 'kg', NULL)
) AS x(token, prod, unidad, insumo_match)
JOIN public.proveedores p ON p.token = x.token
ON CONFLICT (proveedor_id, nombre) DO NOTHING;

NOTIFY pgrst, 'reload schema';
