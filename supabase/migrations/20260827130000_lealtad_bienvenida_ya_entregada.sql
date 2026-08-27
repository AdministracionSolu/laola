-- ============================================================
-- LA RECOMPENSA INICIAL YA SE ENTREGÓ (a todo el padrón)
--
-- Desde la v6 la Recompensa inicial le sale al cliente en la misma
-- pantalla del alta, sentado en la mesa. Ya no es algo que tenga que ir
-- a cobrar después, así que dejar a todo el padrón marcado como "no la
-- ha canjeado" pinta mal el programa: el nivel de un cliente es la parada
-- HACIA la que va, y quien no ha canjeado su Recompensa inicial se queda
-- clavado en la parada 0 por más que siga viniendo.
--
-- El caso que lo destapó: Erick Esquivel llevaba 3 visitas —ya se había
-- ganado la michelada del ciclo— y su badge seguía diciendo "Recompensa
-- inicial". Traía DOS beneficios por cobrar y el nivel sólo reflejaba uno.
--
-- Después de esto: 58 clientes pasan de la parada 0 a la parada 1
-- ("Visita 3"), que es donde de verdad están.
--
-- POR QUÉ NO SE INSERTA NADA EN lealtad_canjes:
--   1. Estos no son canjes que un mesero haya entregado y que haya que
--      conciliar contra el comandero. Meterlos ensuciaría la pestaña de
--      Conciliación con 58 entregas que nunca pasaron por caja.
--   2. `trg_makatea_push_canje` dispara en cada INSERT a lealtad_canjes.
--      58 inserts = 58 pushes, y a quien tenga el canje en la misma fecha
--      que su última visita el estado le cambiaría a 'canje' → segmento
--      "canjeó beneficio" → le cae el "esperamos que tu regalo te haya
--      gustado". Eso no debe pasar.
--
-- POR QUÉ ESTE UPDATE **NO** MANDA MENSAJES (verificado en el código):
--   · `makatea_push_trigger` sólo empuja si cambia ultima_visita, nombre
--     o cumpleanos. `bienvenida_canjeada_at` no está en esa lista.
--   · `makatea_reconciliar` (04:30) filtra por ultima_visita/created_at,
--     no por updated_at, así que este UPDATE no arrastra a nadie.
--   · El `estado` que calcula makatea_push_clientes mira visitas y
--     lealtad_canjes — nunca bienvenida_canjeada_at.
--   Cero efecto del lado de Makatea. Es sólo cosmético/del nivel.
-- ============================================================


-- ============================================================
-- BLOQUE 1 — Marcar la bienvenida como ya entregada
-- Se estampa con la fecha de su ALTA, que es cuando de verdad se le
-- entregó (llenó el formulario sentado en la mesa), no con now().
-- ============================================================
UPDATE public.lealtad_clientes
SET bienvenida_canjeada_at = created_at
WHERE bienvenida_canjeada_at IS NULL;


-- ============================================================
-- BLOQUE 2 — Verificación (correr y leer)
-- ============================================================
-- 1) No debe quedar nadie sin marcar (esperado: 0)
SELECT count(*) AS sin_marcar
FROM public.lealtad_clientes
WHERE bienvenida_canjeada_at IS NULL;

-- 2) Cómo queda repartido el padrón por parada del ciclo.
--    Con 0 canjes de ciclo, todos caen en la parada 1 = "Visita 3".
SELECT n.nombre AS nivel, count(*) AS clientes
FROM public.lealtad_clientes c
CROSS JOIN LATERAL (
  SELECT count(*) AS can FROM public.lealtad_canjes k
  WHERE k.cliente_id = c.id AND k.posicion > 0
    AND EXTRACT(YEAR FROM k.fecha_negocio)::int
        = EXTRACT(YEAR FROM public.laola_fecha_negocio(now()))::int
) t
JOIN public.lealtad_niveles n
  ON n.activo AND n.posicion = CASE
       WHEN c.bienvenida_canjeada_at IS NULL THEN 0
       ELSE (t.can % (SELECT count(*) FROM public.lealtad_recompensas WHERE activo)) + 1
     END
GROUP BY n.nombre, n.posicion
ORDER BY n.posicion;

-- 3) Erick ya no debe traer la bienvenida pendiente, y sí la michelada
SELECT (public.lealtad_perfil_json(c.*)) ->> 'nivel'                   AS nivel,
       (public.lealtad_perfil_json(c.*)) ->> 'bienvenida_disponible'   AS bienvenida_pendiente,
       (public.lealtad_perfil_json(c.*)) ->> 'recompensas_disponibles' AS disponibles,
       (public.lealtad_perfil_json(c.*)) ->> 'recompensa_titulo'       AS toca
FROM public.lealtad_clientes c
WHERE c.telefono = '3313508753';
