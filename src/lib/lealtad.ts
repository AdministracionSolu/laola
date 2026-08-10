/**
 * Identificador y color de cada recompensa del ciclo.
 *
 * El ciclo son 4 recompensas, una cada 3 visitas, y al terminar vuelve a
 * empezar. El identificador es la POSICIÓN DENTRO DEL CICLO, no el conteo
 * de visitas de por vida: en la segunda vuelta, la visita 15 vuelve a ser
 * "Visita 3" y vuelve a ser naranja. Así el color siempre significa lo
 * mismo y el mesero lo reconoce de un vistazo.
 *
 * Estos identificadores son también los NIVELES del programa: lo que se
 * ve aquí, en la pantalla del cliente y en los niveles del admin es la
 * misma lista. Los hex de abajo son los que trae lealtad_niveles.color
 * (migración 20260810120000) — si alguien cambia un color en la base,
 * cámbialo también aquí.
 *
 * La Recompensa inicial (el balazo de bienvenida) va aparte y no lleva
 * color de ciclo: es una sola vez en la vida, no es una parada.
 */

export type RecompensaCiclo = {
  /** posicion que devuelve la base (1 a 4) */
  posicion: number;
  /** lo que se lee en pantalla y se dice en voz alta */
  identificador: string;
  color: string;
  /** el mismo color en hex: es el que vive en lealtad_niveles.color */
  hex: string;
  /** relleno del chip */
  bg: string;
  /** texto sobre ese relleno */
  texto: string;
  /** borde, que es lo que salva al blanco */
  borde: string;
};

export const RECOMPENSA_INICIAL_ID = "Recompensa inicial";

/** La parada 0: no es del ciclo, pero sí es un nivel y necesita chip. */
export const RECOMPENSA_INICIAL: RecompensaCiclo = {
  posicion: 0,
  identificador: RECOMPENSA_INICIAL_ID,
  color: "Gris",
  hex: "#94a3b8",
  bg: "bg-slate-400",
  texto: "text-white",
  borde: "border-slate-500",
};

export const CICLO_RECOMPENSAS: RecompensaCiclo[] = [
  {
    posicion: 1,
    identificador: "Visita 3",
    color: "Naranja",
    hex: "#f97316",
    bg: "bg-orange-500",
    texto: "text-white",
    borde: "border-orange-600",
  },
  {
    posicion: 2,
    identificador: "Visita 6",
    color: "Azul",
    hex: "#2563eb",
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
    hex: "#ffffff",
    bg: "bg-white",
    texto: "text-neutral-900",
    borde: "border-neutral-400",
  },
  {
    posicion: 4,
    identificador: "Visita 12",
    color: "Verde",
    hex: "#059669",
    bg: "bg-emerald-600",
    texto: "text-white",
    borde: "border-emerald-700",
  },
];

/** Los niveles del programa: la parada 0 más las 4 del ciclo, en orden. */
export const NIVELES: RecompensaCiclo[] = [RECOMPENSA_INICIAL, ...CICLO_RECOMPENSAS];

/** Devuelve la recompensa del ciclo por su posición (1 a 4). */
export function recompensaDeCiclo(posicion?: number | null): RecompensaCiclo | null {
  if (!posicion) return null;
  return CICLO_RECOMPENSAS.find((r) => r.posicion === posicion) ?? null;
}

/**
 * Chip de un NIVEL por su posición: igual que recompensaDeCiclo pero la
 * posición 0 (Recompensa inicial) sí devuelve estilo en vez de null.
 */
export function nivelDePosicion(posicion?: number | null): RecompensaCiclo {
  return NIVELES.find((n) => n.posicion === (posicion ?? 0)) ?? RECOMPENSA_INICIAL;
}

/**
 * Texto legible sobre un color de fondo cualquiera. Existe por el nivel
 * blanco: un badge blanco con letra blanca es un badge en blanco.
 */
export function textoSobre(hex: string): string {
  const h = hex.replace("#", "");
  const n = h.length === 3 ? h.split("").map((c) => c + c).join("") : h;
  if (n.length !== 6) return "#ffffff";
  const [r, g, b] = [0, 2, 4].map((i) => parseInt(n.slice(i, i + 2), 16) / 255);
  const lin = (c: number) => (c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4);
  const luz = 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b);
  return luz > 0.5 ? "#171717" : "#ffffff";
}
