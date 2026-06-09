import { useMemo, useState, useCallback } from "react";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { ScrollArea } from "@/components/ui/scroll-area";
import { Download, GitCompareArrows, Loader2 } from "lucide-react";
import { toast } from "sonner";
import { supabase } from "@/integrations/supabase/client";
import { exportarExcel } from "@/lib/exportar";
import type { SucursalLite, PedidoDetLite } from "@/hooks/useAnaliticaPedidos";

const num = (n: number) => (Math.round(n * 100) / 100).toString();

interface Props {
  sucursales: SucursalLite[];
  pedidosDetalle: PedidoDetLite[];
  insumosOrden: string[];
  nombreInsumo: Map<string, string>;
  hasta: string;
  refetch: () => void;
}

export function PedidoDelDiaPanel({ sucursales, pedidosDetalle, insumosOrden, nombreInsumo, hasta, refetch }: Props) {
  const [pedidoEdits, setPedidoEdits] = useState<Record<string, number>>({});
  const [guardando, setGuardando] = useState(false);

  const pedidoRealDe = useCallback(
    (d: { id: string; cantidad_pedida: number }) => pedidoEdits[d.id] ?? (d.cantidad_pedida ?? 0),
    [pedidoEdits]
  );

  const setPedido = (detalleId: string, value: number) =>
    setPedidoEdits((prev) => ({ ...prev, [detalleId]: value }));

  const copiarSolicitados = () => {
    const next: Record<string, number> = {};
    pedidosDetalle
      .filter((d) => d.fecha === hasta)
      .forEach((d) => {
        next[d.id] = d.cantidad_sugerida ?? d.cantidad_pedida ?? 0;
      });
    setPedidoEdits((prev) => ({ ...prev, ...next }));
    toast.success("Copiado lo que pidieron las sucursales");
  };

  const guardar = async () => {
    const entries = Object.entries(pedidoEdits);
    if (entries.length === 0) {
      toast.error("No hay cambios que guardar");
      return;
    }
    setGuardando(true);
    const results = await Promise.all(
      entries.map(([id, value]) =>
        supabase.from("pedidos_detalle").update({ cantidad_pedida: value }).eq("id", id)
      )
    );
    setGuardando(false);
    if (results.find((r) => r.error)) {
      toast.error("No se pudieron guardar todos los renglones");
      return;
    }
    toast.success("Pedido del día guardado ✓");
    setPedidoEdits({});
    refetch();
  };

  const consolidado = useMemo(() => {
    const pedMap = new Map<string, PedidoDetLite>();
    pedidosDetalle.filter((d) => d.fecha === hasta).forEach((d) => pedMap.set(`${d.sucursal_id}|${d.insumo_id}`, d));
    return insumosOrden
      .map((ins) => {
        const celdas = sucursales.map((s) => {
          const det = pedMap.get(`${s.id}|${ins}`);
          return {
            sucursal_id: s.id,
            detalleId: det?.id ?? null,
            existencia: det?.existencia ?? 0,
            solicitado: det?.cantidad_sugerida ?? 0,
            pedidoReal: det ? pedidoRealDe(det) : null,
          };
        });
        const totalPed = celdas.reduce((s, c) => s + (c.pedidoReal ?? 0), 0);
        return { insumo_id: ins, nombre: nombreInsumo.get(ins) || ins, celdas, totalPed };
      })
      .filter((r) => r.totalPed > 0 || r.celdas.some((c) => c.solicitado > 0));
  }, [hasta, pedidosDetalle, insumosOrden, sucursales, nombreInsumo, pedidoRealDe]);

  const exportar = () => {
    const filas = consolidado.map((r) => {
      const fila: Record<string, string | number> = { Insumo: r.nombre };
      r.celdas.forEach((c) => {
        const s = sucursales.find((x) => x.id === c.sucursal_id)?.nombre || "";
        fila[`${s} existencia`] = c.existencia;
        fila[`${s} solicitado`] = c.solicitado;
        fila[`${s} a pedir`] = c.pedidoReal ?? "";
      });
      fila["Total a pedir"] = r.totalPed;
      return fila;
    });
    exportarExcel(filas, `pedido_del_dia_${hasta}`, "Pedido del día");
  };

  return (
    <Card>
      <CardHeader className="pb-2 space-y-2">
        <div className="flex flex-row items-center justify-between gap-2">
          <div>
            <CardTitle className="text-sm">Pedido del día — {hasta}</CardTitle>
            <CardDescription className="text-xs">
              Cada celda: <b>ex</b>istencia · lo que la sucursal <b>pidió</b> · <b>casilla: cuánto les vamos a pedir</b>. Captura y guarda.
            </CardDescription>
          </div>
          <Button size="sm" variant="outline" className="gap-1" onClick={exportar} disabled={!consolidado.length}>
            <Download className="h-4 w-4" /> Excel
          </Button>
        </div>
        <div className="flex flex-wrap gap-2">
          <Button size="sm" variant="secondary" className="gap-1" onClick={copiarSolicitados} disabled={!consolidado.length}>
            <GitCompareArrows className="h-4 w-4" /> Copiar lo que pidieron
          </Button>
          <Button size="sm" className="gap-1" onClick={guardar} disabled={guardando || Object.keys(pedidoEdits).length === 0}>
            {guardando ? <Loader2 className="h-4 w-4 animate-spin" /> : <Download className="h-4 w-4 rotate-180" />}
            Guardar pedido del día
          </Button>
        </div>
      </CardHeader>
      <CardContent className="p-0">
        <ScrollArea className="w-full whitespace-nowrap">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b text-xs text-muted-foreground">
                <th className="text-left p-2 sticky left-0 bg-background">Insumo</th>
                {sucursales.map((s) => (
                  <th key={s.id} className="p-2 text-center min-w-[110px]">{s.nombre}</th>
                ))}
                <th className="p-2 text-center">Total a pedir</th>
              </tr>
            </thead>
            <tbody>
              {consolidado.map((r) => (
                <tr key={r.insumo_id} className="border-b">
                  <td className="p-2 sticky left-0 bg-background font-medium">{r.nombre}</td>
                  {r.celdas.map((c) => (
                    <td key={c.sucursal_id} className="p-2 text-center tabular-nums align-top">
                      <div className="text-[11px] text-muted-foreground">
                        ex {num(c.existencia)} · pidió {num(c.solicitado)}
                      </div>
                      {c.detalleId ? (
                        <div className="flex items-center justify-center gap-1 my-1">
                          <button
                            type="button"
                            title="Usar lo que pidió la sucursal"
                            onClick={() => setPedido(c.detalleId as string, c.solicitado)}
                            className="text-muted-foreground hover:text-primary text-xs px-1"
                          >
                            ←
                          </button>
                          <Input
                            type="number"
                            inputMode="decimal"
                            value={c.pedidoReal === null ? "" : String(c.pedidoReal)}
                            onChange={(e) =>
                              setPedido(c.detalleId as string, e.target.value === "" ? 0 : parseFloat(e.target.value) || 0)
                            }
                            className="h-8 w-16 text-center font-semibold"
                          />
                        </div>
                      ) : (
                        <div className="text-muted-foreground/40 my-1">—</div>
                      )}
                    </td>
                  ))}
                  <td className="p-2 text-center font-semibold">{num(r.totalPed)}</td>
                </tr>
              ))}
              {!consolidado.length && (
                <tr><td colSpan={sucursales.length + 2} className="p-6 text-center text-muted-foreground">Sin pedidos ese día.</td></tr>
              )}
            </tbody>
          </table>
        </ScrollArea>
      </CardContent>
    </Card>
  );
}
