-- ============================================================
-- HORARIOS REALES (tomados de la landing laola.mx / Sucursales.tsx)
-- Pegar en el SQL Editor cuando terminen las PRUEBAS 24/7.
-- Reemplaza por completo los horarios de pedidos en línea.
--
--   Del Valle    todos los días 10:00–23:59
--   Las Brisas   todos los días 10:00–18:00
--   Solares      todos los días 11:00–20:00
--   Cervecería   Dom–Mié 11:00–23:59 · Jue–Sáb 11:00–02:00 (cierra de madrugada;
--                las colas de madrugada se modelan como rangos 00:00–02:00 del día siguiente)
--
-- OJO: es el horario del restaurante. Si los pedidos en línea deben cortar
-- antes (ej. cocina cierra 30 min antes), ajustar las horas de cierre aquí
-- o desde el panel (Configuración → Horario).
-- ============================================================

-- Limpia los horarios actuales (los de prueba 24/7)
DELETE FROM public.horarios_sucursal;

-- Del Valle: todos los días 10:00–23:59
INSERT INTO public.horarios_sucursal (sucursal_id, dia_semana, hora_apertura, hora_cierre, activo)
SELECT s.id, d.dia, '10:00'::time, '23:59'::time, true
FROM public.sucursales s, generate_series(0, 6) AS d(dia)
WHERE s.nombre = 'Del Valle';

-- Las Brisas: todos los días 10:00–18:00
INSERT INTO public.horarios_sucursal (sucursal_id, dia_semana, hora_apertura, hora_cierre, activo)
SELECT s.id, d.dia, '10:00'::time, '18:00'::time, true
FROM public.sucursales s, generate_series(0, 6) AS d(dia)
WHERE s.nombre = 'Las Brisas';

-- Solares: todos los días 11:00–20:00
INSERT INTO public.horarios_sucursal (sucursal_id, dia_semana, hora_apertura, hora_cierre, activo)
SELECT s.id, d.dia, '11:00'::time, '20:00'::time, true
FROM public.sucursales s, generate_series(0, 6) AS d(dia)
WHERE s.nombre = 'Solares';

-- Cervecería — Dom(0) a Mié(3): 11:00–23:59
INSERT INTO public.horarios_sucursal (sucursal_id, dia_semana, hora_apertura, hora_cierre, activo)
SELECT s.id, d.dia, '11:00'::time, '23:59'::time, true
FROM public.sucursales s, generate_series(0, 3) AS d(dia)
WHERE s.nombre = 'Cervecería';

-- Cervecería — Jue(4) a Sáb(6): 11:00–23:59 (la parte del mismo día)
INSERT INTO public.horarios_sucursal (sucursal_id, dia_semana, hora_apertura, hora_cierre, activo)
SELECT s.id, d.dia, '11:00'::time, '23:59:59'::time, true
FROM public.sucursales s, generate_series(4, 6) AS d(dia)
WHERE s.nombre = 'Cervecería';

-- Cervecería — colas de madrugada 00:00–02:00 de Vie(5), Sáb(6) y Dom(0)
-- (corresponden a las noches de Jue, Vie y Sáb que cierran a las 2 a.m.)
INSERT INTO public.horarios_sucursal (sucursal_id, dia_semana, hora_apertura, hora_cierre, activo)
SELECT s.id, d.dia, '00:00'::time, '02:00'::time, true
FROM public.sucursales s, (VALUES (5), (6), (0)) AS d(dia)
WHERE s.nombre = 'Cervecería';

-- Verificación
SELECT s.nombre, h.dia_semana, h.hora_apertura, h.hora_cierre
FROM public.horarios_sucursal h JOIN public.sucursales s ON s.id = h.sucursal_id
ORDER BY s.nombre, h.dia_semana, h.hora_apertura;
