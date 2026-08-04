-- ============================================================
-- TERMINALES DEL DÍA
--
-- Cada mañana se define qué terminal punto de venta usa cada
-- sucursal (Banregio, MercadoPago, HayCash, Espiral). Eso se
-- captura en la pestaña Apertura del dashboard y a las 11:00
-- hora de Mazatlán (Tepic) sale UN mensaje al grupo de cajas
-- vía Makatea (laola-ops-alert), igual que el vigilante de
-- cortes.
--
-- Tres capas:
--   1. terminales            → catálogo (qué terminales existen)
--   2. terminales_sucursal   → qué terminal TIENE cada sucursal
--                              (Espiral solo existe en Valle)
--   3. terminales_asignacion → cuál USA hoy cada sucursal
--
-- Si un día nadie captura nada, el mensaje usa las terminales
-- que la sucursal tiene asignadas de planta. Así el aviso nunca
-- sale vacío.
-- ============================================================


-- ============================================================
-- BLOQUE 1 — Catálogo de terminales
-- ============================================================
CREATE TABLE IF NOT EXISTS public.terminales (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre     text NOT NULL UNIQUE,
  orden      int NOT NULL DEFAULT 100,
  activa     boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.terminales ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "staff_lee_terminales" ON public.terminales;
CREATE POLICY "staff_lee_terminales" ON public.terminales
  FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "staff_edita_terminales" ON public.terminales;
CREATE POLICY "staff_edita_terminales" ON public.terminales
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

INSERT INTO public.terminales (nombre, orden) VALUES
  ('Banregio', 10),
  ('MercadoPago', 20),
  ('HayCash', 30),
  ('Espiral', 40)
ON CONFLICT (nombre) DO NOTHING;


-- ============================================================
-- BLOQUE 2 — Qué terminal tiene cada sucursal (de planta)
-- Seed: las tres de siempre a las cuatro sucursales, y Espiral
-- SOLO a Valle. Se corrige desde el dashboard sin tocar SQL.
-- ============================================================
CREATE TABLE IF NOT EXISTS public.terminales_sucursal (
  sucursal_id uuid NOT NULL REFERENCES public.sucursales(id) ON DELETE CASCADE,
  terminal_id uuid NOT NULL REFERENCES public.terminales(id) ON DELETE CASCADE,
  PRIMARY KEY (sucursal_id, terminal_id)
);

ALTER TABLE public.terminales_sucursal ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "staff_lee_terminales_sucursal" ON public.terminales_sucursal;
CREATE POLICY "staff_lee_terminales_sucursal" ON public.terminales_sucursal
  FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "staff_edita_terminales_sucursal" ON public.terminales_sucursal;
CREATE POLICY "staff_edita_terminales_sucursal" ON public.terminales_sucursal
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

INSERT INTO public.terminales_sucursal (sucursal_id, terminal_id)
SELECT s.id, t.id
FROM public.sucursales s
CROSS JOIN public.terminales t
WHERE t.nombre IN ('Banregio', 'MercadoPago', 'HayCash')
ON CONFLICT DO NOTHING;

INSERT INTO public.terminales_sucursal (sucursal_id, terminal_id)
SELECT s.id, t.id
FROM public.sucursales s
CROSS JOIN public.terminales t
WHERE t.nombre = 'Espiral'
  AND upper(coalesce(s.prefijo_folio, '')) = 'VAL'
ON CONFLICT DO NOTHING;


-- ============================================================
-- BLOQUE 3 — Asignación del día (la que se avisa a cajas)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.terminales_asignacion (
  fecha       date NOT NULL,
  sucursal_id uuid NOT NULL REFERENCES public.sucursales(id) ON DELETE CASCADE,
  terminal_id uuid NOT NULL REFERENCES public.terminales(id) ON DELETE CASCADE,
  created_at  timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (fecha, sucursal_id, terminal_id)
);

CREATE INDEX IF NOT EXISTS idx_terminales_asignacion_fecha
  ON public.terminales_asignacion (fecha);

ALTER TABLE public.terminales_asignacion ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "staff_lee_terminales_asignacion" ON public.terminales_asignacion;
CREATE POLICY "staff_lee_terminales_asignacion" ON public.terminales_asignacion
  FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "staff_edita_terminales_asignacion" ON public.terminales_asignacion;
CREATE POLICY "staff_edita_terminales_asignacion" ON public.terminales_asignacion
  FOR ALL TO authenticated USING (true) WITH CHECK (true);


-- ============================================================
-- BLOQUE 4 — Config del aviso + candado de un envío por día
-- Hora en zona de Tepic/Mazatlán (UTC-7, sin horario de verano).
-- ============================================================
CREATE TABLE IF NOT EXISTS public.terminales_aviso_config (
  id         int PRIMARY KEY DEFAULT 1 CHECK (id = 1),
  hora       time NOT NULL DEFAULT '11:00',
  zona       text NOT NULL DEFAULT 'America/Mazatlan',
  activo     boolean NOT NULL DEFAULT true,
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.terminales_aviso_config ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "staff_lee_aviso_config" ON public.terminales_aviso_config;
CREATE POLICY "staff_lee_aviso_config" ON public.terminales_aviso_config
  FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "staff_edita_aviso_config" ON public.terminales_aviso_config;
CREATE POLICY "staff_edita_aviso_config" ON public.terminales_aviso_config
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

INSERT INTO public.terminales_aviso_config (id) VALUES (1)
ON CONFLICT (id) DO NOTHING;

CREATE TABLE IF NOT EXISTS public.terminales_aviso_enviado (
  fecha      date PRIMARY KEY,
  mensaje    text,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.terminales_aviso_enviado ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "staff_lee_aviso_enviado" ON public.terminales_aviso_enviado;
CREATE POLICY "staff_lee_aviso_enviado" ON public.terminales_aviso_enviado
  FOR SELECT TO authenticated USING (true);


-- ============================================================
-- BLOQUE 5 — Texto del mensaje (misma función para vista previa
-- y para el envío real, así lo que se ve es lo que llega)
-- ============================================================
CREATE OR REPLACE FUNCTION public.terminales_mensaje_dia(p_fecha date DEFAULT NULL)
RETURNS text
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_fecha  date := COALESCE(p_fecha, laola_fecha_negocio(now()));
  v_lineas text[] := ARRAY[]::text[];
  v_row    record;
BEGIN
  FOR v_row IN
    SELECT
      s.nombre,
      COALESCE(
        -- lo capturado para hoy
        (SELECT string_agg(t.nombre, ' + ' ORDER BY t.orden, t.nombre)
           FROM terminales_asignacion a
           JOIN terminales t ON t.id = a.terminal_id
          WHERE a.fecha = v_fecha AND a.sucursal_id = s.id AND t.activa),
        -- si nadie capturó: las que tiene de planta
        (SELECT string_agg(t.nombre, ' + ' ORDER BY t.orden, t.nombre)
           FROM terminales_sucursal ts
           JOIN terminales t ON t.id = ts.terminal_id
          WHERE ts.sucursal_id = s.id AND t.activa)
      ) AS lista
    FROM sucursales s
    ORDER BY
      COALESCE(array_position(ARRAY['VAL','CER','BRI','SOL'], upper(s.prefijo_folio)), 99),
      s.nombre
  LOOP
    v_lineas := v_lineas || ('• ' || v_row.nombre || ': ' || COALESCE(v_row.lista, 'sin terminal asignada'));
  END LOOP;

  IF array_length(v_lineas, 1) IS NULL THEN RETURN NULL; END IF;

  RETURN 'Terminales de hoy ' || to_char(v_fecha, 'DD/MM') || E'\n\n'
      || array_to_string(v_lineas, E'\n') || E'\n\n'
      || 'Cobren con la terminal que les toca. Si algo cambia, avisen por aquí.';
END;
$$;

REVOKE ALL ON FUNCTION public.terminales_mensaje_dia(date) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.terminales_mensaje_dia(date) TO authenticated;


-- ============================================================
-- BLOQUE 6 — Envío al grupo de cajas (vía Makatea)
-- p_forzar = true es el botón "Enviar ahora" del dashboard:
-- ignora la hora y reenvía aunque ya haya salido hoy.
-- Devuelve el mensaje enviado, o NULL si no tocaba enviar.
-- ============================================================
CREATE OR REPLACE FUNCTION public.avisar_terminales_dia(p_forzar boolean DEFAULT false)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_cfg     integracion_makatea%ROWTYPE;
  v_avc     terminales_aviso_config%ROWTYPE;
  v_fecha   date := laola_fecha_negocio(now());
  v_mensaje text;
BEGIN
  SELECT * INTO v_avc FROM terminales_aviso_config WHERE id = 1;
  IF NOT FOUND THEN RETURN NULL; END IF;

  IF NOT p_forzar THEN
    IF NOT v_avc.activo THEN RETURN NULL; END IF;
    -- Antes de la hora local de Tepic no se manda nada.
    IF (now() AT TIME ZONE v_avc.zona)::time < v_avc.hora THEN RETURN NULL; END IF;
  END IF;

  v_mensaje := terminales_mensaje_dia(v_fecha);
  IF v_mensaje IS NULL THEN RETURN NULL; END IF;

  IF p_forzar THEN
    DELETE FROM terminales_aviso_enviado WHERE fecha = v_fecha;
  END IF;

  -- Candado: un aviso por día de negocio
  INSERT INTO terminales_aviso_enviado (fecha, mensaje)
  VALUES (v_fecha, v_mensaje)
  ON CONFLICT (fecha) DO NOTHING;
  IF NOT FOUND THEN RETURN NULL; END IF;

  SELECT * INTO v_cfg FROM integracion_makatea WHERE id = 1 AND activo;
  IF NOT FOUND OR v_cfg.base_url LIKE '%PON-AQUI%' THEN RETURN NULL; END IF;

  PERFORM net.http_post(
    url     := v_cfg.base_url || '/functions/v1/laola-ops-alert',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-laola-secret', v_cfg.secreto
    ),
    body    := jsonb_build_object('mensaje', v_mensaje),
    timeout_milliseconds := 10000
  );

  RETURN v_mensaje;
END;
$$;

REVOKE ALL ON FUNCTION public.avisar_terminales_dia(boolean) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.avisar_terminales_dia(boolean) TO authenticated;


-- ============================================================
-- BLOQUE 7 — Cron cada 15 min; la función decide si ya es hora
-- (así la hora se cambia desde el dashboard, sin reprogramar)
-- ============================================================
SELECT cron.unschedule('avisar-terminales-dia')
WHERE EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'avisar-terminales-dia');

SELECT cron.schedule(
  'avisar-terminales-dia',
  '*/15 * * * *',
  $$SELECT public.avisar_terminales_dia()$$
);
