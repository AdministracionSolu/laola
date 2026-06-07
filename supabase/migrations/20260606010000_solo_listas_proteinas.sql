-- =====================================================================
-- Operar SOLO con las listas de proteínas por sucursal (§5 del prompt).
-- Desactiva del catálogo todo lo que no sea proteína y quita asignaciones
-- de insumos que no son de la lista. Sin tablas temporales (robusto en
-- cualquier modo de ejecución). Idempotente.
-- La asignación exacta por sucursal la hace 20260606000000.
-- =====================================================================

-- 1) Quitar asignaciones de insumos que NO son de la lista de proteínas.
DELETE FROM public.insumo_sucursal isuc
USING public.insumos i
WHERE isuc.insumo_id = i.id
  AND i.nombre NOT IN (
    'Camarón 61-70','Camarón 31-35','Camarón 21-25','Pulpo 2-4','Atún medallón',
    'Marlin ahumado','Robalo chico','Robalo filete','Sierra','Camarón vapor 25-30',
    'Camarón 7-11','Camarón 12-25','Camarón seco','Bolsas ostión','Callo de hacha',
    'Pescado p/sarandear','Filete de res','Costilla de cerdo','Alitas','Boneless','Pizzas'
  );

-- 2) Asegurar activas las asignaciones de proteínas.
UPDATE public.insumo_sucursal isuc
SET activo = true
FROM public.insumos i
WHERE isuc.insumo_id = i.id
  AND i.nombre IN (
    'Camarón 61-70','Camarón 31-35','Camarón 21-25','Pulpo 2-4','Atún medallón',
    'Marlin ahumado','Robalo chico','Robalo filete','Sierra','Camarón vapor 25-30',
    'Camarón 7-11','Camarón 12-25','Camarón seco','Bolsas ostión','Callo de hacha',
    'Pescado p/sarandear','Filete de res','Costilla de cerdo','Alitas','Boneless','Pizzas'
  );

-- 3) Desactivar del catálogo todo lo que NO sea proteína de las listas.
UPDATE public.insumos SET activo = false
WHERE nombre NOT IN (
  'Camarón 61-70','Camarón 31-35','Camarón 21-25','Pulpo 2-4','Atún medallón',
  'Marlin ahumado','Robalo chico','Robalo filete','Sierra','Camarón vapor 25-30',
  'Camarón 7-11','Camarón 12-25','Camarón seco','Bolsas ostión','Callo de hacha',
  'Pescado p/sarandear','Filete de res','Costilla de cerdo','Alitas','Boneless','Pizzas'
);

-- 4) Activar las proteínas de la lista.
UPDATE public.insumos SET activo = true
WHERE nombre IN (
  'Camarón 61-70','Camarón 31-35','Camarón 21-25','Pulpo 2-4','Atún medallón',
  'Marlin ahumado','Robalo chico','Robalo filete','Sierra','Camarón vapor 25-30',
  'Camarón 7-11','Camarón 12-25','Camarón seco','Bolsas ostión','Callo de hacha',
  'Pescado p/sarandear','Filete de res','Costilla de cerdo','Alitas','Boneless','Pizzas'
);
