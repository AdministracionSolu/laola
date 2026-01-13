import { useState, useEffect, useCallback, useMemo } from "react";
import { supabase } from "@/integrations/supabase/client";
import { useToast } from "@/hooks/use-toast";
import { RangoFechas } from "./usePeriodo";
import { format, eachDayOfInterval, parseISO, startOfDay, endOfDay } from "date-fns";
import { es } from "date-fns/locale";

export interface Sucursal {
  id: string;
  nombre: string;
}

export interface Corte {
  id: string;
  sucursal_id: string;
  tipo_corte: "momento" | "cierre";
  corte_x: number;
  tarjetas: number;
  efectivo: number;
  cobradas: number;
  por_cobrar: number;
  total: number;
  created_at: string;
  fecha_venta: string;
  sucursales: {
    nombre: string;
  };
  // Campos opcionales para cierre
  pago_proveedores?: number;
  salarios?: number;
  propinas?: number;
  compras?: number;
  pago_servicios?: number;
  // Desglose de tarjetas
  tarjetas_banregio?: number;
  tarjetas_mercadopago?: number;
  tarjetas_haycash?: number;
  // Apps de delivery (solo Solares)
  rappi?: number;
  uber?: number;
}

export interface Totales {
  corte_x: number;
  tarjetas: number;
  efectivo: number;
  cobradas: number;
  por_cobrar: number;
  total: number;
}

export interface DatosDiarios {
  fecha: string;
  fechaFormateada: string;
  total: number;
  tarjetas: number;
  efectivo: number;
}

export interface UseCortesReturn {
  sucursales: Sucursal[];
  cortes: Corte[];
  cortesCierre: Corte[];
  cortesAnterior: Corte[];
  cortesAnteriorCierre: Corte[];
  ultimosCortesHoy: Map<string, Corte>;
  isLoading: boolean;
  totales: Totales;
  totalesAnterior: Totales;
  datosTendencia: DatosDiarios[];
  dataPorSucursal: { nombre: string; total: number }[];
  estadoSucursales: { nombre: string; cerrado: boolean; ultimoCorte: string | null }[];
  refetch: () => void;
  deleteCorte: (corteId: string) => Promise<boolean>;
}

interface UseCortesOptions {
  rango: RangoFechas;
  rangoAnterior: RangoFechas;
  filtroSucursal: string;
  filtroTipo: string;
}

export function useCortes(options: UseCortesOptions): UseCortesReturn {
  const { rango, rangoAnterior, filtroSucursal, filtroTipo } = options;
  const [sucursales, setSucursales] = useState<Sucursal[]>([]);
  const [cortes, setCortes] = useState<Corte[]>([]);
  const [cortesAnterior, setCortesAnterior] = useState<Corte[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const { toast } = useToast();

  const fetchSucursales = useCallback(async () => {
    const { data, error } = await supabase
      .from("sucursales")
      .select("id, nombre")
      .order("nombre");

    if (error) {
      toast({
        title: "Error",
        description: "No se pudieron cargar las sucursales",
        variant: "destructive",
      });
      return;
    }

    setSucursales(data || []);
  }, [toast]);

  const fetchCortes = useCallback(async (rangoFechas: RangoFechas, isAnterior = false) => {
    // Usar fecha_venta para filtrar (día de negocio real, no hora de registro)
    const fechaInicio = format(rangoFechas.inicio, "yyyy-MM-dd");
    const fechaFin = format(rangoFechas.fin, "yyyy-MM-dd");
    
    // Traemos TODOS los cortes (sin filtro de tipo) para poder calcular estado actual
    let query = supabase
      .from("cortes_caja")
      .select("*, sucursales(nombre)")
      .gte("fecha_venta", fechaInicio)
      .lte("fecha_venta", fechaFin)
      .order("fecha_venta", { ascending: false })
      .order("created_at", { ascending: false });

    if (filtroSucursal !== "todas") {
      query = query.eq("sucursal_id", filtroSucursal);
    }

    // NO aplicamos filtro de tipo aquí - lo aplicamos después para tener ambos conjuntos

    const { data, error } = await query;

    if (error) {
      toast({
        title: "Error",
        description: "No se pudieron cargar los cortes",
        variant: "destructive",
      });
      return;
    }

    if (isAnterior) {
      setCortesAnterior(data as Corte[] || []);
    } else {
      setCortes(data as Corte[] || []);
    }
  }, [filtroSucursal, toast]);

  const refetch = useCallback(() => {
    setIsLoading(true);
    Promise.all([
      fetchCortes(rango, false),
      fetchCortes(rangoAnterior, true),
    ]).finally(() => setIsLoading(false));
  }, [fetchCortes, rango, rangoAnterior]);

  const deleteCorte = useCallback(async (corteId: string): Promise<boolean> => {
    const { error } = await supabase
      .from("cortes_caja")
      .delete()
      .eq("id", corteId);

    if (error) {
      toast({
        title: "Error",
        description: "No se pudo eliminar el corte",
        variant: "destructive",
      });
      return false;
    }

    toast({
      title: "Eliminado",
      description: "El corte ha sido eliminado correctamente",
    });
    
    refetch();
    return true;
  }, [toast, refetch]);

  useEffect(() => {
    fetchSucursales().then(() => setIsLoading(false));
  }, [fetchSucursales]);

  useEffect(() => {
    if (sucursales.length > 0) {
      refetch();
    }
  }, [sucursales.length, rango, rangoAnterior, filtroSucursal]);

  // Filtrar cortes según el tipo seleccionado (para mostrar en histórico)
  const cortesFiltrados = useMemo(() => {
    if (filtroTipo === "todos") return cortes;
    return cortes.filter(c => c.tipo_corte === filtroTipo);
  }, [cortes, filtroTipo]);

  // Solo cortes de CIERRE para análisis/totales
  const cortesCierre = useMemo(() => {
    return cortes.filter(c => c.tipo_corte === "cierre");
  }, [cortes]);

  const cortesAnteriorCierre = useMemo(() => {
    return cortesAnterior.filter(c => c.tipo_corte === "cierre");
  }, [cortesAnterior]);

  // Último corte de cada sucursal (para Estado Actual)
  const ultimosCortesHoy = useMemo(() => {
    const map = new Map<string, Corte>();
    
    // Los cortes ya vienen ordenados por fecha_venta desc, created_at desc
    // Así que el primero de cada sucursal es el más reciente
    for (const corte of cortes) {
      if (!map.has(corte.sucursal_id)) {
        map.set(corte.sucursal_id, corte);
      }
    }
    
    return map;
  }, [cortes]);

  const calcularTotales = (cortesArray: Corte[]): Totales => {
    return cortesArray.reduce(
      (acc, corte) => ({
        corte_x: acc.corte_x + Number(corte.corte_x),
        tarjetas: acc.tarjetas + Number(corte.tarjetas),
        efectivo: acc.efectivo + Number(corte.efectivo),
        cobradas: acc.cobradas + Number(corte.cobradas),
        por_cobrar: acc.por_cobrar + Number(corte.por_cobrar),
        total: acc.total + Number(corte.total),
      }),
      { corte_x: 0, tarjetas: 0, efectivo: 0, cobradas: 0, por_cobrar: 0, total: 0 }
    );
  };

  // IMPORTANTE: Los totales ahora solo usan cortes de CIERRE
  const totales = calcularTotales(cortesCierre);
  const totalesAnterior = calcularTotales(cortesAnteriorCierre);

  // Datos de tendencia también solo con cierres
  const datosTendencia: DatosDiarios[] = useMemo(() => {
    const dias = eachDayOfInterval({ start: rango.inicio, end: rango.fin });
    
    return dias.map((dia) => {
      const fechaStr = format(dia, "yyyy-MM-dd");
      // Usar solo cortes de cierre para tendencia
      const cortesDelDia = cortesCierre.filter((c) => {
        return c.fecha_venta === fechaStr;
      });
      
      const totalesDia = calcularTotales(cortesDelDia);
      
      return {
        fecha: fechaStr,
        fechaFormateada: format(dia, "EEE d", { locale: es }),
        total: totalesDia.total,
        tarjetas: totalesDia.tarjetas,
        efectivo: totalesDia.efectivo,
      };
    });
  }, [rango, cortesCierre]);

  // Ventas por sucursal también solo con cierres
  const dataPorSucursal = useMemo(() => {
    return sucursales.map((sucursal) => {
      const cortesDeEsta = cortesCierre.filter((c) => c.sucursal_id === sucursal.id);
      const totalSucursal = cortesDeEsta.reduce((acc, c) => acc + Number(c.total), 0);
      return {
        nombre: sucursal.nombre,
        total: totalSucursal,
      };
    });
  }, [sucursales, cortesCierre]);

  const estadoSucursales = useMemo(() => {
    return sucursales.map((sucursal) => {
      const cortesHoy = cortes.filter((c) => c.sucursal_id === sucursal.id);
      const corteCierre = cortesHoy.find((c) => c.tipo_corte === "cierre");
      
      return {
        nombre: sucursal.nombre,
        cerrado: !!corteCierre,
        ultimoCorte: cortesHoy.length > 0 
          ? format(parseISO(cortesHoy[0].created_at), "HH:mm")
          : null,
      };
    });
  }, [sucursales, cortes]);

  return {
    sucursales,
    cortes: cortesFiltrados,
    cortesCierre,
    cortesAnterior,
    cortesAnteriorCierre,
    ultimosCortesHoy,
    isLoading,
    totales,
    totalesAnterior,
    datosTendencia,
    dataPorSucursal,
    estadoSucursales,
    refetch,
    deleteCorte,
  };
}
