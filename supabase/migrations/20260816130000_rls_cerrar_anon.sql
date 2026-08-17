-- Barrido de seguridad 2026-08 · Eje 3 (RLS)
-- Cierra el acceso ANÓNIMO (rol anon, con la publishable/anon key que es pública)
-- a tablas que hoy exponen o dejan escribir datos a cualquiera en internet.
--
-- NO aplicar con `db push`. Correr bloque por bloque en el SQL Editor, en orden.
-- Cada bloque es independiente. Verificado: estas tablas se leen/escriben desde
-- el panel admin (autenticado) o por RPC SECURITY DEFINER; el rol anon no las
-- necesita. El flujo público de reservación conserva solo INSERT.

-- ================================================================
-- BLOQUE 1 — reservaciones: anon podía LEER (nombre+teléfono de todos),
-- ACTUALIZAR y BORRAR cualquier reservación. Se deja solo el INSERT público
-- (el sitio permite reservar sin login) y el resto pasa a authenticated.
-- ================================================================
DROP POLICY IF EXISTS "Cualquiera puede ver reservaciones"        ON public.reservaciones;
DROP POLICY IF EXISTS "Cualquiera puede actualizar reservaciones" ON public.reservaciones;
DROP POLICY IF EXISTS "Cualquiera puede eliminar reservaciones"   ON public.reservaciones;

CREATE POLICY "staff_ve_reservaciones"       ON public.reservaciones FOR SELECT TO authenticated USING (true);
CREATE POLICY "staff_actualiza_reservaciones" ON public.reservaciones FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "admin_borra_reservaciones"    ON public.reservaciones FOR DELETE TO authenticated USING (public.has_role(auth.uid(), 'admin'));
-- (se conserva la política de INSERT pública existente para el flujo de reservar)

-- ================================================================
-- BLOQUE 2 — pedidos / pedidos_detalle: pedidos internos de cocina/insumos
-- (registrado_por = personal). anon podía verlos, crearlos y modificarlos.
-- El flujo público de pedidos de clientes vive en pedidos_en_linea, no aquí.
-- ================================================================
DROP POLICY IF EXISTS "Cualquiera puede ver pedidos"         ON public.pedidos;
DROP POLICY IF EXISTS "Cualquiera puede crear pedidos"       ON public.pedidos;
DROP POLICY IF EXISTS "Cualquiera puede actualizar pedidos"  ON public.pedidos;
CREATE POLICY "staff_gestiona_pedidos" ON public.pedidos FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Cualquiera puede ver detalle pedidos"        ON public.pedidos_detalle;
DROP POLICY IF EXISTS "Cualquiera puede crear detalle pedidos"      ON public.pedidos_detalle;
DROP POLICY IF EXISTS "Cualquiera puede actualizar detalle pedidos" ON public.pedidos_detalle;
CREATE POLICY "staff_gestiona_detalle_pedidos" ON public.pedidos_detalle FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- ================================================================
-- BLOQUE 3 — recepciones / recepciones_detalle: recepción de proveedores.
-- ================================================================
DROP POLICY IF EXISTS "Cualquiera puede ver recepciones"        ON public.recepciones;
DROP POLICY IF EXISTS "Cualquiera puede crear recepciones"      ON public.recepciones;
DROP POLICY IF EXISTS "Cualquiera puede actualizar recepciones" ON public.recepciones;
CREATE POLICY "staff_gestiona_recepciones" ON public.recepciones FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Cualquiera puede ver detalle recepciones"        ON public.recepciones_detalle;
DROP POLICY IF EXISTS "Cualquiera puede crear detalle recepciones"      ON public.recepciones_detalle;
DROP POLICY IF EXISTS "Cualquiera puede actualizar detalle recepciones" ON public.recepciones_detalle;
CREATE POLICY "staff_gestiona_detalle_recepciones" ON public.recepciones_detalle FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- ================================================================
-- BLOQUE 4 — cortes_caja: anon podía INSERTAR cortes falsos (contamina el
-- dashboard financiero). Los cortes se capturan desde el panel admin (auth).
-- ================================================================
DROP POLICY IF EXISTS "Cualquiera puede insertar cortes" ON public.cortes_caja;
CREATE POLICY "staff_inserta_cortes" ON public.cortes_caja FOR INSERT TO authenticated WITH CHECK (true);

-- ================================================================
-- BLOQUE 5 — verificaciones_plataforma: anon podía ver e insertar.
-- (Revisar con Diego si algún flujo público la necesita antes de correr.)
-- ================================================================
DROP POLICY IF EXISTS "Cualquiera puede ver verificaciones"   ON public.verificaciones_plataforma;
CREATE POLICY "staff_ve_verificaciones" ON public.verificaciones_plataforma FOR SELECT TO authenticated USING (true);
