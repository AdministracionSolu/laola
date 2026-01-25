
-- Tabla de categorías de insumos
CREATE TABLE public.categorias_insumos (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  nombre TEXT NOT NULL UNIQUE,
  orden INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Tabla de insumos (productos)
CREATE TABLE public.insumos (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  nombre TEXT NOT NULL,
  categoria_id UUID NOT NULL REFERENCES public.categorias_insumos(id) ON DELETE CASCADE,
  unidad TEXT DEFAULT 'pz',
  activo BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Tabla de pedidos (cabecera)
CREATE TABLE public.pedidos (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  sucursal_id UUID NOT NULL REFERENCES public.sucursales(id) ON DELETE CASCADE,
  fecha DATE NOT NULL DEFAULT CURRENT_DATE,
  registrado_por TEXT,
  estado TEXT NOT NULL DEFAULT 'pendiente',
  notas TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Tabla de detalle de pedidos
CREATE TABLE public.pedidos_detalle (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  pedido_id UUID NOT NULL REFERENCES public.pedidos(id) ON DELETE CASCADE,
  insumo_id UUID NOT NULL REFERENCES public.insumos(id) ON DELETE CASCADE,
  existencia NUMERIC DEFAULT 0,
  cantidad_pedida NUMERIC NOT NULL DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Tabla de recepciones (cuando llega el proveedor)
CREATE TABLE public.recepciones (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  sucursal_id UUID NOT NULL REFERENCES public.sucursales(id) ON DELETE CASCADE,
  proveedor TEXT NOT NULL,
  fecha DATE NOT NULL DEFAULT CURRENT_DATE,
  registrado_por TEXT,
  notas TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Tabla de detalle de recepciones
CREATE TABLE public.recepciones_detalle (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  recepcion_id UUID NOT NULL REFERENCES public.recepciones(id) ON DELETE CASCADE,
  insumo_id UUID NOT NULL REFERENCES public.insumos(id) ON DELETE CASCADE,
  cantidad_recibida NUMERIC NOT NULL DEFAULT 0,
  pedido_detalle_id UUID REFERENCES public.pedidos_detalle(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.categorias_insumos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.insumos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pedidos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pedidos_detalle ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.recepciones ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.recepciones_detalle ENABLE ROW LEVEL SECURITY;

-- Políticas para categorías (lectura pública, escritura admin)
CREATE POLICY "Cualquiera puede ver categorías" ON public.categorias_insumos FOR SELECT USING (true);
CREATE POLICY "Solo admins pueden modificar categorías" ON public.categorias_insumos FOR ALL USING (has_role(auth.uid(), 'admin'::app_role));

-- Políticas para insumos (lectura pública, escritura admin)
CREATE POLICY "Cualquiera puede ver insumos" ON public.insumos FOR SELECT USING (true);
CREATE POLICY "Solo admins pueden modificar insumos" ON public.insumos FOR ALL USING (has_role(auth.uid(), 'admin'::app_role));

-- Políticas para pedidos (operaciones públicas para staff)
CREATE POLICY "Cualquiera puede ver pedidos" ON public.pedidos FOR SELECT USING (true);
CREATE POLICY "Cualquiera puede crear pedidos" ON public.pedidos FOR INSERT WITH CHECK (true);
CREATE POLICY "Cualquiera puede actualizar pedidos" ON public.pedidos FOR UPDATE USING (true);
CREATE POLICY "Solo admins pueden eliminar pedidos" ON public.pedidos FOR DELETE USING (has_role(auth.uid(), 'admin'::app_role));

-- Políticas para pedidos_detalle
CREATE POLICY "Cualquiera puede ver detalle pedidos" ON public.pedidos_detalle FOR SELECT USING (true);
CREATE POLICY "Cualquiera puede crear detalle pedidos" ON public.pedidos_detalle FOR INSERT WITH CHECK (true);
CREATE POLICY "Cualquiera puede actualizar detalle pedidos" ON public.pedidos_detalle FOR UPDATE USING (true);
CREATE POLICY "Solo admins pueden eliminar detalle pedidos" ON public.pedidos_detalle FOR DELETE USING (has_role(auth.uid(), 'admin'::app_role));

-- Políticas para recepciones
CREATE POLICY "Cualquiera puede ver recepciones" ON public.recepciones FOR SELECT USING (true);
CREATE POLICY "Cualquiera puede crear recepciones" ON public.recepciones FOR INSERT WITH CHECK (true);
CREATE POLICY "Cualquiera puede actualizar recepciones" ON public.recepciones FOR UPDATE USING (true);
CREATE POLICY "Solo admins pueden eliminar recepciones" ON public.recepciones FOR DELETE USING (has_role(auth.uid(), 'admin'::app_role));

-- Políticas para recepciones_detalle
CREATE POLICY "Cualquiera puede ver detalle recepciones" ON public.recepciones_detalle FOR SELECT USING (true);
CREATE POLICY "Cualquiera puede crear detalle recepciones" ON public.recepciones_detalle FOR INSERT WITH CHECK (true);
CREATE POLICY "Cualquiera puede actualizar detalle recepciones" ON public.recepciones_detalle FOR UPDATE USING (true);
CREATE POLICY "Solo admins pueden eliminar detalle recepciones" ON public.recepciones_detalle FOR DELETE USING (has_role(auth.uid(), 'admin'::app_role));

-- Trigger para updated_at en pedidos
CREATE TRIGGER update_pedidos_updated_at
BEFORE UPDATE ON public.pedidos
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- Insertar categorías basadas en el Excel
INSERT INTO public.categorias_insumos (nombre, orden) VALUES
  ('Abarrotes', 1),
  ('Mariscos y Carnes', 2),
  ('Frutería', 3),
  ('Desechables', 4),
  ('Artículos de Limpieza', 5),
  ('Extras', 6);

-- Insertar insumos de Abarrotes
INSERT INTO public.insumos (nombre, categoria_id, unidad) 
SELECT nombre, cat.id, 'pz'
FROM (VALUES 
  ('ACEITE CRISTAL DE MAÍZ'),
  ('ACEITE OLIVO'),
  ('ADEREZO RANCH'),
  ('ARROZ ENTERO VERDE V.'),
  ('AZUCAR MORENO'),
  ('AZUCAR SPLENDA'),
  ('BARRAS TAM. MICH. BAZU'),
  ('BAGUETTE'),
  ('CAPSULA DE CAFÉ'),
  ('CATSUP EMABASA 1L.'),
  ('CHILE CHIPOTLE'),
  ('CHILE JALAPEÑO'),
  ('CHILE SECO TRITURADO'),
  ('COCO RALLADO'),
  ('CONCENTRADO FRESA'),
  ('CONCENTRADO MANGO'),
  ('CONCENTRADO DE PIÑA'),
  ('CONCENTRADO DE TAM.'),
  ('CONSOME DE CAMARÓN'),
  ('CONSOME DE POLLO'),
  ('CREM COCO CALAHUA 1L.'),
  ('CREMA LALA'),
  ('EMPANIZADOR KELLOGS'),
  ('FRIJOLES FRITOS'),
  ('GALLATEAS SAL. IND.'),
  ('GALLETAS DOR. MAR.'),
  ('HARINA POR KILOS'),
  ('HUEVO POR CARTERA'),
  ('JAMÓN PAVO CORONA'),
  ('JARABE NATURAL GALON 5 LTS'),
  ('JUGO DE NARANJA'),
  ('JUGO DE PIÑA'),
  ('LECHE CLAVEL CARN.'),
  ('LECHERITA'),
  ('MANGO EN ALMIBAR'),
  ('MANTEQUILLA EUGENIA'),
  ('MASA'),
  ('MASECA'),
  ('MAYONESA McCORMICK'),
  ('MEDIA CREMA'),
  ('PALILLOS DE 20 CM'),
  ('PAPAS FRANC.'),
  ('PAPEL ALUMINIO'),
  ('PAPEL EMPANADAS'),
  ('PHILADELPHIA'),
  ('PIMIENTA TONES SAMS'),
  ('PIMIENTO MORR. LATA'),
  ('PIÑA EN ALMIBAR'),
  ('POPOTES BIO'),
  ('PURE DE TOMATE'),
  ('QUESO ENTERO NAV. CHEDDAR'),
  ('QUESO RALLADO NAV. MANCHEGO'),
  ('SAL DE AJO TONES'),
  ('SAL DE GRANO'),
  ('SAL FINA'),
  ('SALCH. CORONA PAVO'),
  ('SALEROS RELLENAR'),
  ('SALSA BBQ'),
  ('SALSA BUFFALO'),
  ('SALSA DE OSTIÓN'),
  ('SALSA HAB. LOL-TUN'),
  ('SALSA HUICHOL'),
  ('SALSA HUICHOL NEG.'),
  ('SALSA INGLESA'),
  ('SALSA MAGGI'),
  ('SALSA MANGO HAB.'),
  ('SALSA MAYA'),
  ('SALSA REDHOT FRANK'),
  ('SALSA SIRACHA'),
  ('SALSA SOYA'),
  ('SALSA TABASCO GDE.'),
  ('SERV. BARRAMESA'),
  ('TAJÍN GRANDE'),
  ('TOCINO FUD'),
  ('TORTILLAS')
) AS t(nombre)
CROSS JOIN (SELECT id FROM public.categorias_insumos WHERE nombre = 'Abarrotes') AS cat;

-- Insertar insumos de Mariscos y Carnes
INSERT INTO public.insumos (nombre, categoria_id, unidad) 
SELECT nombre, cat.id, 'kg'
FROM (VALUES 
  ('CAMARON 61-70'),
  ('CAMARON 31-35'),
  ('CAMARON 21-25'),
  ('PULPO 2-4'),
  ('ATÚN MEDALLON pz'),
  ('MARLIN AHUMADO K.'),
  ('ROBALO (chicharrón)'),
  ('ROBALO (filete)'),
  ('SIERRA'),
  ('CAMARON VAPOR 25 a 30 gr'),
  ('CAMARON 7 A 11 GR'),
  ('CAMARON 12 - 25 GR'),
  ('CAMARON SECO K.'),
  ('BOLSAS OSTIÓN'),
  ('CALLO DE HACHA'),
  ('ALITAS'),
  ('BONELESS'),
  ('PIZZAS'),
  ('FILETE DE RES'),
  ('COSTILLA DE CERDO'),
  ('PESCADO P/SARANDEAR')
) AS t(nombre)
CROSS JOIN (SELECT id FROM public.categorias_insumos WHERE nombre = 'Mariscos y Carnes') AS cat;

-- Insertar insumos de Frutería
INSERT INTO public.insumos (nombre, categoria_id, unidad) 
SELECT nombre, cat.id, 'kg'
FROM (VALUES 
  ('AGUACATE'),
  ('AJO'),
  ('APIO'),
  ('CEBOLLA BLANCA'),
  ('CEBOLLA MORADA'),
  ('CHILE DE ARBOL SECO'),
  ('CHILE HABANERO'),
  ('CHILE HUAJILLO'),
  ('CHILE SERRANO'),
  ('CILANTRO'),
  ('CLAVO DE OLOR'),
  ('COMINO'),
  ('JITOMATE SALADETTE'),
  ('LAUREL'),
  ('LECHUGA ITALIANA'),
  ('LIMON PERSA SIN SEM.'),
  ('NARANJA PARA JUGO'),
  ('OREGANO'),
  ('PEPINO'),
  ('PIM. MORR. ROJO'),
  ('PIM. MORR. AMARILLO'),
  ('PIM. MORR. VER'),
  ('PIÑA'),
  ('PLATANO MACHO MAD.'),
  ('REPOLLO VERDE'),
  ('ZANAHORIA')
) AS t(nombre)
CROSS JOIN (SELECT id FROM public.categorias_insumos WHERE nombre = 'Frutería') AS cat;

-- Insertar insumos de Desechables
INSERT INTO public.insumos (nombre, categoria_id, unidad) 
SELECT nombre, cat.id, 'pz'
FROM (VALUES 
  ('HORCHATA DE LA INDIA'),
  ('BOLSA CAMISETA M. BL'),
  ('BOLSA JUM. 30X70X120'),
  ('BOLSA NEGRA 60 X 90'),
  ('CHAROLA 10 ZAR.'),
  ('CHAROLA 14 ZAR.'),
  ('CONTENEDO 6X6 HAMB'),
  ('CONTENEDOR 8X8 DIV.'),
  ('CUCHARA CH. DES.'),
  ('CUCHARA GDE. DES.'),
  ('GUANTES LATEX G'),
  ('MOLDE DE 1/2 DE UNICEL'),
  ('MOLDE DE 1/4 CON TAPA'),
  ('MOLDE JERICALLA'),
  ('R.BOLSA 5 K. DE BAJA D.'),
  ('R.BOLSA DE BAJA D.'),
  ('TAPA VASO 1L. ORIFICIO'),
  ('TAPA VASO 16 L. ORIFICIO'),
  ('TENEDORES GRANDES'),
  ('VASO CAFÉ 8 OZ C/TAPA'),
  ('VASO 1 L. UNICEL 32 OZ'),
  ('VASO 16 L'),
  ('VASO 4CH DE PLASTICO'),
  ('VASO 4CH UNIC C/TAPA'),
  ('7X7 SIN DIVISION')
) AS t(nombre)
CROSS JOIN (SELECT id FROM public.categorias_insumos WHERE nombre = 'Desechables') AS cat;

-- Insertar insumos de Limpieza
INSERT INTO public.insumos (nombre, categoria_id, unidad) 
SELECT nombre, cat.id, 'pz'
FROM (VALUES 
  ('CLORO 1 LITRO'),
  ('COFIA DE RED NEGRA'),
  ('DESENGRASANTE'),
  ('FABULOSO'),
  ('FIBRA CON ESPONJA'),
  ('FIBRA ESPONJA MET.'),
  ('JABÓN FOCA'),
  ('JABÓN LIQUIDO MANOS'),
  ('JABÓN SALVO'),
  ('PAPEL HIGIENICO JUMBO'),
  ('PAPEL TOALLA ROLLO'),
  ('ROLLO VITAFIL')
) AS t(nombre)
CROSS JOIN (SELECT id FROM public.categorias_insumos WHERE nombre = 'Artículos de Limpieza') AS cat;
