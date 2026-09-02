-- =====================================================================
-- Tope de 99 también en la base, no sólo en la pantalla.
--
-- La pantalla ya no deja teclear más de 99, pero las tablas de pedidos y
-- recepciones se escriben con la llave anónima, así que sin candado en la
-- base un cliente viejo en caché o una llamada directa vuelven a meter un
-- 800. Medido sobre el histórico completo: el máximo real capturado fueron
-- 80 kg de pulpo, y le sigue 60.
--
-- Va NOT VALID a propósito: los renglones malos que ya existen se quedan
-- como están (son la evidencia de lo que pasó y se corrigen a mano desde
-- el panel). El candado aplica a lo que entre de aquí en adelante.
-- =====================================================================

ALTER TABLE public.recepciones_detalle
  DROP CONSTRAINT IF EXISTS recepciones_detalle_cantidad_tope;
ALTER TABLE public.recepciones_detalle
  ADD CONSTRAINT recepciones_detalle_cantidad_tope
  CHECK (cantidad_recibida IS NULL OR (cantidad_recibida >= 0 AND cantidad_recibida <= 99))
  NOT VALID;

ALTER TABLE public.pedidos_detalle
  DROP CONSTRAINT IF EXISTS pedidos_detalle_cantidades_tope;
ALTER TABLE public.pedidos_detalle
  ADD CONSTRAINT pedidos_detalle_cantidades_tope
  CHECK (
    (existencia IS NULL OR (existencia >= 0 AND existencia <= 99)) AND
    (cantidad_pedida IS NULL OR (cantidad_pedida >= 0 AND cantidad_pedida <= 99)) AND
    (cantidad_sugerida IS NULL OR (cantidad_sugerida >= 0 AND cantidad_sugerida <= 99)) AND
    (existencia_procesado IS NULL OR (existencia_procesado >= 0 AND existencia_procesado <= 99)) AND
    (existencia_no_procesado IS NULL OR (existencia_no_procesado >= 0 AND existencia_no_procesado <= 99))
  )
  NOT VALID;
