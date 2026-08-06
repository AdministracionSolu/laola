-- ============================================================
-- PORTAL DE IMPLEMENTACIÓN (Alicia)
--
-- Un tablero de CUMPLIMIENTO, no de dinero: quién sube qué, qué días
-- y qué tan completo. Vive en /implementacion, entra con PIN propio
-- (config_app.pin_implementacion) y NO da acceso al admin ni a ventas.
--
-- Todo se sirve con UN solo RPC SECURITY DEFINER (panel_implementacion)
-- para no abrir RLS a anon. Los porcentajes se calculan en el front a
-- partir de la rejilla cruda que devuelve esta función.
--
-- Lo que mide:
--   1. Cortes de cierre por sucursal × día
--   2. Proveedores: qué días subieron precios y cuántos productos de
--      su catálogo (completitud), más envíos fallidos
--   3. Operación por sucursal (foco Valle): pedido sugerido, existencia
--      capturada y recepciones marcadas, con el nombre de quién reportó
--   4. Facturas por QR (foco Valle): solicitadas / timbradas por día
--   5. Mapa de responsables (quién reporta qué)
--   6. Pendientes de implementación (p. ej. horario de cajas de Valle)
--
-- Semana de negocio: lunes → domingo. Hora local Mazatlán.
-- Idempotente.
-- ============================================================


-- ============================================================
-- BLOQUE 1 — Mapa de responsables: quién reporta qué, por sucursal
-- ============================================================
CREATE TABLE IF NOT EXISTS public.impl_responsables (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  sucursal_id uuid REFERENCES public.sucursales(id) ON DELETE CASCADE,
  proceso     text NOT NULL,          -- corte | pedido | existencia | recepcion | precios | factura | horario
  persona     text NOT NULL,
  puesto      text,
  telefono    text,
  notas       text,
  activo      boolean NOT NULL DEFAULT true,
  updated_at  timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.impl_responsables ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "impl_resp_admin" ON public.impl_responsables;
CREATE POLICY "impl_resp_admin" ON public.impl_responsables
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
-- anon no toca la tabla: entra por las funciones SECURITY DEFINER.

CREATE INDEX IF NOT EXISTS impl_responsables_suc_idx
  ON public.impl_responsables (sucursal_id, proceso);


-- ============================================================
-- BLOQUE 2 — Pendientes de implementación (la libreta de Alicia)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.impl_pendientes (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  titulo        text NOT NULL,
  sucursal_id   uuid REFERENCES public.sucursales(id) ON DELETE SET NULL,
  area          text,                          -- cajas | compras | rrhh | facturación | ...
  estado        text NOT NULL DEFAULT 'pendiente',  -- pendiente | en_curso | hecho | bloqueado
  semana_objetivo date,                        -- lunes de la semana en que debe quedar
  responsable   text,
  notas         text,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.impl_pendientes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "impl_pend_admin" ON public.impl_pendientes;
CREATE POLICY "impl_pend_admin" ON public.impl_pendientes
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

CREATE INDEX IF NOT EXISTS impl_pendientes_estado_idx
  ON public.impl_pendientes (estado, semana_objetivo);


-- ============================================================
-- BLOQUE 3 — PIN propio del portal
-- (config_app ya existe desde la migración de compras)
-- ============================================================
INSERT INTO public.config_app (clave, valor) VALUES ('pin_implementacion', '2580')
ON CONFLICT (clave) DO NOTHING;

CREATE OR REPLACE FUNCTION public.impl_validar_pin(p_pin text)
RETURNS boolean
LANGUAGE sql SECURITY DEFINER SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.config_app
    WHERE clave = 'pin_implementacion' AND valor = p_pin
  );
$$;


-- ============================================================
-- BLOQUE 4 — Semilla: el pendiente que ya está sobre la mesa
-- (horario de cajas de Valle, a realizarse esta semana para la
--  siguiente). Solo se inserta si no existe uno igual.
-- ============================================================
INSERT INTO public.impl_pendientes (titulo, sucursal_id, area, estado, semana_objetivo, notas)
SELECT
  'Horario de cajas',
  s.id,
  'cajas',
  'pendiente',
  ((now() AT TIME ZONE 'America/Mazatlan')::date
     - (EXTRACT(ISODOW FROM (now() AT TIME ZONE 'America/Mazatlan')::date)::int - 1))::date,
  'Se elabora esta semana en curso para que aplique la próxima. Queda pendiente hasta que lo vuelvan a realizar.'
FROM public.sucursales s
WHERE s.nombre ILIKE '%valle%'
  AND NOT EXISTS (
    SELECT 1 FROM public.impl_pendientes p
    WHERE p.titulo = 'Horario de cajas' AND p.sucursal_id = s.id
  );


-- ============================================================
-- BLOQUE 5 — panel_implementacion(): toda la rejilla en un JSON
-- p_desde/p_hasta opcionales; por default la semana (lun→dom) de hoy.
-- ============================================================
CREATE OR REPLACE FUNCTION public.panel_implementacion(
  p_pin   text,
  p_desde date DEFAULT NULL,
  p_hasta date DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $panel$
DECLARE
  v_hoy   date := (now() AT TIME ZONE 'America/Mazatlan')::date;
  v_desde date;
  v_hasta date;
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
  IF v_hasta - v_desde > 92 THEN v_hasta := v_desde + 92; END IF;  -- techo de rango

  RETURN jsonb_build_object(
    'ok',    true,
    'hoy',   v_hoy,
    'desde', v_desde,
    'hasta', v_hasta,

    'dias', (
      SELECT jsonb_agg(d::date ORDER BY d)
      FROM generate_series(v_desde, v_hasta, interval '1 day') d
    ),

    'sucursales', (
      SELECT COALESCE(jsonb_agg(jsonb_build_object(
        'id', s.id, 'nombre', s.nombre,
        'prefijo_folio', s.prefijo_folio,
        'es_valle', s.nombre ILIKE '%valle%'
      ) ORDER BY s.nombre), '[]'::jsonb)
      FROM sucursales s
    ),

    -- ---- 1. Cortes de cierre por sucursal × día ----
    'cortes', (
      SELECT COALESCE(jsonb_agg(jsonb_build_object(
        'sucursal_id', s.id,
        'nombre',      s.nombre,
        'hora_limite', (SELECT c.hora_limite FROM cortes_alertas_config c WHERE c.sucursal_id = s.id),
        'dias', (
          SELECT jsonb_agg(jsonb_build_object(
            'fecha',    d::date,
            'cierre',   EXISTS (SELECT 1 FROM cortes_caja k
                                WHERE k.sucursal_id = s.id AND k.fecha_venta = d::date
                                  AND k.tipo_corte = 'cierre'),
            'momentos', (SELECT count(*) FROM cortes_caja k
                         WHERE k.sucursal_id = s.id AND k.fecha_venta = d::date
                           AND k.tipo_corte = 'momento'),
            'capturado_at', (SELECT max(k.created_at) FROM cortes_caja k
                             WHERE k.sucursal_id = s.id AND k.fecha_venta = d::date
                               AND k.tipo_corte = 'cierre'),
            'alertado', EXISTS (SELECT 1 FROM cortes_alertas_enviadas a
                                WHERE a.sucursal_id = s.id AND a.fecha_negocio = d::date)
          ) ORDER BY d)
          FROM generate_series(v_desde, v_hasta, interval '1 day') d
        )
      ) ORDER BY s.nombre), '[]'::jsonb)
      FROM sucursales s
    ),

    -- ---- 2. Proveedores: días con carga y completitud del catálogo ----
    'proveedores', (
      SELECT COALESCE(jsonb_agg(jsonb_build_object(
        'id',       p.id,
        'nombre',   p.nombre,
        'telefono', p.telefono,
        'categoria', p.categoria,
        'productos_activos', (SELECT count(*) FROM proveedor_productos pp
                              WHERE pp.proveedor_id = p.id AND pp.activo),
        'dias', (
          SELECT jsonb_agg(jsonb_build_object(
            'fecha', d::date,
            'productos', (
              SELECT count(DISTINCT pr.proveedor_producto_id)
              FROM proveedor_precios pr
              JOIN proveedor_productos pp ON pp.id = pr.proveedor_producto_id
              WHERE pp.proveedor_id = p.id
                AND (pr.created_at AT TIME ZONE 'America/Mazatlan')::date = d::date
            ),
            'hora', (
              SELECT min(pr.created_at)
              FROM proveedor_precios pr
              JOIN proveedor_productos pp ON pp.id = pr.proveedor_producto_id
              WHERE pp.proveedor_id = p.id
                AND (pr.created_at AT TIME ZONE 'America/Mazatlan')::date = d::date
            )
          ) ORDER BY d)
          FROM generate_series(v_desde, v_hasta, interval '1 day') d
        ),
        'intentos', (SELECT count(*) FROM proveedor_envios e
                     WHERE e.proveedor_id = p.id
                       AND (e.created_at AT TIME ZONE 'America/Mazatlan')::date BETWEEN v_desde AND v_hasta),
        'fallidos', (SELECT count(*) FROM proveedor_envios e
                     WHERE e.proveedor_id = p.id
                       AND (e.created_at AT TIME ZONE 'America/Mazatlan')::date BETWEEN v_desde AND v_hasta
                       AND COALESCE(e.resultado->>'ok', 'true') = 'false'),
        'ultimo_precio_at', (
          SELECT max(pr.created_at)
          FROM proveedor_precios pr
          JOIN proveedor_productos pp ON pp.id = pr.proveedor_producto_id
          WHERE pp.proveedor_id = p.id
        )
      ) ORDER BY p.nombre), '[]'::jsonb)
      FROM proveedores p
      WHERE p.activo AND NOT p.depurado
        AND EXISTS (SELECT 1 FROM proveedor_productos pp
                    WHERE pp.proveedor_id = p.id AND pp.activo)
    ),

    -- ---- 3. Operación por sucursal: pedido, existencia, recepciones ----
    'operacion', (
      SELECT COALESCE(jsonb_agg(jsonb_build_object(
        'sucursal_id', s.id,
        'nombre',      s.nombre,
        'dias', (
          SELECT jsonb_agg(jsonb_build_object(
            'fecha', d::date,
            'pedido', (
              SELECT jsonb_build_object(
                'estado',         pe.estado,
                'registrado_por', pe.registrado_por,
                'enviado_at',     pe.enviado_at,
                'renglones',      (SELECT count(*) FROM pedidos_detalle pd WHERE pd.pedido_id = pe.id),
                'pedidos',        (SELECT count(*) FROM pedidos_detalle pd
                                   WHERE pd.pedido_id = pe.id AND pd.cantidad_pedida > 0),
                'con_existencia', (SELECT count(*) FROM pedidos_detalle pd
                                   WHERE pd.pedido_id = pe.id AND pd.existencia IS NOT NULL),
                'con_sugerida',   (SELECT count(*) FROM pedidos_detalle pd
                                   WHERE pd.pedido_id = pe.id AND pd.cantidad_sugerida IS NOT NULL)
              )
              FROM pedidos pe
              WHERE pe.sucursal_id = s.id AND pe.fecha = d::date
              LIMIT 1
            ),
            'recepciones', (
              SELECT COALESCE(jsonb_agg(jsonb_build_object(
                'proveedor',      r.proveedor,
                'registrado_por', r.registrado_por,
                'hora',           r.created_at,
                'renglones',      (SELECT count(*) FROM recepciones_detalle rd WHERE rd.recepcion_id = r.id)
              ) ORDER BY r.created_at), '[]'::jsonb)
              FROM recepciones r
              WHERE r.sucursal_id = s.id AND r.fecha = d::date
            )
          ) ORDER BY d)
          FROM generate_series(v_desde, v_hasta, interval '1 day') d
        )
      ) ORDER BY s.nombre), '[]'::jsonb)
      FROM sucursales s
    ),

    -- ---- 4. Facturas por QR, por sucursal ----
    'facturas', (
      SELECT COALESCE(jsonb_agg(jsonb_build_object(
        'sucursal_id', s.id,
        'nombre',      s.nombre,
        'dias', (
          SELECT jsonb_agg(jsonb_build_object(
            'fecha', d::date,
            'solicitadas', (
              SELECT count(*) FROM factura_solicitudes f
              WHERE (f.sucursal_id = s.id
                     OR (f.sucursal_id IS NULL AND f.sucursal_codigo = s.prefijo_folio))
                AND (f.created_at AT TIME ZONE 'America/Mazatlan')::date = d::date
            ),
            'timbradas', (
              SELECT count(*) FROM factura_solicitudes f
              WHERE (f.sucursal_id = s.id
                     OR (f.sucursal_id IS NULL AND f.sucursal_codigo = s.prefijo_folio))
                AND (f.created_at AT TIME ZONE 'America/Mazatlan')::date = d::date
                AND f.estado = 'timbrada'
            )
          ) ORDER BY d)
          FROM generate_series(v_desde, v_hasta, interval '1 day') d
        ),
        'pendientes_totales', (
          SELECT count(*) FROM factura_solicitudes f
          WHERE (f.sucursal_id = s.id
                 OR (f.sucursal_id IS NULL AND f.sucursal_codigo = s.prefijo_folio))
            AND f.estado = 'pendiente'
        ),
        'rechazadas', (
          SELECT count(*) FROM factura_solicitudes f
          WHERE (f.sucursal_id = s.id
                 OR (f.sucursal_id IS NULL AND f.sucursal_codigo = s.prefijo_folio))
            AND f.estado = 'rechazada'
            AND (f.created_at AT TIME ZONE 'America/Mazatlan')::date BETWEEN v_desde AND v_hasta
        ),
        'historico', (
          SELECT count(*) FROM factura_solicitudes f
          WHERE (f.sucursal_id = s.id
                 OR (f.sucursal_id IS NULL AND f.sucursal_codigo = s.prefijo_folio))
        )
      ) ORDER BY s.nombre), '[]'::jsonb)
      FROM sucursales s
    ),

    'facturas_sin_sucursal', (
      SELECT count(*) FROM factura_solicitudes f
      WHERE f.sucursal_id IS NULL
        AND (f.sucursal_codigo IS NULL
             OR NOT EXISTS (SELECT 1 FROM sucursales s WHERE s.prefijo_folio = f.sucursal_codigo))
        AND (f.created_at AT TIME ZONE 'America/Mazatlan')::date BETWEEN v_desde AND v_hasta
    ),

    -- ---- 5. Mapa de responsables ----
    'responsables', (
      SELECT COALESCE(jsonb_agg(jsonb_build_object(
        'id', r.id, 'sucursal_id', r.sucursal_id,
        'sucursal', (SELECT s.nombre FROM sucursales s WHERE s.id = r.sucursal_id),
        'proceso', r.proceso, 'persona', r.persona, 'puesto', r.puesto,
        'telefono', r.telefono, 'notas', r.notas
      ) ORDER BY r.proceso, r.persona), '[]'::jsonb)
      FROM impl_responsables r
      WHERE r.activo
    ),

    -- ---- 6. Pendientes de implementación ----
    'pendientes', (
      SELECT COALESCE(jsonb_agg(jsonb_build_object(
        'id', p.id, 'titulo', p.titulo,
        'sucursal_id', p.sucursal_id,
        'sucursal', (SELECT s.nombre FROM sucursales s WHERE s.id = p.sucursal_id),
        'area', p.area, 'estado', p.estado,
        'semana_objetivo', p.semana_objetivo,
        'responsable', p.responsable, 'notas', p.notas,
        'updated_at', p.updated_at
      ) ORDER BY
          CASE p.estado WHEN 'bloqueado' THEN 0 WHEN 'pendiente' THEN 1
                        WHEN 'en_curso' THEN 2 ELSE 3 END,
          p.semana_objetivo NULLS LAST, p.titulo), '[]'::jsonb)
      FROM impl_pendientes p
    )
  );
END
$panel$;


-- ============================================================
-- BLOQUE 6 — Alicia edita sus pendientes (alta / cambio de estado / baja)
-- ============================================================
CREATE OR REPLACE FUNCTION public.impl_pendiente_guardar(
  p_pin        text,
  p_id         uuid    DEFAULT NULL,
  p_titulo     text    DEFAULT NULL,
  p_sucursal_id uuid   DEFAULT NULL,
  p_area       text    DEFAULT NULL,
  p_estado     text    DEFAULT NULL,
  p_semana     date    DEFAULT NULL,
  p_responsable text   DEFAULT NULL,
  p_notas      text    DEFAULT NULL,
  p_borrar     boolean DEFAULT false
)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_id uuid;
BEGIN
  IF NOT (
    EXISTS (SELECT 1 FROM config_app WHERE clave = 'pin_implementacion' AND valor = p_pin)
    OR has_role(auth.uid(), 'admin')
  ) THEN
    RETURN jsonb_build_object('ok', false, 'error', 'PIN_INVALIDO');
  END IF;

  IF p_borrar THEN
    IF p_id IS NULL THEN RETURN jsonb_build_object('ok', false, 'error', 'FALTA_ID'); END IF;
    DELETE FROM impl_pendientes WHERE id = p_id;
    RETURN jsonb_build_object('ok', true, 'id', p_id, 'borrado', true);
  END IF;

  IF p_estado IS NOT NULL AND p_estado NOT IN ('pendiente','en_curso','hecho','bloqueado') THEN
    RETURN jsonb_build_object('ok', false, 'error', 'ESTADO_INVALIDO');
  END IF;

  IF p_id IS NULL THEN
    IF COALESCE(trim(p_titulo), '') = '' THEN
      RETURN jsonb_build_object('ok', false, 'error', 'FALTA_TITULO');
    END IF;
    INSERT INTO impl_pendientes (titulo, sucursal_id, area, estado, semana_objetivo, responsable, notas)
    VALUES (trim(p_titulo), p_sucursal_id, p_area, COALESCE(p_estado, 'pendiente'),
            p_semana, p_responsable, p_notas)
    RETURNING id INTO v_id;
  ELSE
    UPDATE impl_pendientes SET
      titulo          = COALESCE(NULLIF(trim(p_titulo), ''), titulo),
      sucursal_id     = COALESCE(p_sucursal_id, sucursal_id),
      area            = COALESCE(p_area, area),
      estado          = COALESCE(p_estado, estado),
      semana_objetivo = COALESCE(p_semana, semana_objetivo),
      responsable     = COALESCE(p_responsable, responsable),
      notas           = COALESCE(p_notas, notas),
      updated_at      = now()
    WHERE id = p_id
    RETURNING id INTO v_id;
    IF v_id IS NULL THEN RETURN jsonb_build_object('ok', false, 'error', 'NO_EXISTE'); END IF;
  END IF;

  RETURN jsonb_build_object('ok', true, 'id', v_id);
END $$;


-- ============================================================
-- BLOQUE 7 — Alicia edita el mapa de responsables
-- ============================================================
CREATE OR REPLACE FUNCTION public.impl_responsable_guardar(
  p_pin         text,
  p_id          uuid    DEFAULT NULL,
  p_sucursal_id uuid    DEFAULT NULL,
  p_proceso     text    DEFAULT NULL,
  p_persona     text    DEFAULT NULL,
  p_puesto      text    DEFAULT NULL,
  p_telefono    text    DEFAULT NULL,
  p_notas       text    DEFAULT NULL,
  p_borrar      boolean DEFAULT false
)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_id uuid;
BEGIN
  IF NOT (
    EXISTS (SELECT 1 FROM config_app WHERE clave = 'pin_implementacion' AND valor = p_pin)
    OR has_role(auth.uid(), 'admin')
  ) THEN
    RETURN jsonb_build_object('ok', false, 'error', 'PIN_INVALIDO');
  END IF;

  IF p_borrar THEN
    IF p_id IS NULL THEN RETURN jsonb_build_object('ok', false, 'error', 'FALTA_ID'); END IF;
    UPDATE impl_responsables SET activo = false, updated_at = now() WHERE id = p_id;
    RETURN jsonb_build_object('ok', true, 'id', p_id, 'borrado', true);
  END IF;

  IF p_id IS NULL THEN
    IF COALESCE(trim(p_persona), '') = '' OR COALESCE(trim(p_proceso), '') = '' THEN
      RETURN jsonb_build_object('ok', false, 'error', 'FALTAN_DATOS');
    END IF;
    INSERT INTO impl_responsables (sucursal_id, proceso, persona, puesto, telefono, notas)
    VALUES (p_sucursal_id, trim(p_proceso), trim(p_persona), p_puesto, p_telefono, p_notas)
    RETURNING id INTO v_id;
  ELSE
    UPDATE impl_responsables SET
      sucursal_id = COALESCE(p_sucursal_id, sucursal_id),
      proceso     = COALESCE(NULLIF(trim(p_proceso), ''), proceso),
      persona     = COALESCE(NULLIF(trim(p_persona), ''), persona),
      puesto      = COALESCE(p_puesto, puesto),
      telefono    = COALESCE(p_telefono, telefono),
      notas       = COALESCE(p_notas, notas),
      updated_at  = now()
    WHERE id = p_id
    RETURNING id INTO v_id;
    IF v_id IS NULL THEN RETURN jsonb_build_object('ok', false, 'error', 'NO_EXISTE'); END IF;
  END IF;

  RETURN jsonb_build_object('ok', true, 'id', v_id);
END $$;


-- ============================================================
-- BLOQUE 8 — Permisos: solo por función, nunca por tabla
-- ============================================================
REVOKE ALL ON FUNCTION public.impl_validar_pin(text) FROM public;
REVOKE ALL ON FUNCTION public.panel_implementacion(text, date, date) FROM public;
REVOKE ALL ON FUNCTION public.impl_pendiente_guardar(text, uuid, text, uuid, text, text, date, text, text, boolean) FROM public;
REVOKE ALL ON FUNCTION public.impl_responsable_guardar(text, uuid, uuid, text, text, text, text, text, boolean) FROM public;

GRANT EXECUTE ON FUNCTION public.impl_validar_pin(text) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.panel_implementacion(text, date, date) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.impl_pendiente_guardar(text, uuid, text, uuid, text, text, date, text, text, boolean) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.impl_responsable_guardar(text, uuid, uuid, text, text, text, text, text, boolean) TO anon, authenticated;

NOTIFY pgrst, 'reload schema';
