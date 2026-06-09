-- ============================================================================
-- PEDIDOS EN LÍNEA — SQL CONSOLIDADO (todo en orden, listo para el SQL Editor
-- de Supabase/Lovable). Equivale a aplicar, en este orden:
--   1. supabase/migrations/20260609120000_pedidos_en_linea_schema.sql
--   2. supabase/migrations/20260609120100_pedidos_en_linea_rpcs.sql
--   3. supabase/migrations/20260609120200_pedidos_en_linea_base.sql
--   4. db/seed/menu_seed.sql (generado desde db/seed/menu_seed.csv)
-- Es idempotente: se puede volver a correr completo sin duplicar datos.
-- ============================================================================

-- ============================================================
-- PEDIDOS EN LÍNEA (cliente final) — Esquema
-- Módulo independiente del sistema interno de pedidos a
-- proveedores (tablas pedidos / pedidos_detalle NO se tocan).
-- ============================================================

-- ---------- 1. Columnas nuevas en sucursales ----------
ALTER TABLE public.sucursales
  ADD COLUMN IF NOT EXISTS pedidos_en_linea_activos boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS pedidos_pausados_hasta timestamptz,
  ADD COLUMN IF NOT EXISTS venta_alcohol_en_linea boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS tiempo_estimado_min integer NOT NULL DEFAULT 40,
  ADD COLUMN IF NOT EXISTS prefijo_folio text,
  ADD COLUMN IF NOT EXISTS slug text,
  ADD COLUMN IF NOT EXISTS telefono_contacto text,
  -- Del Valle / Las Brisas / Cervecería están en Tepic (America/Mazatlan, UTC-7);
  -- Solares está en Zapopan (America/Mexico_City, UTC-6). El horario se valida
  -- server-side con la zona horaria de cada sucursal.
  ADD COLUMN IF NOT EXISTS zona_horaria text NOT NULL DEFAULT 'America/Mexico_City';

CREATE UNIQUE INDEX IF NOT EXISTS sucursales_slug_key ON public.sucursales (slug) WHERE slug IS NOT NULL;

-- ---------- 2. Catálogo de menú ----------
CREATE TABLE IF NOT EXISTS public.menu_categorias (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre text NOT NULL UNIQUE,
  orden integer NOT NULL DEFAULT 0,
  activa boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.menu_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  categoria_id uuid NOT NULL REFERENCES public.menu_categorias(id) ON DELETE CASCADE,
  nombre text NOT NULL,
  descripcion text,
  es_alcohol boolean NOT NULL DEFAULT false,
  -- Grupos de opción de selección única, ej. {"preparacion":["Suave","Normal","Picante"]}
  opciones jsonb,
  orden integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (categoria_id, nombre)
);

CREATE TABLE IF NOT EXISTS public.menu_variantes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  item_id uuid NOT NULL REFERENCES public.menu_items(id) ON DELETE CASCADE,
  nombre text NOT NULL, -- 'Mediano 300g', 'Grande 400g', 'Única', '355 ml', ...
  orden integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (item_id, nombre)
);

-- Qué se vende y a qué precio en cada sucursal. Sin fila = no se vende ahí.
CREATE TABLE IF NOT EXISTS public.menu_variante_sucursal (
  variante_id uuid NOT NULL REFERENCES public.menu_variantes(id) ON DELETE CASCADE,
  sucursal_id uuid NOT NULL REFERENCES public.sucursales(id) ON DELETE CASCADE,
  precio numeric(10,2) NOT NULL CHECK (precio >= 0),
  disponible boolean NOT NULL DEFAULT true, -- false = agotado hoy
  PRIMARY KEY (variante_id, sucursal_id)
);

-- ---------- 3. Zonas de reparto y horarios ----------
CREATE TABLE IF NOT EXISTS public.zonas_reparto (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  sucursal_id uuid NOT NULL REFERENCES public.sucursales(id) ON DELETE CASCADE,
  nombre text NOT NULL,
  costo_envio numeric(10,2) NOT NULL DEFAULT 0 CHECK (costo_envio >= 0),
  pedido_minimo numeric(10,2) NOT NULL DEFAULT 0 CHECK (pedido_minimo >= 0),
  activa boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.horarios_sucursal (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  sucursal_id uuid NOT NULL REFERENCES public.sucursales(id) ON DELETE CASCADE,
  dia_semana integer NOT NULL CHECK (dia_semana BETWEEN 0 AND 6), -- 0 = domingo
  hora_apertura time NOT NULL,
  hora_cierre time NOT NULL,
  activo boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS horarios_sucursal_idx ON public.horarios_sucursal (sucursal_id, dia_semana);

-- ---------- 4. Pedidos en línea ----------
-- Secuencia diaria de folios por sucursal (upsert atómico, no MAX+1).
CREATE TABLE IF NOT EXISTS public.folios_secuencia (
  sucursal_id uuid NOT NULL REFERENCES public.sucursales(id) ON DELETE CASCADE,
  fecha date NOT NULL,
  ultimo integer NOT NULL DEFAULT 0,
  PRIMARY KEY (sucursal_id, fecha)
);

CREATE TABLE IF NOT EXISTS public.pedidos_en_linea (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  folio text NOT NULL, -- ej. 'VAL-042' (secuencia diaria por sucursal)
  token uuid NOT NULL UNIQUE DEFAULT gen_random_uuid(), -- seguimiento del cliente
  sucursal_id uuid NOT NULL REFERENCES public.sucursales(id),
  tipo text NOT NULL CHECK (tipo IN ('recoger','reparto')),
  estado text NOT NULL DEFAULT 'nuevo'
    CHECK (estado IN ('nuevo','confirmado','preparando','listo','en_reparto','entregado','cancelado')),
  nombre_cliente text NOT NULL,
  telefono text NOT NULL CHECK (telefono ~ '^[0-9]{10}$'),
  zona_id uuid REFERENCES public.zonas_reparto(id),
  direccion text,
  referencias text,
  subtotal numeric(10,2) NOT NULL DEFAULT 0,
  costo_envio numeric(10,2) NOT NULL DEFAULT 0,
  total numeric(10,2) NOT NULL DEFAULT 0,
  metodo_pago text NOT NULL DEFAULT 'contra_entrega', -- fase 2: pago en línea
  notas_generales text,
  motivo_cancelacion text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  confirmado_at timestamptz,
  listo_at timestamptz,
  entregado_at timestamptz
);
CREATE INDEX IF NOT EXISTS pedidos_en_linea_sucursal_idx ON public.pedidos_en_linea (sucursal_id, created_at DESC);
CREATE INDEX IF NOT EXISTS pedidos_en_linea_telefono_idx ON public.pedidos_en_linea (telefono, created_at DESC);
CREATE INDEX IF NOT EXISTS pedidos_en_linea_estado_idx ON public.pedidos_en_linea (sucursal_id, estado);

CREATE TABLE IF NOT EXISTS public.pedidos_en_linea_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  pedido_id uuid NOT NULL REFERENCES public.pedidos_en_linea(id) ON DELETE CASCADE,
  variante_id uuid REFERENCES public.menu_variantes(id) ON DELETE SET NULL,
  -- Congelados al momento de ordenar: cambios de precio/nombre no corrompen históricos
  nombre_item text NOT NULL,
  nombre_variante text NOT NULL,
  precio_unitario numeric(10,2) NOT NULL,
  cantidad integer NOT NULL CHECK (cantidad > 0),
  opciones_elegidas jsonb,
  notas text,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS pedidos_en_linea_items_pedido_idx ON public.pedidos_en_linea_items (pedido_id);

-- Fase 2 (WhatsApp): el panel solo escribe filas; un worker externo las consume.
CREATE TABLE IF NOT EXISTS public.notificaciones_pedido (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  pedido_id uuid NOT NULL REFERENCES public.pedidos_en_linea(id) ON DELETE CASCADE,
  tipo text NOT NULL, -- 'confirmado' | 'listo' | 'en_reparto'
  telefono text NOT NULL,
  estado text NOT NULL DEFAULT 'pendiente',
  payload jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS notificaciones_pedido_estado_idx ON public.notificaciones_pedido (estado, created_at);

-- ---------- 5. Triggers ----------
-- updated_at + timestamps por estado + notificaciones de fase 2
CREATE OR REPLACE FUNCTION public.pedidos_en_linea_al_actualizar()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  NEW.updated_at := now();
  IF NEW.estado IS DISTINCT FROM OLD.estado THEN
    IF NEW.estado = 'confirmado' AND NEW.confirmado_at IS NULL THEN
      NEW.confirmado_at := now();
    ELSIF NEW.estado = 'listo' AND NEW.listo_at IS NULL THEN
      NEW.listo_at := now();
    ELSIF NEW.estado = 'entregado' AND NEW.entregado_at IS NULL THEN
      NEW.entregado_at := now();
    END IF;
    IF NEW.estado IN ('confirmado','listo','en_reparto') THEN
      INSERT INTO public.notificaciones_pedido (pedido_id, tipo, telefono, estado, payload)
      VALUES (
        NEW.id,
        NEW.estado,
        NEW.telefono,
        'pendiente',
        jsonb_build_object(
          'folio', NEW.folio,
          'nombre_cliente', NEW.nombre_cliente,
          'tipo', NEW.tipo,
          'total', NEW.total,
          'sucursal_id', NEW.sucursal_id
        )
      );
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_pedidos_en_linea_al_actualizar ON public.pedidos_en_linea;
CREATE TRIGGER trg_pedidos_en_linea_al_actualizar
  BEFORE UPDATE ON public.pedidos_en_linea
  FOR EACH ROW EXECUTE FUNCTION public.pedidos_en_linea_al_actualizar();

-- ---------- 6. RLS ----------
ALTER TABLE public.menu_categorias ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.menu_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.menu_variantes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.menu_variante_sucursal ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.zonas_reparto ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.horarios_sucursal ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.folios_secuencia ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pedidos_en_linea ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pedidos_en_linea_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notificaciones_pedido ENABLE ROW LEVEL SECURITY;

-- Público (anon): solo lectura del catálogo. CERO acceso directo a pedidos
-- (el cliente crea/lee pedidos únicamente vía las RPCs SECURITY DEFINER).
DROP POLICY IF EXISTS "publico_lee_categorias" ON public.menu_categorias;
CREATE POLICY "publico_lee_categorias" ON public.menu_categorias
  FOR SELECT USING (activa = true);

DROP POLICY IF EXISTS "publico_lee_items" ON public.menu_items;
CREATE POLICY "publico_lee_items" ON public.menu_items
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "publico_lee_variantes" ON public.menu_variantes;
CREATE POLICY "publico_lee_variantes" ON public.menu_variantes
  FOR SELECT USING (true);

-- Se exponen también filas con disponible=false para poder mostrar "Agotado"
-- en el carrito del cliente (no contiene datos sensibles).
DROP POLICY IF EXISTS "publico_lee_precios" ON public.menu_variante_sucursal;
CREATE POLICY "publico_lee_precios" ON public.menu_variante_sucursal
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "publico_lee_zonas_activas" ON public.zonas_reparto;
CREATE POLICY "publico_lee_zonas_activas" ON public.zonas_reparto
  FOR SELECT USING (activa = true);

DROP POLICY IF EXISTS "publico_lee_horarios" ON public.horarios_sucursal;
CREATE POLICY "publico_lee_horarios" ON public.horarios_sucursal
  FOR SELECT USING (true);

-- Staff (authenticated): acceso completo.
-- PENDIENTE documentado: el sistema interno no asigna usuario→sucursal
-- (usa PIN por dispositivo), por lo que cualquier usuario autenticado ve
-- todas las sucursales. Ver docs/pedidos-en-linea.md.
DROP POLICY IF EXISTS "staff_categorias" ON public.menu_categorias;
CREATE POLICY "staff_categorias" ON public.menu_categorias
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "staff_items" ON public.menu_items;
CREATE POLICY "staff_items" ON public.menu_items
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "staff_variantes" ON public.menu_variantes;
CREATE POLICY "staff_variantes" ON public.menu_variantes
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "staff_precios" ON public.menu_variante_sucursal;
CREATE POLICY "staff_precios" ON public.menu_variante_sucursal
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "staff_zonas" ON public.zonas_reparto;
CREATE POLICY "staff_zonas" ON public.zonas_reparto
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "staff_horarios" ON public.horarios_sucursal;
CREATE POLICY "staff_horarios" ON public.horarios_sucursal
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "staff_pedidos_en_linea" ON public.pedidos_en_linea;
CREATE POLICY "staff_pedidos_en_linea" ON public.pedidos_en_linea
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "staff_pedidos_en_linea_items" ON public.pedidos_en_linea_items;
CREATE POLICY "staff_pedidos_en_linea_items" ON public.pedidos_en_linea_items
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "staff_notificaciones" ON public.notificaciones_pedido;
CREATE POLICY "staff_notificaciones" ON public.notificaciones_pedido
  FOR SELECT TO authenticated USING (true);

-- folios_secuencia: sin políticas → solo las funciones SECURITY DEFINER la tocan.

-- El staff necesita actualizar los controles operativos de su sucursal
-- (toggle de pedidos, pausa, tiempo estimado, alcohol). Política aditiva,
-- no altera las existentes.
DROP POLICY IF EXISTS "staff_actualiza_sucursales" ON public.sucursales;
CREATE POLICY "staff_actualiza_sucursales" ON public.sucursales
  FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

-- ---------- 7. Realtime ----------
ALTER TABLE public.pedidos_en_linea REPLICA IDENTITY FULL;
DO $$
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.pedidos_en_linea;
EXCEPTION WHEN duplicate_object THEN
  NULL; -- ya estaba en la publicación
END $$;

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

-- ============================================================
-- PEDIDOS EN LÍNEA — Configuración base por sucursal
-- Sucursales reales en DB: 'Del Valle', 'Las Brisas', 'Cervecería', 'Solares'
-- ============================================================

-- Crea las sucursales que falten (idempotente; en producción ya existen las 4)
INSERT INTO public.sucursales (nombre, direccion)
SELECT v.nombre, v.direccion
FROM (VALUES
  ('Del Valle',  'Cd. del Valle, Tepic, Nayarit'),
  ('Las Brisas', 'Las Brisas, Tepic, Nayarit'),
  ('Cervecería', 'Col. Versalles, Tepic, Nayarit'),
  ('Solares',    'Solares, Zapopan, Jalisco')
) AS v(nombre, direccion)
WHERE NOT EXISTS (SELECT 1 FROM public.sucursales s WHERE s.nombre = v.nombre);

-- Prefijo de folio, slug público y zona horaria
UPDATE public.sucursales SET prefijo_folio = 'VAL', slug = 'del-valle',  zona_horaria = 'America/Mazatlan'    WHERE nombre = 'Del Valle';
UPDATE public.sucursales SET prefijo_folio = 'BRI', slug = 'las-brisas', zona_horaria = 'America/Mazatlan'    WHERE nombre = 'Las Brisas';
UPDATE public.sucursales SET prefijo_folio = 'CER', slug = 'cerveceria', zona_horaria = 'America/Mazatlan'    WHERE nombre = 'Cervecería';
UPDATE public.sucursales SET prefijo_folio = 'SOL', slug = 'solares',    zona_horaria = 'America/Mexico_City' WHERE nombre = 'Solares';

-- Zonas de reparto placeholder (inactivas; el dueño captura las reales en el panel)
INSERT INTO public.zonas_reparto (sucursal_id, nombre, costo_envio, pedido_minimo, activa)
SELECT s.id, z.nombre, 35, 0, false
FROM public.sucursales s
CROSS JOIN (VALUES ('ZONA PENDIENTE 1'), ('ZONA PENDIENTE 2')) AS z(nombre)
WHERE s.nombre IN ('Del Valle','Las Brisas','Cervecería','Solares')
  AND NOT EXISTS (
    SELECT 1 FROM public.zonas_reparto zr
    WHERE zr.sucursal_id = s.id AND zr.nombre = z.nombre
  );

-- Horarios placeholder: todos los días 11:00–21:00 (editables desde el panel)
INSERT INTO public.horarios_sucursal (sucursal_id, dia_semana, hora_apertura, hora_cierre, activo)
SELECT s.id, d.dia, '11:00'::time, '21:00'::time, true
FROM public.sucursales s
CROSS JOIN generate_series(0, 6) AS d(dia)
WHERE s.nombre IN ('Del Valle','Las Brisas','Cervecería','Solares')
  AND NOT EXISTS (
    SELECT 1 FROM public.horarios_sucursal h
    WHERE h.sucursal_id = s.id AND h.dia_semana = d.dia
  );

-- ============================================================
-- SEED DEL MENÚ — generado por scripts/seed-menu.ts --sql
-- Idempotente: se puede correr más de una vez sin duplicar.
-- El upsert de precios NO toca `disponible` (toggles del staff).
-- ============================================================

-- ===== Entradas y Especialidades =====
INSERT INTO public.menu_categorias (nombre, orden) VALUES ('Entradas y Especialidades', 0) ON CONFLICT (nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Paté de camarón', 'Especialidad de la casa', false, NULL, 0
  FROM public.menu_categorias c WHERE c.nombre = 'Entradas y Especialidades'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 200g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Paté de camarón'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 218.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Paté de camarón' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 218.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Paté de camarón' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 218.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Paté de camarón' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 208.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Paté de camarón' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 300g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Paté de camarón'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 298.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Paté de camarón' AND v.nombre = 'Grande 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 298.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Paté de camarón' AND v.nombre = 'Grande 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 298.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Paté de camarón' AND v.nombre = 'Grande 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Camarones a la Cucaracha', 'Camarón frito entero', false, NULL, 1
  FROM public.menu_categorias c WHERE c.nombre = 'Entradas y Especialidades'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 200g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Camarones a la Cucaracha'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 218.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Camarones a la Cucaracha' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 218.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Camarones a la Cucaracha' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 218.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Camarones a la Cucaracha' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 208.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Camarones a la Cucaracha' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 300g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Camarones a la Cucaracha'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 298.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Camarones a la Cucaracha' AND v.nombre = 'Grande 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 298.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Camarones a la Cucaracha' AND v.nombre = 'Grande 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 298.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Camarones a la Cucaracha' AND v.nombre = 'Grande 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Marlín en estofado', 'En Solares porción 250g', false, NULL, 2
  FROM public.menu_categorias c WHERE c.nombre = 'Entradas y Especialidades'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 200g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Marlín en estofado'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 208.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Marlín en estofado' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 208.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Marlín en estofado' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 208.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Marlín en estofado' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 228.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Marlín en estofado' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 300g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Marlín en estofado'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Marlín en estofado' AND v.nombre = 'Grande 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Marlín en estofado' AND v.nombre = 'Grande 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Marlín en estofado' AND v.nombre = 'Grande 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Chicharrón de róbalo', NULL, false, NULL, 3
  FROM public.menu_categorias c WHERE c.nombre = 'Entradas y Especialidades'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 350g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Chicharrón de róbalo'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 268.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Chicharrón de róbalo' AND v.nombre = 'Mediano 350g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 268.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Chicharrón de róbalo' AND v.nombre = 'Mediano 350g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 268.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Chicharrón de róbalo' AND v.nombre = 'Mediano 350g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 228.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Chicharrón de róbalo' AND v.nombre = 'Mediano 350g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 500g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Chicharrón de róbalo'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 358.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Chicharrón de róbalo' AND v.nombre = 'Grande 500g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 358.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Chicharrón de róbalo' AND v.nombre = 'Grande 500g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 358.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Chicharrón de róbalo' AND v.nombre = 'Grande 500g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Chicharrón de pulpo', NULL, false, NULL, 4
  FROM public.menu_categorias c WHERE c.nombre = 'Entradas y Especialidades'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Única', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Chicharrón de pulpo'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 228.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Chicharrón de pulpo' AND v.nombre = 'Única' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Taco gobernador', 'Camarón con queso pimiento y cebolla', false, NULL, 5
  FROM public.menu_categorias c WHERE c.nombre = 'Entradas y Especialidades'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '1 pieza', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Taco gobernador'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 78.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Taco gobernador' AND v.nombre = '1 pieza' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 78.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Taco gobernador' AND v.nombre = '1 pieza' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 78.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Taco gobernador' AND v.nombre = '1 pieza' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 78.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Taco gobernador' AND v.nombre = '1 pieza' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Taco de atún', NULL, false, NULL, 6
  FROM public.menu_categorias c WHERE c.nombre = 'Entradas y Especialidades'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '1 pieza', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Taco de atún'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 49.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Taco de atún' AND v.nombre = '1 pieza' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Taco capeado', 'Camarón o pescado', false, '{"tipo":["Camarón","Pescado"]}'::jsonb, 7
  FROM public.menu_categorias c WHERE c.nombre = 'Entradas y Especialidades'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '1 pieza', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Taco capeado'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 78.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Taco capeado' AND v.nombre = '1 pieza' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Taquitos La Ola', 'Tacos de machaca de camarón', false, NULL, 8
  FROM public.menu_categorias c WHERE c.nombre = 'Entradas y Especialidades'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '3 piezas', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Taquitos La Ola'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 72.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Taquitos La Ola' AND v.nombre = '3 piezas' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Botana de camarón seco', NULL, false, NULL, 9
  FROM public.menu_categorias c WHERE c.nombre = 'Entradas y Especialidades'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Única 200g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Botana de camarón seco'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 148.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Botana de camarón seco' AND v.nombre = 'Única 200g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 148.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Botana de camarón seco' AND v.nombre = 'Única 200g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Carne asada', 'Incluye 2 tacos de frijoles salsas y tortillas', false, NULL, 10
  FROM public.menu_categorias c WHERE c.nombre = 'Entradas y Especialidades'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Única 500g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Carne asada'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 248.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Carne asada' AND v.nombre = 'Única 500g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Carnitas', 'Incluye salsas y tortillas', false, NULL, 11
  FROM public.menu_categorias c WHERE c.nombre = 'Entradas y Especialidades'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Única 500g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Carnitas'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 178.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Carnitas' AND v.nombre = 'Única 500g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;

-- ===== Balazos =====
INSERT INTO public.menu_categorias (nombre, orden) VALUES ('Balazos', 1) ON CONFLICT (nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Balazo de ostión', 'Salseado con el marisco de tu preferencia', false, NULL, 0
  FROM public.menu_categorias c WHERE c.nombre = 'Balazos'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '15g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Balazos' AND i.nombre = 'Balazo de ostión'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 39.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Balazos' AND i.nombre = 'Balazo de ostión' AND v.nombre = '15g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 39.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Balazos' AND i.nombre = 'Balazo de ostión' AND v.nombre = '15g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 39.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Balazos' AND i.nombre = 'Balazo de ostión' AND v.nombre = '15g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 39.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Balazos' AND i.nombre = 'Balazo de ostión' AND v.nombre = '15g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Balazo de pulpo', NULL, false, NULL, 1
  FROM public.menu_categorias c WHERE c.nombre = 'Balazos'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '15g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Balazos' AND i.nombre = 'Balazo de pulpo'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 39.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Balazos' AND i.nombre = 'Balazo de pulpo' AND v.nombre = '15g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 39.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Balazos' AND i.nombre = 'Balazo de pulpo' AND v.nombre = '15g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 39.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Balazos' AND i.nombre = 'Balazo de pulpo' AND v.nombre = '15g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 39.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Balazos' AND i.nombre = 'Balazo de pulpo' AND v.nombre = '15g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Balazo de camarón cocido', NULL, false, NULL, 2
  FROM public.menu_categorias c WHERE c.nombre = 'Balazos'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '15g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Balazos' AND i.nombre = 'Balazo de camarón cocido'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 39.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Balazos' AND i.nombre = 'Balazo de camarón cocido' AND v.nombre = '15g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 39.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Balazos' AND i.nombre = 'Balazo de camarón cocido' AND v.nombre = '15g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 39.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Balazos' AND i.nombre = 'Balazo de camarón cocido' AND v.nombre = '15g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 39.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Balazos' AND i.nombre = 'Balazo de camarón cocido' AND v.nombre = '15g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Balazo de camarón curtido en limón', 'En Solares: camarón crudo', false, NULL, 3
  FROM public.menu_categorias c WHERE c.nombre = 'Balazos'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '15g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Balazos' AND i.nombre = 'Balazo de camarón curtido en limón'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 39.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Balazos' AND i.nombre = 'Balazo de camarón curtido en limón' AND v.nombre = '15g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 39.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Balazos' AND i.nombre = 'Balazo de camarón curtido en limón' AND v.nombre = '15g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 39.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Balazos' AND i.nombre = 'Balazo de camarón curtido en limón' AND v.nombre = '15g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 39.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Balazos' AND i.nombre = 'Balazo de camarón curtido en limón' AND v.nombre = '15g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Balazo de callo de hacha', NULL, false, NULL, 4
  FROM public.menu_categorias c WHERE c.nombre = 'Balazos'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '15g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Balazos' AND i.nombre = 'Balazo de callo de hacha'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 49.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Balazos' AND i.nombre = 'Balazo de callo de hacha' AND v.nombre = '15g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 49.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Balazos' AND i.nombre = 'Balazo de callo de hacha' AND v.nombre = '15g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 49.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Balazos' AND i.nombre = 'Balazo de callo de hacha' AND v.nombre = '15g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 51.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Balazos' AND i.nombre = 'Balazo de callo de hacha' AND v.nombre = '15g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Tabla La Ola', 'Arma tu tabla al gusto. Máximo 1 balazo de callo por tabla', false, NULL, 5
  FROM public.menu_categorias c WHERE c.nombre = 'Balazos'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '5 balazos', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Balazos' AND i.nombre = 'Tabla La Ola'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 159.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Balazos' AND i.nombre = 'Tabla La Ola' AND v.nombre = '5 balazos' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 159.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Balazos' AND i.nombre = 'Tabla La Ola' AND v.nombre = '5 balazos' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 159.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Balazos' AND i.nombre = 'Tabla La Ola' AND v.nombre = '5 balazos' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 168.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Balazos' AND i.nombre = 'Tabla La Ola' AND v.nombre = '5 balazos' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;

-- ===== Empanadas =====
INSERT INTO public.menu_categorias (nombre, orden) VALUES ('Empanadas', 2) ON CONFLICT (nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Empanada de queso', NULL, false, NULL, 0
  FROM public.menu_categorias c WHERE c.nombre = 'Empanadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '1 pieza', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de queso'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 62.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de queso' AND v.nombre = '1 pieza' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 62.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de queso' AND v.nombre = '1 pieza' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 62.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de queso' AND v.nombre = '1 pieza' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 62.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de queso' AND v.nombre = '1 pieza' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Empanada de camarón', NULL, false, NULL, 1
  FROM public.menu_categorias c WHERE c.nombre = 'Empanadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '1 pieza', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de camarón'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 74.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de camarón' AND v.nombre = '1 pieza' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 74.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de camarón' AND v.nombre = '1 pieza' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 74.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de camarón' AND v.nombre = '1 pieza' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 72.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de camarón' AND v.nombre = '1 pieza' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Empanada de camarón con queso', NULL, false, NULL, 2
  FROM public.menu_categorias c WHERE c.nombre = 'Empanadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '1 pieza', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de camarón con queso'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 82.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de camarón con queso' AND v.nombre = '1 pieza' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 82.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de camarón con queso' AND v.nombre = '1 pieza' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 82.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de camarón con queso' AND v.nombre = '1 pieza' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 82.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de camarón con queso' AND v.nombre = '1 pieza' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Empanada de pulpo', NULL, false, NULL, 3
  FROM public.menu_categorias c WHERE c.nombre = 'Empanadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '1 pieza', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de pulpo'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 74.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de pulpo' AND v.nombre = '1 pieza' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 74.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de pulpo' AND v.nombre = '1 pieza' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 74.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de pulpo' AND v.nombre = '1 pieza' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 72.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de pulpo' AND v.nombre = '1 pieza' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Empanada de pulpo con queso', NULL, false, NULL, 4
  FROM public.menu_categorias c WHERE c.nombre = 'Empanadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '1 pieza', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de pulpo con queso'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 82.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de pulpo con queso' AND v.nombre = '1 pieza' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 82.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de pulpo con queso' AND v.nombre = '1 pieza' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 82.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de pulpo con queso' AND v.nombre = '1 pieza' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 82.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de pulpo con queso' AND v.nombre = '1 pieza' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Empanada de ostión', NULL, false, NULL, 5
  FROM public.menu_categorias c WHERE c.nombre = 'Empanadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '1 pieza', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de ostión'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 74.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de ostión' AND v.nombre = '1 pieza' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 74.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de ostión' AND v.nombre = '1 pieza' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 74.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de ostión' AND v.nombre = '1 pieza' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 72.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de ostión' AND v.nombre = '1 pieza' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Empanada de ostión con queso', NULL, false, NULL, 6
  FROM public.menu_categorias c WHERE c.nombre = 'Empanadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '1 pieza', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de ostión con queso'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 82.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de ostión con queso' AND v.nombre = '1 pieza' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 82.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de ostión con queso' AND v.nombre = '1 pieza' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 82.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de ostión con queso' AND v.nombre = '1 pieza' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 82.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de ostión con queso' AND v.nombre = '1 pieza' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Empanada de marlín', NULL, false, NULL, 7
  FROM public.menu_categorias c WHERE c.nombre = 'Empanadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '1 pieza', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de marlín'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 72.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de marlín' AND v.nombre = '1 pieza' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Empanada de marlín con queso', NULL, false, NULL, 8
  FROM public.menu_categorias c WHERE c.nombre = 'Empanadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '1 pieza', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de marlín con queso'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 82.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de marlín con queso' AND v.nombre = '1 pieza' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Empanada gobernador', 'Camarón con queso pimiento y cebolla', false, NULL, 9
  FROM public.menu_categorias c WHERE c.nombre = 'Empanadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '1 pieza', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada gobernador'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 82.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada gobernador' AND v.nombre = '1 pieza' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 82.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada gobernador' AND v.nombre = '1 pieza' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 82.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada gobernador' AND v.nombre = '1 pieza' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Empanada La Ola', 'Camarón y pulpo con queso pimiento y cebolla', false, NULL, 10
  FROM public.menu_categorias c WHERE c.nombre = 'Empanadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '1 pieza', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada La Ola'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 82.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada La Ola' AND v.nombre = '1 pieza' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 82.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada La Ola' AND v.nombre = '1 pieza' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 82.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada La Ola' AND v.nombre = '1 pieza' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 92.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada La Ola' AND v.nombre = '1 pieza' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;

-- ===== Taquitos Montados =====
INSERT INTO public.menu_categorias (nombre, orden) VALUES ('Taquitos Montados', 3) ON CONFLICT (nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Taco dorado con ceviche de sierra', NULL, false, NULL, 0
  FROM public.menu_categorias c WHERE c.nombre = 'Taquitos Montados'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '1 pieza 80g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Taquitos Montados' AND i.nombre = 'Taco dorado con ceviche de sierra'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 49.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Taquitos Montados' AND i.nombre = 'Taco dorado con ceviche de sierra' AND v.nombre = '1 pieza 80g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 49.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Taquitos Montados' AND i.nombre = 'Taco dorado con ceviche de sierra' AND v.nombre = '1 pieza 80g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Taco dorado con marlín en estofado', NULL, false, NULL, 1
  FROM public.menu_categorias c WHERE c.nombre = 'Taquitos Montados'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '1 pieza 80g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Taquitos Montados' AND i.nombre = 'Taco dorado con marlín en estofado'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 49.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Taquitos Montados' AND i.nombre = 'Taco dorado con marlín en estofado' AND v.nombre = '1 pieza 80g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 49.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Taquitos Montados' AND i.nombre = 'Taco dorado con marlín en estofado' AND v.nombre = '1 pieza 80g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Taco dorado con ceviche de camarón', NULL, false, NULL, 2
  FROM public.menu_categorias c WHERE c.nombre = 'Taquitos Montados'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '1 pieza 80g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Taquitos Montados' AND i.nombre = 'Taco dorado con ceviche de camarón'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 69.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Taquitos Montados' AND i.nombre = 'Taco dorado con ceviche de camarón' AND v.nombre = '1 pieza 80g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 69.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Taquitos Montados' AND i.nombre = 'Taco dorado con ceviche de camarón' AND v.nombre = '1 pieza 80g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Taco dorado con paté de camarón', NULL, false, NULL, 3
  FROM public.menu_categorias c WHERE c.nombre = 'Taquitos Montados'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '1 pieza 80g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Taquitos Montados' AND i.nombre = 'Taco dorado con paté de camarón'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 69.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Taquitos Montados' AND i.nombre = 'Taco dorado con paté de camarón' AND v.nombre = '1 pieza 80g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 69.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Taquitos Montados' AND i.nombre = 'Taco dorado con paté de camarón' AND v.nombre = '1 pieza 80g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Taco dorado con aguachile de camarón', NULL, false, NULL, 4
  FROM public.menu_categorias c WHERE c.nombre = 'Taquitos Montados'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '1 pieza 80g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Taquitos Montados' AND i.nombre = 'Taco dorado con aguachile de camarón'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 69.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Taquitos Montados' AND i.nombre = 'Taco dorado con aguachile de camarón' AND v.nombre = '1 pieza 80g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 69.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Taquitos Montados' AND i.nombre = 'Taco dorado con aguachile de camarón' AND v.nombre = '1 pieza 80g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Taco dorado con camarón cocido', NULL, false, NULL, 5
  FROM public.menu_categorias c WHERE c.nombre = 'Taquitos Montados'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '1 pieza 80g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Taquitos Montados' AND i.nombre = 'Taco dorado con camarón cocido'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 69.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Taquitos Montados' AND i.nombre = 'Taco dorado con camarón cocido' AND v.nombre = '1 pieza 80g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 69.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Taquitos Montados' AND i.nombre = 'Taco dorado con camarón cocido' AND v.nombre = '1 pieza 80g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Taco dorado con pulpo', NULL, false, NULL, 6
  FROM public.menu_categorias c WHERE c.nombre = 'Taquitos Montados'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '1 pieza 80g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Taquitos Montados' AND i.nombre = 'Taco dorado con pulpo'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 69.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Taquitos Montados' AND i.nombre = 'Taco dorado con pulpo' AND v.nombre = '1 pieza 80g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 69.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Taquitos Montados' AND i.nombre = 'Taco dorado con pulpo' AND v.nombre = '1 pieza 80g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Taco dorado especial La Ola', NULL, false, NULL, 7
  FROM public.menu_categorias c WHERE c.nombre = 'Taquitos Montados'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '1 pieza 80g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Taquitos Montados' AND i.nombre = 'Taco dorado especial La Ola'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 99.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Taquitos Montados' AND i.nombre = 'Taco dorado especial La Ola' AND v.nombre = '1 pieza 80g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 99.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Taquitos Montados' AND i.nombre = 'Taco dorado especial La Ola' AND v.nombre = '1 pieza 80g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Taco dorado especial de paté de camarón', NULL, false, NULL, 8
  FROM public.menu_categorias c WHERE c.nombre = 'Taquitos Montados'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '1 pieza 80g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Taquitos Montados' AND i.nombre = 'Taco dorado especial de paté de camarón'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 89.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Taquitos Montados' AND i.nombre = 'Taco dorado especial de paté de camarón' AND v.nombre = '1 pieza 80g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 89.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Taquitos Montados' AND i.nombre = 'Taco dorado especial de paté de camarón' AND v.nombre = '1 pieza 80g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;

-- ===== Tostadas =====
INSERT INTO public.menu_categorias (nombre, orden) VALUES ('Tostadas', 4) ON CONFLICT (nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Tostada de ceviche de sierra', NULL, false, NULL, 0
  FROM public.menu_categorias c WHERE c.nombre = 'Tostadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '120g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de ceviche de sierra'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 79.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de ceviche de sierra' AND v.nombre = '120g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 79.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de ceviche de sierra' AND v.nombre = '120g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 79.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de ceviche de sierra' AND v.nombre = '120g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 92.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de ceviche de sierra' AND v.nombre = '120g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Tostada de ceviche de camarón', NULL, false, NULL, 1
  FROM public.menu_categorias c WHERE c.nombre = 'Tostadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '120g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de ceviche de camarón'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de ceviche de camarón' AND v.nombre = '120g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de ceviche de camarón' AND v.nombre = '120g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de ceviche de camarón' AND v.nombre = '120g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 112.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de ceviche de camarón' AND v.nombre = '120g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Tostada de ceviche de camarón cocido', NULL, false, NULL, 2
  FROM public.menu_categorias c WHERE c.nombre = 'Tostadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '120g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de ceviche de camarón cocido'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de ceviche de camarón cocido' AND v.nombre = '120g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de ceviche de camarón cocido' AND v.nombre = '120g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de ceviche de camarón cocido' AND v.nombre = '120g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 112.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de ceviche de camarón cocido' AND v.nombre = '120g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Tostada de ceviche de camarón seco', NULL, false, NULL, 3
  FROM public.menu_categorias c WHERE c.nombre = 'Tostadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '120g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de ceviche de camarón seco'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de ceviche de camarón seco' AND v.nombre = '120g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de ceviche de camarón seco' AND v.nombre = '120g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de ceviche de camarón seco' AND v.nombre = '120g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 112.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de ceviche de camarón seco' AND v.nombre = '120g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Tostada de ceviche de róbalo en cuadritos', NULL, false, NULL, 4
  FROM public.menu_categorias c WHERE c.nombre = 'Tostadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '120g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de ceviche de róbalo en cuadritos'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de ceviche de róbalo en cuadritos' AND v.nombre = '120g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de ceviche de róbalo en cuadritos' AND v.nombre = '120g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de ceviche de róbalo en cuadritos' AND v.nombre = '120g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 112.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de ceviche de róbalo en cuadritos' AND v.nombre = '120g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Tostada de aguachile de camarón', NULL, false, NULL, 5
  FROM public.menu_categorias c WHERE c.nombre = 'Tostadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '120g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de aguachile de camarón'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de aguachile de camarón' AND v.nombre = '120g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de aguachile de camarón' AND v.nombre = '120g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de aguachile de camarón' AND v.nombre = '120g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 112.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de aguachile de camarón' AND v.nombre = '120g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Tostada de aguachile de camarón seco', NULL, false, NULL, 6
  FROM public.menu_categorias c WHERE c.nombre = 'Tostadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '120g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de aguachile de camarón seco'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 112.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de aguachile de camarón seco' AND v.nombre = '120g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Tostada de aguachile de pulpo', NULL, false, NULL, 7
  FROM public.menu_categorias c WHERE c.nombre = 'Tostadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '120g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de aguachile de pulpo'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 112.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de aguachile de pulpo' AND v.nombre = '120g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Tostada de camarón cocido', NULL, false, NULL, 8
  FROM public.menu_categorias c WHERE c.nombre = 'Tostadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '120g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de camarón cocido'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de camarón cocido' AND v.nombre = '120g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de camarón cocido' AND v.nombre = '120g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de camarón cocido' AND v.nombre = '120g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 112.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de camarón cocido' AND v.nombre = '120g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Tostada de pulpo', NULL, false, NULL, 9
  FROM public.menu_categorias c WHERE c.nombre = 'Tostadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '120g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de pulpo'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de pulpo' AND v.nombre = '120g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de pulpo' AND v.nombre = '120g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de pulpo' AND v.nombre = '120g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 112.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de pulpo' AND v.nombre = '120g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Tostada de paté de camarón', NULL, false, NULL, 10
  FROM public.menu_categorias c WHERE c.nombre = 'Tostadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '120g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de paté de camarón'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de paté de camarón' AND v.nombre = '120g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de paté de camarón' AND v.nombre = '120g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de paté de camarón' AND v.nombre = '120g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 112.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de paté de camarón' AND v.nombre = '120g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Tostada de marlín en estofado', NULL, false, NULL, 11
  FROM public.menu_categorias c WHERE c.nombre = 'Tostadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '120g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de marlín en estofado'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de marlín en estofado' AND v.nombre = '120g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de marlín en estofado' AND v.nombre = '120g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de marlín en estofado' AND v.nombre = '120g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 112.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de marlín en estofado' AND v.nombre = '120g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Tostada de atún', NULL, false, NULL, 12
  FROM public.menu_categorias c WHERE c.nombre = 'Tostadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '120g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de atún'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de atún' AND v.nombre = '120g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de atún' AND v.nombre = '120g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de atún' AND v.nombre = '120g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 112.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de atún' AND v.nombre = '120g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Tostada de callo de hacha', NULL, false, NULL, 13
  FROM public.menu_categorias c WHERE c.nombre = 'Tostadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '120g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de callo de hacha'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de callo de hacha' AND v.nombre = '120g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de callo de hacha' AND v.nombre = '120g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de callo de hacha' AND v.nombre = '120g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 182.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de callo de hacha' AND v.nombre = '120g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;

-- ===== Tostadas Especiales =====
INSERT INTO public.menu_categorias (nombre, orden) VALUES ('Tostadas Especiales', 5) ON CONFLICT (nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Especial de mariscos', 'Camarón cocido camarón curtido en limón y pulpo sobre 2 tostadas. Solares 200g', false, NULL, 0
  FROM public.menu_categorias c WHERE c.nombre = 'Tostadas Especiales'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '2 tostadas 250g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial de mariscos'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 238.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial de mariscos' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 238.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial de mariscos' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 238.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial de mariscos' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 228.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial de mariscos' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Especial de mariscos con callo de hacha', 'Camarón cocido camarón curtido pulpo y callo de hacha', false, NULL, 1
  FROM public.menu_categorias c WHERE c.nombre = 'Tostadas Especiales'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '2 tostadas 250g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial de mariscos con callo de hacha'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 268.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial de mariscos con callo de hacha' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 268.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial de mariscos con callo de hacha' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 268.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial de mariscos con callo de hacha' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 248.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial de mariscos con callo de hacha' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Especial Santa Cruz', 'Mezcla de mariscos con base de ceviche de camarón seco', false, NULL, 2
  FROM public.menu_categorias c WHERE c.nombre = 'Tostadas Especiales'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '2 tostadas 250g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial Santa Cruz'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 258.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial Santa Cruz' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 258.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial Santa Cruz' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 258.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial Santa Cruz' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 248.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial Santa Cruz' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Especial Santa Cruz con callo de hacha', NULL, false, NULL, 3
  FROM public.menu_categorias c WHERE c.nombre = 'Tostadas Especiales'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '2 tostadas 250g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial Santa Cruz con callo de hacha'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 298.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial Santa Cruz con callo de hacha' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 298.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial Santa Cruz con callo de hacha' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 298.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial Santa Cruz con callo de hacha' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 268.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial Santa Cruz con callo de hacha' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Especial La Ola', 'Mezcla de mariscos con base de ceviche de sierra. ESPECIALIDAD', false, NULL, 4
  FROM public.menu_categorias c WHERE c.nombre = 'Tostadas Especiales'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '2 tostadas 250g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial La Ola'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 248.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial La Ola' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 248.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial La Ola' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 248.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial La Ola' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 248.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial La Ola' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Especial La Ola con paté de camarón', 'Mezcla de mariscos con base de paté de camarón', false, NULL, 5
  FROM public.menu_categorias c WHERE c.nombre = 'Tostadas Especiales'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '2 tostadas 250g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial La Ola con paté de camarón'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 258.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial La Ola con paté de camarón' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 258.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial La Ola con paté de camarón' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 258.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial La Ola con paté de camarón' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 258.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial La Ola con paté de camarón' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Especial de paté de camarón', 'Camarón cocido con base de paté de camarón', false, NULL, 6
  FROM public.menu_categorias c WHERE c.nombre = 'Tostadas Especiales'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '2 tostadas 250g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial de paté de camarón'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 258.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial de paté de camarón' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 258.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial de paté de camarón' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 258.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial de paté de camarón' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 228.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial de paté de camarón' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'San Blas', 'Mezcla de mariscos y callo de hacha con base de ceviche de sierra. RECOMENDADA', false, NULL, 7
  FROM public.menu_categorias c WHERE c.nombre = 'Tostadas Especiales'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '2 tostadas 250g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'San Blas'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'San Blas' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'San Blas' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'San Blas' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 268.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'San Blas' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'San Blas con paté de camarón', NULL, false, NULL, 8
  FROM public.menu_categorias c WHERE c.nombre = 'Tostadas Especiales'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '2 tostadas 250g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'San Blas con paté de camarón'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 298.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'San Blas con paté de camarón' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 298.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'San Blas con paté de camarón' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 298.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'San Blas con paté de camarón' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 268.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'San Blas con paté de camarón' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Especial de ceviche La Ola', 'Mezcla de ceviches de camarón curtido camarón cocido y pulpo', false, NULL, 9
  FROM public.menu_categorias c WHERE c.nombre = 'Tostadas Especiales'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '2 tostadas 250g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial de ceviche La Ola'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 238.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial de ceviche La Ola' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 238.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial de ceviche La Ola' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 238.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial de ceviche La Ola' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 228.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial de ceviche La Ola' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Especial de ceviche San Blas', 'Mezcla de ceviches con callo de hacha', false, NULL, 10
  FROM public.menu_categorias c WHERE c.nombre = 'Tostadas Especiales'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '2 tostadas 250g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial de ceviche San Blas'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 268.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial de ceviche San Blas' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 268.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial de ceviche San Blas' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 268.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial de ceviche San Blas' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 248.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial de ceviche San Blas' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Especial Matanchen', 'Mezcla de mariscos sobre tostadas con mayonesa y base de ceviche de sierra. En Solares incluye callo de hacha', false, NULL, 11
  FROM public.menu_categorias c WHERE c.nombre = 'Tostadas Especiales'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '2 tostadas 250g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial Matanchen'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 248.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial Matanchen' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 248.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial Matanchen' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 248.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial Matanchen' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 268.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial Matanchen' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Especial Matanchen con callo de hacha', NULL, false, NULL, 12
  FROM public.menu_categorias c WHERE c.nombre = 'Tostadas Especiales'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '2 tostadas 250g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial Matanchen con callo de hacha'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial Matanchen con callo de hacha' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial Matanchen con callo de hacha' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial Matanchen con callo de hacha' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Mexcalteca', 'Camarón seco y camarón en aguachile', false, NULL, 13
  FROM public.menu_categorias c WHERE c.nombre = 'Tostadas Especiales'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '2 tostadas 200g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Mexcalteca'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 228.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Mexcalteca' AND v.nombre = '2 tostadas 200g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Especial del Pacífico', 'Ceviche de sierra montado con callo de hacha de Sonora', false, NULL, 14
  FROM public.menu_categorias c WHERE c.nombre = 'Tostadas Especiales'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '2 tostadas 200g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial del Pacífico'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 296.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial del Pacífico' AND v.nombre = '2 tostadas 200g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;

-- ===== Cazuelitas =====
INSERT INTO public.menu_categorias (nombre, orden) VALUES ('Cazuelitas', 6) ON CONFLICT (nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Cazuelita de camarón cocido', 'Jugo caliente. Solares porción única 250g', false, NULL, 0
  FROM public.menu_categorias c WHERE c.nombre = 'Cazuelitas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 200g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita de camarón cocido'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita de camarón cocido' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita de camarón cocido' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita de camarón cocido' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 228.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita de camarón cocido' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 300g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita de camarón cocido'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita de camarón cocido' AND v.nombre = 'Grande 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita de camarón cocido' AND v.nombre = 'Grande 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita de camarón cocido' AND v.nombre = 'Grande 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Cazuelita de pulpo', NULL, false, NULL, 1
  FROM public.menu_categorias c WHERE c.nombre = 'Cazuelitas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 200g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita de pulpo'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita de pulpo' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita de pulpo' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita de pulpo' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 228.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita de pulpo' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 300g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita de pulpo'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita de pulpo' AND v.nombre = 'Grande 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita de pulpo' AND v.nombre = 'Grande 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita de pulpo' AND v.nombre = 'Grande 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Cazuelita mixta', 'Camarón y pulpo', false, NULL, 2
  FROM public.menu_categorias c WHERE c.nombre = 'Cazuelitas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 200g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita mixta'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita mixta' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita mixta' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita mixta' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 228.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita mixta' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 300g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita mixta'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita mixta' AND v.nombre = 'Grande 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita mixta' AND v.nombre = 'Grande 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita mixta' AND v.nombre = 'Grande 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Cazuelita La Ola', 'Camarón cocido pulpo y ostión', false, NULL, 3
  FROM public.menu_categorias c WHERE c.nombre = 'Cazuelitas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 200g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita La Ola'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita La Ola' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita La Ola' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita La Ola' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 228.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita La Ola' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 300g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita La Ola'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita La Ola' AND v.nombre = 'Grande 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita La Ola' AND v.nombre = 'Grande 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita La Ola' AND v.nombre = 'Grande 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Cazuelita especial Tanilo', 'Camarón cocido pulpo y ceviche de sierra', false, NULL, 4
  FROM public.menu_categorias c WHERE c.nombre = 'Cazuelitas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 200g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita especial Tanilo'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita especial Tanilo' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita especial Tanilo' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita especial Tanilo' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 228.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita especial Tanilo' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 300g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita especial Tanilo'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita especial Tanilo' AND v.nombre = 'Grande 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita especial Tanilo' AND v.nombre = 'Grande 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita especial Tanilo' AND v.nombre = 'Grande 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Cazuelita especial San Blas', 'Camarón cocido pulpo ostión y callo de hacha', false, NULL, 5
  FROM public.menu_categorias c WHERE c.nombre = 'Cazuelitas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 200g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita especial San Blas'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 238.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita especial San Blas' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 238.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita especial San Blas' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 238.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita especial San Blas' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 268.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita especial San Blas' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 300g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita especial San Blas'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 298.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita especial San Blas' AND v.nombre = 'Grande 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 298.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita especial San Blas' AND v.nombre = 'Grande 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 298.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita especial San Blas' AND v.nombre = 'Grande 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;

-- ===== Cocteles =====
INSERT INTO public.menu_categorias (nombre, orden) VALUES ('Cocteles', 7) ON CONFLICT (nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Vaso loco', 'Camarón curtido en limón sazonado con salsa huichol. Solares porción única 250g', false, NULL, 0
  FROM public.menu_categorias c WHERE c.nombre = 'Cocteles'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 200g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Vaso loco'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Vaso loco' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Vaso loco' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Vaso loco' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 228.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Vaso loco' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 300g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Vaso loco'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Vaso loco' AND v.nombre = 'Grande 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Vaso loco' AND v.nombre = 'Grande 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Vaso loco' AND v.nombre = 'Grande 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Vaso loco especial', 'Camarón curtido y callo de hacha con salsa huichol', false, NULL, 1
  FROM public.menu_categorias c WHERE c.nombre = 'Cocteles'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 200g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Vaso loco especial'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 238.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Vaso loco especial' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 238.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Vaso loco especial' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 238.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Vaso loco especial' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 268.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Vaso loco especial' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 300g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Vaso loco especial'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 298.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Vaso loco especial' AND v.nombre = 'Grande 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 298.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Vaso loco especial' AND v.nombre = 'Grande 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 298.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Vaso loco especial' AND v.nombre = 'Grande 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Vaso macho', 'Camarón curtido y ostión con salsa habanera', false, NULL, 2
  FROM public.menu_categorias c WHERE c.nombre = 'Cocteles'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 200g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Vaso macho'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Vaso macho' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Vaso macho' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Vaso macho' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 228.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Vaso macho' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 300g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Vaso macho'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Vaso macho' AND v.nombre = 'Grande 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Vaso macho' AND v.nombre = 'Grande 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Vaso macho' AND v.nombre = 'Grande 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Vaso macho especial', 'Camarón curtido ostión y callo de hacha con salsa habanera', false, NULL, 3
  FROM public.menu_categorias c WHERE c.nombre = 'Cocteles'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 200g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Vaso macho especial'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 238.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Vaso macho especial' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 238.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Vaso macho especial' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 238.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Vaso macho especial' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 268.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Vaso macho especial' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 300g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Vaso macho especial'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 298.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Vaso macho especial' AND v.nombre = 'Grande 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 298.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Vaso macho especial' AND v.nombre = 'Grande 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 298.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Vaso macho especial' AND v.nombre = 'Grande 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Clamariscos', 'Camarón cocido pulpo y ostión con Clamato preparado. En Solares incluye callo de hacha', false, NULL, 4
  FROM public.menu_categorias c WHERE c.nombre = 'Cocteles'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 200g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Clamariscos'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Clamariscos' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Clamariscos' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Clamariscos' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 268.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Clamariscos' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 300g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Clamariscos'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Clamariscos' AND v.nombre = 'Grande 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Clamariscos' AND v.nombre = 'Grande 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Clamariscos' AND v.nombre = 'Grande 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Clamariscos con callo de hacha', NULL, false, NULL, 5
  FROM public.menu_categorias c WHERE c.nombre = 'Cocteles'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 200g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Clamariscos con callo de hacha'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 238.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Clamariscos con callo de hacha' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 238.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Clamariscos con callo de hacha' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 238.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Clamariscos con callo de hacha' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 300g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Clamariscos con callo de hacha'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 298.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Clamariscos con callo de hacha' AND v.nombre = 'Grande 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 298.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Clamariscos con callo de hacha' AND v.nombre = 'Grande 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 298.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Clamariscos con callo de hacha' AND v.nombre = 'Grande 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Clamacallo', 'Clamato y callo de hacha', false, NULL, 6
  FROM public.menu_categorias c WHERE c.nombre = 'Cocteles'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Única 250g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Clamacallo'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 468.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Clamacallo' AND v.nombre = 'Única 250g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Chilangada', 'Camarón cocido pulpo y ostión con jugo de camarón frío y catsup. En Solares incluye callo de hacha', false, NULL, 7
  FROM public.menu_categorias c WHERE c.nombre = 'Cocteles'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 200g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Chilangada'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Chilangada' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Chilangada' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Chilangada' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 268.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Chilangada' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 300g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Chilangada'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Chilangada' AND v.nombre = 'Grande 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Chilangada' AND v.nombre = 'Grande 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Chilangada' AND v.nombre = 'Grande 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Chilangada con callo de hacha', NULL, false, NULL, 8
  FROM public.menu_categorias c WHERE c.nombre = 'Cocteles'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 200g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Chilangada con callo de hacha'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 238.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Chilangada con callo de hacha' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 238.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Chilangada con callo de hacha' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 238.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Chilangada con callo de hacha' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 300g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Chilangada con callo de hacha'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 298.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Chilangada con callo de hacha' AND v.nombre = 'Grande 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 298.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Chilangada con callo de hacha' AND v.nombre = 'Grande 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 298.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Chilangada con callo de hacha' AND v.nombre = 'Grande 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Coctel de camarón', 'Camarón cocido con pepino cebolla jugo de camarón frío y catsup', false, NULL, 9
  FROM public.menu_categorias c WHERE c.nombre = 'Cocteles'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 200g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Coctel de camarón'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Coctel de camarón' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Coctel de camarón' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 300g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Coctel de camarón'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Coctel de camarón' AND v.nombre = 'Grande 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Coctel de camarón' AND v.nombre = 'Grande 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Coctel de pulpo', NULL, false, NULL, 10
  FROM public.menu_categorias c WHERE c.nombre = 'Cocteles'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 200g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Coctel de pulpo'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Coctel de pulpo' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Coctel de pulpo' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 300g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Coctel de pulpo'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Coctel de pulpo' AND v.nombre = 'Grande 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Coctel de pulpo' AND v.nombre = 'Grande 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Coctel de ostión', 'Ostión de placer sancochado al natural', false, NULL, 11
  FROM public.menu_categorias c WHERE c.nombre = 'Cocteles'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 200g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Coctel de ostión'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Coctel de ostión' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Coctel de ostión' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 148.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Coctel de ostión' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 208.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Coctel de ostión' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 300g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Coctel de ostión'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Coctel de ostión' AND v.nombre = 'Grande 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Coctel de ostión' AND v.nombre = 'Grande 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Coctel de ostión' AND v.nombre = 'Grande 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Campechana fría', 'Camarón cocido pulpo y ostión con aguacate pepino y cebolla', false, NULL, 12
  FROM public.menu_categorias c WHERE c.nombre = 'Cocteles'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 200g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Campechana fría'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Campechana fría' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Campechana fría' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 300g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Campechana fría'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Campechana fría' AND v.nombre = 'Grande 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Campechana fría' AND v.nombre = 'Grande 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;

-- ===== Ceviches =====
INSERT INTO public.menu_categorias (nombre, orden) VALUES ('Ceviches', 8) ON CONFLICT (nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Ceviche de sierra estilo Nayarit', 'Solares porción única 300g', false, NULL, 0
  FROM public.menu_categorias c WHERE c.nombre = 'Ceviches'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de sierra estilo Nayarit'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 178.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de sierra estilo Nayarit' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 178.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de sierra estilo Nayarit' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 178.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de sierra estilo Nayarit' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 208.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de sierra estilo Nayarit' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 400g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de sierra estilo Nayarit'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 208.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de sierra estilo Nayarit' AND v.nombre = 'Grande 400g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 208.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de sierra estilo Nayarit' AND v.nombre = 'Grande 400g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 208.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de sierra estilo Nayarit' AND v.nombre = 'Grande 400g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Ceviche de camarón', 'Camarón curtido en limón con pepino jitomate cebolla cilantro y serrano', false, NULL, 1
  FROM public.menu_categorias c WHERE c.nombre = 'Ceviches'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de camarón'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de camarón' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de camarón' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de camarón' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de camarón' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 400g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de camarón'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de camarón' AND v.nombre = 'Grande 400g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de camarón' AND v.nombre = 'Grande 400g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de camarón' AND v.nombre = 'Grande 400g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Ceviche de camarón cocido', NULL, false, NULL, 2
  FROM public.menu_categorias c WHERE c.nombre = 'Ceviches'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de camarón cocido'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de camarón cocido' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de camarón cocido' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de camarón cocido' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de camarón cocido' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 400g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de camarón cocido'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de camarón cocido' AND v.nombre = 'Grande 400g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de camarón cocido' AND v.nombre = 'Grande 400g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de camarón cocido' AND v.nombre = 'Grande 400g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Ceviche de pulpo', NULL, false, NULL, 3
  FROM public.menu_categorias c WHERE c.nombre = 'Ceviches'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Única 300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de pulpo'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de pulpo' AND v.nombre = 'Única 300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Ceviche especial La Ola', 'Camarón cocido camarón curtido y pulpo', false, NULL, 4
  FROM public.menu_categorias c WHERE c.nombre = 'Ceviches'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche especial La Ola'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche especial La Ola' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche especial La Ola' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche especial La Ola' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche especial La Ola' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 400g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche especial La Ola'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche especial La Ola' AND v.nombre = 'Grande 400g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche especial La Ola' AND v.nombre = 'Grande 400g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche especial La Ola' AND v.nombre = 'Grande 400g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Ceviche de camarón seco', NULL, false, NULL, 5
  FROM public.menu_categorias c WHERE c.nombre = 'Ceviches'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de camarón seco'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de camarón seco' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de camarón seco' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de camarón seco' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de camarón seco' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 400g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de camarón seco'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de camarón seco' AND v.nombre = 'Grande 400g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de camarón seco' AND v.nombre = 'Grande 400g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de camarón seco' AND v.nombre = 'Grande 400g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Ceviche Mexcalteca', 'Camarón crudo y camarón seco', false, NULL, 6
  FROM public.menu_categorias c WHERE c.nombre = 'Ceviches'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Única 300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche Mexcalteca'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche Mexcalteca' AND v.nombre = 'Única 300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Ceviche especial Santa Cruz', 'Camarón cocido camarón curtido pulpo y camarón seco', false, NULL, 7
  FROM public.menu_categorias c WHERE c.nombre = 'Ceviches'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche especial Santa Cruz'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche especial Santa Cruz' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche especial Santa Cruz' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche especial Santa Cruz' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche especial Santa Cruz' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 400g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche especial Santa Cruz'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche especial Santa Cruz' AND v.nombre = 'Grande 400g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche especial Santa Cruz' AND v.nombre = 'Grande 400g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche especial Santa Cruz' AND v.nombre = 'Grande 400g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Ceviche Santa Cruz + callo de hacha', NULL, false, NULL, 8
  FROM public.menu_categorias c WHERE c.nombre = 'Ceviches'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche Santa Cruz + callo de hacha'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche Santa Cruz + callo de hacha' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche Santa Cruz + callo de hacha' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche Santa Cruz + callo de hacha' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 362.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche Santa Cruz + callo de hacha' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 400g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche Santa Cruz + callo de hacha'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 468.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche Santa Cruz + callo de hacha' AND v.nombre = 'Grande 400g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 468.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche Santa Cruz + callo de hacha' AND v.nombre = 'Grande 400g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 468.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche Santa Cruz + callo de hacha' AND v.nombre = 'Grande 400g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Ceviche de róbalo', 'Filete de róbalo fresco en cuadritos con toque de habanero', false, NULL, 9
  FROM public.menu_categorias c WHERE c.nombre = 'Ceviches'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de róbalo'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 378.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de róbalo' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 378.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de róbalo' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 378.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de róbalo' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 362.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de róbalo' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 400g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de róbalo'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 458.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de róbalo' AND v.nombre = 'Grande 400g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 458.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de róbalo' AND v.nombre = 'Grande 400g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 458.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de róbalo' AND v.nombre = 'Grande 400g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Ceviche San Blas', 'Camarón cocido camarón curtido pulpo y callo de hacha', false, NULL, 10
  FROM public.menu_categorias c WHERE c.nombre = 'Ceviches'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche San Blas'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche San Blas' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche San Blas' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche San Blas' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 362.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche San Blas' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 400g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche San Blas'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 468.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche San Blas' AND v.nombre = 'Grande 400g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 468.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche San Blas' AND v.nombre = 'Grande 400g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 468.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche San Blas' AND v.nombre = 'Grande 400g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Ceviche de atún', 'Atún fresco en cubos bañado en salsas negras. En Solares: Negro de atún', false, NULL, 11
  FROM public.menu_categorias c WHERE c.nombre = 'Ceviches'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de atún'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 378.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de atún' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 378.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de atún' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 378.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de atún' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 362.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de atún' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 400g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de atún'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 458.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de atún' AND v.nombre = 'Grande 400g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 458.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de atún' AND v.nombre = 'Grande 400g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 458.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de atún' AND v.nombre = 'Grande 400g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;

-- ===== Ensaladas =====
INSERT INTO public.menu_categorias (nombre, orden) VALUES ('Ensaladas', 9) ON CONFLICT (nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Ensalada de camarón cocido', 'Pídela al natural salseada o bañada con chiltepín. Solares porción única 300g', false, '{"estilo":["Al natural","Salseada","Bañada con chiltepín"]}'::jsonb, 0
  FROM public.menu_categorias c WHERE c.nombre = 'Ensaladas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada de camarón cocido'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada de camarón cocido' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada de camarón cocido' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada de camarón cocido' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada de camarón cocido' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 400g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada de camarón cocido'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada de camarón cocido' AND v.nombre = 'Grande 400g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada de camarón cocido' AND v.nombre = 'Grande 400g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada de camarón cocido' AND v.nombre = 'Grande 400g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Ensalada de pulpo', NULL, false, '{"estilo":["Al natural","Salseada","Bañada con chiltepín"]}'::jsonb, 1
  FROM public.menu_categorias c WHERE c.nombre = 'Ensaladas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada de pulpo'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada de pulpo' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada de pulpo' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada de pulpo' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada de pulpo' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 400g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada de pulpo'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada de pulpo' AND v.nombre = 'Grande 400g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada de pulpo' AND v.nombre = 'Grande 400g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada de pulpo' AND v.nombre = 'Grande 400g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Ensalada mixta', 'Camarón y pulpo', false, '{"estilo":["Al natural","Salseada","Bañada con chiltepín"]}'::jsonb, 2
  FROM public.menu_categorias c WHERE c.nombre = 'Ensaladas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada mixta'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada mixta' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada mixta' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada mixta' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada mixta' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 400g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada mixta'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada mixta' AND v.nombre = 'Grande 400g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada mixta' AND v.nombre = 'Grande 400g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada mixta' AND v.nombre = 'Grande 400g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Ensalada especial La Ola', 'Camarón cocido camarón curtido y pulpo', false, '{"estilo":["Al natural","Salseada","Bañada con chiltepín"]}'::jsonb, 3
  FROM public.menu_categorias c WHERE c.nombre = 'Ensaladas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada especial La Ola'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada especial La Ola' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada especial La Ola' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada especial La Ola' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada especial La Ola' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 400g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada especial La Ola'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada especial La Ola' AND v.nombre = 'Grande 400g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada especial La Ola' AND v.nombre = 'Grande 400g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada especial La Ola' AND v.nombre = 'Grande 400g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Ensalada especial San Blas', 'Con callo de hacha', false, '{"estilo":["Al natural","Salseada","Bañada con chiltepín"]}'::jsonb, 4
  FROM public.menu_categorias c WHERE c.nombre = 'Ensaladas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada especial San Blas'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 388.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada especial San Blas' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 388.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada especial San Blas' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 388.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada especial San Blas' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 362.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada especial San Blas' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 400g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada especial San Blas'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 468.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada especial San Blas' AND v.nombre = 'Grande 400g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 468.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada especial San Blas' AND v.nombre = 'Grande 400g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 468.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada especial San Blas' AND v.nombre = 'Grande 400g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Ensalada de callo de hacha', NULL, false, '{"estilo":["Al natural","Salseada","Bañada con chiltepín"]}'::jsonb, 5
  FROM public.menu_categorias c WHERE c.nombre = 'Ensaladas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada de callo de hacha'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 598.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada de callo de hacha' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 598.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada de callo de hacha' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 598.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada de callo de hacha' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 688.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada de callo de hacha' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 400g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada de callo de hacha'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 798.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada de callo de hacha' AND v.nombre = 'Grande 400g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 798.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada de callo de hacha' AND v.nombre = 'Grande 400g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 798.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada de callo de hacha' AND v.nombre = 'Grande 400g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;

-- ===== Aguachiles =====
INSERT INTO public.menu_categorias (nombre, orden) VALUES ('Aguachiles', 10) ON CONFLICT (nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Aguachile de camarón', 'Pídelo tradicional verde rojo de chiltepín o negro salseado. Solares porción única 300g', false, '{"estilo":["Tradicional verde","Rojo de chiltepín","Negro salseado"]}'::jsonb, 0
  FROM public.menu_categorias c WHERE c.nombre = 'Aguachiles'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de camarón'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de camarón' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de camarón' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de camarón' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de camarón' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 400g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de camarón'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de camarón' AND v.nombre = 'Grande 400g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de camarón' AND v.nombre = 'Grande 400g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de camarón' AND v.nombre = 'Grande 400g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Aguachile de camarón cocido', NULL, false, '{"estilo":["Tradicional verde","Rojo de chiltepín","Negro salseado"]}'::jsonb, 1
  FROM public.menu_categorias c WHERE c.nombre = 'Aguachiles'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de camarón cocido'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de camarón cocido' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de camarón cocido' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de camarón cocido' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de camarón cocido' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 400g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de camarón cocido'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de camarón cocido' AND v.nombre = 'Grande 400g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de camarón cocido' AND v.nombre = 'Grande 400g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de camarón cocido' AND v.nombre = 'Grande 400g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Aguachile de pulpo', NULL, false, '{"estilo":["Tradicional verde","Rojo de chiltepín","Negro salseado"]}'::jsonb, 2
  FROM public.menu_categorias c WHERE c.nombre = 'Aguachiles'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de pulpo'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de pulpo' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de pulpo' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de pulpo' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de pulpo' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 400g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de pulpo'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de pulpo' AND v.nombre = 'Grande 400g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de pulpo' AND v.nombre = 'Grande 400g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de pulpo' AND v.nombre = 'Grande 400g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Aguachile mixto', 'Camarón y pulpo', false, '{"estilo":["Tradicional verde","Rojo de chiltepín","Negro salseado"]}'::jsonb, 3
  FROM public.menu_categorias c WHERE c.nombre = 'Aguachiles'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile mixto'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile mixto' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile mixto' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile mixto' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile mixto' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 400g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile mixto'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile mixto' AND v.nombre = 'Grande 400g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile mixto' AND v.nombre = 'Grande 400g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile mixto' AND v.nombre = 'Grande 400g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Aguachile Mexcalteca', 'Camarón crudo y camarón seco', false, '{"estilo":["Tradicional verde","Rojo de chiltepín","Negro salseado"]}'::jsonb, 4
  FROM public.menu_categorias c WHERE c.nombre = 'Aguachiles'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Única 300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile Mexcalteca'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile Mexcalteca' AND v.nombre = 'Única 300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Aguachile de camarón seco', NULL, false, '{"estilo":["Tradicional verde","Rojo de chiltepín","Negro salseado"]}'::jsonb, 5
  FROM public.menu_categorias c WHERE c.nombre = 'Aguachiles'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Única 300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de camarón seco'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 332.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de camarón seco' AND v.nombre = 'Única 300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Aguachile especial La Ola', 'Camarón cocido camarón curtido y pulpo', false, '{"estilo":["Tradicional verde","Rojo de chiltepín","Negro salseado"]}'::jsonb, 6
  FROM public.menu_categorias c WHERE c.nombre = 'Aguachiles'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile especial La Ola'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile especial La Ola' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile especial La Ola' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile especial La Ola' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 332.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile especial La Ola' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 400g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile especial La Ola'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile especial La Ola' AND v.nombre = 'Grande 400g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile especial La Ola' AND v.nombre = 'Grande 400g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile especial La Ola' AND v.nombre = 'Grande 400g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Aguachile Santa Cruz', 'Con camarón seco', false, '{"estilo":["Tradicional verde","Rojo de chiltepín","Negro salseado"]}'::jsonb, 7
  FROM public.menu_categorias c WHERE c.nombre = 'Aguachiles'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile Santa Cruz'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile Santa Cruz' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile Santa Cruz' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile Santa Cruz' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 332.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile Santa Cruz' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 400g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile Santa Cruz'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile Santa Cruz' AND v.nombre = 'Grande 400g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile Santa Cruz' AND v.nombre = 'Grande 400g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile Santa Cruz' AND v.nombre = 'Grande 400g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Aguachile Santa Cruz + callo de hacha', NULL, false, '{"estilo":["Tradicional verde","Rojo de chiltepín","Negro salseado"]}'::jsonb, 8
  FROM public.menu_categorias c WHERE c.nombre = 'Aguachiles'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile Santa Cruz + callo de hacha'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 388.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile Santa Cruz + callo de hacha' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 388.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile Santa Cruz + callo de hacha' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 388.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile Santa Cruz + callo de hacha' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 362.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile Santa Cruz + callo de hacha' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 400g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile Santa Cruz + callo de hacha'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 468.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile Santa Cruz + callo de hacha' AND v.nombre = 'Grande 400g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 468.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile Santa Cruz + callo de hacha' AND v.nombre = 'Grande 400g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 468.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile Santa Cruz + callo de hacha' AND v.nombre = 'Grande 400g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Aguachile especial de camarón', 'Camarón cocido curtido y seco', false, '{"estilo":["Tradicional verde","Rojo de chiltepín","Negro salseado"]}'::jsonb, 9
  FROM public.menu_categorias c WHERE c.nombre = 'Aguachiles'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile especial de camarón'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile especial de camarón' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile especial de camarón' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile especial de camarón' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 332.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile especial de camarón' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 400g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile especial de camarón'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile especial de camarón' AND v.nombre = 'Grande 400g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile especial de camarón' AND v.nombre = 'Grande 400g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile especial de camarón' AND v.nombre = 'Grande 400g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Aguachile especial San Blas', 'Con callo de hacha', false, '{"estilo":["Tradicional verde","Rojo de chiltepín","Negro salseado"]}'::jsonb, 10
  FROM public.menu_categorias c WHERE c.nombre = 'Aguachiles'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile especial San Blas'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 388.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile especial San Blas' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 388.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile especial San Blas' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 388.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile especial San Blas' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 362.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile especial San Blas' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 400g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile especial San Blas'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 468.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile especial San Blas' AND v.nombre = 'Grande 400g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 468.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile especial San Blas' AND v.nombre = 'Grande 400g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 468.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile especial San Blas' AND v.nombre = 'Grande 400g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Aguachile de callo de hacha', NULL, false, '{"estilo":["Tradicional verde","Rojo de chiltepín","Negro salseado"]}'::jsonb, 11
  FROM public.menu_categorias c WHERE c.nombre = 'Aguachiles'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de callo de hacha'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 598.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de callo de hacha' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 598.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de callo de hacha' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 598.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de callo de hacha' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 400g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de callo de hacha'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 798.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de callo de hacha' AND v.nombre = 'Grande 400g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 798.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de callo de hacha' AND v.nombre = 'Grande 400g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 798.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de callo de hacha' AND v.nombre = 'Grande 400g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Montado con callo de hacha', 'Callo de hacha montado sobre aguachile de camarón', false, '{"estilo":["Tradicional verde","Rojo de chiltepín","Negro salseado"]}'::jsonb, 12
  FROM public.menu_categorias c WHERE c.nombre = 'Aguachiles'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Montado con callo de hacha'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 438.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Montado con callo de hacha' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 438.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Montado con callo de hacha' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 438.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Montado con callo de hacha' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 362.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Montado con callo de hacha' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 400g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Montado con callo de hacha'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 498.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Montado con callo de hacha' AND v.nombre = 'Grande 400g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 498.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Montado con callo de hacha' AND v.nombre = 'Grande 400g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 498.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Montado con callo de hacha' AND v.nombre = 'Grande 400g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;

-- ===== Camarones =====
INSERT INTO public.menu_categorias (nombre, orden) VALUES ('Camarones', 11) ON CONFLICT (nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Camarones a la diabla', 'Pídelos suaves normales o picantes. Acompañados de papas arroz y plátano frito', false, '{"preparacion":["Suave","Normal","Picante"]}'::jsonb, 0
  FROM public.menu_categorias c WHERE c.nombre = 'Camarones'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones a la diabla'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones a la diabla' AND v.nombre = '300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones a la diabla' AND v.nombre = '300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones a la diabla' AND v.nombre = '300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones a la diabla' AND v.nombre = '300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Camarones a la plancha', NULL, false, NULL, 1
  FROM public.menu_categorias c WHERE c.nombre = 'Camarones'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones a la plancha'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones a la plancha' AND v.nombre = '300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones a la plancha' AND v.nombre = '300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones a la plancha' AND v.nombre = '300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones a la plancha' AND v.nombre = '300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Camarones a la mantequilla', NULL, false, NULL, 2
  FROM public.menu_categorias c WHERE c.nombre = 'Camarones'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones a la mantequilla'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones a la mantequilla' AND v.nombre = '300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones a la mantequilla' AND v.nombre = '300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones a la mantequilla' AND v.nombre = '300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones a la mantequilla' AND v.nombre = '300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Camarones al mojo de ajo', NULL, false, NULL, 3
  FROM public.menu_categorias c WHERE c.nombre = 'Camarones'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones al mojo de ajo'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones al mojo de ajo' AND v.nombre = '300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones al mojo de ajo' AND v.nombre = '300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones al mojo de ajo' AND v.nombre = '300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones al mojo de ajo' AND v.nombre = '300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Camarones al coco', NULL, false, NULL, 4
  FROM public.menu_categorias c WHERE c.nombre = 'Camarones'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones al coco'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones al coco' AND v.nombre = '300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones al coco' AND v.nombre = '300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones al coco' AND v.nombre = '300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones al coco' AND v.nombre = '300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Camarones al ajillo', NULL, false, NULL, 5
  FROM public.menu_categorias c WHERE c.nombre = 'Camarones'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones al ajillo'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones al ajillo' AND v.nombre = '300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones al ajillo' AND v.nombre = '300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones al ajillo' AND v.nombre = '300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones al ajillo' AND v.nombre = '300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Camarones empanizados', NULL, false, NULL, 6
  FROM public.menu_categorias c WHERE c.nombre = 'Camarones'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones empanizados'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones empanizados' AND v.nombre = '300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones empanizados' AND v.nombre = '300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones empanizados' AND v.nombre = '300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones empanizados' AND v.nombre = '300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Momias Coras', 'Camarón con queso envueltos en tocino', false, NULL, 7
  FROM public.menu_categorias c WHERE c.nombre = 'Camarones'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Momias Coras'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Momias Coras' AND v.nombre = '300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Momias Coras' AND v.nombre = '300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Momias Coras' AND v.nombre = '300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Momias Coras' AND v.nombre = '300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Camarones Philadelphia', 'Rellenos de queso philadelphia empanizados con panko', false, NULL, 8
  FROM public.menu_categorias c WHERE c.nombre = 'Camarones'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones Philadelphia'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones Philadelphia' AND v.nombre = '300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones Philadelphia' AND v.nombre = '300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones Philadelphia' AND v.nombre = '300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Camarones a la Frank', 'Cremosos con mezcla de philadelphia y cheddar', false, NULL, 9
  FROM public.menu_categorias c WHERE c.nombre = 'Camarones'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones a la Frank'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones a la Frank' AND v.nombre = '300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones a la Frank' AND v.nombre = '300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones a la Frank' AND v.nombre = '300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones a la Frank' AND v.nombre = '300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;

-- ===== Pulpo =====
INSERT INTO public.menu_categorias (nombre, orden) VALUES ('Pulpo', 12) ON CONFLICT (nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Pulpo a la diabla', 'Pulpo maya premium. Acompañado de papas arroz y plátano frito', false, '{"preparacion":["Suave","Normal","Picante"]}'::jsonb, 0
  FROM public.menu_categorias c WHERE c.nombre = 'Pulpo'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Pulpo' AND i.nombre = 'Pulpo a la diabla'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pulpo' AND i.nombre = 'Pulpo a la diabla' AND v.nombre = '300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pulpo' AND i.nombre = 'Pulpo a la diabla' AND v.nombre = '300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pulpo' AND i.nombre = 'Pulpo a la diabla' AND v.nombre = '300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pulpo' AND i.nombre = 'Pulpo a la diabla' AND v.nombre = '300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Pulpo a la plancha', NULL, false, NULL, 1
  FROM public.menu_categorias c WHERE c.nombre = 'Pulpo'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Pulpo' AND i.nombre = 'Pulpo a la plancha'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pulpo' AND i.nombre = 'Pulpo a la plancha' AND v.nombre = '300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pulpo' AND i.nombre = 'Pulpo a la plancha' AND v.nombre = '300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pulpo' AND i.nombre = 'Pulpo a la plancha' AND v.nombre = '300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pulpo' AND i.nombre = 'Pulpo a la plancha' AND v.nombre = '300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Pulpo a la mantequilla', NULL, false, NULL, 2
  FROM public.menu_categorias c WHERE c.nombre = 'Pulpo'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Pulpo' AND i.nombre = 'Pulpo a la mantequilla'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pulpo' AND i.nombre = 'Pulpo a la mantequilla' AND v.nombre = '300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pulpo' AND i.nombre = 'Pulpo a la mantequilla' AND v.nombre = '300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pulpo' AND i.nombre = 'Pulpo a la mantequilla' AND v.nombre = '300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pulpo' AND i.nombre = 'Pulpo a la mantequilla' AND v.nombre = '300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Pulpo al mojo de ajo', NULL, false, NULL, 3
  FROM public.menu_categorias c WHERE c.nombre = 'Pulpo'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Pulpo' AND i.nombre = 'Pulpo al mojo de ajo'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pulpo' AND i.nombre = 'Pulpo al mojo de ajo' AND v.nombre = '300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pulpo' AND i.nombre = 'Pulpo al mojo de ajo' AND v.nombre = '300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pulpo' AND i.nombre = 'Pulpo al mojo de ajo' AND v.nombre = '300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pulpo' AND i.nombre = 'Pulpo al mojo de ajo' AND v.nombre = '300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Pulpo al ajillo', 'Ajo chile de árbol y aceite de oliva', false, NULL, 4
  FROM public.menu_categorias c WHERE c.nombre = 'Pulpo'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Pulpo' AND i.nombre = 'Pulpo al ajillo'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pulpo' AND i.nombre = 'Pulpo al ajillo' AND v.nombre = '300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pulpo' AND i.nombre = 'Pulpo al ajillo' AND v.nombre = '300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pulpo' AND i.nombre = 'Pulpo al ajillo' AND v.nombre = '300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pulpo' AND i.nombre = 'Pulpo al ajillo' AND v.nombre = '300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;

-- ===== Filete de Róbalo =====
INSERT INTO public.menu_categorias (nombre, orden) VALUES ('Filete de Róbalo', 13) ON CONFLICT (nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Filete a la diabla', 'Acompañado de papas arroz y plátano frito', false, '{"preparacion":["Suave","Normal","Picante"]}'::jsonb, 0
  FROM public.menu_categorias c WHERE c.nombre = 'Filete de Róbalo'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Filete de Róbalo' AND i.nombre = 'Filete a la diabla'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Filete de Róbalo' AND i.nombre = 'Filete a la diabla' AND v.nombre = '300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Filete de Róbalo' AND i.nombre = 'Filete a la diabla' AND v.nombre = '300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Filete de Róbalo' AND i.nombre = 'Filete a la diabla' AND v.nombre = '300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Filete de Róbalo' AND i.nombre = 'Filete a la diabla' AND v.nombre = '300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Filete a la plancha', NULL, false, NULL, 1
  FROM public.menu_categorias c WHERE c.nombre = 'Filete de Róbalo'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Filete de Róbalo' AND i.nombre = 'Filete a la plancha'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Filete de Róbalo' AND i.nombre = 'Filete a la plancha' AND v.nombre = '300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Filete de Róbalo' AND i.nombre = 'Filete a la plancha' AND v.nombre = '300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Filete de Róbalo' AND i.nombre = 'Filete a la plancha' AND v.nombre = '300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Filete de Róbalo' AND i.nombre = 'Filete a la plancha' AND v.nombre = '300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Filete a la mantequilla', NULL, false, NULL, 2
  FROM public.menu_categorias c WHERE c.nombre = 'Filete de Róbalo'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Filete de Róbalo' AND i.nombre = 'Filete a la mantequilla'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Filete de Róbalo' AND i.nombre = 'Filete a la mantequilla' AND v.nombre = '300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Filete de Róbalo' AND i.nombre = 'Filete a la mantequilla' AND v.nombre = '300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Filete de Róbalo' AND i.nombre = 'Filete a la mantequilla' AND v.nombre = '300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Filete de Róbalo' AND i.nombre = 'Filete a la mantequilla' AND v.nombre = '300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Filete al mojo de ajo', NULL, false, NULL, 3
  FROM public.menu_categorias c WHERE c.nombre = 'Filete de Róbalo'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Filete de Róbalo' AND i.nombre = 'Filete al mojo de ajo'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Filete de Róbalo' AND i.nombre = 'Filete al mojo de ajo' AND v.nombre = '300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Filete de Róbalo' AND i.nombre = 'Filete al mojo de ajo' AND v.nombre = '300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Filete de Róbalo' AND i.nombre = 'Filete al mojo de ajo' AND v.nombre = '300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Filete de Róbalo' AND i.nombre = 'Filete al mojo de ajo' AND v.nombre = '300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Filete empanizado', NULL, false, NULL, 4
  FROM public.menu_categorias c WHERE c.nombre = 'Filete de Róbalo'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Filete de Róbalo' AND i.nombre = 'Filete empanizado'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Filete de Róbalo' AND i.nombre = 'Filete empanizado' AND v.nombre = '300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Filete de Róbalo' AND i.nombre = 'Filete empanizado' AND v.nombre = '300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Filete de Róbalo' AND i.nombre = 'Filete empanizado' AND v.nombre = '300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Filete de Róbalo' AND i.nombre = 'Filete empanizado' AND v.nombre = '300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Filete al ajillo', NULL, false, NULL, 5
  FROM public.menu_categorias c WHERE c.nombre = 'Filete de Róbalo'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Filete de Róbalo' AND i.nombre = 'Filete al ajillo'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Filete de Róbalo' AND i.nombre = 'Filete al ajillo' AND v.nombre = '300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Filete de Róbalo' AND i.nombre = 'Filete al ajillo' AND v.nombre = '300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Filete de Róbalo' AND i.nombre = 'Filete al ajillo' AND v.nombre = '300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Filete de Róbalo' AND i.nombre = 'Filete al ajillo' AND v.nombre = '300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Filete especial del Rey', 'Róbalo con camarón pulpo y queso cheddar', false, NULL, 6
  FROM public.menu_categorias c WHERE c.nombre = 'Filete de Róbalo'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Filete de Róbalo' AND i.nombre = 'Filete especial del Rey'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Filete de Róbalo' AND i.nombre = 'Filete especial del Rey' AND v.nombre = '300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Filete de Róbalo' AND i.nombre = 'Filete especial del Rey' AND v.nombre = '300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Filete de Róbalo' AND i.nombre = 'Filete especial del Rey' AND v.nombre = '300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Filete de Róbalo' AND i.nombre = 'Filete especial del Rey' AND v.nombre = '300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;

-- ===== Zarandeados =====
INSERT INTO public.menu_categorias (nombre, orden) VALUES ('Zarandeados', 14) ON CONFLICT (nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Pescado zarandeado (róbalo)', 'Solo en menú Del Valle', false, NULL, 0
  FROM public.menu_categorias c WHERE c.nombre = 'Zarandeados'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '1/2 kg', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Zarandeados' AND i.nombre = 'Pescado zarandeado (róbalo)'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 228.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Zarandeados' AND i.nombre = 'Pescado zarandeado (róbalo)' AND v.nombre = '1/2 kg' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '1 kg', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Zarandeados' AND i.nombre = 'Pescado zarandeado (róbalo)'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 428.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Zarandeados' AND i.nombre = 'Pescado zarandeado (róbalo)' AND v.nombre = '1 kg' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Carne zarandeada (filete de res)', NULL, false, NULL, 1
  FROM public.menu_categorias c WHERE c.nombre = 'Zarandeados'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '1/2 kg', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Zarandeados' AND i.nombre = 'Carne zarandeada (filete de res)'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 228.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Zarandeados' AND i.nombre = 'Carne zarandeada (filete de res)' AND v.nombre = '1/2 kg' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '1 kg', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Zarandeados' AND i.nombre = 'Carne zarandeada (filete de res)'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 428.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Zarandeados' AND i.nombre = 'Carne zarandeada (filete de res)' AND v.nombre = '1 kg' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Camarón zarandeado', NULL, false, NULL, 2
  FROM public.menu_categorias c WHERE c.nombre = 'Zarandeados'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '1/2 kg', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Zarandeados' AND i.nombre = 'Camarón zarandeado'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 228.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Zarandeados' AND i.nombre = 'Camarón zarandeado' AND v.nombre = '1/2 kg' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '1 kg', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Zarandeados' AND i.nombre = 'Camarón zarandeado'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 428.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Zarandeados' AND i.nombre = 'Camarón zarandeado' AND v.nombre = '1 kg' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Costilla zarandeada', NULL, false, NULL, 3
  FROM public.menu_categorias c WHERE c.nombre = 'Zarandeados'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '1/2 kg', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Zarandeados' AND i.nombre = 'Costilla zarandeada'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 168.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Zarandeados' AND i.nombre = 'Costilla zarandeada' AND v.nombre = '1/2 kg' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '1 kg', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Zarandeados' AND i.nombre = 'Costilla zarandeada'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 298.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Zarandeados' AND i.nombre = 'Costilla zarandeada' AND v.nombre = '1 kg' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Tasajo de cerdo zarandeado', NULL, false, NULL, 4
  FROM public.menu_categorias c WHERE c.nombre = 'Zarandeados'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '1/2 kg', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Zarandeados' AND i.nombre = 'Tasajo de cerdo zarandeado'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 168.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Zarandeados' AND i.nombre = 'Tasajo de cerdo zarandeado' AND v.nombre = '1/2 kg' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '1 kg', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Zarandeados' AND i.nombre = 'Tasajo de cerdo zarandeado'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 298.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Zarandeados' AND i.nombre = 'Tasajo de cerdo zarandeado' AND v.nombre = '1 kg' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;

-- ===== Manitas de Jaiba =====
INSERT INTO public.menu_categorias (nombre, orden) VALUES ('Manitas de Jaiba', 15) ON CONFLICT (nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Manitas de jaiba', 'A la diabla plancha mantequilla mojo de ajo ajillo o al vapor', false, '{"preparacion":["A la diabla","A la plancha","A la mantequilla","Al mojo de ajo","Al ajillo","Al vapor"]}'::jsonb, 0
  FROM public.menu_categorias c WHERE c.nombre = 'Manitas de Jaiba'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '350g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Manitas de Jaiba' AND i.nombre = 'Manitas de jaiba'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 490.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Manitas de Jaiba' AND i.nombre = 'Manitas de jaiba' AND v.nombre = '350g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;

-- ===== Hamburguesas =====
INSERT INTO public.menu_categorias (nombre, orden) VALUES ('Hamburguesas', 16) ON CONFLICT (nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Hamburguesa de camarón', NULL, false, NULL, 0
  FROM public.menu_categorias c WHERE c.nombre = 'Hamburguesas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '250g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Hamburguesas' AND i.nombre = 'Hamburguesa de camarón'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 202.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Hamburguesas' AND i.nombre = 'Hamburguesa de camarón' AND v.nombre = '250g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Hamburguesa La Ola', 'Camarón y pulpo', false, NULL, 1
  FROM public.menu_categorias c WHERE c.nombre = 'Hamburguesas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '250g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Hamburguesas' AND i.nombre = 'Hamburguesa La Ola'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 202.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Hamburguesas' AND i.nombre = 'Hamburguesa La Ola' AND v.nombre = '250g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;

-- ===== Pizza =====
INSERT INTO public.menu_categorias (nombre, orden) VALUES ('Pizza', 17) ON CONFLICT (nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Pizza de jamón', NULL, false, NULL, 0
  FROM public.menu_categorias c WHERE c.nombre = 'Pizza'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '17 cm', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Pizza' AND i.nombre = 'Pizza de jamón'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pizza' AND i.nombre = 'Pizza de jamón' AND v.nombre = '17 cm' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pizza' AND i.nombre = 'Pizza de jamón' AND v.nombre = '17 cm' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pizza' AND i.nombre = 'Pizza de jamón' AND v.nombre = '17 cm' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Pizza de salchicha', NULL, false, NULL, 1
  FROM public.menu_categorias c WHERE c.nombre = 'Pizza'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '17 cm', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Pizza' AND i.nombre = 'Pizza de salchicha'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pizza' AND i.nombre = 'Pizza de salchicha' AND v.nombre = '17 cm' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pizza' AND i.nombre = 'Pizza de salchicha' AND v.nombre = '17 cm' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pizza' AND i.nombre = 'Pizza de salchicha' AND v.nombre = '17 cm' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Pizza hawaiana', NULL, false, NULL, 2
  FROM public.menu_categorias c WHERE c.nombre = 'Pizza'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '17 cm', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Pizza' AND i.nombre = 'Pizza hawaiana'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pizza' AND i.nombre = 'Pizza hawaiana' AND v.nombre = '17 cm' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pizza' AND i.nombre = 'Pizza hawaiana' AND v.nombre = '17 cm' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pizza' AND i.nombre = 'Pizza hawaiana' AND v.nombre = '17 cm' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Pizza de camarón', NULL, false, NULL, 3
  FROM public.menu_categorias c WHERE c.nombre = 'Pizza'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '17 cm', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Pizza' AND i.nombre = 'Pizza de camarón'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 148.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pizza' AND i.nombre = 'Pizza de camarón' AND v.nombre = '17 cm' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 148.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pizza' AND i.nombre = 'Pizza de camarón' AND v.nombre = '17 cm' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 148.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pizza' AND i.nombre = 'Pizza de camarón' AND v.nombre = '17 cm' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Pizza de camarón con piña', NULL, false, NULL, 4
  FROM public.menu_categorias c WHERE c.nombre = 'Pizza'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '17 cm', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Pizza' AND i.nombre = 'Pizza de camarón con piña'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 148.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pizza' AND i.nombre = 'Pizza de camarón con piña' AND v.nombre = '17 cm' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 148.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pizza' AND i.nombre = 'Pizza de camarón con piña' AND v.nombre = '17 cm' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 148.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pizza' AND i.nombre = 'Pizza de camarón con piña' AND v.nombre = '17 cm' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Pizza de camarones a la diabla', NULL, false, '{"preparacion":["Suave","Normal","Picante"]}'::jsonb, 5
  FROM public.menu_categorias c WHERE c.nombre = 'Pizza'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '17 cm', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Pizza' AND i.nombre = 'Pizza de camarones a la diabla'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 148.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pizza' AND i.nombre = 'Pizza de camarones a la diabla' AND v.nombre = '17 cm' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 148.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pizza' AND i.nombre = 'Pizza de camarones a la diabla' AND v.nombre = '17 cm' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 148.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pizza' AND i.nombre = 'Pizza de camarones a la diabla' AND v.nombre = '17 cm' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;

-- ===== Snacks =====
INSERT INTO public.menu_categorias (nombre, orden) VALUES ('Snacks', 18) ON CONFLICT (nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Boneless', 'BBQ buffalo red hot franks o mango habanero. Con papas a la francesa', false, '{"sabor":["BBQ","Buffalo","Red Hot Frank''s","Mango habanero"]}'::jsonb, 0
  FROM public.menu_categorias c WHERE c.nombre = 'Snacks'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '10 piezas', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Snacks' AND i.nombre = 'Boneless'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 168.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Snacks' AND i.nombre = 'Boneless' AND v.nombre = '10 piezas' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 168.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Snacks' AND i.nombre = 'Boneless' AND v.nombre = '10 piezas' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 168.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Snacks' AND i.nombre = 'Boneless' AND v.nombre = '10 piezas' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 148.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Snacks' AND i.nombre = 'Boneless' AND v.nombre = '10 piezas' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Alitas de pollo', 'BBQ buffalo red hot franks o mango habanero. Con papas a la francesa', false, '{"sabor":["BBQ","Buffalo","Red Hot Frank''s","Mango habanero"]}'::jsonb, 1
  FROM public.menu_categorias c WHERE c.nombre = 'Snacks'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '10 piezas', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Snacks' AND i.nombre = 'Alitas de pollo'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 168.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Snacks' AND i.nombre = 'Alitas de pollo' AND v.nombre = '10 piezas' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Carnes frías', 'Jamón salchicha y queso cheddar en cubos', false, NULL, 2
  FROM public.menu_categorias c WHERE c.nombre = 'Snacks'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '200g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Snacks' AND i.nombre = 'Carnes frías'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 128.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Snacks' AND i.nombre = 'Carnes frías' AND v.nombre = '200g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 128.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Snacks' AND i.nombre = 'Carnes frías' AND v.nombre = '200g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 128.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Snacks' AND i.nombre = 'Carnes frías' AND v.nombre = '200g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 108.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Snacks' AND i.nombre = 'Carnes frías' AND v.nombre = '200g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Papas a la francesa', NULL, false, NULL, 3
  FROM public.menu_categorias c WHERE c.nombre = 'Snacks'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '120g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Snacks' AND i.nombre = 'Papas a la francesa'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 78.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Snacks' AND i.nombre = 'Papas a la francesa' AND v.nombre = '120g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 78.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Snacks' AND i.nombre = 'Papas a la francesa' AND v.nombre = '120g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 78.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Snacks' AND i.nombre = 'Papas a la francesa' AND v.nombre = '120g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 58.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Snacks' AND i.nombre = 'Papas a la francesa' AND v.nombre = '120g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;

-- ===== Menú Infantil =====
INSERT INTO public.menu_categorias (nombre, orden) VALUES ('Menú Infantil', 19) ON CONFLICT (nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Quesadillas natural jamón o salchicha', 'Acompañadas con arroz y papas a la francesa', false, '{"tipo":["Natural","Jamón","Salchicha"]}'::jsonb, 0
  FROM public.menu_categorias c WHERE c.nombre = 'Menú Infantil'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '2 piezas', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Menú Infantil' AND i.nombre = 'Quesadillas natural jamón o salchicha'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 78.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Menú Infantil' AND i.nombre = 'Quesadillas natural jamón o salchicha' AND v.nombre = '2 piezas' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 78.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Menú Infantil' AND i.nombre = 'Quesadillas natural jamón o salchicha' AND v.nombre = '2 piezas' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 78.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Menú Infantil' AND i.nombre = 'Quesadillas natural jamón o salchicha' AND v.nombre = '2 piezas' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 78.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Menú Infantil' AND i.nombre = 'Quesadillas natural jamón o salchicha' AND v.nombre = '2 piezas' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Quesadillas de camarón o pulpo', 'Acompañadas con arroz y papas a la francesa', false, '{"tipo":["Camarón","Pulpo"]}'::jsonb, 1
  FROM public.menu_categorias c WHERE c.nombre = 'Menú Infantil'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '2 piezas', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Menú Infantil' AND i.nombre = 'Quesadillas de camarón o pulpo'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 98.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Menú Infantil' AND i.nombre = 'Quesadillas de camarón o pulpo' AND v.nombre = '2 piezas' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 98.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Menú Infantil' AND i.nombre = 'Quesadillas de camarón o pulpo' AND v.nombre = '2 piezas' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 98.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Menú Infantil' AND i.nombre = 'Quesadillas de camarón o pulpo' AND v.nombre = '2 piezas' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 109.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Menú Infantil' AND i.nombre = 'Quesadillas de camarón o pulpo' AND v.nombre = '2 piezas' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Mini filete al gusto', 'Acompañado con arroz y papas a la francesa', false, NULL, 2
  FROM public.menu_categorias c WHERE c.nombre = 'Menú Infantil'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '100g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Menú Infantil' AND i.nombre = 'Mini filete al gusto'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 128.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Menú Infantil' AND i.nombre = 'Mini filete al gusto' AND v.nombre = '100g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 128.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Menú Infantil' AND i.nombre = 'Mini filete al gusto' AND v.nombre = '100g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 128.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Menú Infantil' AND i.nombre = 'Mini filete al gusto' AND v.nombre = '100g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 152.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Menú Infantil' AND i.nombre = 'Mini filete al gusto' AND v.nombre = '100g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;

-- ===== Postres =====
INSERT INTO public.menu_categorias (nombre, orden) VALUES ('Postres', 20) ON CONFLICT (nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Plátanos fritos', 'Con lechera', false, NULL, 0
  FROM public.menu_categorias c WHERE c.nombre = 'Postres'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '150g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Postres' AND i.nombre = 'Plátanos fritos'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 64.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Postres' AND i.nombre = 'Plátanos fritos' AND v.nombre = '150g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 64.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Postres' AND i.nombre = 'Plátanos fritos' AND v.nombre = '150g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 64.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Postres' AND i.nombre = 'Plátanos fritos' AND v.nombre = '150g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 78.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Postres' AND i.nombre = 'Plátanos fritos' AND v.nombre = '150g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Pay', 'Fresa guayaba o calabaza', false, '{"sabor":["Fresa","Guayaba","Calabaza"]}'::jsonb, 1
  FROM public.menu_categorias c WHERE c.nombre = 'Postres'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '150g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Postres' AND i.nombre = 'Pay'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 64.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Postres' AND i.nombre = 'Pay' AND v.nombre = '150g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 64.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Postres' AND i.nombre = 'Pay' AND v.nombre = '150g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 64.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Postres' AND i.nombre = 'Pay' AND v.nombre = '150g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Flan', 'Cajeta o caramelo', false, '{"sabor":["Cajeta","Caramelo"]}'::jsonb, 2
  FROM public.menu_categorias c WHERE c.nombre = 'Postres'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '150g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Postres' AND i.nombre = 'Flan'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 64.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Postres' AND i.nombre = 'Flan' AND v.nombre = '150g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 64.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Postres' AND i.nombre = 'Flan' AND v.nombre = '150g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 64.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Postres' AND i.nombre = 'Flan' AND v.nombre = '150g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Mini pastel de brownie', NULL, false, NULL, 3
  FROM public.menu_categorias c WHERE c.nombre = 'Postres'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '150g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Postres' AND i.nombre = 'Mini pastel de brownie'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 64.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Postres' AND i.nombre = 'Mini pastel de brownie' AND v.nombre = '150g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 64.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Postres' AND i.nombre = 'Mini pastel de brownie' AND v.nombre = '150g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Pastel red velvet', 'Marisa', false, NULL, 4
  FROM public.menu_categorias c WHERE c.nombre = 'Postres'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '150g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Postres' AND i.nombre = 'Pastel red velvet'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 78.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Postres' AND i.nombre = 'Pastel red velvet' AND v.nombre = '150g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Gelatina de cajeta', 'Marisa', false, NULL, 5
  FROM public.menu_categorias c WHERE c.nombre = 'Postres'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '150g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Postres' AND i.nombre = 'Gelatina de cajeta'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 78.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Postres' AND i.nombre = 'Gelatina de cajeta' AND v.nombre = '150g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Helados Bök', 'Varios sabores', false, NULL, 6
  FROM public.menu_categorias c WHERE c.nombre = 'Postres'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '1 pieza', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Postres' AND i.nombre = 'Helados Bök'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 49.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Postres' AND i.nombre = 'Helados Bök' AND v.nombre = '1 pieza' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;

-- ===== Bebidas sin alcohol =====
INSERT INTO public.menu_categorias (nombre, orden) VALUES ('Bebidas sin alcohol', 21) ON CONFLICT (nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Refresco', 'Coca-Cola Light Sin azúcar Sprite Topo Chico Fresca Fanta Mundet', false, '{"sabor":["Coca-Cola","Coca-Cola Light","Coca-Cola Sin Azúcar","Sprite","Topo Chico","Fresca","Fanta","Mundet"]}'::jsonb, 0
  FROM public.menu_categorias c WHERE c.nombre = 'Bebidas sin alcohol'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '355 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Refresco'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 39.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Refresco' AND v.nombre = '355 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 39.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Refresco' AND v.nombre = '355 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 39.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Refresco' AND v.nombre = '355 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 42.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Refresco' AND v.nombre = '355 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Squirt', NULL, false, NULL, 1
  FROM public.menu_categorias c WHERE c.nombre = 'Bebidas sin alcohol'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '355 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Squirt'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 39.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Squirt' AND v.nombre = '355 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 39.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Squirt' AND v.nombre = '355 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 39.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Squirt' AND v.nombre = '355 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Boost', NULL, false, NULL, 2
  FROM public.menu_categorias c WHERE c.nombre = 'Bebidas sin alcohol'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '235 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Boost'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 39.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Boost' AND v.nombre = '235 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 39.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Boost' AND v.nombre = '235 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 39.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Boost' AND v.nombre = '235 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Agua Delixis', 'Té de jazmín jamaica horchata', false, '{"sabor":["Té de jazmín","Jamaica","Horchata"]}'::jsonb, 3
  FROM public.menu_categorias c WHERE c.nombre = 'Bebidas sin alcohol'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '500 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Agua Delixis'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 39.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Agua Delixis' AND v.nombre = '500 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 39.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Agua Delixis' AND v.nombre = '500 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 39.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Agua Delixis' AND v.nombre = '500 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Agua de sabor', 'Tamarindo jamaica pepino-limón horchata de fresa', false, '{"sabor":["Tamarindo","Jamaica","Pepino-limón","Horchata de fresa"]}'::jsonb, 4
  FROM public.menu_categorias c WHERE c.nombre = 'Bebidas sin alcohol'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '500 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Agua de sabor'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 42.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Agua de sabor' AND v.nombre = '500 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Felix', 'Schorle agua mineral con jugo de frutas', false, NULL, 5
  FROM public.menu_categorias c WHERE c.nombre = 'Bebidas sin alcohol'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '355 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Felix'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 42.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Felix' AND v.nombre = '355 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Fuze tea', NULL, false, NULL, 6
  FROM public.menu_categorias c WHERE c.nombre = 'Bebidas sin alcohol'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '600 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Fuze tea'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 42.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Fuze tea' AND v.nombre = '600 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Agua Ciel embotellada', NULL, false, NULL, 7
  FROM public.menu_categorias c WHERE c.nombre = 'Bebidas sin alcohol'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '600 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Agua Ciel embotellada'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 29.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Agua Ciel embotellada' AND v.nombre = '600 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 29.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Agua Ciel embotellada' AND v.nombre = '600 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 29.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Agua Ciel embotellada' AND v.nombre = '600 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 42.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Agua Ciel embotellada' AND v.nombre = '600 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Café americano', NULL, false, NULL, 8
  FROM public.menu_categorias c WHERE c.nombre = 'Bebidas sin alcohol'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '300 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Café americano'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 39.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Café americano' AND v.nombre = '300 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 39.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Café americano' AND v.nombre = '300 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 39.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Café americano' AND v.nombre = '300 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 52.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Café americano' AND v.nombre = '300 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Limonada / Naranjada', NULL, false, '{"tipo":["Limonada","Naranjada"]}'::jsonb, 9
  FROM public.menu_categorias c WHERE c.nombre = 'Bebidas sin alcohol'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 450 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Limonada / Naranjada'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 49.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Limonada / Naranjada' AND v.nombre = 'Mediano 450 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 49.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Limonada / Naranjada' AND v.nombre = 'Mediano 450 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 49.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Limonada / Naranjada' AND v.nombre = 'Mediano 450 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 62.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Limonada / Naranjada' AND v.nombre = 'Mediano 450 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 900 ml', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Limonada / Naranjada'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 98.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Limonada / Naranjada' AND v.nombre = 'Grande 900 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 98.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Limonada / Naranjada' AND v.nombre = 'Grande 900 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 98.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Limonada / Naranjada' AND v.nombre = 'Grande 900 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Piñada / Fresada', NULL, false, '{"tipo":["Piñada","Fresada"]}'::jsonb, 10
  FROM public.menu_categorias c WHERE c.nombre = 'Bebidas sin alcohol'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 450 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Piñada / Fresada'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 49.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Piñada / Fresada' AND v.nombre = 'Mediano 450 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 49.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Piñada / Fresada' AND v.nombre = 'Mediano 450 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 49.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Piñada / Fresada' AND v.nombre = 'Mediano 450 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 72.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Piñada / Fresada' AND v.nombre = 'Mediano 450 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 900 ml', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Piñada / Fresada'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 98.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Piñada / Fresada' AND v.nombre = 'Grande 900 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 98.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Piñada / Fresada' AND v.nombre = 'Grande 900 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 98.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Piñada / Fresada' AND v.nombre = 'Grande 900 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Agua fresca', NULL, false, NULL, 11
  FROM public.menu_categorias c WHERE c.nombre = 'Bebidas sin alcohol'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 450 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Agua fresca'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 29.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Agua fresca' AND v.nombre = 'Mediano 450 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 29.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Agua fresca' AND v.nombre = 'Mediano 450 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 900 ml', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Agua fresca'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 58.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Agua fresca' AND v.nombre = 'Grande 900 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 58.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Agua fresca' AND v.nombre = 'Grande 900 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Coco natural', NULL, false, NULL, 12
  FROM public.menu_categorias c WHERE c.nombre = 'Bebidas sin alcohol'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '1 pieza', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Coco natural'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 50.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Coco natural' AND v.nombre = '1 pieza' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 80.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Coco natural' AND v.nombre = '1 pieza' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;

-- ===== Bebidas preparadas =====
INSERT INTO public.menu_categorias (nombre, orden) VALUES ('Bebidas preparadas', 22) ON CONFLICT (nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Michelada La Ola', 'Con camarón cocido camarón seco y pulpo', true, NULL, 0
  FROM public.menu_categorias c WHERE c.nombre = 'Bebidas preparadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '120g + 800 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Michelada La Ola'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 178.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Michelada La Ola' AND v.nombre = '120g + 800 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 178.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Michelada La Ola' AND v.nombre = '120g + 800 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 178.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Michelada La Ola' AND v.nombre = '120g + 800 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Cielo rojo / Chelada / Michelada', 'Solares 500 ml', true, '{"tipo":["Cielo rojo","Chelada","Michelada"]}'::jsonb, 1
  FROM public.menu_categorias c WHERE c.nombre = 'Bebidas preparadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 450 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Cielo rojo / Chelada / Michelada'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 52.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Cielo rojo / Chelada / Michelada' AND v.nombre = 'Mediano 450 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 52.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Cielo rojo / Chelada / Michelada' AND v.nombre = 'Mediano 450 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 58.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Cielo rojo / Chelada / Michelada' AND v.nombre = 'Mediano 450 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 72.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Cielo rojo / Chelada / Michelada' AND v.nombre = 'Mediano 450 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 900 ml', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Cielo rojo / Chelada / Michelada'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 104.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Cielo rojo / Chelada / Michelada' AND v.nombre = 'Grande 900 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 104.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Cielo rojo / Chelada / Michelada' AND v.nombre = 'Grande 900 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 116.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Cielo rojo / Chelada / Michelada' AND v.nombre = 'Grande 900 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Michelada salseada', 'Sin clamato', true, NULL, 2
  FROM public.menu_categorias c WHERE c.nombre = 'Bebidas preparadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 450 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Michelada salseada'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 52.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Michelada salseada' AND v.nombre = 'Mediano 450 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 52.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Michelada salseada' AND v.nombre = 'Mediano 450 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 58.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Michelada salseada' AND v.nombre = 'Mediano 450 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 900 ml', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Michelada salseada'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 104.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Michelada salseada' AND v.nombre = 'Grande 900 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 104.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Michelada salseada' AND v.nombre = 'Grande 900 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 116.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Michelada salseada' AND v.nombre = 'Grande 900 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Michelada de sabor', 'Mango piña o tamarindo', true, '{"sabor":["Mango","Piña","Tamarindo"]}'::jsonb, 3
  FROM public.menu_categorias c WHERE c.nombre = 'Bebidas preparadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 450 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Michelada de sabor'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 52.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Michelada de sabor' AND v.nombre = 'Mediano 450 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 52.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Michelada de sabor' AND v.nombre = 'Mediano 450 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 58.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Michelada de sabor' AND v.nombre = 'Mediano 450 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 72.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Michelada de sabor' AND v.nombre = 'Mediano 450 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 900 ml', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Michelada de sabor'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 104.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Michelada de sabor' AND v.nombre = 'Grande 900 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 104.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Michelada de sabor' AND v.nombre = 'Grande 900 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 116.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Michelada de sabor' AND v.nombre = 'Grande 900 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Piña colada', NULL, true, NULL, 4
  FROM public.menu_categorias c WHERE c.nombre = 'Bebidas preparadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Piña colada'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 78.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Piña colada' AND v.nombre = 'Mediano' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 78.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Piña colada' AND v.nombre = 'Mediano' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 98.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Piña colada' AND v.nombre = 'Mediano' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 98.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Piña colada' AND v.nombre = 'Mediano' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Piña colada'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 148.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Piña colada' AND v.nombre = 'Grande' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 148.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Piña colada' AND v.nombre = 'Grande' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 178.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Piña colada' AND v.nombre = 'Grande' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Cerveza española', NULL, true, NULL, 5
  FROM public.menu_categorias c WHERE c.nombre = 'Bebidas preparadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Cerveza española'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 78.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Cerveza española' AND v.nombre = 'Mediano' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 78.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Cerveza española' AND v.nombre = 'Mediano' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 98.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Cerveza española' AND v.nombre = 'Mediano' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 98.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Cerveza española' AND v.nombre = 'Mediano' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Cerveza española'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 148.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Cerveza española' AND v.nombre = 'Grande' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 148.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Cerveza española' AND v.nombre = 'Grande' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 178.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Cerveza española' AND v.nombre = 'Grande' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Sangría', NULL, true, NULL, 6
  FROM public.menu_categorias c WHERE c.nombre = 'Bebidas preparadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Sangría'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 78.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Sangría' AND v.nombre = 'Mediano' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 78.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Sangría' AND v.nombre = 'Mediano' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 98.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Sangría' AND v.nombre = 'Mediano' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Sangría'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 148.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Sangría' AND v.nombre = 'Grande' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 148.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Sangría' AND v.nombre = 'Grande' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 178.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Sangría' AND v.nombre = 'Grande' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Margarita', NULL, true, NULL, 7
  FROM public.menu_categorias c WHERE c.nombre = 'Bebidas preparadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Margarita'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 78.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Margarita' AND v.nombre = 'Mediano' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 78.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Margarita' AND v.nombre = 'Mediano' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 98.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Margarita' AND v.nombre = 'Mediano' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Margarita'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 148.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Margarita' AND v.nombre = 'Grande' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 148.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Margarita' AND v.nombre = 'Grande' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 178.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Margarita' AND v.nombre = 'Grande' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Paloma', NULL, true, NULL, 8
  FROM public.menu_categorias c WHERE c.nombre = 'Bebidas preparadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '300 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Paloma'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 98.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Paloma' AND v.nombre = '300 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 98.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Paloma' AND v.nombre = '300 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 98.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Paloma' AND v.nombre = '300 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Mezcalitas', 'Jamaica pepino mandarina maracuyá mango', true, '{"sabor":["Jamaica","Pepino","Mandarina","Maracuyá","Mango"]}'::jsonb, 9
  FROM public.menu_categorias c WHERE c.nombre = 'Bebidas preparadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '240 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Mezcalitas'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 98.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Mezcalitas' AND v.nombre = '240 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 98.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Mezcalitas' AND v.nombre = '240 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 98.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Mezcalitas' AND v.nombre = '240 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 98.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Mezcalitas' AND v.nombre = '240 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Aperol', 'Spritz veraniego tropical', true, NULL, 10
  FROM public.menu_categorias c WHERE c.nombre = 'Bebidas preparadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '180 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Aperol'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 98.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Aperol' AND v.nombre = '180 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 98.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Aperol' AND v.nombre = '180 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 98.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Aperol' AND v.nombre = '180 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Mojito', 'Solares 500 ml', true, NULL, 11
  FROM public.menu_categorias c WHERE c.nombre = 'Bebidas preparadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '300 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Mojito'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 78.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Mojito' AND v.nombre = '300 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 78.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Mojito' AND v.nombre = '300 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 98.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Mojito' AND v.nombre = '300 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 98.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Mojito' AND v.nombre = '300 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Clericot', 'Solares 355 ml', true, NULL, 12
  FROM public.menu_categorias c WHERE c.nombre = 'Bebidas preparadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '300 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Clericot'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 78.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Clericot' AND v.nombre = '300 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 78.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Clericot' AND v.nombre = '300 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 98.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Clericot' AND v.nombre = '300 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 98.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Clericot' AND v.nombre = '300 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Perla Negra', NULL, true, NULL, 13
  FROM public.menu_categorias c WHERE c.nombre = 'Bebidas preparadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '300 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Perla Negra'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 128.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Perla Negra' AND v.nombre = '300 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 128.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Perla Negra' AND v.nombre = '300 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 128.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Perla Negra' AND v.nombre = '300 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Coco La Ola', 'Agua de coco limón jarabe tequila vodka ron ginebra y controy', true, NULL, 14
  FROM public.menu_categorias c WHERE c.nombre = 'Bebidas preparadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '1 pieza', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Coco La Ola'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 128.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Coco La Ola' AND v.nombre = '1 pieza' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 120.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Coco La Ola' AND v.nombre = '1 pieza' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Cantarito', NULL, true, NULL, 15
  FROM public.menu_categorias c WHERE c.nombre = 'Bebidas preparadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '500 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Cantarito'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 120.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Cantarito' AND v.nombre = '500 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Tinto de verano', NULL, true, NULL, 16
  FROM public.menu_categorias c WHERE c.nombre = 'Bebidas preparadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '355 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Tinto de verano'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 98.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Tinto de verano' AND v.nombre = '355 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Calimocho', NULL, true, NULL, 17
  FROM public.menu_categorias c WHERE c.nombre = 'Bebidas preparadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '355 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Calimocho'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 98.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Calimocho' AND v.nombre = '355 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Painkiller', 'Bacardi crema de coco naranja piña', true, NULL, 18
  FROM public.menu_categorias c WHERE c.nombre = 'Bebidas preparadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '355 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Painkiller'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 98.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Painkiller' AND v.nombre = '355 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Vaso chelado', NULL, false, NULL, 19
  FROM public.menu_categorias c WHERE c.nombre = 'Bebidas preparadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Único', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Vaso chelado'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 10.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Vaso chelado' AND v.nombre = 'Único' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 10.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Vaso chelado' AND v.nombre = 'Único' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 10.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Vaso chelado' AND v.nombre = 'Único' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 12.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Vaso chelado' AND v.nombre = 'Único' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Vaso michelado', NULL, false, NULL, 20
  FROM public.menu_categorias c WHERE c.nombre = 'Bebidas preparadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Único', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Vaso michelado'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 20.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Vaso michelado' AND v.nombre = 'Único' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 20.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Vaso michelado' AND v.nombre = 'Único' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 20.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Vaso michelado' AND v.nombre = 'Único' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 22.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Vaso michelado' AND v.nombre = 'Único' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Vaso salseado', NULL, false, NULL, 21
  FROM public.menu_categorias c WHERE c.nombre = 'Bebidas preparadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Único', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Vaso salseado'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 15.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Vaso salseado' AND v.nombre = 'Único' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 15.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Vaso salseado' AND v.nombre = 'Único' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 15.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Vaso salseado' AND v.nombre = 'Único' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;

-- ===== Cervezas =====
INSERT INTO public.menu_categorias (nombre, orden) VALUES ('Cervezas', 23) ON CONFLICT (nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Pacífico', 'En Solares: Pacífico clara', true, NULL, 0
  FROM public.menu_categorias c WHERE c.nombre = 'Cervezas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Media 210 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Pacífico'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 24.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Pacífico' AND v.nombre = 'Media 210 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 24.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Pacífico' AND v.nombre = 'Media 210 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 24.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Pacífico' AND v.nombre = 'Media 210 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 28.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Pacífico' AND v.nombre = 'Media 210 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '355 ml', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Pacífico'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 48.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Pacífico' AND v.nombre = '355 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 48.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Pacífico' AND v.nombre = '355 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 48.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Pacífico' AND v.nombre = '355 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 56.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Pacífico' AND v.nombre = '355 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mega 940 ml', 2
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Pacífico'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 108.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Pacífico' AND v.nombre = 'Mega 940 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 108.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Pacífico' AND v.nombre = 'Mega 940 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 108.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Pacífico' AND v.nombre = 'Mega 940 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Pacífico Light', NULL, true, NULL, 1
  FROM public.menu_categorias c WHERE c.nombre = 'Cervezas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Media 210 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Pacífico Light'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 24.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Pacífico Light' AND v.nombre = 'Media 210 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 24.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Pacífico Light' AND v.nombre = 'Media 210 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 24.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Pacífico Light' AND v.nombre = 'Media 210 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '355 ml', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Pacífico Light'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 48.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Pacífico Light' AND v.nombre = '355 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 48.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Pacífico Light' AND v.nombre = '355 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 48.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Pacífico Light' AND v.nombre = '355 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mega 940 ml', 2
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Pacífico Light'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 108.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Pacífico Light' AND v.nombre = 'Mega 940 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 108.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Pacífico Light' AND v.nombre = 'Mega 940 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 108.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Pacífico Light' AND v.nombre = 'Mega 940 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Pacífico Suave', NULL, true, NULL, 2
  FROM public.menu_categorias c WHERE c.nombre = 'Cervezas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '355 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Pacífico Suave'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 48.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Pacífico Suave' AND v.nombre = '355 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 48.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Pacífico Suave' AND v.nombre = '355 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 48.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Pacífico Suave' AND v.nombre = '355 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 56.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Pacífico Suave' AND v.nombre = '355 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Corona', NULL, true, NULL, 3
  FROM public.menu_categorias c WHERE c.nombre = 'Cervezas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Media 210 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 24.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona' AND v.nombre = 'Media 210 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 24.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona' AND v.nombre = 'Media 210 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 24.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona' AND v.nombre = 'Media 210 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 28.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona' AND v.nombre = 'Media 210 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '355 ml', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 48.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona' AND v.nombre = '355 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 48.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona' AND v.nombre = '355 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 48.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona' AND v.nombre = '355 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 56.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona' AND v.nombre = '355 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mega 940 ml', 2
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 108.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona' AND v.nombre = 'Mega 940 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 108.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona' AND v.nombre = 'Mega 940 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 108.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona' AND v.nombre = 'Mega 940 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Corona Light', NULL, true, NULL, 4
  FROM public.menu_categorias c WHERE c.nombre = 'Cervezas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Media 210 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona Light'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 24.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona Light' AND v.nombre = 'Media 210 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 24.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona Light' AND v.nombre = 'Media 210 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 24.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona Light' AND v.nombre = 'Media 210 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 28.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona Light' AND v.nombre = 'Media 210 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '355 ml', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona Light'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 48.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona Light' AND v.nombre = '355 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 48.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona Light' AND v.nombre = '355 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 48.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona Light' AND v.nombre = '355 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 56.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona Light' AND v.nombre = '355 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mega 940 ml', 2
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona Light'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 108.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona Light' AND v.nombre = 'Mega 940 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 108.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona Light' AND v.nombre = 'Mega 940 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 108.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona Light' AND v.nombre = 'Mega 940 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Corona Ámbar', NULL, true, NULL, 5
  FROM public.menu_categorias c WHERE c.nombre = 'Cervezas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Media 210 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona Ámbar'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 28.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona Ámbar' AND v.nombre = 'Media 210 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '355 ml', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona Ámbar'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 56.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona Ámbar' AND v.nombre = '355 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Corona Cero', 'En Valle/Brisas/Cervecería: Coronita Cero', true, NULL, 6
  FROM public.menu_categorias c WHERE c.nombre = 'Cervezas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Media 210 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona Cero'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 28.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona Cero' AND v.nombre = 'Media 210 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '355 ml', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona Cero'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 48.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona Cero' AND v.nombre = '355 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 48.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona Cero' AND v.nombre = '355 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 48.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona Cero' AND v.nombre = '355 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 56.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona Cero' AND v.nombre = '355 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Victoria', NULL, true, NULL, 7
  FROM public.menu_categorias c WHERE c.nombre = 'Cervezas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Media 210 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Victoria'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 24.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Victoria' AND v.nombre = 'Media 210 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 24.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Victoria' AND v.nombre = 'Media 210 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 24.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Victoria' AND v.nombre = 'Media 210 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 28.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Victoria' AND v.nombre = 'Media 210 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '355 ml', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Victoria'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 48.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Victoria' AND v.nombre = '355 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 48.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Victoria' AND v.nombre = '355 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 48.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Victoria' AND v.nombre = '355 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 56.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Victoria' AND v.nombre = '355 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mega 940 ml', 2
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Victoria'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 108.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Victoria' AND v.nombre = 'Mega 940 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 108.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Victoria' AND v.nombre = 'Mega 940 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 108.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Victoria' AND v.nombre = 'Mega 940 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Ultra', 'En Solares: Michelob Ultra', true, NULL, 8
  FROM public.menu_categorias c WHERE c.nombre = 'Cervezas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '355 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Ultra'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 58.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Ultra' AND v.nombre = '355 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 58.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Ultra' AND v.nombre = '355 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 58.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Ultra' AND v.nombre = '355 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 62.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Ultra' AND v.nombre = '355 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mega 940 ml', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Ultra'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 108.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Ultra' AND v.nombre = 'Mega 940 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 108.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Ultra' AND v.nombre = 'Mega 940 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 108.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Ultra' AND v.nombre = 'Mega 940 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Modelo Especial', NULL, true, NULL, 9
  FROM public.menu_categorias c WHERE c.nombre = 'Cervezas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '355 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Modelo Especial'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 58.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Modelo Especial' AND v.nombre = '355 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 58.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Modelo Especial' AND v.nombre = '355 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 58.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Modelo Especial' AND v.nombre = '355 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 62.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Modelo Especial' AND v.nombre = '355 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mega 940 ml', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Modelo Especial'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 108.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Modelo Especial' AND v.nombre = 'Mega 940 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 108.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Modelo Especial' AND v.nombre = 'Mega 940 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 108.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Modelo Especial' AND v.nombre = 'Mega 940 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Negra Modelo', NULL, true, NULL, 10
  FROM public.menu_categorias c WHERE c.nombre = 'Cervezas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '355 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Negra Modelo'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 58.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Negra Modelo' AND v.nombre = '355 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 58.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Negra Modelo' AND v.nombre = '355 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 58.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Negra Modelo' AND v.nombre = '355 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 62.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Negra Modelo' AND v.nombre = '355 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Stella Artois', NULL, true, NULL, 11
  FROM public.menu_categorias c WHERE c.nombre = 'Cervezas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '355 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Stella Artois'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 62.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Stella Artois' AND v.nombre = '355 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Corona Light lata', NULL, true, NULL, 12
  FROM public.menu_categorias c WHERE c.nombre = 'Cervezas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '355 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona Light lata'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 48.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona Light lata' AND v.nombre = '355 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 48.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona Light lata' AND v.nombre = '355 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 48.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona Light lata' AND v.nombre = '355 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Corona Cero lata', NULL, true, NULL, 13
  FROM public.menu_categorias c WHERE c.nombre = 'Cervezas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '355 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona Cero lata'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 48.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona Cero lata' AND v.nombre = '355 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 48.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona Cero lata' AND v.nombre = '355 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 48.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona Cero lata' AND v.nombre = '355 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Modelo Especial lata', NULL, true, NULL, 14
  FROM public.menu_categorias c WHERE c.nombre = 'Cervezas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '355 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Modelo Especial lata'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 48.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Modelo Especial lata' AND v.nombre = '355 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Cerveza San Blas Agüita de Mar', NULL, true, NULL, 15
  FROM public.menu_categorias c WHERE c.nombre = 'Cervezas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Artesanal 355 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Cerveza San Blas Agüita de Mar'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 89.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Cerveza San Blas Agüita de Mar' AND v.nombre = 'Artesanal 355 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Cerveza San Blas Beach Lager', NULL, true, NULL, 16
  FROM public.menu_categorias c WHERE c.nombre = 'Cervezas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Artesanal 355 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Cerveza San Blas Beach Lager'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 89.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Cerveza San Blas Beach Lager' AND v.nombre = 'Artesanal 355 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Cerveza San Blas Negra Tovara', NULL, true, NULL, 17
  FROM public.menu_categorias c WHERE c.nombre = 'Cervezas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Artesanal 355 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Cerveza San Blas Negra Tovara'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 89.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Cerveza San Blas Negra Tovara' AND v.nombre = 'Artesanal 355 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
