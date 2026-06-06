// Zona horaria del negocio (mariscos La Ola). Define "el pedido del día"
// sin depender de UTC ni del huso del dispositivo.
export const TZ_NEGOCIO = "America/Mexico_City";

/** Fecha del negocio (yyyy-MM-dd) en zona horaria local del restaurante. */
export function getFechaNegocio(date: Date = new Date()): string {
  // en-CA produce el formato yyyy-MM-dd directamente.
  return new Intl.DateTimeFormat("en-CA", {
    timeZone: TZ_NEGOCIO,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(date);
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
