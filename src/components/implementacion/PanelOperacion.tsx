import { useMemo } from "react";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { Celda, Estado, LeyendaIconos, Porcentaje } from "./Celdas";
import { PanelData, etiquetaDia, etiquetaFechaLarga, hora, pct } from "./tipos";

/**
 * Operación diaria de una sucursal: pedido sugerido, existencias y recepciones.
 * Tres renglones × los días de la semana, y debajo el detalle de quién reportó
 * cada cosa (lo que sale de pedidos.registrado_por y recepciones.registrado_por).
 */
export function PanelOperacion({ data, sucursalId }: { data: PanelData; sucursalId: string }) {
  const fila = data.operacion.find((o) => o.sucursal_id === sucursalId);

  const calc = useMemo(() => {
    if (!fila) return null;
    const evaluables = fila.dias.filter((d) => d.fecha < data.hoy);
    const pedidoOk = evaluables.filter((d) => d.pedido && d.pedido.enviado_at).length;
    const existenciaOk = evaluables.filter(
      (d) => d.pedido && d.pedido.renglones > 0 && d.pedido.con_existencia > 0
    ).length;
    const recepcionOk = evaluables.filter((d) => d.recepciones.length > 0).length;
    return {
      total: evaluables.length,
      pedidoOk,
      existenciaOk,
      recepcionOk,
      pctPedido: pct(pedidoOk, evaluables.length),
      pctExistencia: pct(existenciaOk, evaluables.length),
      pctRecepcion: pct(recepcionOk, evaluables.length),
    };
  }, [fila, data.hoy]);

  if (!fila || !calc) {
    return (
      <Card>
        <CardContent className="py-10 text-center text-muted-foreground">
          Sin datos de operación para esta sucursal.
        </CardContent>
      </Card>
    );
  }

  const renglones: {
    clave: "pedido" | "existencia" | "recepcion";
    etiqueta: string;
    porcentaje: number | null;
    hechos: number;
  }[] = [
    { clave: "pedido", etiqueta: "Pedido sugerido enviado", porcentaje: calc.pctPedido, hechos: calc.pedidoOk },
    { clave: "existencia", etiqueta: "Existencias capturadas", porcentaje: calc.pctExistencia, hechos: calc.existenciaOk },
    { clave: "recepcion", etiqueta: "Recepciones marcadas", porcentaje: calc.pctRecepcion, hechos: calc.recepcionOk },
  ];

  const estadoDe = (
    clave: "pedido" | "existencia" | "recepcion",
    dia: (typeof fila.dias)[number]
  ): { estado: Estado; detalle: string } => {
    const enCurso = dia.fecha >= data.hoy;
    if (clave === "pedido") {
      if (!dia.pedido) return { estado: enCurso ? "curso" : "falta", detalle: enCurso ? "Día en curso" : "No se hizo pedido" };
      if (!dia.pedido.enviado_at)
        return {
          estado: "parcial",
          detalle: `Quedó en borrador${dia.pedido.registrado_por ? ` · ${dia.pedido.registrado_por}` : ""}`,
        };
      return {
        estado: "ok",
        detalle: `Enviado ${hora(dia.pedido.enviado_at)} · ${dia.pedido.pedidos} insumos pedidos${
          dia.pedido.registrado_por ? ` · ${dia.pedido.registrado_por}` : ""
        }`,
      };
    }
    if (clave === "existencia") {
      if (!dia.pedido || dia.pedido.renglones === 0)
        return { estado: enCurso ? "curso" : "falta", detalle: enCurso ? "Día en curso" : "Sin captura" };
      const p = dia.pedido.con_existencia / dia.pedido.renglones;
      if (dia.pedido.con_existencia === 0)
        return { estado: enCurso ? "curso" : "falta", detalle: "No capturaron existencias" };
      return {
        estado: p >= 0.9 ? "ok" : "parcial",
        detalle: `${dia.pedido.con_existencia} de ${dia.pedido.renglones} insumos con existencia`,
      };
    }
    if (dia.recepciones.length === 0)
      return { estado: enCurso ? "curso" : "falta", detalle: enCurso ? "Día en curso" : "No marcaron recepción" };
    return {
      estado: "ok",
      detalle: dia.recepciones
        .map((r) => `${r.proveedor} · ${r.renglones} insumos${r.registrado_por ? ` · ${r.registrado_por}` : ""}`)
        .join("\n"),
    };
  };

  return (
    <div className="space-y-4">
      <Card>
        <CardHeader>
          <CardTitle>Operación diaria · {fila.nombre}</CardTitle>
          <CardDescription>
            Los tres pasos que la sucursal debe cerrar cada día. El día de hoy no entra al
            porcentaje.
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="overflow-x-auto">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead className="min-w-[200px]">Proceso</TableHead>
                  {data.dias.map((d) => (
                    <TableHead key={d} className="text-center whitespace-nowrap">
                      {etiquetaDia(d)}
                    </TableHead>
                  ))}
                  <TableHead className="text-right whitespace-nowrap">Cumplimiento</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {renglones.map((r) => (
                  <TableRow key={r.clave}>
                    <TableCell className="font-medium">{r.etiqueta}</TableCell>
                    {fila.dias.map((d) => {
                      const { estado, detalle } = estadoDe(r.clave, d);
                      return (
                        <TableCell key={d.fecha}>
                          <Celda estado={estado} detalle={detalle} />
                        </TableCell>
                      );
                    })}
                    <TableCell className="text-right">
                      <Porcentaje
                        valor={r.porcentaje}
                        leyenda={`${r.hechos} de ${calc.total}`}
                        tamano="sm"
                      />
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
          <LeyendaIconos />
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Quién reportó</CardTitle>
          <CardDescription>
            El nombre que quedó grabado en cada captura, día por día.
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="overflow-x-auto">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead className="min-w-[120px]">Día</TableHead>
                  <TableHead className="min-w-[200px]">Pedido / existencias</TableHead>
                  <TableHead>Recepciones</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {fila.dias.map((d) => (
                  <TableRow key={d.fecha}>
                    <TableCell className="whitespace-nowrap">
                      <div className="font-medium">{etiquetaDia(d.fecha)}</div>
                      <div className="text-xs text-muted-foreground">
                        {etiquetaFechaLarga(d.fecha)}
                      </div>
                    </TableCell>
                    <TableCell>
                      {d.pedido ? (
                        <div className="space-y-1">
                          <div className="font-medium">
                            {d.pedido.registrado_por || "Sin nombre"}
                          </div>
                          <div className="text-xs text-muted-foreground">
                            {d.pedido.enviado_at
                              ? `Enviado ${hora(d.pedido.enviado_at)}`
                              : "Borrador sin enviar"}
                            {" · "}
                            {d.pedido.con_existencia}/{d.pedido.renglones} con existencia
                          </div>
                        </div>
                      ) : (
                        <span className="text-sm text-muted-foreground">—</span>
                      )}
                    </TableCell>
                    <TableCell>
                      {d.recepciones.length === 0 ? (
                        <span className="text-sm text-muted-foreground">—</span>
                      ) : (
                        <div className="flex flex-wrap gap-2">
                          {d.recepciones.map((r, i) => (
                            <Badge key={i} variant="secondary" className="font-normal">
                              {r.proveedor}
                              {r.registrado_por ? ` · ${r.registrado_por}` : ""}
                              <span className="ml-1 text-muted-foreground">{hora(r.hora)}</span>
                            </Badge>
                          ))}
                        </div>
                      )}
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
