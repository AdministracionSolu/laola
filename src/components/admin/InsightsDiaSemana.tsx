import { useMemo } from "react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { TrendingUp, TrendingDown, Calendar, Store } from "lucide-react";
import { Corte } from "@/hooks/useCortes";
import { parseISO, getDay } from "date-fns";

const DIAS_SEMANA = ["Domingo", "Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado"];

interface InsightsDiaSemanaProps {
  cortesCierre: Corte[];
  formatMoney: (value: number) => string;
}

interface VentasPorDia {
  dia: string;
  diaIndex: number;
  total: number;
  conteo: number;
  promedio: number;
}

interface VentasPorDiaSucursal {
  sucursal: string;
  mejorDia: string;
  peorDia: string;
  mejorTotal: number;
  peorTotal: number;
}

export function InsightsDiaSemana({ cortesCierre, formatMoney }: InsightsDiaSemanaProps) {
  const { ventasGlobalesPorDia, mejorDiaGlobal, peorDiaGlobal, ventasPorSucursal } = useMemo(() => {
    // Agrupar ventas por día de la semana (global)
    const porDia: Record<number, { total: number; conteo: number }> = {};
    
    // Agrupar ventas por día de la semana y sucursal
    const porSucursalDia: Record<string, Record<number, { total: number; conteo: number }>> = {};

    for (const corte of cortesCierre) {
      const fecha = parseISO(corte.fecha_venta);
      const diaIndex = getDay(fecha);
      const sucursal = corte.sucursales?.nombre || "Desconocida";

      // Global
      if (!porDia[diaIndex]) {
        porDia[diaIndex] = { total: 0, conteo: 0 };
      }
      porDia[diaIndex].total += Number(corte.total);
      porDia[diaIndex].conteo += 1;

      // Por sucursal
      if (!porSucursalDia[sucursal]) {
        porSucursalDia[sucursal] = {};
      }
      if (!porSucursalDia[sucursal][diaIndex]) {
        porSucursalDia[sucursal][diaIndex] = { total: 0, conteo: 0 };
      }
      porSucursalDia[sucursal][diaIndex].total += Number(corte.total);
      porSucursalDia[sucursal][diaIndex].conteo += 1;
    }

    // Convertir a array con promedios (global)
    const ventasGlobalesPorDia: VentasPorDia[] = Object.entries(porDia).map(([diaIndex, datos]) => ({
      dia: DIAS_SEMANA[Number(diaIndex)],
      diaIndex: Number(diaIndex),
      total: datos.total,
      conteo: datos.conteo,
      promedio: datos.conteo > 0 ? datos.total / datos.conteo : 0,
    })).sort((a, b) => b.promedio - a.promedio);

    // Mejor y peor día global (por promedio)
    const mejorDiaGlobal = ventasGlobalesPorDia[0] || null;
    const peorDiaGlobal = ventasGlobalesPorDia[ventasGlobalesPorDia.length - 1] || null;

    // Mejor y peor día por sucursal
    const ventasPorSucursal: VentasPorDiaSucursal[] = Object.entries(porSucursalDia).map(([sucursal, dias]) => {
      const diasArray = Object.entries(dias).map(([diaIndex, datos]) => ({
        dia: DIAS_SEMANA[Number(diaIndex)],
        promedio: datos.conteo > 0 ? datos.total / datos.conteo : 0,
      })).sort((a, b) => b.promedio - a.promedio);

      const mejor = diasArray[0];
      const peor = diasArray[diasArray.length - 1];

      return {
        sucursal,
        mejorDia: mejor?.dia || "-",
        peorDia: peor?.dia || "-",
        mejorTotal: mejor?.promedio || 0,
        peorTotal: peor?.promedio || 0,
      };
    });

    return { ventasGlobalesPorDia, mejorDiaGlobal, peorDiaGlobal, ventasPorSucursal };
  }, [cortesCierre]);

  if (cortesCierre.length === 0) {
    return null;
  }

  // Necesitamos al menos datos de 2 días diferentes para mostrar insights
  if (ventasGlobalesPorDia.length < 2) {
    return null;
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <Calendar className="w-5 h-5" />
          Análisis por Día de la Semana
        </CardTitle>
        <CardDescription>
          Basado en promedios de venta por día para identificar patrones
        </CardDescription>
      </CardHeader>
      <CardContent className="space-y-6">
        {/* Insights globales */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {mejorDiaGlobal && (
            <div className="p-4 rounded-lg bg-primary/10 border border-primary/20">
              <div className="flex items-center gap-2 mb-2">
                <TrendingUp className="w-5 h-5 text-primary" />
                <span className="font-semibold text-primary">Día más fuerte</span>
              </div>
              <p className="text-2xl font-bold">{mejorDiaGlobal.dia}</p>
              <p className="text-sm text-muted-foreground">
                Promedio: {formatMoney(mejorDiaGlobal.promedio)} ({mejorDiaGlobal.conteo} cierres)
              </p>
            </div>
          )}

          {peorDiaGlobal && (
            <div className="p-4 rounded-lg bg-muted border border-border">
              <div className="flex items-center gap-2 mb-2">
                <TrendingDown className="w-5 h-5 text-muted-foreground" />
                <span className="font-semibold text-muted-foreground">Día más bajo</span>
              </div>
              <p className="text-2xl font-bold">{peorDiaGlobal.dia}</p>
              <p className="text-sm text-muted-foreground">
                Promedio: {formatMoney(peorDiaGlobal.promedio)} ({peorDiaGlobal.conteo} cierres)
              </p>
            </div>
          )}
        </div>

        {/* Ranking de días */}
        <div>
          <h4 className="font-medium mb-3 flex items-center gap-2">
            <Calendar className="w-4 h-4" />
            Ranking de ventas por día
          </h4>
          <div className="space-y-2">
            {ventasGlobalesPorDia.map((dia, index) => {
              const maxPromedio = ventasGlobalesPorDia[0]?.promedio || 1;
              const porcentaje = (dia.promedio / maxPromedio) * 100;
              
              return (
                <div key={dia.dia} className="flex items-center gap-3">
                  <span className="w-6 text-sm text-muted-foreground">#{index + 1}</span>
                  <span className="w-24 font-medium">{dia.dia}</span>
                  <div className="flex-1 h-6 bg-muted rounded-full overflow-hidden">
                    <div 
                      className="h-full bg-primary/70 rounded-full transition-all"
                      style={{ width: `${porcentaje}%` }}
                    />
                  </div>
                  <span className="w-28 text-right text-sm font-medium">
                    {formatMoney(dia.promedio)}
                  </span>
                </div>
              );
            })}
          </div>
        </div>

        {/* Por sucursal */}
        {ventasPorSucursal.length > 1 && (
          <div>
            <h4 className="font-medium mb-3 flex items-center gap-2">
              <Store className="w-4 h-4" />
              Por sucursal
            </h4>
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
              {ventasPorSucursal.map((sucursal) => (
                <div key={sucursal.sucursal} className="p-3 rounded-lg border bg-card">
                  <p className="font-semibold mb-2">{sucursal.sucursal}</p>
                  <div className="space-y-1 text-sm">
                    <div className="flex justify-between">
                      <span className="text-primary">↑ {sucursal.mejorDia}</span>
                      <span className="text-muted-foreground">{formatMoney(sucursal.mejorTotal)}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-muted-foreground">↓ {sucursal.peorDia}</span>
                      <span className="text-muted-foreground">{formatMoney(sucursal.peorTotal)}</span>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Nota de contexto */}
        <p className="text-xs text-muted-foreground italic">
          💡 Estos datos son útiles para decidir días de cierre, promociones o ajustes de personal.
          Los promedios consideran solo días con cierres registrados en el período seleccionado.
        </p>
      </CardContent>
    </Card>
  );
}
