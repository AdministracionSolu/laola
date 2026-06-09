/**
 * Seed del menú de pedidos en línea desde db/seed/menu_seed.csv
 *
 * Modos:
 *   npx tsx scripts/seed-menu.ts          → siembra directo en Supabase
 *                                           (requiere SUPABASE_URL y SUPABASE_SERVICE_ROLE_KEY
 *                                            como variables de entorno; NUNCA hardcodeadas)
 *   npx tsx scripts/seed-menu.ts --sql    → genera db/seed/menu_seed.sql (para pegar en el
 *                                           SQL Editor de Lovable/Supabase)
 *
 * Idempotente: corre dos veces y no duplica (upsert por nombre/variante).
 * El upsert de precios NO toca la columna `disponible` (respeta los toggles
 * de "agotado" que haya puesto el staff).
 */
import { readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const RAIZ = join(dirname(fileURLToPath(import.meta.url)), "..");
const RUTA_CSV = join(RAIZ, "db", "seed", "menu_seed.csv");
const RUTA_SQL = join(RAIZ, "db", "seed", "menu_seed.sql");

// Columna del CSV → nombre de la sucursal en la tabla `sucursales`
const SUCURSALES: Array<{ columna: string; nombre: string }> = [
  { columna: "precio_valle", nombre: "Del Valle" },
  { columna: "precio_brisas", nombre: "Las Brisas" },
  { columna: "precio_cerveceria", nombre: "Cervecería" },
  { columna: "precio_solares", nombre: "Solares" },
];

interface Fila {
  categoria: string;
  item: string;
  variante: string;
  precios: Record<string, number | null>; // por nombre de sucursal
  es_alcohol: boolean;
  descripcion: string;
}

// ---------- Parseo CSV (soporta comillas dobles por seguridad) ----------
function parsearCsv(texto: string): string[][] {
  const filas: string[][] = [];
  let fila: string[] = [];
  let campo = "";
  let enComillas = false;
  for (let i = 0; i < texto.length; i++) {
    const c = texto[i];
    if (enComillas) {
      if (c === '"') {
        if (texto[i + 1] === '"') {
          campo += '"';
          i++;
        } else {
          enComillas = false;
        }
      } else {
        campo += c;
      }
    } else if (c === '"') {
      enComillas = true;
    } else if (c === ",") {
      fila.push(campo);
      campo = "";
    } else if (c === "\n" || c === "\r") {
      if (c === "\r" && texto[i + 1] === "\n") i++;
      fila.push(campo);
      campo = "";
      if (fila.some((v) => v !== "")) filas.push(fila);
      fila = [];
    } else {
      campo += c;
    }
  }
  fila.push(campo);
  if (fila.some((v) => v !== "")) filas.push(fila);
  return filas;
}

function leerFilas(): Fila[] {
  const crudo = parsearCsv(readFileSync(RUTA_CSV, "utf8"));
  const encabezado = crudo[0];
  const idx = (nombre: string): number => {
    const i = encabezado.indexOf(nombre);
    if (i < 0) throw new Error(`Columna faltante en CSV: ${nombre}`);
    return i;
  };
  const iCat = idx("categoria");
  const iItem = idx("item");
  const iVar = idx("variante");
  const iAlc = idx("es_alcohol");
  const iDesc = idx("descripcion");
  return crudo.slice(1).map((f) => {
    const precios: Record<string, number | null> = {};
    for (const s of SUCURSALES) {
      const v = (f[idx(s.columna)] || "").trim();
      precios[s.nombre] = v === "" ? null : Number(v);
    }
    return {
      categoria: f[iCat].trim(),
      item: f[iItem].trim(),
      variante: f[iVar].trim(),
      precios,
      es_alcohol: f[iAlc].trim() === "1",
      descripcion: (f[iDesc] || "").trim(),
    };
  });
}

// Las notas "VALIDAR ..." del CSV son para el dueño, no para el cliente:
// se quitan de la descripción pública (quedan en el CSV y en docs).
function limpiarDescripcion(desc: string): string | null {
  const sinValidar = desc.replace(/\.?\s*VALIDAR.*$/i, "").trim();
  return sinValidar === "" ? null : sinValidar;
}

// ---------- Opciones jsonb por item ----------
function opcionesParaItem(categoria: string, item: string): Record<string, string[]> | null {
  if (/a la diabla/i.test(item)) return { preparacion: ["Suave", "Normal", "Picante"] };
  if (categoria === "Aguachiles") return { estilo: ["Tradicional verde", "Rojo de chiltepín", "Negro salseado"] };
  if (categoria === "Ensaladas") return { estilo: ["Al natural", "Salseada", "Bañada con chiltepín"] };
  switch (item) {
    case "Pay":
      return { sabor: ["Fresa", "Guayaba", "Calabaza"] };
    case "Flan":
      return { sabor: ["Cajeta", "Caramelo"] };
    case "Boneless":
    case "Alitas de pollo":
      return { sabor: ["BBQ", "Buffalo", "Red Hot Frank's", "Mango habanero"] };
    case "Refresco":
      return { sabor: ["Coca-Cola", "Coca-Cola Light", "Coca-Cola Sin Azúcar", "Sprite", "Topo Chico", "Fresca", "Fanta", "Mundet"] };
    case "Quesadillas natural jamón o salchicha":
      return { tipo: ["Natural", "Jamón", "Salchicha"] };
    case "Quesadillas de camarón o pulpo":
      return { tipo: ["Camarón", "Pulpo"] };
    case "Michelada de sabor":
      return { sabor: ["Mango", "Piña", "Tamarindo"] };
    case "Mezcalitas":
      return { sabor: ["Jamaica", "Pepino", "Mandarina", "Maracuyá", "Mango"] };
    case "Taco capeado":
      return { tipo: ["Camarón", "Pescado"] };
    case "Manitas de jaiba":
      return { preparacion: ["A la diabla", "A la plancha", "A la mantequilla", "Al mojo de ajo", "Al ajillo", "Al vapor"] };
    case "Limonada / Naranjada":
      return { tipo: ["Limonada", "Naranjada"] };
    case "Piñada / Fresada":
      return { tipo: ["Piñada", "Fresada"] };
    case "Cielo rojo / Chelada / Michelada":
      return { tipo: ["Cielo rojo", "Chelada", "Michelada"] };
    case "Agua Delixis":
      return { sabor: ["Té de jazmín", "Jamaica", "Horchata"] };
    case "Agua de sabor":
      return { sabor: ["Tamarindo", "Jamaica", "Pepino-limón", "Horchata de fresa"] };
    default:
      return null;
  }
}

// ---------- Modelo en memoria ----------
interface Variante {
  nombre: string;
  orden: number;
  precios: Record<string, number | null>;
}
interface Item {
  nombre: string;
  orden: number;
  descripcion: string | null;
  es_alcohol: boolean;
  opciones: Record<string, string[]> | null;
  variantes: Variante[];
}
interface Categoria {
  nombre: string;
  orden: number;
  items: Item[];
}

function construirCatalogo(filas: Fila[]): Categoria[] {
  const categorias: Categoria[] = [];
  for (const fila of filas) {
    let cat = categorias.find((c) => c.nombre === fila.categoria);
    if (!cat) {
      cat = { nombre: fila.categoria, orden: categorias.length, items: [] };
      categorias.push(cat);
    }
    let item = cat.items.find((i) => i.nombre === fila.item);
    if (!item) {
      item = {
        nombre: fila.item,
        orden: cat.items.length,
        descripcion: limpiarDescripcion(fila.descripcion),
        es_alcohol: fila.es_alcohol,
        opciones: opcionesParaItem(fila.categoria, fila.item),
        variantes: [],
      };
      cat.items.push(item);
    } else {
      if (!item.descripcion) item.descripcion = limpiarDescripcion(fila.descripcion);
      if (fila.es_alcohol) item.es_alcohol = true;
    }
    item.variantes.push({
      nombre: fila.variante,
      orden: item.variantes.length,
      precios: fila.precios,
    });
  }
  return categorias;
}

// ---------- Generación de SQL ----------
function sql(valor: string): string {
  return `'${valor.replace(/'/g, "''")}'`;
}

function generarSql(categorias: Categoria[]): string {
  const lineas: string[] = [];
  lineas.push("-- ============================================================");
  lineas.push("-- SEED DEL MENÚ — generado por scripts/seed-menu.ts --sql");
  lineas.push("-- Idempotente: se puede correr más de una vez sin duplicar.");
  lineas.push("-- El upsert de precios NO toca `disponible` (toggles del staff).");
  lineas.push("-- ============================================================");
  lineas.push("");
  for (const cat of categorias) {
    lineas.push(`-- ===== ${cat.nombre} =====`);
    lineas.push(
      `INSERT INTO public.menu_categorias (nombre, orden) VALUES (${sql(cat.nombre)}, ${cat.orden})` +
        ` ON CONFLICT (nombre) DO UPDATE SET orden = EXCLUDED.orden;`
    );
    for (const item of cat.items) {
      const desc = item.descripcion ? sql(item.descripcion) : "NULL";
      const opc = item.opciones ? `${sql(JSON.stringify(item.opciones))}::jsonb` : "NULL";
      lineas.push(
        `INSERT INTO public.menu_items (categoria_id, nombre, descripcion, es_alcohol, opciones, orden)\n` +
          `  SELECT c.id, ${sql(item.nombre)}, ${desc}, ${item.es_alcohol}, ${opc}, ${item.orden}\n` +
          `  FROM public.menu_categorias c WHERE c.nombre = ${sql(cat.nombre)}\n` +
          `  ON CONFLICT (categoria_id, nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion, es_alcohol = EXCLUDED.es_alcohol, opciones = EXCLUDED.opciones, orden = EXCLUDED.orden;`
      );
      for (const variante of item.variantes) {
        lineas.push(
          `INSERT INTO public.menu_variantes (item_id, nombre, orden)\n` +
            `  SELECT i.id, ${sql(variante.nombre)}, ${variante.orden}\n` +
            `  FROM public.menu_items i JOIN public.menu_categorias c ON c.id = i.categoria_id\n` +
            `  WHERE c.nombre = ${sql(cat.nombre)} AND i.nombre = ${sql(item.nombre)}\n` +
            `  ON CONFLICT (item_id, nombre) DO UPDATE SET orden = EXCLUDED.orden;`
        );
        for (const suc of SUCURSALES) {
          const precio = variante.precios[suc.nombre];
          if (precio === null) continue;
          lineas.push(
            `INSERT INTO public.menu_variante_sucursal (variante_id, sucursal_id, precio)\n` +
              `  SELECT v.id, s.id, ${precio.toFixed(2)}\n` +
              `  FROM public.menu_variantes v\n` +
              `  JOIN public.menu_items i ON i.id = v.item_id\n` +
              `  JOIN public.menu_categorias c ON c.id = i.categoria_id\n` +
              `  CROSS JOIN public.sucursales s\n` +
              `  WHERE c.nombre = ${sql(cat.nombre)} AND i.nombre = ${sql(item.nombre)} AND v.nombre = ${sql(variante.nombre)} AND s.nombre = ${sql(suc.nombre)}\n` +
              `  ON CONFLICT (variante_id, sucursal_id) DO UPDATE SET precio = EXCLUDED.precio;`
          );
        }
      }
    }
    lineas.push("");
  }
  return lineas.join("\n");
}

// ---------- Siembra directa vía supabase-js ----------
async function sembrar(categorias: Categoria[]): Promise<void> {
  const url = process.env.SUPABASE_URL;
  const llave = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!url || !llave) {
    console.error("Faltan SUPABASE_URL y/o SUPABASE_SERVICE_ROLE_KEY en el entorno.");
    console.error("Ejemplo:");
    console.error('  SUPABASE_URL="https://xxx.supabase.co" SUPABASE_SERVICE_ROLE_KEY="..." npx tsx scripts/seed-menu.ts');
    process.exit(1);
  }
  const { createClient } = await import("@supabase/supabase-js");
  const supabase = createClient(url, llave, { auth: { persistSession: false } });

  const { data: sucursales, error: errSuc } = await supabase
    .from("sucursales")
    .select("id, nombre");
  if (errSuc) throw new Error(`No se pudieron leer sucursales: ${errSuc.message}`);
  const idSucursal = new Map<string, string>();
  for (const s of sucursales ?? []) idSucursal.set(s.nombre as string, s.id as string);
  for (const s of SUCURSALES) {
    if (!idSucursal.has(s.nombre)) {
      throw new Error(
        `La sucursal '${s.nombre}' no existe en la tabla sucursales. ` +
          `Aplica primero supabase/migrations/20260609120200_pedidos_en_linea_base.sql`
      );
    }
  }

  let nPrecios = 0;
  for (const cat of categorias) {
    const { data: catRow, error: e1 } = await supabase
      .from("menu_categorias")
      .upsert({ nombre: cat.nombre, orden: cat.orden }, { onConflict: "nombre" })
      .select("id")
      .single();
    if (e1 || !catRow) throw new Error(`Categoría '${cat.nombre}': ${e1?.message}`);

    for (const item of cat.items) {
      const { data: itemRow, error: e2 } = await supabase
        .from("menu_items")
        .upsert(
          {
            categoria_id: catRow.id,
            nombre: item.nombre,
            descripcion: item.descripcion,
            es_alcohol: item.es_alcohol,
            opciones: item.opciones,
            orden: item.orden,
          },
          { onConflict: "categoria_id,nombre" }
        )
        .select("id")
        .single();
      if (e2 || !itemRow) throw new Error(`Item '${item.nombre}': ${e2?.message}`);

      for (const variante of item.variantes) {
        const { data: varRow, error: e3 } = await supabase
          .from("menu_variantes")
          .upsert(
            { item_id: itemRow.id, nombre: variante.nombre, orden: variante.orden },
            { onConflict: "item_id,nombre" }
          )
          .select("id")
          .single();
        if (e3 || !varRow) throw new Error(`Variante '${item.nombre} / ${variante.nombre}': ${e3?.message}`);

        for (const suc of SUCURSALES) {
          const precio = variante.precios[suc.nombre];
          if (precio === null) continue;
          // Solo precio: no se manda `disponible` para no pisar toggles del staff
          const { error: e4 } = await supabase
            .from("menu_variante_sucursal")
            .upsert(
              { variante_id: varRow.id, sucursal_id: idSucursal.get(suc.nombre), precio },
              { onConflict: "variante_id,sucursal_id" }
            );
          if (e4) throw new Error(`Precio '${item.nombre} / ${variante.nombre} / ${suc.nombre}': ${e4.message}`);
          nPrecios++;
        }
      }
    }
    console.log(`✓ ${cat.nombre} (${cat.items.length} items)`);
  }
  console.log(`Listo: ${categorias.length} categorías, ${nPrecios} precios por sucursal.`);
}

// ---------- Main ----------
const categorias = construirCatalogo(leerFilas());
if (process.argv.includes("--sql")) {
  writeFileSync(RUTA_SQL, generarSql(categorias), "utf8");
  const nItems = categorias.reduce((acc, c) => acc + c.items.length, 0);
  console.log(`SQL generado en db/seed/menu_seed.sql (${categorias.length} categorías, ${nItems} items).`);
} else {
  sembrar(categorias).catch((err) => {
    console.error(err);
    process.exit(1);
  });
}
