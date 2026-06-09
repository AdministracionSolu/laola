-- ============================================================
-- SEED DEL MENÚ — generado por scripts/seed-menu.ts --sql
-- Idempotente: se puede correr más de una vez sin duplicar.
-- El upsert de precios NO toca `disponible` (toggles del staff).
-- ============================================================

-- ===== Entradas y Especialidades =====
INSERT INTO public.menu_categorias (nombre, orden) VALUES ('Entradas y Especialidades', 0) ON CONFLICT (nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Paté de camarón', 'Especialidad de la casa', false, NULL, 0
  FROM public.menu_categorias c WHERE c.nombre = 'Entradas y Especialidades'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 200g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Paté de camarón'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 218.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Paté de camarón' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 218.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Paté de camarón' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 218.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Paté de camarón' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 208.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Paté de camarón' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 300g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Paté de camarón'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 298.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Paté de camarón' AND v.nombre = 'Grande 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 298.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Paté de camarón' AND v.nombre = 'Grande 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 298.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Paté de camarón' AND v.nombre = 'Grande 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Camarones a la Cucaracha', 'Camarón frito entero', false, NULL, 1
  FROM public.menu_categorias c WHERE c.nombre = 'Entradas y Especialidades'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 200g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Camarones a la Cucaracha'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 218.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Camarones a la Cucaracha' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 218.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Camarones a la Cucaracha' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 218.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Camarones a la Cucaracha' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 208.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Camarones a la Cucaracha' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 300g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Camarones a la Cucaracha'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 298.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Camarones a la Cucaracha' AND v.nombre = 'Grande 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 298.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Camarones a la Cucaracha' AND v.nombre = 'Grande 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 298.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Camarones a la Cucaracha' AND v.nombre = 'Grande 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Marlín en estofado', 'En Solares porción 250g', false, NULL, 2
  FROM public.menu_categorias c WHERE c.nombre = 'Entradas y Especialidades'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 200g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Marlín en estofado'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 208.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Marlín en estofado' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 208.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Marlín en estofado' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 208.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Marlín en estofado' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 228.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Marlín en estofado' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 300g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Marlín en estofado'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Marlín en estofado' AND v.nombre = 'Grande 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Marlín en estofado' AND v.nombre = 'Grande 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Marlín en estofado' AND v.nombre = 'Grande 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Chicharrón de róbalo', NULL, false, NULL, 3
  FROM public.menu_categorias c WHERE c.nombre = 'Entradas y Especialidades'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 350g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Chicharrón de róbalo'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 268.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Chicharrón de róbalo' AND v.nombre = 'Mediano 350g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 268.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Chicharrón de róbalo' AND v.nombre = 'Mediano 350g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 268.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Chicharrón de róbalo' AND v.nombre = 'Mediano 350g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 228.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Chicharrón de róbalo' AND v.nombre = 'Mediano 350g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 500g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Chicharrón de róbalo'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 358.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Chicharrón de róbalo' AND v.nombre = 'Grande 500g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 358.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Chicharrón de róbalo' AND v.nombre = 'Grande 500g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 358.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Chicharrón de róbalo' AND v.nombre = 'Grande 500g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Chicharrón de pulpo', NULL, false, NULL, 4
  FROM public.menu_categorias c WHERE c.nombre = 'Entradas y Especialidades'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Única', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Chicharrón de pulpo'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 228.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Chicharrón de pulpo' AND v.nombre = 'Única' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Taco gobernador', 'Camarón con queso pimiento y cebolla', false, NULL, 5
  FROM public.menu_categorias c WHERE c.nombre = 'Entradas y Especialidades'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '1 pieza', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Taco gobernador'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 78.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Taco gobernador' AND v.nombre = '1 pieza' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 78.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Taco gobernador' AND v.nombre = '1 pieza' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 78.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Taco gobernador' AND v.nombre = '1 pieza' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 78.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Taco gobernador' AND v.nombre = '1 pieza' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Taco de atún', NULL, false, NULL, 6
  FROM public.menu_categorias c WHERE c.nombre = 'Entradas y Especialidades'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '1 pieza', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Taco de atún'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 49.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Taco de atún' AND v.nombre = '1 pieza' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Taco capeado', 'Camarón o pescado', false, '{"tipo":["Camarón","Pescado"]}'::jsonb, 7
  FROM public.menu_categorias c WHERE c.nombre = 'Entradas y Especialidades'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '1 pieza', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Taco capeado'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 78.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Taco capeado' AND v.nombre = '1 pieza' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Taquitos La Ola', 'Tacos de machaca de camarón', false, NULL, 8
  FROM public.menu_categorias c WHERE c.nombre = 'Entradas y Especialidades'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '3 piezas', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Taquitos La Ola'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 72.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Taquitos La Ola' AND v.nombre = '3 piezas' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Botana de camarón seco', NULL, false, NULL, 9
  FROM public.menu_categorias c WHERE c.nombre = 'Entradas y Especialidades'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Única 200g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Botana de camarón seco'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 148.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Botana de camarón seco' AND v.nombre = 'Única 200g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 148.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Botana de camarón seco' AND v.nombre = 'Única 200g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Carne asada', 'Incluye 2 tacos de frijoles salsas y tortillas', false, NULL, 10
  FROM public.menu_categorias c WHERE c.nombre = 'Entradas y Especialidades'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Única 500g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Carne asada'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 248.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Carne asada' AND v.nombre = 'Única 500g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Carnitas', 'Incluye salsas y tortillas', false, NULL, 11
  FROM public.menu_categorias c WHERE c.nombre = 'Entradas y Especialidades'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Única 500g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Carnitas'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 178.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Entradas y Especialidades' AND i.nombre = 'Carnitas' AND v.nombre = 'Única 500g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;

-- ===== Balazos =====
INSERT INTO public.menu_categorias (nombre, orden) VALUES ('Balazos', 1) ON CONFLICT (nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Balazo de ostión', 'Salseado con el marisco de tu preferencia', false, NULL, 0
  FROM public.menu_categorias c WHERE c.nombre = 'Balazos'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '15g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Balazos' AND i.nombre = 'Balazo de ostión'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 39.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Balazos' AND i.nombre = 'Balazo de ostión' AND v.nombre = '15g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 39.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Balazos' AND i.nombre = 'Balazo de ostión' AND v.nombre = '15g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 39.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Balazos' AND i.nombre = 'Balazo de ostión' AND v.nombre = '15g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 39.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Balazos' AND i.nombre = 'Balazo de ostión' AND v.nombre = '15g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Balazo de pulpo', NULL, false, NULL, 1
  FROM public.menu_categorias c WHERE c.nombre = 'Balazos'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '15g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Balazos' AND i.nombre = 'Balazo de pulpo'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 39.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Balazos' AND i.nombre = 'Balazo de pulpo' AND v.nombre = '15g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 39.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Balazos' AND i.nombre = 'Balazo de pulpo' AND v.nombre = '15g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 39.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Balazos' AND i.nombre = 'Balazo de pulpo' AND v.nombre = '15g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 39.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Balazos' AND i.nombre = 'Balazo de pulpo' AND v.nombre = '15g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Balazo de camarón cocido', NULL, false, NULL, 2
  FROM public.menu_categorias c WHERE c.nombre = 'Balazos'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '15g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Balazos' AND i.nombre = 'Balazo de camarón cocido'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 39.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Balazos' AND i.nombre = 'Balazo de camarón cocido' AND v.nombre = '15g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 39.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Balazos' AND i.nombre = 'Balazo de camarón cocido' AND v.nombre = '15g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 39.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Balazos' AND i.nombre = 'Balazo de camarón cocido' AND v.nombre = '15g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 39.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Balazos' AND i.nombre = 'Balazo de camarón cocido' AND v.nombre = '15g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Balazo de camarón curtido en limón', 'En Solares: camarón crudo', false, NULL, 3
  FROM public.menu_categorias c WHERE c.nombre = 'Balazos'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '15g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Balazos' AND i.nombre = 'Balazo de camarón curtido en limón'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 39.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Balazos' AND i.nombre = 'Balazo de camarón curtido en limón' AND v.nombre = '15g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 39.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Balazos' AND i.nombre = 'Balazo de camarón curtido en limón' AND v.nombre = '15g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 39.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Balazos' AND i.nombre = 'Balazo de camarón curtido en limón' AND v.nombre = '15g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 39.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Balazos' AND i.nombre = 'Balazo de camarón curtido en limón' AND v.nombre = '15g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Balazo de callo de hacha', NULL, false, NULL, 4
  FROM public.menu_categorias c WHERE c.nombre = 'Balazos'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '15g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Balazos' AND i.nombre = 'Balazo de callo de hacha'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 49.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Balazos' AND i.nombre = 'Balazo de callo de hacha' AND v.nombre = '15g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 49.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Balazos' AND i.nombre = 'Balazo de callo de hacha' AND v.nombre = '15g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 49.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Balazos' AND i.nombre = 'Balazo de callo de hacha' AND v.nombre = '15g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 51.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Balazos' AND i.nombre = 'Balazo de callo de hacha' AND v.nombre = '15g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Tabla La Ola', 'Arma tu tabla al gusto. Máximo 1 balazo de callo por tabla', false, NULL, 5
  FROM public.menu_categorias c WHERE c.nombre = 'Balazos'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '5 balazos', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Balazos' AND i.nombre = 'Tabla La Ola'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 159.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Balazos' AND i.nombre = 'Tabla La Ola' AND v.nombre = '5 balazos' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 159.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Balazos' AND i.nombre = 'Tabla La Ola' AND v.nombre = '5 balazos' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 159.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Balazos' AND i.nombre = 'Tabla La Ola' AND v.nombre = '5 balazos' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 168.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Balazos' AND i.nombre = 'Tabla La Ola' AND v.nombre = '5 balazos' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;

-- ===== Empanadas =====
INSERT INTO public.menu_categorias (nombre, orden) VALUES ('Empanadas', 2) ON CONFLICT (nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Empanada de queso', NULL, false, NULL, 0
  FROM public.menu_categorias c WHERE c.nombre = 'Empanadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '1 pieza', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de queso'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 62.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de queso' AND v.nombre = '1 pieza' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 62.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de queso' AND v.nombre = '1 pieza' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 62.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de queso' AND v.nombre = '1 pieza' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 62.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de queso' AND v.nombre = '1 pieza' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Empanada de camarón', NULL, false, NULL, 1
  FROM public.menu_categorias c WHERE c.nombre = 'Empanadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '1 pieza', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de camarón'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 74.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de camarón' AND v.nombre = '1 pieza' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 74.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de camarón' AND v.nombre = '1 pieza' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 74.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de camarón' AND v.nombre = '1 pieza' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 72.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de camarón' AND v.nombre = '1 pieza' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Empanada de camarón con queso', NULL, false, NULL, 2
  FROM public.menu_categorias c WHERE c.nombre = 'Empanadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '1 pieza', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de camarón con queso'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 82.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de camarón con queso' AND v.nombre = '1 pieza' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 82.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de camarón con queso' AND v.nombre = '1 pieza' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 82.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de camarón con queso' AND v.nombre = '1 pieza' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 82.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de camarón con queso' AND v.nombre = '1 pieza' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Empanada de pulpo', NULL, false, NULL, 3
  FROM public.menu_categorias c WHERE c.nombre = 'Empanadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '1 pieza', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de pulpo'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 74.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de pulpo' AND v.nombre = '1 pieza' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 74.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de pulpo' AND v.nombre = '1 pieza' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 74.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de pulpo' AND v.nombre = '1 pieza' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 72.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de pulpo' AND v.nombre = '1 pieza' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Empanada de pulpo con queso', NULL, false, NULL, 4
  FROM public.menu_categorias c WHERE c.nombre = 'Empanadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '1 pieza', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de pulpo con queso'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 82.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de pulpo con queso' AND v.nombre = '1 pieza' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 82.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de pulpo con queso' AND v.nombre = '1 pieza' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 82.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de pulpo con queso' AND v.nombre = '1 pieza' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 82.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de pulpo con queso' AND v.nombre = '1 pieza' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Empanada de ostión', NULL, false, NULL, 5
  FROM public.menu_categorias c WHERE c.nombre = 'Empanadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '1 pieza', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de ostión'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 74.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de ostión' AND v.nombre = '1 pieza' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 74.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de ostión' AND v.nombre = '1 pieza' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 74.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de ostión' AND v.nombre = '1 pieza' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 72.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de ostión' AND v.nombre = '1 pieza' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Empanada de ostión con queso', NULL, false, NULL, 6
  FROM public.menu_categorias c WHERE c.nombre = 'Empanadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '1 pieza', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de ostión con queso'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 82.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de ostión con queso' AND v.nombre = '1 pieza' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 82.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de ostión con queso' AND v.nombre = '1 pieza' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 82.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de ostión con queso' AND v.nombre = '1 pieza' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 82.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de ostión con queso' AND v.nombre = '1 pieza' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Empanada de marlín', NULL, false, NULL, 7
  FROM public.menu_categorias c WHERE c.nombre = 'Empanadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '1 pieza', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de marlín'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 72.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de marlín' AND v.nombre = '1 pieza' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Empanada de marlín con queso', NULL, false, NULL, 8
  FROM public.menu_categorias c WHERE c.nombre = 'Empanadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '1 pieza', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de marlín con queso'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 82.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada de marlín con queso' AND v.nombre = '1 pieza' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Empanada gobernador', 'Camarón con queso pimiento y cebolla', false, NULL, 9
  FROM public.menu_categorias c WHERE c.nombre = 'Empanadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '1 pieza', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada gobernador'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 82.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada gobernador' AND v.nombre = '1 pieza' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 82.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada gobernador' AND v.nombre = '1 pieza' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 82.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada gobernador' AND v.nombre = '1 pieza' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Empanada La Ola', 'Camarón y pulpo con queso pimiento y cebolla', false, NULL, 10
  FROM public.menu_categorias c WHERE c.nombre = 'Empanadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '1 pieza', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada La Ola'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 82.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada La Ola' AND v.nombre = '1 pieza' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 82.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada La Ola' AND v.nombre = '1 pieza' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 82.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada La Ola' AND v.nombre = '1 pieza' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 92.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Empanadas' AND i.nombre = 'Empanada La Ola' AND v.nombre = '1 pieza' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;

-- ===== Taquitos Montados =====
INSERT INTO public.menu_categorias (nombre, orden) VALUES ('Taquitos Montados', 3) ON CONFLICT (nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Taco dorado con ceviche de sierra', NULL, false, NULL, 0
  FROM public.menu_categorias c WHERE c.nombre = 'Taquitos Montados'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '1 pieza 80g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Taquitos Montados' AND i.nombre = 'Taco dorado con ceviche de sierra'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 49.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Taquitos Montados' AND i.nombre = 'Taco dorado con ceviche de sierra' AND v.nombre = '1 pieza 80g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 49.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Taquitos Montados' AND i.nombre = 'Taco dorado con ceviche de sierra' AND v.nombre = '1 pieza 80g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Taco dorado con marlín en estofado', NULL, false, NULL, 1
  FROM public.menu_categorias c WHERE c.nombre = 'Taquitos Montados'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '1 pieza 80g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Taquitos Montados' AND i.nombre = 'Taco dorado con marlín en estofado'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 49.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Taquitos Montados' AND i.nombre = 'Taco dorado con marlín en estofado' AND v.nombre = '1 pieza 80g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 49.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Taquitos Montados' AND i.nombre = 'Taco dorado con marlín en estofado' AND v.nombre = '1 pieza 80g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Taco dorado con ceviche de camarón', NULL, false, NULL, 2
  FROM public.menu_categorias c WHERE c.nombre = 'Taquitos Montados'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '1 pieza 80g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Taquitos Montados' AND i.nombre = 'Taco dorado con ceviche de camarón'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 69.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Taquitos Montados' AND i.nombre = 'Taco dorado con ceviche de camarón' AND v.nombre = '1 pieza 80g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 69.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Taquitos Montados' AND i.nombre = 'Taco dorado con ceviche de camarón' AND v.nombre = '1 pieza 80g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Taco dorado con paté de camarón', NULL, false, NULL, 3
  FROM public.menu_categorias c WHERE c.nombre = 'Taquitos Montados'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '1 pieza 80g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Taquitos Montados' AND i.nombre = 'Taco dorado con paté de camarón'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 69.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Taquitos Montados' AND i.nombre = 'Taco dorado con paté de camarón' AND v.nombre = '1 pieza 80g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 69.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Taquitos Montados' AND i.nombre = 'Taco dorado con paté de camarón' AND v.nombre = '1 pieza 80g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Taco dorado con aguachile de camarón', NULL, false, NULL, 4
  FROM public.menu_categorias c WHERE c.nombre = 'Taquitos Montados'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '1 pieza 80g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Taquitos Montados' AND i.nombre = 'Taco dorado con aguachile de camarón'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 69.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Taquitos Montados' AND i.nombre = 'Taco dorado con aguachile de camarón' AND v.nombre = '1 pieza 80g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 69.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Taquitos Montados' AND i.nombre = 'Taco dorado con aguachile de camarón' AND v.nombre = '1 pieza 80g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Taco dorado con camarón cocido', NULL, false, NULL, 5
  FROM public.menu_categorias c WHERE c.nombre = 'Taquitos Montados'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '1 pieza 80g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Taquitos Montados' AND i.nombre = 'Taco dorado con camarón cocido'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 69.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Taquitos Montados' AND i.nombre = 'Taco dorado con camarón cocido' AND v.nombre = '1 pieza 80g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 69.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Taquitos Montados' AND i.nombre = 'Taco dorado con camarón cocido' AND v.nombre = '1 pieza 80g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Taco dorado con pulpo', NULL, false, NULL, 6
  FROM public.menu_categorias c WHERE c.nombre = 'Taquitos Montados'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '1 pieza 80g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Taquitos Montados' AND i.nombre = 'Taco dorado con pulpo'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 69.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Taquitos Montados' AND i.nombre = 'Taco dorado con pulpo' AND v.nombre = '1 pieza 80g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 69.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Taquitos Montados' AND i.nombre = 'Taco dorado con pulpo' AND v.nombre = '1 pieza 80g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Taco dorado especial La Ola', NULL, false, NULL, 7
  FROM public.menu_categorias c WHERE c.nombre = 'Taquitos Montados'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '1 pieza 80g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Taquitos Montados' AND i.nombre = 'Taco dorado especial La Ola'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 99.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Taquitos Montados' AND i.nombre = 'Taco dorado especial La Ola' AND v.nombre = '1 pieza 80g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 99.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Taquitos Montados' AND i.nombre = 'Taco dorado especial La Ola' AND v.nombre = '1 pieza 80g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Taco dorado especial de paté de camarón', NULL, false, NULL, 8
  FROM public.menu_categorias c WHERE c.nombre = 'Taquitos Montados'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '1 pieza 80g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Taquitos Montados' AND i.nombre = 'Taco dorado especial de paté de camarón'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 89.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Taquitos Montados' AND i.nombre = 'Taco dorado especial de paté de camarón' AND v.nombre = '1 pieza 80g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 89.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Taquitos Montados' AND i.nombre = 'Taco dorado especial de paté de camarón' AND v.nombre = '1 pieza 80g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;

-- ===== Tostadas =====
INSERT INTO public.menu_categorias (nombre, orden) VALUES ('Tostadas', 4) ON CONFLICT (nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Tostada de ceviche de sierra', NULL, false, NULL, 0
  FROM public.menu_categorias c WHERE c.nombre = 'Tostadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '120g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de ceviche de sierra'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 79.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de ceviche de sierra' AND v.nombre = '120g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 79.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de ceviche de sierra' AND v.nombre = '120g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 79.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de ceviche de sierra' AND v.nombre = '120g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 92.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de ceviche de sierra' AND v.nombre = '120g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Tostada de ceviche de camarón', NULL, false, NULL, 1
  FROM public.menu_categorias c WHERE c.nombre = 'Tostadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '120g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de ceviche de camarón'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de ceviche de camarón' AND v.nombre = '120g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de ceviche de camarón' AND v.nombre = '120g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de ceviche de camarón' AND v.nombre = '120g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 112.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de ceviche de camarón' AND v.nombre = '120g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Tostada de ceviche de camarón cocido', NULL, false, NULL, 2
  FROM public.menu_categorias c WHERE c.nombre = 'Tostadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '120g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de ceviche de camarón cocido'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de ceviche de camarón cocido' AND v.nombre = '120g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de ceviche de camarón cocido' AND v.nombre = '120g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de ceviche de camarón cocido' AND v.nombre = '120g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 112.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de ceviche de camarón cocido' AND v.nombre = '120g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Tostada de ceviche de camarón seco', NULL, false, NULL, 3
  FROM public.menu_categorias c WHERE c.nombre = 'Tostadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '120g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de ceviche de camarón seco'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de ceviche de camarón seco' AND v.nombre = '120g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de ceviche de camarón seco' AND v.nombre = '120g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de ceviche de camarón seco' AND v.nombre = '120g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 112.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de ceviche de camarón seco' AND v.nombre = '120g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Tostada de ceviche de róbalo en cuadritos', NULL, false, NULL, 4
  FROM public.menu_categorias c WHERE c.nombre = 'Tostadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '120g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de ceviche de róbalo en cuadritos'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de ceviche de róbalo en cuadritos' AND v.nombre = '120g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de ceviche de róbalo en cuadritos' AND v.nombre = '120g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de ceviche de róbalo en cuadritos' AND v.nombre = '120g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 112.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de ceviche de róbalo en cuadritos' AND v.nombre = '120g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Tostada de aguachile de camarón', NULL, false, NULL, 5
  FROM public.menu_categorias c WHERE c.nombre = 'Tostadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '120g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de aguachile de camarón'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de aguachile de camarón' AND v.nombre = '120g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de aguachile de camarón' AND v.nombre = '120g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de aguachile de camarón' AND v.nombre = '120g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 112.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de aguachile de camarón' AND v.nombre = '120g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Tostada de aguachile de camarón seco', NULL, false, NULL, 6
  FROM public.menu_categorias c WHERE c.nombre = 'Tostadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '120g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de aguachile de camarón seco'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 112.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de aguachile de camarón seco' AND v.nombre = '120g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Tostada de aguachile de pulpo', NULL, false, NULL, 7
  FROM public.menu_categorias c WHERE c.nombre = 'Tostadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '120g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de aguachile de pulpo'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 112.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de aguachile de pulpo' AND v.nombre = '120g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Tostada de camarón cocido', NULL, false, NULL, 8
  FROM public.menu_categorias c WHERE c.nombre = 'Tostadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '120g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de camarón cocido'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de camarón cocido' AND v.nombre = '120g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de camarón cocido' AND v.nombre = '120g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de camarón cocido' AND v.nombre = '120g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 112.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de camarón cocido' AND v.nombre = '120g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Tostada de pulpo', NULL, false, NULL, 9
  FROM public.menu_categorias c WHERE c.nombre = 'Tostadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '120g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de pulpo'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de pulpo' AND v.nombre = '120g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de pulpo' AND v.nombre = '120g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de pulpo' AND v.nombre = '120g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 112.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de pulpo' AND v.nombre = '120g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Tostada de paté de camarón', NULL, false, NULL, 10
  FROM public.menu_categorias c WHERE c.nombre = 'Tostadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '120g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de paté de camarón'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de paté de camarón' AND v.nombre = '120g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de paté de camarón' AND v.nombre = '120g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de paté de camarón' AND v.nombre = '120g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 112.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de paté de camarón' AND v.nombre = '120g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Tostada de marlín en estofado', NULL, false, NULL, 11
  FROM public.menu_categorias c WHERE c.nombre = 'Tostadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '120g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de marlín en estofado'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de marlín en estofado' AND v.nombre = '120g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de marlín en estofado' AND v.nombre = '120g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de marlín en estofado' AND v.nombre = '120g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 112.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de marlín en estofado' AND v.nombre = '120g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Tostada de atún', NULL, false, NULL, 12
  FROM public.menu_categorias c WHERE c.nombre = 'Tostadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '120g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de atún'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de atún' AND v.nombre = '120g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de atún' AND v.nombre = '120g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de atún' AND v.nombre = '120g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 112.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de atún' AND v.nombre = '120g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Tostada de callo de hacha', NULL, false, NULL, 13
  FROM public.menu_categorias c WHERE c.nombre = 'Tostadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '120g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de callo de hacha'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de callo de hacha' AND v.nombre = '120g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de callo de hacha' AND v.nombre = '120g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de callo de hacha' AND v.nombre = '120g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 182.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas' AND i.nombre = 'Tostada de callo de hacha' AND v.nombre = '120g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;

-- ===== Tostadas Especiales =====
INSERT INTO public.menu_categorias (nombre, orden) VALUES ('Tostadas Especiales', 5) ON CONFLICT (nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Especial de mariscos', 'Camarón cocido camarón curtido en limón y pulpo sobre 2 tostadas. Solares 200g', false, NULL, 0
  FROM public.menu_categorias c WHERE c.nombre = 'Tostadas Especiales'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '2 tostadas 250g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial de mariscos'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 238.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial de mariscos' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 238.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial de mariscos' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 238.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial de mariscos' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 228.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial de mariscos' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Especial de mariscos con callo de hacha', 'Camarón cocido camarón curtido pulpo y callo de hacha', false, NULL, 1
  FROM public.menu_categorias c WHERE c.nombre = 'Tostadas Especiales'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '2 tostadas 250g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial de mariscos con callo de hacha'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 268.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial de mariscos con callo de hacha' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 268.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial de mariscos con callo de hacha' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 268.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial de mariscos con callo de hacha' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 248.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial de mariscos con callo de hacha' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Especial Santa Cruz', 'Mezcla de mariscos con base de ceviche de camarón seco', false, NULL, 2
  FROM public.menu_categorias c WHERE c.nombre = 'Tostadas Especiales'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '2 tostadas 250g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial Santa Cruz'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 258.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial Santa Cruz' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 258.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial Santa Cruz' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 258.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial Santa Cruz' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 248.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial Santa Cruz' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Especial Santa Cruz con callo de hacha', NULL, false, NULL, 3
  FROM public.menu_categorias c WHERE c.nombre = 'Tostadas Especiales'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '2 tostadas 250g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial Santa Cruz con callo de hacha'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 298.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial Santa Cruz con callo de hacha' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 298.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial Santa Cruz con callo de hacha' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 298.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial Santa Cruz con callo de hacha' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 268.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial Santa Cruz con callo de hacha' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Especial La Ola', 'Mezcla de mariscos con base de ceviche de sierra. ESPECIALIDAD', false, NULL, 4
  FROM public.menu_categorias c WHERE c.nombre = 'Tostadas Especiales'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '2 tostadas 250g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial La Ola'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 248.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial La Ola' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 248.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial La Ola' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 248.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial La Ola' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 248.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial La Ola' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Especial La Ola con paté de camarón', 'Mezcla de mariscos con base de paté de camarón', false, NULL, 5
  FROM public.menu_categorias c WHERE c.nombre = 'Tostadas Especiales'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '2 tostadas 250g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial La Ola con paté de camarón'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 258.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial La Ola con paté de camarón' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 258.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial La Ola con paté de camarón' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 258.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial La Ola con paté de camarón' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 258.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial La Ola con paté de camarón' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Especial de paté de camarón', 'Camarón cocido con base de paté de camarón', false, NULL, 6
  FROM public.menu_categorias c WHERE c.nombre = 'Tostadas Especiales'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '2 tostadas 250g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial de paté de camarón'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 258.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial de paté de camarón' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 258.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial de paté de camarón' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 258.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial de paté de camarón' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 228.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial de paté de camarón' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'San Blas', 'Mezcla de mariscos y callo de hacha con base de ceviche de sierra. RECOMENDADA', false, NULL, 7
  FROM public.menu_categorias c WHERE c.nombre = 'Tostadas Especiales'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '2 tostadas 250g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'San Blas'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'San Blas' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'San Blas' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'San Blas' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 268.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'San Blas' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'San Blas con paté de camarón', NULL, false, NULL, 8
  FROM public.menu_categorias c WHERE c.nombre = 'Tostadas Especiales'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '2 tostadas 250g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'San Blas con paté de camarón'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 298.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'San Blas con paté de camarón' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 298.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'San Blas con paté de camarón' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 298.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'San Blas con paté de camarón' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 268.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'San Blas con paté de camarón' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Especial de ceviche La Ola', 'Mezcla de ceviches de camarón curtido camarón cocido y pulpo', false, NULL, 9
  FROM public.menu_categorias c WHERE c.nombre = 'Tostadas Especiales'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '2 tostadas 250g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial de ceviche La Ola'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 238.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial de ceviche La Ola' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 238.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial de ceviche La Ola' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 238.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial de ceviche La Ola' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 228.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial de ceviche La Ola' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Especial de ceviche San Blas', 'Mezcla de ceviches con callo de hacha', false, NULL, 10
  FROM public.menu_categorias c WHERE c.nombre = 'Tostadas Especiales'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '2 tostadas 250g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial de ceviche San Blas'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 268.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial de ceviche San Blas' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 268.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial de ceviche San Blas' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 268.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial de ceviche San Blas' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 248.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial de ceviche San Blas' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Especial Matanchen', 'Mezcla de mariscos sobre tostadas con mayonesa y base de ceviche de sierra. En Solares incluye callo de hacha', false, NULL, 11
  FROM public.menu_categorias c WHERE c.nombre = 'Tostadas Especiales'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '2 tostadas 250g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial Matanchen'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 248.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial Matanchen' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 248.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial Matanchen' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 248.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial Matanchen' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 268.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial Matanchen' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Especial Matanchen con callo de hacha', NULL, false, NULL, 12
  FROM public.menu_categorias c WHERE c.nombre = 'Tostadas Especiales'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '2 tostadas 250g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial Matanchen con callo de hacha'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial Matanchen con callo de hacha' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial Matanchen con callo de hacha' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial Matanchen con callo de hacha' AND v.nombre = '2 tostadas 250g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Mexcalteca', 'Camarón seco y camarón en aguachile', false, NULL, 13
  FROM public.menu_categorias c WHERE c.nombre = 'Tostadas Especiales'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '2 tostadas 200g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Mexcalteca'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 228.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Mexcalteca' AND v.nombre = '2 tostadas 200g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Especial del Pacífico', 'Ceviche de sierra montado con callo de hacha de Sonora', false, NULL, 14
  FROM public.menu_categorias c WHERE c.nombre = 'Tostadas Especiales'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '2 tostadas 200g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial del Pacífico'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 296.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Tostadas Especiales' AND i.nombre = 'Especial del Pacífico' AND v.nombre = '2 tostadas 200g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;

-- ===== Cazuelitas =====
INSERT INTO public.menu_categorias (nombre, orden) VALUES ('Cazuelitas', 6) ON CONFLICT (nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Cazuelita de camarón cocido', 'Jugo caliente. Solares porción única 250g', false, NULL, 0
  FROM public.menu_categorias c WHERE c.nombre = 'Cazuelitas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 200g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita de camarón cocido'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita de camarón cocido' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita de camarón cocido' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita de camarón cocido' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 228.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita de camarón cocido' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 300g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita de camarón cocido'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita de camarón cocido' AND v.nombre = 'Grande 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita de camarón cocido' AND v.nombre = 'Grande 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita de camarón cocido' AND v.nombre = 'Grande 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Cazuelita de pulpo', NULL, false, NULL, 1
  FROM public.menu_categorias c WHERE c.nombre = 'Cazuelitas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 200g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita de pulpo'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita de pulpo' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita de pulpo' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita de pulpo' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 228.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita de pulpo' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 300g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita de pulpo'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita de pulpo' AND v.nombre = 'Grande 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita de pulpo' AND v.nombre = 'Grande 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita de pulpo' AND v.nombre = 'Grande 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Cazuelita mixta', 'Camarón y pulpo', false, NULL, 2
  FROM public.menu_categorias c WHERE c.nombre = 'Cazuelitas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 200g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita mixta'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita mixta' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita mixta' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita mixta' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 228.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita mixta' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 300g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita mixta'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita mixta' AND v.nombre = 'Grande 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita mixta' AND v.nombre = 'Grande 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita mixta' AND v.nombre = 'Grande 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Cazuelita La Ola', 'Camarón cocido pulpo y ostión', false, NULL, 3
  FROM public.menu_categorias c WHERE c.nombre = 'Cazuelitas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 200g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita La Ola'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita La Ola' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita La Ola' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita La Ola' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 228.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita La Ola' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 300g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita La Ola'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita La Ola' AND v.nombre = 'Grande 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita La Ola' AND v.nombre = 'Grande 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita La Ola' AND v.nombre = 'Grande 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Cazuelita especial Tanilo', 'Camarón cocido pulpo y ceviche de sierra', false, NULL, 4
  FROM public.menu_categorias c WHERE c.nombre = 'Cazuelitas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 200g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita especial Tanilo'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita especial Tanilo' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita especial Tanilo' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita especial Tanilo' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 228.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita especial Tanilo' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 300g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita especial Tanilo'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita especial Tanilo' AND v.nombre = 'Grande 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita especial Tanilo' AND v.nombre = 'Grande 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita especial Tanilo' AND v.nombre = 'Grande 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Cazuelita especial San Blas', 'Camarón cocido pulpo ostión y callo de hacha', false, NULL, 5
  FROM public.menu_categorias c WHERE c.nombre = 'Cazuelitas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 200g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita especial San Blas'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 238.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita especial San Blas' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 238.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita especial San Blas' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 238.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita especial San Blas' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 268.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita especial San Blas' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 300g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita especial San Blas'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 298.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita especial San Blas' AND v.nombre = 'Grande 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 298.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita especial San Blas' AND v.nombre = 'Grande 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 298.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cazuelitas' AND i.nombre = 'Cazuelita especial San Blas' AND v.nombre = 'Grande 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;

-- ===== Cocteles =====
INSERT INTO public.menu_categorias (nombre, orden) VALUES ('Cocteles', 7) ON CONFLICT (nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Vaso loco', 'Camarón curtido en limón sazonado con salsa huichol. Solares porción única 250g', false, NULL, 0
  FROM public.menu_categorias c WHERE c.nombre = 'Cocteles'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 200g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Vaso loco'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Vaso loco' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Vaso loco' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Vaso loco' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 228.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Vaso loco' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 300g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Vaso loco'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Vaso loco' AND v.nombre = 'Grande 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Vaso loco' AND v.nombre = 'Grande 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Vaso loco' AND v.nombre = 'Grande 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Vaso loco especial', 'Camarón curtido y callo de hacha con salsa huichol', false, NULL, 1
  FROM public.menu_categorias c WHERE c.nombre = 'Cocteles'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 200g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Vaso loco especial'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 238.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Vaso loco especial' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 238.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Vaso loco especial' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 238.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Vaso loco especial' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 268.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Vaso loco especial' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 300g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Vaso loco especial'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 298.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Vaso loco especial' AND v.nombre = 'Grande 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 298.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Vaso loco especial' AND v.nombre = 'Grande 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 298.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Vaso loco especial' AND v.nombre = 'Grande 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Vaso macho', 'Camarón curtido y ostión con salsa habanera', false, NULL, 2
  FROM public.menu_categorias c WHERE c.nombre = 'Cocteles'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 200g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Vaso macho'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Vaso macho' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Vaso macho' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Vaso macho' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 228.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Vaso macho' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 300g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Vaso macho'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Vaso macho' AND v.nombre = 'Grande 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Vaso macho' AND v.nombre = 'Grande 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Vaso macho' AND v.nombre = 'Grande 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Vaso macho especial', 'Camarón curtido ostión y callo de hacha con salsa habanera', false, NULL, 3
  FROM public.menu_categorias c WHERE c.nombre = 'Cocteles'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 200g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Vaso macho especial'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 238.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Vaso macho especial' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 238.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Vaso macho especial' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 238.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Vaso macho especial' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 268.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Vaso macho especial' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 300g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Vaso macho especial'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 298.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Vaso macho especial' AND v.nombre = 'Grande 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 298.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Vaso macho especial' AND v.nombre = 'Grande 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 298.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Vaso macho especial' AND v.nombre = 'Grande 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Clamariscos', 'Camarón cocido pulpo y ostión con Clamato preparado. En Solares incluye callo de hacha', false, NULL, 4
  FROM public.menu_categorias c WHERE c.nombre = 'Cocteles'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 200g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Clamariscos'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Clamariscos' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Clamariscos' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Clamariscos' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 268.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Clamariscos' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 300g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Clamariscos'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Clamariscos' AND v.nombre = 'Grande 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Clamariscos' AND v.nombre = 'Grande 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Clamariscos' AND v.nombre = 'Grande 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Clamariscos con callo de hacha', NULL, false, NULL, 5
  FROM public.menu_categorias c WHERE c.nombre = 'Cocteles'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 200g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Clamariscos con callo de hacha'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 238.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Clamariscos con callo de hacha' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 238.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Clamariscos con callo de hacha' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 238.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Clamariscos con callo de hacha' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 300g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Clamariscos con callo de hacha'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 298.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Clamariscos con callo de hacha' AND v.nombre = 'Grande 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 298.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Clamariscos con callo de hacha' AND v.nombre = 'Grande 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 298.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Clamariscos con callo de hacha' AND v.nombre = 'Grande 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Clamacallo', 'Clamato y callo de hacha', false, NULL, 6
  FROM public.menu_categorias c WHERE c.nombre = 'Cocteles'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Única 250g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Clamacallo'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 468.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Clamacallo' AND v.nombre = 'Única 250g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Chilangada', 'Camarón cocido pulpo y ostión con jugo de camarón frío y catsup. En Solares incluye callo de hacha', false, NULL, 7
  FROM public.menu_categorias c WHERE c.nombre = 'Cocteles'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 200g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Chilangada'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Chilangada' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Chilangada' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Chilangada' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 268.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Chilangada' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 300g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Chilangada'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Chilangada' AND v.nombre = 'Grande 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Chilangada' AND v.nombre = 'Grande 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Chilangada' AND v.nombre = 'Grande 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Chilangada con callo de hacha', NULL, false, NULL, 8
  FROM public.menu_categorias c WHERE c.nombre = 'Cocteles'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 200g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Chilangada con callo de hacha'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 238.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Chilangada con callo de hacha' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 238.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Chilangada con callo de hacha' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 238.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Chilangada con callo de hacha' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 300g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Chilangada con callo de hacha'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 298.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Chilangada con callo de hacha' AND v.nombre = 'Grande 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 298.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Chilangada con callo de hacha' AND v.nombre = 'Grande 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 298.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Chilangada con callo de hacha' AND v.nombre = 'Grande 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Coctel de camarón', 'Camarón cocido con pepino cebolla jugo de camarón frío y catsup', false, NULL, 9
  FROM public.menu_categorias c WHERE c.nombre = 'Cocteles'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 200g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Coctel de camarón'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Coctel de camarón' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Coctel de camarón' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 300g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Coctel de camarón'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Coctel de camarón' AND v.nombre = 'Grande 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Coctel de camarón' AND v.nombre = 'Grande 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Coctel de pulpo', NULL, false, NULL, 10
  FROM public.menu_categorias c WHERE c.nombre = 'Cocteles'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 200g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Coctel de pulpo'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Coctel de pulpo' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Coctel de pulpo' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 300g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Coctel de pulpo'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Coctel de pulpo' AND v.nombre = 'Grande 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Coctel de pulpo' AND v.nombre = 'Grande 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Coctel de ostión', 'Ostión de placer sancochado al natural', false, NULL, 11
  FROM public.menu_categorias c WHERE c.nombre = 'Cocteles'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 200g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Coctel de ostión'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Coctel de ostión' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Coctel de ostión' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 148.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Coctel de ostión' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 208.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Coctel de ostión' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 300g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Coctel de ostión'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Coctel de ostión' AND v.nombre = 'Grande 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Coctel de ostión' AND v.nombre = 'Grande 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Coctel de ostión' AND v.nombre = 'Grande 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Campechana fría', 'Camarón cocido pulpo y ostión con aguacate pepino y cebolla', false, NULL, 12
  FROM public.menu_categorias c WHERE c.nombre = 'Cocteles'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 200g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Campechana fría'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Campechana fría' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 198.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Campechana fría' AND v.nombre = 'Mediano 200g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 300g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Campechana fría'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Campechana fría' AND v.nombre = 'Grande 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 278.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cocteles' AND i.nombre = 'Campechana fría' AND v.nombre = 'Grande 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;

-- ===== Ceviches =====
INSERT INTO public.menu_categorias (nombre, orden) VALUES ('Ceviches', 8) ON CONFLICT (nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Ceviche de sierra estilo Nayarit', 'Solares porción única 300g', false, NULL, 0
  FROM public.menu_categorias c WHERE c.nombre = 'Ceviches'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de sierra estilo Nayarit'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 178.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de sierra estilo Nayarit' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 178.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de sierra estilo Nayarit' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 178.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de sierra estilo Nayarit' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 208.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de sierra estilo Nayarit' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 400g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de sierra estilo Nayarit'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 208.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de sierra estilo Nayarit' AND v.nombre = 'Grande 400g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 208.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de sierra estilo Nayarit' AND v.nombre = 'Grande 400g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 208.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de sierra estilo Nayarit' AND v.nombre = 'Grande 400g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Ceviche de camarón', 'Camarón curtido en limón con pepino jitomate cebolla cilantro y serrano', false, NULL, 1
  FROM public.menu_categorias c WHERE c.nombre = 'Ceviches'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de camarón'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de camarón' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de camarón' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de camarón' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de camarón' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 400g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de camarón'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de camarón' AND v.nombre = 'Grande 400g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de camarón' AND v.nombre = 'Grande 400g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de camarón' AND v.nombre = 'Grande 400g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Ceviche de camarón cocido', NULL, false, NULL, 2
  FROM public.menu_categorias c WHERE c.nombre = 'Ceviches'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de camarón cocido'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de camarón cocido' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de camarón cocido' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de camarón cocido' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de camarón cocido' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 400g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de camarón cocido'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de camarón cocido' AND v.nombre = 'Grande 400g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de camarón cocido' AND v.nombre = 'Grande 400g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de camarón cocido' AND v.nombre = 'Grande 400g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Ceviche de pulpo', NULL, false, NULL, 3
  FROM public.menu_categorias c WHERE c.nombre = 'Ceviches'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Única 300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de pulpo'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de pulpo' AND v.nombre = 'Única 300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Ceviche especial La Ola', 'Camarón cocido camarón curtido y pulpo', false, NULL, 4
  FROM public.menu_categorias c WHERE c.nombre = 'Ceviches'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche especial La Ola'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche especial La Ola' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche especial La Ola' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche especial La Ola' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche especial La Ola' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 400g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche especial La Ola'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche especial La Ola' AND v.nombre = 'Grande 400g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche especial La Ola' AND v.nombre = 'Grande 400g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche especial La Ola' AND v.nombre = 'Grande 400g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Ceviche de camarón seco', NULL, false, NULL, 5
  FROM public.menu_categorias c WHERE c.nombre = 'Ceviches'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de camarón seco'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de camarón seco' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de camarón seco' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de camarón seco' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de camarón seco' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 400g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de camarón seco'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de camarón seco' AND v.nombre = 'Grande 400g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de camarón seco' AND v.nombre = 'Grande 400g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de camarón seco' AND v.nombre = 'Grande 400g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Ceviche Mexcalteca', 'Camarón crudo y camarón seco', false, NULL, 6
  FROM public.menu_categorias c WHERE c.nombre = 'Ceviches'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Única 300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche Mexcalteca'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche Mexcalteca' AND v.nombre = 'Única 300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Ceviche especial Santa Cruz', 'Camarón cocido camarón curtido pulpo y camarón seco', false, NULL, 7
  FROM public.menu_categorias c WHERE c.nombre = 'Ceviches'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche especial Santa Cruz'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche especial Santa Cruz' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche especial Santa Cruz' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche especial Santa Cruz' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche especial Santa Cruz' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 400g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche especial Santa Cruz'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche especial Santa Cruz' AND v.nombre = 'Grande 400g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche especial Santa Cruz' AND v.nombre = 'Grande 400g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche especial Santa Cruz' AND v.nombre = 'Grande 400g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Ceviche Santa Cruz + callo de hacha', NULL, false, NULL, 8
  FROM public.menu_categorias c WHERE c.nombre = 'Ceviches'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche Santa Cruz + callo de hacha'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche Santa Cruz + callo de hacha' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche Santa Cruz + callo de hacha' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche Santa Cruz + callo de hacha' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 362.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche Santa Cruz + callo de hacha' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 400g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche Santa Cruz + callo de hacha'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 468.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche Santa Cruz + callo de hacha' AND v.nombre = 'Grande 400g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 468.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche Santa Cruz + callo de hacha' AND v.nombre = 'Grande 400g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 468.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche Santa Cruz + callo de hacha' AND v.nombre = 'Grande 400g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Ceviche de róbalo', 'Filete de róbalo fresco en cuadritos con toque de habanero', false, NULL, 9
  FROM public.menu_categorias c WHERE c.nombre = 'Ceviches'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de róbalo'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 378.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de róbalo' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 378.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de róbalo' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 378.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de róbalo' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 362.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de róbalo' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 400g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de róbalo'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 458.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de róbalo' AND v.nombre = 'Grande 400g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 458.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de róbalo' AND v.nombre = 'Grande 400g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 458.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de róbalo' AND v.nombre = 'Grande 400g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Ceviche San Blas', 'Camarón cocido camarón curtido pulpo y callo de hacha', false, NULL, 10
  FROM public.menu_categorias c WHERE c.nombre = 'Ceviches'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche San Blas'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche San Blas' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche San Blas' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche San Blas' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 362.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche San Blas' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 400g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche San Blas'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 468.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche San Blas' AND v.nombre = 'Grande 400g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 468.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche San Blas' AND v.nombre = 'Grande 400g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 468.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche San Blas' AND v.nombre = 'Grande 400g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Ceviche de atún', 'Atún fresco en cubos bañado en salsas negras. En Solares: Negro de atún', false, NULL, 11
  FROM public.menu_categorias c WHERE c.nombre = 'Ceviches'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de atún'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 378.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de atún' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 378.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de atún' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 378.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de atún' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 362.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de atún' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 400g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de atún'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 458.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de atún' AND v.nombre = 'Grande 400g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 458.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de atún' AND v.nombre = 'Grande 400g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 458.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ceviches' AND i.nombre = 'Ceviche de atún' AND v.nombre = 'Grande 400g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;

-- ===== Ensaladas =====
INSERT INTO public.menu_categorias (nombre, orden) VALUES ('Ensaladas', 9) ON CONFLICT (nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Ensalada de camarón cocido', 'Pídela al natural salseada o bañada con chiltepín. Solares porción única 300g', false, '{"estilo":["Al natural","Salseada","Bañada con chiltepín"]}'::jsonb, 0
  FROM public.menu_categorias c WHERE c.nombre = 'Ensaladas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada de camarón cocido'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada de camarón cocido' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada de camarón cocido' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada de camarón cocido' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada de camarón cocido' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 400g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada de camarón cocido'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada de camarón cocido' AND v.nombre = 'Grande 400g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada de camarón cocido' AND v.nombre = 'Grande 400g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada de camarón cocido' AND v.nombre = 'Grande 400g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Ensalada de pulpo', NULL, false, '{"estilo":["Al natural","Salseada","Bañada con chiltepín"]}'::jsonb, 1
  FROM public.menu_categorias c WHERE c.nombre = 'Ensaladas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada de pulpo'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada de pulpo' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada de pulpo' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada de pulpo' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada de pulpo' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 400g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada de pulpo'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada de pulpo' AND v.nombre = 'Grande 400g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada de pulpo' AND v.nombre = 'Grande 400g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada de pulpo' AND v.nombre = 'Grande 400g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Ensalada mixta', 'Camarón y pulpo', false, '{"estilo":["Al natural","Salseada","Bañada con chiltepín"]}'::jsonb, 2
  FROM public.menu_categorias c WHERE c.nombre = 'Ensaladas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada mixta'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada mixta' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada mixta' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada mixta' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada mixta' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 400g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada mixta'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada mixta' AND v.nombre = 'Grande 400g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada mixta' AND v.nombre = 'Grande 400g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada mixta' AND v.nombre = 'Grande 400g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Ensalada especial La Ola', 'Camarón cocido camarón curtido y pulpo', false, '{"estilo":["Al natural","Salseada","Bañada con chiltepín"]}'::jsonb, 3
  FROM public.menu_categorias c WHERE c.nombre = 'Ensaladas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada especial La Ola'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada especial La Ola' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada especial La Ola' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada especial La Ola' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada especial La Ola' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 400g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada especial La Ola'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada especial La Ola' AND v.nombre = 'Grande 400g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada especial La Ola' AND v.nombre = 'Grande 400g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada especial La Ola' AND v.nombre = 'Grande 400g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Ensalada especial San Blas', 'Con callo de hacha', false, '{"estilo":["Al natural","Salseada","Bañada con chiltepín"]}'::jsonb, 4
  FROM public.menu_categorias c WHERE c.nombre = 'Ensaladas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada especial San Blas'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 388.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada especial San Blas' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 388.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada especial San Blas' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 388.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada especial San Blas' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 362.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada especial San Blas' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 400g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada especial San Blas'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 468.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada especial San Blas' AND v.nombre = 'Grande 400g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 468.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada especial San Blas' AND v.nombre = 'Grande 400g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 468.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada especial San Blas' AND v.nombre = 'Grande 400g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Ensalada de callo de hacha', NULL, false, '{"estilo":["Al natural","Salseada","Bañada con chiltepín"]}'::jsonb, 5
  FROM public.menu_categorias c WHERE c.nombre = 'Ensaladas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada de callo de hacha'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 598.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada de callo de hacha' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 598.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada de callo de hacha' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 598.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada de callo de hacha' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 688.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada de callo de hacha' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 400g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada de callo de hacha'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 798.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada de callo de hacha' AND v.nombre = 'Grande 400g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 798.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada de callo de hacha' AND v.nombre = 'Grande 400g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 798.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Ensaladas' AND i.nombre = 'Ensalada de callo de hacha' AND v.nombre = 'Grande 400g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;

-- ===== Aguachiles =====
INSERT INTO public.menu_categorias (nombre, orden) VALUES ('Aguachiles', 10) ON CONFLICT (nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Aguachile de camarón', 'Pídelo tradicional verde rojo de chiltepín o negro salseado. Solares porción única 300g', false, '{"estilo":["Tradicional verde","Rojo de chiltepín","Negro salseado"]}'::jsonb, 0
  FROM public.menu_categorias c WHERE c.nombre = 'Aguachiles'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de camarón'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de camarón' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de camarón' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de camarón' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de camarón' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 400g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de camarón'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de camarón' AND v.nombre = 'Grande 400g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de camarón' AND v.nombre = 'Grande 400g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de camarón' AND v.nombre = 'Grande 400g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Aguachile de camarón cocido', NULL, false, '{"estilo":["Tradicional verde","Rojo de chiltepín","Negro salseado"]}'::jsonb, 1
  FROM public.menu_categorias c WHERE c.nombre = 'Aguachiles'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de camarón cocido'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de camarón cocido' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de camarón cocido' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de camarón cocido' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de camarón cocido' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 400g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de camarón cocido'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de camarón cocido' AND v.nombre = 'Grande 400g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de camarón cocido' AND v.nombre = 'Grande 400g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de camarón cocido' AND v.nombre = 'Grande 400g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Aguachile de pulpo', NULL, false, '{"estilo":["Tradicional verde","Rojo de chiltepín","Negro salseado"]}'::jsonb, 2
  FROM public.menu_categorias c WHERE c.nombre = 'Aguachiles'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de pulpo'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de pulpo' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de pulpo' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de pulpo' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de pulpo' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 400g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de pulpo'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de pulpo' AND v.nombre = 'Grande 400g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de pulpo' AND v.nombre = 'Grande 400g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de pulpo' AND v.nombre = 'Grande 400g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Aguachile mixto', 'Camarón y pulpo', false, '{"estilo":["Tradicional verde","Rojo de chiltepín","Negro salseado"]}'::jsonb, 3
  FROM public.menu_categorias c WHERE c.nombre = 'Aguachiles'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile mixto'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile mixto' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile mixto' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile mixto' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile mixto' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 400g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile mixto'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile mixto' AND v.nombre = 'Grande 400g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile mixto' AND v.nombre = 'Grande 400g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile mixto' AND v.nombre = 'Grande 400g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Aguachile Mexcalteca', 'Camarón crudo y camarón seco', false, '{"estilo":["Tradicional verde","Rojo de chiltepín","Negro salseado"]}'::jsonb, 4
  FROM public.menu_categorias c WHERE c.nombre = 'Aguachiles'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Única 300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile Mexcalteca'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile Mexcalteca' AND v.nombre = 'Única 300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Aguachile de camarón seco', NULL, false, '{"estilo":["Tradicional verde","Rojo de chiltepín","Negro salseado"]}'::jsonb, 5
  FROM public.menu_categorias c WHERE c.nombre = 'Aguachiles'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Única 300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de camarón seco'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 332.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de camarón seco' AND v.nombre = 'Única 300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Aguachile especial La Ola', 'Camarón cocido camarón curtido y pulpo', false, '{"estilo":["Tradicional verde","Rojo de chiltepín","Negro salseado"]}'::jsonb, 6
  FROM public.menu_categorias c WHERE c.nombre = 'Aguachiles'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile especial La Ola'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile especial La Ola' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile especial La Ola' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile especial La Ola' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 332.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile especial La Ola' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 400g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile especial La Ola'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile especial La Ola' AND v.nombre = 'Grande 400g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile especial La Ola' AND v.nombre = 'Grande 400g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile especial La Ola' AND v.nombre = 'Grande 400g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Aguachile Santa Cruz', 'Con camarón seco', false, '{"estilo":["Tradicional verde","Rojo de chiltepín","Negro salseado"]}'::jsonb, 7
  FROM public.menu_categorias c WHERE c.nombre = 'Aguachiles'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile Santa Cruz'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile Santa Cruz' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile Santa Cruz' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile Santa Cruz' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 332.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile Santa Cruz' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 400g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile Santa Cruz'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile Santa Cruz' AND v.nombre = 'Grande 400g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile Santa Cruz' AND v.nombre = 'Grande 400g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile Santa Cruz' AND v.nombre = 'Grande 400g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Aguachile Santa Cruz + callo de hacha', NULL, false, '{"estilo":["Tradicional verde","Rojo de chiltepín","Negro salseado"]}'::jsonb, 8
  FROM public.menu_categorias c WHERE c.nombre = 'Aguachiles'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile Santa Cruz + callo de hacha'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 388.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile Santa Cruz + callo de hacha' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 388.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile Santa Cruz + callo de hacha' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 388.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile Santa Cruz + callo de hacha' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 362.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile Santa Cruz + callo de hacha' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 400g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile Santa Cruz + callo de hacha'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 468.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile Santa Cruz + callo de hacha' AND v.nombre = 'Grande 400g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 468.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile Santa Cruz + callo de hacha' AND v.nombre = 'Grande 400g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 468.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile Santa Cruz + callo de hacha' AND v.nombre = 'Grande 400g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Aguachile especial de camarón', 'Camarón cocido curtido y seco', false, '{"estilo":["Tradicional verde","Rojo de chiltepín","Negro salseado"]}'::jsonb, 9
  FROM public.menu_categorias c WHERE c.nombre = 'Aguachiles'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile especial de camarón'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile especial de camarón' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile especial de camarón' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 338.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile especial de camarón' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 332.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile especial de camarón' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 400g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile especial de camarón'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile especial de camarón' AND v.nombre = 'Grande 400g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile especial de camarón' AND v.nombre = 'Grande 400g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 398.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile especial de camarón' AND v.nombre = 'Grande 400g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Aguachile especial San Blas', 'Con callo de hacha', false, '{"estilo":["Tradicional verde","Rojo de chiltepín","Negro salseado"]}'::jsonb, 10
  FROM public.menu_categorias c WHERE c.nombre = 'Aguachiles'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile especial San Blas'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 388.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile especial San Blas' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 388.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile especial San Blas' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 388.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile especial San Blas' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 362.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile especial San Blas' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 400g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile especial San Blas'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 468.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile especial San Blas' AND v.nombre = 'Grande 400g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 468.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile especial San Blas' AND v.nombre = 'Grande 400g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 468.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile especial San Blas' AND v.nombre = 'Grande 400g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Aguachile de callo de hacha', NULL, false, '{"estilo":["Tradicional verde","Rojo de chiltepín","Negro salseado"]}'::jsonb, 11
  FROM public.menu_categorias c WHERE c.nombre = 'Aguachiles'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de callo de hacha'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 598.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de callo de hacha' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 598.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de callo de hacha' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 598.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de callo de hacha' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 400g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de callo de hacha'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 798.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de callo de hacha' AND v.nombre = 'Grande 400g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 798.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de callo de hacha' AND v.nombre = 'Grande 400g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 798.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Aguachile de callo de hacha' AND v.nombre = 'Grande 400g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Montado con callo de hacha', 'Callo de hacha montado sobre aguachile de camarón', false, '{"estilo":["Tradicional verde","Rojo de chiltepín","Negro salseado"]}'::jsonb, 12
  FROM public.menu_categorias c WHERE c.nombre = 'Aguachiles'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Montado con callo de hacha'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 438.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Montado con callo de hacha' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 438.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Montado con callo de hacha' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 438.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Montado con callo de hacha' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 362.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Montado con callo de hacha' AND v.nombre = 'Mediano 300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 400g', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Montado con callo de hacha'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 498.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Montado con callo de hacha' AND v.nombre = 'Grande 400g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 498.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Montado con callo de hacha' AND v.nombre = 'Grande 400g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 498.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Aguachiles' AND i.nombre = 'Montado con callo de hacha' AND v.nombre = 'Grande 400g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;

-- ===== Camarones =====
INSERT INTO public.menu_categorias (nombre, orden) VALUES ('Camarones', 11) ON CONFLICT (nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Camarones a la diabla', 'Pídelos suaves normales o picantes. Acompañados de papas arroz y plátano frito', false, '{"preparacion":["Suave","Normal","Picante"]}'::jsonb, 0
  FROM public.menu_categorias c WHERE c.nombre = 'Camarones'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones a la diabla'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones a la diabla' AND v.nombre = '300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones a la diabla' AND v.nombre = '300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones a la diabla' AND v.nombre = '300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones a la diabla' AND v.nombre = '300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Camarones a la plancha', NULL, false, NULL, 1
  FROM public.menu_categorias c WHERE c.nombre = 'Camarones'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones a la plancha'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones a la plancha' AND v.nombre = '300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones a la plancha' AND v.nombre = '300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones a la plancha' AND v.nombre = '300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones a la plancha' AND v.nombre = '300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Camarones a la mantequilla', NULL, false, NULL, 2
  FROM public.menu_categorias c WHERE c.nombre = 'Camarones'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones a la mantequilla'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones a la mantequilla' AND v.nombre = '300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones a la mantequilla' AND v.nombre = '300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones a la mantequilla' AND v.nombre = '300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones a la mantequilla' AND v.nombre = '300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Camarones al mojo de ajo', NULL, false, NULL, 3
  FROM public.menu_categorias c WHERE c.nombre = 'Camarones'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones al mojo de ajo'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones al mojo de ajo' AND v.nombre = '300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones al mojo de ajo' AND v.nombre = '300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones al mojo de ajo' AND v.nombre = '300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones al mojo de ajo' AND v.nombre = '300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Camarones al coco', NULL, false, NULL, 4
  FROM public.menu_categorias c WHERE c.nombre = 'Camarones'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones al coco'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones al coco' AND v.nombre = '300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones al coco' AND v.nombre = '300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones al coco' AND v.nombre = '300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones al coco' AND v.nombre = '300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Camarones al ajillo', NULL, false, NULL, 5
  FROM public.menu_categorias c WHERE c.nombre = 'Camarones'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones al ajillo'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones al ajillo' AND v.nombre = '300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones al ajillo' AND v.nombre = '300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones al ajillo' AND v.nombre = '300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones al ajillo' AND v.nombre = '300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Camarones empanizados', NULL, false, NULL, 6
  FROM public.menu_categorias c WHERE c.nombre = 'Camarones'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones empanizados'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones empanizados' AND v.nombre = '300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones empanizados' AND v.nombre = '300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones empanizados' AND v.nombre = '300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones empanizados' AND v.nombre = '300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Momias Coras', 'Camarón con queso envueltos en tocino', false, NULL, 7
  FROM public.menu_categorias c WHERE c.nombre = 'Camarones'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Momias Coras'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Momias Coras' AND v.nombre = '300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Momias Coras' AND v.nombre = '300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Momias Coras' AND v.nombre = '300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Momias Coras' AND v.nombre = '300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Camarones Philadelphia', 'Rellenos de queso philadelphia empanizados con panko', false, NULL, 8
  FROM public.menu_categorias c WHERE c.nombre = 'Camarones'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones Philadelphia'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones Philadelphia' AND v.nombre = '300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones Philadelphia' AND v.nombre = '300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones Philadelphia' AND v.nombre = '300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Camarones a la Frank', 'Cremosos con mezcla de philadelphia y cheddar', false, NULL, 9
  FROM public.menu_categorias c WHERE c.nombre = 'Camarones'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones a la Frank'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones a la Frank' AND v.nombre = '300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones a la Frank' AND v.nombre = '300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones a la Frank' AND v.nombre = '300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Camarones' AND i.nombre = 'Camarones a la Frank' AND v.nombre = '300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;

-- ===== Pulpo =====
INSERT INTO public.menu_categorias (nombre, orden) VALUES ('Pulpo', 12) ON CONFLICT (nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Pulpo a la diabla', 'Pulpo maya premium. Acompañado de papas arroz y plátano frito', false, '{"preparacion":["Suave","Normal","Picante"]}'::jsonb, 0
  FROM public.menu_categorias c WHERE c.nombre = 'Pulpo'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Pulpo' AND i.nombre = 'Pulpo a la diabla'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pulpo' AND i.nombre = 'Pulpo a la diabla' AND v.nombre = '300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pulpo' AND i.nombre = 'Pulpo a la diabla' AND v.nombre = '300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pulpo' AND i.nombre = 'Pulpo a la diabla' AND v.nombre = '300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pulpo' AND i.nombre = 'Pulpo a la diabla' AND v.nombre = '300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Pulpo a la plancha', NULL, false, NULL, 1
  FROM public.menu_categorias c WHERE c.nombre = 'Pulpo'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Pulpo' AND i.nombre = 'Pulpo a la plancha'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pulpo' AND i.nombre = 'Pulpo a la plancha' AND v.nombre = '300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pulpo' AND i.nombre = 'Pulpo a la plancha' AND v.nombre = '300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pulpo' AND i.nombre = 'Pulpo a la plancha' AND v.nombre = '300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pulpo' AND i.nombre = 'Pulpo a la plancha' AND v.nombre = '300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Pulpo a la mantequilla', NULL, false, NULL, 2
  FROM public.menu_categorias c WHERE c.nombre = 'Pulpo'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Pulpo' AND i.nombre = 'Pulpo a la mantequilla'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pulpo' AND i.nombre = 'Pulpo a la mantequilla' AND v.nombre = '300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pulpo' AND i.nombre = 'Pulpo a la mantequilla' AND v.nombre = '300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pulpo' AND i.nombre = 'Pulpo a la mantequilla' AND v.nombre = '300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pulpo' AND i.nombre = 'Pulpo a la mantequilla' AND v.nombre = '300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Pulpo al mojo de ajo', NULL, false, NULL, 3
  FROM public.menu_categorias c WHERE c.nombre = 'Pulpo'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Pulpo' AND i.nombre = 'Pulpo al mojo de ajo'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pulpo' AND i.nombre = 'Pulpo al mojo de ajo' AND v.nombre = '300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pulpo' AND i.nombre = 'Pulpo al mojo de ajo' AND v.nombre = '300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pulpo' AND i.nombre = 'Pulpo al mojo de ajo' AND v.nombre = '300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pulpo' AND i.nombre = 'Pulpo al mojo de ajo' AND v.nombre = '300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Pulpo al ajillo', 'Ajo chile de árbol y aceite de oliva', false, NULL, 4
  FROM public.menu_categorias c WHERE c.nombre = 'Pulpo'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Pulpo' AND i.nombre = 'Pulpo al ajillo'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pulpo' AND i.nombre = 'Pulpo al ajillo' AND v.nombre = '300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pulpo' AND i.nombre = 'Pulpo al ajillo' AND v.nombre = '300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pulpo' AND i.nombre = 'Pulpo al ajillo' AND v.nombre = '300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pulpo' AND i.nombre = 'Pulpo al ajillo' AND v.nombre = '300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;

-- ===== Filete de Róbalo =====
INSERT INTO public.menu_categorias (nombre, orden) VALUES ('Filete de Róbalo', 13) ON CONFLICT (nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Filete a la diabla', 'Acompañado de papas arroz y plátano frito', false, '{"preparacion":["Suave","Normal","Picante"]}'::jsonb, 0
  FROM public.menu_categorias c WHERE c.nombre = 'Filete de Róbalo'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Filete de Róbalo' AND i.nombre = 'Filete a la diabla'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Filete de Róbalo' AND i.nombre = 'Filete a la diabla' AND v.nombre = '300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Filete de Róbalo' AND i.nombre = 'Filete a la diabla' AND v.nombre = '300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Filete de Róbalo' AND i.nombre = 'Filete a la diabla' AND v.nombre = '300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Filete de Róbalo' AND i.nombre = 'Filete a la diabla' AND v.nombre = '300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Filete a la plancha', NULL, false, NULL, 1
  FROM public.menu_categorias c WHERE c.nombre = 'Filete de Róbalo'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Filete de Róbalo' AND i.nombre = 'Filete a la plancha'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Filete de Róbalo' AND i.nombre = 'Filete a la plancha' AND v.nombre = '300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Filete de Róbalo' AND i.nombre = 'Filete a la plancha' AND v.nombre = '300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Filete de Róbalo' AND i.nombre = 'Filete a la plancha' AND v.nombre = '300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Filete de Róbalo' AND i.nombre = 'Filete a la plancha' AND v.nombre = '300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Filete a la mantequilla', NULL, false, NULL, 2
  FROM public.menu_categorias c WHERE c.nombre = 'Filete de Róbalo'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Filete de Róbalo' AND i.nombre = 'Filete a la mantequilla'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Filete de Róbalo' AND i.nombre = 'Filete a la mantequilla' AND v.nombre = '300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Filete de Róbalo' AND i.nombre = 'Filete a la mantequilla' AND v.nombre = '300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Filete de Róbalo' AND i.nombre = 'Filete a la mantequilla' AND v.nombre = '300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Filete de Róbalo' AND i.nombre = 'Filete a la mantequilla' AND v.nombre = '300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Filete al mojo de ajo', NULL, false, NULL, 3
  FROM public.menu_categorias c WHERE c.nombre = 'Filete de Róbalo'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Filete de Róbalo' AND i.nombre = 'Filete al mojo de ajo'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Filete de Róbalo' AND i.nombre = 'Filete al mojo de ajo' AND v.nombre = '300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Filete de Róbalo' AND i.nombre = 'Filete al mojo de ajo' AND v.nombre = '300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Filete de Róbalo' AND i.nombre = 'Filete al mojo de ajo' AND v.nombre = '300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Filete de Róbalo' AND i.nombre = 'Filete al mojo de ajo' AND v.nombre = '300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Filete empanizado', NULL, false, NULL, 4
  FROM public.menu_categorias c WHERE c.nombre = 'Filete de Róbalo'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Filete de Róbalo' AND i.nombre = 'Filete empanizado'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Filete de Róbalo' AND i.nombre = 'Filete empanizado' AND v.nombre = '300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Filete de Róbalo' AND i.nombre = 'Filete empanizado' AND v.nombre = '300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Filete de Róbalo' AND i.nombre = 'Filete empanizado' AND v.nombre = '300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Filete de Róbalo' AND i.nombre = 'Filete empanizado' AND v.nombre = '300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Filete al ajillo', NULL, false, NULL, 5
  FROM public.menu_categorias c WHERE c.nombre = 'Filete de Róbalo'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Filete de Róbalo' AND i.nombre = 'Filete al ajillo'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Filete de Róbalo' AND i.nombre = 'Filete al ajillo' AND v.nombre = '300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Filete de Róbalo' AND i.nombre = 'Filete al ajillo' AND v.nombre = '300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Filete de Róbalo' AND i.nombre = 'Filete al ajillo' AND v.nombre = '300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Filete de Róbalo' AND i.nombre = 'Filete al ajillo' AND v.nombre = '300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Filete especial del Rey', 'Róbalo con camarón pulpo y queso cheddar', false, NULL, 6
  FROM public.menu_categorias c WHERE c.nombre = 'Filete de Róbalo'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '300g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Filete de Róbalo' AND i.nombre = 'Filete especial del Rey'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Filete de Róbalo' AND i.nombre = 'Filete especial del Rey' AND v.nombre = '300g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Filete de Róbalo' AND i.nombre = 'Filete especial del Rey' AND v.nombre = '300g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 308.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Filete de Róbalo' AND i.nombre = 'Filete especial del Rey' AND v.nombre = '300g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 312.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Filete de Róbalo' AND i.nombre = 'Filete especial del Rey' AND v.nombre = '300g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;

-- ===== Zarandeados =====
INSERT INTO public.menu_categorias (nombre, orden) VALUES ('Zarandeados', 14) ON CONFLICT (nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Pescado zarandeado (róbalo)', 'Solo en menú Del Valle', false, NULL, 0
  FROM public.menu_categorias c WHERE c.nombre = 'Zarandeados'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '1/2 kg', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Zarandeados' AND i.nombre = 'Pescado zarandeado (róbalo)'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 228.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Zarandeados' AND i.nombre = 'Pescado zarandeado (róbalo)' AND v.nombre = '1/2 kg' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '1 kg', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Zarandeados' AND i.nombre = 'Pescado zarandeado (róbalo)'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 428.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Zarandeados' AND i.nombre = 'Pescado zarandeado (róbalo)' AND v.nombre = '1 kg' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Carne zarandeada (filete de res)', NULL, false, NULL, 1
  FROM public.menu_categorias c WHERE c.nombre = 'Zarandeados'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '1/2 kg', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Zarandeados' AND i.nombre = 'Carne zarandeada (filete de res)'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 228.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Zarandeados' AND i.nombre = 'Carne zarandeada (filete de res)' AND v.nombre = '1/2 kg' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '1 kg', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Zarandeados' AND i.nombre = 'Carne zarandeada (filete de res)'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 428.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Zarandeados' AND i.nombre = 'Carne zarandeada (filete de res)' AND v.nombre = '1 kg' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Camarón zarandeado', NULL, false, NULL, 2
  FROM public.menu_categorias c WHERE c.nombre = 'Zarandeados'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '1/2 kg', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Zarandeados' AND i.nombre = 'Camarón zarandeado'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 228.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Zarandeados' AND i.nombre = 'Camarón zarandeado' AND v.nombre = '1/2 kg' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '1 kg', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Zarandeados' AND i.nombre = 'Camarón zarandeado'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 428.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Zarandeados' AND i.nombre = 'Camarón zarandeado' AND v.nombre = '1 kg' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Costilla zarandeada', NULL, false, NULL, 3
  FROM public.menu_categorias c WHERE c.nombre = 'Zarandeados'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '1/2 kg', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Zarandeados' AND i.nombre = 'Costilla zarandeada'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 168.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Zarandeados' AND i.nombre = 'Costilla zarandeada' AND v.nombre = '1/2 kg' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '1 kg', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Zarandeados' AND i.nombre = 'Costilla zarandeada'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 298.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Zarandeados' AND i.nombre = 'Costilla zarandeada' AND v.nombre = '1 kg' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Tasajo de cerdo zarandeado', NULL, false, NULL, 4
  FROM public.menu_categorias c WHERE c.nombre = 'Zarandeados'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '1/2 kg', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Zarandeados' AND i.nombre = 'Tasajo de cerdo zarandeado'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 168.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Zarandeados' AND i.nombre = 'Tasajo de cerdo zarandeado' AND v.nombre = '1/2 kg' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '1 kg', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Zarandeados' AND i.nombre = 'Tasajo de cerdo zarandeado'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 298.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Zarandeados' AND i.nombre = 'Tasajo de cerdo zarandeado' AND v.nombre = '1 kg' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;

-- ===== Manitas de Jaiba =====
INSERT INTO public.menu_categorias (nombre, orden) VALUES ('Manitas de Jaiba', 15) ON CONFLICT (nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Manitas de jaiba', 'A la diabla plancha mantequilla mojo de ajo ajillo o al vapor', false, '{"preparacion":["A la diabla","A la plancha","A la mantequilla","Al mojo de ajo","Al ajillo","Al vapor"]}'::jsonb, 0
  FROM public.menu_categorias c WHERE c.nombre = 'Manitas de Jaiba'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '350g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Manitas de Jaiba' AND i.nombre = 'Manitas de jaiba'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 490.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Manitas de Jaiba' AND i.nombre = 'Manitas de jaiba' AND v.nombre = '350g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;

-- ===== Hamburguesas =====
INSERT INTO public.menu_categorias (nombre, orden) VALUES ('Hamburguesas', 16) ON CONFLICT (nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Hamburguesa de camarón', NULL, false, NULL, 0
  FROM public.menu_categorias c WHERE c.nombre = 'Hamburguesas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '250g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Hamburguesas' AND i.nombre = 'Hamburguesa de camarón'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 202.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Hamburguesas' AND i.nombre = 'Hamburguesa de camarón' AND v.nombre = '250g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Hamburguesa La Ola', 'Camarón y pulpo', false, NULL, 1
  FROM public.menu_categorias c WHERE c.nombre = 'Hamburguesas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '250g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Hamburguesas' AND i.nombre = 'Hamburguesa La Ola'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 202.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Hamburguesas' AND i.nombre = 'Hamburguesa La Ola' AND v.nombre = '250g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;

-- ===== Pizza =====
INSERT INTO public.menu_categorias (nombre, orden) VALUES ('Pizza', 17) ON CONFLICT (nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Pizza de jamón', NULL, false, NULL, 0
  FROM public.menu_categorias c WHERE c.nombre = 'Pizza'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '17 cm', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Pizza' AND i.nombre = 'Pizza de jamón'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pizza' AND i.nombre = 'Pizza de jamón' AND v.nombre = '17 cm' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pizza' AND i.nombre = 'Pizza de jamón' AND v.nombre = '17 cm' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pizza' AND i.nombre = 'Pizza de jamón' AND v.nombre = '17 cm' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Pizza de salchicha', NULL, false, NULL, 1
  FROM public.menu_categorias c WHERE c.nombre = 'Pizza'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '17 cm', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Pizza' AND i.nombre = 'Pizza de salchicha'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pizza' AND i.nombre = 'Pizza de salchicha' AND v.nombre = '17 cm' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pizza' AND i.nombre = 'Pizza de salchicha' AND v.nombre = '17 cm' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pizza' AND i.nombre = 'Pizza de salchicha' AND v.nombre = '17 cm' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Pizza hawaiana', NULL, false, NULL, 2
  FROM public.menu_categorias c WHERE c.nombre = 'Pizza'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '17 cm', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Pizza' AND i.nombre = 'Pizza hawaiana'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pizza' AND i.nombre = 'Pizza hawaiana' AND v.nombre = '17 cm' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pizza' AND i.nombre = 'Pizza hawaiana' AND v.nombre = '17 cm' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 118.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pizza' AND i.nombre = 'Pizza hawaiana' AND v.nombre = '17 cm' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Pizza de camarón', NULL, false, NULL, 3
  FROM public.menu_categorias c WHERE c.nombre = 'Pizza'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '17 cm', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Pizza' AND i.nombre = 'Pizza de camarón'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 148.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pizza' AND i.nombre = 'Pizza de camarón' AND v.nombre = '17 cm' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 148.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pizza' AND i.nombre = 'Pizza de camarón' AND v.nombre = '17 cm' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 148.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pizza' AND i.nombre = 'Pizza de camarón' AND v.nombre = '17 cm' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Pizza de camarón con piña', NULL, false, NULL, 4
  FROM public.menu_categorias c WHERE c.nombre = 'Pizza'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '17 cm', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Pizza' AND i.nombre = 'Pizza de camarón con piña'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 148.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pizza' AND i.nombre = 'Pizza de camarón con piña' AND v.nombre = '17 cm' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 148.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pizza' AND i.nombre = 'Pizza de camarón con piña' AND v.nombre = '17 cm' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 148.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pizza' AND i.nombre = 'Pizza de camarón con piña' AND v.nombre = '17 cm' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Pizza de camarones a la diabla', NULL, false, '{"preparacion":["Suave","Normal","Picante"]}'::jsonb, 5
  FROM public.menu_categorias c WHERE c.nombre = 'Pizza'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '17 cm', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Pizza' AND i.nombre = 'Pizza de camarones a la diabla'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 148.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pizza' AND i.nombre = 'Pizza de camarones a la diabla' AND v.nombre = '17 cm' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 148.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pizza' AND i.nombre = 'Pizza de camarones a la diabla' AND v.nombre = '17 cm' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 148.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Pizza' AND i.nombre = 'Pizza de camarones a la diabla' AND v.nombre = '17 cm' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;

-- ===== Snacks =====
INSERT INTO public.menu_categorias (nombre, orden) VALUES ('Snacks', 18) ON CONFLICT (nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Boneless', 'BBQ buffalo red hot franks o mango habanero. Con papas a la francesa', false, '{"sabor":["BBQ","Buffalo","Red Hot Frank''s","Mango habanero"]}'::jsonb, 0
  FROM public.menu_categorias c WHERE c.nombre = 'Snacks'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '10 piezas', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Snacks' AND i.nombre = 'Boneless'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 168.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Snacks' AND i.nombre = 'Boneless' AND v.nombre = '10 piezas' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 168.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Snacks' AND i.nombre = 'Boneless' AND v.nombre = '10 piezas' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 168.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Snacks' AND i.nombre = 'Boneless' AND v.nombre = '10 piezas' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 148.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Snacks' AND i.nombre = 'Boneless' AND v.nombre = '10 piezas' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Alitas de pollo', 'BBQ buffalo red hot franks o mango habanero. Con papas a la francesa', false, '{"sabor":["BBQ","Buffalo","Red Hot Frank''s","Mango habanero"]}'::jsonb, 1
  FROM public.menu_categorias c WHERE c.nombre = 'Snacks'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '10 piezas', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Snacks' AND i.nombre = 'Alitas de pollo'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 168.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Snacks' AND i.nombre = 'Alitas de pollo' AND v.nombre = '10 piezas' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Carnes frías', 'Jamón salchicha y queso cheddar en cubos', false, NULL, 2
  FROM public.menu_categorias c WHERE c.nombre = 'Snacks'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '200g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Snacks' AND i.nombre = 'Carnes frías'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 128.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Snacks' AND i.nombre = 'Carnes frías' AND v.nombre = '200g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 128.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Snacks' AND i.nombre = 'Carnes frías' AND v.nombre = '200g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 128.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Snacks' AND i.nombre = 'Carnes frías' AND v.nombre = '200g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 108.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Snacks' AND i.nombre = 'Carnes frías' AND v.nombre = '200g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Papas a la francesa', NULL, false, NULL, 3
  FROM public.menu_categorias c WHERE c.nombre = 'Snacks'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '120g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Snacks' AND i.nombre = 'Papas a la francesa'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 78.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Snacks' AND i.nombre = 'Papas a la francesa' AND v.nombre = '120g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 78.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Snacks' AND i.nombre = 'Papas a la francesa' AND v.nombre = '120g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 78.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Snacks' AND i.nombre = 'Papas a la francesa' AND v.nombre = '120g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 58.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Snacks' AND i.nombre = 'Papas a la francesa' AND v.nombre = '120g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;

-- ===== Menú Infantil =====
INSERT INTO public.menu_categorias (nombre, orden) VALUES ('Menú Infantil', 19) ON CONFLICT (nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Quesadillas natural jamón o salchicha', 'Acompañadas con arroz y papas a la francesa', false, '{"tipo":["Natural","Jamón","Salchicha"]}'::jsonb, 0
  FROM public.menu_categorias c WHERE c.nombre = 'Menú Infantil'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '2 piezas', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Menú Infantil' AND i.nombre = 'Quesadillas natural jamón o salchicha'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 78.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Menú Infantil' AND i.nombre = 'Quesadillas natural jamón o salchicha' AND v.nombre = '2 piezas' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 78.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Menú Infantil' AND i.nombre = 'Quesadillas natural jamón o salchicha' AND v.nombre = '2 piezas' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 78.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Menú Infantil' AND i.nombre = 'Quesadillas natural jamón o salchicha' AND v.nombre = '2 piezas' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 78.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Menú Infantil' AND i.nombre = 'Quesadillas natural jamón o salchicha' AND v.nombre = '2 piezas' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Quesadillas de camarón o pulpo', 'Acompañadas con arroz y papas a la francesa', false, '{"tipo":["Camarón","Pulpo"]}'::jsonb, 1
  FROM public.menu_categorias c WHERE c.nombre = 'Menú Infantil'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '2 piezas', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Menú Infantil' AND i.nombre = 'Quesadillas de camarón o pulpo'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 98.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Menú Infantil' AND i.nombre = 'Quesadillas de camarón o pulpo' AND v.nombre = '2 piezas' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 98.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Menú Infantil' AND i.nombre = 'Quesadillas de camarón o pulpo' AND v.nombre = '2 piezas' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 98.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Menú Infantil' AND i.nombre = 'Quesadillas de camarón o pulpo' AND v.nombre = '2 piezas' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 109.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Menú Infantil' AND i.nombre = 'Quesadillas de camarón o pulpo' AND v.nombre = '2 piezas' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Mini filete al gusto', 'Acompañado con arroz y papas a la francesa', false, NULL, 2
  FROM public.menu_categorias c WHERE c.nombre = 'Menú Infantil'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '100g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Menú Infantil' AND i.nombre = 'Mini filete al gusto'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 128.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Menú Infantil' AND i.nombre = 'Mini filete al gusto' AND v.nombre = '100g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 128.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Menú Infantil' AND i.nombre = 'Mini filete al gusto' AND v.nombre = '100g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 128.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Menú Infantil' AND i.nombre = 'Mini filete al gusto' AND v.nombre = '100g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 152.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Menú Infantil' AND i.nombre = 'Mini filete al gusto' AND v.nombre = '100g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;

-- ===== Postres =====
INSERT INTO public.menu_categorias (nombre, orden) VALUES ('Postres', 20) ON CONFLICT (nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Plátanos fritos', 'Con lechera', false, NULL, 0
  FROM public.menu_categorias c WHERE c.nombre = 'Postres'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '150g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Postres' AND i.nombre = 'Plátanos fritos'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 64.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Postres' AND i.nombre = 'Plátanos fritos' AND v.nombre = '150g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 64.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Postres' AND i.nombre = 'Plátanos fritos' AND v.nombre = '150g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 64.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Postres' AND i.nombre = 'Plátanos fritos' AND v.nombre = '150g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 78.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Postres' AND i.nombre = 'Plátanos fritos' AND v.nombre = '150g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Pay', 'Fresa guayaba o calabaza', false, '{"sabor":["Fresa","Guayaba","Calabaza"]}'::jsonb, 1
  FROM public.menu_categorias c WHERE c.nombre = 'Postres'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '150g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Postres' AND i.nombre = 'Pay'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 64.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Postres' AND i.nombre = 'Pay' AND v.nombre = '150g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 64.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Postres' AND i.nombre = 'Pay' AND v.nombre = '150g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 64.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Postres' AND i.nombre = 'Pay' AND v.nombre = '150g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Flan', 'Cajeta o caramelo', false, '{"sabor":["Cajeta","Caramelo"]}'::jsonb, 2
  FROM public.menu_categorias c WHERE c.nombre = 'Postres'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '150g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Postres' AND i.nombre = 'Flan'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 64.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Postres' AND i.nombre = 'Flan' AND v.nombre = '150g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 64.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Postres' AND i.nombre = 'Flan' AND v.nombre = '150g' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 64.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Postres' AND i.nombre = 'Flan' AND v.nombre = '150g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Mini pastel de brownie', NULL, false, NULL, 3
  FROM public.menu_categorias c WHERE c.nombre = 'Postres'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '150g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Postres' AND i.nombre = 'Mini pastel de brownie'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 64.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Postres' AND i.nombre = 'Mini pastel de brownie' AND v.nombre = '150g' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 64.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Postres' AND i.nombre = 'Mini pastel de brownie' AND v.nombre = '150g' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Pastel red velvet', 'Marisa', false, NULL, 4
  FROM public.menu_categorias c WHERE c.nombre = 'Postres'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '150g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Postres' AND i.nombre = 'Pastel red velvet'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 78.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Postres' AND i.nombre = 'Pastel red velvet' AND v.nombre = '150g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Gelatina de cajeta', 'Marisa', false, NULL, 5
  FROM public.menu_categorias c WHERE c.nombre = 'Postres'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '150g', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Postres' AND i.nombre = 'Gelatina de cajeta'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 78.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Postres' AND i.nombre = 'Gelatina de cajeta' AND v.nombre = '150g' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Helados Bök', 'Varios sabores', false, NULL, 6
  FROM public.menu_categorias c WHERE c.nombre = 'Postres'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '1 pieza', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Postres' AND i.nombre = 'Helados Bök'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 49.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Postres' AND i.nombre = 'Helados Bök' AND v.nombre = '1 pieza' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;

-- ===== Bebidas sin alcohol =====
INSERT INTO public.menu_categorias (nombre, orden) VALUES ('Bebidas sin alcohol', 21) ON CONFLICT (nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Refresco', 'Coca-Cola Light Sin azúcar Sprite Topo Chico Fresca Fanta Mundet', false, '{"sabor":["Coca-Cola","Coca-Cola Light","Coca-Cola Sin Azúcar","Sprite","Topo Chico","Fresca","Fanta","Mundet"]}'::jsonb, 0
  FROM public.menu_categorias c WHERE c.nombre = 'Bebidas sin alcohol'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '355 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Refresco'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 39.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Refresco' AND v.nombre = '355 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 39.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Refresco' AND v.nombre = '355 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 39.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Refresco' AND v.nombre = '355 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 42.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Refresco' AND v.nombre = '355 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Squirt', NULL, false, NULL, 1
  FROM public.menu_categorias c WHERE c.nombre = 'Bebidas sin alcohol'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '355 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Squirt'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 39.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Squirt' AND v.nombre = '355 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 39.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Squirt' AND v.nombre = '355 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 39.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Squirt' AND v.nombre = '355 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Boost', NULL, false, NULL, 2
  FROM public.menu_categorias c WHERE c.nombre = 'Bebidas sin alcohol'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '235 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Boost'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 39.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Boost' AND v.nombre = '235 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 39.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Boost' AND v.nombre = '235 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 39.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Boost' AND v.nombre = '235 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Agua Delixis', 'Té de jazmín jamaica horchata', false, '{"sabor":["Té de jazmín","Jamaica","Horchata"]}'::jsonb, 3
  FROM public.menu_categorias c WHERE c.nombre = 'Bebidas sin alcohol'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '500 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Agua Delixis'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 39.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Agua Delixis' AND v.nombre = '500 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 39.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Agua Delixis' AND v.nombre = '500 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 39.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Agua Delixis' AND v.nombre = '500 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Agua de sabor', 'Tamarindo jamaica pepino-limón horchata de fresa', false, '{"sabor":["Tamarindo","Jamaica","Pepino-limón","Horchata de fresa"]}'::jsonb, 4
  FROM public.menu_categorias c WHERE c.nombre = 'Bebidas sin alcohol'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '500 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Agua de sabor'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 42.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Agua de sabor' AND v.nombre = '500 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Felix', 'Schorle agua mineral con jugo de frutas', false, NULL, 5
  FROM public.menu_categorias c WHERE c.nombre = 'Bebidas sin alcohol'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '355 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Felix'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 42.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Felix' AND v.nombre = '355 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Fuze tea', NULL, false, NULL, 6
  FROM public.menu_categorias c WHERE c.nombre = 'Bebidas sin alcohol'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '600 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Fuze tea'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 42.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Fuze tea' AND v.nombre = '600 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Agua Ciel embotellada', NULL, false, NULL, 7
  FROM public.menu_categorias c WHERE c.nombre = 'Bebidas sin alcohol'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '600 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Agua Ciel embotellada'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 29.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Agua Ciel embotellada' AND v.nombre = '600 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 29.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Agua Ciel embotellada' AND v.nombre = '600 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 29.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Agua Ciel embotellada' AND v.nombre = '600 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 42.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Agua Ciel embotellada' AND v.nombre = '600 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Café americano', NULL, false, NULL, 8
  FROM public.menu_categorias c WHERE c.nombre = 'Bebidas sin alcohol'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '300 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Café americano'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 39.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Café americano' AND v.nombre = '300 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 39.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Café americano' AND v.nombre = '300 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 39.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Café americano' AND v.nombre = '300 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 52.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Café americano' AND v.nombre = '300 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Limonada / Naranjada', NULL, false, '{"tipo":["Limonada","Naranjada"]}'::jsonb, 9
  FROM public.menu_categorias c WHERE c.nombre = 'Bebidas sin alcohol'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 450 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Limonada / Naranjada'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 49.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Limonada / Naranjada' AND v.nombre = 'Mediano 450 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 49.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Limonada / Naranjada' AND v.nombre = 'Mediano 450 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 49.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Limonada / Naranjada' AND v.nombre = 'Mediano 450 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 62.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Limonada / Naranjada' AND v.nombre = 'Mediano 450 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 900 ml', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Limonada / Naranjada'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 98.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Limonada / Naranjada' AND v.nombre = 'Grande 900 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 98.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Limonada / Naranjada' AND v.nombre = 'Grande 900 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 98.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Limonada / Naranjada' AND v.nombre = 'Grande 900 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Piñada / Fresada', NULL, false, '{"tipo":["Piñada","Fresada"]}'::jsonb, 10
  FROM public.menu_categorias c WHERE c.nombre = 'Bebidas sin alcohol'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 450 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Piñada / Fresada'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 49.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Piñada / Fresada' AND v.nombre = 'Mediano 450 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 49.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Piñada / Fresada' AND v.nombre = 'Mediano 450 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 49.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Piñada / Fresada' AND v.nombre = 'Mediano 450 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 72.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Piñada / Fresada' AND v.nombre = 'Mediano 450 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 900 ml', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Piñada / Fresada'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 98.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Piñada / Fresada' AND v.nombre = 'Grande 900 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 98.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Piñada / Fresada' AND v.nombre = 'Grande 900 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 98.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Piñada / Fresada' AND v.nombre = 'Grande 900 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Agua fresca', NULL, false, NULL, 11
  FROM public.menu_categorias c WHERE c.nombre = 'Bebidas sin alcohol'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 450 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Agua fresca'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 29.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Agua fresca' AND v.nombre = 'Mediano 450 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 29.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Agua fresca' AND v.nombre = 'Mediano 450 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 900 ml', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Agua fresca'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 58.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Agua fresca' AND v.nombre = 'Grande 900 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 58.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Agua fresca' AND v.nombre = 'Grande 900 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Coco natural', NULL, false, NULL, 12
  FROM public.menu_categorias c WHERE c.nombre = 'Bebidas sin alcohol'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '1 pieza', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Coco natural'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 50.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Coco natural' AND v.nombre = '1 pieza' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 80.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas sin alcohol' AND i.nombre = 'Coco natural' AND v.nombre = '1 pieza' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;

-- ===== Bebidas preparadas =====
INSERT INTO public.menu_categorias (nombre, orden) VALUES ('Bebidas preparadas', 22) ON CONFLICT (nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Michelada La Ola', 'Con camarón cocido camarón seco y pulpo', true, NULL, 0
  FROM public.menu_categorias c WHERE c.nombre = 'Bebidas preparadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '120g + 800 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Michelada La Ola'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 178.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Michelada La Ola' AND v.nombre = '120g + 800 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 178.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Michelada La Ola' AND v.nombre = '120g + 800 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 178.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Michelada La Ola' AND v.nombre = '120g + 800 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Cielo rojo / Chelada / Michelada', 'Solares 500 ml', true, '{"tipo":["Cielo rojo","Chelada","Michelada"]}'::jsonb, 1
  FROM public.menu_categorias c WHERE c.nombre = 'Bebidas preparadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 450 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Cielo rojo / Chelada / Michelada'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 52.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Cielo rojo / Chelada / Michelada' AND v.nombre = 'Mediano 450 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 52.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Cielo rojo / Chelada / Michelada' AND v.nombre = 'Mediano 450 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 58.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Cielo rojo / Chelada / Michelada' AND v.nombre = 'Mediano 450 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 72.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Cielo rojo / Chelada / Michelada' AND v.nombre = 'Mediano 450 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 900 ml', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Cielo rojo / Chelada / Michelada'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 104.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Cielo rojo / Chelada / Michelada' AND v.nombre = 'Grande 900 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 104.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Cielo rojo / Chelada / Michelada' AND v.nombre = 'Grande 900 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 116.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Cielo rojo / Chelada / Michelada' AND v.nombre = 'Grande 900 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Michelada salseada', 'Sin clamato', true, NULL, 2
  FROM public.menu_categorias c WHERE c.nombre = 'Bebidas preparadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 450 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Michelada salseada'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 52.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Michelada salseada' AND v.nombre = 'Mediano 450 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 52.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Michelada salseada' AND v.nombre = 'Mediano 450 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 58.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Michelada salseada' AND v.nombre = 'Mediano 450 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 900 ml', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Michelada salseada'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 104.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Michelada salseada' AND v.nombre = 'Grande 900 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 104.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Michelada salseada' AND v.nombre = 'Grande 900 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 116.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Michelada salseada' AND v.nombre = 'Grande 900 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Michelada de sabor', 'Mango piña o tamarindo', true, '{"sabor":["Mango","Piña","Tamarindo"]}'::jsonb, 3
  FROM public.menu_categorias c WHERE c.nombre = 'Bebidas preparadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano 450 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Michelada de sabor'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 52.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Michelada de sabor' AND v.nombre = 'Mediano 450 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 52.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Michelada de sabor' AND v.nombre = 'Mediano 450 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 58.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Michelada de sabor' AND v.nombre = 'Mediano 450 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 72.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Michelada de sabor' AND v.nombre = 'Mediano 450 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande 900 ml', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Michelada de sabor'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 104.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Michelada de sabor' AND v.nombre = 'Grande 900 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 104.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Michelada de sabor' AND v.nombre = 'Grande 900 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 116.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Michelada de sabor' AND v.nombre = 'Grande 900 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Piña colada', NULL, true, NULL, 4
  FROM public.menu_categorias c WHERE c.nombre = 'Bebidas preparadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Piña colada'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 78.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Piña colada' AND v.nombre = 'Mediano' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 78.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Piña colada' AND v.nombre = 'Mediano' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 98.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Piña colada' AND v.nombre = 'Mediano' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 98.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Piña colada' AND v.nombre = 'Mediano' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Piña colada'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 148.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Piña colada' AND v.nombre = 'Grande' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 148.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Piña colada' AND v.nombre = 'Grande' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 178.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Piña colada' AND v.nombre = 'Grande' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Cerveza española', NULL, true, NULL, 5
  FROM public.menu_categorias c WHERE c.nombre = 'Bebidas preparadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Cerveza española'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 78.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Cerveza española' AND v.nombre = 'Mediano' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 78.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Cerveza española' AND v.nombre = 'Mediano' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 98.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Cerveza española' AND v.nombre = 'Mediano' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 98.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Cerveza española' AND v.nombre = 'Mediano' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Cerveza española'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 148.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Cerveza española' AND v.nombre = 'Grande' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 148.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Cerveza española' AND v.nombre = 'Grande' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 178.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Cerveza española' AND v.nombre = 'Grande' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Sangría', NULL, true, NULL, 6
  FROM public.menu_categorias c WHERE c.nombre = 'Bebidas preparadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Sangría'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 78.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Sangría' AND v.nombre = 'Mediano' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 78.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Sangría' AND v.nombre = 'Mediano' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 98.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Sangría' AND v.nombre = 'Mediano' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Sangría'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 148.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Sangría' AND v.nombre = 'Grande' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 148.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Sangría' AND v.nombre = 'Grande' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 178.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Sangría' AND v.nombre = 'Grande' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Margarita', NULL, true, NULL, 7
  FROM public.menu_categorias c WHERE c.nombre = 'Bebidas preparadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mediano', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Margarita'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 78.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Margarita' AND v.nombre = 'Mediano' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 78.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Margarita' AND v.nombre = 'Mediano' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 98.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Margarita' AND v.nombre = 'Mediano' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Grande', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Margarita'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 148.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Margarita' AND v.nombre = 'Grande' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 148.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Margarita' AND v.nombre = 'Grande' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 178.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Margarita' AND v.nombre = 'Grande' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Paloma', NULL, true, NULL, 8
  FROM public.menu_categorias c WHERE c.nombre = 'Bebidas preparadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '300 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Paloma'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 98.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Paloma' AND v.nombre = '300 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 98.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Paloma' AND v.nombre = '300 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 98.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Paloma' AND v.nombre = '300 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Mezcalitas', 'Jamaica pepino mandarina maracuyá mango', true, '{"sabor":["Jamaica","Pepino","Mandarina","Maracuyá","Mango"]}'::jsonb, 9
  FROM public.menu_categorias c WHERE c.nombre = 'Bebidas preparadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '240 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Mezcalitas'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 98.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Mezcalitas' AND v.nombre = '240 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 98.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Mezcalitas' AND v.nombre = '240 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 98.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Mezcalitas' AND v.nombre = '240 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 98.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Mezcalitas' AND v.nombre = '240 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Aperol', 'Spritz veraniego tropical', true, NULL, 10
  FROM public.menu_categorias c WHERE c.nombre = 'Bebidas preparadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '180 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Aperol'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 98.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Aperol' AND v.nombre = '180 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 98.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Aperol' AND v.nombre = '180 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 98.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Aperol' AND v.nombre = '180 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Mojito', 'Solares 500 ml', true, NULL, 11
  FROM public.menu_categorias c WHERE c.nombre = 'Bebidas preparadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '300 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Mojito'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 78.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Mojito' AND v.nombre = '300 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 78.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Mojito' AND v.nombre = '300 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 98.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Mojito' AND v.nombre = '300 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 98.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Mojito' AND v.nombre = '300 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Clericot', 'Solares 355 ml', true, NULL, 12
  FROM public.menu_categorias c WHERE c.nombre = 'Bebidas preparadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '300 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Clericot'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 78.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Clericot' AND v.nombre = '300 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 78.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Clericot' AND v.nombre = '300 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 98.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Clericot' AND v.nombre = '300 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 98.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Clericot' AND v.nombre = '300 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Perla Negra', NULL, true, NULL, 13
  FROM public.menu_categorias c WHERE c.nombre = 'Bebidas preparadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '300 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Perla Negra'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 128.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Perla Negra' AND v.nombre = '300 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 128.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Perla Negra' AND v.nombre = '300 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 128.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Perla Negra' AND v.nombre = '300 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Coco La Ola', 'Agua de coco limón jarabe tequila vodka ron ginebra y controy', true, NULL, 14
  FROM public.menu_categorias c WHERE c.nombre = 'Bebidas preparadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '1 pieza', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Coco La Ola'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 128.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Coco La Ola' AND v.nombre = '1 pieza' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 120.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Coco La Ola' AND v.nombre = '1 pieza' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Cantarito', NULL, true, NULL, 15
  FROM public.menu_categorias c WHERE c.nombre = 'Bebidas preparadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '500 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Cantarito'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 120.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Cantarito' AND v.nombre = '500 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Tinto de verano', NULL, true, NULL, 16
  FROM public.menu_categorias c WHERE c.nombre = 'Bebidas preparadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '355 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Tinto de verano'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 98.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Tinto de verano' AND v.nombre = '355 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Calimocho', NULL, true, NULL, 17
  FROM public.menu_categorias c WHERE c.nombre = 'Bebidas preparadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '355 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Calimocho'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 98.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Calimocho' AND v.nombre = '355 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Painkiller', 'Bacardi crema de coco naranja piña', true, NULL, 18
  FROM public.menu_categorias c WHERE c.nombre = 'Bebidas preparadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '355 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Painkiller'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 98.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Painkiller' AND v.nombre = '355 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Vaso chelado', NULL, false, NULL, 19
  FROM public.menu_categorias c WHERE c.nombre = 'Bebidas preparadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Único', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Vaso chelado'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 10.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Vaso chelado' AND v.nombre = 'Único' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 10.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Vaso chelado' AND v.nombre = 'Único' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 10.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Vaso chelado' AND v.nombre = 'Único' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 12.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Vaso chelado' AND v.nombre = 'Único' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Vaso michelado', NULL, false, NULL, 20
  FROM public.menu_categorias c WHERE c.nombre = 'Bebidas preparadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Único', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Vaso michelado'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 20.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Vaso michelado' AND v.nombre = 'Único' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 20.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Vaso michelado' AND v.nombre = 'Único' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 20.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Vaso michelado' AND v.nombre = 'Único' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 22.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Vaso michelado' AND v.nombre = 'Único' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Vaso salseado', NULL, false, NULL, 21
  FROM public.menu_categorias c WHERE c.nombre = 'Bebidas preparadas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Único', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Vaso salseado'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 15.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Vaso salseado' AND v.nombre = 'Único' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 15.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Vaso salseado' AND v.nombre = 'Único' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 15.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Bebidas preparadas' AND i.nombre = 'Vaso salseado' AND v.nombre = 'Único' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;

-- ===== Cervezas =====
INSERT INTO public.menu_categorias (nombre, orden) VALUES ('Cervezas', 23) ON CONFLICT (nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Pacífico', 'En Solares: Pacífico clara', true, NULL, 0
  FROM public.menu_categorias c WHERE c.nombre = 'Cervezas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Media 210 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Pacífico'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 24.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Pacífico' AND v.nombre = 'Media 210 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 24.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Pacífico' AND v.nombre = 'Media 210 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 24.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Pacífico' AND v.nombre = 'Media 210 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 28.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Pacífico' AND v.nombre = 'Media 210 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '355 ml', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Pacífico'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 48.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Pacífico' AND v.nombre = '355 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 48.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Pacífico' AND v.nombre = '355 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 48.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Pacífico' AND v.nombre = '355 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 56.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Pacífico' AND v.nombre = '355 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mega 940 ml', 2
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Pacífico'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 108.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Pacífico' AND v.nombre = 'Mega 940 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 108.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Pacífico' AND v.nombre = 'Mega 940 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 108.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Pacífico' AND v.nombre = 'Mega 940 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Pacífico Light', NULL, true, NULL, 1
  FROM public.menu_categorias c WHERE c.nombre = 'Cervezas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Media 210 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Pacífico Light'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 24.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Pacífico Light' AND v.nombre = 'Media 210 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 24.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Pacífico Light' AND v.nombre = 'Media 210 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 24.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Pacífico Light' AND v.nombre = 'Media 210 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '355 ml', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Pacífico Light'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 48.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Pacífico Light' AND v.nombre = '355 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 48.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Pacífico Light' AND v.nombre = '355 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 48.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Pacífico Light' AND v.nombre = '355 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mega 940 ml', 2
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Pacífico Light'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 108.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Pacífico Light' AND v.nombre = 'Mega 940 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 108.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Pacífico Light' AND v.nombre = 'Mega 940 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 108.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Pacífico Light' AND v.nombre = 'Mega 940 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Pacífico Suave', NULL, true, NULL, 2
  FROM public.menu_categorias c WHERE c.nombre = 'Cervezas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '355 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Pacífico Suave'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 48.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Pacífico Suave' AND v.nombre = '355 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 48.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Pacífico Suave' AND v.nombre = '355 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 48.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Pacífico Suave' AND v.nombre = '355 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 56.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Pacífico Suave' AND v.nombre = '355 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Corona', NULL, true, NULL, 3
  FROM public.menu_categorias c WHERE c.nombre = 'Cervezas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Media 210 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 24.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona' AND v.nombre = 'Media 210 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 24.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona' AND v.nombre = 'Media 210 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 24.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona' AND v.nombre = 'Media 210 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 28.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona' AND v.nombre = 'Media 210 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '355 ml', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 48.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona' AND v.nombre = '355 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 48.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona' AND v.nombre = '355 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 48.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona' AND v.nombre = '355 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 56.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona' AND v.nombre = '355 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mega 940 ml', 2
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 108.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona' AND v.nombre = 'Mega 940 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 108.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona' AND v.nombre = 'Mega 940 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 108.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona' AND v.nombre = 'Mega 940 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Corona Light', NULL, true, NULL, 4
  FROM public.menu_categorias c WHERE c.nombre = 'Cervezas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Media 210 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona Light'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 24.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona Light' AND v.nombre = 'Media 210 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 24.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona Light' AND v.nombre = 'Media 210 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 24.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona Light' AND v.nombre = 'Media 210 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 28.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona Light' AND v.nombre = 'Media 210 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '355 ml', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona Light'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 48.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona Light' AND v.nombre = '355 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 48.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona Light' AND v.nombre = '355 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 48.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona Light' AND v.nombre = '355 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 56.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona Light' AND v.nombre = '355 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mega 940 ml', 2
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona Light'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 108.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona Light' AND v.nombre = 'Mega 940 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 108.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona Light' AND v.nombre = 'Mega 940 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 108.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona Light' AND v.nombre = 'Mega 940 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Corona Ámbar', NULL, true, NULL, 5
  FROM public.menu_categorias c WHERE c.nombre = 'Cervezas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Media 210 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona Ámbar'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 28.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona Ámbar' AND v.nombre = 'Media 210 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '355 ml', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona Ámbar'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 56.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona Ámbar' AND v.nombre = '355 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Corona Cero', 'En Valle/Brisas/Cervecería: Coronita Cero', true, NULL, 6
  FROM public.menu_categorias c WHERE c.nombre = 'Cervezas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Media 210 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona Cero'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 28.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona Cero' AND v.nombre = 'Media 210 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '355 ml', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona Cero'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 48.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona Cero' AND v.nombre = '355 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 48.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona Cero' AND v.nombre = '355 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 48.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona Cero' AND v.nombre = '355 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 56.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona Cero' AND v.nombre = '355 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Victoria', NULL, true, NULL, 7
  FROM public.menu_categorias c WHERE c.nombre = 'Cervezas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Media 210 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Victoria'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 24.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Victoria' AND v.nombre = 'Media 210 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 24.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Victoria' AND v.nombre = 'Media 210 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 24.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Victoria' AND v.nombre = 'Media 210 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 28.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Victoria' AND v.nombre = 'Media 210 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '355 ml', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Victoria'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 48.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Victoria' AND v.nombre = '355 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 48.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Victoria' AND v.nombre = '355 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 48.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Victoria' AND v.nombre = '355 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 56.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Victoria' AND v.nombre = '355 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mega 940 ml', 2
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Victoria'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 108.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Victoria' AND v.nombre = 'Mega 940 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 108.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Victoria' AND v.nombre = 'Mega 940 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 108.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Victoria' AND v.nombre = 'Mega 940 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Ultra', 'En Solares: Michelob Ultra', true, NULL, 8
  FROM public.menu_categorias c WHERE c.nombre = 'Cervezas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '355 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Ultra'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 58.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Ultra' AND v.nombre = '355 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 58.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Ultra' AND v.nombre = '355 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 58.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Ultra' AND v.nombre = '355 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 62.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Ultra' AND v.nombre = '355 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mega 940 ml', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Ultra'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 108.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Ultra' AND v.nombre = 'Mega 940 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 108.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Ultra' AND v.nombre = 'Mega 940 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 108.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Ultra' AND v.nombre = 'Mega 940 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Modelo Especial', NULL, true, NULL, 9
  FROM public.menu_categorias c WHERE c.nombre = 'Cervezas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '355 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Modelo Especial'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 58.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Modelo Especial' AND v.nombre = '355 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 58.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Modelo Especial' AND v.nombre = '355 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 58.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Modelo Especial' AND v.nombre = '355 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 62.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Modelo Especial' AND v.nombre = '355 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Mega 940 ml', 1
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Modelo Especial'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 108.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Modelo Especial' AND v.nombre = 'Mega 940 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 108.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Modelo Especial' AND v.nombre = 'Mega 940 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 108.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Modelo Especial' AND v.nombre = 'Mega 940 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Negra Modelo', NULL, true, NULL, 10
  FROM public.menu_categorias c WHERE c.nombre = 'Cervezas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '355 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Negra Modelo'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 58.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Negra Modelo' AND v.nombre = '355 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 58.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Negra Modelo' AND v.nombre = '355 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 58.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Negra Modelo' AND v.nombre = '355 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 62.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Negra Modelo' AND v.nombre = '355 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Stella Artois', NULL, true, NULL, 11
  FROM public.menu_categorias c WHERE c.nombre = 'Cervezas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '355 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Stella Artois'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 62.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Stella Artois' AND v.nombre = '355 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Corona Light lata', NULL, true, NULL, 12
  FROM public.menu_categorias c WHERE c.nombre = 'Cervezas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '355 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona Light lata'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 48.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona Light lata' AND v.nombre = '355 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 48.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona Light lata' AND v.nombre = '355 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 48.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona Light lata' AND v.nombre = '355 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Corona Cero lata', NULL, true, NULL, 13
  FROM public.menu_categorias c WHERE c.nombre = 'Cervezas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '355 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona Cero lata'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 48.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona Cero lata' AND v.nombre = '355 ml' AND s.nombre = 'Del Valle'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 48.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona Cero lata' AND v.nombre = '355 ml' AND s.nombre = 'Las Brisas'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 48.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Corona Cero lata' AND v.nombre = '355 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Modelo Especial lata', NULL, true, NULL, 14
  FROM public.menu_categorias c WHERE c.nombre = 'Cervezas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, '355 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Modelo Especial lata'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 48.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Modelo Especial lata' AND v.nombre = '355 ml' AND s.nombre = 'Cervecería'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Cerveza San Blas Agüita de Mar', NULL, true, NULL, 15
  FROM public.menu_categorias c WHERE c.nombre = 'Cervezas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Artesanal 355 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Cerveza San Blas Agüita de Mar'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 89.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Cerveza San Blas Agüita de Mar' AND v.nombre = 'Artesanal 355 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Cerveza San Blas Beach Lager', NULL, true, NULL, 16
  FROM public.menu_categorias c WHERE c.nombre = 'Cervezas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Artesanal 355 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Cerveza San Blas Beach Lager'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 89.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Cerveza San Blas Beach Lager' AND v.nombre = 'Artesanal 355 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)
  SELECT c.id, 'Cerveza San Blas Negra Tovara', NULL, true, NULL, 17
  FROM public.menu_categorias c WHERE c.nombre = 'Cervezas'
  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;
INSERT INTO public.menu_variantes (item_id, nombre, orden)
  SELECT i.id, 'Artesanal 355 ml', 0
  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Cerveza San Blas Negra Tovara'
  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;
INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)
  SELECT v.id, s.id, 89.00
  FROM public.menu_variantes v
  JOIN public.menu_items i ON i.id = v.item_id
  JOIN public.menu_categorias c ON c.id = i.categoria_id
  CROSS JOIN public.sucursales s
  WHERE c.nombre = 'Cervezas' AND i.nombre = 'Cerveza San Blas Negra Tovara' AND v.nombre = 'Artesanal 355 ml' AND s.nombre = 'Solares'
  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;
