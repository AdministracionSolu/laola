-- ============================================================
-- UN TICKET, UNA VISITA — PARA SIEMPRE (lealtad)
--
-- Lo que estaba pasando: en producción sigue viva la `lealtad_visita`
-- de la v4 (26-jul), que sólo compara el folio contra las visitas del
-- MISMO día. Guardar un ticket y teclearlo mañana contaba otra visita.
-- El front ya decía "Cada ticket cuenta una sola vez" y el panel de
-- anomalías ya sabía pintar 'folio_repetido' y 'folio_invalido' — la
-- base era la única que no se había enterado.
--
-- (La migración 20260804150000_lealtad_folio_blindaje.sql ya traía esto
-- a medias pero NUNCA se corrió: `lealtad_folio_sospechoso` no existe en
-- la base. Esta la reemplaza y la incluye completa. Si algún día se corre
-- aquélla por error, PISA ésta con la versión de ventana de 180 días.)
--
-- Diferencia con aquélla: aquí el folio se consume PARA SIEMPRE en su
-- sucursal, sin ventana de días, y el candado también vive en un índice
-- único — no sólo en la RPC.
--
-- Caso que lo destapó: Erick Esquivel (3313508753) tecleó el 25-ago el
-- folio 198463, que ya había usado el 24. 43 minutos después intentó su
-- ticket real de ese día (198502) y le rebotó por tope diario. Sí comió
-- el 25; nomás quedó registrado con el folio equivocado. Bloque 1.
--
-- ORDEN: los bloques 1 y 2 van ANTES del 3 o el índice único falla.
-- ============================================================


-- ============================================================
-- BLOQUE 1 — El folio equivocado de Erick (25-ago)
-- La visita se queda; el folio pasa al real, el que dejó rastro
-- en lealtad_intentos ese mismo día a las 21:42Z.
-- ============================================================
UPDATE public.lealtad_visitas
SET folio = '198502', folio_norm = '198502'
WHERE id = 'd79f43c9-aeca-47c8-8b34-61c23514d20f'
  AND folio_norm = '198463';


-- ============================================================
-- BLOQUE 2 — El folio de prueba '1000' (Diego, 21-jul)
-- Se usó dos veces cuando se estaba probando el flujo. La visita
-- se conserva; se le quita el folio para que salga del índice
-- (que es parcial: WHERE folio_norm IS NOT NULL).
-- ============================================================
UPDATE public.lealtad_visitas
SET folio = NULL, folio_norm = NULL
WHERE id = '9f6310ea-1d5d-4ff1-91bf-1a7c0dcc7348'
  AND folio_norm = '1000';


-- ============================================================
-- BLOQUE 3 — El candado en la base
-- Antes: único por (sucursal, DÍA, folio). Ahora: por (sucursal, folio).
-- Sigue siendo parcial para que las altas sin folio (origen 'registro')
-- convivan sin chocar.
--
-- Si algún día el punto de venta reinicia su contador de folios, este
-- índice va a empezar a rechazar tickets legítimos y se van a ver como
-- 'folio_repetido' en Anomalías. Ese es el momento de meterle el año.
-- ============================================================
DROP INDEX IF EXISTS public.lealtad_visitas_folio_uniq;

CREATE UNIQUE INDEX IF NOT EXISTS lealtad_visitas_folio_suc_uniq
  ON public.lealtad_visitas (COALESCE(sucursal_id::text, ''), folio_norm)
  WHERE folio_norm IS NOT NULL;

-- Para que la RPC busque folios usados sin escanear la tabla.
CREATE INDEX IF NOT EXISTS lealtad_visitas_folio_suc_idx
  ON public.lealtad_visitas (sucursal_id, folio_norm, fecha_negocio DESC);


-- ============================================================
-- BLOQUE 4 — ¿Esto parece un folio de ticket?
-- Devuelve NULL si está bien, o el motivo del rechazo.
-- (Venía de la migración del 4-ago que nunca se corrió.)
-- ============================================================
CREATE OR REPLACE FUNCTION public.lealtad_folio_sospechoso(p_folio_norm text)
RETURNS text
LANGUAGE plpgsql
IMMUTABLE
SET search_path = public
AS $$
DECLARE
  v_digitos text := regexp_replace(COALESCE(p_folio_norm, ''), '\D', '', 'g');
  v_asc     text := '01234567890123456789';
  v_desc    text := '98765432109876543210';
BEGIN
  -- Un ticket real trae número. Menos de 4 dígitos no es folio.
  IF char_length(v_digitos) < 4 THEN RETURN 'muy_corto'; END IF;

  -- 1111, 000000, 55555: teclado, no ticket.
  IF v_digitos ~ ('^(' || substr(v_digitos, 1, 1) || ')+$') THEN RETURN 'repetido'; END IF;

  -- 1234, 123456, 4321: secuencia corrida.
  IF position(v_digitos in v_asc) > 0 OR position(v_digitos in v_desc) > 0 THEN
    RETURN 'secuencia';
  END IF;

  RETURN NULL;
END;
$$;

REVOKE ALL ON FUNCTION public.lealtad_folio_sospechoso(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.lealtad_folio_sospechoso(text) TO anon, authenticated;


-- ============================================================
-- BLOQUE 5 — lealtad_visita v7
-- Igual que la v4 viva salvo la parte del folio:
--   · se valida que parezca folio      → status 'folio_invalido'
--   · se busca en TODA la historia de la sucursal, no sólo hoy:
--       - mismo cliente, mismo día  → 'ya_hoy' (doble tap, le mostramos
--         su progreso; no es trampa)
--       - mismo cliente, otro día   → 'folio_usado' + intento
--         'folio_repetido' (esto es lo que hacía Erick)
--       - otro teléfono             → 'folio_usado' + intento
--         'folio_usado' (esto sí huele a ticket compartido)
-- ============================================================
CREATE OR REPLACE FUNCTION public.lealtad_visita(
  p_telefono         text,
  p_sucursal_codigo  text DEFAULT NULL,
  p_folio            text DEFAULT NULL,
  p_primer_nombre    text DEFAULT NULL,
  p_segundo_nombre   text DEFAULT NULL,
  p_apellido_paterno text DEFAULT NULL,
  p_apellido_materno text DEFAULT NULL,
  p_cumpleanos       date DEFAULT NULL,
  p_consentimiento   boolean DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_tel        text;
  v_folio_norm text;
  v_mal        text;
  v_cli        lealtad_clientes%ROWTYPE;
  v_prev       lealtad_visitas%ROWTYPE;
  v_suc_id     uuid;
  v_fecha      date := laola_fecha_negocio(now());
  v_hoy        int;
  v_tope       int;
  v_nombre     text;
BEGIN
  v_tel := regexp_replace(COALESCE(p_telefono, ''), '\D', '', 'g');
  IF char_length(v_tel) <> 10 THEN
    RAISE EXCEPTION 'TELEFONO_INVALIDO';
  END IF;

  v_folio_norm := upper(regexp_replace(COALESCE(p_folio, ''), '\s', '', 'g'));
  IF v_folio_norm = '' THEN
    RAISE EXCEPTION 'FOLIO_REQUERIDO';
  END IF;
  IF char_length(v_folio_norm) > 40 THEN
    RAISE EXCEPTION 'FOLIO_INVALIDO';
  END IF;

  IF p_sucursal_codigo IS NOT NULL THEN
    SELECT id INTO v_suc_id FROM sucursales
    WHERE upper(prefijo_folio) = upper(trim(p_sucursal_codigo)) LIMIT 1;
  END IF;

  -- ¿Tiene forma de folio de ticket?
  v_mal := lealtad_folio_sospechoso(v_folio_norm);
  IF v_mal IS NOT NULL THEN
    INSERT INTO lealtad_intentos (telefono, folio_norm, sucursal_id, motivo, fecha_negocio)
    VALUES (v_tel, v_folio_norm, v_suc_id, 'folio_invalido', v_fecha);
    RETURN jsonb_build_object('status', 'folio_invalido');
  END IF;

  SELECT * INTO v_cli FROM lealtad_clientes WHERE telefono = v_tel;

  -- ¿Ese folio ya se consumió alguna vez en esta sucursal?
  -- Sin filtro de fecha: un ticket vale UNA visita, no una por día.
  SELECT * INTO v_prev FROM lealtad_visitas
  WHERE COALESCE(sucursal_id::text, '') = COALESCE(v_suc_id::text, '')
    AND folio_norm = v_folio_norm
  ORDER BY fecha_negocio DESC
  LIMIT 1;

  IF FOUND THEN
    -- Mismo cliente, mismo día: es doble tap, le mostramos su progreso.
    IF v_cli.id IS NOT NULL AND v_cli.id = v_prev.cliente_id
       AND v_prev.fecha_negocio = v_fecha THEN
      RETURN jsonb_build_object('status', 'ya_hoy') || lealtad_perfil_json(v_cli);
    END IF;

    INSERT INTO lealtad_intentos (telefono, folio_norm, sucursal_id, motivo, fecha_negocio)
    VALUES (
      v_tel, v_folio_norm, v_suc_id,
      CASE WHEN v_cli.id IS NOT NULL AND v_cli.id = v_prev.cliente_id
           THEN 'folio_repetido'   -- reusó su propio ticket de otro día
           ELSE 'folio_usado'      -- otro teléfono con un ticket ya cobrado
      END,
      v_fecha);
    RETURN jsonb_build_object('status', 'folio_usado');
  END IF;

  -- ---------- Cliente NUEVO ----------
  IF v_cli.id IS NULL THEN
    IF NULLIF(trim(COALESCE(p_primer_nombre, '')), '') IS NULL
       OR NULLIF(trim(COALESCE(p_apellido_paterno, '')), '') IS NULL
       OR NULLIF(trim(COALESCE(p_apellido_materno, '')), '') IS NULL THEN
      RETURN jsonb_build_object('status', 'necesita_registro');
    END IF;

    IF p_cumpleanos IS NULL THEN
      RAISE EXCEPTION 'CUMPLE_REQUERIDO';
    END IF;
    IF p_consentimiento IS NOT TRUE THEN
      RAISE EXCEPTION 'CONSENTIMIENTO_REQUERIDO';
    END IF;

    v_nombre := btrim(regexp_replace(
      concat_ws(' ',
        trim(p_primer_nombre),
        NULLIF(trim(COALESCE(p_segundo_nombre, '')), ''),
        trim(p_apellido_paterno),
        trim(p_apellido_materno)),
      '\s+', ' ', 'g'));

    INSERT INTO lealtad_clientes (
      telefono, nombre, primer_nombre, segundo_nombre, apellido_paterno, apellido_materno,
      cumpleanos, sucursal_captacion_id, sucursal_captacion_codigo,
      consentimiento_marketing, consentimiento_at, activo, visitas_total, ultima_visita
    ) VALUES (
      v_tel, v_nombre, trim(p_primer_nombre), NULLIF(trim(COALESCE(p_segundo_nombre, '')), ''),
      trim(p_apellido_paterno), trim(p_apellido_materno),
      p_cumpleanos, v_suc_id, upper(trim(p_sucursal_codigo)),
      true, now(), true, 1, now()
    ) RETURNING * INTO v_cli;

    INSERT INTO lealtad_visitas (cliente_id, sucursal_id, fecha_negocio, origen, folio, folio_norm)
    VALUES (v_cli.id, v_suc_id, v_fecha, 'qr', trim(p_folio), v_folio_norm);

    RETURN jsonb_build_object('status', 'registrado') || lealtad_perfil_json(v_cli);
  END IF;

  -- ---------- Cliente EXISTENTE ----------
  SELECT tope_visitas_dia INTO v_tope FROM lealtad_config WHERE id = 1;
  v_tope := GREATEST(1, COALESCE(v_tope, 1));
  SELECT count(*) INTO v_hoy FROM lealtad_visitas
  WHERE cliente_id = v_cli.id AND fecha_negocio = v_fecha;

  IF v_hoy >= v_tope THEN
    INSERT INTO lealtad_intentos (telefono, folio_norm, sucursal_id, motivo, fecha_negocio)
    VALUES (v_tel, v_folio_norm, v_suc_id, 'ya_hoy', v_fecha);
    RETURN jsonb_build_object('status', 'ya_hoy') || lealtad_perfil_json(v_cli);
  END IF;

  IF v_cli.primer_nombre IS NULL AND NULLIF(trim(COALESCE(p_primer_nombre, '')), '') IS NOT NULL
     AND NULLIF(trim(COALESCE(p_apellido_paterno, '')), '') IS NOT NULL THEN
    UPDATE lealtad_clientes SET
      primer_nombre    = trim(p_primer_nombre),
      segundo_nombre   = NULLIF(trim(COALESCE(p_segundo_nombre, '')), ''),
      apellido_paterno = trim(p_apellido_paterno),
      apellido_materno = NULLIF(trim(COALESCE(p_apellido_materno, '')), ''),
      cumpleanos       = COALESCE(cumpleanos, p_cumpleanos)
    WHERE id = v_cli.id;
  END IF;

  INSERT INTO lealtad_visitas (cliente_id, sucursal_id, fecha_negocio, origen, folio, folio_norm)
  VALUES (v_cli.id, v_suc_id, v_fecha, 'qr', trim(p_folio), v_folio_norm);

  UPDATE lealtad_clientes
  SET visitas_total = visitas_total + 1,
      ultima_visita = now(),
      activo = true
  WHERE id = v_cli.id
  RETURNING * INTO v_cli;

  RETURN jsonb_build_object('status', 'ok') || lealtad_perfil_json(v_cli);
END;
$$;

REVOKE ALL ON FUNCTION public.lealtad_visita(text, text, text, text, text, text, text, date, boolean) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.lealtad_visita(text, text, text, text, text, text, text, date, boolean)
  TO anon, authenticated;


-- ============================================================
-- BLOQUE 6 — Verificación (correr y leer el resultado)
-- ============================================================
-- 1) Erick debe quedar con 3 visitas y folios 198463 / 198502 / 198554
SELECT v.fecha_negocio, v.origen, v.folio
FROM public.lealtad_visitas v
JOIN public.lealtad_clientes c ON c.id = v.cliente_id
WHERE c.telefono = '3313508753'
ORDER BY v.fecha_negocio;

-- 2) No debe quedar ningún folio repetido por sucursal (0 filas)
SELECT COALESCE(sucursal_id::text, '') AS suc, folio_norm, count(*)
FROM public.lealtad_visitas
WHERE folio_norm IS NOT NULL
GROUP BY 1, 2 HAVING count(*) > 1;

-- 3) El candado nuevo existe y el viejo ya no
SELECT indexname FROM pg_indexes
WHERE tablename = 'lealtad_visitas' AND indexname LIKE '%folio%';

-- 4) La función del folio sospechoso ya existe
--    ('repetido', 'secuencia', 'muy_corto', NULL)
SELECT public.lealtad_folio_sospechoso('1111'),
       public.lealtad_folio_sospechoso('123456'),
       public.lealtad_folio_sospechoso('12'),
       public.lealtad_folio_sospechoso('198554');
