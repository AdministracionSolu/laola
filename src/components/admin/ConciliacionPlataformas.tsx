import { useState, useEffect } from "react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Calendar } from "@/components/ui/calendar";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { CalendarIcon, TrendingUp, AlertTriangle, CheckCircle2, ArrowLeft } from "lucide-react";
import { supabase } from "@/integrations/supabase/client";
import { format, subDays, startOfWeek, endOfWeek, subWeeks, parseISO } from "date-fns";
import { es } from "date-fns/locale";
import { cn } from "@/lib/utils";
import { DateRange } from "react-day-picker";
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Legend,
} from "recharts";

interface ConciliacionPlataformasProps {
  sucursalId: string;
  sucursalNombre: string;
  onClose: () => void;
}

type PeriodoType = "ayer" | "semana" | "semana_anterior" | "personalizado";

interface VentaPlataforma {
  fecha: string;
  rappi: number;
  uber: number;
  total: number;
}

interface Verificacion {
  fecha_inicio: string;
  fecha_fin: string;
  cantidad_reportada: number;
  plataforma: string;
  created_at: string;
}

interface ConciliacionData {
  plataforma: string;
  ventasSistema: number;
  reportadoContadoras: number;
  diferencia: number;
  tieneDiscrepancia: boolean;
}

export function ConciliacionPlataformas({
  sucursalId,
  sucursalNombre,
  onClose,
}: ConciliacionPlataformasProps) {
  const [periodo, setPeriodo] = useState<PeriodoType>("semana");
  const [dateRange, setDateRange] = useState<DateRange | undefined>(undefined);
  const [ventasDiarias, setVentasDiarias] = useState<VentaPlataforma[]>([]);
  const [totales, setTotales] = useState({ rappi: 0, uber: 0, total: 0 });
  const [verificaciones, setVerificaciones] = useState<Verificacion[]>([]);
  const [conciliacion, setConciliacion] = useState<ConciliacionData[]>([]);
  const [isLoading, setIsLoading] = useState(false);

  const getFechasPeriodo = (p: PeriodoType): { desde: Date; hasta: Date } => {
    const hoy = new Date();
    switch (p) {
      case "ayer":
        const ayer = subDays(hoy, 1);
        return { desde: ayer, hasta: ayer };
      case "semana":
        return { desde: startOfWeek(hoy, { weekStartsOn: 1 }), hasta: hoy };
      case "semana_anterior":
        const semanaAnterior = subWeeks(hoy, 1);
        return {
          desde: startOfWeek(semanaAnterior, { weekStartsOn: 1 }),
          hasta: endOfWeek(semanaAnterior, { weekStartsOn: 1 }),
        };
      case "personalizado":
        if (dateRange?.from && dateRange?.to) {
          return { desde: dateRange.from, hasta: dateRange.to };
        }
        return { desde: hoy, hasta: hoy };
    }
  };

  const cargarDatos = async () => {
    const { desde, hasta } = getFechasPeriodo(periodo);
    if (periodo === "personalizado" && (!dateRange?.from || !dateRange?.to)) return;

    setIsLoading(true);

    try {
      // Obtener cortes con ventas de plataformas
      const { data: cortes, error } = await supabase
        .from("cortes_caja")
        .select("fecha_venta, rappi, uber")
        .eq("sucursal_id", sucursalId)
        .eq("tipo_corte", "cierre")
        .gte("fecha_venta", format(desde, "yyyy-MM-dd"))
        .lte("fecha_venta", format(hasta, "yyyy-MM-dd"))
        .order("fecha_venta", { ascending: true });

      if (error) throw error;

      // Agrupar por fecha
      const ventasPorFecha: Record<string, VentaPlataforma> = {};
      cortes?.forEach((corte) => {
        const fecha = corte.fecha_venta;
        if (!ventasPorFecha[fecha]) {
          ventasPorFecha[fecha] = { fecha, rappi: 0, uber: 0, total: 0 };
        }
        ventasPorFecha[fecha].rappi += Number(corte.rappi || 0);
        ventasPorFecha[fecha].uber += Number(corte.uber || 0);
        ventasPorFecha[fecha].total += Number(corte.rappi || 0) + Number(corte.uber || 0);
      });

      const ventasArray = Object.values(ventasPorFecha);
      setVentasDiarias(ventasArray);

      // Calcular totales
      const totalRappi = ventasArray.reduce((sum, v) => sum + v.rappi, 0);
      const totalUber = ventasArray.reduce((sum, v) => sum + v.uber, 0);
      setTotales({
        rappi: totalRappi,
        uber: totalUber,
        total: totalRappi + totalUber,
      });

      // Obtener verificaciones de contadoras para el período
      const { data: verifs } = await supabase
        .from("verificaciones_plataforma")
        .select("fecha_inicio, fecha_fin, cantidad_reportada, plataforma, created_at")
        .eq("sucursal_id", sucursalId)
        .gte("fecha_inicio", format(desde, "yyyy-MM-dd"))
        .lte("fecha_fin", format(hasta, "yyyy-MM-dd"))
        .order("created_at", { ascending: false });

      setVerificaciones((verifs as Verificacion[]) || []);

      // Calcular conciliación
      const conciliacionData: ConciliacionData[] = [
        {
          plataforma: "Rappi",
          ventasSistema: totalRappi,
          reportadoContadoras: 0,
          diferencia: 0,
          tieneDiscrepancia: false,
        },
        {
          plataforma: "Uber",
          ventasSistema: totalUber,
          reportadoContadoras: 0,
          diferencia: 0,
          tieneDiscrepancia: false,
        },
        {
          plataforma: "Total",
          ventasSistema: totalRappi + totalUber,
          reportadoContadoras: 0,
          diferencia: 0,
          tieneDiscrepancia: false,
        },
      ];

      // Sumar verificaciones por plataforma
      verifs?.forEach((v: Verificacion) => {
        const idx = v.plataforma === "rappi" ? 0 : v.plataforma === "uber" ? 1 : 2;
        if (idx < 2) {
          conciliacionData[idx].reportadoContadoras += v.cantidad_reportada;
        }
        if (v.plataforma === "total") {
          conciliacionData[2].reportadoContadoras += v.cantidad_reportada;
        }
      });

      // Si no hay verificación de total pero sí de individuales, sumar
      if (conciliacionData[2].reportadoContadoras === 0) {
        conciliacionData[2].reportadoContadoras =
          conciliacionData[0].reportadoContadoras + conciliacionData[1].reportadoContadoras;
      }

      // Calcular diferencias
      conciliacionData.forEach((c) => {
        c.diferencia = c.reportadoContadoras - c.ventasSistema;
        c.tieneDiscrepancia = Math.abs(c.diferencia) > 100;
      });

      setConciliacion(conciliacionData);
    } catch (error) {
      console.error("Error cargando datos:", error);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    if (periodo !== "personalizado" || (dateRange?.from && dateRange?.to)) {
      cargarDatos();
    }
  }, [periodo, dateRange, sucursalId]);

  const formatMoney = (value: number) =>
    new Intl.NumberFormat("es-MX", { style: "currency", currency: "MXN" }).format(value);

  const { desde, hasta } = getFechasPeriodo(periodo);
  const periodoLabel =
    periodo === "personalizado" && dateRange?.from && dateRange?.to
      ? `${format(dateRange.from, "d MMM", { locale: es })} - ${format(dateRange.to, "d MMM yyyy", { locale: es })}`
      : periodo === "ayer"
      ? format(subDays(new Date(), 1), "d 'de' MMMM", { locale: es })
      : periodo === "semana"
      ? "Esta semana"
      : "Semana anterior";

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <Button variant="ghost" size="icon" onClick={onClose}>
            <ArrowLeft className="w-5 h-5" />
          </Button>
          <div>
            <h2 className="text-xl font-bold">Conciliación de Plataformas</h2>
            <p className="text-sm text-muted-foreground">{sucursalNombre}</p>
          </div>
        </div>
      </div>

      {/* Selector de período */}
      <Card>
        <CardContent className="pt-4">
          <div className="flex flex-wrap gap-2">
            <Button
              variant={periodo === "ayer" ? "default" : "outline"}
              size="sm"
              onClick={() => setPeriodo("ayer")}
            >
              Ayer
            </Button>
            <Button
              variant={periodo === "semana" ? "default" : "outline"}
              size="sm"
              onClick={() => setPeriodo("semana")}
            >
              Esta semana
            </Button>
            <Button
              variant={periodo === "semana_anterior" ? "default" : "outline"}
              size="sm"
              onClick={() => setPeriodo("semana_anterior")}
            >
              Semana anterior
            </Button>
            <Popover>
              <PopoverTrigger asChild>
                <Button
                  variant={periodo === "personalizado" ? "default" : "outline"}
                  size="sm"
                  className="gap-2"
                >
                  <CalendarIcon className="w-4 h-4" />
                  {periodo === "personalizado" && dateRange?.from && dateRange?.to
                    ? `${format(dateRange.from, "d MMM", { locale: es })} - ${format(dateRange.to, "d MMM", { locale: es })}`
                    : "Personalizado"}
                </Button>
              </PopoverTrigger>
              <PopoverContent className="w-auto p-0" align="start">
                <Calendar
                  mode="range"
                  selected={dateRange}
                  onSelect={(range) => {
                    setDateRange(range);
                    if (range?.from && range?.to) {
                      setPeriodo("personalizado");
                    }
                  }}
                  locale={es}
                  numberOfMonths={1}
                />
              </PopoverContent>
            </Popover>
          </div>
        </CardContent>
      </Card>

      {isLoading ? (
        <div className="text-center py-8 text-muted-foreground">Cargando datos...</div>
      ) : (
        <Tabs defaultValue="resumen" className="space-y-4">
          <TabsList>
            <TabsTrigger value="resumen">Resumen</TabsTrigger>
            <TabsTrigger value="historial">Historial Diario</TabsTrigger>
            <TabsTrigger value="conciliacion">Conciliación</TabsTrigger>
          </TabsList>

          {/* Tab Resumen */}
          <TabsContent value="resumen" className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <Card>
                <CardHeader className="pb-2">
                  <CardDescription>Rappi</CardDescription>
                  <CardTitle className="text-2xl text-orange-500">
                    {formatMoney(totales.rappi)}
                  </CardTitle>
                </CardHeader>
              </Card>
              <Card>
                <CardHeader className="pb-2">
                  <CardDescription>Uber Eats</CardDescription>
                  <CardTitle className="text-2xl text-primary">
                    {formatMoney(totales.uber)}
                  </CardTitle>
                </CardHeader>
              </Card>
              <Card className="bg-primary/5 border-primary">
                <CardHeader className="pb-2">
                  <CardDescription>Total Plataformas</CardDescription>
                  <CardTitle className="text-2xl">{formatMoney(totales.total)}</CardTitle>
                </CardHeader>
              </Card>
            </div>

            {/* Gráfica */}
            {ventasDiarias.length > 1 && (
              <Card>
                <CardHeader>
                  <CardTitle>Ventas por Día</CardTitle>
                  <CardDescription>{periodoLabel}</CardDescription>
                </CardHeader>
                <CardContent>
                  <div className="h-[300px]">
                    <ResponsiveContainer width="100%" height="100%">
                      <BarChart data={ventasDiarias}>
                        <CartesianGrid strokeDasharray="3 3" className="stroke-muted" />
                        <XAxis
                          dataKey="fecha"
                          tickFormatter={(value) => format(parseISO(value), "d MMM", { locale: es })}
                          tick={{ fontSize: 12 }}
                        />
                        <YAxis tickFormatter={(value) => `$${(value / 1000).toFixed(0)}k`} />
                        <Tooltip
                          formatter={(value: number) => formatMoney(value)}
                          labelFormatter={(label) => format(parseISO(label), "EEEE d 'de' MMMM", { locale: es })}
                        />
                        <Legend />
                        <Bar dataKey="rappi" name="Rappi" fill="#FF6B00" radius={[4, 4, 0, 0]} />
                        <Bar dataKey="uber" name="Uber Eats" fill="hsl(var(--primary))" radius={[4, 4, 0, 0]} />
                      </BarChart>
                    </ResponsiveContainer>
                  </div>
                </CardContent>
              </Card>
            )}
          </TabsContent>

          {/* Tab Historial */}
          <TabsContent value="historial">
            <Card>
              <CardHeader>
                <CardTitle>Historial Diario</CardTitle>
                <CardDescription>Detalle de ventas por plataforma</CardDescription>
              </CardHeader>
              <CardContent>
                {ventasDiarias.length === 0 ? (
                  <p className="text-center py-8 text-muted-foreground">
                    No hay datos para este período
                  </p>
                ) : (
                  <Table>
                    <TableHeader>
                      <TableRow>
                        <TableHead>Fecha</TableHead>
                        <TableHead className="text-right">Rappi</TableHead>
                        <TableHead className="text-right">Uber Eats</TableHead>
                        <TableHead className="text-right">Total</TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {ventasDiarias.map((venta) => (
                        <TableRow key={venta.fecha}>
                          <TableCell>
                            {format(parseISO(venta.fecha), "EEEE d 'de' MMMM", { locale: es })}
                          </TableCell>
                          <TableCell className="text-right">{formatMoney(venta.rappi)}</TableCell>
                          <TableCell className="text-right">{formatMoney(venta.uber)}</TableCell>
                          <TableCell className="text-right font-semibold">
                            {formatMoney(venta.total)}
                          </TableCell>
                        </TableRow>
                      ))}
                      <TableRow className="bg-muted/50 font-bold">
                        <TableCell>Total</TableCell>
                        <TableCell className="text-right">{formatMoney(totales.rappi)}</TableCell>
                        <TableCell className="text-right">{formatMoney(totales.uber)}</TableCell>
                        <TableCell className="text-right">{formatMoney(totales.total)}</TableCell>
                      </TableRow>
                    </TableBody>
                  </Table>
                )}
              </CardContent>
            </Card>
          </TabsContent>

          {/* Tab Conciliación */}
          <TabsContent value="conciliacion" className="space-y-4">
            <Card>
              <CardHeader>
                <CardTitle>Conciliación con Contadoras</CardTitle>
                <CardDescription>
                  Comparación entre ventas reportadas en cortes vs lo ingresado por contadoras
                </CardDescription>
              </CardHeader>
              <CardContent>
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Plataforma</TableHead>
                      <TableHead className="text-right">Sistema (Cortes)</TableHead>
                      <TableHead className="text-right">Contadoras</TableHead>
                      <TableHead className="text-right">Diferencia</TableHead>
                      <TableHead className="text-center">Estado</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {conciliacion.map((c) => (
                      <TableRow
                        key={c.plataforma}
                        className={c.plataforma === "Total" ? "bg-muted/50 font-bold" : ""}
                      >
                        <TableCell>{c.plataforma}</TableCell>
                        <TableCell className="text-right">{formatMoney(c.ventasSistema)}</TableCell>
                        <TableCell className="text-right">
                          {c.reportadoContadoras > 0 ? formatMoney(c.reportadoContadoras) : "—"}
                        </TableCell>
                        <TableCell
                          className={cn(
                            "text-right",
                            c.tieneDiscrepancia ? "text-destructive" : ""
                          )}
                        >
                          {c.reportadoContadoras > 0 ? formatMoney(c.diferencia) : "—"}
                        </TableCell>
                        <TableCell className="text-center">
                          {c.reportadoContadoras > 0 ? (
                            c.tieneDiscrepancia ? (
                              <Badge variant="destructive" className="gap-1">
                                <AlertTriangle className="w-3 h-3" />
                                Discrepancia
                              </Badge>
                            ) : (
                              <Badge className="gap-1 bg-primary">
                                <CheckCircle2 className="w-3 h-3" />
                                OK
                              </Badge>
                            )
                          ) : (
                            <Badge variant="secondary">Sin verificar</Badge>
                          )}
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </CardContent>
            </Card>

            {/* Historial de verificaciones */}
            {verificaciones.length > 0 && (
              <Card>
                <CardHeader>
                  <CardTitle>Verificaciones Registradas</CardTitle>
                  <CardDescription>Historial de verificaciones de contadoras</CardDescription>
                </CardHeader>
                <CardContent>
                  <Table>
                    <TableHeader>
                      <TableRow>
                        <TableHead>Fecha Registro</TableHead>
                        <TableHead>Período</TableHead>
                        <TableHead>Plataforma</TableHead>
                        <TableHead className="text-right">Monto</TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {verificaciones.slice(0, 10).map((v, idx) => (
                        <TableRow key={idx}>
                          <TableCell className="text-muted-foreground">
                            {format(parseISO(v.created_at), "d MMM HH:mm", { locale: es })}
                          </TableCell>
                          <TableCell>
                            {format(parseISO(v.fecha_inicio), "d MMM", { locale: es })} -{" "}
                            {format(parseISO(v.fecha_fin), "d MMM", { locale: es })}
                          </TableCell>
                          <TableCell className="capitalize">{v.plataforma}</TableCell>
                          <TableCell className="text-right font-medium">
                            {formatMoney(v.cantidad_reportada)}
                          </TableCell>
                        </TableRow>
                      ))}
                    </TableBody>
                  </Table>
                </CardContent>
              </Card>
            )}
          </TabsContent>
        </Tabs>
      )}
    </div>
  );
}
