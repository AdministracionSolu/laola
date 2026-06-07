-- =====================================================================
-- LA OLA · Sistema de Pedidos por Sucursal — aplicar completo (idempotente)
-- =====================================================================

-- =====================================================================
-- Sistema de Pedidos por Sucursal · La Ola
-- Migración idempotente: corrige sucursales, normaliza catálogo de
-- proteínas, agrega lista de insumos por sucursal (nivel par / costo),
-- ciclo de vida de pedidos y pedido sugerido.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Sucursales: se conservan los nombres reales de la base
--    (Del Valle, Las Brisas, Cervecería, Solares). No se renombran.
-- ---------------------------------------------------------------------

-- PIN opcional de 4 dígitos por sucursal (NULL = sin PIN).
ALTER TABLE public.sucursales ADD COLUMN IF NOT EXISTS pin text;

-- ---------------------------------------------------------------------
-- 2. Ciclo de vida del pedido: borrador → enviado → recibido[/_parcial] → cerrado
-- ---------------------------------------------------------------------
ALTER TABLE public.pedidos ADD COLUMN IF NOT EXISTS enviado_at timestamptz;

-- Normalizar estados heredados de la app anterior.
UPDATE public.pedidos SET estado = 'enviado'          WHERE estado = 'pendiente';
UPDATE public.pedidos SET estado = 'recibido_parcial' WHERE estado = 'parcial';
ALTER TABLE public.pedidos ALTER COLUMN estado SET DEFAULT 'borrador';

-- CHECK de estados. Se agrega solo si no hay filas que lo violen (no aborta).
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'pedidos_estado_check')
     AND NOT EXISTS (
       SELECT 1 FROM public.pedidos
       WHERE estado NOT IN ('borrador', 'enviado', 'recibido', 'recibido_parcial', 'cerrado')
     ) THEN
    ALTER TABLE public.pedidos
      ADD CONSTRAINT pedidos_estado_check
      CHECK (estado IN ('borrador', 'enviado', 'recibido', 'recibido_parcial', 'cerrado'));
  END IF;
END $$;

-- Un pedido abierto por (sucursal, fecha). Se agrega solo si los datos
-- existentes lo permiten (no aborta la migración si hubiera duplicados).
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'pedidos_sucursal_fecha_key')
     AND NOT EXISTS (
       SELECT 1 FROM public.pedidos GROUP BY sucursal_id, fecha HAVING count(*) > 1
     ) THEN
    ALTER TABLE public.pedidos
      ADD CONSTRAINT pedidos_sucursal_fecha_key UNIQUE (sucursal_id, fecha);
  END IF;
END $$;

-- ---------------------------------------------------------------------
-- 3. Snapshot del pedido sugerido en el detalle.
-- ---------------------------------------------------------------------
ALTER TABLE public.pedidos_detalle ADD COLUMN IF NOT EXISTS cantidad_sugerida numeric;

-- ---------------------------------------------------------------------
-- 4. Normalizar catálogo de proteínas existente (mayúsculas → canónico).
--    Los seeds previos cargaron estos insumos en MAYÚSCULAS dentro de
--    'Mariscos y Carnes'. Los renombramos al formato canónico y movemos
--    Alitas/Boneless/Pizzas a 'Extras' antes de crear el índice único.
-- ---------------------------------------------------------------------
UPDATE public.insumos SET nombre = 'Camarón 61-70'       WHERE nombre = 'CAMARON 61-70';
UPDATE public.insumos SET nombre = 'Camarón 31-35'       WHERE nombre = 'CAMARON 31-35';
UPDATE public.insumos SET nombre = 'Camarón 21-25'       WHERE nombre = 'CAMARON 21-25';
UPDATE public.insumos SET nombre = 'Pulpo 2-4'           WHERE nombre = 'PULPO 2-4';
UPDATE public.insumos SET nombre = 'Atún medallón'       WHERE nombre = 'ATÚN MEDALLON pz';
UPDATE public.insumos SET nombre = 'Marlin ahumado'      WHERE nombre = 'MARLIN AHUMADO K.';
UPDATE public.insumos SET nombre = 'Robalo chico'        WHERE nombre = 'ROBALO (chicharrón)';
UPDATE public.insumos SET nombre = 'Robalo filete'       WHERE nombre = 'ROBALO (filete)';
UPDATE public.insumos SET nombre = 'Sierra'              WHERE nombre = 'SIERRA';
UPDATE public.insumos SET nombre = 'Camarón vapor 25-30' WHERE nombre = 'CAMARON VAPOR 25 a 30 gr';
UPDATE public.insumos SET nombre = 'Camarón 7-11'        WHERE nombre = 'CAMARON 7 A 11 GR';
UPDATE public.insumos SET nombre = 'Camarón 12-25'       WHERE nombre = 'CAMARON 12 - 25 GR';
UPDATE public.insumos SET nombre = 'Camarón seco'        WHERE nombre = 'CAMARON SECO K.';
UPDATE public.insumos SET nombre = 'Bolsas ostión'       WHERE nombre = 'BOLSAS OSTIÓN';
UPDATE public.insumos SET nombre = 'Callo de hacha'      WHERE nombre = 'CALLO DE HACHA';
UPDATE public.insumos SET nombre = 'Alitas'              WHERE nombre = 'ALITAS';
UPDATE public.insumos SET nombre = 'Boneless'            WHERE nombre = 'BONELESS';
UPDATE public.insumos SET nombre = 'Pizzas'              WHERE nombre = 'PIZZAS';
UPDATE public.insumos SET nombre = 'Filete de res'       WHERE nombre = 'FILETE DE RES';
UPDATE public.insumos SET nombre = 'Costilla de cerdo'   WHERE nombre = 'COSTILLA DE CERDO';
UPDATE public.insumos SET nombre = 'Pescado p/sarandear' WHERE nombre = 'PESCADO P/SARANDEAR';

-- Mover Alitas / Boneless / Pizzas a la categoría 'Extras'.
UPDATE public.insumos i
SET categoria_id = c.id
FROM public.categorias_insumos c
WHERE c.nombre = 'Extras'
  AND i.nombre IN ('Alitas', 'Boneless', 'Pizzas');

-- De-duplicar insumos por nombre (por si seeds previos crearon repetidos o
-- los renombres colapsaron variantes). Se conserva el más antiguo y se
-- repuntan las referencias antes de crear el índice único.
WITH dups AS (
  SELECT id,
         row_number() OVER (PARTITION BY nombre ORDER BY created_at) AS rn,
         first_value(id) OVER (PARTITION BY nombre ORDER BY created_at) AS keep_id
  FROM public.insumos
),
repuntar_pedidos AS (
  UPDATE public.pedidos_detalle pd
  SET insumo_id = d.keep_id
  FROM dups d
  WHERE pd.insumo_id = d.id AND d.rn > 1
  RETURNING 1
),
repuntar_recepciones AS (
  UPDATE public.recepciones_detalle rd
  SET insumo_id = d.keep_id
  FROM dups d
  WHERE rd.insumo_id = d.id AND d.rn > 1
  RETURNING 1
)
DELETE FROM public.insumos i
USING dups d
WHERE i.id = d.id AND d.rn > 1;

-- Índice único por nombre (requisito para el upsert idempotente).
CREATE UNIQUE INDEX IF NOT EXISTS insumos_nombre_key ON public.insumos (nombre);

-- De-duplicar renglones repetidos (pedido_id, insumo_id), conservando el más
-- reciente y repuntando el enlace de recepciones, para poder crear el UNIQUE
-- de forma determinística (el upsert de la app depende de él).
WITH dups AS (
  SELECT id,
         row_number() OVER (PARTITION BY pedido_id, insumo_id ORDER BY created_at DESC) AS rn,
         first_value(id) OVER (PARTITION BY pedido_id, insumo_id ORDER BY created_at DESC) AS keep_id
  FROM public.pedidos_detalle
),
repuntar_rec AS (
  UPDATE public.recepciones_detalle rd
  SET pedido_detalle_id = d.keep_id
  FROM dups d
  WHERE rd.pedido_detalle_id = d.id AND d.rn > 1
  RETURNING 1
)
DELETE FROM public.pedidos_detalle pd
USING dups d
WHERE pd.id = d.id AND d.rn > 1;

-- Un renglón por (pedido, insumo): permite upsert sin borrar/recrear filas,
-- preservando el enlace recepciones_detalle.pedido_detalle_id.
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'pedidos_detalle_pedido_insumo_key') THEN
    ALTER TABLE public.pedidos_detalle
      ADD CONSTRAINT pedidos_detalle_pedido_insumo_key UNIQUE (pedido_id, insumo_id);
  END IF;
END $$;

-- ---------------------------------------------------------------------
-- 5. Upsert idempotente de las proteínas con su categoría y unidad.
-- ---------------------------------------------------------------------
INSERT INTO public.insumos (nombre, categoria_id, unidad, activo)
SELECT x.nombre, c.id, x.unidad, true
FROM (VALUES
  ('Camarón 61-70',       'Mariscos y Carnes', 'kg'),
  ('Camarón 31-35',       'Mariscos y Carnes', 'kg'),
  ('Camarón 21-25',       'Mariscos y Carnes', 'kg'),
  ('Pulpo 2-4',           'Mariscos y Carnes', 'kg'),
  ('Atún medallón',       'Mariscos y Carnes', 'pz'),
  ('Marlin ahumado',      'Mariscos y Carnes', 'kg'),
  ('Robalo chico',        'Mariscos y Carnes', 'kg'),
  ('Robalo filete',       'Mariscos y Carnes', 'kg'),
  ('Sierra',              'Mariscos y Carnes', 'kg'),
  ('Camarón vapor 25-30', 'Mariscos y Carnes', 'kg'),
  ('Camarón 7-11',        'Mariscos y Carnes', 'kg'),
  ('Camarón 12-25',       'Mariscos y Carnes', 'kg'),
  ('Camarón seco',        'Mariscos y Carnes', 'kg'),
  ('Bolsas ostión',       'Mariscos y Carnes', 'bolsa'),
  ('Callo de hacha',      'Mariscos y Carnes', 'kg'),
  ('Pescado p/sarandear', 'Mariscos y Carnes', 'pz'),
  ('Filete de res',       'Mariscos y Carnes', 'kg'),
  ('Costilla de cerdo',   'Mariscos y Carnes', 'kg'),
  ('Alitas',              'Extras',            'kg'),
  ('Boneless',            'Extras',            'kg'),
  ('Pizzas',              'Extras',            'pz')
) AS x(nombre, categoria, unidad)
JOIN public.categorias_insumos c ON c.nombre = x.categoria
ON CONFLICT (nombre) DO UPDATE
  SET unidad = EXCLUDED.unidad,
      activo = true;

-- ---------------------------------------------------------------------
-- 6. Tabla puente: lista de insumos por sucursal (núcleo del sistema).
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.insumo_sucursal (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  insumo_id   uuid NOT NULL REFERENCES public.insumos(id) ON DELETE CASCADE,
  sucursal_id uuid NOT NULL REFERENCES public.sucursales(id) ON DELETE CASCADE,
  activo      boolean NOT NULL DEFAULT true,
  nivel_par   numeric,            -- objetivo de stock; base del pedido sugerido
  costo       numeric,            -- costo unitario actual (para gasto) [CONFIRMAR]
  unidad      text,               -- override opcional; si null, usa insumos.unidad
  orden       integer NOT NULL DEFAULT 0,
  created_at  timestamptz NOT NULL DEFAULT now(),
  UNIQUE (insumo_id, sucursal_id)
);

ALTER TABLE public.insumo_sucursal ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "lectura insumo_sucursal" ON public.insumo_sucursal;
CREATE POLICY "lectura insumo_sucursal" ON public.insumo_sucursal
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "admin gestiona insumo_sucursal" ON public.insumo_sucursal;
CREATE POLICY "admin gestiona insumo_sucursal" ON public.insumo_sucursal
  FOR ALL
  USING (public.has_role(auth.uid(), 'admin'))
  WITH CHECK (public.has_role(auth.uid(), 'admin'));

CREATE INDEX IF NOT EXISTS idx_insumo_sucursal_suc
  ON public.insumo_sucursal (sucursal_id, activo, orden);

-- ---------------------------------------------------------------------
-- 7. Asignación de proteínas por sucursal (matriz §5). Idempotente.
--    Del Valle 21 · Las Brisas 17 · Cervecería 19 · Solares 21 (= copia de Del Valle).
-- ---------------------------------------------------------------------
INSERT INTO public.insumo_sucursal (insumo_id, sucursal_id, orden)
SELECT i.id, s.id, m.orden
FROM (VALUES
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
    ('Solares','Pizzas',21)
) AS m(sucursal, nombre, orden)
JOIN public.insumos i    ON i.nombre = m.nombre
JOIN public.sucursales s ON s.nombre = m.sucursal
ON CONFLICT (insumo_id, sucursal_id) DO NOTHING;


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
