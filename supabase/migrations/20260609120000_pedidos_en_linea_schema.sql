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
