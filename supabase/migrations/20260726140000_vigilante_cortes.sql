-- ============================================================
-- VIGILANTE DE CORTES
--
-- Cada 15 min revisa qué sucursales ya pasaron su hora límite del
-- día de negocio SIN registrar corte de cierre en cortes_caja, y
-- avisa UNA vez por sucursal/día vía Makatea (laola-ops-alert →
-- WhatsApp al grupo de cajas).
--
-- Hora límite en hora local CDMX. Para que una hora límite nocturna
-- (p. ej. 23:30) siga siendo "de hoy" aunque el cron corra a las
-- 00:15, todo se compara en "reloj de negocio" (hora local - 4h,
-- igual que laola_fecha_negocio).
-- ============================================================


-- ============================================================
-- BLOQUE 1 — Config por sucursal (activo=false hasta que Diego
-- ponga las horas reales en el admin o por SQL)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.cortes_alertas_config (
  sucursal_id uuid PRIMARY KEY REFERENCES public.sucursales(id) ON DELETE CASCADE,
  hora_limite time NOT NULL DEFAULT '23:30',
  activo      boolean NOT NULL DEFAULT false,
  updated_at  timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.cortes_alertas_config ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "staff_lee_alertas_config" ON public.cortes_alertas_config;
CREATE POLICY "staff_lee_alertas_config" ON public.cortes_alertas_config
  FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "staff_edita_alertas_config" ON public.cortes_alertas_config;
CREATE POLICY "staff_edita_alertas_config" ON public.cortes_alertas_config
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

INSERT INTO public.cortes_alertas_config (sucursal_id)
SELECT id FROM public.sucursales
ON CONFLICT (sucursal_id) DO NOTHING;


-- ============================================================
-- BLOQUE 2 — Registro de alertas enviadas (dedupe + semáforo)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.cortes_alertas_enviadas (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  sucursal_id   uuid NOT NULL REFERENCES public.sucursales(id) ON DELETE CASCADE,
  fecha_negocio date NOT NULL,
  created_at    timestamptz NOT NULL DEFAULT now(),
  UNIQUE (sucursal_id, fecha_negocio)
);

ALTER TABLE public.cortes_alertas_enviadas ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "staff_lee_alertas_enviadas" ON public.cortes_alertas_enviadas;
CREATE POLICY "staff_lee_alertas_enviadas" ON public.cortes_alertas_enviadas
  FOR SELECT TO authenticated USING (true);


-- ============================================================
-- BLOQUE 3 — vigilar_cortes(): detecta y avisa (una vez por día)
-- ============================================================
CREATE OR REPLACE FUNCTION public.vigilar_cortes()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_cfg      integracion_makatea%ROWTYPE;
  v_fecha    date := laola_fecha_negocio(now());
  -- Reloj de negocio: segundos desde las 4 AM locales
  v_bt_ahora int := ((EXTRACT(EPOCH FROM (now() AT TIME ZONE 'America/Mexico_City')::time)::int - 14400) + 86400) % 86400;
  v_bt_lim   int;
  v_row      record;
  v_faltan   text[] := ARRAY[]::text[];
  v_mensaje  text;
BEGIN
  FOR v_row IN
    SELECT c.sucursal_id, c.hora_limite, s.nombre
    FROM cortes_alertas_config c
    JOIN sucursales s ON s.id = c.sucursal_id
    WHERE c.activo
  LOOP
    v_bt_lim := ((EXTRACT(EPOCH FROM v_row.hora_limite)::int - 14400) + 86400) % 86400;
    IF v_bt_ahora < v_bt_lim THEN CONTINUE; END IF;

    -- ¿Ya hay corte de CIERRE de este día de negocio?
    IF EXISTS (
      SELECT 1 FROM cortes_caja k
      WHERE k.sucursal_id = v_row.sucursal_id
        AND k.tipo_corte = 'cierre'
        AND k.fecha_venta = v_fecha
    ) THEN CONTINUE; END IF;

    -- Dedupe: una alerta por sucursal por día de negocio
    BEGIN
      INSERT INTO cortes_alertas_enviadas (sucursal_id, fecha_negocio)
      VALUES (v_row.sucursal_id, v_fecha);
    EXCEPTION WHEN unique_violation THEN
      CONTINUE;
    END;

    v_faltan := v_faltan || v_row.nombre;
  END LOOP;

  IF array_length(v_faltan, 1) IS NULL THEN RETURN; END IF;

  SELECT * INTO v_cfg FROM integracion_makatea WHERE id = 1 AND activo;
  IF NOT FOUND OR v_cfg.base_url LIKE '%PON-AQUI%' THEN RETURN; END IF;

  v_mensaje := '⚠️ Corte pendiente (' || to_char(v_fecha, 'DD/MM') || '): '
    || array_to_string(v_faltan, ', ')
    || ' aún no registra su corte de cierre. Favor de subirlo en el Centro de Operaciones.';

  PERFORM net.http_post(
    url     := v_cfg.base_url || '/functions/v1/laola-ops-alert',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-laola-secret', v_cfg.secreto
    ),
    body    := jsonb_build_object('mensaje', v_mensaje)
  );
END;
$$;


-- ============================================================
-- BLOQUE 4 — Cron cada 15 minutos
-- ============================================================
SELECT cron.schedule(
  'vigilar-cortes',
  '*/15 * * * *',
  $$SELECT public.vigilar_cortes()$$
);
