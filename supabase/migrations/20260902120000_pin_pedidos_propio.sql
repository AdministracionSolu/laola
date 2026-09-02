-- =====================================================================
-- PIN propio para /compras (quien captura el pedido del día).
--
-- Hasta hoy /compras usaba el mismo 1278 del panel de administración, así
-- que quien captura pedidos podía entrar también a facturación, lealtad y
-- cortes. Con un PIN aparte se le puede cambiar o quitar el acceso sin
-- tocar el de Alicia ni el del dueño.
--
-- CAMBIA EL 4590 por el que quieras antes de correrlo.
-- =====================================================================

UPDATE public.config_app SET valor = '4590' WHERE clave = 'pin_compras';

-- Si por lo que sea el renglón no existiera, lo crea.
INSERT INTO public.config_app (clave, valor)
VALUES ('pin_compras', '4590')
ON CONFLICT (clave) DO UPDATE SET valor = EXCLUDED.valor;
