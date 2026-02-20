import { useMemo, useState } from "react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Label } from "@/components/ui/label";
import { CheckCircle2, XCircle, AlertTriangle, Store, Filter } from "lucide-react";
import { eachDayOfInterval, format, parseISO } from "date-fns";
import { es } from "date-fns/locale";
import { Corte, Sucursal } from "@/hooks/useCortes";
import { RangoFechas } from "@/hooks/usePeriodo";
import { PeriodSelector } from "./PeriodSelector";
import { usePeriodo, TipoPeriodo } from "@/hooks/usePeriodo";
import { useCortes } from "@/hooks/useCortes";

export function InformeCumplimiento() {
  const [filtroSucursal, setFiltroSucursal] = useState<string>("todas");
  const [filtroEstado, setFiltroEstado] = useState<string>("todos"); // todos | faltantes | completos

  const {
    tipoPeriodo,
    setTipoPeriodo,
    rangoPersonalizado,
    setRangoPersonalizado,
    rangoActual,
    rangoAnterior,
    etiquetaPeriodo,
    formatoFechaRango,
  } = usePeriodo();

  const {
    sucursales,
    cortes: todosCortes,
    isLoading,
  } = useCortes({
    rango: rangoActual,
    rangoAnterior,
    filtroSucursal: "todas",
    filtroTipo: "todos",
  });

  // Build matrix: for each day in range, for each sucursal, did they submit a cierre?
  const { dias, matriz, resumenSucursales, resumenGeneral } = useMemo(() => {
    const dias = eachDayOfInterval({ start: rangoActual.inicio, end: rangoActual.fin });

    // Map: fecha_venta -> Set of sucursal_ids that have cierre
    const cierresPorDia = new Map<string, Set<string>>();
    for (const corte of todosCortes) {
      if (corte.tipo_corte === "cierre") {
        const key = corte.fecha_venta;
        if (!cierresPorDia.has(key)) cierresPorDia.set(key, new Set());
        cierresPorDia.get(key)!.add(corte.sucursal_id);
      }
    }

    // Build matrix rows (one per day)
    const matriz = dias.map((dia) => {
      const fechaStr = format(dia, "yyyy-MM-dd");
      const cierresDelDia = cierresPorDia.get(fechaStr) || new Set<string>();
      const sucursalesStatus = sucursales.map((s) => ({
        sucursal_id: s.id,
        nombre: s.nombre,
        tieneCierre: cierresDelDia.has(s.id),
      }));
      return {
        fecha: fechaStr,
        dia,
        fechaFormateada: format(dia, "EEE d MMM", { locale: es }),
        sucursales: sucursalesStatus,
        totalCierres: sucursalesStatus.filter((s) => s.tieneCierre).length,
        totalFaltantes: sucursalesStatus.filter((s) => !s.tieneCierre).length,
      };
    });

    // Summary per sucursal
    const resumenSucursales = sucursales.map((s) => {
      const diasConCierre = matriz.filter((row) =>
        row.sucursales.find((ss) => ss.sucursal_id === s.id && ss.tieneCierre)
      ).length;
      return {
        ...s,
        diasConCierre,
        diasSinCierre: dias.length - diasConCierre,
        porcentaje: dias.length > 0 ? Math.round((diasConCierre / dias.length) * 100) : 0,
      };
    });

    const totalCeldas = dias.length * sucursales.length;
    const totalCierres = matriz.reduce((acc, row) => acc + row.totalCierres, 0);

    return {
      dias,
      matriz,
      resumenSucursales,
      resumenGeneral: {
        totalDias: dias.length,
        totalSucursales: sucursales.length,
        totalCierres,
        totalFaltantes: totalCeldas - totalCierres,
        porcentaje: totalCeldas > 0 ? Math.round((totalCierres / totalCeldas) * 100) : 0,
      },
    };
  }, [rangoActual, todosCortes, sucursales]);

  // Filter sucursales displayed
  const sucursalesFiltradas = useMemo(() => {
    if (filtroSucursal === "todas") return sucursales;
    return sucursales.filter((s) => s.id === filtroSucursal);
  }, [sucursales, filtroSucursal]);

  // Filter days displayed
  const matrizFiltrada = useMemo(() => {
    return matriz.map((row) => ({
      ...row,
      sucursales: row.sucursales.filter((s) =>
        filtroSucursal === "todas" ? true : s.sucursal_id === filtroSucursal
      ),
    })).filter((row) => {
      if (filtroEstado === "faltantes") return row.sucursales.some((s) => !s.tieneCierre);
      if (filtroEstado === "completos") return row.sucursales.every((s) => s.tieneCierre);
      return true;
    });
  }, [matriz, filtroSucursal, filtroEstado]);

  if (isLoading) {
    return (
      <div className="flex items-center justify-center py-12">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Period selector */}
      <Card>
        <CardHeader className="pb-3">
          <CardTitle className="text-lg">Período</CardTitle>
        </CardHeader>
        <CardContent>
          <PeriodSelector
            tipoPeriodo={tipoPeriodo}
            onTipoPeriodoChange={setTipoPeriodo}
            onRangoPersonalizadoChange={setRangoPersonalizado}
            etiquetaPeriodo={etiquetaPeriodo}
            formatoFechaRango={formatoFechaRango}
          />
        </CardContent>
      </Card>

      {/* Filters */}
      <Card>
        <CardContent className="pt-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label className="flex items-center gap-2">
                <Store className="w-4 h-4" />
                Sucursal
              </Label>
              <Select value={filtroSucursal} onValueChange={setFiltroSucursal}>
                <SelectTrigger>
                  <SelectValue placeholder="Todas las sucursales" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="todas">Todas las sucursales</SelectItem>
                  {sucursales.map((s) => (
                    <SelectItem key={s.id} value={s.id}>{s.nombre}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-2">
              <Label className="flex items-center gap-2">
                <Filter className="w-4 h-4" />
                Mostrar
              </Label>
              <Select value={filtroEstado} onValueChange={setFiltroEstado}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="todos">Todos los días</SelectItem>
                  <SelectItem value="faltantes">Solo días con faltantes</SelectItem>
                  <SelectItem value="completos">Solo días completos</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Summary cards */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <Card>
          <CardContent className="pt-6 text-center">
            <p className="text-3xl font-bold">{resumenGeneral.porcentaje}%</p>
            <p className="text-sm text-muted-foreground">Cumplimiento general</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6 text-center">
            <p className="text-3xl font-bold text-green-600">{resumenGeneral.totalCierres}</p>
            <p className="text-sm text-muted-foreground">Cierres registrados</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6 text-center">
            <p className="text-3xl font-bold text-destructive">{resumenGeneral.totalFaltantes}</p>
            <p className="text-sm text-muted-foreground">Cierres faltantes</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6 text-center">
            <p className="text-3xl font-bold">{resumenGeneral.totalDias}</p>
            <p className="text-sm text-muted-foreground">Días analizados</p>
          </CardContent>
        </Card>
      </div>

      {/* Per-sucursal summary */}
      <Card>
        <CardHeader className="pb-3">
          <CardTitle className="text-base">Cumplimiento por Sucursal</CardTitle>
          <CardDescription>Porcentaje de días con cierre registrado en el período</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
            {resumenSucursales.map((s) => (
              <div
                key={s.id}
                className="flex items-center justify-between p-3 rounded-lg border"
              >
                <div className="min-w-0">
                  <p className="font-medium text-sm truncate">{s.nombre}</p>
                  <p className="text-xs text-muted-foreground">
                    {s.diasConCierre} de {resumenGeneral.totalDias} días
                  </p>
                </div>
                <Badge
                  variant={s.porcentaje === 100 ? "default" : s.porcentaje >= 80 ? "secondary" : "destructive"}
                >
                  {s.porcentaje}%
                </Badge>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>

      {/* Detail matrix table */}
      <Card>
        <CardHeader className="pb-3">
          <CardTitle className="text-base">Detalle por Día</CardTitle>
          <CardDescription>
            {matrizFiltrada.length} días mostrados • 
            <CheckCircle2 className="w-3 h-3 inline text-green-600 mx-1" /> = cierre registrado • 
            <XCircle className="w-3 h-3 inline text-destructive mx-1" /> = sin cierre
          </CardDescription>
        </CardHeader>
        <CardContent>
          {matrizFiltrada.length === 0 ? (
            <p className="text-center text-muted-foreground py-8">No hay datos para mostrar con los filtros seleccionados.</p>
          ) : (
            <div className="overflow-x-auto">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead className="sticky left-0 bg-card z-10 min-w-[120px]">Fecha</TableHead>
                    {sucursalesFiltradas.map((s) => (
                      <TableHead key={s.id} className="text-center min-w-[100px]">
                        <span className="text-xs">{s.nombre}</span>
                      </TableHead>
                    ))}
                    <TableHead className="text-center min-w-[80px]">Estado</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {matrizFiltrada.map((row) => {
                    const sucsFiltradas = row.sucursales.filter((s) =>
                      sucursalesFiltradas.some((sf) => sf.id === s.sucursal_id)
                    );
                    const todasOk = sucsFiltradas.every((s) => s.tieneCierre);
                    const algunaFalta = sucsFiltradas.some((s) => !s.tieneCierre);
                    return (
                      <TableRow key={row.fecha}>
                        <TableCell className="sticky left-0 bg-card z-10 font-medium text-sm whitespace-nowrap">
                          {row.fechaFormateada}
                        </TableCell>
                        {sucsFiltradas.map((s) => (
                          <TableCell key={s.sucursal_id} className="text-center">
                            {s.tieneCierre ? (
                              <CheckCircle2 className="w-5 h-5 text-green-600 mx-auto" />
                            ) : (
                              <XCircle className="w-5 h-5 text-destructive mx-auto" />
                            )}
                          </TableCell>
                        ))}
                        <TableCell className="text-center">
                          {todasOk ? (
                            <Badge variant="default" className="text-xs">Completo</Badge>
                          ) : (
                            <Badge variant="destructive" className="text-xs">
                              {sucsFiltradas.filter((s) => !s.tieneCierre).length} faltante{sucsFiltradas.filter((s) => !s.tieneCierre).length > 1 ? "s" : ""}
                            </Badge>
                          )}
                        </TableCell>
                      </TableRow>
                    );
                  })}
                </TableBody>
              </Table>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
