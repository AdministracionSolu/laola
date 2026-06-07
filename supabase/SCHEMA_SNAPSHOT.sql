-- laola — esquema completo (public)
-- snapshot Lovable Cloud · 2026-06-07
-- Documento de referencia (no es una migración). Refleja el estado real de la base.

-- ============ TABLES ============
CREATE TABLE categorias_insumos (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  nombre text NOT NULL,
  orden integer NOT NULL DEFAULT 0,
  created_at timestamp with time zone NOT NULL DEFAULT now()
);
CREATE TABLE cortes_caja (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  sucursal_id uuid NOT NULL,
  tipo_corte tipo_corte NOT NULL,
  corte_x numeric(12,2) NOT NULL DEFAULT 0,
  tarjetas numeric(12,2) NOT NULL DEFAULT 0,
  efectivo numeric(12,2) NOT NULL DEFAULT 0,
  total numeric(12,2) NOT NULL DEFAULT 0,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  cobradas numeric NOT NULL DEFAULT 0,
  por_cobrar numeric NOT NULL DEFAULT 0,
  pago_proveedores numeric DEFAULT 0,
  salarios numeric DEFAULT 0,
  propinas numeric DEFAULT 0,
  compras numeric DEFAULT 0,
  pago_servicios numeric DEFAULT 0,
  fecha_venta date NOT NULL,
  tarjetas_banregio numeric DEFAULT 0,
  tarjetas_mercadopago numeric DEFAULT 0,
  tarjetas_haycash numeric DEFAULT 0,
  rappi numeric DEFAULT 0,
  uber numeric DEFAULT 0
);
CREATE TABLE insumo_sucursal (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  insumo_id uuid NOT NULL,
  sucursal_id uuid NOT NULL,
  nivel_par numeric,
  costo numeric,
  unidad text,
  orden integer NOT NULL DEFAULT 0,
  activo boolean NOT NULL DEFAULT true,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now()
);
CREATE TABLE insumos (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  nombre text NOT NULL,
  categoria_id uuid NOT NULL,
  unidad text DEFAULT 'pz'::text,
  activo boolean NOT NULL DEFAULT true,
  created_at timestamp with time zone NOT NULL DEFAULT now()
);
CREATE TABLE pedidos (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  sucursal_id uuid NOT NULL,
  fecha date NOT NULL DEFAULT CURRENT_DATE,
  registrado_por text,
  estado text NOT NULL DEFAULT 'pendiente'::text,
  notas text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  enviado_at timestamp with time zone
);
CREATE TABLE pedidos_detalle (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  pedido_id uuid NOT NULL,
  insumo_id uuid NOT NULL,
  existencia numeric DEFAULT 0,
  cantidad_pedida numeric NOT NULL DEFAULT 0,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  cantidad_sugerida numeric
  -- Modelo Feature 1: existencia (sucursal) · cantidad_sugerida (solicitud sucursal)
  --                   · cantidad_pedida (pedido real capturado por el admin)
);
CREATE TABLE recepciones (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  sucursal_id uuid NOT NULL,
  proveedor text NOT NULL,
  fecha date NOT NULL DEFAULT CURRENT_DATE,
  registrado_por text,
  notas text,
  created_at timestamp with time zone NOT NULL DEFAULT now()
);
CREATE TABLE recepciones_detalle (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  recepcion_id uuid NOT NULL,
  insumo_id uuid NOT NULL,
  cantidad_recibida numeric NOT NULL DEFAULT 0,
  pedido_detalle_id uuid,
  created_at timestamp with time zone NOT NULL DEFAULT now()
);
CREATE TABLE sucursales (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  nombre text NOT NULL,
  direccion text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  pin text
);
-- (reservaciones, zonas_sucursal, user_roles, verificaciones_plataforma: ver snapshot original)

-- ============ DATOS REALES OBSERVADOS (2026-06-07) ============
-- sucursales (4): 'Del Valle', 'Las Brisas', 'Cervecería', 'Solares'  (NO hay 'Rodeo')
-- insumos: 159 filas, nombres en MAYÚSCULAS ('CAMARON 61-70', 'ROBALO (chicharrón)', ...)
-- insumo_sucursal: 636 filas = 159 insumos × 4 sucursales (TODO asignado por Lovable)
-- pedidos / pedidos_detalle: 0
-- recepciones / recepciones_detalle: 1 / 1

-- ============ RLS — QUÉ PERMITE CADA LLAVE ============
-- Con la llave PÚBLICA (anon), TO public USING(true):
--   LEER: sucursales, insumos, categorias_insumos, insumo_sucursal, pedidos,
--         pedidos_detalle, recepciones, recepciones_detalle, reservaciones,
--         zonas_sucursal, verificaciones_plataforma
--   ESCRIBIR (insert/update/select): pedidos, pedidos_detalle, recepciones,
--         recepciones_detalle, reservaciones, verificaciones_plataforma
--   NO puede escribir: insumos, insumo_sucursal, categorias_insumos  (FOR ALL → has_role admin)
--   NO puede leer: cortes_caja (solo authenticated), user_roles (admin/self)
--
-- Para MODIFICAR insumo_sucursal / insumos (arreglar listas, desactivar, costos)
-- se requiere SESIÓN DE ADMIN (has_role(auth.uid(),'admin')) o el service_role key.
