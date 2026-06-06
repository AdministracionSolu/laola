-- =====================================================================
-- Sistema de Pedidos por Sucursal · La Ola
-- Migración idempotente: corrige sucursales, normaliza catálogo de
-- proteínas, agrega lista de insumos por sucursal (nivel par / costo),
-- ciclo de vida de pedidos y pedido sugerido.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Sucursales reales (renombrar las demo). Idempotente por nombre.
-- ---------------------------------------------------------------------
UPDATE public.sucursales SET nombre = 'Valle'      WHERE nombre = 'Del Valle';
UPDATE public.sucursales SET nombre = 'Rodeo'      WHERE nombre = 'Insurgentes';
UPDATE public.sucursales SET nombre = 'Cervecería' WHERE nombre = 'Las Brisas';
-- 'Solares' ya existe. Direcciones reales: [CONFIRMAR con el dueño].

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
--    Valle 21 · Rodeo 17 · Cervecería 19 · Solares 21 (= copia de Valle [CONFIRMAR]).
-- ---------------------------------------------------------------------
INSERT INTO public.insumo_sucursal (insumo_id, sucursal_id, orden)
SELECT i.id, s.id, m.orden
FROM (VALUES
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
    ('Solares','Pizzas',21)
) AS m(sucursal, nombre, orden)
JOIN public.insumos i    ON i.nombre = m.nombre
JOIN public.sucursales s ON s.nombre = m.sucursal
ON CONFLICT (insumo_id, sucursal_id) DO NOTHING;
