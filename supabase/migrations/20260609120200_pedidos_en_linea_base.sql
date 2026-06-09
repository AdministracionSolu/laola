-- ============================================================
-- PEDIDOS EN LÍNEA — Configuración base por sucursal
-- Sucursales reales en DB: 'Del Valle', 'Las Brisas', 'Cervecería', 'Solares'
-- ============================================================

-- Crea las sucursales que falten (idempotente; en producción ya existen las 4)
INSERT INTO public.sucursales (nombre, direccion)
SELECT v.nombre, v.direccion
FROM (VALUES
  ('Del Valle',  'Cd. del Valle, Tepic, Nayarit'),
  ('Las Brisas', 'Las Brisas, Tepic, Nayarit'),
  ('Cervecería', 'Col. Versalles, Tepic, Nayarit'),
  ('Solares',    'Solares, Zapopan, Jalisco')
) AS v(nombre, direccion)
WHERE NOT EXISTS (SELECT 1 FROM public.sucursales s WHERE s.nombre = v.nombre);

-- Prefijo de folio, slug público y zona horaria
UPDATE public.sucursales SET prefijo_folio = 'VAL', slug = 'del-valle',  zona_horaria = 'America/Mazatlan'    WHERE nombre = 'Del Valle';
UPDATE public.sucursales SET prefijo_folio = 'BRI', slug = 'las-brisas', zona_horaria = 'America/Mazatlan'    WHERE nombre = 'Las Brisas';
UPDATE public.sucursales SET prefijo_folio = 'CER', slug = 'cerveceria', zona_horaria = 'America/Mazatlan'    WHERE nombre = 'Cervecería';
UPDATE public.sucursales SET prefijo_folio = 'SOL', slug = 'solares',    zona_horaria = 'America/Mexico_City' WHERE nombre = 'Solares';

-- Zonas de reparto placeholder (inactivas; el dueño captura las reales en el panel)
INSERT INTO public.zonas_reparto (sucursal_id, nombre, costo_envio, pedido_minimo, activa)
SELECT s.id, z.nombre, 35, 0, false
FROM public.sucursales s
CROSS JOIN (VALUES ('ZONA PENDIENTE 1'), ('ZONA PENDIENTE 2')) AS z(nombre)
WHERE s.nombre IN ('Del Valle','Las Brisas','Cervecería','Solares')
  AND NOT EXISTS (
    SELECT 1 FROM public.zonas_reparto zr
    WHERE zr.sucursal_id = s.id AND zr.nombre = z.nombre
  );

-- Horarios placeholder: todos los días 11:00–21:00 (editables desde el panel)
INSERT INTO public.horarios_sucursal (sucursal_id, dia_semana, hora_apertura, hora_cierre, activo)
SELECT s.id, d.dia, '11:00'::time, '21:00'::time, true
FROM public.sucursales s
CROSS JOIN generate_series(0, 6) AS d(dia)
WHERE s.nombre IN ('Del Valle','Las Brisas','Cervecería','Solares')
  AND NOT EXISTS (
    SELECT 1 FROM public.horarios_sucursal h
    WHERE h.sucursal_id = s.id AND h.dia_semana = d.dia
  );
