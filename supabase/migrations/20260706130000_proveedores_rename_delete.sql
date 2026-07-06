-- =====================================================================
-- Ajuste de proveedores (jul-2026):
--   · Renombrar: Camarinay -> Marinay, Berkins -> Berkis (y su slug de liga).
--   · Eliminar 5 proveedores (la FK ON DELETE CASCADE borra sus productos y
--     precios automáticamente).
-- Idempotente.
-- =====================================================================

-- Renombrar (nombre + slug de la liga para que quede coherente)
UPDATE public.proveedores SET nombre = 'Marinay', token = 'marinay' WHERE nombre = 'Camarinay';
UPDATE public.proveedores SET nombre = 'Berkis',  token = 'berkis'  WHERE nombre = 'Berkins';

-- Eliminar proveedores (cascada: se van sus proveedor_productos y proveedor_precios)
DELETE FROM public.proveedores
WHERE nombre IN (
  'Callo de Hacha Sonora',
  'El Pollo',
  'La Sierra Pescadería',
  'Proveedor Pizzas',
  'Proveedor Ostión'
);

NOTIFY pgrst, 'reload schema';
