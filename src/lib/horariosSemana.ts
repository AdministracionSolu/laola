import { startOfWeek, addWeeks, addDays, format, isSameMonth, parseISO } from "date-fns";
import { es } from "date-fns/locale";

// ============================================================
// Horario de la semana (por archivo)
//
// La semana SIEMPRE se identifica por su lunes, en formato YYYY-MM-DD.
// El archivo se guarda contra la semana que CUBRE, no contra el día en que
// se subió: por eso el encargado sube el domingo el horario que arranca al
// día siguiente y el administrador lo ve donde va.
// ============================================================

/** Áreas que entregan horario. Mismas etiquetas que el catálogo de personal. */
export const AREAS_HORARIO = [
  "mesero",
  "cocina",
  "caja",
  "barman",
  "valet",
  "repartidor",
  "contabilidad",
] as const;

export type AreaHorario = (typeof AREAS_HORARIO)[number];

export const AREA_LABEL: Record<string, string> = {
  mesero: "Meseros",
  cocina: "Cocina",
  caja: "Caja",
  barman: "Barra",
  valet: "Valet parking",
  repartidor: "Repartidores",
  contabilidad: "Contabilidad",
};

export const areaLabel = (a: string) =>
  AREA_LABEL[a] ?? a.charAt(0).toUpperCase() + a.slice(1);

/** Lunes de la semana a la que pertenece una fecha. */
export const lunesDe = (d: Date | string): Date =>
  startOfWeek(typeof d === "string" ? parseISO(d) : d, { weekStartsOn: 1 });

/** YYYY-MM-DD sin pasar por UTC (toISOString correría un día en Mazatlán). */
export const isoFecha = (d: Date) => format(d, "yyyy-MM-dd");

/** Lunes de la semana en curso, como YYYY-MM-DD. */
export const semanaActual = () => isoFecha(lunesDe(new Date()));

/**
 * Semana que el sistema propone al subir.
 *
 * Los horarios se arman el fin de semana anterior. De jueves a domingo lo
 * que se está capturando es la semana que viene; de lunes a miércoles, la
 * que ya está corriendo. Siempre se puede cambiar a mano.
 */
export function semanaSugerida(hoy: Date = new Date()): string {
  const dow = hoy.getDay(); // 0=Dom … 6=Sáb
  const proxima = dow === 0 || dow >= 4;
  const lunes = lunesDe(hoy);
  return isoFecha(proxima ? addWeeks(lunes, 1) : lunes);
}

export const semanaDesplazada = (semanaISO: string, semanas: number) =>
  isoFecha(addWeeks(parseISO(semanaISO), semanas));

/** "10 al 16 de agosto" · "31 de agosto al 6 de septiembre" */
export function rotuloSemana(semanaISO: string): string {
  const lunes = parseISO(semanaISO);
  const domingo = addDays(lunes, 6);
  const mismoMes = isSameMonth(lunes, domingo);
  const ini = mismoMes
    ? format(lunes, "d", { locale: es })
    : format(lunes, "d 'de' MMMM", { locale: es });
  const fin = format(domingo, "d 'de' MMMM", { locale: es });
  return `${ini} al ${fin}`;
}

/** Rótulo con año, para historiales. */
export const rotuloSemanaLargo = (semanaISO: string) =>
  `${rotuloSemana(semanaISO)} de ${format(parseISO(semanaISO), "yyyy")}`;

/** Los 7 días de la semana, para pintar encabezados. */
export function diasDeSemana(semanaISO: string): Date[] {
  const lunes = parseISO(semanaISO);
  return Array.from({ length: 7 }, (_, i) => addDays(lunes, i));
}

/** "en curso" | "próxima" | "pasada" respecto de hoy. */
export function estadoSemana(semanaISO: string, hoy: Date = new Date()) {
  const actual = isoFecha(lunesDe(hoy));
  if (semanaISO === actual) return "en curso" as const;
  return semanaISO > actual ? ("próxima" as const) : ("pasada" as const);
}
