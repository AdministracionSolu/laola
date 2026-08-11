-- =====================================================================
-- Panel de implementación: el filtro de proveedores estaba al revés.
--
-- `proveedores.depurado` se agregó en junio (20260608010000) como marca de
-- "ya revisado" durante la limpieza de catálogos. NO significa dado de baja.
-- El panel filtraba `AND NOT p.depurado`, así que escondía justo a los cinco
-- proveedores cuyo catálogo sí se revisó —Lindo Mar entre ellos, el que más
-- captura— y solo mostraba a Capital Camaronera, el único sin revisar.
--
-- Único cambio: `WHERE p.activo AND NOT p.depurado` -> `WHERE p.activo`.
-- El resto del cuerpo va igual que en 20260806120000.
-- =====================================================================

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
      WHERE p.activo
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

REVOKE ALL ON FUNCTION public.panel_implementacion(text, date, date) FROM public;
GRANT EXECUTE ON FUNCTION public.panel_implementacion(text, date, date) TO anon, authenticated;
