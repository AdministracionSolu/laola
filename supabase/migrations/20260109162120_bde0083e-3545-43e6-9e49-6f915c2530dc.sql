-- Permitir que usuarios con rol admin puedan eliminar cortes
CREATE POLICY "Solo admins pueden eliminar cortes"
ON public.cortes_caja
FOR DELETE
TO authenticated
USING (public.has_role(auth.uid(), 'admin'));