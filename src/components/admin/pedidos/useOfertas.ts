import { useEffect, useMemo, useState } from "react";
import { supabase } from "@/integrations/supabase/client";
import { claveProducto } from "@/lib/proteinas";

const rpc = (fn: string, args: Record<string, unknown>) =>
  (supabase.rpc as unknown as (f: string, a: Record<string, unknown>) => Promise<{ data: unknown; error: unknown }>)(fn, args);

export interface Oferta {
  insumo_id: string | null;
  proveedor: string;
  producto: string;
  unidad: string;
  precio: number | null;
}

/**
 * Precios vigentes de proveedores agrupados por insumo interno.
 * Empareja por insumo_id cuando el producto está mapeado y, si no,
 * por nombre (claveProducto, igual que la comparativa de proveedores).
 * Cada lista queda ordenada del más barato al más caro.
 */
export function useOfertasPorInsumo(
  insumosOrden: string[],
  nombreInsumo: Map<string, string>,
  pin = ""
) {
  const [ofertas, setOfertas] = useState<Oferta[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    setLoading(true);
    rpc("compras_precios", { p_pin: pin }).then(({ data }) => {
      setOfertas(Array.isArray(data) ? (data as Oferta[]) : []);
      setLoading(false);
    });
  }, [pin]);

  const ofertasPorInsumo = useMemo(() => {
    const porClave = new Map<string, string>();
    insumosOrden.forEach((ins) => {
      const nombre = nombreInsumo.get(ins);
      if (nombre) porClave.set(claveProducto(nombre), ins);
    });
    const m = new Map<string, Oferta[]>();
    ofertas.forEach((o) => {
      if (o.precio == null) return;
      const destino = o.insumo_id ?? porClave.get(claveProducto(o.producto));
      if (!destino) return;
      const arr = m.get(destino) || [];
      arr.push(o);
      m.set(destino, arr);
    });
    m.forEach((arr) => arr.sort((a, b) => a.precio! - b.precio!));
    return m;
  }, [ofertas, insumosOrden, nombreInsumo]);

  return { ofertasPorInsumo, loading };
}
