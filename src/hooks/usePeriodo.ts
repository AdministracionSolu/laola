import { useState, useMemo } from "react";
import { 
  startOfDay, 
  endOfDay, 
  startOfWeek, 
  endOfWeek, 
  startOfMonth, 
  endOfMonth, 
  subDays, 
  subWeeks, 
  subMonths,
  format
} from "date-fns";
import { es } from "date-fns/locale";

export type TipoPeriodo = 
  | "hoy" 
  | "ayer" 
  | "esta_semana" 
  | "semana_pasada" 
  | "este_mes" 
  | "mes_pasado" 
  | "personalizado";

export interface RangoFechas {
  inicio: Date;
  fin: Date;
}

export interface UsePeriodoReturn {
  tipoPeriodo: TipoPeriodo;
  setTipoPeriodo: (tipo: TipoPeriodo) => void;
  rangoPersonalizado: RangoFechas | null;
  setRangoPersonalizado: (rango: RangoFechas | null) => void;
  rangoActual: RangoFechas;
  rangoAnterior: RangoFechas;
  etiquetaPeriodo: string;
  formatoFechaRango: string;
}

export function usePeriodo(): UsePeriodoReturn {
  const [tipoPeriodo, setTipoPeriodo] = useState<TipoPeriodo>("hoy");
  const [rangoPersonalizado, setRangoPersonalizado] = useState<RangoFechas | null>(null);

  const rangoActual = useMemo((): RangoFechas => {
    const hoy = new Date();
    
    switch (tipoPeriodo) {
      case "hoy":
        return { inicio: startOfDay(hoy), fin: endOfDay(hoy) };
      case "ayer":
        const ayer = subDays(hoy, 1);
        return { inicio: startOfDay(ayer), fin: endOfDay(ayer) };
      case "esta_semana":
        return { 
          inicio: startOfWeek(hoy, { weekStartsOn: 1 }), 
          fin: endOfWeek(hoy, { weekStartsOn: 1 }) 
        };
      case "semana_pasada":
        const semanaAnterior = subWeeks(hoy, 1);
        return { 
          inicio: startOfWeek(semanaAnterior, { weekStartsOn: 1 }), 
          fin: endOfWeek(semanaAnterior, { weekStartsOn: 1 }) 
        };
      case "este_mes":
        return { inicio: startOfMonth(hoy), fin: endOfMonth(hoy) };
      case "mes_pasado":
        const mesAnterior = subMonths(hoy, 1);
        return { inicio: startOfMonth(mesAnterior), fin: endOfMonth(mesAnterior) };
      case "personalizado":
        return rangoPersonalizado || { inicio: startOfDay(hoy), fin: endOfDay(hoy) };
      default:
        return { inicio: startOfDay(hoy), fin: endOfDay(hoy) };
    }
  }, [tipoPeriodo, rangoPersonalizado]);

  const rangoAnterior = useMemo((): RangoFechas => {
    const duracionMs = rangoActual.fin.getTime() - rangoActual.inicio.getTime();
    const inicioAnterior = new Date(rangoActual.inicio.getTime() - duracionMs - 1);
    const finAnterior = new Date(rangoActual.inicio.getTime() - 1);
    
    return { inicio: startOfDay(inicioAnterior), fin: endOfDay(finAnterior) };
  }, [rangoActual]);

  const etiquetaPeriodo = useMemo((): string => {
    switch (tipoPeriodo) {
      case "hoy": return "Hoy";
      case "ayer": return "Ayer";
      case "esta_semana": return "Esta semana";
      case "semana_pasada": return "Semana pasada";
      case "este_mes": return "Este mes";
      case "mes_pasado": return "Mes pasado";
      case "personalizado": return "Personalizado";
      default: return "";
    }
  }, [tipoPeriodo]);

  const formatoFechaRango = useMemo((): string => {
    const { inicio, fin } = rangoActual;
    
    if (tipoPeriodo === "hoy" || tipoPeriodo === "ayer") {
      return format(inicio, "EEEE d 'de' MMMM", { locale: es });
    }
    
    return `${format(inicio, "d MMM", { locale: es })} - ${format(fin, "d MMM yyyy", { locale: es })}`;
  }, [rangoActual, tipoPeriodo]);

  return {
    tipoPeriodo,
    setTipoPeriodo,
    rangoPersonalizado,
    setRangoPersonalizado,
    rangoActual,
    rangoAnterior,
    etiquetaPeriodo,
    formatoFechaRango,
  };
}
