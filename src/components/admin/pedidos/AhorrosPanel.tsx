import { useMemo } from "react";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Download, Loader2, PiggyBank } from "lucide-react";
import { exportarExcel } from "@/lib/exportar";
import type { PedidoDetLite } from "@/hooks/useAnaliticaPedidos";
import { useOfertasPorInsumo } from "./useOfertas";

const money = (n: number) =>
  new Intl.NumberFormat("es-MX", { style: "currency", currency: "MXN" }).format(n);
const num = (n: number) => (Math.round(n * 100) / 100).toString();
const normUnidad = (u: string | null | undefined) => (u ?? "").trim().toLowerCase();

interface Props {
  pedidosDetalle: PedidoDetLite[];
  insumosOrden: string[];
  nombreInsumo: Map<string, string>;
  unidadInsumo: Map<string, string>;
  hasta: string;
  /** PIN del área de compras; vacío si es admin autenticado. */
  pin?: string;
}

export function AhorrosPanel({ pedidosDetalle, insumosOrden, nombreInsumo, unidadInsumo, hasta, pin = "" }: Props) {
  // Ofertas agrupadas por insumo (mapeo directo o por nombre), ordenadas por precio.
  const { ofertasPorInsumo, loading } = useOfertasPorInsumo(insumosOrden, nombreInsumo, pin);

  // Total a pedir por insumo (suma de cantidad_pedida del día).
  const totalPorInsumo = useMemo(() => {
    const m = new Map<string, number>();
    pedidosDetalle
      .filter((d) => d.fecha === hasta)
      .forEach((d) => m.set(d.insumo_id, (m.get(d.insumo_id) || 0) + d.cantidad_pedida));
    return m;
  }, [pedidosDetalle, hasta]);

  // El ahorro solo es real si los precios comparados están en la MISMA unidad
  // que el pedido: se descartan ofertas en otra unidad.
  const filas = useMemo(() => {
    return insumosOrden
      .map((ins) => {
        const total = totalPorInsumo.get(ins) || 0;
        const unidad = unidadInsumo.get(ins) || "";
        const comparables = (ofertasPorInsumo.get(ins) || [])
          .filter((o) => normUnidad(o.unidad) === normUnidad(unidad));
        const barato = comparables[0] || null;
        const caro = comparables.length > 1 ? comparables[comparables.length - 1] : null;
        const ahorro = barato && caro ? total * (caro.precio! - barato.precio!) : null;
        return {
          insumo_id: ins,
          nombre: nombreInsumo.get(ins) || ins,
          total,
          unidad,
          barato,
          caro,
          proveedores: comparables.length,
          costoBarato: barato ? total * barato.precio! : null,
          costoCaro: caro ? total * caro.precio! : null,
          ahorro,
        };
      })
      .filter((f) => f.total > 0);
  }, [insumosOrden, totalPorInsumo, ofertasPorInsumo, nombreInsumo, unidadInsumo]);

  const comparadas = filas.filter((f) => f.ahorro != null);
  const totalBarato = comparadas.reduce((s, f) => s + (f.costoBarato || 0), 0);
  const totalCaro = comparadas.reduce((s, f) => s + (f.costoCaro || 0), 0);
  const totalAhorro = totalCaro - totalBarato;
  const sinComparar = filas.length - comparadas.length;

  const exportar = () => {
    exportarExcel(
      filas.map((f) => ({
        Insumo: f.nombre,
        "A pedir": f.total,
        Unidad: f.unidad,
        "Más barato": f.barato ? `${f.barato.proveedor} ${f.barato.precio}` : "",
        "Más caro": f.caro ? `${f.caro.proveedor} ${f.caro.precio}` : "",
        "Costo optimizado": f.costoBarato ?? "",
        "Ahorro potencial": f.ahorro ?? "",
      })),
      `ahorros_${hasta}`,
      "Ahorros"
    );
  };

  if (loading) {
    return (
      <div className="flex justify-center py-16">
        <Loader2 className="h-8 w-8 animate-spin text-primary" />
      </div>
    );
  }

  return (
    <div className="space-y-4">
      {/* Resumen del día */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
        <Card>
          <CardContent className="p-4">
            <p className="text-xs text-muted-foreground">Comprando al más barato</p>
            <p className="text-2xl font-bold tabular-nums">{money(totalBarato)}</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <p className="text-xs text-muted-foreground">Comprando al más caro</p>
            <p className="text-2xl font-bold tabular-nums text-muted-foreground">{money(totalCaro)}</p>
          </CardContent>
        </Card>
        <Card className="border-emerald-200 bg-emerald-50/50">
          <CardContent className="p-4">
            <p className="text-xs text-emerald-700 flex items-center gap-1"><PiggyBank className="h-3.5 w-3.5" /> Ahorro potencial del día</p>
            <p className="text-2xl font-bold tabular-nums text-emerald-700">{money(totalAhorro)}</p>
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader className="pb-2 flex-row items-center justify-between">
          <div>
            <CardTitle className="text-sm">Ahorros potenciales — {hasta}</CardTitle>
            <CardDescription className="text-xs">
              Con los precios vigentes de los proveedores: lo que cuesta el pedido del día
              eligiendo al más barato vs. al más caro de cada insumo.
              {sinComparar > 0 && (
                <span className="block text-amber-600 mt-0.5">
                  {sinComparar} insumo(s) sin comparativa (falta precio de 2+ proveedores en la misma unidad): no suman al ahorro.
                </span>
              )}
            </CardDescription>
          </div>
          <Button size="sm" variant="outline" className="gap-1" onClick={exportar} disabled={!filas.length}>
            <Download className="h-4 w-4" /> Excel
          </Button>
        </CardHeader>
        <CardContent className="p-0">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b text-xs text-muted-foreground">
                <th className="text-left p-2">Insumo</th>
                <th className="p-2 text-center">A pedir</th>
                <th className="text-left p-2">Más barato</th>
                <th className="text-left p-2">Más caro</th>
                <th className="p-2 text-right">Ahorro</th>
              </tr>
            </thead>
            <tbody>
              {filas.map((f) => (
                <tr key={f.insumo_id} className="border-b align-top">
                  <td className="p-2 font-medium">{f.nombre}</td>
                  <td className="p-2 text-center tabular-nums">{num(f.total)} {f.unidad}</td>
                  <td className="p-2">
                    {f.barato ? (
                      <span>
                        {f.barato.proveedor}
                        <Badge className="ml-2 bg-emerald-500 hover:bg-emerald-500 text-xs">{money(f.barato.precio!)}/{f.barato.unidad}</Badge>
                      </span>
                    ) : (
                      <span className="text-muted-foreground text-xs">sin precio comparable</span>
                    )}
                  </td>
                  <td className="p-2">
                    {f.caro ? (
                      <span className="text-muted-foreground">
                        {f.caro.proveedor}
                        <Badge variant="outline" className="ml-2 text-xs">{money(f.caro.precio!)}/{f.caro.unidad}</Badge>
                      </span>
                    ) : (
                      <span className="text-muted-foreground text-xs">{f.barato ? "único proveedor" : "—"}</span>
                    )}
                  </td>
                  <td className="p-2 text-right tabular-nums font-semibold text-emerald-700">
                    {f.ahorro == null ? <span className="text-muted-foreground font-normal">—</span> : money(f.ahorro)}
                  </td>
                </tr>
              ))}
              {!filas.length && (
                <tr><td colSpan={5} className="p-6 text-center text-muted-foreground">Nada que pedir ese día.</td></tr>
              )}
            </tbody>
          </table>
        </CardContent>
      </Card>
    </div>
  );
}
