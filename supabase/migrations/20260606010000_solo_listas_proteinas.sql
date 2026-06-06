-- =====================================================================
-- Operar SOLO con las listas de proteínas por sucursal (§5 del prompt).
-- Deja en cada sucursal EXACTAMENTE su lista y desactiva todo lo demás.
-- Idempotente.
-- =====================================================================

-- Matriz oficial sucursal × insumo (Valle 21 · Rodeo 17 · Cervecería 19 · Solares 21).
CREATE TEMP TABLE _matriz (sucursal text, nombre text, orden int) ON COMMIT DROP;
INSERT INTO _matriz (sucursal, nombre, orden) VALUES
  ('Valle','Camarón 61-70',1),
  ('Valle','Camarón 31-35',2),
  ('Valle','Camarón 21-25',3),
  ('Valle','Pulpo 2-4',4),
  ('Valle','Atún medallón',5),
  ('Valle','Marlin ahumado',6),
  ('Valle','Robalo chico',7),
  ('Valle','Robalo filete',8),
  ('Valle','Sierra',9),
  ('Valle','Camarón vapor 25-30',10),
  ('Valle','Camarón 7-11',11),
  ('Valle','Camarón 12-25',12),
  ('Valle','Camarón seco',13),
  ('Valle','Bolsas ostión',14),
  ('Valle','Callo de hacha',15),
  ('Valle','Pescado p/sarandear',16),
  ('Valle','Filete de res',17),
  ('Valle','Costilla de cerdo',18),
  ('Valle','Alitas',19),
  ('Valle','Boneless',20),
  ('Valle','Pizzas',21),
  ('Rodeo','Camarón 61-70',1),
  ('Rodeo','Camarón 31-35',2),
  ('Rodeo','Camarón 21-25',3),
  ('Rodeo','Pulpo 2-4',4),
  ('Rodeo','Atún medallón',5),
  ('Rodeo','Marlin ahumado',6),
  ('Rodeo','Robalo chico',7),
  ('Rodeo','Robalo filete',8),
  ('Rodeo','Sierra',9),
  ('Rodeo','Camarón vapor 25-30',10),
  ('Rodeo','Camarón 7-11',11),
  ('Rodeo','Camarón 12-25',12),
  ('Rodeo','Camarón seco',13),
  ('Rodeo','Bolsas ostión',14),
  ('Rodeo','Callo de hacha',15),
  ('Rodeo','Boneless',20),
  ('Rodeo','Pizzas',21),
  ('Cervecería','Camarón 61-70',1),
  ('Cervecería','Camarón 31-35',2),
  ('Cervecería','Camarón 21-25',3),
  ('Cervecería','Pulpo 2-4',4),
  ('Cervecería','Atún medallón',5),
  ('Cervecería','Marlin ahumado',6),
  ('Cervecería','Robalo chico',7),
  ('Cervecería','Robalo filete',8),
  ('Cervecería','Sierra',9),
  ('Cervecería','Camarón vapor 25-30',10),
  ('Cervecería','Camarón 7-11',11),
  ('Cervecería','Camarón 12-25',12),
  ('Cervecería','Camarón seco',13),
  ('Cervecería','Bolsas ostión',14),
  ('Cervecería','Callo de hacha',15),
  ('Cervecería','Filete de res',17),
  ('Cervecería','Alitas',19),
  ('Cervecería','Boneless',20),
  ('Cervecería','Pizzas',21),
  ('Solares','Camarón 61-70',1),
  ('Solares','Camarón 31-35',2),
  ('Solares','Camarón 21-25',3),
  ('Solares','Pulpo 2-4',4),
  ('Solares','Atún medallón',5),
  ('Solares','Marlin ahumado',6),
  ('Solares','Robalo chico',7),
  ('Solares','Robalo filete',8),
  ('Solares','Sierra',9),
  ('Solares','Camarón vapor 25-30',10),
  ('Solares','Camarón 7-11',11),
  ('Solares','Camarón 12-25',12),
  ('Solares','Camarón seco',13),
  ('Solares','Bolsas ostión',14),
  ('Solares','Callo de hacha',15),
  ('Solares','Pescado p/sarandear',16),
  ('Solares','Filete de res',17),
  ('Solares','Costilla de cerdo',18),
  ('Solares','Alitas',19),
  ('Solares','Boneless',20),
  ('Solares','Pizzas',21);

-- 1) Quitar de cada sucursal cualquier asignación que NO esté en su lista.
DELETE FROM public.insumo_sucursal isuc
USING public.insumos i, public.sucursales s
WHERE isuc.insumo_id = i.id
  AND isuc.sucursal_id = s.id
  AND NOT EXISTS (
    SELECT 1 FROM _matriz m WHERE m.sucursal = s.nombre AND m.nombre = i.nombre
  );

-- 2) Asegurar que cada sucursal tenga EXACTAMENTE su lista (activa y ordenada).
INSERT INTO public.insumo_sucursal (insumo_id, sucursal_id, orden, activo)
SELECT i.id, s.id, m.orden, true
FROM _matriz m
JOIN public.insumos i    ON i.nombre = m.nombre
JOIN public.sucursales s ON s.nombre = m.sucursal
ON CONFLICT (insumo_id, sucursal_id)
  DO UPDATE SET activo = true, orden = EXCLUDED.orden;

-- 3) Desactivar del catálogo todo lo que NO esté en las listas; activar lo que sí.
UPDATE public.insumos SET activo = false
WHERE nombre NOT IN (SELECT DISTINCT nombre FROM _matriz);

UPDATE public.insumos SET activo = true
WHERE nombre IN (SELECT DISTINCT nombre FROM _matriz);
