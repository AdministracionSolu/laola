-- ============================================================
-- LA RECOMPENSA INICIAL SE ENTREGA EN EL ALTA, YA NO SE CANJEA
--
-- Segunda mitad de 20260827130000. Aquélla puso al día a los 66 clientes
-- que ya estaban; ésta hace que el que se inscriba mañana nazca igual, en
-- vez de volver a caer en la parada 0 con un botón de canje pendiente.
--
-- La premisa es la misma de la v6: nadie se registra desde su casa. Si
-- está llenando el formulario es porque está sentado en una mesa, y el
-- mesero le da su balazo ahí mismo. No hay un segundo momento en el que
-- vaya a "cobrarlo", así que tampoco hay canje que conciliar.
--
-- SE HACE CON UN DEFAULT, no reescribiendo lealtad_registrar:
-- ni `lealtad_registrar` ni `lealtad_visita` nombran esta columna en sus
-- INSERT, así que el default las cubre a las dos y no hay que recrear dos
-- funciones largas para cambiar un campo. OJO si algún día se reescribe
-- alguna de las dos: mientras no le pasen NULL explícito, sigue jalando.
--
-- Lo que cambia del lado del cliente (commit del front que acompaña):
--   · La pantalla de después del alta muestra la Recompensa inicial como
--     un aviso —"enséñale esta pantalla a tu mesero"— en lugar del botón
--     "Canjear mi Recompensa inicial".
--   · En visitas posteriores ya no aparece: no hay nada que enseñar.
--
-- `lealtad_canjear_bienvenida` se deja viva a propósito: si a alguien le
-- quedó la página vieja cargada y le pica, ahora revienta con YA_CANJEADA
-- —que es justo lo correcto— en lugar de un 404.
--
-- LO QUE SE PIERDE, dicho de frente: el contador de bienvenidas canjeadas
-- dejaba de existir como dato para empatar contra el comandero. Si un día
-- se quiere volver a medir cuántos balazos de inscripción se entregaron,
-- el número es el de altas del periodo.
-- ============================================================


-- ============================================================
-- BLOQUE 1 — Toda alta nueva nace con su Recompensa inicial entregada
-- ============================================================
ALTER TABLE public.lealtad_clientes
  ALTER COLUMN bienvenida_canjeada_at SET DEFAULT now();

COMMENT ON COLUMN public.lealtad_clientes.bienvenida_canjeada_at IS
  'Cuándo se le entregó su Recompensa inicial. Desde el 27-ago-2026 se '
  'estampa sola en el alta (DEFAULT now()): el regalo se da en la mesa al '
  'inscribirse, ya no hay canje aparte. NULL sólo en filas anteriores a '
  'esa fecha que no se hayan puesto al día.';


-- ============================================================
-- BLOQUE 2 — Verificación (correr y leer)
-- ============================================================
-- 1) El default quedó puesto
SELECT column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name   = 'lealtad_clientes'
  AND column_name  = 'bienvenida_canjeada_at';

-- 2) Nadie debe quedar con la bienvenida pendiente (esperado: 0)
SELECT count(*) AS pendientes
FROM public.lealtad_clientes
WHERE bienvenida_canjeada_at IS NULL;
