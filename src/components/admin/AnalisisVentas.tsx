import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart, Pie, Cell, Legend } from "recharts";
import { TrendingUp, CreditCard, Banknote, DollarSign } from "lucide-react";

import { TrendChart } from "./TrendChart";
import { ComparativoCard } from "./ComparativoCard";
import { Totales, DatosDiarios } from "@/hooks/useCortes";
import { TipoPeriodo } from "@/hooks/usePeriodo";

const COLORS = ["#0088FE", "#00C49F", "#FFBB28", "#FF8042"];

interface AnalisisVentasProps {
  totales: Totales;
  totalesAnterior: Totales;
  datosTendencia: DatosDiarios[];
  dataPorSucursal: { nombre: string; total: number }[];
  tipoPeriodo: TipoPeriodo;
  formatMoney: (value: number) => string;
}

export function AnalisisVentas({
  totales,
  totalesAnterior,
  datosTendencia,
  dataPorSucursal,
  tipoPeriodo,
  formatMoney,
}: AnalisisVentasProps) {
  const dataPie = [
    { name: "Tarjetas", value: totales.tarjetas },
    { name: "Efectivo", value: totales.efectivo },
  ];

  return (
    <div className="space-y-6">
      {/* Tarjetas de resumen con comparativos */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <ComparativoCard
          titulo="Corte X"
          valor={totales.corte_x}
          valorAnterior={totalesAnterior.corte_x}
          formatMoney={formatMoney}
          icon={DollarSign}
        />
        <ComparativoCard
          titulo="Tarjetas"
          valor={totales.tarjetas}
          valorAnterior={totalesAnterior.tarjetas}
          formatMoney={formatMoney}
          icon={CreditCard}
          iconColor="text-blue-500/30"
        />
        <ComparativoCard
          titulo="Efectivo"
          valor={totales.efectivo}
          valorAnterior={totalesAnterior.efectivo}
          formatMoney={formatMoney}
          icon={Banknote}
          iconColor="text-green-500/30"
        />
        <ComparativoCard
          titulo="Total General"
          valor={totales.total}
          valorAnterior={totalesAnterior.total}
          formatMoney={formatMoney}
          icon={TrendingUp}
          destacado
        />
      </div>

      {/* Gráfica de tendencia (solo para rangos mayores a un día) */}
      <TrendChart
        datos={datosTendencia}
        tipoPeriodo={tipoPeriodo}
        formatMoney={formatMoney}
      />

      {/* Gráficas */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <Card>
          <CardHeader>
            <CardTitle>Ventas por Sucursal</CardTitle>
            <CardDescription>Total del período por cada sucursal (solo cierres)</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="h-[300px]">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={dataPorSucursal}>
                  <CartesianGrid strokeDasharray="3 3" className="stroke-muted" />
                  <XAxis dataKey="nombre" tick={{ fontSize: 12 }} />
                  <YAxis tickFormatter={(value) => `$${(value / 1000).toFixed(0)}k`} />
                  <Tooltip formatter={(value: number) => formatMoney(value)} />
                  <Bar dataKey="total" fill="hsl(var(--primary))" radius={[4, 4, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            </div>
            {/* Desglose porcentual por sucursal */}
            {totales.total > 0 && (
              <div className="mt-4 pt-4 border-t">
                <p className="text-sm font-medium text-muted-foreground mb-2">Participación por sucursal</p>
                <div className="grid grid-cols-2 gap-2">
                  {dataPorSucursal.map((sucursal, index) => {
                    const porcentaje = (sucursal.total / totales.total) * 100;
                    return (
                      <div key={sucursal.nombre} className="flex items-center justify-between text-sm">
                        <div className="flex items-center gap-2">
                          <div 
                            className="w-3 h-3 rounded-full" 
                            style={{ backgroundColor: COLORS[index % COLORS.length] }}
                          />
                          <span>{sucursal.nombre}</span>
                        </div>
                        <span className="font-medium">{porcentaje.toFixed(1)}%</span>
                      </div>
                    );
                  })}
                </div>
              </div>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Distribución de Pagos</CardTitle>
            <CardDescription>Tarjetas vs Efectivo</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="h-[300px]">
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie
                    data={dataPie}
                    cx="50%"
                    cy="50%"
                    labelLine={false}
                    label={({ name, percent }) => `${name}: ${(percent * 100).toFixed(0)}%`}
                    outerRadius={100}
                    fill="#8884d8"
                    dataKey="value"
                  >
                    {dataPie.map((_, index) => (
                      <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                    ))}
                  </Pie>
                  <Tooltip formatter={(value: number) => formatMoney(value)} />
                  <Legend />
                </PieChart>
              </ResponsiveContainer>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
