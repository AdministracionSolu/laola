-- =====================================================================
-- Pedidos · 11-ago-2026 · tres cambios acordados en la junta
--
--   1. EXISTENCIA PROCESADA / NO PROCESADA. En ocho insumos la sucursal
--      reporta por separado cuánto tiene ya procesado y cuánto crudo. Sirve
--      para que quien pide al día siguiente sepa de verdad con qué cuenta.
--      Aplica SOLO a la existencia, nunca al pedido.
--
--   2. POSTRES en la lista de pedidos: flan y pay.
--
--   3. Nada aquí toca `pedidos_detalle.existencia`, que sigue siendo el
--      TOTAL. Los dos campos nuevos son el desglose. Así el panel de Alicia,
--      la analítica y el consolidado siguen leyendo lo mismo de siempre.
-- =====================================================================

-- ---- 1. Qué insumos se desglosan -----------------------------------------
ALTER TABLE public.insumos
  ADD COLUMN IF NOT EXISTS desglosa_procesado boolean NOT NULL DEFAULT false;

COMMENT ON COLUMN public.insumos.desglosa_procesado IS
  'true = al capturar existencia se piden dos cantidades (procesado / no procesado). El pedido sigue siendo uno solo.';

UPDATE public.insumos SET desglosa_procesado = true
WHERE nombre IN (
  'CAMARON 31-35',
  'CAMARON 21-25',
  'CAMARON 61-70',
  'CAMARON 7 A 11 GR',
  'CAMARON 12 - 25 GR',
  'PULPO 2-4',
  'MARLIN AHUMADO K.',
  'ROBALO (chicharrón)',
  'ROBALO (filete)',
  'SIERRA'
);

-- ---- 2. El desglose vive en el renglón del pedido ------------------------
ALTER TABLE public.pedidos_detalle
  ADD COLUMN IF NOT EXISTS existencia_procesado    numeric,
  ADD COLUMN IF NOT EXISTS existencia_no_procesado numeric;

COMMENT ON COLUMN public.pedidos_detalle.existencia_procesado IS
  'Parte de `existencia` que ya está procesada. NULL en insumos que no se desglosan.';
COMMENT ON COLUMN public.pedidos_detalle.existencia_no_procesado IS
  'Parte de `existencia` que sigue cruda. NULL en insumos que no se desglosan.';

-- Candado: si se captura el desglose, tiene que sumar la existencia. Se deja
-- una tolerancia de 0.01 por los decimales de los kilos.
ALTER TABLE public.pedidos_detalle
  DROP CONSTRAINT IF EXISTS pedidos_detalle_desglose_cuadra;
ALTER TABLE public.pedidos_detalle
  ADD CONSTRAINT pedidos_detalle_desglose_cuadra CHECK (
    (existencia_procesado IS NULL AND existencia_no_procesado IS NULL)
    OR abs(COALESCE(existencia, 0)
           - (COALESCE(existencia_procesado, 0) + COALESCE(existencia_no_procesado, 0))) <= 0.01
  );

-- ---- 3. Postres en la lista ---------------------------------------------
-- Misma categoría que el resto (sólo hay una) y unidad en piezas.
INSERT INTO public.insumos (nombre, categoria_id, unidad, activo)
SELECT v.nombre, c.id, 'pz', true
FROM (VALUES ('FLAN'), ('PAY')) AS v(nombre)
CROSS JOIN LATERAL (
  SELECT id FROM public.categorias_insumos ORDER BY orden LIMIT 1
) c
WHERE NOT EXISTS (SELECT 1 FROM public.insumos i WHERE i.nombre = v.nombre);

-- Alta en las cuatro sucursales, al final de la lista de cada una.
INSERT INTO public.insumo_sucursal (insumo_id, sucursal_id, unidad, orden, activo)
SELECT i.id,
       s.id,
       'pz',
       (SELECT COALESCE(MAX(x.orden), 0) FROM public.insumo_sucursal x WHERE x.sucursal_id = s.id)
         + ROW_NUMBER() OVER (PARTITION BY s.id ORDER BY i.nombre),
       true
FROM public.insumos i
CROSS JOIN public.sucursales s
WHERE i.nombre IN ('FLAN', 'PAY')
  AND NOT EXISTS (
    SELECT 1 FROM public.insumo_sucursal y
    WHERE y.insumo_id = i.id AND y.sucursal_id = s.id
  );
