-- Barrido de seguridad 2026-08 · Eje 3 (RLS) — OPCIONAL / TIER 2
--
-- Hoy estas tablas de PII y finanzas están abiertas a CUALQUIER usuario
-- `authenticated` con USING(true): autenticarse = leerlo todo. Si el registro
-- de usuarios (signup) está abierto en Supabase, cualquiera crea una cuenta y
-- lee empleados, teléfonos de clientes, datos fiscales, ventas y cortes.
--
-- ANTES de correr esto:
--   1. Desactiva el signup público (Auth > Providers > Email > Disable signups)
--      o confirma que solo existen cuentas de personal de confianza.
--   2. Confirma que TODAS las cuentas del staff que usan el panel tienen rol
--      'admin' en user_roles. Si scope a has_role('admin') y una cuenta legítima
--      no tiene el rol, deja de ver estos datos.
--
-- Correr bloque por bloque. Cada tabla es independiente: si una rompe un flujo,
-- revierte solo esa recreando la política vieja `... TO authenticated USING (true)`.

-- empleados (padrón de los 77 colaboradores)
DROP POLICY IF EXISTS "staff_todo_empleados" ON public.empleados;
CREATE POLICY "admin_empleados" ON public.empleados FOR ALL TO authenticated
  USING (public.has_role(auth.uid(), 'admin')) WITH CHECK (public.has_role(auth.uid(), 'admin'));

-- asistencias (checador)
DROP POLICY IF EXISTS "staff_todo_asistencias" ON public.asistencias;
CREATE POLICY "admin_asistencias" ON public.asistencias FOR ALL TO authenticated
  USING (public.has_role(auth.uid(), 'admin')) WITH CHECK (public.has_role(auth.uid(), 'admin'));

-- lealtad_clientes (nombre + teléfono de clientes)
DROP POLICY IF EXISTS "staff_lee_lealtad" ON public.lealtad_clientes;
DROP POLICY IF EXISTS "staff_actualiza_lealtad" ON public.lealtad_clientes;
CREATE POLICY "admin_lee_lealtad" ON public.lealtad_clientes FOR SELECT TO authenticated
  USING (public.has_role(auth.uid(), 'admin'));
CREATE POLICY "admin_actualiza_lealtad" ON public.lealtad_clientes FOR UPDATE TO authenticated
  USING (public.has_role(auth.uid(), 'admin')) WITH CHECK (public.has_role(auth.uid(), 'admin'));

-- factura_solicitudes (datos fiscales: RFC, razón social)
DROP POLICY IF EXISTS "staff_lee_facturas" ON public.factura_solicitudes;
DROP POLICY IF EXISTS "staff_actualiza_facturas" ON public.factura_solicitudes;
CREATE POLICY "admin_lee_facturas" ON public.factura_solicitudes FOR SELECT TO authenticated
  USING (public.has_role(auth.uid(), 'admin'));
CREATE POLICY "admin_actualiza_facturas" ON public.factura_solicitudes FOR UPDATE TO authenticated
  USING (public.has_role(auth.uid(), 'admin')) WITH CHECK (public.has_role(auth.uid(), 'admin'));

-- lealtad_colaboradores
DROP POLICY IF EXISTS colaboradores_admin_select ON public.lealtad_colaboradores;
DROP POLICY IF EXISTS colaboradores_admin_write  ON public.lealtad_colaboradores;
CREATE POLICY colaboradores_admin_select ON public.lealtad_colaboradores FOR SELECT TO authenticated
  USING (public.has_role(auth.uid(), 'admin'));
CREATE POLICY colaboradores_admin_write ON public.lealtad_colaboradores FOR ALL TO authenticated
  USING (public.has_role(auth.uid(), 'admin')) WITH CHECK (public.has_role(auth.uid(), 'admin'));

-- pos_ventas / pos_venta_detalle (ventas reales desde Soft Restaurant)
DROP POLICY IF EXISTS pos_ventas_leer ON public.pos_ventas;
CREATE POLICY pos_ventas_leer ON public.pos_ventas FOR SELECT TO authenticated
  USING (public.has_role(auth.uid(), 'admin'));
DROP POLICY IF EXISTS pos_det_leer ON public.pos_venta_detalle;
CREATE POLICY pos_det_leer ON public.pos_venta_detalle FOR SELECT TO authenticated
  USING (public.has_role(auth.uid(), 'admin'));
