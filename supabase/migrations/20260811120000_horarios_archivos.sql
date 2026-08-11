-- ============================================================
-- HORARIOS POR ARCHIVO — el horario de la semana como documento
--
-- El módulo de turnos estructurado (tablas `turnos`, `horarios_roles_def`)
-- sigue existiendo para el checador. Esto es OTRA cosa, y a propósito:
-- cada área arma su horario como siempre lo ha hecho (Excel, papel, Canva)
-- y solo SUBE el archivo de la semana. Cero captura.
--
-- La pieza clave es `semana_inicio` (siempre lunes): el archivo se guarda
-- contra la semana a la que APLICA, no contra el día en que se subió. Por eso
-- el encargado puede subir el domingo el horario de la semana que arranca
-- mañana, y el administrador lo ve en la semana correcta.
-- ============================================================

-- ---------- Bucket privado ----------
-- Privado porque el archivo trae nombres del personal (PII). El admin lo abre
-- con URL firmada; nadie más lo lee. Mismo patrón que 'factura-tickets'.
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'horarios', 'horarios', false, 20971520,  -- 20 MB
  ARRAY[
    'application/pdf',
    'image/jpeg','image/png','image/webp','image/heic','image/heif',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/msword'
  ]
)
ON CONFLICT (id) DO UPDATE
  SET public = EXCLUDED.public,
      file_size_limit = EXCLUDED.file_size_limit,
      allowed_mime_types = EXCLUDED.allowed_mime_types;

-- El encargado de área (anon, detrás del PIN de sucursal) sube pero no lee.
DROP POLICY IF EXISTS "horarios_sube" ON storage.objects;
CREATE POLICY "horarios_sube" ON storage.objects
  FOR INSERT TO anon, authenticated
  WITH CHECK (bucket_id = 'horarios');

-- Solo el admin (authenticated) lee y borra.
DROP POLICY IF EXISTS "horarios_lee" ON storage.objects;
CREATE POLICY "horarios_lee" ON storage.objects
  FOR SELECT TO authenticated
  USING (bucket_id = 'horarios');

DROP POLICY IF EXISTS "horarios_borra" ON storage.objects;
CREATE POLICY "horarios_borra" ON storage.objects
  FOR DELETE TO authenticated
  USING (bucket_id = 'horarios');

-- ---------- Tabla ----------
CREATE TABLE IF NOT EXISTS public.horarios_archivos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  sucursal_id uuid NOT NULL REFERENCES public.sucursales(id) ON DELETE CASCADE,
  area text NOT NULL,
  -- Lunes de la semana que cubre el horario. Se normaliza en el RPC.
  semana_inicio date NOT NULL,
  archivo_path text NOT NULL,
  archivo_nombre text NOT NULL,
  mime text,
  tamano_bytes integer,
  subido_por text,
  nota text,
  version integer NOT NULL DEFAULT 1,
  -- Al resubir, la anterior queda vigente=false pero NO se borra: si alguien
  -- reclama que le cambiaron el horario, la versión previa sigue ahí.
  vigente boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS horarios_archivos_vigente_unico
  ON public.horarios_archivos (sucursal_id, area, semana_inicio)
  WHERE vigente;

CREATE INDEX IF NOT EXISTS horarios_archivos_semana_idx
  ON public.horarios_archivos (semana_inicio DESC, sucursal_id);

ALTER TABLE public.horarios_archivos ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "staff_todo_horarios_archivos" ON public.horarios_archivos;
CREATE POLICY "staff_todo_horarios_archivos" ON public.horarios_archivos
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- ---------- Registrar un archivo (público, detrás del PIN de sucursal) ----------
CREATE OR REPLACE FUNCTION public.horarios_archivo_registrar(
  p_sucursal_id uuid,
  p_pin text,
  p_area text,
  p_semana_inicio date,
  p_path text,
  p_nombre text,
  p_mime text DEFAULT NULL,
  p_tamano_bytes integer DEFAULT NULL,
  p_subido_por text DEFAULT NULL,
  p_nota text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $hor$
DECLARE
  v_pin text;
  v_area text;
  v_semana date;
  v_version integer;
  v_id uuid;
BEGIN
  SELECT pin INTO v_pin FROM sucursales WHERE id = p_sucursal_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'SUCURSAL_INVALIDA';
  END IF;
  -- Si la sucursal tiene PIN, se exige (igual que el gate de operaciones).
  IF v_pin IS NOT NULL AND COALESCE(trim(p_pin), '') <> v_pin THEN
    RAISE EXCEPTION 'PIN_INVALIDO';
  END IF;

  v_area := lower(trim(COALESCE(p_area, '')));
  IF v_area = '' THEN
    RAISE EXCEPTION 'AREA_REQUERIDA';
  END IF;

  IF p_semana_inicio IS NULL THEN
    RAISE EXCEPTION 'SEMANA_REQUERIDA';
  END IF;
  -- date_trunc('week') en Postgres cae en lunes: la semana queda normalizada
  -- aunque el front mande cualquier día de ella.
  v_semana := (date_trunc('week', p_semana_inicio::timestamp))::date;

  IF NULLIF(trim(COALESCE(p_path, '')), '') IS NULL THEN
    RAISE EXCEPTION 'ARCHIVO_REQUERIDO';
  END IF;

  SELECT COALESCE(MAX(version), 0) + 1 INTO v_version
  FROM horarios_archivos
  WHERE sucursal_id = p_sucursal_id AND area = v_area AND semana_inicio = v_semana;

  UPDATE horarios_archivos
     SET vigente = false
   WHERE sucursal_id = p_sucursal_id AND area = v_area
     AND semana_inicio = v_semana AND vigente;

  INSERT INTO horarios_archivos (
    sucursal_id, area, semana_inicio, archivo_path, archivo_nombre,
    mime, tamano_bytes, subido_por, nota, version, vigente
  ) VALUES (
    p_sucursal_id, v_area, v_semana, trim(p_path), trim(COALESCE(p_nombre, 'horario')),
    NULLIF(trim(COALESCE(p_mime, '')), ''), p_tamano_bytes,
    NULLIF(trim(COALESCE(p_subido_por, '')), ''), NULLIF(trim(COALESCE(p_nota, '')), ''),
    v_version, true
  )
  RETURNING id INTO v_id;

  RETURN jsonb_build_object(
    'ok', true, 'id', v_id, 'semana_inicio', v_semana,
    'version', v_version, 'reemplazo', v_version > 1
  );
END;
$hor$;

GRANT EXECUTE ON FUNCTION public.horarios_archivo_registrar(uuid, text, text, date, text, text, text, integer, text, text)
  TO anon, authenticated;

-- ---------- Qué áreas ya subieron (público, para la pantalla de carga) ----------
-- Devuelve solo lo necesario para que el encargado vea qué falta de SU sucursal.
-- No expone el archivo ni su ruta.
CREATE OR REPLACE FUNCTION public.horarios_semana_publico(
  p_sucursal_id uuid,
  p_pin text,
  p_semana_inicio date
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $hsp$
DECLARE
  v_pin text;
  v_semana date;
  v_rows jsonb;
BEGIN
  SELECT pin INTO v_pin FROM sucursales WHERE id = p_sucursal_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'SUCURSAL_INVALIDA';
  END IF;
  IF v_pin IS NOT NULL AND COALESCE(trim(p_pin), '') <> v_pin THEN
    RAISE EXCEPTION 'PIN_INVALIDO';
  END IF;

  v_semana := (date_trunc('week', COALESCE(p_semana_inicio, current_date)::timestamp))::date;

  SELECT COALESCE(jsonb_agg(jsonb_build_object(
           'area', area,
           'subido_por', subido_por,
           'created_at', created_at,
           'version', version
         ) ORDER BY area), '[]'::jsonb)
    INTO v_rows
  FROM horarios_archivos
  WHERE sucursal_id = p_sucursal_id AND semana_inicio = v_semana AND vigente;

  RETURN jsonb_build_object('ok', true, 'semana_inicio', v_semana, 'areas', v_rows);
END;
$hsp$;

GRANT EXECUTE ON FUNCTION public.horarios_semana_publico(uuid, text, date)
  TO anon, authenticated;
