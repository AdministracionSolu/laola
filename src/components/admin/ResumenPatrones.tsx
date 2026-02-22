import { useMemo } from "react";
import { parseISO, getDay, format } from "date-fns";
import { es } from "date-fns/locale";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
} from "recharts";
import {
  CalendarDays, TrendingUp, TrendingDown, Trophy, AlertTriangle, Store, Flame, ArrowUp, ArrowDown, Lightbulb, BedDouble,
} from "lucide-react";
import { CorteRow, YearSummary, DIAS_SEMANA, COLORS_SUCURSAL, MESES_CORTO, formatMoney, formatMoneyShort, formatFecha, formatFechaCorta } from "./ResumenAnual";

interface Props {
  cortes: CorteRow[];
  allCortes: CorteRow[];
  sucursalNames: string[];
  yearSummaries: YearSummary[];
  selectedYear: number | "global";
}

export function ResumenPatrones({ cortes, allCortes, sucursalNames, yearSummaries, selectedYear }: Props) {
  // Day of week analysis
  const dayOfWeek = useMemo(() => {
    const byDate: Record<string, number> = {};
    for (const c of cortes) {
      byDate[c.fecha_venta] = (byDate[c.fecha_venta] || 0) + Number(c.total);
    }
    const byDow: Record<number, { total: number; count: number }> = {};
    for (const [fecha, total] of Object.entries(byDate)) {
      const dow = getDay(parseISO(fecha));
      if (!byDow[dow]) byDow[dow] = { total: 0, count: 0 };
      byDow[dow].total += total;
      byDow[dow].count += 1;
    }
    return Object.entries(byDow)
      .map(([dow, d]) => ({
        dia: DIAS_SEMANA[Number(dow)],
        diaCorto: DIAS_SEMANA[Number(dow)].substring(0, 3),
        dowIndex: Number(dow),
        promedio: d.count > 0 ? d.total / d.count : 0,
        totalDias: d.count,
      }))
      .sort((a, b) => b.promedio - a.promedio);
  }, [cortes]);

  // Day of week per branch
  const dayOfWeekPerBranch = useMemo(() => {
    const byBranch: Record<string, Record<number, { total: number; count: number }>> = {};
    for (const c of cortes) {
      const suc = c.sucursales?.nombre || "?";
      if (!byBranch[suc]) byBranch[suc] = {};
      const dow = getDay(parseISO(c.fecha_venta));
      // Need to aggregate per date first per branch
    }
    // Better approach: aggregate by date per branch, then average
    const byBranchDate: Record<string, Record<string, number>> = {};
    for (const c of cortes) {
      const suc = c.sucursales?.nombre || "?";
      if (!byBranchDate[suc]) byBranchDate[suc] = {};
      byBranchDate[suc][c.fecha_venta] = (byBranchDate[suc][c.fecha_venta] || 0) + Number(c.total);
    }
    return Object.entries(byBranchDate).map(([suc, dates]) => {
      const dowAgg: Record<number, { total: number; count: number }> = {};
      for (const [fecha, total] of Object.entries(dates)) {
        const dow = getDay(parseISO(fecha));
        if (!dowAgg[dow]) dowAgg[dow] = { total: 0, count: 0 };
        dowAgg[dow].total += total;
        dowAgg[dow].count += 1;
      }
      const sorted = Object.entries(dowAgg)
        .map(([d, v]) => ({ dia: DIAS_SEMANA[Number(d)], promedio: v.count > 0 ? v.total / v.count : 0 }))
        .sort((a, b) => b.promedio - a.promedio);
      return { sucursal: suc, mejor: sorted[0], peor: sorted[sorted.length - 1] };
    });
  }, [cortes]);

  // Best/worst days (all time or selected)
  const topDays = useMemo(() => {
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

  // Best/worst per branch
  const bestWorstPerBranch = useMemo(() => {
    const bySuc: Record<string, { fecha: string; total: number }[]> = {};
    for (const c of cortes) {
      const suc = c.sucursales?.nombre || "?";
      if (!bySuc[suc]) bySuc[suc] = [];
      const existing = bySuc[suc].find(d => d.fecha === c.fecha_venta);
      if (existing) existing.total += Number(c.total);
      else bySuc[suc].push({ fecha: c.fecha_venta, total: Number(c.total) });
    }
    return Object.entries(bySuc).map(([suc, dias]) => {
      const sorted = [...dias].sort((a, b) => b.total - a.total);
      return { sucursal: suc, mejor: sorted[0], peor: sorted[sorted.length - 1] };
    });
  }, [cortes]);

  // Strategic insights
  const insights = useMemo(() => {
    const list: { icon: string; text: string; type: "positive" | "negative" | "neutral" }[] = [];

    // Best day to close
    if (dayOfWeek.length > 0) {
      const worst = dayOfWeek[dayOfWeek.length - 1];
      const best = dayOfWeek[0];
      list.push({
        icon: "🔒",
        text: `Si necesitas cerrar un día, **${worst.dia}** es la mejor opción — es el día con menor venta promedio (${formatMoney(worst.promedio)}). El mejor día es **${best.dia}** (${formatMoney(best.promedio)}).`,
        type: "neutral",
      });
    }

    // Payment trend
    const fullYears = yearSummaries.filter(ys => ys.dias >= 300);
    if (fullYears.length >= 2) {
      const first = fullYears[0];
      const last = fullYears[fullYears.length - 1];
      const diff = last.pctTarjetas - first.pctTarjetas;
      if (Math.abs(diff) > 2) {
        list.push({
          icon: diff > 0 ? "🏦" : "💵",
          text: `El pago con tarjeta ${diff > 0 ? "ha crecido" : "ha disminuido"} **${Math.abs(diff).toFixed(1)} puntos porcentuales** desde ${first.year} (${first.pctTarjetas.toFixed(0)}%) hasta ${last.year} (${last.pctTarjetas.toFixed(0)}%).`,
          type: diff > 0 ? "neutral" : "neutral",
        });
      }
    }

    // Growth trend
    if (fullYears.length >= 2) {
      const last = fullYears[fullYears.length - 1];
      const prev = fullYears[fullYears.length - 2];
      const growth = ((last.total - prev.total) / prev.total) * 100;
      list.push({
        icon: growth > 0 ? "📈" : "📉",
        text: `Las ventas ${growth > 0 ? "crecieron" : "disminuyeron"} un **${Math.abs(growth).toFixed(1)}%** de ${prev.year} a ${last.year} (${formatMoneyShort(prev.total)} → ${formatMoneyShort(last.total)}).`,
        type: growth > 0 ? "positive" : "negative",
      });

      // Per branch growth
      for (const suc of sucursalNames) {
        const prevSuc = prev.porSucursal[suc] || 0;
        const lastSuc = last.porSucursal[suc] || 0;
        if (prevSuc > 0) {
          const gSuc = ((lastSuc - prevSuc) / prevSuc) * 100;
          if (Math.abs(gSuc) > 5) {
            list.push({
              icon: gSuc > 0 ? "🟢" : "🔴",
              text: `**${suc}** ${gSuc > 0 ? "creció" : "bajó"} un **${Math.abs(gSuc).toFixed(1)}%** de ${prev.year} a ${last.year}.`,
              type: gSuc > 0 ? "positive" : "negative",
            });
          }
        }
      }
    }

    // Strongest branch
    if (sucursalNames.length > 1) {
      const totalPorSuc = sucursalNames.map(suc => ({
        suc,
        total: cortes.filter(c => c.sucursales?.nombre === suc).reduce((s, c) => s + Number(c.total), 0),
      })).sort((a, b) => b.total - a.total);
      const globalT = totalPorSuc.reduce((s, x) => s + x.total, 0);
      const top = totalPorSuc[0];
      list.push({
        icon: "🏆",
        text: `**${top.suc}** es la sucursal líder, representando el **${((top.total / globalT) * 100).toFixed(0)}%** de las ventas totales.`,
        type: "positive",
      });
    }

    // Seasonality
    if (cortes.length > 0) {
      const monthTotals: Record<number, { total: number; count: number }> = {};
      const byDate: Record<string, number> = {};
      for (const c of cortes) {
        byDate[c.fecha_venta] = (byDate[c.fecha_venta] || 0) + Number(c.total);
      }
      for (const [fecha, total] of Object.entries(byDate)) {
        const m = parseInt(fecha.split("-")[1]) - 1;
        if (!monthTotals[m]) monthTotals[m] = { total: 0, count: 0 };
        monthTotals[m].total += total;
        monthTotals[m].count += 1;
      }
      const sorted = Object.entries(monthTotals)
        .map(([m, d]) => ({ mes: MESES_CORTO[Number(m)], promedio: d.count > 0 ? d.total / d.count : 0 }))
        .sort((a, b) => b.promedio - a.promedio);
      if (sorted.length >= 2) {
        list.push({
          icon: "📅",
          text: `Históricamente, **${sorted[0].mes}** es el mes con mayor venta promedio diaria (${formatMoney(sorted[0].promedio)}) y **${sorted[sorted.length - 1].mes}** el menor (${formatMoney(sorted[sorted.length - 1].promedio)}).`,
          type: "neutral",
        });
      }
    }

    return list;
  }, [cortes, dayOfWeek, yearSummaries, sucursalNames]);

  const mejorDia = topDays[0];
  const peorDia = topDays[topDays.length - 1];

  const dayChartData = useMemo(() => {
    // Ordered Mon-Sun
    const order = [1, 2, 3, 4, 5, 6, 0];
    return order.map(d => dayOfWeek.find(x => x.dowIndex === d)).filter(Boolean) as typeof dayOfWeek;
  }, [dayOfWeek]);

  const label = selectedYear === "global" ? "Histórico" : `${selectedYear}`;

  return (
    <div className="space-y-6">
      {/* Strategic Insights */}
      <Card className="border-primary/20 bg-gradient-to-br from-primary/5 to-transparent">
        <CardHeader>
          <CardTitle className="text-lg flex items-center gap-2">
            <Lightbulb className="w-5 h-5 text-primary" />
            Insights Estratégicos — {label}
          </CardTitle>
          <CardDescription>Patrones detectados automáticamente para tomar mejores decisiones</CardDescription>
        </CardHeader>
        <CardContent className="space-y-3">
          {insights.map((insight, i) => (
            <div
              key={i}
              className={`p-3 rounded-lg border ${
                insight.type === "positive" ? "bg-emerald-50/50 border-emerald-200 dark:bg-emerald-950/20 dark:border-emerald-800" :
                insight.type === "negative" ? "bg-red-50/50 border-red-200 dark:bg-red-950/20 dark:border-red-800" :
                "bg-muted/50 border-dashed"
              }`}
            >
              <p className="text-sm" dangerouslySetInnerHTML={{
                __html: `${insight.icon} ${insight.text.replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')}`
              }} />
            </div>
          ))}
        </CardContent>
      </Card>

      {/* Day of week chart */}
      <Card>
        <CardHeader>
          <CardTitle className="text-lg flex items-center gap-2">
            <CalendarDays className="w-5 h-5" />
            Venta Promedio por Día de la Semana
          </CardTitle>
          <CardDescription>
            {label} — ¿Qué día conviene reforzar o cerrar?
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="h-[250px] mb-4">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={dayChartData}>
                <CartesianGrid strokeDasharray="3 3" className="stroke-muted" />
                <XAxis dataKey="diaCorto" tick={{ fontSize: 11 }} />
                <YAxis tickFormatter={v => formatMoneyShort(v)} tick={{ fontSize: 10 }} />
                <Tooltip formatter={(value: number) => [formatMoney(value), "Promedio"]} />
                <Bar dataKey="promedio" fill="hsl(var(--primary))" radius={[4, 4, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
          {/* Ranking bars */}
          <div className="space-y-2">
            {dayOfWeek.map((d, idx) => {
              const max = dayOfWeek[0]?.promedio || 1;
              const pct = (d.promedio / max) * 100;
              return (
                <div key={d.dia} className="flex items-center gap-3">
                  <span className="w-6 text-sm text-muted-foreground font-medium">#{idx + 1}</span>
                  <span className="w-24 text-sm font-medium">{d.dia}</span>
                  <div className="flex-1 h-5 bg-muted rounded-full overflow-hidden">
                    <div
                      className={`h-full rounded-full transition-all ${idx === 0 ? "bg-emerald-500/70" : idx === dayOfWeek.length - 1 ? "bg-destructive/50" : "bg-primary/50"}`}
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

      {/* Per-branch day of week */}
      {dayOfWeekPerBranch.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle className="text-lg flex items-center gap-2">
              <Store className="w-5 h-5" />
              Mejor y Peor Día por Sucursal
            </CardTitle>
            <CardDescription>Recomendación de operación por sucursal</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              {dayOfWeekPerBranch.map(s => (
                <div key={s.sucursal} className="p-4 rounded-lg border bg-card space-y-2">
                  <p className="font-semibold text-sm" style={{ color: COLORS_SUCURSAL[s.sucursal] }}>{s.sucursal}</p>
                  {s.mejor && (
                    <div className="flex items-center gap-2 text-sm">
                      <ArrowUp className="w-3 h-3 text-emerald-500" />
                      <span className="text-muted-foreground">Mejor:</span>
                      <span className="font-medium">{s.mejor.dia}</span>
                      <span className="text-xs text-muted-foreground">({formatMoney(s.mejor.promedio)})</span>
                    </div>
                  )}
                  {s.peor && (
                    <div className="flex items-center gap-2 text-sm">
                      <ArrowDown className="w-3 h-3 text-destructive" />
                      <span className="text-muted-foreground">Menor:</span>
                      <span className="font-medium">{s.peor.dia}</span>
                      <span className="text-xs text-muted-foreground">({formatMoney(s.peor.promedio)})</span>
                    </div>
                  )}
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      )}

      {/* Best/worst days */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {mejorDia && (
          <Card className="border-emerald-200 dark:border-emerald-800">
            <CardHeader className="pb-2">
              <CardTitle className="text-base flex items-center gap-2 text-emerald-600">
                <TrendingUp className="w-5 h-5" /> Mejor Día {label}
              </CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-2xl font-bold">{formatMoney(mejorDia.total)}</p>
              <p className="text-sm text-muted-foreground capitalize">{formatFecha(mejorDia.fecha)}</p>
              <div className="mt-2 flex flex-wrap gap-1">
                {Object.entries(mejorDia.porSucursal).map(([suc, val]) => (
                  <Badge key={suc} variant="secondary" className="text-[10px]">{suc}: {formatMoneyShort(val)}</Badge>
                ))}
              </div>
            </CardContent>
          </Card>
        )}
        {peorDia && (
          <Card>
            <CardHeader className="pb-2">
              <CardTitle className="text-base flex items-center gap-2 text-muted-foreground">
                <TrendingDown className="w-5 h-5" /> Día Más Bajo {label}
              </CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-2xl font-bold">{formatMoney(peorDia.total)}</p>
              <p className="text-sm text-muted-foreground capitalize">{formatFecha(peorDia.fecha)}</p>
              <div className="mt-2 flex flex-wrap gap-1">
                {Object.entries(peorDia.porSucursal).map(([suc, val]) => (
                  <Badge key={suc} variant="outline" className="text-[10px]">{suc}: {formatMoneyShort(val)}</Badge>
                ))}
              </div>
            </CardContent>
          </Card>
        )}
      </div>

      {/* Best/worst per branch */}
      <Card>
        <CardHeader>
          <CardTitle className="text-lg flex items-center gap-2">
            <Trophy className="w-5 h-5" />
            Mejor y Peor Día por Sucursal
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            {bestWorstPerBranch.map(s => (
              <div key={s.sucursal} className="p-4 rounded-lg border bg-card space-y-3">
                <p className="font-semibold text-sm" style={{ color: COLORS_SUCURSAL[s.sucursal] }}>{s.sucursal}</p>
                {s.mejor && (
                  <div className="flex items-start gap-2">
                    <ArrowUp className="w-4 h-4 text-emerald-500 mt-0.5 shrink-0" />
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

      {/* Top 5 / Bottom 5 */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-base flex items-center gap-2">
              <Flame className="w-4 h-4 text-primary" /> Top 10 Días
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-2">
            {topDays.slice(0, 10).map((d, i) => (
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
              <AlertTriangle className="w-4 h-4 text-muted-foreground" /> 10 Días Más Bajos
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-2">
            {topDays.slice(-10).reverse().map((d, i) => (
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
