// Zona horaria del negocio: Nayarit usa horario de Mazatlán (Montaña).
export const TZ_NEGOCIO = "America/Mazatlan";

// Hora de corte del pedido: a partir de esta hora local, lo capturado cuenta
// para el DÍA SIGUIENTE (el pedido de mariscos se hace de noche para mañana).
const HORA_CORTE = 13; // 1:00 p.m.

function partesNegocio(date: Date) {
  const fmt = new Intl.DateTimeFormat("en-CA", {
    timeZone: TZ_NEGOCIO,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    hourCycle: "h23",
  });
  const p = Object.fromEntries(fmt.formatToParts(date).map((x) => [x.type, x.value]));
  return { y: +p.year, m: +p.month, d: +p.day, hour: +p.hour };
}

function ymd(y: number, m: number, d: number): string {
  const base = new Date(Date.UTC(y, m - 1, d));
  return `${base.getUTCFullYear()}-${String(base.getUTCMonth() + 1).padStart(2, "0")}-${String(
    base.getUTCDate()
  ).padStart(2, "0")}`;
}

/**
 * Fecha del PEDIDO (yyyy-MM-dd) en zona del negocio con corte a la 1 p.m.:
 * capturas ≥ 1 p.m. cuentan para mañana; antes de la 1 p.m. (incluida la
 * madrugada hasta el cierre tardío) cuentan para hoy.
 */
export function getFechaNegocio(date: Date = new Date()): string {
  const { y, m, d, hour } = partesNegocio(date);
  if (hour >= HORA_CORTE) {
    const next = new Date(Date.UTC(y, m - 1, d + 1));
    return ymd(next.getUTCFullYear(), next.getUTCMonth() + 1, next.getUTCDate());
  }
  return ymd(y, m, d);
}

/** Fecha calendario local (sin corte) — para fechar la recepción del día. */
export function getFechaCalendario(date: Date = new Date()): string {
  const { y, m, d } = partesNegocio(date);
  return ymd(y, m, d);
}

/** Hora corta (ej. "9:14 a.m.") en zona horaria del negocio. */
export function getHoraNegocio(value: string | Date): string {
  const date = typeof value === "string" ? new Date(value) : value;
  return new Intl.DateTimeFormat("es-MX", {
    timeZone: TZ_NEGOCIO,
    hour: "numeric",
    minute: "2-digit",
  }).format(date);
}
