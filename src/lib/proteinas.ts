// Lista oficial de proteínas (lo único que se pide). Sirve como filtro de
// seguridad en el front: aunque la base tenga asignados otros insumos a una
// sucursal, cocina solo ve estos. Reconoce tanto el nombre real en MAYÚSCULAS
// (como está hoy en la base) como el nombre "bonito" canónico.

interface ProteinaDef {
  // Nombre tal cual puede estar en la base (mayúsculas heredadas o canónico).
  variantes: string[];
  display: string;
  unidad: string;
  orden: number;
  // La existencia se cuenta en dos partes: procesado y no procesado. Solo
  // afecta la captura de EXISTENCIA; el pedido sigue siendo una sola cantidad.
  // La base manda (insumos.desglosa_procesado); esto es el valor por omisión
  // para que la pantalla funcione antes de correr la migración.
  desglosa?: boolean;
}

// Lista conciliada con sucursal (jul-2026): nombres, unidades y orden finales.
export const PROTEINAS: ProteinaDef[] = [
  { variantes: ["CAMARON 61-70", "Camarón 61-70"], display: "Camarón 61-70", unidad: "kg", orden: 1, desglosa: true },
  { variantes: ["CAMARON 31-35", "Camarón 31-35"], display: "Camarón 31-35", unidad: "kg", orden: 2, desglosa: true },
  { variantes: ["CAMARON 21-25", "Camarón 21-25"], display: "Camarón 21-25", unidad: "kg", orden: 3, desglosa: true },
  { variantes: ["PULPO 2-4", "Pulpo 2-4"], display: "Pulpo 2-4", unidad: "kg", orden: 4, desglosa: true },
  { variantes: ["ATÚN MEDALLON pz", "ATUN MEDALLON pz", "Atún medallón", "Medallón de atún"], display: "Atún medallón", unidad: "pz", orden: 5 },
  { variantes: ["MARLIN AHUMADO K.", "Marlin ahumado", "Marlín ahumado"], display: "Marlín ahumado", unidad: "kg", orden: 6, desglosa: true },
  { variantes: ["ROBALO (chicharrón)", "ROBALO (chicharron)", "Robalo chico", "Robalo ch."], display: "Robalo ch.", unidad: "kg", orden: 7, desglosa: true },
  { variantes: ["ROBALO (filete)", "Robalo filete"], display: "Robalo filete", unidad: "kg", orden: 8, desglosa: true },
  { variantes: ["SIERRA", "Sierra"], display: "Sierra", unidad: "kg", orden: 9, desglosa: true },
  { variantes: ["CAMARON VAPOR 25 a 30 gr", "Camarón vapor 25-30"], display: "Camarón vapor 25-30", unidad: "kg", orden: 10 },
  { variantes: ["CAMARON P/VAPOR 20/30", "Camarón p/vapor 20/30", "Camarón p/vapor 20-30"], display: "Camarón p/vapor 20/30", unidad: "kg", orden: 11 },
  { variantes: ["CAMARON 7 A 11 GR", "Camarón 7-11"], display: "Camarón 7-11", unidad: "kg", orden: 12, desglosa: true },
  { variantes: ["CAMARON 12 - 25 GR", "Camarón 12-25"], display: "Camarón 12-25", unidad: "kg", orden: 13, desglosa: true },
  { variantes: ["CAMARON SECO K.", "Camarón seco"], display: "Camarón seco", unidad: "kg", orden: 14 },
  { variantes: ["BOLSAS OSTIÓN", "BOLSAS OSTION", "Bolsas ostión"], display: "Bolsas ostión", unidad: "bolsa", orden: 15 },
  { variantes: ["CALLO DE HACHA", "Callo de hacha"], display: "Callo de hacha", unidad: "kg", orden: 16 },
  { variantes: ["ALITAS", "Alitas"], display: "Alitas", unidad: "bolsa", orden: 17 },
  { variantes: ["BONELESS", "Boneless"], display: "Boneless", unidad: "bolsa", orden: 18 },
  { variantes: ["PIZZAS", "Pizzas"], display: "Pizzas", unidad: "pz", orden: 19 },
  { variantes: ["FILETE DE RES", "Filete de res"], display: "Filete de res", unidad: "kg", orden: 20 },
  { variantes: ["COSTILLA DE CERDO", "Costilla de cerdo"], display: "Costilla de cerdo", unidad: "kg", orden: 21 },
  { variantes: ["PESCADO P/SARANDEAR", "Pescado p/sarandear"], display: "Pescado p/sarandear", unidad: "pz", orden: 22 },
  // Postres (ago-2026): entran a existencia y pedido como cualquier insumo.
  { variantes: ["FLAN", "Flan"], display: "Flan", unidad: "pz", orden: 23 },
  { variantes: ["PAY", "Pay", "PAY DE LA CASA", "Pie"], display: "Pay", unidad: "pz", orden: 24 },
  { variantes: ["TARTA VASCA", "Tarta vasca", "Tarta Vasca", "TARTA DE QUESO VASCA"], display: "Tarta vasca", unidad: "pz", orden: 25 },
  { variantes: ["BROWNIE", "Brownie", "BROWNIES"], display: "Brownie", unidad: "pz", orden: 26 },
];

// Normaliza un nombre: mayúsculas, sin acentos, sin signos, espacios colapsados.
function norm(nombre: string): string {
  return nombre
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "")
    .toUpperCase()
    .replace(/[^A-Z0-9]+/g, " ")
    .trim();
}

const INDEX = new Map<string, ProteinaDef>();
for (const p of PROTEINAS) {
  for (const v of p.variantes) INDEX.set(norm(v), p);
}

export function infoProteina(nombre: string): ProteinaDef | undefined {
  return INDEX.get(norm(nombre));
}

export function esProteina(nombre: string): boolean {
  return INDEX.has(norm(nombre));
}

// Clave para agrupar en la comparativa los productos de distintos proveedores
// que son "lo mismo": usa el nombre canónico de la proteína si se reconoce
// (así "Camarón 21/25" y "Camarón 21-25" caen juntos); si no, el nombre
// normalizado. Sin mapeo manual a insumo interno.
export function claveProducto(nombre: string): string {
  const info = infoProteina(nombre);
  return info ? `p:${info.orden}` : `n:${norm(nombre)}`;
}

// Etiqueta bonita para un grupo de la comparativa.
export function etiquetaProducto(nombre: string): string {
  return infoProteina(nombre)?.display ?? nombre;
}
