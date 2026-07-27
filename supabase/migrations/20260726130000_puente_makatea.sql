-- ============================================================
-- PUENTE La Ola → Makatea (arquitectura "día cero")
--
-- El ESTADO de cada cliente (última visita = día cero, cumpleaños,
-- sucursal) vive aquí. Makatea es dueña del teléfono y del ENVÍO.
-- Este puente empuja el estado a la org restaurante-la-ola:
--
--   1) Push INMEDIATO: trigger en lealtad_clientes → pg_net POST a
--      la edge function laola-lealtad-sync de Makatea. Inmediato
--      porque si el cliente vuelve en el día +9, su contador se
--      reinicia y Makatea debe cancelar el mensaje de +10 ANTES de
--      que el cron nocturno lo materialice/envíe.
--   2) Reconciliación NOCTURNA (pg_cron 04:30 CDMX): re-empuja los
--      clientes tocados en 3 días por si algún push falló.
--
-- La Ola NUNCA envía mensajes. Solo sincroniza datos.
-- ============================================================


-- ============================================================
-- BLOQUE 1 — Extensiones (idempotente; en Supabase ya suelen estar)
-- ============================================================
CREATE EXTENSION IF NOT EXISTS pg_net;
CREATE EXTENSION IF NOT EXISTS pg_cron;


-- ============================================================
-- BLOQUE 2 — Configuración del puente (URL + secreto)
-- RLS sin policies: NADIE la lee por la API; solo funciones DEFINER.
-- ============================================================
CREATE TABLE IF NOT EXISTS public.integracion_makatea (
  id         int PRIMARY KEY DEFAULT 1 CHECK (id = 1),
  base_url   text NOT NULL,   -- https://<ref-makatea>.supabase.co
  secreto    text NOT NULL,   -- mismo valor que LAOLA_SHARED_SECRET en Makatea
  activo     boolean NOT NULL DEFAULT true,
  updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.integracion_makatea ENABLE ROW LEVEL SECURITY;

-- URL real del Supabase de Makatea; el secreto ya está cargado allá
-- como LAOLA_SHARED_SECRET (vía Management API, 26-jul-2026).
INSERT INTO public.integracion_makatea (id, base_url, secreto)
VALUES (1, 'https://vhoqjbbkshhbqdnxxlzm.supabase.co', '59decf3ee383f542d15d4760a5f8350f899d718c6f19919d')
ON CONFLICT (id) DO NOTHING;


-- ============================================================
-- BLOQUE 3 — Función de push (uno o varios clientes)
-- ============================================================
CREATE OR REPLACE FUNCTION public.makatea_push_clientes(p_cliente_ids uuid[])
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_cfg     integracion_makatea%ROWTYPE;
  v_payload jsonb;
BEGIN
  SELECT * INTO v_cfg FROM integracion_makatea WHERE id = 1 AND activo;
  IF NOT FOUND OR v_cfg.base_url LIKE '%PON-AQUI%' THEN RETURN; END IF;

  SELECT jsonb_agg(jsonb_build_object(
    'telefono', c.telefono,
    'nombre', c.nombre,
    'ultima_visita', to_char(laola_fecha_negocio(COALESCE(c.ultima_visita, c.created_at)), 'YYYY-MM-DD'),
    'cumpleanos', to_char(c.cumpleanos, 'YYYY-MM-DD'),
    'sucursal', c.sucursal_captacion_codigo
  ))
  INTO v_payload
  FROM lealtad_clientes c
  WHERE c.id = ANY(p_cliente_ids) AND c.activo;

  IF v_payload IS NULL THEN RETURN; END IF;

  PERFORM net.http_post(
    url     := v_cfg.base_url || '/functions/v1/laola-lealtad-sync',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-laola-secret', v_cfg.secreto
    ),
    body    := jsonb_build_object('members', v_payload)
  );
END;
$$;


-- ============================================================
-- BLOQUE 4 — Trigger: push inmediato al registrarse o sumar visita
-- (lealtad_visita actualiza ultima_visita → dispara este trigger)
-- ============================================================
CREATE OR REPLACE FUNCTION public.makatea_push_trigger()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'UPDATE'
     AND NEW.ultima_visita IS NOT DISTINCT FROM OLD.ultima_visita
     AND NEW.nombre IS NOT DISTINCT FROM OLD.nombre
     AND NEW.cumpleanos IS NOT DISTINCT FROM OLD.cumpleanos THEN
    RETURN NEW;  -- nada relevante cambió para Makatea
  END IF;
  PERFORM makatea_push_clientes(ARRAY[NEW.id]);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_makatea_push ON public.lealtad_clientes;
CREATE TRIGGER trg_makatea_push
  AFTER INSERT OR UPDATE ON public.lealtad_clientes
  FOR EACH ROW EXECUTE FUNCTION public.makatea_push_trigger();


-- ============================================================
-- BLOQUE 5 — Reconciliación nocturna (por si un push falló)
-- Re-empuja clientes tocados en los últimos 3 días, en lotes de 200.
-- pg_cron corre en UTC: 10:30 UTC = 04:30 CDMX.
-- ============================================================
CREATE OR REPLACE FUNCTION public.makatea_reconciliar()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_ids uuid[];
BEGIN
  FOR v_ids IN
    SELECT array_agg(id) FROM (
      SELECT id, row_number() OVER (ORDER BY id) AS rn
      FROM lealtad_clientes
      WHERE activo AND (
        ultima_visita >= now() - interval '3 days'
        OR created_at >= now() - interval '3 days'
      )
    ) t
    GROUP BY (rn - 1) / 200
  LOOP
    PERFORM makatea_push_clientes(v_ids);
  END LOOP;
END;
$$;

SELECT cron.schedule(
  'makatea-reconciliar-lealtad',
  '30 10 * * *',
  $$SELECT public.makatea_reconciliar()$$
);
