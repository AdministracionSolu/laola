-- ============================================================
-- LEALTAD v5 — LOS NIVELES SON EL CICLO (y el panel para Alicia)
--
-- Antes los niveles eran de por vida (Nuevo/Frecuente/Oro/Platino) y no
-- coincidían con nada de lo que ve el cliente ni el mesero. Ahora el
-- nivel ES la parada del ciclo, con el mismo nombre y el mismo color que
-- se imprime y se dice en voz alta:
--
--   Recompensa inicial  (una vez de por vida, sin color de ciclo)
--   Visita 3   naranja   Michelada o limonada
--   Visita 6   azul      Postre de la casa o taco gobernador
--   Visita 9   blanco    Cubeta nacional (media) o paté de camarón mediano
--   Visita 12  verde     Tostada La Ola   → y vuelve a arrancar
--
-- El nivel de un cliente es la parada HACIA LA QUE VA, no cuántas veces
-- ha venido en su vida: en la segunda vuelta la visita 15 vuelve a ser
-- "Visita 3" y vuelve a ser naranja. Quien todavía no canjea su
-- Recompensa inicial se queda en ese nivel.
--
-- Bloque 3: panel_implementacion_lealtad() — el programa completo servido
-- al portal de Alicia (/implementacion) con su PIN, de solo lectura.
--
-- Idempotente.
-- ============================================================


-- ============================================================
-- BLOQUE 1 — Los niveles pasan a ser las paradas del ciclo
-- ============================================================
ALTER TABLE public.lealtad_niveles
  ADD COLUMN IF NOT EXISTS posicion int;

COMMENT ON COLUMN public.lealtad_niveles.posicion IS
  '0 = Recompensa inicial (una vez de por vida). 1..N = parada del ciclo, empata con lealtad_recompensas.posicion.';

CREATE UNIQUE INDEX IF NOT EXISTS lealtad_niveles_posicion_key
  ON public.lealtad_niveles (posicion);

-- Los niveles viejos de por vida ya no significan nada: se van.
DELETE FROM public.lealtad_niveles WHERE posicion IS NULL;

-- min_visitas queda como referencia legible (visitas DENTRO del ciclo).
-- El beneficio de las paradas vive en lealtad_recompensas para no tener
-- dos textos que se contradigan; aquí solo va el de la inicial.
INSERT INTO public.lealtad_niveles (nombre, posicion, min_visitas, beneficio, color, orden, activo) VALUES
  ('Recompensa inicial', 0,  0, 'Un balazo de tu elección + cerveza o refresco (una sola vez, sin callo de hacha ni cerveza premium)', '#94a3b8', 1, true),
  ('Visita 3',           1,  3, NULL, '#f97316', 2, true),
  ('Visita 6',           2,  6, NULL, '#2563eb', 3, true),
  ('Visita 9',           3,  9, NULL, '#ffffff', 4, true),
  ('Visita 12',          4, 12, NULL, '#059669', 5, true)
ON CONFLICT (posicion) DO NOTHING;


-- ============================================================
-- BLOQUE 2 — Perfil v5: el nivel sale del ciclo, no del acumulado
-- ============================================================
CREATE OR REPLACE FUNCTION public.lealtad_perfil_json(p_cliente public.lealtad_clientes)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SET search_path = public
AS $$
DECLARE
  v_meta     int;
  v_anio     int := EXTRACT(YEAR FROM laola_fecha_negocio(now()))::int;
  v_vis_anio int;
  v_can_anio int;
  v_gan      int;
  v_disp     int;
  v_prog     int;
  -- Escalares, no un record: si el catálogo se quedara sin recompensas
  -- activas un record sin asignar reventaría al leerlo.
  v_rec_pos  int;
  v_rec_tit  text;
  v_niv      record;
  v_n_recs   int;
  v_pos_niv  int;
BEGIN
  SELECT GREATEST(1, COALESCE(meta_visitas, 3)) INTO v_meta FROM lealtad_config WHERE id = 1;
  v_meta := COALESCE(v_meta, 3);

  -- Ciclo del AÑO en curso
  SELECT count(*) INTO v_vis_anio FROM lealtad_visitas
  WHERE cliente_id = p_cliente.id AND EXTRACT(YEAR FROM fecha_negocio)::int = v_anio;

  SELECT count(*) INTO v_can_anio FROM lealtad_canjes
  WHERE cliente_id = p_cliente.id AND posicion > 0
    AND EXTRACT(YEAR FROM fecha_negocio)::int = v_anio;

  v_gan  := floor(v_vis_anio::numeric / v_meta)::int;
  v_disp := GREATEST(0, v_gan - v_can_anio);
  v_prog := v_vis_anio % v_meta;

  -- Recompensa que toca: posición (canjes del año % total activas) + 1,
  -- mapeada sobre el catálogo activo ordenado (aguanta huecos).
  SELECT count(*) INTO v_n_recs FROM lealtad_recompensas WHERE activo;
  IF v_n_recs > 0 THEN
    SELECT posicion, titulo INTO v_rec_pos, v_rec_tit
    FROM (
      SELECT posicion, titulo, row_number() OVER (ORDER BY posicion) AS rn
      FROM lealtad_recompensas WHERE activo
    ) t
    WHERE t.rn = (v_can_anio % v_n_recs) + 1;
  END IF;

  -- Nivel = la parada del ciclo hacia la que va. Quien no ha canjeado su
  -- Recompensa inicial se queda en la parada 0.
  v_pos_niv := CASE WHEN p_cliente.bienvenida_canjeada_at IS NULL THEN 0 ELSE v_rec_pos END;
  SELECT nombre, beneficio, color, posicion INTO v_niv
  FROM lealtad_niveles WHERE activo AND posicion = v_pos_niv;

  RETURN jsonb_build_object(
    'nombre', p_cliente.nombre,
    'primer_nombre', COALESCE(p_cliente.primer_nombre, split_part(p_cliente.nombre, ' ', 1)),
    'telefono', p_cliente.telefono,
    'visitas_total', p_cliente.visitas_total,
    'nivel', COALESCE(v_niv.nombre, 'Recompensa inicial'),
    'nivel_posicion', COALESCE(v_niv.posicion, v_pos_niv),
    'nivel_beneficio', COALESCE(v_niv.beneficio, v_rec_tit),
    'nivel_color', COALESCE(v_niv.color, '#94a3b8'),
    -- El escalón siguiente ya lo dice la tarjeta de sellos ("Vas por: X,
    -- te faltan N visitas"). Repetirlo aquí confundía: se apaga.
    'siguiente_nivel', NULL,
    'faltan_siguiente_nivel', NULL,
    'anio', v_anio,
    'visitas_anio', v_vis_anio,
    'meta_visitas', v_meta,
    'sellos', v_prog,
    'faltan_recompensa', CASE WHEN v_disp > 0 THEN 0 ELSE v_meta - v_prog END,
    'recompensas_disponibles', v_disp,
    'recompensa_posicion', v_rec_pos,
    'recompensa_titulo', v_rec_tit,
    'bienvenida_disponible', (p_cliente.bienvenida_canjeada_at IS NULL)
  );
END;
$$;


-- ============================================================
-- BLOQUE 3 — El programa de lealtad completo, para el portal de Alicia
--
-- Mismo molde que panel_implementacion: un solo RPC SECURITY DEFINER,
-- PIN propio, nada de abrir RLS a anon. Es de SOLO LECTURA: canjear,
-- editar reglas y dar de baja siguen viviendo en /admin/lealtad.
--
-- Los teléfonos van completos. Se enmascaraban por default; Diego lo quitó
-- el 10-ago-2026 porque quien opera el panel necesita poder marcarle al
-- cliente. El PIN es lo único que separa este padrón de la calle.
-- ============================================================
CREATE OR REPLACE FUNCTION public.panel_implementacion_lealtad(
  p_pin   text,
  p_desde date DEFAULT NULL,
  p_hasta date DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $lealtad$
DECLARE
  v_hoy    date := (now() AT TIME ZONE 'America/Mazatlan')::date;
  v_desde  date;
  v_hasta  date;
  v_anio   int;
  v_meta   int;
  v_tope   int;
  v_n_recs int;
  v_pend   int;
  v_clientes jsonb;
BEGIN
  IF NOT (
    EXISTS (SELECT 1 FROM config_app WHERE clave = 'pin_implementacion' AND valor = p_pin)
    OR has_role(auth.uid(), 'admin')
  ) THEN
    RETURN jsonb_build_object('ok', false, 'error', 'PIN_INVALIDO');
  END IF;

  v_desde := COALESCE(p_desde, (v_hoy - (EXTRACT(ISODOW FROM v_hoy)::int - 1))::date);
  v_hasta := COALESCE(p_hasta, v_desde + 6);
  IF v_hasta < v_desde THEN v_hasta := v_desde; END IF;
  IF v_hasta - v_desde > 92 THEN v_hasta := v_desde + 92; END IF;

  v_anio := EXTRACT(YEAR FROM v_hasta)::int;
  SELECT GREATEST(1, COALESCE(meta_visitas, 3)), GREATEST(1, COALESCE(tope_visitas_dia, 1))
    INTO v_meta, v_tope FROM lealtad_config WHERE id = 1;
  v_meta := COALESCE(v_meta, 3);
  v_tope := COALESCE(v_tope, 1);
  SELECT count(*) INTO v_n_recs FROM lealtad_recompensas WHERE activo;

  -- Recompensas ganadas y no canjeadas en todo el padrón (el pasivo vivo)
  WITH v AS (
    SELECT cliente_id, count(*) AS n FROM lealtad_visitas
    WHERE EXTRACT(YEAR FROM fecha_negocio)::int = v_anio GROUP BY 1
  ), c AS (
    SELECT cliente_id, count(*) AS n FROM lealtad_canjes
    WHERE posicion > 0 AND EXTRACT(YEAR FROM fecha_negocio)::int = v_anio GROUP BY 1
  )
  SELECT COALESCE(sum(GREATEST(0, floor(v.n::numeric / v_meta)::int - COALESCE(c.n, 0))), 0)
    INTO v_pend
  FROM v LEFT JOIN c ON c.cliente_id = v.cliente_id;

  -- Padrón con su posición en el ciclo (los 150 más activos del año)
  WITH v AS (
    SELECT cliente_id, count(*) AS n FROM lealtad_visitas
    WHERE EXTRACT(YEAR FROM fecha_negocio)::int = v_anio GROUP BY 1
  ), c AS (
    SELECT cliente_id, count(*) AS n FROM lealtad_canjes
    WHERE posicion > 0 AND EXTRACT(YEAR FROM fecha_negocio)::int = v_anio GROUP BY 1
  )
  SELECT COALESCE(jsonb_agg(x ORDER BY x.visitas_anio DESC, x.visitas_total DESC), '[]'::jsonb)
    INTO v_clientes
  FROM (
    SELECT
      cl.nombre,
      -- Teléfono completo por decisión de Diego (10-ago-2026): quien opera el
      -- panel necesita poder llamarle al cliente, no solo casar un caso.
      cl.telefono                                             AS telefono,
      COALESCE(s.nombre, cl.sucursal_captacion_codigo, 'Sin sucursal') AS sucursal,
      cl.activo,
      cl.visitas_total,
      COALESCE(v.n, 0)                                        AS visitas_anio,
      COALESCE(c.n, 0)                                        AS canjes_anio,
      (cl.bienvenida_canjeada_at IS NULL)                     AS bienvenida_pendiente,
      GREATEST(0, floor(COALESCE(v.n, 0)::numeric / v_meta)::int - COALESCE(c.n, 0)) AS disponibles,
      CASE WHEN cl.bienvenida_canjeada_at IS NULL THEN 0
           WHEN v_n_recs = 0 THEN NULL
           ELSE (COALESCE(c.n, 0) % v_n_recs) + 1 END          AS nivel_posicion,
      COALESCE(v.n, 0) % v_meta                                AS sellos,
      to_char(cl.ultima_visita AT TIME ZONE 'America/Mazatlan', 'YYYY-MM-DD') AS ultima_visita
    FROM lealtad_clientes cl
    LEFT JOIN sucursales s ON s.id = cl.sucursal_captacion_id
    LEFT JOIN v ON v.cliente_id = cl.id
    LEFT JOIN c ON c.cliente_id = cl.id
    ORDER BY COALESCE(v.n, 0) DESC, cl.visitas_total DESC
    LIMIT 150
  ) x;

  RETURN jsonb_build_object(
    'ok',    true,
    'hoy',   v_hoy,
    'desde', v_desde,
    'hasta', v_hasta,
    'anio',  v_anio,

    'reglas', jsonb_build_object(
      'meta_visitas',    v_meta,
      'tope_visitas_dia', v_tope,
      'recompensas_ciclo', v_n_recs
    ),

    -- Niveles con su color: es la tabla que Alicia usa para enseñarle al
    -- piso qué color corresponde a qué beneficio.
    'niveles', (
      SELECT COALESCE(jsonb_agg(jsonb_build_object(
        'posicion',  n.posicion,
        'nombre',    n.nombre,
        'color',     n.color,
        'beneficio', COALESCE(n.beneficio, r.titulo),
        'activo',    n.activo
      ) ORDER BY n.posicion), '[]'::jsonb)
      FROM lealtad_niveles n
      LEFT JOIN lealtad_recompensas r ON r.posicion = n.posicion AND n.posicion > 0
      WHERE n.activo
    ),

    'ciclo', (
      SELECT COALESCE(jsonb_agg(jsonb_build_object(
        'posicion', r.posicion, 'titulo', r.titulo, 'activo', r.activo
      ) ORDER BY r.posicion), '[]'::jsonb)
      FROM lealtad_recompensas r
    ),

    'resumen', jsonb_build_object(
      'clientes',       (SELECT count(*) FROM lealtad_clientes WHERE activo),
      'bajas',          (SELECT count(*) FROM lealtad_clientes WHERE NOT activo),
      'altas_periodo',  (SELECT count(*) FROM lealtad_clientes
                         WHERE (created_at AT TIME ZONE 'America/Mazatlan')::date BETWEEN v_desde AND v_hasta),
      'altas_hoy',      (SELECT count(*) FROM lealtad_clientes
                         WHERE (created_at AT TIME ZONE 'America/Mazatlan')::date = v_hoy),
      'con_cumple',     (SELECT count(*) FROM lealtad_clientes WHERE activo AND cumpleanos IS NOT NULL),
      'visitas_periodo',(SELECT count(*) FROM lealtad_visitas WHERE fecha_negocio BETWEEN v_desde AND v_hasta),
      'visitas_anio',   (SELECT count(*) FROM lealtad_visitas WHERE EXTRACT(YEAR FROM fecha_negocio)::int = v_anio),
      'canjes_periodo', (SELECT count(*) FROM lealtad_canjes WHERE fecha_negocio BETWEEN v_desde AND v_hasta),
      'recompensas_pendientes', v_pend,
      'bienvenidas_pendientes', (SELECT count(*) FROM lealtad_clientes
                                 WHERE activo AND bienvenida_canjeada_at IS NULL)
    ),

    -- ---- Rejilla día × sucursal, con la misma forma que el resto del panel ----
    'sucursales', (
      SELECT COALESCE(jsonb_agg(jsonb_build_object(
        'sucursal_id', s.id,
        'nombre',      s.nombre,
        'clientes',    (SELECT count(*) FROM lealtad_clientes cl WHERE cl.sucursal_captacion_id = s.id),
        'dias', (
          SELECT jsonb_agg(jsonb_build_object(
            'fecha',   d::date,
            'altas',   (SELECT count(*) FROM lealtad_clientes cl
                        WHERE cl.sucursal_captacion_id = s.id
                          AND (cl.created_at AT TIME ZONE 'America/Mazatlan')::date = d::date),
            'visitas', (SELECT count(*) FROM lealtad_visitas lv
                        WHERE lv.sucursal_id = s.id AND lv.fecha_negocio = d::date),
            'canjes',  (SELECT count(*) FROM lealtad_canjes lc
                        WHERE lc.sucursal_id = s.id AND lc.fecha_negocio = d::date)
          ) ORDER BY d)
          FROM generate_series(v_desde, v_hasta, interval '1 day') d
        )
      ) ORDER BY s.nombre), '[]'::jsonb)
      FROM sucursales s
    ),

    'dias', (
      SELECT jsonb_agg(d::date ORDER BY d)
      FROM generate_series(v_desde, v_hasta, interval '1 day') d
    ),

    -- ---- Conciliación: qué se canjeó, por sucursal y beneficio ----
    'canjes', (
      SELECT COALESCE(jsonb_agg(jsonb_build_object(
        'sucursal', t.sucursal, 'posicion', t.posicion, 'titulo', t.titulo, 'n', t.n
      ) ORDER BY t.sucursal, t.posicion), '[]'::jsonb)
      FROM (
        SELECT COALESCE(s.nombre, 'Sin sucursal') AS sucursal,
               lc.posicion, lc.titulo, count(*) AS n
        FROM lealtad_canjes lc
        LEFT JOIN sucursales s ON s.id = lc.sucursal_id
        WHERE lc.fecha_negocio BETWEEN v_desde AND v_hasta
        GROUP BY 1, 2, 3
      ) t
    ),

    -- ---- Actividad reciente: las últimas visitas registradas ----
    'actividad', (
      SELECT COALESCE(jsonb_agg(jsonb_build_object(
        'cliente',  t.cliente,
        'telefono', t.telefono,
        'sucursal', t.sucursal,
        'folio',    t.folio,
        'fecha',    t.fecha,
        'hora',     t.hora
      ) ORDER BY t.creado DESC), '[]'::jsonb)
      FROM (
        SELECT cl.nombre AS cliente,
               cl.telefono AS telefono,
               COALESCE(s.nombre, 'Sin sucursal') AS sucursal,
               lv.folio,
               lv.fecha_negocio AS fecha,
               to_char(lv.created_at AT TIME ZONE 'America/Mazatlan', 'HH24:MI') AS hora,
               lv.created_at AS creado
        FROM lealtad_visitas lv
        JOIN lealtad_clientes cl ON cl.id = lv.cliente_id
        LEFT JOIN sucursales s ON s.id = lv.sucursal_id
        WHERE lv.fecha_negocio BETWEEN v_desde AND v_hasta
        ORDER BY lv.created_at DESC
        LIMIT 80
      ) t
    ),

    -- ---- Anomalías del periodo (las mismas señales que ve el admin) ----
    'anomalias', jsonb_build_object(
      'tope_repetido', (
        SELECT COALESCE(jsonb_agg(jsonb_build_object(
          'cliente', t.cliente, 'telefono', t.telefono, 'n', t.n
        ) ORDER BY t.n DESC), '[]'::jsonb)
        FROM (
          SELECT COALESCE(cl.nombre, 'Sin registro') AS cliente,
                 li.telefono AS telefono,
                 count(*) AS n
          FROM lealtad_intentos li
          LEFT JOIN lealtad_clientes cl ON cl.telefono = li.telefono
          WHERE li.motivo = 'ya_hoy' AND li.fecha_negocio BETWEEN v_desde AND v_hasta
          GROUP BY 1, 2
          HAVING count(*) >= 3
        ) t
      ),
      'multi_sucursal', (
        SELECT COALESCE(jsonb_agg(jsonb_build_object(
          'cliente', t.cliente, 'fecha', t.fecha, 'sucursales', t.sucursales
        ) ORDER BY t.fecha DESC), '[]'::jsonb)
        FROM (
          SELECT cl.nombre AS cliente, lv.fecha_negocio AS fecha,
                 string_agg(DISTINCT COALESCE(s.nombre, '—'), ', ') AS sucursales
          FROM lealtad_visitas lv
          JOIN lealtad_clientes cl ON cl.id = lv.cliente_id
          LEFT JOIN sucursales s ON s.id = lv.sucursal_id
          WHERE lv.sucursal_id IS NOT NULL AND lv.fecha_negocio BETWEEN v_desde AND v_hasta
          -- Por cliente_id, no por nombre: dos tocayos en dos sucursales
          -- distintas no son una anomalía.
          GROUP BY cl.id, cl.nombre, lv.fecha_negocio
          HAVING count(DISTINCT lv.sucursal_id) > 1
        ) t
      ),
      'folios', (
        SELECT COALESCE(jsonb_agg(jsonb_build_object(
          'telefono', t.telefono, 'folio', t.folio, 'motivo', t.motivo,
          'sucursal', t.sucursal, 'fecha', t.fecha
        ) ORDER BY t.fecha DESC), '[]'::jsonb)
        FROM (
          SELECT li.telefono AS telefono,
                 li.folio_norm AS folio, li.motivo,
                 COALESCE(s.nombre, 'Sin sucursal') AS sucursal,
                 li.fecha_negocio AS fecha
          FROM lealtad_intentos li
          LEFT JOIN sucursales s ON s.id = li.sucursal_id
          WHERE li.motivo <> 'ya_hoy' AND li.fecha_negocio BETWEEN v_desde AND v_hasta
          ORDER BY li.created_at DESC
          LIMIT 60
        ) t
      )
    ),

    'clientes', v_clientes
  );
END $lealtad$;


-- ============================================================
-- BLOQUE 4 — Permisos: solo por función, nunca por tabla
-- ============================================================
REVOKE ALL ON FUNCTION public.panel_implementacion_lealtad(text, date, date) FROM public;
GRANT EXECUTE ON FUNCTION public.panel_implementacion_lealtad(text, date, date) TO anon, authenticated;

NOTIFY pgrst, 'reload schema';
