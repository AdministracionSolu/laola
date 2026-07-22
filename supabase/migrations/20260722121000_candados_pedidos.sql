-- ============================================================
-- CANDADOS DE PEDIDOS (repara la migración 20260606000000 aplicada a medias)
-- Auditoría 2026-07-22: la base en vivo NO tiene ni el único de
-- pedidos(sucursal_id, fecha) ni el de pedidos_detalle(pedido_id, insumo_id).
-- Los bloques DO de junio se saltaban en silencio si había duplicados.
-- Aquí primero se FUSIONAN los duplicados y luego se agregan los candados.
-- Orden importa: 1) pedidos, 2) pedidos_detalle.
-- ============================================================

-- 1) Un pedido por (sucursal, fecha): fusiona duplicados moviendo su detalle
--    al pedido más reciente, y agrega el candado.
WITH dups AS (
  SELECT id,
         row_number() OVER (PARTITION BY sucursal_id, fecha ORDER BY created_at DESC) AS rn,
         first_value(id) OVER (PARTITION BY sucursal_id, fecha ORDER BY created_at DESC) AS keep_id
  FROM public.pedidos
),
mover_detalle AS (
  UPDATE public.pedidos_detalle pd
  SET pedido_id = d.keep_id
  FROM dups d
  WHERE pd.pedido_id = d.id AND d.rn > 1
  RETURNING 1
)
DELETE FROM public.pedidos p
USING dups d
WHERE p.id = d.id AND d.rn > 1;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'pedidos_sucursal_fecha_key') THEN
    ALTER TABLE public.pedidos
      ADD CONSTRAINT pedidos_sucursal_fecha_key UNIQUE (sucursal_id, fecha);
  END IF;
END $$;

-- 2) Un renglón por (pedido, insumo): quita duplicados (conserva el más
--    reciente, re-apunta recepciones) y agrega el candado que permite upsert.
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

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'pedidos_detalle_pedido_insumo_key') THEN
    ALTER TABLE public.pedidos_detalle
      ADD CONSTRAINT pedidos_detalle_pedido_insumo_key UNIQUE (pedido_id, insumo_id);
  END IF;
END $$;
