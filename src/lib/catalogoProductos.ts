// Catálogo interno de productos que compra La Ola.
// Es la fuente única de nombres "buenos" (con acento y talla correctos).
// En el admin se elige por BOTONES (no se teclea), así todos los proveedores
// usan EXACTAMENTE el mismo nombre y la comparativa agrupa sin fallar por
// "camarón" vs "camaron" o "21/25" vs "21-25".

import { claveProducto } from "./proteinas";

export interface CatalogoItem {
  nombre: string;
  unidad: string;
  categoria: string;
}

export const CATALOGO_PRODUCTOS: CatalogoItem[] = [
  // Camarón
  { nombre: "Camarón 61-70", unidad: "kg", categoria: "Camarón" },
  { nombre: "Camarón 51-60", unidad: "kg", categoria: "Camarón" },
  { nombre: "Camarón 31-35", unidad: "kg", categoria: "Camarón" },
  { nombre: "Camarón 21-25", unidad: "kg", categoria: "Camarón" },
  { nombre: "Camarón 19g", unidad: "kg", categoria: "Camarón" },
  { nombre: "Camarón 12-25", unidad: "kg", categoria: "Camarón" },
  { nombre: "Camarón 7-11", unidad: "kg", categoria: "Camarón" },
  { nombre: "Camarón vapor 25-30", unidad: "kg", categoria: "Camarón" },
  { nombre: "Camarón fresco", unidad: "kg", categoria: "Camarón" },
  { nombre: "Camarón seco", unidad: "kg", categoria: "Camarón" },

  // Pescado y marisco
  { nombre: "Pulpo 2-4", unidad: "kg", categoria: "Pescado y marisco" },
  { nombre: "Marlin ahumado", unidad: "kg", categoria: "Pescado y marisco" },
  { nombre: "Atún medallón", unidad: "pz", categoria: "Pescado y marisco" },
  { nombre: "Atún steak", unidad: "kg", categoria: "Pescado y marisco" },
  { nombre: "Róbalo chico", unidad: "kg", categoria: "Pescado y marisco" },
  { nombre: "Róbalo filete", unidad: "kg", categoria: "Pescado y marisco" },
  { nombre: "Sierra", unidad: "kg", categoria: "Pescado y marisco" },
  { nombre: "Callo de hacha", unidad: "kg", categoria: "Pescado y marisco" },
  { nombre: "Ostión", unidad: "bolsa", categoria: "Pescado y marisco" },
  { nombre: "Pescado p/sarandear", unidad: "pz", categoria: "Pescado y marisco" },

  // Carne y pollo
  { nombre: "Filete de res", unidad: "kg", categoria: "Carne y pollo" },
  { nombre: "Sirloin", unidad: "kg", categoria: "Carne y pollo" },
  { nombre: "Diezmillo", unidad: "kg", categoria: "Carne y pollo" },
  { nombre: "Molida", unidad: "kg", categoria: "Carne y pollo" },
  { nombre: "Costilla de cerdo", unidad: "kg", categoria: "Carne y pollo" },
  { nombre: "Alitas", unidad: "kg", categoria: "Carne y pollo" },
  { nombre: "Boneless", unidad: "kg", categoria: "Carne y pollo" },
  { nombre: "Nuggets", unidad: "kg", categoria: "Carne y pollo" },
  { nombre: "Aros", unidad: "kg", categoria: "Carne y pollo" },
  { nombre: "Dedos de queso", unidad: "kg", categoria: "Carne y pollo" },
  { nombre: "Cubos de pechuga", unidad: "pz", categoria: "Carne y pollo" },

  // Papas y otros
  { nombre: "Papa gajo", unidad: "kg", categoria: "Otros" },
  { nombre: "Papas punta cáscara", unidad: "kg", categoria: "Otros" },
  { nombre: "Pizzas", unidad: "pz", categoria: "Otros" },
];

// Orden de las categorías tal como se muestran.
export const CATEGORIAS_CATALOGO = [
  "Camarón",
  "Pescado y marisco",
  "Carne y pollo",
  "Otros",
];

// Set con las claves del catálogo (para saber si un producto ya existente
// cae dentro del catálogo o quedó "fuera de catálogo").
export const CLAVES_CATALOGO = new Set(CATALOGO_PRODUCTOS.map((c) => claveProducto(c.nombre)));

export function itemPorClave(clave: string): CatalogoItem | undefined {
  return CATALOGO_PRODUCTOS.find((c) => claveProducto(c.nombre) === clave);
}
