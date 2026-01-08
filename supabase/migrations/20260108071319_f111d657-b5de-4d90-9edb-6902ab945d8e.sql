-- Agregar columnas opcionales para gastos del cierre
ALTER TABLE public.cortes_caja 
ADD COLUMN pago_proveedores numeric DEFAULT 0,
ADD COLUMN salarios numeric DEFAULT 0,
ADD COLUMN propinas numeric DEFAULT 0,
ADD COLUMN compras numeric DEFAULT 0,
ADD COLUMN pago_servicios numeric DEFAULT 0;