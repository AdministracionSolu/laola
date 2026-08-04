-- ============================================================
-- Mensaje de terminales, versión 2.
--
-- Cambios pedidos por Diego (4-ago):
--   - Ya NO hereda las terminales de planta. Lo que no se marca
--     en el dashboard sale como "sin asignar".
--   - Nombre de la sucursal entre asteriscos: WhatsApp lo pone
--     en negritas.
--   - Se agrega el día con letra ("martes 4 de agosto").
--   - Fuera la leyenda del final.
--
-- Si nadie marcó nada, la función devuelve NULL y no se manda
-- mensaje: un aviso donde las cuatro dicen "sin asignar" no le
-- sirve a nadie.
--
-- Los nombres de día y mes se arman a mano y no con to_char(TM),
-- que depende del lc_time del servidor.
-- ============================================================

CREATE OR REPLACE FUNCTION public.terminales_mensaje_dia(p_fecha date DEFAULT NULL)
RETURNS text
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_fecha  date := COALESCE(p_fecha, laola_fecha_negocio(now()));
  v_dias   text[] := ARRAY['domingo','lunes','martes','miércoles','jueves','viernes','sábado'];
  v_meses  text[] := ARRAY['enero','febrero','marzo','abril','mayo','junio','julio',
                           'agosto','septiembre','octubre','noviembre','diciembre'];
  v_lineas text[] := ARRAY[]::text[];
  v_row    record;
  v_hay    boolean := false;
BEGIN
  FOR v_row IN
    SELECT
      s.nombre,
      (SELECT string_agg(t.nombre, ' + ' ORDER BY t.orden, t.nombre)
         FROM terminales_asignacion a
         JOIN terminales t ON t.id = a.terminal_id
        WHERE a.fecha = v_fecha AND a.sucursal_id = s.id AND t.activa) AS lista
    FROM sucursales s
    ORDER BY
      COALESCE(array_position(ARRAY['VAL','CER','BRI','SOL'], upper(s.prefijo_folio)), 99),
      s.nombre
  LOOP
    IF v_row.lista IS NOT NULL THEN v_hay := true; END IF;
    v_lineas := v_lineas || ('• *' || v_row.nombre || '*: ' || COALESCE(v_row.lista, 'sin asignar'));
  END LOOP;

  IF NOT v_hay THEN RETURN NULL; END IF;

  RETURN 'Terminales de hoy' || E'\n'
      || v_dias[EXTRACT(DOW FROM v_fecha)::int + 1] || ' '
      || EXTRACT(DAY FROM v_fecha)::int || ' de '
      || v_meses[EXTRACT(MONTH FROM v_fecha)::int] || E'\n\n'
      || array_to_string(v_lineas, E'\n');
END;
$$;

REVOKE ALL ON FUNCTION public.terminales_mensaje_dia(date) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.terminales_mensaje_dia(date) TO authenticated;
