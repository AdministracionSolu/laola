import { useMemo, useState } from "react";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import { Celda, Estado, LeyendaIconos, Porcentaje } from "./Celdas";
import { PanelData, etiquetaDia, etiquetaFechaLarga, hora, pct } from "./tipos";

/**
 * Precios de proveedores: quién subió y qué tan completo.
 *  · "Días" = de los días ya cerrados, en cuántos mandó al menos un precio.
 *  · "Catálogo" = qué porción de sus productos activos trae precio,
 *    promediada sobre los días en que sí mandó (subir 3 de 40 no es cumplir).
 * Los peores quedan arriba: la lista existe para perseguir a quien falla.
 */
export function PanelProveedores({ data }: { data: PanelData }) {
  const [busqueda, setBusqueda] = useState("");

  const filas = useMemo(() => {
    const calc = data.proveedores.map((p) => {
      const evaluables = p.dias.filter((d) => d.fecha < data.hoy);
      const conCarga = evaluables.filter((d) => d.productos > 0);
      const completitudes = conCarga.map((d) =>
        p.productos_activos > 0 ? Math.min(100, (d.productos / p.productos_activos) * 100) : 0
      );
      const completitud =
        completitudes.length > 0
          ? Math.round(completitudes.reduce((a, b) => a + b, 0) / completitudes.length)
          : null;
      return {
        ...p,
        evaluables: evaluables.length,
        diasConCarga: conCarga.length,
        pctDias: pct(conCarga.length, evaluables.length),
        completitud,
      };
    });
    const filtradas = busqueda.trim()
      ? calc.filter((p) => p.nombre.toLowerCase().includes(busqueda.trim().toLowerCase()))
      : calc;
    return filtradas.sort((a, b) => (a.pctDias ?? -1) - (b.pctDias ?? -1) || a.nombre.localeCompare(b.nombre));
  }, [data, busqueda]);

  const resumen = useMemo(() => {
    const totalDias = filas.reduce((a, f) => a + f.evaluables, 0);
    const totalCarga = filas.reduce((a, f) => a + f.diasConCarga, 0);
    return pct(totalCarga, totalDias);
  }, [filas]);

  return (
    <Card>
      <CardHeader>
        <div className="flex flex-wrap items-start justify-between gap-4">
          <div>
            <CardTitle>Precios de proveedores</CardTitle>
            <CardDescription>
              De lunes a domingo: quién sube, qué días y qué tanto de su catálogo.
            </CardDescription>
          </div>
          <div className="flex items-center gap-4">
            <Porcentaje valor={resumen} leyenda="carga general de la semana" />
            <Input
              placeholder="Buscar proveedor"
              value={busqueda}
              onChange={(e) => setBusqueda(e.target.value)}
              className="w-44"
            />
          </div>
        </div>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="overflow-x-auto">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead className="min-w-[180px]">Proveedor</TableHead>
                <TableHead className="text-center">Catálogo</TableHead>
                {data.dias.map((d) => (
                  <TableHead key={d} className="text-center whitespace-nowrap">
                    {etiquetaDia(d)}
                  </TableHead>
                ))}
                <TableHead className="text-right whitespace-nowrap">Días</TableHead>
                <TableHead className="text-right whitespace-nowrap">Completo</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {filas.map((p) => (
                <TableRow key={p.id}>
                  <TableCell>
                    <div className="font-medium">{p.nombre}</div>
                    <div className="text-xs text-muted-foreground">
                      {p.ultimo_precio_at
                        ? `Último precio: ${etiquetaFechaLarga(p.ultimo_precio_at.slice(0, 10))}`
                        : "Nunca ha subido precios"}
                      {p.fallidos > 0 && (
                        <Badge variant="outline" className="ml-2 text-red-600 border-red-300">
                          {p.fallidos} envío{p.fallidos > 1 ? "s" : ""} fallido{p.fallidos > 1 ? "s" : ""}
                        </Badge>
                      )}
                    </div>
                  </TableCell>
                  <TableCell className="text-center tabular-nums text-muted-foreground">
                    {p.productos_activos}
                  </TableCell>
                  {p.dias.map((d) => {
                    const proporcion =
                      p.productos_activos > 0 ? d.productos / p.productos_activos : 0;
                    const estado: Estado =
                      d.productos === 0
                        ? d.fecha >= data.hoy
                          ? "curso"
                          : "falta"
                        : proporcion >= 0.9
                        ? "ok"
                        : "parcial";
                    const detalle =
                      d.productos === 0
                        ? d.fecha >= data.hoy
                          ? "Día en curso"
                          : "No subió precios"
                        : `${d.productos} de ${p.productos_activos} productos · primer precio ${hora(d.hora)}`;
                    return (
                      <TableCell key={d.fecha}>
                        <Celda estado={estado} detalle={detalle} />
                      </TableCell>
                    );
                  })}
                  <TableCell className="text-right">
                    <Porcentaje
                      valor={p.pctDias}
                      leyenda={`${p.diasConCarga}/${p.evaluables}`}
                      tamano="sm"
                    />
                  </TableCell>
                  <TableCell className="text-right">
                    <Porcentaje valor={p.completitud} tamano="sm" />
                  </TableCell>
                </TableRow>
              ))}
              {filas.length === 0 && (
                <TableRow>
                  <TableCell colSpan={data.dias.length + 4} className="text-center text-muted-foreground py-8">
                    Sin proveedores que coincidan.
                  </TableCell>
                </TableRow>
              )}
            </TableBody>
          </Table>
        </div>
        <LeyendaIconos />
      </CardContent>
    </Card>
  );
}
