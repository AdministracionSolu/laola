-- ============================================================
-- BITÁCORA DE CORTES + EDICIÓN DE FECHA
--
-- Las auxiliares de contabilidad necesitan poder MOVER la fecha de un
-- corte (p. ej. lo subieron en la tarde y el trigger lo puso en el día
-- siguiente, o subieron dos veces el mismo día) sin duplicar datos.
-- Todo cambio o borrado sobre cortes_caja deja rastro inmutable en
-- cortes_audit (append-only: nadie puede editarla ni borrarla desde
-- el cliente), para detectar si alguien intenta meter un gol.
-- ============================================================


-- ============================================================
-- BLOQUE 1 — Tabla de auditoría (append-only)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.cortes_audit (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  corte_id    uuid NOT NULL,
  sucursal_id uuid,
  accion      text NOT NULL CHECK (accion IN ('editar', 'eliminar')),
  quien       text,           -- email de la sesión admin (o 'sistema')
  antes       jsonb NOT NULL, -- fila completa antes del cambio
  despues     jsonb,          -- fila después (NULL si se eliminó)
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_cortes_audit_corte ON public.cortes_audit (corte_id);
CREATE INDEX IF NOT EXISTS idx_cortes_audit_fecha ON public.cortes_audit (created_at DESC);

ALTER TABLE public.cortes_audit ENABLE ROW LEVEL SECURITY;
-- Solo lectura para sesiones admin. Nadie inserta/edita/borra directo:
-- las filas las escribe el trigger (SECURITY DEFINER).
DROP POLICY IF EXISTS "staff_lee_cortes_audit" ON public.cortes_audit;
CREATE POLICY "staff_lee_cortes_audit" ON public.cortes_audit
  FOR SELECT TO authenticated USING (true);


-- ============================================================
-- BLOQUE 2 — Trigger: todo UPDATE/DELETE en cortes_caja queda grabado
-- ============================================================
CREATE OR REPLACE FUNCTION public.cortes_caja_audit()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_quien text := COALESCE(NULLIF(auth.jwt() ->> 'email', ''), 'sistema');
BEGIN
  IF TG_OP = 'DELETE' THEN
    INSERT INTO cortes_audit (corte_id, sucursal_id, accion, quien, antes, despues)
    VALUES (OLD.id, OLD.sucursal_id, 'eliminar', v_quien, to_jsonb(OLD), NULL);
    RETURN OLD;
  END IF;

  INSERT INTO cortes_audit (corte_id, sucursal_id, accion, quien, antes, despues)
  VALUES (OLD.id, OLD.sucursal_id, 'editar', v_quien, to_jsonb(OLD), to_jsonb(NEW));
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_cortes_caja_audit ON public.cortes_caja;
CREATE TRIGGER trg_cortes_caja_audit
  AFTER UPDATE OR DELETE ON public.cortes_caja
  FOR EACH ROW EXECUTE FUNCTION public.cortes_caja_audit();
