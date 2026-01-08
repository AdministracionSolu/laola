import { Button } from "@/components/ui/button";
import { Calendar } from "@/components/ui/calendar";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { TipoPeriodo, RangoFechas } from "@/hooks/usePeriodo";
import { CalendarDays, ChevronDown } from "lucide-react";
import { cn } from "@/lib/utils";
import { useState } from "react";
import { format } from "date-fns";
import { es } from "date-fns/locale";
import { DateRange } from "react-day-picker";

interface PeriodSelectorProps {
  tipoPeriodo: TipoPeriodo;
  onTipoPeriodoChange: (tipo: TipoPeriodo) => void;
  onRangoPersonalizadoChange: (rango: RangoFechas | null) => void;
  etiquetaPeriodo: string;
  formatoFechaRango: string;
}

const OPCIONES_PERIODO: { valor: TipoPeriodo; etiqueta: string }[] = [
  { valor: "hoy", etiqueta: "Hoy" },
  { valor: "ayer", etiqueta: "Ayer" },
  { valor: "esta_semana", etiqueta: "Esta semana" },
  { valor: "semana_pasada", etiqueta: "Sem. pasada" },
  { valor: "este_mes", etiqueta: "Este mes" },
  { valor: "mes_pasado", etiqueta: "Mes pasado" },
];

export function PeriodSelector({
  tipoPeriodo,
  onTipoPeriodoChange,
  onRangoPersonalizadoChange,
  etiquetaPeriodo,
  formatoFechaRango,
}: PeriodSelectorProps) {
  const [rangoCalendario, setRangoCalendario] = useState<DateRange | undefined>();
  const [mostrarCalendario, setMostrarCalendario] = useState(false);

  const handleRangoSeleccionado = (range: DateRange | undefined) => {
    setRangoCalendario(range);
    if (range?.from && range?.to) {
      onRangoPersonalizadoChange({ inicio: range.from, fin: range.to });
      onTipoPeriodoChange("personalizado");
      setMostrarCalendario(false);
    }
  };

  return (
    <div className="space-y-3">
      {/* Pills de período rápido */}
      <div className="flex flex-wrap gap-2">
        {OPCIONES_PERIODO.map((opcion) => (
          <Button
            key={opcion.valor}
            variant={tipoPeriodo === opcion.valor ? "default" : "outline"}
            size="sm"
            onClick={() => onTipoPeriodoChange(opcion.valor)}
            className="h-8"
          >
            {opcion.etiqueta}
          </Button>
        ))}
        
        {/* Botón de rango personalizado */}
        <Popover open={mostrarCalendario} onOpenChange={setMostrarCalendario}>
          <PopoverTrigger asChild>
            <Button
              variant={tipoPeriodo === "personalizado" ? "default" : "outline"}
              size="sm"
              className={cn("h-8 gap-1", tipoPeriodo === "personalizado" && "min-w-[140px]")}
            >
              <CalendarDays className="w-4 h-4" />
              {tipoPeriodo === "personalizado" ? (
                <span className="text-xs">
                  {rangoCalendario?.from && rangoCalendario?.to
                    ? `${format(rangoCalendario.from, "d MMM", { locale: es })} - ${format(rangoCalendario.to, "d MMM", { locale: es })}`
                    : "Personalizado"}
                </span>
              ) : (
                <ChevronDown className="w-3 h-3" />
              )}
            </Button>
          </PopoverTrigger>
          <PopoverContent className="w-auto p-0" align="start">
            <Calendar
              mode="range"
              selected={rangoCalendario}
              onSelect={handleRangoSeleccionado}
              numberOfMonths={2}
              locale={es}
            />
          </PopoverContent>
        </Popover>
      </div>

      {/* Indicador del rango actual */}
      <p className="text-sm text-muted-foreground capitalize">
        {formatoFechaRango}
      </p>
    </div>
  );
}
