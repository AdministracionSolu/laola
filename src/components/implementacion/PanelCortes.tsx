import { useMemo } from "react";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { Celda, Estado, LeyendaIconos, Porcentaje } from "./Celdas";
import { PanelData, etiquetaDia, hora, pct } from "./tipos";

/**
 * Carga de cortes de cierre: una fila por sucursal, una columna por día.
 * El porcentaje sólo cuenta los días ya cerrados (el de hoy va como "en curso").
 */
export function PanelCortes({ data }: { data: PanelData }) {
  const filas = useMemo(() => {
    return data.cortes.map((f) => {
      const evaluables = f.dias.filter((d) => d.fecha < data.hoy);
      const hechos = evaluables.filter((d) => d.cierre).length;
      return {
        ...f,
        evaluables: evaluables.length,
        hechos,
        porcentaje: pct(hechos, evaluables.length),
        alertas: f.dias.filter((d) => d.alertado).length,
      };
    });
  }, [data]);

  return (
    <Card>
      <CardHeader>
        <CardTitle>Cortes de cierre</CardTitle>
        <CardDescription>
          Un día cuenta como cumplido cuando la sucursal registró su corte de cierre en el Centro de
          Operaciones. El día de hoy no entra al porcentaje porque aún está en curso.
        </CardDescription>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="overflow-x-auto">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead className="min-w-[160px]">Sucursal</TableHead>
                {data.dias.map((d) => (
                  <TableHead key={d} className="text-center whitespace-nowrap">
                    {etiquetaDia(d)}
                  </TableHead>
                ))}
                <TableHead className="text-right whitespace-nowrap">Cumplimiento</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {filas.map((f) => (
                <TableRow key={f.sucursal_id}>
                  <TableCell className="font-medium">
                    {f.nombre}
                    {f.hora_limite && (
                      <span className="ml-2 text-xs text-muted-foreground">
                        límite {f.hora_limite.slice(0, 5)}
                      </span>
                    )}
                  </TableCell>
                  {f.dias.map((d) => {
                    const estado: Estado = d.cierre ? "ok" : d.fecha >= data.hoy ? "curso" : "falta";
                    const detalle = d.cierre
                      ? `Corte de cierre capturado ${hora(d.capturado_at)}${
                          d.momentos ? ` · ${d.momentos} corte(s) de momento` : ""
                        }`
                      : d.fecha >= data.hoy
                      ? "Día en curso"
                      : d.alertado
                      ? "Sin corte de cierre · ya se les avisó por WhatsApp"
                      : "Sin corte de cierre";
                    return (
                      <TableCell key={d.fecha}>
                        <Celda estado={estado} detalle={detalle} />
                      </TableCell>
                    );
                  })}
                  <TableCell className="text-right">
                    <div className="flex items-center justify-end gap-2">
                      {f.alertas > 0 && (
                        <Badge variant="outline" className="text-amber-600 border-amber-300">
                          {f.alertas} aviso{f.alertas > 1 ? "s" : ""}
                        </Badge>
                      )}
                      <Porcentaje
                        valor={f.porcentaje}
                        leyenda={`${f.hechos} de ${f.evaluables}`}
                        tamano="sm"
                      />
                    </div>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </div>
        <LeyendaIconos />
      </CardContent>
    </Card>
  );
}
