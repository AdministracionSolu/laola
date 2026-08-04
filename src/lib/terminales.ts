/**
 * Terminales punto de venta.
 *
 * Espiral solo existe en Valle. En cualquier otra sucursal no se captura
 * ni se muestra, para que nadie tenga que escribir un cero de más.
 *
 * Se reconoce por el prefijo de folio (VAL) y, si viniera vacío, por el
 * nombre. Así no depende de un UUID escrito a mano en el código.
 */

function normaliza(s: string): string {
  return s
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "") // quita acentos
    .trim();
}

export function tieneEspiral(
  sucursal?: { nombre?: string | null; prefijo_folio?: string | null } | null
): boolean {
  if (!sucursal) return false;
  const codigo = (sucursal.prefijo_folio ?? "").trim().toUpperCase();
  if (codigo) return codigo === "VAL";
  return normaliza(sucursal.nombre ?? "").includes("valle");
}
