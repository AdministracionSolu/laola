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
}

export const PROTEINAS: ProteinaDef[] = [
  { variantes: ["CAMARON 61-70", "Camarón 61-70"], display: "Camarón 61-70", unidad: "kg", orden: 1 },
  { variantes: ["CAMARON 31-35", "Camarón 31-35"], display: "Camarón 31-35", unidad: "kg", orden: 2 },
  { variantes: ["CAMARON 21-25", "Camarón 21-25"], display: "Camarón 21-25", unidad: "kg", orden: 3 },
  { variantes: ["PULPO 2-4", "Pulpo 2-4"], display: "Pulpo 2-4", unidad: "kg", orden: 4 },
  { variantes: ["ATÚN MEDALLON pz", "ATUN MEDALLON pz", "Atún medallón"], display: "Atún medallón", unidad: "pz", orden: 5 },
  { variantes: ["MARLIN AHUMADO K.", "Marlin ahumado"], display: "Marlin ahumado", unidad: "kg", orden: 6 },
  { variantes: ["ROBALO (chicharrón)", "ROBALO (chicharron)", "Robalo chico"], display: "Robalo chico", unidad: "kg", orden: 7 },
  { variantes: ["ROBALO (filete)", "Robalo filete"], display: "Robalo filete", unidad: "kg", orden: 8 },
  { variantes: ["SIERRA", "Sierra"], display: "Sierra", unidad: "kg", orden: 9 },
  { variantes: ["CAMARON VAPOR 25 a 30 gr", "Camarón vapor 25-30"], display: "Camarón vapor 25-30", unidad: "kg", orden: 10 },
  { variantes: ["CAMARON 7 A 11 GR", "Camarón 7-11"], display: "Camarón 7-11", unidad: "kg", orden: 11 },
  { variantes: ["CAMARON 12 - 25 GR", "Camarón 12-25"], display: "Camarón 12-25", unidad: "kg", orden: 12 },
  { variantes: ["CAMARON SECO K.", "Camarón seco"], display: "Camarón seco", unidad: "kg", orden: 13 },
  { variantes: ["BOLSAS OSTIÓN", "BOLSAS OSTION", "Bolsas ostión"], display: "Bolsas ostión", unidad: "bolsa", orden: 14 },
  { variantes: ["CALLO DE HACHA", "Callo de hacha"], display: "Callo de hacha", unidad: "kg", orden: 15 },
  { variantes: ["PESCADO P/SARANDEAR", "Pescado p/sarandear"], display: "Pescado p/sarandear", unidad: "pz", orden: 16 },
  { variantes: ["FILETE DE RES", "Filete de res"], display: "Filete de res", unidad: "kg", orden: 17 },
  { variantes: ["COSTILLA DE CERDO", "Costilla de cerdo"], display: "Costilla de cerdo", unidad: "kg", orden: 18 },
  { variantes: ["ALITAS", "Alitas"], display: "Alitas", unidad: "kg", orden: 19 },
  { variantes: ["BONELESS", "Boneless"], display: "Boneless", unidad: "kg", orden: 20 },
  { variantes: ["PIZZAS", "Pizzas"], display: "Pizzas", unidad: "pz", orden: 21 },
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
