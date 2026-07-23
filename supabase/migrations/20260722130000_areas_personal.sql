-- ============================================================
-- ÁREAS del PERSONAL (roster real de la operación, jul-2026)
--
-- El seed original cargó a todo el personal con area='mesero' de
-- placeholder. Aquí se asigna el área real de cada quien según la
-- lista que pasó la operación (Valle / Alameda / Rodeo).
--
--   - Se agregan dos puestos nuevos: 'contabilidad' y 'valet'.
--   - 'Barra' de la lista = 'barman'; 'Repartidor' = 'repartidor'.
--   - Altas nuevas en Del Valle: ALEXANDER EFRAIN VILLELA HERRERA
--     (mesero) y LUIS ERNESTO TRUJILLO MURILLO (cocina).
--   - EVELIA FLORES MEZA (Valle) y CHRISTIAN (Cervecería) ya no
--     vienen en la lista nueva: NO se tocan aquí (dar de baja a
--     mano en la pestaña Personal si aplica).
--
-- Mapeo de sucursales: VALLE=Del Valle, ALAMEDA=Cervecería,
-- RODEO=Las Brisas.
--
-- Idempotente: los UPDATE son por (nombre, sucursal) y los INSERT
-- verifican existencia.
-- ============================================================


-- ============================================================
-- BLOQUE 1 — Puestos nuevos en el constraint
-- ============================================================
ALTER TABLE public.empleados DROP CONSTRAINT IF EXISTS empleados_area_check;
ALTER TABLE public.empleados
  ADD CONSTRAINT empleados_area_check
  CHECK (area IN ('mesero', 'cocina', 'caja', 'repartidor', 'barman', 'contabilidad', 'valet'));


-- ============================================================
-- BLOQUE 2 — Áreas DEL VALLE
-- ============================================================
UPDATE public.empleados e
SET area = v.area
FROM (VALUES
  ('ALICIA STEPHANY GARCIA SANTANA', 'caja'),
  ('MARTINA ARTEAGA MUÑOZ', 'contabilidad'),
  ('ANGEL DAVID AGUILAR MEDINA', 'mesero'),
  ('BERTHA ESCOBAR DAMIAN', 'cocina'),
  ('CICTLALY MITZERY CARRANZA NAVA', 'caja'),
  ('DAVID EDUARDO BAÑUELOS MARIN', 'repartidor'),
  ('ERICA CALDERA NUÑEZ', 'caja'),
  ('ERICK ULISES ESCAMILLA VALDERRAMA', 'cocina'),
  ('ESTEFANIA CIELO DE LA CRUZ HERNANDEZ', 'cocina'),
  ('FEDERICO SANDOVAL HERNANDEZ', 'cocina'),
  ('GENESIS VANESSA RAMIREZ PIÑA', 'cocina'),
  ('GRECIA DANELLE SANTOS PALACIOS', 'caja'),
  ('GUSTAVO ADOLFO CORDOBA RAMIREZ', 'barman'),
  ('IRVING SAMUEL CASTRO PASOS', 'cocina'),
  ('JESUS CAMACHO IBARRA', 'cocina'),
  ('JOSE HUMBERTO GONZALEZ SOTO', 'cocina'),
  ('JOSE LUIS GONZALEZ JIMENEZ', 'barman'),
  ('JUAN CARLOS VARGAS BENITEZ', 'mesero'),
  ('KEVIN ISAI RAMOS HENRIQUEZ', 'repartidor'),
  ('LILIANA DE LA CRUZ HERNANDEZ', 'cocina'),
  ('MAGALY ESCOBAR DAMIAN', 'cocina'),
  ('MARCO AURELIO AGUIRRE NAVARRO', 'mesero'),
  ('MARIA PICHARDO', 'cocina'),
  ('NADIA CAROLINA RODRIGUEZ GONZALEZ', 'cocina'),
  ('OMAR MISSAEL RUBIO MARTINEZ', 'mesero'),
  ('PABLO GIANCARLO PICHARDO GONZALEZ', 'barman'),
  ('PAULINA ROCHA BECERRA', 'cocina'),
  ('REIVAJ ANDRES GARCIA DELGADO', 'mesero'),
  ('UZIEL ABISAI ARROYO DE LA CRUZ', 'cocina'),
  ('YARETZI ESTEFANIA JIMENEZ MEJIA', 'cocina'),
  ('YURIDIA YOVERY ISLAS MEZA', 'cocina'),
  ('JESUS EDUARDO URIAS VALENZUELA', 'mesero'),
  ('JULIO HUMBERTO DE HARO QUEZADA', 'mesero'),
  ('LIBNA RAQUEL ARIAS LARA', 'cocina'),
  ('XAVIER IVAN BUSTOS SALMERON', 'mesero'),
  ('FRANCISCO JAVIER GARCIA REYNALDO', 'mesero'),
  ('LIMNY GISEL JIMENEZ LOPEZ', 'mesero'),
  ('ESMERALDA SARAY GARCIA JIMENEZ', 'cocina'),
  ('DIEGO ALEJANDRO AGUIRRE NAVARRO', 'mesero'),
  ('KAROL ABRIL MARTINEZ VILLASEÑOR', 'mesero'),
  ('LUZ ELENA CARRILLO MUÑOZ', 'mesero'),
  ('MARIA GUADALUPE NUÑEZ CARVAJAL', 'contabilidad'),
  ('WENDY MARLEN GARCIA SANTANA', 'contabilidad'),
  ('WILLIAMS ALFONSO BELTRAN CONCHAS', 'mesero')
) AS v(nombre, area),
     public.sucursales s
WHERE s.nombre = 'Del Valle'
  AND e.sucursal_principal_id = s.id
  AND e.nombre = v.nombre;


-- ============================================================
-- BLOQUE 3 — Altas nuevas DEL VALLE
-- ============================================================
INSERT INTO public.empleados (nombre, area, sucursal_principal_id, orden)
SELECT v.nombre, v.area, s.id, v.orden
FROM (VALUES
  ('ALEXANDER EFRAIN VILLELA HERRERA', 'mesero', 46),
  ('LUIS ERNESTO TRUJILLO MURILLO', 'cocina', 47)
) AS v(nombre, area, orden)
JOIN public.sucursales s ON s.nombre = 'Del Valle'
WHERE NOT EXISTS (
  SELECT 1 FROM public.empleados e
  WHERE e.nombre = v.nombre AND e.sucursal_principal_id = s.id
);


-- ============================================================
-- BLOQUE 4 — Áreas CERVECERÍA (Alameda)
-- ============================================================
UPDATE public.empleados e
SET area = v.area
FROM (VALUES
  ('REMIGIO HUMBERTO ROSALES ZENTENO', 'caja'),
  ('RODOLFO HERBERT OJEDA ZENTENO', 'caja'),
  ('ALONDRA JAQUELINE MEDINA SAUCEDO', 'cocina'),
  ('ARTURO VALET PARKING', 'valet'),
  ('BRITANNY VALERIA PEREZ SIMON', 'mesero'),
  ('DANILO ARIEL PEÑA DEL RIO', 'mesero'),
  ('DENILSON ARE PEÑA DEL RIO', 'mesero'),
  ('DIEGO ALEXANDER ESPARZA TAPIA', 'mesero'),
  ('EMMA ELIZABETH DIAZ MONTOYA', 'cocina'),
  ('EMMANUEL CONTRERAS TORRES', 'mesero'),
  ('FAUSTINO POLANCO HERNANDEZ', 'cocina'),
  ('FRIDA FERNANDA CHAVEZ LOPEZ', 'cocina'),
  ('JEHUDI MERAHI', 'cocina'),
  ('JESUS ALBERTO DE HARO QUEZADA', 'mesero'),
  ('JHOAN MARTIN DAVALOS CORRAL', 'cocina'),
  ('JOSE CARLOS MEZA RAMOS', 'cocina'),
  ('KARLA ZORAILA SANDOVAL ARROYO', 'cocina'),
  ('LILIANA ISABEL ESPARZA ROMERO', 'mesero'),
  ('MARLON FRANCISCO BELTRAN SOLIS', 'barman'),
  ('MAURICIO ALEXANDER POLANCO DE LA CRUZ', 'barman'),
  ('MILDRED GUADALUPE SORIA PARRA', 'mesero'),
  ('MIRIAM ELIZABETH CORTES VALENZUELA', 'cocina'),
  ('MONICA SELENE ARROYO DE LA CRUZ', 'caja'),
  ('PERLA SINAHI TALAMANTES VALERA', 'cocina'),
  ('SAMUEL MARTIN MATANZO', 'mesero'),
  ('VANESSA JAQUELINE CRUZ HERNANDEZ', 'caja')
) AS v(nombre, area),
     public.sucursales s
WHERE s.nombre = 'Cervecería'
  AND e.sucursal_principal_id = s.id
  AND e.nombre = v.nombre;


-- ============================================================
-- BLOQUE 5 — Áreas LAS BRISAS (Rodeo)
-- ============================================================
UPDATE public.empleados e
SET area = v.area
FROM (VALUES
  ('ALICIA NUNGARAY FLORES', 'cocina'),
  ('ALONDRA GUADALUPE ILLAN ALVARADO', 'mesero'),
  ('CINTHIA GUADALUPE APARICIO TOVAR', 'cocina'),
  ('GRACIELA RAZURA RAMIREZ', 'cocina'),
  ('JULIO FABIAN JAIME GARCIA', 'cocina'),
  ('PABLO JAVIER MONTES SAUCEDO', 'mesero'),
  ('ROCIO ISABEL GUTIERREZ PASTRANA', 'caja'),
  ('XIMENA CABUTO GUIZAR', 'caja')
) AS v(nombre, area),
     public.sucursales s
WHERE s.nombre = 'Las Brisas'
  AND e.sucursal_principal_id = s.id
  AND e.nombre = v.nombre;
