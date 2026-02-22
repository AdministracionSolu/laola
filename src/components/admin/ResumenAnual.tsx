import { useState, useEffect, useMemo } from "react";
import { endOfMonth, parseISO, getDay, format } from "date-fns";
import { es } from "date-fns/locale";
import { supabase } from "@/integrations/supabase/client";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, LineChart, Line, Legend, PieChart, Pie, Cell,
} from "recharts";
import {
  CalendarDays, TrendingUp, TrendingDown, Trophy, Store, Flame, Snowflake, Loader2, Eye, BarChart3, Lightbulb, ArrowUpRight, ArrowDownRight, Minus,
} from "lucide-react";
import { ResumenComparativo } from "./ResumenComparativo";
import { ResumenPatrones } from "./ResumenPatrones";

export const MESES = ["Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"];
export const MESES_CORTO = ["Ene", "Feb", "Mar", "Abr", "May", "Jun", "Jul", "Ago", "Sep", "Oct", "Nov", "Dic"];
export const DIAS_SEMANA = ["Domingo", "Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado"];

export const COLORS_SUCURSAL: Record<string, string> = {
  "Del Valle": "hsl(210, 70%, 55%)",
  "Las Brisas": "hsl(150, 60%, 45%)",
  "Cervecería": "hsl(35, 80%, 50%)",
  "Solares": "hsl(280, 50%, 55%)",
};

const COLORS_YEAR: Record<number, string> = {
  2021: "hsl(0, 60%, 55%)",
  2022: "hsl(30, 70%, 50%)",
  2023: "hsl(60, 60%, 45%)",
  2024: "hsl(210, 70%, 55%)",
  2025: "hsl(150, 60%, 45%)",
  2026: "hsl(280, 50%, 55%)",
};

export interface CorteRow {
  fecha_venta: string;
  sucursal_id: string;
  efectivo: number;
  tarjetas: number;
  total: number;
  sucursales: { nombre: string };
}

export interface YearSummary {
  year: number;
  total: number;
  efectivo: number;
  tarjetas: number;
  dias: number;
  pctTarjetas: number;
  promedioDia: number;
  porMes: { mes: number; total: number; efectivo: number; tarjetas: number; dias: number }[];
  porSucursal: Record<string, number>;
}

export const formatMoney = (v: number) =>
  new Intl.NumberFormat("es-MX", { style: "currency", currency: "MXN" }).format(v);

export const formatMoneyShort = (v: number) => {
  if (v >= 1_000_000) return `$${(v / 1_000_000).toFixed(1)}M`;
  if (v >= 1_000) return `$${(v / 1_000).toFixed(0)}k`;
  return `$${v.toFixed(0)}`;
};

export const formatFecha = (f: string) => {
  try { return format(parseISO(f), "EEEE d 'de' MMMM yyyy", { locale: es }); } catch { return f; }
};
export const formatFechaCorta = (f: string) => {
  try { return format(parseISO(f), "d MMM yy", { locale: es }); } catch { return f; }
};

export function ResumenAnual() {
  const [cortes, setCortes] = useState<CorteRow[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [selectedYear, setSelectedYear] = useState<number | "global">("global");

  // Fetch ALL data across all years
  useEffect(() => {
    const fetchAll = async () => {
      setIsLoading(true);
      // First get date range
      const { data: rangeData } = await supabase
        .from("cortes_caja")
        .select("fecha_venta")
        .eq("tipo_corte", "cierre")
        .order("fecha_venta", { ascending: true })
        .limit(1);
      const { data: rangeEnd } = await supabase
        .from("cortes_caja")
        .select("fecha_venta")
        .eq("tipo_corte", "cierre")
        .order("fecha_venta", { ascending: false })
        .limit(1);

      if (!rangeData?.length || !rangeEnd?.length) {
        setIsLoading(false);
        return;
      }

      const startYear = parseInt(rangeData[0].fecha_venta.split("-")[0]);
      const endYear = parseInt(rangeEnd[0].fecha_venta.split("-")[0]);

      const allCortes: CorteRow[] = [];
      for (let y = startYear; y <= endYear; y++) {
        for (let m = 0; m < 12; m++) {
          const desde = `${y}-${String(m + 1).padStart(2, "0")}-01`;
          const lastDay = endOfMonth(new Date(y, m)).getDate();
          const hasta = `${y}-${String(m + 1).padStart(2, "0")}-${String(lastDay).padStart(2, "0")}`;
          const { data } = await supabase
            .from("cortes_caja")
            .select("fecha_venta, sucursal_id, efectivo, tarjetas, total, sucursales(nombre)")
            .eq("tipo_corte", "cierre")
            .gte("fecha_venta", desde)
            .lte("fecha_venta", hasta)
            .order("fecha_venta");
          if (data?.length) allCortes.push(...(data as CorteRow[]));
        }
      }
      setCortes(allCortes);
      setIsLoading(false);
    };
    fetchAll();
  }, []);

  // Available years
  const availableYears = useMemo(() => {
    const years = [...new Set(cortes.map(c => parseInt(c.fecha_venta.split("-")[0])))].sort();
    return years;
  }, [cortes]);

  // All branch names
  const sucursalNames = useMemo(() =>
    [...new Set(cortes.map(c => c.sucursales?.nombre || ""))].filter(Boolean).sort()
  , [cortes]);

  // Per-year summaries
  const yearSummaries = useMemo<YearSummary[]>(() => {
    return availableYears.map(year => {
      const yCortes = cortes.filter(c => c.fecha_venta.startsWith(`${year}-`));
      const total = yCortes.reduce((s, c) => s + Number(c.total), 0);
      const efectivo = yCortes.reduce((s, c) => s + Number(c.efectivo), 0);
      const tarjetas = yCortes.reduce((s, c) => s + Number(c.tarjetas), 0);
      const diasSet = new Set(yCortes.map(c => c.fecha_venta));
      const dias = diasSet.size;

      const porMes: YearSummary["porMes"] = [];
      for (let m = 0; m < 12; m++) {
        const mCortes = yCortes.filter(c => parseInt(c.fecha_venta.split("-")[1]) - 1 === m);
        const mDias = new Set(mCortes.map(c => c.fecha_venta)).size;
        porMes.push({
          mes: m,
          total: mCortes.reduce((s, c) => s + Number(c.total), 0),
          efectivo: mCortes.reduce((s, c) => s + Number(c.efectivo), 0),
          tarjetas: mCortes.reduce((s, c) => s + Number(c.tarjetas), 0),
          dias: mDias,
        });
      }

      const porSucursal: Record<string, number> = {};
      for (const c of yCortes) {
        const suc = c.sucursales?.nombre || "?";
        porSucursal[suc] = (porSucursal[suc] || 0) + Number(c.total);
      }

      return { year, total, efectivo, tarjetas, dias, pctTarjetas: total > 0 ? (tarjetas / total) * 100 : 0, promedioDia: dias > 0 ? total / dias : 0, porMes, porSucursal };
    });
  }, [cortes, availableYears]);

  // Filtered cortes by selected year
  const filteredCortes = useMemo(() => {
    if (selectedYear === "global") return cortes;
    return cortes.filter(c => c.fecha_venta.startsWith(`${selectedYear}-`));
  }, [cortes, selectedYear]);

  // Global totals
  const globalTotal = useMemo(() => cortes.reduce((s, c) => s + Number(c.total), 0), [cortes]);
  const globalDias = useMemo(() => new Set(cortes.map(c => c.fecha_venta)).size, [cortes]);

  if (isLoading) {
    return (
      <div className="flex items-center justify-center py-20">
        <Loader2 className="w-8 h-8 animate-spin text-muted-foreground" />
        <span className="ml-3 text-muted-foreground">Cargando todos los datos históricos...</span>
      </div>
    );
  }

  if (cortes.length === 0) {
    return (
      <Card>
        <CardContent className="pt-6 text-center text-muted-foreground">
          No hay datos de cierre registrados.
        </CardContent>
      </Card>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header global */}
      <Card className="bg-gradient-to-br from-primary/10 to-primary/5 border-primary/20">
        <CardContent className="pt-6">
          <div className="flex flex-col gap-4">
            <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
              <div>
                <p className="text-sm text-muted-foreground font-medium">
                  {selectedYear === "global" ? "Ventas Históricas Totales" : `Ventas ${selectedYear}`}
                </p>
                <p className="text-3xl md:text-4xl font-bold">
                  {formatMoney(selectedYear === "global" ? globalTotal : (yearSummaries.find(y => y.year === selectedYear)?.total || 0))}
                </p>
                <p className="text-sm text-muted-foreground mt-1">
                  {selectedYear === "global"
                    ? `${availableYears[0]}–${availableYears[availableYears.length - 1]} · ${globalDias} días con registro`
                    : `${yearSummaries.find(y => y.year === selectedYear)?.dias || 0} días · Promedio: ${formatMoney(yearSummaries.find(y => y.year === selectedYear)?.promedioDia || 0)}/día`
                  }
                </p>
              </div>
              <div className="flex gap-2 flex-wrap">
                {sucursalNames.map(suc => {
                  const totalSuc = filteredCortes.filter(c => c.sucursales?.nombre === suc).reduce((s, c) => s + Number(c.total), 0);
                  return (
                    <Badge key={suc} variant="outline" className="text-xs py-1 px-2" style={{ borderColor: COLORS_SUCURSAL[suc] }}>
                      {suc}: {formatMoneyShort(totalSuc)}
                    </Badge>
                  );
                })}
              </div>
            </div>
            {/* Year selector */}
            <div className="flex gap-2 flex-wrap">
              <Button
                size="sm"
                variant={selectedYear === "global" ? "default" : "outline"}
                onClick={() => setSelectedYear("global")}
                className="gap-1"
              >
                <Eye className="w-3 h-3" />
                Global
              </Button>
              {availableYears.map(y => (
                <Button
                  key={y}
                  size="sm"
                  variant={selectedYear === y ? "default" : "outline"}
                  onClick={() => setSelectedYear(y)}
                >
                  {y}
                </Button>
              ))}
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Year-over-year quick cards */}
      {selectedYear === "global" && yearSummaries.length > 1 && (
        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-3">
          {yearSummaries.map((ys, i) => {
            const prev = i > 0 ? yearSummaries[i - 1] : null;
            // Compare full years only if both have 300+ days
            const canCompare = prev && prev.dias >= 300 && ys.dias >= 300;
            const growth = canCompare ? ((ys.total - prev.total) / prev.total) * 100 : null;
            return (
              <Card key={ys.year} className="cursor-pointer hover:border-primary/50 transition-colors" onClick={() => setSelectedYear(ys.year)}>
                <CardContent className="pt-4 pb-3 px-4">
                  <p className="text-xs text-muted-foreground">{ys.year}</p>
                  <p className="text-lg font-bold">{formatMoneyShort(ys.total)}</p>
                  <div className="flex items-center gap-1 mt-1">
                    {growth !== null ? (
                      <>
                        {growth > 0 ? <ArrowUpRight className="w-3 h-3 text-emerald-500" /> : growth < 0 ? <ArrowDownRight className="w-3 h-3 text-destructive" /> : <Minus className="w-3 h-3" />}
                        <span className={`text-xs font-medium ${growth > 0 ? "text-emerald-500" : growth < 0 ? "text-destructive" : ""}`}>
                          {growth > 0 ? "+" : ""}{growth.toFixed(1)}%
                        </span>
                      </>
                    ) : (
                      <span className="text-[10px] text-muted-foreground">{ys.dias}d registrados</span>
                    )}
                  </div>
                  <p className="text-[10px] text-muted-foreground mt-1">
                    🏦 {ys.pctTarjetas.toFixed(0)}% tarjetas
                  </p>
                </CardContent>
              </Card>
            );
          })}
        </div>
      )}

      {/* Main tabs */}
      <Tabs defaultValue="comparativo" className="space-y-4">
        <TabsList className="grid w-full grid-cols-3 lg:w-auto lg:inline-grid">
          <TabsTrigger value="comparativo" className="gap-2">
            <BarChart3 className="w-4 h-4" />
            <span className="hidden sm:inline">Comparativo</span>
            <span className="sm:hidden">Años</span>
          </TabsTrigger>
          <TabsTrigger value="patrones" className="gap-2">
            <Lightbulb className="w-4 h-4" />
            <span className="hidden sm:inline">Patrones e Insights</span>
            <span className="sm:hidden">Insights</span>
          </TabsTrigger>
          <TabsTrigger value="detalle" className="gap-2">
            <CalendarDays className="w-4 h-4" />
            <span className="hidden sm:inline">Detalle Mensual</span>
            <span className="sm:hidden">Meses</span>
          </TabsTrigger>
        </TabsList>

        <TabsContent value="comparativo">
          <ResumenComparativo
            yearSummaries={yearSummaries}
            sucursalNames={sucursalNames}
            selectedYear={selectedYear}
          />
        </TabsContent>

        <TabsContent value="patrones">
          <ResumenPatrones
            cortes={filteredCortes}
            allCortes={cortes}
            sucursalNames={sucursalNames}
            yearSummaries={yearSummaries}
            selectedYear={selectedYear}
          />
        </TabsContent>

        <TabsContent value="detalle">
          <DetalleAnual
            cortes={filteredCortes}
            sucursalNames={sucursalNames}
            selectedYear={selectedYear}
            yearSummaries={yearSummaries}
          />
        </TabsContent>
      </Tabs>
    </div>
  );
}

// ── Detalle Mensual (inline sub-component) ──
function DetalleAnual({
  cortes, sucursalNames, selectedYear, yearSummaries,
}: {
  cortes: CorteRow[];
  sucursalNames: string[];
  selectedYear: number | "global";
  yearSummaries: YearSummary[];
}) {
  const [mesDetalle, setMesDetalle] = useState<number | null>(null);

  const datosMensuales = useMemo(() => {
    const meses: Record<number, { total: number; efectivo: number; tarjetas: number; dias: Set<string> }> = {};
    for (let m = 0; m < 12; m++) meses[m] = { total: 0, efectivo: 0, tarjetas: 0, dias: new Set() };
    for (const c of cortes) {
      const m = parseInt(c.fecha_venta.split("-")[1]) - 1;
      meses[m].total += Number(c.total);
      meses[m].efectivo += Number(c.efectivo);
      meses[m].tarjetas += Number(c.tarjetas);
      meses[m].dias.add(c.fecha_venta);
    }
    return Object.entries(meses).map(([m, d]) => ({
      mesIndex: Number(m),
      mes: MESES[Number(m)],
      mesCorto: MESES_CORTO[Number(m)],
      total: d.total,
      dias: d.dias.size,
      promedioDia: d.dias.size > 0 ? d.total / d.dias.size : 0,
    }));
  }, [cortes]);

  const mejorMes = useMemo(() => datosMensuales.filter(m => m.total > 0).reduce((b, m) => m.total > b.total ? m : b, datosMensuales[0]), [datosMensuales]);
  const peorMes = useMemo(() => datosMensuales.filter(m => m.total > 0).reduce((w, m) => m.total < w.total ? m : w, datosMensuales[0]), [datosMensuales]);

  const detalleMes = useMemo(() => {
    if (mesDetalle === null) return null;
    const mesCortes = cortes.filter(c => parseInt(c.fecha_venta.split("-")[1]) - 1 === mesDetalle);
    const byDay: Record<string, Record<string, number>> = {};
    for (const c of mesCortes) {
      if (!byDay[c.fecha_venta]) byDay[c.fecha_venta] = {};
      const suc = c.sucursales?.nombre || "?";
      byDay[c.fecha_venta][suc] = (byDay[c.fecha_venta][suc] || 0) + Number(c.total);
    }
    return Object.entries(byDay)
      .map(([fecha, sucs]) => ({ fecha, ...sucs, total: Object.values(sucs).reduce((s, v) => s + v, 0) }))
      .sort((a, b) => a.fecha.localeCompare(b.fecha));
  }, [cortes, mesDetalle]);

  return (
    <div className="space-y-4">
      <Card>
        <CardHeader className="pb-3">
          <CardTitle className="text-lg flex items-center gap-2">
            <CalendarDays className="w-5 h-5" />
            {selectedYear === "global" ? "Meses (todos los años acumulados)" : `Meses ${selectedYear}`}
          </CardTitle>
          <CardDescription>Toca un mes para ver detalle diario</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-3 sm:grid-cols-4 md:grid-cols-6 gap-2">
            {datosMensuales.map(m => {
              const isBest = m.mesIndex === mejorMes?.mesIndex && m.total > 0;
              const isWorst = m.mesIndex === peorMes?.mesIndex && m.total > 0 && mejorMes?.mesIndex !== peorMes?.mesIndex;
              const isSelected = mesDetalle === m.mesIndex;
              return (
                <Button
                  key={m.mesIndex}
                  variant={isSelected ? "default" : "outline"}
                  className={`h-auto py-3 flex flex-col items-center gap-1 relative ${isBest ? "border-primary ring-1 ring-primary/30" : ""} ${isWorst ? "border-destructive/50" : ""}`}
                  onClick={() => setMesDetalle(isSelected ? null : m.mesIndex)}
                  disabled={m.total === 0}
                >
                  {isBest && <Flame className="w-3 h-3 text-primary absolute top-1 right-1" />}
                  {isWorst && <Snowflake className="w-3 h-3 text-destructive absolute top-1 right-1" />}
                  <span className="font-semibold text-xs">{m.mesCorto}</span>
                  <span className="text-[10px] text-muted-foreground">{formatMoneyShort(m.total)}</span>
                  <span className="text-[10px] text-muted-foreground">{m.dias}d</span>
                </Button>
              );
            })}
          </div>
        </CardContent>
      </Card>

      {mesDetalle !== null && detalleMes && detalleMes.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle className="text-lg">{MESES[mesDetalle]}</CardTitle>
            <CardDescription>
              {formatMoney(datosMensuales[mesDetalle].total)} en {datosMensuales[mesDetalle].dias} días · Promedio: {formatMoney(datosMensuales[mesDetalle].promedioDia)}/día
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="h-[250px] mb-4">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={detalleMes}>
                  <CartesianGrid strokeDasharray="3 3" className="stroke-muted" />
                  <XAxis dataKey="fecha" tickFormatter={f => f.split("-")[2]} tick={{ fontSize: 10 }} />
                  <YAxis tickFormatter={v => formatMoneyShort(v)} tick={{ fontSize: 10 }} />
                  <Tooltip formatter={(value: number, name: string) => [formatMoney(value), name]} labelFormatter={f => formatFechaCorta(f as string)} />
                  <Legend />
                  {sucursalNames.map(suc => (
                    <Bar key={suc} dataKey={suc} stackId="a" fill={COLORS_SUCURSAL[suc] || "hsl(var(--primary))"} />
                  ))}
                </BarChart>
              </ResponsiveContainer>
            </div>
            <Button variant="ghost" size="sm" onClick={() => setMesDetalle(null)}>Cerrar detalle</Button>
          </CardContent>
        </Card>
      )}

      {/* Monthly ranking */}
      <Card>
        <CardHeader>
          <CardTitle className="text-lg">Ranking de Meses</CardTitle>
        </CardHeader>
        <CardContent className="space-y-2">
          {[...datosMensuales].filter(m => m.total > 0).sort((a, b) => b.total - a.total).map((m, idx) => {
            const max = datosMensuales.filter(x => x.total > 0).sort((a, b) => b.total - a.total)[0]?.total || 1;
            const pct = (m.total / max) * 100;
            return (
              <div key={m.mesIndex} className="flex items-center gap-3">
                <span className="w-6 text-sm font-medium text-muted-foreground">
                  {idx === 0 ? <Trophy className="w-4 h-4 text-primary" /> : `#${idx + 1}`}
                </span>
                <span className="w-20 text-sm font-medium">{m.mesCorto}</span>
                <div className="flex-1 h-5 bg-muted rounded-full overflow-hidden">
                  <div className="h-full bg-primary/60 rounded-full" style={{ width: `${pct}%` }} />
                </div>
                <span className="w-28 text-right text-xs font-semibold">{formatMoney(m.total)}</span>
              </div>
            );
          })}
        </CardContent>
      </Card>
    </div>
  );
}
