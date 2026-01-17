-- Política para permitir a admins actualizar tipo de corte
CREATE POLICY "Solo admins pueden actualizar cortes" 
ON public.cortes_caja 
FOR UPDATE 
USING (has_role(auth.uid(), 'admin'::app_role))
WITH CHECK (has_role(auth.uid(), 'admin'::app_role));