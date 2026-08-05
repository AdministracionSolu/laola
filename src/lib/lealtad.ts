/**
 * Identificador y color de cada recompensa del ciclo.
 *
 * El ciclo son 4 recompensas, una cada 3 visitas, y al terminar vuelve a
 * empezar. El identificador es la POSICIÓN DENTRO DEL CICLO, no el conteo
 * de visitas de por vida: en la segunda vuelta, la visita 15 vuelve a ser
 * "Visita 3" y vuelve a ser naranja. Así el color siempre significa lo
 * mismo y el mesero lo reconoce de un vistazo.
 *
 * La Recompensa inicial (el balazo de bienvenida) va aparte y no lleva
 * color: es una sola vez en la vida, no parte del ciclo.
 */

export type RecompensaCiclo = {
  /** posicion que devuelve la base (1 a 4) */
  posicion: number;
  /** lo que se lee en pantalla y se dice en voz alta */
  identificador: string;
  color: string;
  /** relleno del chip */
  bg: string;
  /** texto sobre ese relleno */
  texto: string;
  /** borde, que es lo que salva al blanco */
  borde: string;
};

export const RECOMPENSA_INICIAL_ID = "Recompensa inicial";

export const CICLO_RECOMPENSAS: RecompensaCiclo[] = [
  {
    posicion: 1,
    identificador: "Visita 3",
    color: "Naranja",
    bg: "bg-orange-500",
    texto: "text-white",
    borde: "border-orange-600",
  },
  {
    posicion: 2,
    identificador: "Visita 6",
    color: "Azul",
    bg: "bg-blue-600",
    texto: "text-white",
    borde: "border-blue-700",
  },
  {
    // El blanco desaparece sobre fondo claro, por eso lleva borde marcado
    // y texto oscuro. Es el único que no puede ir en texto blanco.
    posicion: 3,
    identificador: "Visita 9",
    color: "Blanco",
    bg: "bg-white",
    texto: "text-neutral-900",
    borde: "border-neutral-400",
  },
  {
    posicion: 4,
    identificador: "Visita 12",
    color: "Verde",
    bg: "bg-emerald-600",
    texto: "text-white",
    borde: "border-emerald-700",
  },
];

/** Devuelve la recompensa del ciclo por su posición (1 a 4). */
export function recompensaDeCiclo(posicion?: number | null): RecompensaCiclo | null {
  if (!posicion) return null;
  return CICLO_RECOMPENSAS.find((r) => r.posicion === posicion) ?? null;
}
