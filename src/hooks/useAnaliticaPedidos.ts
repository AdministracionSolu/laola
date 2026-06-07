import { useState, useEffect, useCallback } from "react";
import { supabase } from "@/integrations/supabase/client";
import { infoProteina, esProteina } from "@/lib/proteinas";

export interface SucursalLite {
  id: string;
  nombre: string;
}

export interface ListaItem {
  insumo_id: string;
  sucursal_id: string;
  nombre: string;
  categoria_id: string;
  unidad: string;
  nivel_par: number | null;
  costo: number | null;
  orden: number;
  activo: boolean;
}

export interface PedidoLite {
  id: string;
  sucursal_id: string;
  fecha: string;
  estado: string;
  enviado_at: string | null;
}

export interface PedidoDetLite {
  id: string;
  pedido_id: string;
  sucursal_id: string;
  fecha: string;
  insumo_id: string;
  existencia: number;
  cantidad_pedida: number;
  cantidad_sugerida: number | null;
  cantidad_enviada: number | null;
}

export interface RecepcionDetLite {
  sucursal_id: string;
  fecha: string;
  insumo_id: string;
  cantidad_recibida: number;
  pedido_detalle_id: string | null;
}

export interface InsumoMaster {
  id: string;
  nombre: string;
  unidad: string;
}

export interface AnaliticaData {
  sucursales: SucursalLite[];
  lista: ListaItem[];
  insumosMaster: InsumoMaster[];
  pedidos: PedidoLite[];
  pedidosDetalle: PedidoDetLite[];
  recepcionesDetalle: RecepcionDetLite[];
  loading: boolean;
  refetch: () => void;
}

export function useAnaliticaPedidos(desde: string, hasta: string): AnaliticaData {
  const [sucursales, setSucursales] = useState<SucursalLite[]>([]);
  const [lista, setLista] = useState<ListaItem[]>([]);
  const [insumosMaster, setInsumosMaster] = useState<InsumoMaster[]>([]);
  const [pedidos, setPedidos] = useState<PedidoLite[]>([]);
  const [pedidosDetalle, setPedidosDetalle] = useState<PedidoDetLite[]>([]);
  const [recepcionesDetalle, setRecepcionesDetalle] = useState<RecepcionDetLite[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchAll = useCallback(async () => {
    setLoading(true);

    const [sucRes, listaRes, insRes, pedRes, recRes] = await Promise.all([
      supabase.from("sucursales").select("id, nombre").order("nombre"),
      supabase
        .from("insumo_sucursal")
        .select("insumo_id, sucursal_id, nivel_par, costo, unidad, orden, activo, insumos!inner(nombre, categoria_id, unidad)")
        .order("orden"),
      supabase.from("insumos").select("id, nombre, unidad"),
      supabase
        .from("pedidos")
        .select("id, sucursal_id, fecha, estado, enviado_at")
        .gte("fecha", desde)
        .lte("fecha", hasta),
      supabase
        .from("recepciones")
        .select("id, sucursal_id, fecha")
        .gte("fecha", desde)
        .lte("fecha", hasta),
    ]);

    const sucs = (sucRes.data || []) as SucursalLite[];
    setSucursales(sucs);

    // IDs de proteínas (lista oficial). Todo lo demás se ignora en la analítica.
    const insRows = (insRes.data ?? []) as { id: string; nombre: string; unidad: string | null }[];
    const proteinIds = new Set(insRows.filter((r) => esProteina(r.nombre)).map((r) => r.id));

    setInsumosMaster(
      insRows
        .map((r) => {
          const p = infoProteina(r.nombre);
          if (!p) return null;
          return { id: r.id, nombre: p.display, unidad: p.unidad || r.unidad || "pz" } as InsumoMaster;
        })
        .filter((x): x is InsumoMaster => x !== null)
    );

    type ListaRow = {
      insumo_id: string;
      sucursal_id: string;
      nivel_par: number | null;
      costo: number | null;
      unidad: string | null;
      orden: number;
      activo: boolean;
      insumos: { nombre: string; categoria_id: string; unidad: string | null };
    };
    setLista(
      ((listaRes.data ?? []) as unknown as ListaRow[])
        // Solo proteínas de la lista oficial (oculta el resto del catálogo).
        .map((r) => {
          const p = infoProteina(r.insumos.nombre);
          if (!p) return null;
          return {
            insumo_id: r.insumo_id,
            sucursal_id: r.sucursal_id,
            nombre: p.display,
            categoria_id: r.insumos.categoria_id,
            unidad: r.unidad || p.unidad || r.insumos.unidad || "pz",
            nivel_par: r.nivel_par,
            costo: r.costo,
            orden: p.orden,
            activo: r.activo,
          } as ListaItem;
        })
        .filter((x): x is ListaItem => x !== null)
    );

    const peds = (pedRes.data || []) as PedidoLite[];
    setPedidos(peds);

    const pedFecha = new Map(peds.map((p) => [p.id, p]));
    const pedIds = peds.map((p) => p.id);

    let pedDet: PedidoDetLite[] = [];
    if (pedIds.length > 0) {
      const { data } = await supabase
        .from("pedidos_detalle")
        .select("id, pedido_id, insumo_id, existencia, cantidad_pedida, cantidad_sugerida, cantidad_enviada")
        .in("pedido_id", pedIds);
      type PDRow = {
        id: string;
        pedido_id: string;
        insumo_id: string;
        existencia: number | null;
        cantidad_pedida: number;
        cantidad_sugerida: number | null;
        cantidad_enviada: number | null;
      };
      pedDet = ((data ?? []) as PDRow[]).filter((d) => proteinIds.has(d.insumo_id)).map((d) => {
        const p = pedFecha.get(d.pedido_id);
        return {
          id: d.id,
          pedido_id: d.pedido_id,
          sucursal_id: p?.sucursal_id || "",
          fecha: p?.fecha || "",
          insumo_id: d.insumo_id,
          existencia: Number(d.existencia) || 0,
          cantidad_pedida: Number(d.cantidad_pedida) || 0,
          cantidad_sugerida:
            d.cantidad_sugerida === null ? null : Number(d.cantidad_sugerida),
          cantidad_enviada:
            d.cantidad_enviada === null || d.cantidad_enviada === undefined
              ? null
              : Number(d.cantidad_enviada),
        };
      });
    }
    setPedidosDetalle(pedDet);

    const recs = (recRes.data || []) as { id: string; sucursal_id: string; fecha: string }[];
    const recFecha = new Map(recs.map((r) => [r.id, r]));
    const recIds = recs.map((r) => r.id);

    let recDet: RecepcionDetLite[] = [];
    if (recIds.length > 0) {
      const { data } = await supabase
        .from("recepciones_detalle")
        .select("recepcion_id, insumo_id, cantidad_recibida, pedido_detalle_id")
        .in("recepcion_id", recIds);
      type RDRow = {
        recepcion_id: string;
        insumo_id: string;
        cantidad_recibida: number;
        pedido_detalle_id: string | null;
      };
      recDet = ((data ?? []) as RDRow[]).filter((d) => proteinIds.has(d.insumo_id)).map((d) => {
        const r = recFecha.get(d.recepcion_id);
        return {
          sucursal_id: r?.sucursal_id || "",
          fecha: r?.fecha || "",
          insumo_id: d.insumo_id,
          cantidad_recibida: Number(d.cantidad_recibida) || 0,
          pedido_detalle_id: d.pedido_detalle_id,
        };
      });
    }
    setRecepcionesDetalle(recDet);

    setLoading(false);
  }, [desde, hasta]);

  useEffect(() => {
    fetchAll();
  }, [fetchAll]);

  return {
    sucursales,
    lista,
    insumosMaster,
    pedidos,
    pedidosDetalle,
    recepcionesDetalle,
    loading,
    refetch: fetchAll,
  };
}
