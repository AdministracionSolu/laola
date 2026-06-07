-- =====================================================================
-- Niveles par por defecto (ESTIMADOS) para que el pedido sugerido
-- (nivel_par − existencia) funcione desde el día 1.
-- Solo se aplican donde nivel_par está vacío (no pisa lo capturado).
-- Sin tablas temporales. Idempotente.
-- =====================================================================

WITH par(nombre, valor) AS (
  VALUES
    ('Camarón 61-70',        8::numeric),
    ('Camarón 31-35',        8),
    ('Camarón 21-25',        8),
    ('Pulpo 2-4',            5),
    ('Atún medallón',        20),
    ('Marlin ahumado',       4),
    ('Robalo chico',         6),
    ('Robalo filete',        6),
    ('Sierra',               5),
    ('Camarón vapor 25-30',  6),
    ('Camarón 7-11',         5),
    ('Camarón 12-25',        6),
    ('Camarón seco',         3),
    ('Bolsas ostión',        10),
    ('Callo de hacha',       4),
    ('Pescado p/sarandear',  10),
    ('Filete de res',        8),
    ('Costilla de cerdo',    8),
    ('Alitas',               10),
    ('Boneless',             10),
    ('Pizzas',               12)
)
UPDATE public.insumo_sucursal isuc
SET nivel_par = p.valor
FROM public.insumos i, par p
WHERE isuc.insumo_id = i.id
  AND i.nombre = p.nombre
  AND isuc.nivel_par IS NULL;
