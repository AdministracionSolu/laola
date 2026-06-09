import { useEffect, useMemo, useState } from "react";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Download, Loader2 } from "lucide-react";
import { supabase } from "@/integrations/supabase/client";
import { exportarExcel } from "@/lib/exportar";
import type { PedidoDetLite } from "@/hooks/useAnaliticaPedidos";

const money = (n: number) =>
  new Intl.NumberFormat("es-MX", { style: "currency", currency: "MXN" }).format(n);
const num = (n: number) => (Math.round(n * 100) / 100).toString();

const rpc = (fn: string, args: Record<string, unknown>) =>
  (supabase.rpc as unknown as (f: string, a: Record<string, unknown>) => Promise<{ data: unknown; error: unknown }>)(fn, args);

interface Oferta {
  insumo_id: string;
  proveedor: string;
  producto: string;
  unidad: string;
  precio: number | null;
}

interface Props {
  pedidosDetalle: PedidoDetLite[];
  insumosOrden: string[];
  nombreInsumo: Map<string, string>;
  unidadInsumo: Map<string, string>;
  hasta: string;
  /** PIN del área de compras; vacío si es admin autenticado. */
  pin?: string;
}

export function DondeComprarPanel({ pedidosDetalle, insumosOrden, nombreInsumo, unidadInsumo, hasta, pin = "" }: Props) {
  const [ofertas, setOfertas] = useState<Oferta[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    setLoading(true);
    rpc("compras_precios", { p_pin: pin }).then(({ data }) => {
      setOfertas(Array.isArray(data) ? (data as Oferta[]) : []);
      setLoading(false);
    });
  }, [pin]);

  // Total a pedir por insumo (suma de cantidad_pedida del día).
  const totalPorInsumo = useMemo(() => {
    const m = new Map<string, number>();
    pedidosDetalle
      .filter((d) => d.fecha === hasta)
      .forEach((d) => m.set(d.insumo_id, (m.get(d.insumo_id) || 0) + d.cantidad_pedida));
    return m;
  }, [pedidosDetalle, hasta]);

  // Ofertas agrupadas por insumo, ordenadas por precio.
  const ofertasPorInsumo = useMemo(() => {
    const m = new Map<string, Oferta[]>();
    ofertas.forEach((o) => {
      if (o.precio == null) return;
      const arr = m.get(o.insumo_id) || [];
      arr.push(o);
      m.set(o.insumo_id, arr);
    });
    m.forEach((arr) => arr.sort((a, b) => (a.precio! - b.precio!)));
    return m;
  }, [ofertas]);

  const filas = useMemo(() => {
    return insumosOrden
      .map((ins) => {
        const total = totalPorInsumo.get(ins) || 0;
        const ofs = ofertasPorInsumo.get(ins) || [];
        const mejor = ofs[0] || null;
        const unidad = unidadInsumo.get(ins) || mejor?.unidad || "";
        return {
          insumo_id: ins,
          nombre: nombreInsumo.get(ins) || ins,
          total,
          unidad,
          mejor,
          alternativas: ofs.slice(1),
          costo: mejor?.precio != null ? total * mejor.precio : null,
        };
      })
      .filter((f) => f.total > 0);
  }, [insumosOrden, totalPorInsumo, ofertasPorInsumo, nombreInsumo, unidadInsumo]);

  const totalGasto = filas.reduce((s, f) => s + (f.costo || 0), 0);

  const exportar = () => {
    exportarExcel(
      filas.map((f) => ({
        Insumo: f.nombre,
        "A pedir": f.total,
        Unidad: f.unidad,
        Proveedor: f.mejor?.proveedor ?? "sin precio",
        "Precio unit.": f.mejor?.precio ?? "",
        "Costo estimado": f.costo ?? "",
      })),
      `donde_comprar_${hasta}`,
      "Dónde comprar"
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
    <Card>
      <CardHeader className="pb-2 flex-row items-center justify-between">
        <div>
          <CardTitle className="text-sm">Dónde comprar — {hasta}</CardTitle>
          <CardDescription className="text-xs">
            Lo que hay que pedir y el proveedor más barato. Total estimado: <b>{money(totalGasto)}</b>
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
              <th className="text-left p-2">Comprar a (más barato)</th>
              <th className="p-2 text-right">Costo est.</th>
            </tr>
          </thead>
          <tbody>
            {filas.map((f) => (
              <tr key={f.insumo_id} className="border-b align-top">
                <td className="p-2 font-medium">{f.nombre}</td>
                <td className="p-2 text-center tabular-nums">{num(f.total)} {f.unidad}</td>
                <td className="p-2">
                  {f.mejor ? (
                    <div>
                      <span className="font-medium">{f.mejor.proveedor}</span>
                      <Badge className="ml-2 bg-emerald-500 hover:bg-emerald-500 text-xs">{money(f.mejor.precio!)}/{f.mejor.unidad}</Badge>
                      {f.alternativas.length > 0 && (
                        <div className="text-[11px] text-muted-foreground mt-0.5">
                          otros: {f.alternativas.map((a) => `${a.proveedor} ${money(a.precio!)}`).join(" · ")}
                        </div>
                      )}
                    </div>
                  ) : (
                    <span className="text-muted-foreground text-xs">sin precio cargado</span>
                  )}
                </td>
                <td className="p-2 text-right tabular-nums">{f.costo != null ? money(f.costo) : "—"}</td>
              </tr>
            ))}
            {!filas.length && (
              <tr><td colSpan={4} className="p-6 text-center text-muted-foreground">Nada que pedir ese día.</td></tr>
            )}
          </tbody>
        </table>
      </CardContent>
    </Card>
  );
}
