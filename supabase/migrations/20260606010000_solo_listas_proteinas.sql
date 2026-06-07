-- =====================================================================
-- Operar SOLO con las listas de proteínas por sucursal (§5 del prompt).
-- Deja en cada sucursal EXACTAMENTE su lista y desactiva todo lo demás.
-- Idempotente.
-- =====================================================================

-- Matriz oficial sucursal × insumo (Del Valle 21 · Las Brisas 17 · Cervecería 19 · Solares 21).
CREATE TEMP TABLE _matriz (sucursal text, nombre text, orden int) ON COMMIT DROP;
INSERT INTO _matriz (sucursal, nombre, orden) VALUES
  ('Del Valle','Camarón 61-70',1),
  ('Del Valle','Camarón 31-35',2),
  ('Del Valle','Camarón 21-25',3),
  ('Del Valle','Pulpo 2-4',4),
  ('Del Valle','Atún medallón',5),
  ('Del Valle','Marlin ahumado',6),
  ('Del Valle','Robalo chico',7),
  ('Del Valle','Robalo filete',8),
  ('Del Valle','Sierra',9),
  ('Del Valle','Camarón vapor 25-30',10),
  ('Del Valle','Camarón 7-11',11),
  ('Del Valle','Camarón 12-25',12),
  ('Del Valle','Camarón seco',13),
  ('Del Valle','Bolsas ostión',14),
  ('Del Valle','Callo de hacha',15),
  ('Del Valle','Pescado p/sarandear',16),
  ('Del Valle','Filete de res',17),
  ('Del Valle','Costilla de cerdo',18),
  ('Del Valle','Alitas',19),
  ('Del Valle','Boneless',20),
  ('Del Valle','Pizzas',21),
  ('Las Brisas','Camarón 61-70',1),
  ('Las Brisas','Camarón 31-35',2),
  ('Las Brisas','Camarón 21-25',3),
  ('Las Brisas','Pulpo 2-4',4),
  ('Las Brisas','Atún medallón',5),
  ('Las Brisas','Marlin ahumado',6),
  ('Las Brisas','Robalo chico',7),
  ('Las Brisas','Robalo filete',8),
  ('Las Brisas','Sierra',9),
  ('Las Brisas','Camarón vapor 25-30',10),
  ('Las Brisas','Camarón 7-11',11),
  ('Las Brisas','Camarón 12-25',12),
  ('Las Brisas','Camarón seco',13),
  ('Las Brisas','Bolsas ostión',14),
  ('Las Brisas','Callo de hacha',15),
  ('Las Brisas','Boneless',20),
  ('Las Brisas','Pizzas',21),
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
