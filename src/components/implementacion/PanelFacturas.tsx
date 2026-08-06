import { useMemo } from "react";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Indicador, Porcentaje } from "./Celdas";
import { PanelData, etiquetaDia, etiquetaFechaLarga, pct } from "./tipos";

/**
 * Facturación por QR. Hoy sólo opera Valle, así que el panel se enfoca en la
 * sucursal seleccionada y deja abajo el comparativo del resto para el día que
 * se prendan los demás QR.
 */
export function PanelFacturas({ data, sucursalId }: { data: PanelData; sucursalId: string }) {
  const fila = data.facturas.find((f) => f.sucursal_id === sucursalId);

  const calc = useMemo(() => {
    if (!fila) return null;
    const solicitadas = fila.dias.reduce((a, d) => a + d.solicitadas, 0);
    const timbradas = fila.dias.reduce((a, d) => a + d.timbradas, 0);
    const conActividad = fila.dias.filter((d) => d.fecha < data.hoy && d.solicitadas > 0).length;
    const evaluables = fila.dias.filter((d) => d.fecha < data.hoy).length;
    return {
      solicitadas,
      timbradas,
      pctTimbrado: pct(timbradas, solicitadas),
      conActividad,
      evaluables,
    };
  }, [fila, data.hoy]);

  const otras = data.facturas.filter((f) => f.sucursal_id !== sucursalId && f.historico > 0);

  if (!fila || !calc) {
    return (
      <Card>
        <CardContent className="py-10 text-center text-muted-foreground">
          Sin datos de facturación para esta sucursal.
        </CardContent>
      </Card>
    );
  }

  return (
    <div className="space-y-4">
      <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
        <Indicador
          titulo="Solicitadas"
          valor={String(calc.solicitadas)}
          leyenda="con el QR, en el periodo"
        />
        <Indicador titulo="Timbradas" valor={String(calc.timbradas)} leyenda="ya facturadas" />
        <Indicador
          titulo="Por timbrar"
          valor={String(fila.pendientes_totales)}
          leyenda="pendientes acumuladas"
        />
        <Indicador
          titulo="Histórico"
          valor={String(fila.historico)}
          leyenda="desde que arrancó el QR"
        />
      </div>

      <Card>
        <CardHeader>
          <div className="flex flex-wrap items-start justify-between gap-4">
            <div>
              <CardTitle>Facturas por QR · {fila.nombre}</CardTitle>
              <CardDescription>
                Cuántas se solicitaron cada día y cuántas ya se timbraron.
              </CardDescription>
            </div>
            <Porcentaje valor={calc.pctTimbrado} leyenda="solicitudes ya timbradas" />
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="overflow-x-auto">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Día</TableHead>
                  <TableHead className="text-right">Solicitadas</TableHead>
                  <TableHead className="text-right">Timbradas</TableHead>
                  <TableHead className="text-right">Por timbrar</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {fila.dias.map((d) => (
                  <TableRow key={d.fecha}>
                    <TableCell className="whitespace-nowrap">
                      <span className="font-medium">{etiquetaDia(d.fecha)}</span>
                      <span className="ml-2 text-xs text-muted-foreground">
                        {etiquetaFechaLarga(d.fecha)}
                      </span>
                    </TableCell>
                    <TableCell className="text-right tabular-nums font-medium">
                      {d.solicitadas || <span className="text-muted-foreground">—</span>}
                    </TableCell>
                    <TableCell className="text-right tabular-nums text-emerald-600">
                      {d.timbradas || <span className="text-muted-foreground">—</span>}
                    </TableCell>
                    <TableCell className="text-right tabular-nums text-amber-600">
                      {d.solicitadas - d.timbradas || <span className="text-muted-foreground">—</span>}
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
          {fila.rechazadas > 0 && (
            <p className="text-sm text-red-600">
              {fila.rechazadas} solicitud{fila.rechazadas > 1 ? "es" : ""} rechazada
              {fila.rechazadas > 1 ? "s" : ""} en el periodo.
            </p>
          )}
          {data.facturas_sin_sucursal > 0 && (
            <p className="text-sm text-muted-foreground">
              {data.facturas_sin_sucursal} solicitud{data.facturas_sin_sucursal > 1 ? "es" : ""} llegaron
              sin sucursal (entraron a /factura sin el QR de una sucursal).
            </p>
          )}
        </CardContent>
      </Card>

      {otras.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle>Otras sucursales</CardTitle>
            <CardDescription>Sólo aparecen las que ya recibieron alguna solicitud.</CardDescription>
          </CardHeader>
          <CardContent>
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Sucursal</TableHead>
                  <TableHead className="text-right">En el periodo</TableHead>
                  <TableHead className="text-right">Por timbrar</TableHead>
                  <TableHead className="text-right">Histórico</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {otras.map((f) => (
                  <TableRow key={f.sucursal_id}>
                    <TableCell className="font-medium">{f.nombre}</TableCell>
                    <TableCell className="text-right tabular-nums">
                      {f.dias.reduce((a, d) => a + d.solicitadas, 0)}
                    </TableCell>
                    <TableCell className="text-right tabular-nums">{f.pendientes_totales}</TableCell>
                    <TableCell className="text-right tabular-nums">{f.historico}</TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
