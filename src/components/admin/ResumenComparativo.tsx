import { useMemo } from "react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, LineChart, Line, Legend, AreaChart, Area,
} from "recharts";
import { TrendingUp, TrendingDown, ArrowUpRight, ArrowDownRight, CreditCard, Banknote, BarChart3 } from "lucide-react";
import { YearSummary, MESES_CORTO, COLORS_SUCURSAL, formatMoney, formatMoneyShort } from "./ResumenAnual";

const COLORS_YEAR: Record<number, string> = {
  2021: "hsl(0, 60%, 55%)",
  2022: "hsl(30, 70%, 50%)",
  2023: "hsl(60, 60%, 45%)",
  2024: "hsl(210, 70%, 55%)",
  2025: "hsl(150, 60%, 45%)",
  2026: "hsl(280, 50%, 55%)",
};

interface Props {
  yearSummaries: YearSummary[];
  sucursalNames: string[];
  selectedYear: number | "global";
}

export function ResumenComparativo({ yearSummaries, sucursalNames, selectedYear }: Props) {
  // Monthly comparison data (all years overlayed)
  const monthlyOverlay = useMemo(() => {
    return MESES_CORTO.map((mes, m) => {
      const row: Record<string, number | string> = { mes };
      for (const ys of yearSummaries) {
        const md = ys.porMes[m];
        if (md && md.total > 0) row[`${ys.year}`] = md.total;
      }
      return row;
    });
  }, [yearSummaries]);

  // Payment method evolution
  const paymentEvolution = useMemo(() => {
    return yearSummaries.filter(ys => ys.dias >= 60).map(ys => ({
      year: `${ys.year}`,
      tarjetas: ys.pctTarjetas,
      efectivo: 100 - ys.pctTarjetas,
      totalTarjetas: ys.tarjetas,
      totalEfectivo: ys.efectivo,
    }));
  }, [yearSummaries]);

  // Branch share evolution
  const branchEvolution = useMemo(() => {
    return yearSummaries.filter(ys => ys.dias >= 60).map(ys => {
      const row: Record<string, number | string> = { year: `${ys.year}` };
      for (const suc of sucursalNames) {
        row[suc] = ys.porSucursal[suc] || 0;
      }
      return row;
    });
  }, [yearSummaries, sucursalNames]);

  // YoY growth table
  const yoyData = useMemo(() => {
    return yearSummaries.map((ys, i) => {
      const prev = i > 0 ? yearSummaries[i - 1] : null;
      const canCompare = prev && prev.dias >= 300 && ys.dias >= 300;
      return {
        ...ys,
        growth: canCompare ? ((ys.total - prev!.total) / prev!.total) * 100 : null,
        growthProm: canCompare ? ((ys.promedioDia - prev!.promedioDia) / prev!.promedioDia) * 100 : null,
        diffTarjetas: canCompare ? ys.pctTarjetas - prev!.pctTarjetas : null,
      };
    });
  }, [yearSummaries]);

  return (
    <div className="space-y-6">
      {/* Year comparison table */}
      <Card>
        <CardHeader>
          <CardTitle className="text-lg flex items-center gap-2">
            <BarChart3 className="w-5 h-5" />
            Comparativo Año con Año
          </CardTitle>
          <CardDescription>Evolución de las ventas globales de La Ola</CardDescription>
        </CardHeader>
        <CardContent className="overflow-x-auto">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Año</TableHead>
                <TableHead className="text-right">Total</TableHead>
                <TableHead className="text-right">Prom/Día</TableHead>
                <TableHead className="text-right hidden sm:table-cell">Días</TableHead>
                <TableHead className="text-right hidden md:table-cell">% Tarjetas</TableHead>
                <TableHead className="text-right">Crecimiento</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {yoyData.map(ys => (
                <TableRow key={ys.year}>
                  <TableCell className="font-bold">{ys.year}</TableCell>
                  <TableCell className="text-right font-semibold">{formatMoney(ys.total)}</TableCell>
                  <TableCell className="text-right">{formatMoney(ys.promedioDia)}</TableCell>
                  <TableCell className="text-right hidden sm:table-cell text-muted-foreground">{ys.dias}</TableCell>
                  <TableCell className="text-right hidden md:table-cell">
                    <span className="text-muted-foreground">{ys.pctTarjetas.toFixed(1)}%</span>
                  </TableCell>
                  <TableCell className="text-right">
                    {ys.growth !== null ? (
                      <span className={`flex items-center justify-end gap-1 font-medium ${ys.growth > 0 ? "text-emerald-600" : "text-destructive"}`}>
                        {ys.growth > 0 ? <ArrowUpRight className="w-3 h-3" /> : <ArrowDownRight className="w-3 h-3" />}
                        {ys.growth > 0 ? "+" : ""}{ys.growth.toFixed(1)}%
                      </span>
                    ) : (
                      <span className="text-muted-foreground text-xs">—</span>
                    )}
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </CardContent>
      </Card>

      {/* Monthly overlay chart */}
      <Card>
        <CardHeader>
          <CardTitle className="text-lg">Estacionalidad Mensual por Año</CardTitle>
          <CardDescription>Ventas mensuales superpuestas para comparar patrones</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="h-[300px]">
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={monthlyOverlay}>
                <CartesianGrid strokeDasharray="3 3" className="stroke-muted" />
                <XAxis dataKey="mes" tick={{ fontSize: 11 }} />
                <YAxis tickFormatter={v => formatMoneyShort(v)} tick={{ fontSize: 10 }} />
                <Tooltip formatter={(value: number, name: string) => [formatMoney(value), name]} />
                <Legend />
                {yearSummaries.map(ys => (
                  <Line
                    key={ys.year}
                    type="monotone"
                    dataKey={`${ys.year}`}
                    stroke={COLORS_YEAR[ys.year] || "hsl(var(--primary))"}
                    strokeWidth={ys.year === 2025 ? 3 : 2}
                    dot={{ r: 3 }}
                    strokeDasharray={ys.dias < 300 ? "5 5" : undefined}
                    connectNulls
                  />
                ))}
              </LineChart>
            </ResponsiveContainer>
          </div>
        </CardContent>
      </Card>

      {/* Payment method evolution */}
      <Card>
        <CardHeader>
          <CardTitle className="text-lg flex items-center gap-2">
            <CreditCard className="w-5 h-5" />
            Evolución: Tarjetas vs Efectivo
          </CardTitle>
          <CardDescription>Cómo ha cambiado la forma de pago a lo largo del tiempo</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="h-[250px]">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={paymentEvolution}>
                <CartesianGrid strokeDasharray="3 3" className="stroke-muted" />
                <XAxis dataKey="year" tick={{ fontSize: 11 }} />
                <YAxis tickFormatter={v => `${v}%`} tick={{ fontSize: 10 }} domain={[0, 100]} />
                <Tooltip formatter={(value: number, name: string) => [`${value.toFixed(1)}%`, name === "tarjetas" ? "Tarjetas" : "Efectivo"]} />
                <Legend formatter={(v) => v === "tarjetas" ? "🏦 Tarjetas" : "💵 Efectivo"} />
                <Bar dataKey="tarjetas" stackId="a" fill="hsl(210, 70%, 55%)" />
                <Bar dataKey="efectivo" stackId="a" fill="hsl(140, 50%, 50%)" />
              </BarChart>
            </ResponsiveContainer>
          </div>
          {paymentEvolution.length >= 2 && (
            <div className="mt-4 p-3 rounded-lg bg-muted/50 border border-dashed">
              <p className="text-sm text-muted-foreground">
                💡 <strong>Tendencia:</strong> El uso de tarjetas fue de <strong>{paymentEvolution[0]?.tarjetas.toFixed(1)}%</strong> en {paymentEvolution[0]?.year} y ahora es de <strong>{paymentEvolution[paymentEvolution.length - 1]?.tarjetas.toFixed(1)}%</strong> en {paymentEvolution[paymentEvolution.length - 1]?.year}.
                {Number(paymentEvolution[paymentEvolution.length - 1]?.tarjetas) > Number(paymentEvolution[0]?.tarjetas)
                  ? " Los clientes prefieren cada vez más pagar con tarjeta."
                  : " El efectivo sigue siendo el método preferido."}
              </p>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Branch evolution */}
      <Card>
        <CardHeader>
          <CardTitle className="text-lg flex items-center gap-2">
            <TrendingUp className="w-5 h-5" />
            Evolución por Sucursal
          </CardTitle>
          <CardDescription>Ventas totales por sucursal a lo largo del tiempo</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="h-[300px]">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={branchEvolution}>
                <CartesianGrid strokeDasharray="3 3" className="stroke-muted" />
                <XAxis dataKey="year" tick={{ fontSize: 11 }} />
                <YAxis tickFormatter={v => formatMoneyShort(v)} tick={{ fontSize: 10 }} />
                <Tooltip formatter={(value: number, name: string) => [formatMoney(value), name]} />
                <Legend />
                {sucursalNames.map(suc => (
                  <Bar key={suc} dataKey={suc} fill={COLORS_SUCURSAL[suc] || "hsl(var(--primary))"} />
                ))}
              </BarChart>
            </ResponsiveContainer>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
