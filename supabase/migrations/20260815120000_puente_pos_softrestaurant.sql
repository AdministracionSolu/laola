-- =====================================================================
-- PUENTE POS SOFT RESTAURANT → PANEL LA OLA (15-ago-2026)
-- Un agente en la máquina de cada sucursal lee el SQL Server del POS
-- (cheques, cheqdet, turnos, productos) y llama al RPC pos_ingest cada
-- 15 minutos con la ventana de los últimos días (upsert idempotente).
-- El agente vive en scripts/pos-agente/ de este repo.
-- REGLAS heredadas del volcado MACRODATA:
--   * los ids se repiten entre sucursales → todo lleva `origen` en la llave
--   * venta = cheques.total con cancelado=0 (nunca sumar renglones)
--   * cheqdet.precio trae IVA; cheques.subtotal no
--   * cheqdet.descuento es PORCENTAJE, no importe
--   * turnos.efectivo va NETO de retiros de caja
--   * día de negocio rueda a las 4 AM (igual que fecha_venta en cortes_caja)
-- =====================================================================

-- BLOQUE 1: llaves de ingesta (una por sucursal; nadie las lee por API)
CREATE TABLE IF NOT EXISTS pos_ingest_keys (
  origen text PRIMARY KEY,
  secret text NOT NULL,
  zona_horaria text NOT NULL DEFAULT 'America/Mazatlan',
  sucursal_id uuid REFERENCES sucursales(id),
  activo boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE pos_ingest_keys ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON pos_ingest_keys FROM anon, authenticated;

INSERT INTO pos_ingest_keys (origen, secret, zona_horaria, sucursal_id) VALUES
  ('cerveceria', 'a5fa9d2ad6970e06e3f86319ddf359a655cf53ab248d6c13', 'America/Mazatlan',    (SELECT id FROM sucursales WHERE nombre = 'Cervecería')),
  ('valle',      'e7a9b9135ceee53e809b04fff24969e148ff34d552ba1183', 'America/Mazatlan',    (SELECT id FROM sucursales WHERE nombre = 'Del Valle')),
  ('brisas',     'd2dab4014e6f3a54268d67d589aa3c0791721e4ea5e68659', 'America/Mazatlan',    (SELECT id FROM sucursales WHERE nombre = 'Las Brisas')),
  ('solares',    'd03c4438138538698cebf968b62424674e35ba9417205658', 'America/Mexico_City', (SELECT id FROM sucursales WHERE nombre = 'Solares'))
ON CONFLICT (origen) DO NOTHING;

-- BLOQUE 2: cuentas (cheques)
CREATE TABLE IF NOT EXISTS pos_ventas (
  origen text NOT NULL,
  folio bigint NOT NULL,
  numcheque bigint,
  fecha_venta date,                 -- día de negocio (corte 4 AM, hora local de la sucursal)
  apertura timestamptz,
  cierre timestamptz,
  mesa text,
  personas int,
  total numeric,
  subtotal numeric,                 -- sin IVA
  efectivo numeric,
  tarjeta numeric,
  propina numeric,
  descuento numeric,
  cancelado boolean NOT NULL DEFAULT false,
  tipodeservicio int,
  idturno bigint,
  payload jsonb NOT NULL,           -- la fila completa tal cual vino del POS
  actualizado timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (origen, folio)
);
CREATE INDEX IF NOT EXISTS pos_ventas_fecha_idx ON pos_ventas (origen, fecha_venta);
ALTER TABLE pos_ventas ENABLE ROW LEVEL SECURITY;
CREATE POLICY pos_ventas_leer ON pos_ventas FOR SELECT TO authenticated USING (true);

-- BLOQUE 3: renglones (cheqdet)
CREATE TABLE IF NOT EXISTS pos_venta_detalle (
  origen text NOT NULL,
  foliodet bigint NOT NULL,         -- une con pos_ventas.folio
  movimiento bigint NOT NULL,
  idproducto text,
  cantidad numeric,
  precio numeric,                   -- CON IVA (regla del volcado)
  descuento_pct numeric,            -- es PORCENTAJE
  hora timestamptz,
  payload jsonb NOT NULL,
  actualizado timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (origen, foliodet, movimiento)
);
CREATE INDEX IF NOT EXISTS pos_det_producto_idx ON pos_venta_detalle (origen, idproducto);
ALTER TABLE pos_venta_detalle ENABLE ROW LEVEL SECURITY;
CREATE POLICY pos_det_leer ON pos_venta_detalle FOR SELECT TO authenticated USING (true);

-- BLOQUE 4: turnos y catálogo de productos
CREATE TABLE IF NOT EXISTS pos_turnos (
  origen text NOT NULL,
  idturno bigint NOT NULL,
  apertura timestamptz,
  cierre timestamptz,
  cajero text,
  fondo numeric,
  efectivo numeric,                 -- OJO: neto de retiros, no efectivo cobrado
  payload jsonb NOT NULL,
  actualizado timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (origen, idturno)
);
ALTER TABLE pos_turnos ENABLE ROW LEVEL SECURITY;
CREATE POLICY pos_turnos_leer ON pos_turnos FOR SELECT TO authenticated USING (true);

CREATE TABLE IF NOT EXISTS pos_productos (
  origen text NOT NULL,
  idproducto text NOT NULL,
  descripcion text,
  grupo text,
  precio numeric,
  payload jsonb NOT NULL,
  actualizado timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (origen, idproducto)
);
ALTER TABLE pos_productos ENABLE ROW LEVEL SECURITY;
CREATE POLICY pos_productos_leer ON pos_productos FOR SELECT TO authenticated USING (true);

-- BLOQUE 5: bitácora de sincronización (para el semáforo del panel)
CREATE TABLE IF NOT EXISTS pos_sync_log (
  id bigserial PRIMARY KEY,
  origen text NOT NULL,
  tabla text NOT NULL,
  filas int NOT NULL,
  creado timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS pos_sync_log_idx ON pos_sync_log (origen, creado DESC);
ALTER TABLE pos_sync_log ENABLE ROW LEVEL SECURITY;
CREATE POLICY pos_sync_leer ON pos_sync_log FOR SELECT TO authenticated USING (true);

-- BLOQUE 6: el receptor. El agente lo llama por PostgREST como anon;
-- autoriza con el secret de pos_ingest_keys. SECURITY DEFINER brinca RLS.
CREATE OR REPLACE FUNCTION pos_ingest(p_secret text, p_origen text, p_tabla text, p_filas jsonb)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_tz text;
  v_n int := 0;
BEGIN
  SELECT zona_horaria INTO v_tz
  FROM pos_ingest_keys
  WHERE origen = p_origen AND secret = p_secret AND activo;
  IF v_tz IS NULL THEN
    RAISE EXCEPTION 'no autorizado';
  END IF;
  IF jsonb_typeof(p_filas) <> 'array' THEN
    RAISE EXCEPTION 'p_filas debe ser un arreglo';
  END IF;

  IF p_tabla = 'cheques' THEN
    INSERT INTO pos_ventas (origen, folio, numcheque, fecha_venta, apertura, cierre, mesa,
      personas, total, subtotal, efectivo, tarjeta, propina, descuento, cancelado,
      tipodeservicio, idturno, payload)
    SELECT p_origen,
      (r->>'folio')::numeric::bigint,
      NULLIF(r->>'numcheque','')::numeric::bigint,
      (COALESCE(NULLIF(r->>'cierre',''), NULLIF(r->>'fecha',''))::timestamp - interval '4 hours')::date,
      NULLIF(r->>'fecha','')::timestamp AT TIME ZONE v_tz,
      NULLIF(r->>'cierre','')::timestamp AT TIME ZONE v_tz,
      r->>'mesa',
      NULLIF(r->>'nopersonas','')::numeric::int,
      NULLIF(r->>'total','')::numeric,
      NULLIF(r->>'subtotal','')::numeric,
      NULLIF(r->>'efectivo','')::numeric,
      NULLIF(r->>'tarjeta','')::numeric,
      NULLIF(r->>'propina','')::numeric,
      NULLIF(r->>'descuento','')::numeric,
      COALESCE(lower(r->>'cancelado') IN ('true','1'), false),
      NULLIF(r->>'tipodeservicio','')::numeric::int,
      NULLIF(r->>'idturno','')::numeric::bigint,
      r
    FROM jsonb_array_elements(p_filas) AS t(r)
    WHERE COALESCE(r->>'folio','') ~ '^[0-9]+(\.0+)?$'
    ON CONFLICT (origen, folio) DO UPDATE SET
      numcheque = EXCLUDED.numcheque, fecha_venta = EXCLUDED.fecha_venta,
      apertura = EXCLUDED.apertura, cierre = EXCLUDED.cierre, mesa = EXCLUDED.mesa,
      personas = EXCLUDED.personas, total = EXCLUDED.total, subtotal = EXCLUDED.subtotal,
      efectivo = EXCLUDED.efectivo, tarjeta = EXCLUDED.tarjeta, propina = EXCLUDED.propina,
      descuento = EXCLUDED.descuento, cancelado = EXCLUDED.cancelado,
      tipodeservicio = EXCLUDED.tipodeservicio, idturno = EXCLUDED.idturno,
      payload = EXCLUDED.payload, actualizado = now();
    GET DIAGNOSTICS v_n = ROW_COUNT;

  ELSIF p_tabla = 'cheqdet' THEN
    INSERT INTO pos_venta_detalle (origen, foliodet, movimiento, idproducto, cantidad,
      precio, descuento_pct, hora, payload)
    SELECT p_origen,
      (r->>'foliodet')::numeric::bigint,
      (r->>'movimiento')::numeric::bigint,
      r->>'idproducto',
      NULLIF(r->>'cantidad','')::numeric,
      NULLIF(r->>'precio','')::numeric,
      NULLIF(r->>'descuento','')::numeric,
      NULLIF(r->>'hora','')::timestamp AT TIME ZONE v_tz,
      r
    FROM jsonb_array_elements(p_filas) AS t(r)
    WHERE COALESCE(r->>'foliodet','') ~ '^[0-9]+(\.0+)?$'
      AND COALESCE(r->>'movimiento','') ~ '^[0-9]+(\.0+)?$'
    ON CONFLICT (origen, foliodet, movimiento) DO UPDATE SET
      idproducto = EXCLUDED.idproducto, cantidad = EXCLUDED.cantidad,
      precio = EXCLUDED.precio, descuento_pct = EXCLUDED.descuento_pct,
      hora = EXCLUDED.hora, payload = EXCLUDED.payload, actualizado = now();
    GET DIAGNOSTICS v_n = ROW_COUNT;

  ELSIF p_tabla = 'turnos' THEN
    INSERT INTO pos_turnos (origen, idturno, apertura, cierre, cajero, fondo, efectivo, payload)
    SELECT p_origen,
      (r->>'idturno')::numeric::bigint,
      NULLIF(r->>'apertura','')::timestamp AT TIME ZONE v_tz,
      NULLIF(r->>'cierre','')::timestamp AT TIME ZONE v_tz,
      r->>'cajero',
      NULLIF(r->>'fondo','')::numeric,
      NULLIF(r->>'efectivo','')::numeric,
      r
    FROM jsonb_array_elements(p_filas) AS t(r)
    WHERE COALESCE(r->>'idturno','') ~ '^[0-9]+(\.0+)?$'
    ON CONFLICT (origen, idturno) DO UPDATE SET
      apertura = EXCLUDED.apertura, cierre = EXCLUDED.cierre, cajero = EXCLUDED.cajero,
      fondo = EXCLUDED.fondo, efectivo = EXCLUDED.efectivo,
      payload = EXCLUDED.payload, actualizado = now();
    GET DIAGNOSTICS v_n = ROW_COUNT;

  ELSIF p_tabla = 'productos' THEN
    INSERT INTO pos_productos (origen, idproducto, descripcion, grupo, precio, payload)
    SELECT p_origen,
      r->>'idproducto',
      r->>'descripcion',
      r->>'grupo',
      COALESCE(NULLIF(r->>'precio',''), NULLIF(r->>'precio1',''))::numeric,
      r
    FROM jsonb_array_elements(p_filas) AS t(r)
    WHERE COALESCE(r->>'idproducto','') <> ''
    ON CONFLICT (origen, idproducto) DO UPDATE SET
      descripcion = EXCLUDED.descripcion, grupo = EXCLUDED.grupo, precio = EXCLUDED.precio,
      payload = EXCLUDED.payload, actualizado = now();
    GET DIAGNOSTICS v_n = ROW_COUNT;

  ELSE
    RAISE EXCEPTION 'tabla desconocida: %', p_tabla;
  END IF;

  INSERT INTO pos_sync_log (origen, tabla, filas) VALUES (p_origen, p_tabla, v_n);
  RETURN jsonb_build_object('ok', true, 'tabla', p_tabla, 'filas', v_n);
END;
$$;

REVOKE ALL ON FUNCTION pos_ingest(text, text, text, jsonb) FROM public;
GRANT EXECUTE ON FUNCTION pos_ingest(text, text, text, jsonb) TO anon, authenticated;
