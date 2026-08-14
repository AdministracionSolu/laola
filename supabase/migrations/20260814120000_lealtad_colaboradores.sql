-- ============================================================
-- LEALTAD — COLABORADORES DE LA OLA (mapeo, sin decisión de programa)
--
-- Los 77 números del grupo de WhatsApp "La Ola 🌊"
-- (5213112000393-1429116282@g.us, leído de la instancia
-- restaurante-la-ola el 14-ago-2026). Esto NO les da ni les quita
-- beneficios: solo deja identificado quién es colaborador, para que
-- cuando uno se registre en lealtad se sepa, y para la decisión
-- pendiente de si entran o no al programa.
--
-- La tabla es el padrón de consenso: si entra gente nueva al equipo se
-- agrega aquí (o se re-corre el mapeo del grupo). `activo=false` sirve
-- para quien salga del equipo sin perder el rastro.
--
-- Idempotente.
-- ============================================================

CREATE TABLE IF NOT EXISTS public.lealtad_colaboradores (
  telefono     text PRIMARY KEY,          -- 10 dígitos, mismo formato que lealtad_clientes.telefono
  telefono_wa  text,                      -- como aparece en WhatsApp (con 521)
  nombre_wa    text,                      -- pushName de la agenda, puede venir vacío
  admin_grupo  boolean NOT NULL DEFAULT false,
  origen       text NOT NULL DEFAULT 'grupo_wa_la_ola_2026-08-14',
  activo       boolean NOT NULL DEFAULT true,
  notas        text,
  agregado_at  timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.lealtad_colaboradores IS
  'Padrón de colaboradores de La Ola (números del grupo de WhatsApp). Identificación solamente: la decisión de si participan en lealtad está pendiente.';

ALTER TABLE public.lealtad_colaboradores ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS colaboradores_admin_select ON public.lealtad_colaboradores;
CREATE POLICY colaboradores_admin_select ON public.lealtad_colaboradores
  FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS colaboradores_admin_write ON public.lealtad_colaboradores;
CREATE POLICY colaboradores_admin_write ON public.lealtad_colaboradores
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

REVOKE ALL ON public.lealtad_colaboradores FROM anon;
GRANT SELECT, INSERT, UPDATE ON public.lealtad_colaboradores TO authenticated;

INSERT INTO public.lealtad_colaboradores (telefono, telefono_wa, nombre_wa, admin_grupo) VALUES
  ('3111014668', '5213111014668', NULL, false),
  ('3111015620', '5213111015620', NULL, false),
  ('3111016976', '5213111016976', NULL, false),
  ('3111017870', '5213111017870', 'Jose Carlos Meza Ramos', true),
  ('3111059776', '5213111059776', NULL, false),
  ('3111110411', '5213111110411', NULL, false),
  ('3111115705', '5213111115705', NULL, false),
  ('3111160349', '5213111160349', 'Angel David Aguilar Medina', true),
  ('3111164134', '5213111164134', NULL, false),
  ('3111212728', '5213111212728', NULL, false),
  ('3111223365', '5213111223365', NULL, true),
  ('3111259224', '5213111259224', NULL, false),
  ('3111265384', '5213111265384', NULL, false),
  ('3111301069', '5213111301069', 'Martina Arteaga', false),
  ('3111343696', '5213111343696', 'Grecia Santos', false),
  ('3111361857', '5213111361857', 'Cristopher German Abarca Hernandez', false),
  ('3111385183', '5213111385183', NULL, false),
  ('3111389637', '5213111389637', NULL, false),
  ('3111426402', '5213111426402', NULL, false),
  ('3111430614', '5213111430614', 'Wendy', true),
  ('3111451679', '5213111451679', NULL, false),
  ('3111480489', '5213111480489', NULL, false),
  ('3111572002', '5213111572002', NULL, false),
  ('3111634374', '5213111634374', 'Rocio Pastrana', true),
  ('3111842816', '5213111842816', 'Francisco Javier Garcia Reynaldo', false),
  ('3111849188', '5213111849188', NULL, true),
  ('3112016693', '5213112016693', 'Ximena Cabuto Guizar', true),
  ('3112019533', '5213112019533', 'Cic', true),
  ('3112250410', '5213112250410', 'Jasiel', true),
  ('3112269661', '5213112269661', NULL, false),
  ('3112272520', '5213112272520', NULL, false),
  ('3112461005', '5213112461005', NULL, false),
  ('3112500402', '5213112500402', 'Emma Elizabeth Diaz Montoya', false),
  ('3112500887', '5213112500887', NULL, false),
  ('3112508247', '5213112508247', NULL, false),
  ('3112575062', '5213112575062', NULL, true),
  ('3112602114', '5213112602114', NULL, false),
  ('3112605586', '5213112605586', NULL, true),
  ('3112625776', '5213112625776', '❤‍🩹', true),
  ('3112673121', '5213112673121', NULL, false),
  ('3112798143', '5213112798143', 'Omar Missael Rubio Martinez', false),
  ('3112851176', '5213112851176', 'Tio Fito Ojeda', true),
  ('3112880581', '5213112880581', NULL, true),
  ('3112887729', '5213112887729', NULL, true),
  ('3112902290', '5213112902290', 'Faustino Polanco Hernandez', false),
  ('3113178289', '5213113178289', NULL, false),
  ('3113387499', '5213113387499', 'Vanessa Cruz', false),
  ('3113403898', '5213113403898', 'Eduardo', false),
  ('3113405421', '5213113405421', NULL, false),
  ('3113415164', '5213113415164', NULL, false),
  ('3113728554', '523113728554', 'Lupita Nuñez', true),
  ('3113746209', '5213113746209', NULL, false),
  ('3113758640', '5213113758640', 'Luz Elena Carrillo Muñoz', false),
  ('3113836008', '5213113836008', NULL, false),
  ('3113858469', '5213113858469', 'Sel', false),
  ('3113914154', '5213113914154', NULL, false),
  ('3113937851', '5213113937851', NULL, false),
  ('3113971759', '5213113971759', 'Bertha', false),
  ('3114835303', '5213114835303', NULL, false),
  ('3115048575', '5213115048575', NULL, false),
  ('3115123632', '5213115123632', NULL, false),
  ('3115314855', '5213115314855', 'Uziel', false),
  ('3117407295', '5213117407295', NULL, false),
  ('3117430931', '5213117430931', NULL, false),
  ('3118760450', '5213118760450', 'Tio Remigio Rosales', true),
  ('3119105498', '5213119105498', NULL, false),
  ('3222424859', '5213222424859', NULL, false),
  ('3231296032', '5213231296032', NULL, false),
  ('3231438856', '5213231438856', 'Ivan Ernesto Corral', false),
  ('3271112565', '5213271112565', NULL, false),
  ('3271124938', '5213271124938', NULL, false),
  ('3318394762', '5213318394762', NULL, false),
  ('3325071363', '5213325071363', 'Denilson Are Peña Del Rio', false),
  ('3344872128', '5213344872128', NULL, false),
  ('3348093103', '5213348093103', NULL, false),
  ('6644219153', '5216644219153', NULL, true),
  ('7223226053', '5217223226053', NULL, false)
ON CONFLICT (telefono) DO NOTHING;
