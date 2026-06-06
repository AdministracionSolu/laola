-- =====================================================================
-- Niveles par por defecto (ESTIMADOS) para que el pedido sugerido
-- (nivel_par − existencia) funcione desde el día 1.
-- Solo se aplican donde nivel_par está vacío (no pisa lo que el dueño
-- haya capturado). El dueño los afina en /admin/pedidos → Configuración.
-- Idempotente.
-- =====================================================================

CREATE TEMP TABLE _par (nombre text, par numeric) ON COMMIT DROP;
INSERT INTO _par (nombre, par) VALUES
  ('Camarón 61-70',        8),
  ('Camarón 31-35',        8),
  ('Camarón 21-25',        8),
  ('Pulpo 2-4',            5),
  ('Atún medallón',        20),   -- pz
  ('Marlin ahumado',       4),
  ('Robalo chico',         6),
  ('Robalo filete',        6),
  ('Sierra',               5),
  ('Camarón vapor 25-30',  6),
  ('Camarón 7-11',         5),
  ('Camarón 12-25',        6),
  ('Camarón seco',         3),
  ('Bolsas ostión',        10),   -- bolsa
  ('Callo de hacha',       4),
  ('Pescado p/sarandear',  10),   -- pz
  ('Filete de res',        8),
  ('Costilla de cerdo',    8),
  ('Alitas',               10),
  ('Boneless',             10),
  ('Pizzas',               12);   -- pz

UPDATE public.insumo_sucursal isuc
SET nivel_par = p.par
FROM public.insumos i, _par p
WHERE isuc.insumo_id = i.id
  AND i.nombre = p.nombre
  AND isuc.nivel_par IS NULL;
