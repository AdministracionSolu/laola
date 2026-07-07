import { useState, useEffect, useCallback, useMemo } from "react";
import { supabase } from "@/integrations/supabase/client";
import { useToast } from "@/hooks/use-toast";
import { format, subDays, addDays, isSameDay, isAfter } from "date-fns";

/**
 * Apertura de caja: "¿con cuánto amanecimos?"
 *
 * El Corte X de un cierre = efectivo que queda físicamente en la caja a la hora
 * de cerrar. Ese efectivo es con el que la sucursal "amanece" al día siguiente.
 *
 * Día de negocio: la BD ya asigna los cierres de madrugada (antes de las 4 AM)
 * al día anterior vía trigger. Aquí solo consultamos por `fecha_venta`, que ya
 * viene con esa lógica aplicada, así que un cierre a las 2 AM del 6 de julio
 * cuenta como del 5 de julio automáticamente.
 */

export interface AperturaSucursal {
  sucursal_id: string;
  nombre: string;
  plaza: string;
  reportado: boolean;
  corte_x: number | null;
  total: number | null;
  efectivo: number | null;
  tarjetas: number | null;
  hora_cierre: string | null; // created_at del cierre (hora real de registro)
}

export interface AperturaPlaza {
  plaza: string;
  sucursales: AperturaSucursal[];
  totalCaja: number;
  totalVendido: number;
  reportadas: number;
  sinReporte: number;
}

/**
 * Plaza (ciudad) de cada sucursal. La operación no es la misma por ciudad:
 * en Guadalajara no disponemos del efectivo (lo usan allá para otras cosas),
 * pero sí queremos verlo por separado para saber cuánto usa cada plaza.
 *
 * Tepic: Cervecería, Del Valle, Las Brisas. Todo lo demás cae en Guadalajara.
 */
const TEPIC = new Set(["cerveceria", "del valle", "las brisas"]);

function normaliza(s: string): string {
  return s
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "") // quita acentos
    .trim();
}

function plazaDeSucursal(nombre: string): string {
  return TEPIC.has(normaliza(nombre)) ? "Tepic" : "Guadalajara";
}

// Orden en que se muestran las plazas (las conocidas primero).
const ORDEN_PLAZAS = ["Tepic", "Guadalajara"];

// El día de negocio "rueda" a las 4 AM (igual que el trigger de la BD).
// Antes de las 4 AM seguimos operando el día anterior.
function diaDeNegocioHoy(): Date {
  const ahora = new Date();
  return ahora.getHours() < 4 ? subDays(ahora, 1) : ahora;
}

export interface UseAperturaReturn {
  porSucursal: AperturaSucursal[];
  porPlaza: AperturaPlaza[];
  totalCaja: number;
  totalVendido: number;
  reportadas: number;
  sinReporte: number;
  totalSucursales: number;
  fechaObjetivo: Date;
  esDiaAnterior: boolean;
  puedeAvanzar: boolean;
  isLoading: boolean;
  refetch: () => void;
  irDiaAnterior: () => void;
  irDiaSiguiente: () => void;
  volverADiaAnterior: () => void;
}

export function useApertura(): UseAperturaReturn {
  const { toast } = useToast();
  const [sucursales, setSucursales] = useState<{ id: string; nombre: string }[]>([]);
  const [cierres, setCierres] = useState<any[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  // Por defecto: el cierre del día de negocio anterior (con lo que amanecimos hoy)
  const [fechaObjetivo, setFechaObjetivo] = useState<Date>(() => subDays(diaDeNegocioHoy(), 1));

  const fetchData = useCallback(async () => {
    setIsLoading(true);
    const fechaStr = format(fechaObjetivo, "yyyy-MM-dd");
    const [sucRes, cierreRes] = await Promise.all([
      supabase.from("sucursales").select("id, nombre").order("nombre"),
      supabase
        .from("cortes_caja")
        .select("sucursal_id, corte_x, total, efectivo, tarjetas, created_at")
        .eq("tipo_corte", "cierre")
        .eq("fecha_venta", fechaStr)
        .order("created_at", { ascending: false }),
    ]);

    if (sucRes.error || cierreRes.error) {
      toast({
        title: "Error",
        description: "No se pudo cargar la apertura de caja",
        variant: "destructive",
      });
      setIsLoading(false);
      return;
    }

    setSucursales(sucRes.data || []);
    setCierres(cierreRes.data || []);
    setIsLoading(false);
  }, [fechaObjetivo, toast]);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  const porSucursal = useMemo<AperturaSucursal[]>(() => {
    // Si hay más de un cierre por sucursal ese día, tomamos el más reciente
    // (los cortes ya vienen ordenados por created_at desc).
    const map = new Map<string, any>();
    for (const c of cierres) {
      if (!map.has(c.sucursal_id)) map.set(c.sucursal_id, c);
    }

    return sucursales.map((s) => {
      const c = map.get(s.id);
      if (!c) {
        return {
          sucursal_id: s.id,
          nombre: s.nombre,
          plaza: plazaDeSucursal(s.nombre),
          reportado: false,
          corte_x: null,
          total: null,
          efectivo: null,
          tarjetas: null,
          hora_cierre: null,
        };
      }
      return {
        sucursal_id: s.id,
        nombre: s.nombre,
        plaza: plazaDeSucursal(s.nombre),
        reportado: true,
        corte_x: Number(c.corte_x),
        total: Number(c.total),
        efectivo: Number(c.efectivo),
        tarjetas: Number(c.tarjetas),
        hora_cierre: c.created_at,
      };
    });
  }, [sucursales, cierres]);

  // Agrupado por plaza (ciudad). Tepic y Guadalajara operan por separado.
  const porPlaza = useMemo<AperturaPlaza[]>(() => {
    const grupos = new Map<string, AperturaSucursal[]>();
    for (const s of porSucursal) {
      const arr = grupos.get(s.plaza) || [];
      arr.push(s);
      grupos.set(s.plaza, arr);
    }
    return Array.from(grupos.entries())
      .map(([plaza, sucs]) => ({
        plaza,
        sucursales: sucs,
        totalCaja: sucs.reduce((acc, s) => acc + (s.corte_x || 0), 0),
        totalVendido: sucs.reduce((acc, s) => acc + (s.total || 0), 0),
        reportadas: sucs.filter((s) => s.reportado).length,
        sinReporte: sucs.filter((s) => !s.reportado).length,
      }))
      .sort((a, b) => {
        // Plazas conocidas primero en su orden; el resto alfabético al final.
        const ia = ORDEN_PLAZAS.indexOf(a.plaza);
        const ib = ORDEN_PLAZAS.indexOf(b.plaza);
        return (ia === -1 ? 99 : ia) - (ib === -1 ? 99 : ib) || a.plaza.localeCompare(b.plaza);
      });
  }, [porSucursal]);

  const totalCaja = useMemo(
    () => porSucursal.reduce((acc, s) => acc + (s.corte_x || 0), 0),
    [porSucursal]
  );
  const totalVendido = useMemo(
    () => porSucursal.reduce((acc, s) => acc + (s.total || 0), 0),
    [porSucursal]
  );
  const reportadas = porSucursal.filter((s) => s.reportado).length;
  const sinReporte = porSucursal.filter((s) => !s.reportado).length;

  const esDiaAnterior = isSameDay(fechaObjetivo, subDays(diaDeNegocioHoy(), 1));
  // No dejamos avanzar más allá del día de negocio actual
  const puedeAvanzar = !isSameDay(fechaObjetivo, diaDeNegocioHoy()) && !isAfter(fechaObjetivo, diaDeNegocioHoy());

  const irDiaAnterior = () => setFechaObjetivo((d) => subDays(d, 1));
  const irDiaSiguiente = () =>
    setFechaObjetivo((d) => (isSameDay(d, diaDeNegocioHoy()) ? d : addDays(d, 1)));
  const volverADiaAnterior = () => setFechaObjetivo(subDays(diaDeNegocioHoy(), 1));

  return {
    porSucursal,
    porPlaza,
    totalCaja,
    totalVendido,
    reportadas,
    sinReporte,
    totalSucursales: sucursales.length,
    fechaObjetivo,
    esDiaAnterior,
    puedeAvanzar,
    isLoading,
    refetch: fetchData,
    irDiaAnterior,
    irDiaSiguiente,
    volverADiaAnterior,
  };
}
