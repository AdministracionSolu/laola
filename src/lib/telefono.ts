/**
 * Teléfonos, una sola regla para todo La Ola.
 *
 * Nació de un caso real: el proveedor Capital Camaronera está guardado como
 * "+52 1 311 227 6299" y quien le mandaba el agradecimiento diario exigía diez
 * dígitos pelones. Ese número trae trece, así que capturó precios casi a diario
 * durante tres semanas y nunca recibió nada. El error era un 400 que no miraba
 * nadie.
 *
 * De ahí las dos reglas:
 *   1. Tolerar el formato de entrada. La gente escribe con lada, con espacios,
 *      con guiones y con el 1 viejo de móvil.
 *   2. No inventar. Lo que no cuadra a diez dígitos mexicanos se rechaza para
 *      que alguien lo vea, en vez de recortarse a un número que sí existe y le
 *      pertenece a otra persona.
 *
 * El espejo de esto en el backend es makatea-core → _shared/phone.ts
 * (normalizePhoneMx). Si cambia una regla, cambian las dos.
 */

/** Los diez dígitos nacionales, o null si el número no es reconocible. */
export function telefonoMx10(valor: string | null | undefined): string | null {
  const bruto = String(valor ?? "").trim();
  let d = bruto.replace(/\D/g, "");
  if (!d) return null;
  if (d.startsWith("00")) d = d.slice(2);
  // Lada explícita que no es México: no es asunto nuestro, mejor rechazarlo.
  if ((bruto.startsWith("+") || /^00\d/.test(bruto)) && !d.startsWith("52")) return null;
  if (d.startsWith("521") && d.length === 13) d = d.slice(3);
  else if (d.startsWith("52") && d.length === 12) d = d.slice(2);
  else if (d.length === 11 && (d.startsWith("1") || d.startsWith("0"))) d = d.slice(1);
  return d.length === 10 ? d : null;
}

/** Como lo lee una persona: "31 1122 6727". Para enseñárselo de vuelta. */
export function telefonoLegible(valor: string | null | undefined): string | null {
  const d = telefonoMx10(valor);
  return d ? `${d.slice(0, 2)} ${d.slice(2, 6)} ${d.slice(6)}` : null;
}
