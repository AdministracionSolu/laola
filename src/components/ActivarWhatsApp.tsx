import { MessageCircle } from "lucide-react";

// Número que atiende el programa de lealtad. Es la línea establecida de La Ola
// (la misma de proveedores): tiene historial real y sobrevivió lo que tumbó a
// la segunda línea.
const NUMERO_LEALTAD = "523111223365";

/**
 * Botón "salúdanos por WhatsApp" de las pantallas de confirmación.
 *
 * No es un adorno de contacto: es el mecanismo que evita que nos vuelvan a
 * bloquear el número. Escribirle primero a alguien que nunca nos ha escrito,
 * desde una sesión vinculada en datacenter, es exactamente el patrón por el
 * que WhatsApp bloqueó la segunda línea de La Ola el 7 de agosto — un solo
 * mensaje bastó. Si el cliente saluda él, la bienvenida sale como RESPUESTA
 * dentro de la ventana de 24 h y deja de ser un primer toque en frío.
 *
 * Del lado de Makatea el goteo de bienvenidas prioriza a quien ya escribió y
 * no le cobra presupuesto diario, así que entre más gente toque este botón,
 * más rápido recibe todo el mundo.
 */
export default function ActivarWhatsApp({
  nombre,
  contexto,
}: {
  nombre?: string | null;
  contexto: "alta" | "visita";
}) {
  const quien = (nombre ?? "").trim();
  const texto =
    contexto === "alta"
      ? `Hola, soy ${quien || "un nuevo miembro"}. Me acabo de unir al programa de lealtad de La Ola 🌊`
      : `Hola, soy ${quien || "miembro del programa"}. Acabo de registrar mi visita en La Ola 🌊`;

  const href = `https://wa.me/${NUMERO_LEALTAD}?text=${encodeURIComponent(texto)}`;

  return (
    <a
      href={href}
      target="_blank"
      rel="noreferrer"
      className="flex items-center gap-3 w-full rounded-xl border-2 border-[#25D366] bg-[#25D366]/10 p-3.5 text-left transition-all hover:bg-[#25D366]/20 active:scale-[0.99]"
    >
      <div className="w-10 h-10 rounded-full bg-[#25D366] flex items-center justify-center shrink-0">
        <MessageCircle className="h-5 w-5 text-white" />
      </div>
      <div className="min-w-0 flex-1">
        <p className="font-semibold leading-tight">Salúdanos por WhatsApp</p>
        <p className="text-xs text-muted-foreground mt-0.5 leading-snug">
          Así te confirmamos tus beneficios y te avisamos de lo que te toca.
        </p>
      </div>
    </a>
  );
}
