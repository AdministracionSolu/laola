import { useQuery } from "@tanstack/react-query";
import {
  db,
  type HorarioSucursal,
  type MenuCategoria,
  type MenuItem,
  type MenuVariante,
  type PrecioVarianteSucursal,
  type SucursalEnLinea,
  type ZonaReparto,
} from "@/lib/pedidosEnLinea";

const COLUMNAS_SUCURSAL =
  "id, nombre, direccion, slug, telefono_contacto, pedidos_en_linea_activos, pedidos_pausados_hasta, venta_alcohol_en_linea, tiempo_estimado_min, prefijo_folio, zona_horaria";

/** Sucursales con su configuración de pedidos en línea + horarios (página pública). */
export function useSucursalesEnLinea() {
  return useQuery({
    queryKey: ["sucursales-en-linea"],
    queryFn: async (): Promise<{ sucursales: SucursalEnLinea[]; horarios: HorarioSucursal[] }> => {
      const [sucRes, horRes] = await Promise.all([
        db.from("sucursales").select(COLUMNAS_SUCURSAL).order("nombre"),
        db.from("horarios_sucursal").select("*"),
      ]);
      if (sucRes.error) throw sucRes.error;
      if (horRes.error) throw horRes.error;
      return {
        sucursales: (sucRes.data ?? []) as SucursalEnLinea[],
        horarios: (horRes.data ?? []) as HorarioSucursal[],
      };
    },
    refetchInterval: 60_000, // pausa/apertura se reflejan sin recargar
  });
}

export interface VarianteConPrecio extends MenuVariante {
  precio: number;
  disponible: boolean;
}

export interface ItemConVariantes extends MenuItem {
  variantes: VarianteConPrecio[];
  precioMin: number;
  precioMax: number;
}

export interface CategoriaConItems extends MenuCategoria {
  items: ItemConVariantes[];
}

/**
 * Menú público de UNA sucursal: solo categorías activas, solo variantes con
 * precio en esa sucursal y disponibles; sin alcohol si la sucursal no tiene
 * habilitada la venta en línea.
 */
export function useMenuSucursal(sucursal: SucursalEnLinea | null) {
  return useQuery({
    queryKey: ["menu-sucursal", sucursal?.id],
    enabled: !!sucursal,
    queryFn: async (): Promise<CategoriaConItems[]> => {
      if (!sucursal) return [];
      const [catRes, itemRes, varRes, precioRes] = await Promise.all([
        db.from("menu_categorias").select("*").eq("activa", true).order("orden"),
        db.from("menu_items").select("*").order("orden"),
        db.from("menu_variantes").select("*").order("orden"),
        db.from("menu_variante_sucursal").select("*").eq("sucursal_id", sucursal.id),
      ]);
      const error = catRes.error || itemRes.error || varRes.error || precioRes.error;
      if (error) throw error;

      const categorias = (catRes.data ?? []) as MenuCategoria[];
      const items = (itemRes.data ?? []) as MenuItem[];
      const variantes = (varRes.data ?? []) as MenuVariante[];
      const precios = (precioRes.data ?? []) as PrecioVarianteSucursal[];

      const precioPorVariante = new Map<string, PrecioVarianteSucursal>();
      for (const p of precios) precioPorVariante.set(p.variante_id, p);

      const variantesPorItem = new Map<string, VarianteConPrecio[]>();
      for (const v of variantes) {
        const precio = precioPorVariante.get(v.id);
        if (!precio || !precio.disponible) continue; // agotado o no se vende aquí
        const lista = variantesPorItem.get(v.item_id) ?? [];
        lista.push({ ...v, precio: Number(precio.precio), disponible: precio.disponible });
        variantesPorItem.set(v.item_id, lista);
      }

      return categorias
        .map((cat) => {
          const itemsCat = items
            .filter((i) => i.categoria_id === cat.id)
            .filter((i) => !i.es_alcohol || sucursal.venta_alcohol_en_linea)
            .map((i) => {
              const vs = variantesPorItem.get(i.id) ?? [];
              const preciosVs = vs.map((v) => v.precio);
              return {
                ...i,
                variantes: vs,
                precioMin: Math.min(...preciosVs),
                precioMax: Math.max(...preciosVs),
              };
            })
            .filter((i) => i.variantes.length > 0);
          return { ...cat, items: itemsCat };
        })
        .filter((cat) => cat.items.length > 0);
    },
    refetchInterval: 60_000, // "agotado" se refleja sin recargar
  });
}

/** Zonas de reparto activas de una sucursal (checkout público). */
export function useZonasReparto(sucursalId: string | null) {
  return useQuery({
    queryKey: ["zonas-reparto", sucursalId],
    enabled: !!sucursalId,
    queryFn: async (): Promise<ZonaReparto[]> => {
      const { data, error } = await db
        .from("zonas_reparto")
        .select("*")
        .eq("sucursal_id", sucursalId)
        .eq("activa", true)
        .order("nombre");
      if (error) throw error;
      return (data ?? []) as ZonaReparto[];
    },
  });
}
