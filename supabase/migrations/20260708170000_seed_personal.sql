-- ============================================================
-- SEED de PERSONAL (empleados) por sucursal
--
-- Carga inicial del roster que dio la operación. Las listas vinieron
-- SIN área ni PIN, así que:
--   - area = 'mesero' (placeholder; se reasigna en la pestaña Personal).
--   - pin  = NULL     (la UI lo marca "sin PIN" en rojo; Diego lo captura).
--   - sucursal_principal_id = sucursal base para agruparlos en el roster.
--   - orden = posición en la lista original.
--
-- Idempotente: cada bloque solo inserta a quien NO exista ya con ese
-- (nombre, sucursal). Se puede correr de nuevo sin duplicar.
--
-- Sucursales: 'Del Valle', 'Cervecería', 'Las Brisas'. Solares queda
-- pendiente (falta lista).
-- ============================================================


-- ============================================================
-- DEL VALLE
-- ============================================================
INSERT INTO public.empleados (nombre, area, sucursal_principal_id, orden)
SELECT v.nombre, 'mesero', s.id, v.orden
FROM (VALUES
  ('ALICIA STEPHANY GARCIA SANTANA', 1),
  ('MARTINA ARTEAGA MUÑOZ', 2),
  ('ANGEL DAVID AGUILAR MEDINA', 3),
  ('BERTHA ESCOBAR DAMIAN', 4),
  ('CICTLALY MITZERY CARRANZA NAVA', 5),
  ('DAVID EDUARDO BAÑUELOS MARIN', 6),
  ('ERICA CALDERA NUÑEZ', 7),
  ('ERICK ULISES ESCAMILLA VALDERRAMA', 8),
  ('ESTEFANIA CIELO DE LA CRUZ HERNANDEZ', 9),
  ('FEDERICO SANDOVAL HERNANDEZ', 10),
  ('GENESIS VANESSA RAMIREZ PIÑA', 11),
  ('GRECIA DANELLE SANTOS PALACIOS', 12),
  ('GUSTAVO ADOLFO CORDOBA RAMIREZ', 13),
  ('IRVING SAMUEL CASTRO PASOS', 14),
  ('JESUS CAMACHO IBARRA', 15),
  ('JOSE HUMBERTO GONZALEZ SOTO', 16),
  ('JOSE LUIS GONZALEZ JIMENEZ', 17),
  ('JUAN CARLOS VARGAS BENITEZ', 18),
  ('KEVIN ISAI RAMOS HENRIQUEZ', 19),
  ('LILIANA DE LA CRUZ HERNANDEZ', 20),
  ('MAGALY ESCOBAR DAMIAN', 21),
  ('MARCO AURELIO AGUIRRE NAVARRO', 22),
  ('MARIA PICHARDO', 23),
  ('NADIA CAROLINA RODRIGUEZ GONZALEZ', 24),
  ('OMAR MISSAEL RUBIO MARTINEZ', 25),
  ('PABLO GIANCARLO PICHARDO GONZALEZ', 26),
  ('PAULINA ROCHA BECERRA', 27),
  ('REIVAJ ANDRES GARCIA DELGADO', 28),
  ('UZIEL ABISAI ARROYO DE LA CRUZ', 29),
  ('YARETZI ESTEFANIA JIMENEZ MEJIA', 30),
  ('YURIDIA YOVERY ISLAS MEZA', 31),
  ('EVELIA FLORES MEZA', 32),
  ('JESUS EDUARDO URIAS VALENZUELA', 33),
  ('JULIO HUMBERTO DE HARO QUEZADA', 34),
  ('LIBNA RAQUEL ARIAS LARA', 35),
  ('XAVIER IVAN BUSTOS SALMERON', 36),
  ('FRANCISCO JAVIER GARCIA REYNALDO', 37),
  ('LIMNY GISEL JIMENEZ LOPEZ', 38),
  ('ESMERALDA SARAY GARCIA JIMENEZ', 39),
  ('DIEGO ALEJANDRO AGUIRRE NAVARRO', 40),
  ('KAROL ABRIL MARTINEZ VILLASEÑOR', 41),
  ('LUZ ELENA CARRILLO MUÑOZ', 42),
  ('MARIA GUADALUPE NUÑEZ CARVAJAL', 43),
  ('WENDY MARLEN GARCIA SANTANA', 44),
  ('WILLIAMS ALFONSO BELTRAN CONCHAS', 45)
) AS v(nombre, orden)
JOIN public.sucursales s ON s.nombre = 'Del Valle'
WHERE NOT EXISTS (
  SELECT 1 FROM public.empleados e
  WHERE e.nombre = v.nombre AND e.sucursal_principal_id = s.id
);


-- ============================================================
-- CERVECERÍA
-- ============================================================
INSERT INTO public.empleados (nombre, area, sucursal_principal_id, orden)
SELECT v.nombre, 'mesero', s.id, v.orden
FROM (VALUES
  ('REMIGIO HUMBERTO ROSALES ZENTENO', 1),
  ('RODOLFO HERBERT OJEDA ZENTENO', 2),
  ('ALONDRA JAQUELINE MEDINA SAUCEDO', 3),
  ('ARTURO VALET PARKING', 4),
  ('BRITANNY VALERIA PEREZ SIMON', 5),
  ('CHRISTIAN', 6),
  ('DANILO ARIEL PEÑA DEL RIO', 7),
  ('DENILSON ARE PEÑA DEL RIO', 8),
  ('DIEGO ALEXANDER ESPARZA TAPIA', 9),
  ('EMMA ELIZABETH DIAZ MONTOYA', 10),
  ('EMMANUEL CONTRERAS TORRES', 11),
  ('FAUSTINO POLANCO HERNANDEZ', 12),
  ('FRIDA FERNANDA CHAVEZ LOPEZ', 13),
  ('JEHUDI MERAHI', 14),
  ('JESUS ALBERTO DE HARO QUEZADA', 15),
  ('JHOAN MARTIN DAVALOS CORRAL', 16),
  ('JOSE CARLOS MEZA RAMOS', 17),
  ('KARLA ZORAILA SANDOVAL ARROYO', 18),
  ('LILIANA ISABEL ESPARZA ROMERO', 19),
  ('MARLON FRANCISCO BELTRAN SOLIS', 20),
  ('MAURICIO ALEXANDER POLANCO DE LA CRUZ', 21),
  ('MILDRED GUADALUPE SORIA PARRA', 22),
  ('MIRIAM ELIZABETH CORTES VALENZUELA', 23),
  ('MONICA SELENE ARROYO DE LA CRUZ', 24),
  ('PERLA SINAHI TALAMANTES VALERA', 25),
  ('SAMUEL MARTIN MATANZO', 26),
  ('VANESSA JAQUELINE CRUZ HERNANDEZ', 27)
) AS v(nombre, orden)
JOIN public.sucursales s ON s.nombre = 'Cervecería'
WHERE NOT EXISTS (
  SELECT 1 FROM public.empleados e
  WHERE e.nombre = v.nombre AND e.sucursal_principal_id = s.id
);


-- ============================================================
-- LAS BRISAS
-- ============================================================
INSERT INTO public.empleados (nombre, area, sucursal_principal_id, orden)
SELECT v.nombre, 'mesero', s.id, v.orden
FROM (VALUES
  ('ALICIA NUNGARAY FLORES', 1),
  ('ALONDRA GUADALUPE ILLAN ALVARADO', 2),
  ('CINTHIA GUADALUPE APARICIO TOVAR', 3),
  ('GRACIELA RAZURA RAMIREZ', 4),
  ('JULIO FABIAN JAIME GARCIA', 5),
  ('PABLO JAVIER MONTES SAUCEDO', 6),
  ('ROCIO ISABEL GUTIERREZ PASTRANA', 7),
  ('XIMENA CABUTO GUIZAR', 8)
) AS v(nombre, orden)
JOIN public.sucursales s ON s.nombre = 'Las Brisas'
WHERE NOT EXISTS (
  SELECT 1 FROM public.empleados e
  WHERE e.nombre = v.nombre AND e.sucursal_principal_id = s.id
);
