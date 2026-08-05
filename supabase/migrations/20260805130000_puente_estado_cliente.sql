-- =====================================================================
-- El puente manda CÓMO se fue el cliente, no solo cuándo vino.
--
-- Makatea tiene tres mensajes para el día siguiente de una visita:
--   · normal  — "Nos encantó recibirte, te vemos mañana"
--   · canje   — "Esperamos que tu regalo te haya gustado"
--   · cerca   — "Solo falta una visita más para tu próximo regalo"
-- Los tres compiten por el mismo momento, así que allá cada uno vive en
-- un flujo con su propio segmento y aquí se decide cuál toca. La Ola es
-- quien sabe el estado; Makatea solo lo obedece.
--
-- Precedencia: si canjeó en esa visita gana 'canje'; si no, y le falta
-- una sola visita para la recompensa, 'cerca'; si no, 'normal'. La
-- cuenta es la misma que muestra la pantalla del cliente
-- (lealtad_perfil_json): ciclo por año natural, meta de lealtad_config.
-- =====================================================================


-- ---------------------------------------------------------------------
-- BLOQUE 1 — Push con estado
-- ---------------------------------------------------------------------
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


-- ---------------------------------------------------------------------
-- BLOQUE 2 — Un canje también mueve el estado, así que también empuja
-- (el trigger viejo solo miraba lealtad_clientes)
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.makatea_push_canje()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM makatea_push_clientes(ARRAY[NEW.cliente_id]);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_makatea_push_canje ON public.lealtad_canjes;
CREATE TRIGGER trg_makatea_push_canje
  AFTER INSERT ON public.lealtad_canjes
  FOR EACH ROW EXECUTE FUNCTION public.makatea_push_canje();

NOTIFY pgrst, 'reload schema';
