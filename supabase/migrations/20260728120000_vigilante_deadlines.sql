-- ============================================================
-- VIGILANTE DE CORTES v2 — deadlines reales por sucursal
--
-- Cambios sobre 20260726140000_vigilante_cortes.sql (ya aplicada):
--  · Hora límite especial para viernes y sábado (hora_limite_finde),
--    pensada para Cervecería: el día de negocio del viernes cierra a
--    las 2:00 AM del sábado (y el del sábado a las 2:00 AM del domingo).
--  · Todo se calcula en la HORA LOCAL de cada sucursal
--    (sucursales.zona_horaria: Valle/Brisas/Cervecería = Mazatlán,
--    Solares = CDMX), con el mismo corte de día de negocio a las 4 AM.
--  · UN mensaje por sucursal (texto plano con el nombre) en vez del
--    mensaje agregado.
--  · El cron corre cada minuto para disparar 1 minuto después de la
--    hora límite (la función sale en microsegundos si no hay nada).
--
-- Horas configuradas:
--  · Las Brisas  18:00 todos los días
--  · Solares     18:30 todos los días
--  · Valle       23:30 todos los días
--  · Cervecería  23:30 dom-jue · 02:00 (del día siguiente) vie-sáb
-- ============================================================


-- ============================================================
-- BLOQUE 1 — Columna de hora límite de fin de semana (vie/sáb)
-- ============================================================
ALTER TABLE public.cortes_alertas_config
  ADD COLUMN IF NOT EXISTS hora_limite_finde time;


-- ============================================================
-- BLOQUE 2 — Horas reales + activar vigilancia en las 4 sucursales
-- ============================================================
UPDATE public.cortes_alertas_config c SET
  hora_limite = CASE s.nombre
    WHEN 'Las Brisas' THEN '18:00'::time
    WHEN 'Solares'    THEN '18:30'::time
    ELSE '23:30'::time  -- Valle y Cervecería
  END,
  hora_limite_finde = CASE s.nombre
    WHEN 'Cervecería' THEN '02:00'::time
    ELSE NULL
  END,
  activo = true,
  updated_at = now()
FROM public.sucursales s
WHERE s.id = c.sucursal_id;


-- ============================================================
-- BLOQUE 3 — vigilar_cortes() v2
-- ============================================================
CREATE OR REPLACE FUNCTION public.vigilar_cortes()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_cfg      integracion_makatea%ROWTYPE;
  v_row      record;
  v_loc      timestamp;
  v_fecha    date;
  v_dow      int;
  v_lim      time;
  v_bt_ahora int;
  v_bt_lim   int;
  v_mensaje  text;
BEGIN
  SELECT * INTO v_cfg FROM integracion_makatea WHERE id = 1 AND activo;
  IF NOT FOUND OR v_cfg.base_url LIKE '%PON-AQUI%' THEN RETURN; END IF;

  FOR v_row IN
    SELECT c.sucursal_id, c.hora_limite, c.hora_limite_finde, s.nombre,
           COALESCE(s.zona_horaria, 'America/Mexico_City') AS tz
    FROM cortes_alertas_config c
    JOIN sucursales s ON s.id = c.sucursal_id
    WHERE c.activo
  LOOP
    -- Reloj y día de negocio en la hora LOCAL de la sucursal (corte 4 AM).
    v_loc   := now() AT TIME ZONE v_row.tz;
    v_fecha := (v_loc - interval '4 hours')::date;
    v_dow   := EXTRACT(DOW FROM v_fecha)::int;  -- DOW del día de NEGOCIO

    -- Vie(5)/Sáb(6) usan la hora especial si existe (Cervecería: 02:00,
    -- que en reloj de negocio cae DESPUÉS de medianoche pero sigue
    -- siendo el mismo día de negocio).
    v_lim := CASE WHEN v_dow IN (5, 6) AND v_row.hora_limite_finde IS NOT NULL
                  THEN v_row.hora_limite_finde
                  ELSE v_row.hora_limite END;

    -- Segundos desde las 4 AM locales, para que una hora pasada la
    -- medianoche compare bien dentro del mismo día de negocio.
    v_bt_ahora := ((EXTRACT(EPOCH FROM v_loc::time)::int - 14400) + 86400) % 86400;
    v_bt_lim   := ((EXTRACT(EPOCH FROM v_lim)::int - 14400) + 86400) % 86400;

    -- Dispara a partir de 1 minuto después de la hora límite.
    IF v_bt_ahora < v_bt_lim + 60 THEN CONTINUE; END IF;

    -- ¿Ya hay corte de CIERRE de este día de negocio?
    IF EXISTS (
      SELECT 1 FROM cortes_caja k
      WHERE k.sucursal_id = v_row.sucursal_id
        AND k.tipo_corte = 'cierre'
        AND k.fecha_venta = v_fecha
    ) THEN CONTINUE; END IF;

    -- Dedupe: una alerta por sucursal por día de negocio.
    BEGIN
      INSERT INTO cortes_alertas_enviadas (sucursal_id, fecha_negocio)
      VALUES (v_row.sucursal_id, v_fecha);
    EXCEPTION WHEN unique_violation THEN
      CONTINUE;
    END;

    -- Un mensaje por sucursal, texto plano.
    v_mensaje := v_row.nombre || ': está pendiente cargar los datos del corte de cierre del '
      || to_char(v_fecha, 'DD/MM')
      || '. Favor de subirlo en el Centro de Operaciones.';

    PERFORM net.http_post(
      url     := v_cfg.base_url || '/functions/v1/laola-ops-alert',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'x-laola-secret', v_cfg.secreto
      ),
      body    := jsonb_build_object('mensaje', v_mensaje)
    );
  END LOOP;
END;
$$;


-- ============================================================
-- BLOQUE 4 — Cron cada minuto (reemplaza el de cada 15)
-- ============================================================
SELECT cron.unschedule('vigilar-cortes');
SELECT cron.schedule(
  'vigilar-cortes',
  '* * * * *',
  $$SELECT public.vigilar_cortes()$$
);
