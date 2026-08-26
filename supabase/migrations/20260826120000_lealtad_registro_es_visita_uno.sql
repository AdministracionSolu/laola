-- =====================================================================
-- LEALTAD v6 — INSCRIBIRSE ES LA VISITA 1
--
-- El problema (Diego, 26-ago-2026): el programa se sentía en dos etapas.
-- El cliente se registraba, la pantalla le decía "tienes tu Recompensa
-- inicial disponible"… y para canjearla tenía que salir, entrar por "Ya
-- soy miembro" y teclear el folio de un ticket. Ese brinco es donde se
-- caen los clientes y donde el mesero pierde la paciencia.
--
-- La regla nueva: **nadie se registra desde su casa**. Si se está
-- inscribiendo es porque está sentado en una mesa, así que la inscripción
-- ES la visita 1, cuenta como visita, y la Recompensa inicial se canjea
-- ahí mismo, sin folio.
--
-- Lo que NO cambia: de la segunda visita en adelante SIEMPRE se pide
-- folio. El folio es lo único que impide que alguien sume visitas desde
-- el sofá, y sigue siendo único por sucursal (blindaje del 4-ago).
--
-- Y no se manda mensaje por esa primera visita: su mensaje es la
-- bienvenida. Eso se resuelve en el BLOQUE 5, marcando el estado `alta`,
-- que del lado de Makatea cae en el segmento `lealtad_alta` — fuera de la
-- audiencia de "Día siguiente · visita normal".
--
-- Además, BLOQUES 1-2: el padrón de colaboradores y el corte semanal del
-- grupo de WhatsApp del equipo, que Makatea empuja cada lunes.
--
-- Idempotente. Se corre BLOQUE POR BLOQUE en el SQL Editor.
-- =====================================================================


-- =====================================================================
-- BLOQUE 1 — Padrón de colaboradores
--
-- Diego corrió el seed del 14-ago (`20260814120000`) la mañana del 26, así
-- que la tabla YA EXISTE con esos 77 números y este bloque no hace nada.
-- Se deja por si la base se levanta desde cero: de aquí en adelante quien
-- la llena es el corte semanal del grupo, que trae el estado de hoy y no
-- el de hace doce días.
-- =====================================================================
CREATE TABLE IF NOT EXISTS public.lealtad_colaboradores (
  telefono     text PRIMARY KEY,          -- 10 dígitos, mismo formato que lealtad_clientes.telefono
  telefono_wa  text,                      -- como aparece en WhatsApp (con 521)
  nombre_wa    text,                      -- pushName de la agenda, puede venir vacío
  admin_grupo  boolean NOT NULL DEFAULT false,
  origen       text NOT NULL DEFAULT 'grupo_wa_la_ola',
  activo       boolean NOT NULL DEFAULT true,
  notas        text,
  agregado_at  timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.lealtad_colaboradores IS
  'Padrón de colaboradores de La Ola, alimentado por el corte semanal del grupo de WhatsApp del equipo. SOLO SUMA: quien se sale del grupo se queda marcado (regla de Diego, 26-ago-2026); la baja es a mano con activo=false.';

ALTER TABLE public.lealtad_colaboradores ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS colaboradores_admin_select ON public.lealtad_colaboradores;
CREATE POLICY colaboradores_admin_select ON public.lealtad_colaboradores
  FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS colaboradores_admin_write ON public.lealtad_colaboradores;
CREATE POLICY colaboradores_admin_write ON public.lealtad_colaboradores
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

REVOKE ALL ON public.lealtad_colaboradores FROM anon;
GRANT SELECT, INSERT, UPDATE ON public.lealtad_colaboradores TO authenticated;


-- =====================================================================
-- BLOQUE 2 — El corte semanal escribe por aquí
--
-- Makatea (edge `laola-colaboradores-sync`, cron los lunes 09:00 de
-- Mazatlán) lee el grupo de WhatsApp del equipo y llama a esta RPC con el
-- mismo secreto compartido que ya usa el puente. Es la única puerta: anon
-- no toca la tabla.
--
-- SOLO SUMA. Un UPDATE nunca apaga `activo` ni borra un nombre bueno con
-- un vacío: quien salga del grupo se queda, que es la regla.
-- =====================================================================
CREATE OR REPLACE FUNCTION public.lealtad_colaboradores_sync(
  p_secreto text,
  p_items   jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_cfg    integracion_makatea%ROWTYPE;
  v_nuevos int := 0;
  v_total  int := 0;
BEGIN
  SELECT * INTO v_cfg FROM integracion_makatea WHERE id = 1;
  IF NOT FOUND OR v_cfg.secreto IS NULL OR v_cfg.secreto = ''
     OR p_secreto IS NULL OR p_secreto <> v_cfg.secreto THEN
    RAISE EXCEPTION 'SECRETO_INVALIDO';
  END IF;

  IF p_items IS NULL OR jsonb_typeof(p_items) <> 'array' THEN
    RAISE EXCEPTION 'ITEMS_INVALIDOS';
  END IF;

  WITH entrada AS (
    SELECT
      regexp_replace(COALESCE(i->>'telefono', ''), '\D', '', 'g')    AS telefono,
      NULLIF(regexp_replace(COALESCE(i->>'telefono_wa', ''), '\D', '', 'g'), '') AS telefono_wa,
      NULLIF(btrim(COALESCE(i->>'nombre_wa', '')), '')               AS nombre_wa,
      COALESCE((i->>'admin_grupo')::boolean, false)                  AS admin_grupo
    FROM jsonb_array_elements(p_items) i
  ), buenos AS (
    -- Diez dígitos ya normalizados del otro lado. Lo que no cuadre se cae
    -- aquí en vez de entrar recortado a la fuerza.
    SELECT DISTINCT ON (telefono) * FROM entrada WHERE char_length(telefono) = 10
  ), guardados AS (
    INSERT INTO public.lealtad_colaboradores AS c
      (telefono, telefono_wa, nombre_wa, admin_grupo)
    SELECT telefono, telefono_wa, nombre_wa, admin_grupo FROM buenos
    ON CONFLICT (telefono) DO UPDATE SET
      telefono_wa = COALESCE(EXCLUDED.telefono_wa, c.telefono_wa),
      nombre_wa   = COALESCE(EXCLUDED.nombre_wa,   c.nombre_wa),
      admin_grupo = EXCLUDED.admin_grupo
      -- `activo` NO se toca a propósito: el corte solo suma.
    RETURNING (xmax = 0) AS es_nuevo
  )
  SELECT count(*), count(*) FILTER (WHERE es_nuevo) INTO v_total, v_nuevos FROM guardados;

  RETURN jsonb_build_object(
    'ok', true,
    'recibidos', jsonb_array_length(p_items),
    'guardados', v_total,
    'nuevos',    v_nuevos,
    'padron',    (SELECT count(*) FROM lealtad_colaboradores)
  );
END;
$$;

REVOKE ALL ON FUNCTION public.lealtad_colaboradores_sync(text, jsonb) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.lealtad_colaboradores_sync(text, jsonb) TO anon, authenticated;


-- =====================================================================
-- BLOQUE 3 — lealtad_registrar v6: inscribirse cuenta como visita 1
--
-- Misma firma que antes (el front no cambia de contrato), pero ahora:
--   · si el teléfono es nuevo, se le abre la visita 1 (origen 'registro',
--     SIN folio) y se le pone ultima_visita;
--   · devuelve el PERFIL COMPLETO, para que la pantalla siguiente ya sea
--     su promoción y no un "gracias" que obliga a volver a empezar.
--
-- El folio va NULL a propósito: el índice único de folio es parcial
-- (WHERE folio_norm IS NOT NULL), así que varias altas del mismo día en
-- la misma sucursal conviven sin chocar.
-- =====================================================================
CREATE OR REPLACE FUNCTION public.lealtad_registrar(
  p_primer_nombre    text,
  p_apellido_paterno text,
  p_apellido_materno text,
  p_telefono         text,
  p_cumpleanos       date,
  p_segundo_nombre   text DEFAULT NULL,
  p_sucursal_codigo  text DEFAULT NULL,
  p_consentimiento   boolean DEFAULT true
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $leal$
DECLARE
  v_tel      text;
  v_suc_id   uuid;
  v_nombre   text;
  v_nuevo    boolean;
  v_cli      lealtad_clientes%ROWTYPE;
  v_fecha    date := laola_fecha_negocio(now());
  v_visitas  int;
BEGIN
  v_tel := regexp_replace(COALESCE(p_telefono, ''), '\D', '', 'g');
  IF char_length(v_tel) <> 10 THEN
    RAISE EXCEPTION 'TELEFONO_INVALIDO';
  END IF;

  IF NULLIF(trim(COALESCE(p_primer_nombre, '')), '') IS NULL
     OR NULLIF(trim(COALESCE(p_apellido_paterno, '')), '') IS NULL
     OR NULLIF(trim(COALESCE(p_apellido_materno, '')), '') IS NULL THEN
    RAISE EXCEPTION 'NOMBRE_INCOMPLETO';
  END IF;

  IF p_cumpleanos IS NULL THEN
    RAISE EXCEPTION 'CUMPLE_REQUERIDO';
  END IF;

  IF p_consentimiento IS NOT TRUE THEN
    RAISE EXCEPTION 'CONSENTIMIENTO_REQUERIDO';
  END IF;

  IF p_sucursal_codigo IS NOT NULL THEN
    SELECT id INTO v_suc_id FROM sucursales
    WHERE upper(prefijo_folio) = upper(trim(p_sucursal_codigo)) LIMIT 1;
  END IF;

  v_nombre := btrim(regexp_replace(concat_ws(' ',
    trim(p_primer_nombre), NULLIF(trim(COALESCE(p_segundo_nombre, '')), ''),
    trim(p_apellido_paterno), trim(p_apellido_materno)), '\s+', ' ', 'g'));

  INSERT INTO lealtad_clientes (
    telefono, nombre, primer_nombre, segundo_nombre, apellido_paterno, apellido_materno,
    cumpleanos, sucursal_captacion_id, sucursal_captacion_codigo,
    consentimiento_marketing, consentimiento_at, activo
  ) VALUES (
    v_tel, v_nombre, trim(p_primer_nombre), NULLIF(trim(COALESCE(p_segundo_nombre, '')), ''),
    trim(p_apellido_paterno), trim(p_apellido_materno),
    p_cumpleanos, v_suc_id, upper(trim(p_sucursal_codigo)),
    true, now(), true
  )
  ON CONFLICT (telefono) DO UPDATE SET
    nombre           = EXCLUDED.nombre,
    primer_nombre    = EXCLUDED.primer_nombre,
    segundo_nombre   = EXCLUDED.segundo_nombre,
    apellido_paterno = EXCLUDED.apellido_paterno,
    apellido_materno = EXCLUDED.apellido_materno,
    cumpleanos       = COALESCE(lealtad_clientes.cumpleanos, EXCLUDED.cumpleanos),
    activo           = true,
    consentimiento_marketing = true,
    consentimiento_at = COALESCE(lealtad_clientes.consentimiento_at, now())
  -- `xmax = 0` distingue el INSERT del UPDATE del upsert. Va solo en su
  -- propio RETURNING: un INTO no puede repartir columnas entre una
  -- variable de tipo fila y un escalar en la misma llamada.
  RETURNING (xmax = 0) INTO v_nuevo;

  SELECT * INTO v_cli FROM lealtad_clientes WHERE telefono = v_tel;

  IF v_suc_id IS NOT NULL THEN
    UPDATE lealtad_clientes
    SET sucursal_captacion_id = v_suc_id,
        sucursal_captacion_codigo = upper(trim(p_sucursal_codigo))
    WHERE telefono = v_tel AND sucursal_captacion_id IS NULL;
  END IF;

  -- La visita 1. Se abre solo si el cliente no tiene NINGUNA visita: quien
  -- ya venía sumando y vuelve a llenar el formulario no gana una visita de
  -- regalo, y si le da dos veces al botón tampoco.
  SELECT count(*) INTO v_visitas FROM lealtad_visitas WHERE cliente_id = v_cli.id;

  IF v_visitas = 0 THEN
    INSERT INTO lealtad_visitas (cliente_id, sucursal_id, fecha_negocio, origen, folio, folio_norm)
    VALUES (v_cli.id, v_suc_id, v_fecha, 'registro', NULL, NULL);

    UPDATE lealtad_clientes
    SET visitas_total = GREATEST(COALESCE(visitas_total, 0), 1),
        ultima_visita = COALESCE(ultima_visita, now())
    WHERE id = v_cli.id
    RETURNING * INTO v_cli;
  END IF;

  RETURN jsonb_build_object(
    'ok',     true,
    'nuevo',  COALESCE(v_nuevo, false),
    'status', CASE WHEN COALESCE(v_nuevo, false) THEN 'registrado' ELSE 'ya_estaba' END
  ) || lealtad_perfil_json(v_cli);
END;
$leal$;

GRANT EXECUTE ON FUNCTION public.lealtad_registrar(text, text, text, text, date, text, text, boolean)
  TO anon, authenticated;


-- =====================================================================
-- BLOQUE 4 — Todos arrancan en la visita 1
--
-- Los que ya estaban inscritos también se inscribieron estando sentados
-- en una mesa, así que les toca su visita 1 con la fecha de su alta.
--
-- Ojo con el orden: primero las visitas, luego el contador. `ultima_visita`
-- NO se toca — moverla dispararía trg_makatea_push para todo el padrón y
-- re-anclaría calendarios que ya están corriendo. El puente ya lee
-- COALESCE(ultima_visita, created_at), así que no hace falta.
-- =====================================================================
INSERT INTO lealtad_visitas (cliente_id, sucursal_id, fecha_negocio, origen, folio, folio_norm)
SELECT c.id,
       c.sucursal_captacion_id,
       laola_fecha_negocio(c.created_at),
       'registro',
       NULL,
       NULL
FROM lealtad_clientes c
WHERE NOT EXISTS (SELECT 1 FROM lealtad_visitas v WHERE v.cliente_id = c.id);

UPDATE lealtad_clientes c
SET visitas_total = v.n
FROM (SELECT cliente_id, count(*) AS n FROM lealtad_visitas GROUP BY 1) v
WHERE v.cliente_id = c.id
  AND COALESCE(c.visitas_total, 0) <> v.n;


-- =====================================================================
-- BLOQUE 5 — El estado `alta`: la primera visita no lleva mensaje
--
-- Precedencia nueva: alta > canje > cerca > normal.
--
-- `alta` = el cliente no tiene NINGUNA visita con ticket todavía (solo la
-- de su inscripción). Del otro lado, Makatea lo pone en el segmento
-- `lealtad_alta`, que escuchan la bienvenida, el calendario día cero y el
-- cumpleaños, pero NO "Día siguiente · visita normal" ni "· canjeó
-- beneficio". Así el recién inscrito recibe su bienvenida y nada más — y
-- en cuanto registre su primera visita CON folio, el estado cambia solo y
-- el segmento se mueve con él.
--
-- Sin esto, quien canjea su Recompensa inicial el mismo día del alta se
-- ganaba además el mensaje de "esperamos que tu regalo te haya gustado"
-- al día siguiente.
-- =====================================================================
CREATE OR REPLACE FUNCTION public.makatea_push_clientes(p_cliente_ids uuid[])
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_cfg     integracion_makatea%ROWTYPE;
  v_payload jsonb;
  v_meta    int;
  v_anio    int := EXTRACT(YEAR FROM (now() AT TIME ZONE 'America/Mazatlan'))::int;
BEGIN
  SELECT * INTO v_cfg FROM integracion_makatea WHERE id = 1 AND activo;
  IF NOT FOUND OR v_cfg.base_url LIKE '%PON-AQUI%' THEN RETURN; END IF;

  SELECT GREATEST(1, COALESCE(meta_visitas, 3)) INTO v_meta FROM lealtad_config WHERE id = 1;
  v_meta := COALESCE(v_meta, 3);

  SELECT jsonb_agg(jsonb_build_object(
    'telefono', c.telefono,
    'nombre', c.nombre,
    'ultima_visita', to_char(laola_fecha_negocio(COALESCE(c.ultima_visita, c.created_at)), 'YYYY-MM-DD'),
    'cumpleanos', to_char(c.cumpleanos, 'YYYY-MM-DD'),
    'sucursal', c.sucursal_captacion_codigo,
    'estado', est.estado
  ))
  INTO v_payload
  FROM lealtad_clientes c
  CROSS JOIN LATERAL (
    SELECT
      (SELECT count(*) FROM lealtad_visitas v
        WHERE v.cliente_id = c.id
          AND EXTRACT(YEAR FROM v.fecha_negocio)::int = v_anio) AS vis_anio,
      (SELECT count(*) FROM lealtad_canjes k
        WHERE k.cliente_id = c.id AND k.posicion > 0
          AND EXTRACT(YEAR FROM k.fecha_negocio)::int = v_anio) AS can_anio
  ) n
  CROSS JOIN LATERAL (
    SELECT CASE
      -- Recién inscrito: todavía no ha registrado una visita con ticket.
      WHEN NOT EXISTS (
        SELECT 1 FROM lealtad_visitas v2
        WHERE v2.cliente_id = c.id AND COALESCE(v2.origen, '') <> 'registro'
      ) THEN 'alta'
      WHEN EXISTS (
        SELECT 1 FROM lealtad_canjes k2
        WHERE k2.cliente_id = c.id
          AND k2.fecha_negocio = laola_fecha_negocio(COALESCE(c.ultima_visita, c.created_at))
      ) THEN 'canje'
      WHEN GREATEST(0, floor(n.vis_anio::numeric / v_meta)::int - n.can_anio) = 0
       AND (v_meta - (n.vis_anio % v_meta)) = 1
        THEN 'cerca'
      ELSE 'normal'
    END AS estado
  ) est
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

NOTIFY pgrst, 'reload schema';


-- =====================================================================
-- BLOQUE 6 — Alicia se borra para volver a probar desde cero
--
-- Alicia Stephany García Santana (6644219153) es la encargada de
-- implementación: se registró el 25-ago para probar y hay que borrarla
-- para que vuelva a entrar por el camino nuevo y lo pruebe de verdad.
--
-- Se hace aquí y no por REST porque `lealtad_clientes` no tiene policy de
-- DELETE para `authenticated` — un DELETE por PostgREST devuelve 200 y no
-- borra nada.
--
-- Del lado de Makatea ya quedó listo (26-ago): sus 6 corridas en `exit`
-- con outcome `reinicio_prueba_implementacion` y su segmento en NULL, para
-- que al reinscribirse le vuelva a tocar la bienvenida.
--
-- Su folio 198569 se libera con la visita, así que puede volver a usar el
-- mismo ticket.
-- =====================================================================
DELETE FROM lealtad_canjes
  WHERE cliente_id IN (SELECT id FROM lealtad_clientes WHERE telefono = '6644219153');
DELETE FROM lealtad_visitas
  WHERE cliente_id IN (SELECT id FROM lealtad_clientes WHERE telefono = '6644219153');
DELETE FROM lealtad_intentos WHERE telefono = '6644219153';
DELETE FROM lealtad_clientes WHERE telefono = '6644219153';
