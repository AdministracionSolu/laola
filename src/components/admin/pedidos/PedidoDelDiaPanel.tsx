import { Fragment, useMemo, useState, useCallback } from "react";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Download, GitCompareArrows, Loader2 } from "lucide-react";
import { toast } from "sonner";
import { supabase } from "@/integrations/supabase/client";
import { exportarExcel } from "@/lib/exportar";
import { esSucursalReferencia, type SucursalLite, type PedidoDetLite } from "@/hooks/useAnaliticaPedidos";

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

  // Solares (GDL) va solo de referencia: compra con sus propios proveedores,
  // así que no se captura "a comprar" ni entra al total de Tepic.
  const idsReferencia = useMemo(
    () => new Set(sucursales.filter((s) => esSucursalReferencia(s.codigo)).map((s) => s.id)),
    [sucursales]
  );

  const pedidoRealDe = useCallback(
    (d: { id: string; cantidad_pedida: number }) => pedidoEdits[d.id] ?? (d.cantidad_pedida ?? 0),
    [pedidoEdits]
  );

  const setPedido = (detalleId: string, value: number) =>
    setPedidoEdits((prev) => ({ ...prev, [detalleId]: value }));

  const copiarSolicitados = () => {
    const next: Record<string, number> = {};
    pedidosDetalle
      .filter((d) => d.fecha === hasta && !idsReferencia.has(d.sucursal_id))
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
    if (pedMap.size === 0) return [];
    // TODOS los insumos de la lista, aunque nadie los haya pedido: la
    // existencia capturada también cuenta, y el "—" delata lo que no llenaron.
    return insumosOrden.map((ins) => {
      const celdas = sucursales.map((s) => {
        const det = pedMap.get(`${s.id}|${ins}`);
        return {
          sucursal_id: s.id,
          referencia: idsReferencia.has(s.id),
          detalleId: det?.id ?? null,
          existencia: det?.existencia ?? 0,
          solicitado: det?.cantidad_sugerida ?? 0,
          pedidoReal: det ? pedidoRealDe(det) : null,
        };
      });
      const totalPed = celdas.reduce((s, c) => s + (c.referencia ? 0 : c.pedidoReal ?? 0), 0);
      return { insumo_id: ins, nombre: nombreInsumo.get(ins) || ins, celdas, totalPed };
    });
  }, [hasta, pedidosDetalle, insumosOrden, sucursales, nombreInsumo, pedidoRealDe, idsReferencia]);

  // Cuántas existencias capturó cada sucursal (renglones guardados ese día).
  const capturadas = useMemo(() => {
    const m = new Map<string, number>();
    pedidosDetalle
      .filter((d) => d.fecha === hasta)
      .forEach((d) => m.set(d.sucursal_id, (m.get(d.sucursal_id) || 0) + 1));
    return m;
  }, [pedidosDetalle, hasta]);

  const exportar = () => {
    const filas = consolidado.map((r) => {
      const fila: Record<string, string | number> = { Insumo: r.nombre };
      r.celdas.forEach((c) => {
        const suc = sucursales.find((x) => x.id === c.sucursal_id);
        const s = (suc?.nombre || "") + (c.referencia ? " (referencia)" : "");
        fila[`${s} existencia`] = c.existencia;
        fila[`${s} pedido sugerido`] = c.solicitado;
        fila[`${s} a comprar`] = c.pedidoReal ?? "";
      });
      fila["Total a comprar (Tepic)"] = r.totalPed;
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
              Por sucursal: <b>Existencia</b> (cuánto tienen) · <b>Pedido sugerido</b> (cuánto solicitó la sucursal) · <b>A comprar</b> (cuánto se va a comprar; captura y guarda).
              Se muestra la lista completa: un <b>—</b> significa que la sucursal no capturó ese producto.
              <b> Solares</b> aparece solo de referencia (compra aparte en Guadalajara) y no entra al total.
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
        {/* Scroll horizontal nativo: la tabla es más ancha que la pantalla y
            todas las columnas (incluida "A comprar") deben poder verse. */}
        <div className="w-full overflow-x-auto whitespace-nowrap">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b text-xs text-muted-foreground">
                <th rowSpan={2} className="text-left p-2 sticky left-0 bg-background align-bottom">Insumo</th>
                {sucursales.map((s) => {
                  const ref = esSucursalReferencia(s.codigo);
                  return (
                    <th key={s.id} colSpan={3} className={`p-2 text-center border-l font-semibold ${ref ? "text-muted-foreground/70" : ""}`}>
                      {s.nombre}
                      <div className="font-normal text-[10px] text-muted-foreground">
                        {ref ? "referencia · compra aparte (GDL)" : `${capturadas.get(s.id) || 0}/${insumosOrden.length} existencias`}
                      </div>
                    </th>
                  );
                })}
                <th rowSpan={2} className="p-2 text-center align-bottom">
                  Total a comprar
                  <div className="font-normal text-[10px] text-muted-foreground">Tepic</div>
                </th>
              </tr>
              <tr className="border-b text-[11px] text-muted-foreground">
                {sucursales.map((s) => (
                  <Fragment key={s.id}>
                    <th className="p-1 text-center border-l">Existencia</th>
                    <th className="p-1 text-center">Pedido sugerido</th>
                    <th className="p-1 text-center min-w-[90px]">A comprar</th>
                  </Fragment>
                ))}
              </tr>
            </thead>
            <tbody>
              {consolidado.map((r) => (
                <tr key={r.insumo_id} className="border-b">
                  <td className="p-2 sticky left-0 bg-background font-medium">{r.nombre}</td>
                  {r.celdas.map((c) => (
                    <Fragment key={c.sucursal_id}>
                      <td className={`p-2 text-center tabular-nums border-l ${c.referencia ? "text-muted-foreground/70 bg-muted/30" : ""}`}>
                        {c.detalleId ? num(c.existencia) : <span className="text-muted-foreground/40">—</span>}
                      </td>
                      <td className={`p-2 text-center tabular-nums ${c.referencia ? "text-muted-foreground/70 bg-muted/30" : ""}`}>
                        {c.detalleId ? num(c.solicitado) : <span className="text-muted-foreground/40">—</span>}
                      </td>
                      <td className={`p-2 text-center ${c.referencia ? "bg-muted/30" : ""}`}>
                        {!c.detalleId ? (
                          <span className="text-muted-foreground/40">—</span>
                        ) : c.referencia ? (
                          <span className="tabular-nums text-muted-foreground/70">{num(c.pedidoReal ?? 0)}</span>
                        ) : (
                          <div className="flex items-center justify-center gap-1">
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
                        )}
                      </td>
                    </Fragment>
                  ))}
                  <td className="p-2 text-center font-semibold">{num(r.totalPed)}</td>
                </tr>
              ))}
              {!consolidado.length && (
                <tr><td colSpan={sucursales.length * 3 + 2} className="p-6 text-center text-muted-foreground">Sin pedidos ese día.</td></tr>
              )}
            </tbody>
          </table>
        </div>
      </CardContent>
    </Card>
  );
}
