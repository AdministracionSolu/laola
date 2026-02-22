import { useState, useEffect, useMemo } from "react";
import { endOfMonth } from "date-fns";
import { supabase } from "@/integrations/supabase/client";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, LineChart, Line, Legend,
} from "recharts";
import {
  CalendarDays, TrendingUp, TrendingDown, Trophy, AlertTriangle, Store, Flame, Snowflake, ArrowUp, ArrowDown, Loader2,
} from "lucide-react";
import { format, parseISO, getDay } from "date-fns";
import { es } from "date-fns/locale";

const MESES = [
  "Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio",
  "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre",
];

const DIAS_SEMANA = ["Domingo", "Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado"];

const COLORS_SUCURSAL: Record<string, string> = {
  "Del Valle": "hsl(210, 70%, 55%)",
  "Las Brisas": "hsl(150, 60%, 45%)",
  "Cervecería": "hsl(35, 80%, 50%)",
  "Solares": "hsl(280, 50%, 55%)",
};

interface CorteRow {
  fecha_venta: string;
  sucursal_id: string;
  efectivo: number;
  tarjetas: number;
  total: number;
  sucursales: { nombre: string };
}

const formatMoney = (v: number) =>
  new Intl.NumberFormat("es-MX", { style: "currency", currency: "MXN" }).format(v);

const formatMoneyShort = (v: number) => {
  if (v >= 1_000_000) return `$${(v / 1_000_000).toFixed(1)}M`;
  if (v >= 1_000) return `$${(v / 1_000).toFixed(0)}k`;
  return `$${v.toFixed(0)}`;
};

export function ResumenAnual() {
  const [cortes, setCortes] = useState<CorteRow[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [mesDetalle, setMesDetalle] = useState<number | null>(null);
  const [year] = useState(2025);

  useEffect(() => {
    const fetchAll = async () => {
      setIsLoading(true);
      // Fetch in chunks to avoid 1000-row limit
      const allCortes: CorteRow[] = [];
      for (let m = 0; m < 12; m++) {
        const desde = `${year}-${String(m + 1).padStart(2, "0")}-01`;
        const lastDay = endOfMonth(new Date(year, m)).getDate();
        const hasta = `${year}-${String(m + 1).padStart(2, "0")}-${String(lastDay).padStart(2, "0")}`;
        const { data } = await supabase
          .from("cortes_caja")
          .select("fecha_venta, sucursal_id, efectivo, tarjetas, total, sucursales(nombre)")
          .eq("tipo_corte", "cierre")
          .gte("fecha_venta", desde)
          .lte("fecha_venta", hasta)
          .order("fecha_venta");
        if (data) allCortes.push(...(data as CorteRow[]));
      }
      setCortes(allCortes);
      setIsLoading(false);
    };
    fetchAll();
  }, [year]);

  // ── Computed data ──
  const sucursalNames = useMemo(() => {
    return [...new Set(cortes.map((c) => c.sucursales?.nombre || ""))].filter(Boolean).sort();
  }, [cortes]);

  // Monthly aggregates
  const datosMensuales = useMemo(() => {
    const meses: Record<number, { total: number; efectivo: number; tarjetas: number; dias: Set<string>; porSucursal: Record<string, number> }> = {};
    for (let m = 0; m < 12; m++) {
      meses[m] = { total: 0, efectivo: 0, tarjetas: 0, dias: new Set(), porSucursal: {} };
    }
    for (const c of cortes) {
      const m = parseInt(c.fecha_venta.split("-")[1]) - 1;
      meses[m].total += Number(c.total);
      meses[m].efectivo += Number(c.efectivo);
      meses[m].tarjetas += Number(c.tarjetas);
      meses[m].dias.add(c.fecha_venta);
      const suc = c.sucursales?.nombre || "?";
      meses[m].porSucursal[suc] = (meses[m].porSucursal[suc] || 0) + Number(c.total);
    }
    return Object.entries(meses).map(([m, d]) => ({
      mesIndex: Number(m),
      mes: MESES[Number(m)],
      mesCorto: MESES[Number(m)].substring(0, 3),
      total: d.total,
      efectivo: d.efectivo,
      tarjetas: d.tarjetas,
      dias: d.dias.size,
      promedioDia: d.dias.size > 0 ? d.total / d.dias.size : 0,
      porSucursal: d.porSucursal,
    }));
  }, [cortes]);

  const mejorMes = useMemo(() => datosMensuales.reduce((best, m) => (m.total > best.total ? m : best), datosMensuales[0]), [datosMensuales]);
  const peorMes = useMemo(() => datosMensuales.filter(m => m.total > 0).reduce((worst, m) => (m.total < worst.total ? m : worst), datosMensuales[0]), [datosMensuales]);

  // Best/worst individual day
  const diasAgrupados = useMemo(() => {
    const byDay: Record<string, { total: number; porSucursal: Record<string, number> }> = {};
    for (const c of cortes) {
      if (!byDay[c.fecha_venta]) byDay[c.fecha_venta] = { total: 0, porSucursal: {} };
      byDay[c.fecha_venta].total += Number(c.total);
      const suc = c.sucursales?.nombre || "?";
      byDay[c.fecha_venta].porSucursal[suc] = (byDay[c.fecha_venta].porSucursal[suc] || 0) + Number(c.total);
    }
    return Object.entries(byDay)
      .map(([fecha, d]) => ({ fecha, ...d }))
      .sort((a, b) => b.total - a.total);
  }, [cortes]);

  const mejorDia = diasAgrupados[0];
  const peorDia = diasAgrupados[diasAgrupados.length - 1];

  // Best/worst day per branch
  const mejorPeorPorSucursal = useMemo(() => {
    const bySucDia: Record<string, { fecha: string; total: number }[]> = {};
    for (const c of cortes) {
      const suc = c.sucursales?.nombre || "?";
      if (!bySucDia[suc]) bySucDia[suc] = [];
      const existing = bySucDia[suc].find((d) => d.fecha === c.fecha_venta);
      if (existing) {
        existing.total += Number(c.total);
      } else {
        bySucDia[suc].push({ fecha: c.fecha_venta, total: Number(c.total) });
      }
    }
    return Object.entries(bySucDia).map(([suc, dias]) => {
      const sorted = [...dias].sort((a, b) => b.total - a.total);
      return {
        sucursal: suc,
        mejor: sorted[0],
        peor: sorted[sorted.length - 1],
      };
    });
  }, [cortes]);

  // Day of week insights
  const insightsDiaSemana = useMemo(() => {
    const byDow: Record<number, { total: number; count: number }> = {};
    const byDate: Record<string, number> = {};
    for (const c of cortes) {
      if (!byDate[c.fecha_venta]) byDate[c.fecha_venta] = 0;
      byDate[c.fecha_venta] += Number(c.total);
    }
    for (const [fecha, total] of Object.entries(byDate)) {
      const dow = getDay(parseISO(fecha));
      if (!byDow[dow]) byDow[dow] = { total: 0, count: 0 };
      byDow[dow].total += total;
      byDow[dow].count += 1;
    }
    return Object.entries(byDow)
      .map(([dow, d]) => ({
        dia: DIAS_SEMANA[Number(dow)],
        dowIndex: Number(dow),
        promedio: d.count > 0 ? d.total / d.count : 0,
        totalDias: d.count,
      }))
      .sort((a, b) => b.promedio - a.promedio);
  }, [cortes]);

  // Total anual
  const totalAnual = useMemo(() => cortes.reduce((s, c) => s + Number(c.total), 0), [cortes]);

  // Datos gráfica mensual por sucursal
  const chartMensualData = useMemo(() => {
    return datosMensuales.map((m) => ({
      mes: m.mesCorto,
      ...m.porSucursal,
      Total: m.total,
    }));
  }, [datosMensuales]);

  // Detail for selected month
  const detalleMes = useMemo(() => {
    if (mesDetalle === null) return null;
    const mesCortes = cortes.filter((c) => parseInt(c.fecha_venta.split("-")[1]) - 1 === mesDetalle);
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

  const formatFecha = (f: string) => {
    try {
      return format(parseISO(f), "EEEE d 'de' MMMM", { locale: es });
    } catch {
      return f;
    }
  };

  const formatFechaCorta = (f: string) => {
    try {
      return format(parseISO(f), "d MMM", { locale: es });
    } catch {
      return f;
    }
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center py-20">
        <Loader2 className="w-8 h-8 animate-spin text-muted-foreground" />
        <span className="ml-3 text-muted-foreground">Cargando datos del {year}...</span>
      </div>
    );
  }

  if (cortes.length === 0) {
    return (
      <Card>
        <CardContent className="pt-6 text-center text-muted-foreground">
          No hay datos de cierre para el año {year}.
        </CardContent>
      </Card>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header with year total */}
      <Card className="bg-gradient-to-br from-primary/10 to-primary/5 border-primary/20">
        <CardContent className="pt-6">
          <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
            <div>
              <p className="text-sm text-muted-foreground font-medium">Total Ventas {year}</p>
              <p className="text-3xl md:text-4xl font-bold">{formatMoney(totalAnual)}</p>
              <p className="text-sm text-muted-foreground mt-1">
                {diasAgrupados.length} días con registro · Promedio diario: {formatMoney(totalAnual / (diasAgrupados.length || 1))}
              </p>
            </div>
            <div className="flex gap-2 flex-wrap">
              {sucursalNames.map((suc) => {
                const totalSuc = cortes.filter((c) => c.sucursales?.nombre === suc).reduce((s, c) => s + Number(c.total), 0);
                return (
                  <Badge key={suc} variant="outline" className="text-xs py-1 px-2">
                    {suc}: {formatMoneyShort(totalSuc)}
                  </Badge>
                );
              })}
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Month buttons */}
      <Card>
        <CardHeader className="pb-3">
          <CardTitle className="text-lg flex items-center gap-2">
            <CalendarDays className="w-5 h-5" />
            Meses {year}
          </CardTitle>
          <CardDescription>Selecciona un mes para ver detalle diario</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-3 sm:grid-cols-4 md:grid-cols-6 gap-2">
            {datosMensuales.map((m) => {
              const isMejor = m.mesIndex === mejorMes?.mesIndex && m.total > 0;
              const isPeor = m.mesIndex === peorMes?.mesIndex && m.total > 0 && mejorMes?.mesIndex !== peorMes?.mesIndex;
              const isSelected = mesDetalle === m.mesIndex;
              return (
                <Button
                  key={m.mesIndex}
                  variant={isSelected ? "default" : "outline"}
                  className={`h-auto py-3 flex flex-col items-center gap-1 relative ${isMejor ? "border-primary ring-1 ring-primary/30" : ""} ${isPeor ? "border-destructive/50" : ""}`}
                  onClick={() => setMesDetalle(isSelected ? null : m.mesIndex)}
                >
                  {isMejor && <Flame className="w-3 h-3 text-primary absolute top-1 right-1" />}
                  {isPeor && <Snowflake className="w-3 h-3 text-destructive absolute top-1 right-1" />}
                  <span className="font-semibold text-xs">{m.mesCorto}</span>
                  <span className="text-[10px] text-muted-foreground">{formatMoneyShort(m.total)}</span>
                  <span className="text-[10px] text-muted-foreground">{m.dias}d</span>
                </Button>
              );
            })}
          </div>
        </CardContent>
      </Card>

      {/* Month detail */}
      {mesDetalle !== null && detalleMes && (
        <Card>
          <CardHeader>
            <CardTitle className="text-lg">{MESES[mesDetalle]} {year}</CardTitle>
            <CardDescription>
              {formatMoney(datosMensuales[mesDetalle].total)} en {datosMensuales[mesDetalle].dias} días
              · Promedio: {formatMoney(datosMensuales[mesDetalle].promedioDia)}/día
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="h-[250px] mb-4">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={detalleMes}>
                  <CartesianGrid strokeDasharray="3 3" className="stroke-muted" />
                  <XAxis dataKey="fecha" tickFormatter={(f) => f.split("-")[2]} tick={{ fontSize: 10 }} />
                  <YAxis tickFormatter={(v) => formatMoneyShort(v)} tick={{ fontSize: 10 }} />
                  <Tooltip
                    formatter={(value: number, name: string) => [formatMoney(value), name]}
                    labelFormatter={(f) => formatFechaCorta(f as string)}
                  />
                  <Legend />
                  {sucursalNames.map((suc) => (
                    <Bar key={suc} dataKey={suc} stackId="a" fill={COLORS_SUCURSAL[suc] || "hsl(var(--primary))"} />
                  ))}
                </BarChart>
              </ResponsiveContainer>
            </div>
            <Button variant="ghost" size="sm" onClick={() => setMesDetalle(null)}>
              Cerrar detalle
            </Button>
          </CardContent>
        </Card>
      )}

      {/* Monthly trend chart */}
      <Card>
        <CardHeader>
          <CardTitle className="text-lg">Tendencia Mensual por Sucursal</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="h-[300px]">
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={chartMensualData}>
                <CartesianGrid strokeDasharray="3 3" className="stroke-muted" />
                <XAxis dataKey="mes" tick={{ fontSize: 11 }} />
                <YAxis tickFormatter={(v) => formatMoneyShort(v)} tick={{ fontSize: 10 }} />
                <Tooltip formatter={(value: number, name: string) => [formatMoney(value), name]} />
                <Legend />
                {sucursalNames.map((suc) => (
                  <Line
                    key={suc}
                    type="monotone"
                    dataKey={suc}
                    stroke={COLORS_SUCURSAL[suc] || "hsl(var(--primary))"}
                    strokeWidth={2}
                    dot={{ r: 3 }}
                  />
                ))}
              </LineChart>
            </ResponsiveContainer>
          </div>
        </CardContent>
      </Card>

      {/* Monthly ranking table */}
      <Card>
        <CardHeader>
          <CardTitle className="text-lg">Ranking de Meses</CardTitle>
          <CardDescription>Ordenado por ventas totales</CardDescription>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead className="w-10">#</TableHead>
                <TableHead>Mes</TableHead>
                <TableHead className="text-right">Total</TableHead>
                <TableHead className="text-right hidden sm:table-cell">Prom/Día</TableHead>
                <TableHead className="text-right hidden md:table-cell">Días</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {[...datosMensuales]
                .filter((m) => m.total > 0)
                .sort((a, b) => b.total - a.total)
                .map((m, idx) => (
                  <TableRow key={m.mesIndex} className={idx === 0 ? "bg-primary/5" : ""}>
                    <TableCell className="font-medium">
                      {idx === 0 ? <Trophy className="w-4 h-4 text-primary" /> : idx + 1}
                    </TableCell>
                    <TableCell className="font-medium">{m.mes}</TableCell>
                    <TableCell className="text-right font-semibold">{formatMoney(m.total)}</TableCell>
                    <TableCell className="text-right hidden sm:table-cell text-muted-foreground">
                      {formatMoney(m.promedioDia)}
                    </TableCell>
                    <TableCell className="text-right hidden md:table-cell text-muted-foreground">{m.dias}</TableCell>
                  </TableRow>
                ))}
            </TableBody>
          </Table>
        </CardContent>
      </Card>

      {/* Best/worst days - Global */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {mejorDia && (
          <Card className="border-primary/30">
            <CardHeader className="pb-2">
              <CardTitle className="text-base flex items-center gap-2 text-primary">
                <TrendingUp className="w-5 h-5" />
                Mejor Día del Año
              </CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-2xl font-bold">{formatMoney(mejorDia.total)}</p>
              <p className="text-sm text-muted-foreground capitalize">{formatFecha(mejorDia.fecha)}</p>
              <div className="mt-2 flex flex-wrap gap-1">
                {Object.entries(mejorDia.porSucursal).map(([suc, val]) => (
                  <Badge key={suc} variant="secondary" className="text-[10px]">
                    {suc}: {formatMoneyShort(val)}
                  </Badge>
                ))}
              </div>
            </CardContent>
          </Card>
        )}
        {peorDia && (
          <Card>
            <CardHeader className="pb-2">
              <CardTitle className="text-base flex items-center gap-2 text-muted-foreground">
                <TrendingDown className="w-5 h-5" />
                Día Más Bajo del Año
              </CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-2xl font-bold">{formatMoney(peorDia.total)}</p>
              <p className="text-sm text-muted-foreground capitalize">{formatFecha(peorDia.fecha)}</p>
              <div className="mt-2 flex flex-wrap gap-1">
                {Object.entries(peorDia.porSucursal).map(([suc, val]) => (
                  <Badge key={suc} variant="outline" className="text-[10px]">
                    {suc}: {formatMoneyShort(val)}
                  </Badge>
                ))}
              </div>
            </CardContent>
          </Card>
        )}
      </div>

      {/* Best/worst day per branch */}
      <Card>
        <CardHeader>
          <CardTitle className="text-lg flex items-center gap-2">
            <Store className="w-5 h-5" />
            Mejor y Peor Día por Sucursal
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            {mejorPeorPorSucursal.map((s) => (
              <div key={s.sucursal} className="p-4 rounded-lg border bg-card space-y-3">
                <p className="font-semibold text-sm">{s.sucursal}</p>
                {s.mejor && (
                  <div className="flex items-start gap-2">
                    <ArrowUp className="w-4 h-4 text-primary mt-0.5 shrink-0" />
                    <div>
                      <p className="text-sm font-medium">{formatMoney(s.mejor.total)}</p>
                      <p className="text-xs text-muted-foreground capitalize">{formatFechaCorta(s.mejor.fecha)}</p>
                    </div>
                  </div>
                )}
                {s.peor && (
                  <div className="flex items-start gap-2">
                    <ArrowDown className="w-4 h-4 text-muted-foreground mt-0.5 shrink-0" />
                    <div>
                      <p className="text-sm font-medium">{formatMoney(s.peor.total)}</p>
                      <p className="text-xs text-muted-foreground capitalize">{formatFechaCorta(s.peor.fecha)}</p>
                    </div>
                  </div>
                )}
              </div>
            ))}
          </div>
        </CardContent>
      </Card>

      {/* Day of week insights */}
      <Card>
        <CardHeader>
          <CardTitle className="text-lg flex items-center gap-2">
            <CalendarDays className="w-5 h-5" />
            Promedio por Día de la Semana ({year})
          </CardTitle>
          <CardDescription>Basado en todos los cierres del año</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="space-y-2">
            {insightsDiaSemana.map((d, idx) => {
              const max = insightsDiaSemana[0]?.promedio || 1;
              const pct = (d.promedio / max) * 100;
              return (
                <div key={d.dia} className="flex items-center gap-3">
                  <span className="w-6 text-sm text-muted-foreground font-medium">#{idx + 1}</span>
                  <span className="w-24 text-sm font-medium">{d.dia}</span>
                  <div className="flex-1 h-6 bg-muted rounded-full overflow-hidden">
                    <div
                      className="h-full bg-primary/70 rounded-full transition-all"
                      style={{ width: `${pct}%` }}
                    />
                  </div>
                  <span className="w-28 text-right text-xs font-medium">{formatMoney(d.promedio)}</span>
                  <span className="w-10 text-right text-[10px] text-muted-foreground">{d.totalDias}d</span>
                </div>
              );
            })}
          </div>
        </CardContent>
      </Card>

      {/* Top 5 / Bottom 5 days */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-base flex items-center gap-2">
              <Flame className="w-4 h-4 text-primary" /> Top 5 Días
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-2">
            {diasAgrupados.slice(0, 5).map((d, i) => (
              <div key={d.fecha} className="flex items-center justify-between text-sm">
                <div className="flex items-center gap-2">
                  <span className="w-5 text-muted-foreground font-medium">{i + 1}.</span>
                  <span className="capitalize">{formatFechaCorta(d.fecha)}</span>
                </div>
                <span className="font-semibold">{formatMoney(d.total)}</span>
              </div>
            ))}
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-base flex items-center gap-2">
              <AlertTriangle className="w-4 h-4 text-muted-foreground" /> 5 Días Más Bajos
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-2">
            {diasAgrupados.slice(-5).reverse().map((d, i) => (
              <div key={d.fecha} className="flex items-center justify-between text-sm">
                <div className="flex items-center gap-2">
                  <span className="w-5 text-muted-foreground font-medium">{i + 1}.</span>
                  <span className="capitalize">{formatFechaCorta(d.fecha)}</span>
                </div>
                <span className="font-semibold">{formatMoney(d.total)}</span>
              </div>
            ))}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
