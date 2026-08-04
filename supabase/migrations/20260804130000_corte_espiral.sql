-- ============================================================
-- Espiral en el corte de cierre.
--
-- Se comporta igual que MercadoPago: casilla propia en el
-- desglose, y su monto suma al total de tarjetas del corte.
-- Solo Valle la usa, pero la columna vive en cortes_caja para
-- todas (las demás la dejan en 0), igual que las otras tres.
-- ============================================================

ALTER TABLE public.cortes_caja
  ADD COLUMN IF NOT EXISTS tarjetas_espiral numeric DEFAULT 0;

COMMENT ON COLUMN public.cortes_caja.tarjetas_espiral IS 'Cobros con terminal Espiral';
