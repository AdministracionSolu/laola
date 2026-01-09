import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { AlertCircle, CheckCircle2 } from "lucide-react";
import { EstadoActualCard } from "./EstadoActualCard";
import { Corte, Sucursal } from "@/hooks/useCortes";

interface EstadoActualViewProps {
  sucursales: Sucursal[];
  ultimosCortes: Map<string, Corte>;
  formatMoney: (value: number) => string;
}

export function EstadoActualView({ sucursales, ultimosCortes, formatMoney }: EstadoActualViewProps) {
  const sucursalesConReporte = sucursales.filter(s => ultimosCortes.has(s.id));
  const sucursalesSinReporte = sucursales.filter(s => !ultimosCortes.has(s.id));
  
  const totalCierres = Array.from(ultimosCortes.values()).filter(c => c.tipo_corte === "cierre").length;
  const totalMomentos = Array.from(ultimosCortes.values()).filter(c => c.tipo_corte === "momento").length;

  return (
    <div className="space-y-6">
      {/* Resumen rápido */}
      <Card>
        <CardHeader className="pb-3">
          <CardTitle className="text-lg">Estado del Día</CardTitle>
          <CardDescription>Vista rápida del último corte de cada sucursal</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="flex flex-wrap gap-4">
            <div className="flex items-center gap-2">
              <CheckCircle2 className="w-5 h-5 text-green-500" />
              <span className="text-sm">
                <strong>{totalCierres}</strong> cerradas
              </span>
            </div>
            <div className="flex items-center gap-2">
              <AlertCircle className="w-5 h-5 text-amber-500" />
              <span className="text-sm">
                <strong>{totalMomentos}</strong> con corte del momento
              </span>
            </div>
            {sucursalesSinReporte.length > 0 && (
              <div className="flex items-center gap-2">
                <AlertCircle className="w-5 h-5 text-muted-foreground" />
                <span className="text-sm text-muted-foreground">
                  <strong>{sucursalesSinReporte.length}</strong> sin reporte
                </span>
              </div>
            )}
          </div>
        </CardContent>
      </Card>

      {/* Cards de sucursales con reporte */}
      {sucursalesConReporte.length > 0 && (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {sucursalesConReporte.map((sucursal) => {
            const corte = ultimosCortes.get(sucursal.id)!;
            return (
              <EstadoActualCard
                key={sucursal.id}
                estado={{
                  sucursal_id: sucursal.id,
                  nombre: sucursal.nombre,
                  tipo_corte: corte.tipo_corte,
                  corte_x: corte.corte_x,
                  tarjetas: corte.tarjetas,
                  efectivo: corte.efectivo,
                  por_cobrar: corte.por_cobrar,
                  total: corte.total,
                  created_at: corte.created_at,
                  fecha_venta: corte.fecha_venta,
                }}
                formatMoney={formatMoney}
              />
            );
          })}
        </div>
      )}

      {/* Sucursales sin reporte */}
      {sucursalesSinReporte.length > 0 && (
        <Card className="border-dashed">
          <CardHeader className="pb-3">
            <CardTitle className="text-base text-muted-foreground">Sin reporte hoy</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="flex flex-wrap gap-2">
              {sucursalesSinReporte.map((sucursal) => (
                <span
                  key={sucursal.id}
                  className="px-3 py-1 rounded-full bg-muted text-muted-foreground text-sm"
                >
                  {sucursal.nombre}
                </span>
              ))}
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
