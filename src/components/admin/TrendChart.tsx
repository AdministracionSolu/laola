import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { 
  LineChart, 
  Line, 
  XAxis, 
  YAxis, 
  CartesianGrid, 
  Tooltip, 
  ResponsiveContainer,
  Legend 
} from "recharts";
import { DatosDiarios } from "@/hooks/useCortes";
import { TipoPeriodo } from "@/hooks/usePeriodo";

interface TrendChartProps {
  datos: DatosDiarios[];
  tipoPeriodo: TipoPeriodo;
  formatMoney: (value: number) => string;
}

export function TrendChart({ datos, tipoPeriodo, formatMoney }: TrendChartProps) {
  const esRangoCorto = tipoPeriodo === "hoy" || tipoPeriodo === "ayer";

  if (esRangoCorto) {
    return null; // No mostrar tendencia para un solo día
  }

  return (
    <Card className="col-span-full">
      <CardHeader>
        <CardTitle>Tendencia de Ventas</CardTitle>
        <CardDescription>Evolución de ventas en el período seleccionado</CardDescription>
      </CardHeader>
      <CardContent>
        <div className="h-[300px]">
          <ResponsiveContainer width="100%" height="100%">
            <LineChart data={datos}>
              <CartesianGrid strokeDasharray="3 3" className="stroke-muted" />
              <XAxis 
                dataKey="fechaFormateada" 
                tick={{ fontSize: 12 }}
                className="text-muted-foreground"
              />
              <YAxis 
                tickFormatter={(value) => `$${(value / 1000).toFixed(0)}k`}
                tick={{ fontSize: 12 }}
                className="text-muted-foreground"
              />
              <Tooltip 
                formatter={(value: number) => formatMoney(value)}
                labelFormatter={(label) => `Fecha: ${label}`}
                contentStyle={{ 
                  backgroundColor: "hsl(var(--card))",
                  border: "1px solid hsl(var(--border))",
                  borderRadius: "var(--radius)"
                }}
              />
              <Legend />
              <Line 
                type="monotone" 
                dataKey="total" 
                name="Total"
                stroke="hsl(var(--primary))" 
                strokeWidth={3}
                dot={{ fill: "hsl(var(--primary))", strokeWidth: 2, r: 4 }}
                activeDot={{ r: 6 }}
              />
              <Line 
                type="monotone" 
                dataKey="tarjetas" 
                name="Tarjetas"
                stroke="hsl(200, 70%, 50%)" 
                strokeWidth={2}
                dot={{ fill: "hsl(200, 70%, 50%)", strokeWidth: 2, r: 3 }}
              />
              <Line 
                type="monotone" 
                dataKey="efectivo" 
                name="Efectivo"
                stroke="hsl(var(--accent))" 
                strokeWidth={2}
                dot={{ fill: "hsl(var(--accent))", strokeWidth: 2, r: 3 }}
              />
            </LineChart>
          </ResponsiveContainer>
        </div>
      </CardContent>
    </Card>
  );
}
