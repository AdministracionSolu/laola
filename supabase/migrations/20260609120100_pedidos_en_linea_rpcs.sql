-- ============================================================
-- PEDIDOS EN LÍNEA — Funciones RPC públicas
-- El cliente JAMÁS manda precios: todo se calcula server-side.
-- Errores con código legible que el front traduce a mensajes:
--   'CODIGO' o 'CODIGO|detalle'
-- ============================================================

-- ¿La sucursal está dentro de su horario en su zona horaria local?
CREATE OR REPLACE FUNCTION public.sucursal_en_horario(p_sucursal_id uuid)
RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_tz text;
  v_local timestamp;
  v_dia int;
  v_hora time;
BEGIN
  SELECT COALESCE(zona_horaria, 'America/Mexico_City') INTO v_tz
  FROM sucursales WHERE id = p_sucursal_id;
  IF NOT FOUND THEN
    RETURN false;
  END IF;
  v_local := now() AT TIME ZONE v_tz;
  v_dia := EXTRACT(dow FROM v_local)::int;
  v_hora := v_local::time;
  RETURN EXISTS (
    SELECT 1 FROM horarios_sucursal h
    WHERE h.sucursal_id = p_sucursal_id
      AND h.activo
      AND h.dia_semana = v_dia
      AND (
        (h.hora_apertura <= h.hora_cierre AND v_hora >= h.hora_apertura AND v_hora < h.hora_cierre)
        OR
        -- rango que cruza medianoche (ej. 18:00–01:00)
        (h.hora_apertura > h.hora_cierre AND (v_hora >= h.hora_apertura OR v_hora < h.hora_cierre))
      )
  );
END;
$$;

-- Crea un pedido validando TODO server-side. p_items:
--   [{"variante_id":"uuid","cantidad":2,"opciones":{"preparacion":"Picante"},"notas":"sin cebolla"}]
CREATE OR REPLACE FUNCTION public.crear_pedido_en_linea(
  p_sucursal_id uuid,
  p_tipo text,
  p_nombre_cliente text,
  p_telefono text,
  p_items jsonb,
  p_zona_id uuid DEFAULT NULL,
  p_direccion text DEFAULT NULL,
  p_referencias text DEFAULT NULL,
  p_notas_generales text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_sucursal sucursales%ROWTYPE;
  v_telefono text;
  v_item jsonb;
  v_variante_id uuid;
  v_cantidad int;
  v_precio numeric(10,2);
  v_disponible boolean;
  v_nombre_item text;
  v_nombre_variante text;
  v_es_alcohol boolean;
  v_categoria_activa boolean;
  v_subtotal numeric(10,2) := 0;
  v_costo_envio numeric(10,2) := 0;
  v_zona zonas_reparto%ROWTYPE;
  v_fecha_local date;
  v_consecutivo int;
  v_folio text;
  v_pedido_id uuid;
  v_token uuid;
  v_num_items int := 0;
BEGIN
  -- Sucursal: existe, activa, sin pausa, en horario
  SELECT * INTO v_sucursal FROM sucursales WHERE id = p_sucursal_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'SUCURSAL_NO_ENCONTRADA';
  END IF;
  IF NOT v_sucursal.pedidos_en_linea_activos THEN
    RAISE EXCEPTION 'PEDIDOS_DESACTIVADOS';
  END IF;
  IF v_sucursal.pedidos_pausados_hasta IS NOT NULL AND v_sucursal.pedidos_pausados_hasta > now() THEN
    RAISE EXCEPTION 'SUCURSAL_PAUSADA|%', to_char(v_sucursal.pedidos_pausados_hasta AT TIME ZONE COALESCE(v_sucursal.zona_horaria,'America/Mexico_City'), 'HH24:MI');
  END IF;
  IF NOT sucursal_en_horario(p_sucursal_id) THEN
    RAISE EXCEPTION 'FUERA_DE_HORARIO';
  END IF;

  -- Tipo y datos del cliente
  IF p_tipo NOT IN ('recoger','reparto') THEN
    RAISE EXCEPTION 'TIPO_INVALIDO';
  END IF;
  IF p_nombre_cliente IS NULL OR length(trim(p_nombre_cliente)) < 2 THEN
    RAISE EXCEPTION 'NOMBRE_REQUERIDO';
  END IF;
  -- Normaliza teléfono: quita todo lo que no sea dígito y el prefijo +52
  v_telefono := regexp_replace(COALESCE(p_telefono, ''), '[^0-9]', '', 'g');
  IF length(v_telefono) = 12 AND v_telefono LIKE '52%' THEN
    v_telefono := substr(v_telefono, 3);
  ELSIF length(v_telefono) = 13 AND v_telefono LIKE '521%' THEN
    v_telefono := substr(v_telefono, 4);
  END IF;
  IF v_telefono !~ '^[0-9]{10}$' THEN
    RAISE EXCEPTION 'TELEFONO_INVALIDO';
  END IF;

  -- Anti-spam: máximo 3 pedidos por teléfono por hora
  IF (SELECT count(*) FROM pedidos_en_linea
      WHERE telefono = v_telefono AND created_at > now() - interval '1 hour') >= 3 THEN
    RAISE EXCEPTION 'LIMITE_PEDIDOS';
  END IF;

  -- Reparto: zona válida de la sucursal
  IF p_tipo = 'reparto' THEN
    IF p_zona_id IS NULL THEN
      RAISE EXCEPTION 'ZONA_INVALIDA';
    END IF;
    SELECT * INTO v_zona FROM zonas_reparto
    WHERE id = p_zona_id AND sucursal_id = p_sucursal_id AND activa = true;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'ZONA_INVALIDA';
    END IF;
    IF p_direccion IS NULL OR length(trim(p_direccion)) < 5 THEN
      RAISE EXCEPTION 'DIRECCION_REQUERIDA';
    END IF;
    v_costo_envio := v_zona.costo_envio;
  END IF;

  -- Items: existen, disponibles, pertenecen a la sucursal; precios SIEMPRE de DB
  IF p_items IS NULL OR jsonb_typeof(p_items) <> 'array' OR jsonb_array_length(p_items) = 0 THEN
    RAISE EXCEPTION 'CARRITO_VACIO';
  END IF;
  IF jsonb_array_length(p_items) > 50 THEN
    RAISE EXCEPTION 'CARRITO_DEMASIADO_GRANDE';
  END IF;

  FOR v_item IN SELECT * FROM jsonb_array_elements(p_items) LOOP
    v_variante_id := (v_item->>'variante_id')::uuid;
    v_cantidad := COALESCE((v_item->>'cantidad')::int, 0);
    IF v_cantidad < 1 OR v_cantidad > 99 THEN
      RAISE EXCEPTION 'CANTIDAD_INVALIDA';
    END IF;

    v_nombre_item := NULL; -- que el error no arrastre el nombre del item anterior
    SELECT mvs.precio, mvs.disponible, mi.nombre, mv.nombre, mi.es_alcohol, mc.activa
      INTO v_precio, v_disponible, v_nombre_item, v_nombre_variante, v_es_alcohol, v_categoria_activa
    FROM menu_variantes mv
    JOIN menu_items mi ON mi.id = mv.item_id
    JOIN menu_categorias mc ON mc.id = mi.categoria_id
    JOIN menu_variante_sucursal mvs ON mvs.variante_id = mv.id AND mvs.sucursal_id = p_sucursal_id
    WHERE mv.id = v_variante_id;

    IF NOT FOUND OR NOT v_categoria_activa THEN
      RAISE EXCEPTION 'ITEM_NO_DISPONIBLE|%', COALESCE(v_nombre_item, 'Producto');
    END IF;
    IF NOT v_disponible THEN
      RAISE EXCEPTION 'ITEM_NO_DISPONIBLE|%', v_nombre_item || ' (' || v_nombre_variante || ')';
    END IF;
    IF v_es_alcohol AND NOT v_sucursal.venta_alcohol_en_linea THEN
      RAISE EXCEPTION 'ALCOHOL_NO_DISPONIBLE|%', v_nombre_item;
    END IF;

    v_subtotal := v_subtotal + (v_precio * v_cantidad);
    v_num_items := v_num_items + 1;
  END LOOP;

  -- Pedido mínimo de la zona (sobre el subtotal, sin envío)
  IF p_tipo = 'reparto' AND v_subtotal < v_zona.pedido_minimo THEN
    RAISE EXCEPTION 'PEDIDO_MINIMO|%', v_zona.pedido_minimo::text;
  END IF;

  -- Folio secuencial diario por sucursal, atómico (la fecha es local a la sucursal)
  v_fecha_local := (now() AT TIME ZONE COALESCE(v_sucursal.zona_horaria,'America/Mexico_City'))::date;
  INSERT INTO folios_secuencia (sucursal_id, fecha, ultimo)
  VALUES (p_sucursal_id, v_fecha_local, 1)
  ON CONFLICT (sucursal_id, fecha)
  DO UPDATE SET ultimo = folios_secuencia.ultimo + 1
  RETURNING ultimo INTO v_consecutivo;
  v_folio := COALESCE(v_sucursal.prefijo_folio, 'PED') || '-' || lpad(v_consecutivo::text, 3, '0');

  -- Inserta pedido + items (misma transacción de la función)
  INSERT INTO pedidos_en_linea (
    folio, sucursal_id, tipo, estado, nombre_cliente, telefono,
    zona_id, direccion, referencias,
    subtotal, costo_envio, total, notas_generales
  ) VALUES (
    v_folio, p_sucursal_id, p_tipo, 'nuevo', trim(p_nombre_cliente), v_telefono,
    CASE WHEN p_tipo = 'reparto' THEN p_zona_id ELSE NULL END,
    CASE WHEN p_tipo = 'reparto' THEN trim(p_direccion) ELSE NULL END,
    NULLIF(trim(COALESCE(p_referencias,'')), ''),
    v_subtotal, v_costo_envio, v_subtotal + v_costo_envio,
    NULLIF(trim(COALESCE(p_notas_generales,'')), '')
  )
  RETURNING id, token INTO v_pedido_id, v_token;

  FOR v_item IN SELECT * FROM jsonb_array_elements(p_items) LOOP
    v_variante_id := (v_item->>'variante_id')::uuid;
    v_cantidad := (v_item->>'cantidad')::int;
    SELECT mvs.precio, mi.nombre, mv.nombre
      INTO v_precio, v_nombre_item, v_nombre_variante
    FROM menu_variantes mv
    JOIN menu_items mi ON mi.id = mv.item_id
    JOIN menu_variante_sucursal mvs ON mvs.variante_id = mv.id AND mvs.sucursal_id = p_sucursal_id
    WHERE mv.id = v_variante_id;

    INSERT INTO pedidos_en_linea_items (
      pedido_id, variante_id, nombre_item, nombre_variante,
      precio_unitario, cantidad, opciones_elegidas, notas
    ) VALUES (
      v_pedido_id, v_variante_id, v_nombre_item, v_nombre_variante,
      v_precio, v_cantidad,
      CASE WHEN jsonb_typeof(v_item->'opciones') = 'object' THEN v_item->'opciones' ELSE NULL END,
      NULLIF(trim(COALESCE(v_item->>'notas','')), '')
    );
  END LOOP;

  RETURN jsonb_build_object(
    'token', v_token,
    'folio', v_folio,
    'tiempo_estimado_min', v_sucursal.tiempo_estimado_min
  );
END;
$$;

-- Lo ÚNICO que el público puede leer de pedidos: su propio pedido, por token.
CREATE OR REPLACE FUNCTION public.obtener_pedido_por_token(p_token uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_resultado jsonb;
BEGIN
  SELECT jsonb_build_object(
    'folio', p.folio,
    'estado', p.estado,
    'tipo', p.tipo,
    'nombre_cliente', p.nombre_cliente,
    'direccion', p.direccion,
    'referencias', p.referencias,
    'subtotal', p.subtotal,
    'costo_envio', p.costo_envio,
    'total', p.total,
    'notas_generales', p.notas_generales,
    'motivo_cancelacion', p.motivo_cancelacion,
    'created_at', p.created_at,
    'confirmado_at', p.confirmado_at,
    'listo_at', p.listo_at,
    'entregado_at', p.entregado_at,
    'zona', z.nombre,
    'sucursal', jsonb_build_object(
      'nombre', s.nombre,
      'direccion', s.direccion,
      'telefono', s.telefono_contacto,
      'tiempo_estimado_min', s.tiempo_estimado_min
    ),
    'items', (
      SELECT COALESCE(jsonb_agg(jsonb_build_object(
        'nombre_item', i.nombre_item,
        'nombre_variante', i.nombre_variante,
        'precio_unitario', i.precio_unitario,
        'cantidad', i.cantidad,
        'opciones_elegidas', i.opciones_elegidas,
        'notas', i.notas
      ) ORDER BY i.created_at), '[]'::jsonb)
      FROM pedidos_en_linea_items i
      WHERE i.pedido_id = p.id
    )
  )
  INTO v_resultado
  FROM pedidos_en_linea p
  JOIN sucursales s ON s.id = p.sucursal_id
  LEFT JOIN zonas_reparto z ON z.id = p.zona_id
  WHERE p.token = p_token;

  RETURN v_resultado; -- NULL si el token no existe
END;
$$;

GRANT EXECUTE ON FUNCTION public.sucursal_en_horario(uuid) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.crear_pedido_en_linea(uuid, text, text, text, jsonb, uuid, text, text, text) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.obtener_pedido_por_token(uuid) TO anon, authenticated;
