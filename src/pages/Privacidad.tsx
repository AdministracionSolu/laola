import { Layout } from "@/components/layout/Layout";
import { WHATSAPP_LEALTAD, WHATSAPP_LEALTAD_VISIBLE } from "@/lib/lealtad";

// Aviso de privacidad simplificado (LFPDPPP art. 17). Lo enlazan el
// formulario de inscripción al programa (/lealtad), el de registro de
// visita (/visita) y el de facturación (/factura).
const ACTUALIZADO = "13 de agosto de 2026";

const Seccion = ({ titulo, children }: { titulo: string; children: React.ReactNode }) => (
  <section className="mb-8">
    <h2 className="font-display font-bold text-xl text-foreground mb-3">{titulo}</h2>
    <div className="space-y-3 text-muted-foreground leading-relaxed">{children}</div>
  </section>
);

export default function Privacidad() {
  return (
    <Layout>
      <section className="bg-gradient-ocean py-14 md:py-20">
        <div className="container mx-auto px-4 text-center">
          <h1 className="text-4xl md:text-5xl font-display font-bold text-white mb-3">
            Aviso de privacidad
          </h1>
          <p className="text-white/90">Actualizado el {ACTUALIZADO}</p>
        </div>
      </section>

      <section className="py-12 md:py-16 bg-background">
        <div className="container mx-auto px-4 max-w-3xl">
          <Seccion titulo="Quién trata tus datos">
            <p>
              La Ola, restaurante de mariscos con sucursales en Tepic, Nayarit y Zapopan,
              Jalisco, es responsable del uso y la protección de los datos personales que
              nos das.
            </p>
          </Seccion>

          <Seccion titulo="Qué datos recabamos">
            <p>
              Del programa de lealtad: tu nombre, tu teléfono, tu fecha de nacimiento, la
              sucursal donde te inscribiste y el registro de tus visitas y beneficios.
            </p>
            <p>
              De la facturación: tu RFC, tu razón social, tu régimen fiscal, tu código
              postal, tu correo, tu teléfono y los datos del consumo que vas a facturar.
            </p>
            <p>No pedimos datos financieros ni datos sensibles.</p>
          </Seccion>

          <Seccion titulo="Para qué los usamos">
            <p>
              Para operar el programa de lealtad: contar tus visitas, entregarte los
              beneficios que te tocan y llevar el control de lo que se canjea.
            </p>
            <p>
              Para escribirte por WhatsApp: darte la bienvenida, felicitarte en tu
              cumpleaños e invitarte cuando tenemos algo que contarte. Puedes pedirnos que
              dejemos de escribirte cuando quieras.
            </p>
            <p>Para emitir y enviarte tu factura.</p>
          </Seccion>

          <Seccion titulo="Con quién los compartimos">
            <p>
              No vendemos tus datos ni los damos a terceros para que te vendan algo.
            </p>
            <p>
              Nos apoyamos en proveedores de tecnología que los guardan y los transmiten
              por nosotros: nuestro proveedor de base de datos, la plataforma que envía
              los mensajes y el servicio de mensajería por el que te llegan. Cada uno los
              trata solo para prestarnos ese servicio.
            </p>
          </Seccion>

          <Seccion titulo="Tus derechos">
            <p>
              Puedes pedirnos acceder a tus datos, corregirlos, cancelarlos u oponerte a
              que los usemos, y también retirar tu consentimiento para que te escribamos.
            </p>
            <p>
              Escríbenos por WhatsApp al número del programa,{" "}
              <a
                href={`https://wa.me/${WHATSAPP_LEALTAD}`}
                target="_blank"
                rel="noreferrer"
                className="text-primary underline"
              >
                {WHATSAPP_LEALTAD_VISIBLE}
              </a>
              , o llámanos a la sucursal La Ola Valle, al{" "}
              <a href="tel:+523111330891" className="text-primary underline">
                311 133 0891
              </a>
              . Dinos tu nombre y tu teléfono para localizar tu registro. Te contestamos
              dentro de los 20 días hábiles que marca la ley.
            </p>
            <p>
              Para darte de baja del programa basta con pedirlo: borramos tu registro y
              dejas de recibir mensajes.
            </p>
          </Seccion>

          <Seccion titulo="Cambios a este aviso">
            <p>
              Si cambiamos algo, publicamos la versión nueva en esta misma página con su
              fecha de actualización.
            </p>
          </Seccion>
        </div>
      </section>
    </Layout>
  );
}
