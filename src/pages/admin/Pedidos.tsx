import { useEffect, useMemo, useState, useCallback } from "react";
import { useNavigate } from "react-router-dom";
import { supabase } from "@/integrations/supabase/client";
import { toast } from "sonner";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { ScrollArea } from "@/components/ui/scroll-area";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  ArrowLeft,
  RefreshCw,
  Download,
  Loader2,
  AlertTriangle,
  Grid3x3,
  TrafficCone,
  TrendingUp,
  GitCompareArrows,
  PackageCheck,
  Flame,
  DollarSign,
  Settings,
  ShieldAlert,
} from "lucide-react";
import { format, subDays } from "date-fns";
import {
  LineChart,
  Line,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip as RTooltip,
  ResponsiveContainer,
  Legend,
} from "recharts";
import logoLaOla from "@/assets/logo-la-ola.jpeg";
import { useAnaliticaPedidos } from "@/hooks/useAnaliticaPedidos";
import { exportarExcel } from "@/lib/exportar";
import { getFechaNegocio } from "@/lib/fecha";
import { ConfiguracionCatalogo } from "@/components/admin/pedidos/ConfiguracionCatalogo";

const money = (n: number) =>
  new Intl.NumberFormat("es-MX", { style: "currency", currency: "MXN" }).format(n);
const num = (n: number) => (Math.round(n * 100) / 100).toString();

const ESTADO_BADGE: Record<string, { label: string; cls: string }> = {
  sin: { label: "Sin pedido", cls: "bg-muted text-muted-foreground" },
  borrador: { label: "Borrador", cls: "bg-amber-100 text-amber-700" },
  enviado: { label: "Enviado", cls: "bg-blue-100 text-blue-700" },
  recibido: { label: "Recibido", cls: "bg-emerald-100 text-emerald-700" },
  recibido_parcial: { label: "Parcial", cls: "bg-orange-100 text-orange-700" },
  cerrado: { label: "Cerrado", cls: "bg-emerald-100 text-emerald-700" },
};

export default function AdminPedidos() {
  const navigate = useNavigate();
  const hoy = getFechaNegocio();
  const [desde, setDesde] = useState(format(subDays(new Date(), 27), "yyyy-MM-dd"));
  const [hasta, setHasta] = useState(hoy);

  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => {
      if (!session) navigate("/admin/login");
    });
  }, [navigate]);

  const {
    sucursales,
    lista,
    insumosMaster,
    pedidos,
    pedidosDetalle,
    recepcionesDetalle,
    loading,
    refetch,
  } = useAnaliticaPedidos(desde, hasta);

  // ---- Mapas auxiliares (catálogo maestro evita mostrar UUIDs) ----
  const nombreInsumo = useMemo(() => {
    const m = new Map<string, string>();
    insumosMaster.forEach((i) => m.set(i.id, i.nombre));
    lista.forEach((l) => m.set(l.insumo_id, l.nombre));
    return m;
  }, [insumosMaster, lista]);

  const unidadInsumo = useMemo(() => {
    const m = new Map<string, string>();
    insumosMaster.forEach((i) => m.set(i.id, i.unidad));
    lista.forEach((l) => m.set(l.insumo_id, l.unidad));
    return m;
  }, [insumosMaster, lista]);

  const costoMap = useMemo(() => {
    const m = new Map<string, number>();
    lista.forEach((l) => {
      if (l.costo != null) m.set(`${l.sucursal_id}|${l.insumo_id}`, l.costo);
    });
    return m;
  }, [lista]);

  // Insumos ordenados (union por catálogo)
  const insumosOrden = useMemo(() => {
    const seen = new Map<string, number>();
    lista.forEach((l) => {
      const cur = seen.get(l.insumo_id);
      if (cur === undefined || l.orden < cur) seen.set(l.insumo_id, l.orden);
    });
    return Array.from(seen.keys()).sort(
      (a, b) =>
        (seen.get(a)! - seen.get(b)!) ||
        (nombreInsumo.get(a) || "").localeCompare(nombreInsumo.get(b) || "")
    );
  }, [lista, nombreInsumo]);

  // Ediciones locales de "enviado" (admin) por id de detalle.
  const [enviadoEdits, setEnviadoEdits] = useState<Record<string, number>>({});
  const enviadoDe = useCallback(
    (d: { id: string; cantidad_enviada: number | null }) =>
      enviadoEdits[d.id] ?? (d.cantidad_enviada ?? null),
    [enviadoEdits]
  );

  const saveEnviado = async (detalleId: string, value: number) => {
    const { error } = await supabase
      .from("pedidos_detalle")
      .update({ cantidad_enviada: value })
      .eq("id", detalleId);
    if (error) {
      toast.error("No se pudo guardar lo enviado");
      return;
    }
    setEnviadoEdits((prev) => ({ ...prev, [detalleId]: value }));
    toast.success("Envío guardado");
  };

  // ============ 1) Consolidado del día (matriz) ============
  const consolidado = useMemo(() => {
    const dia = hasta;
    const pedMap = new Map<string, (typeof pedidosDetalle)[number]>();
    pedidosDetalle
      .filter((d) => d.fecha === dia)
      .forEach((d) => pedMap.set(`${d.sucursal_id}|${d.insumo_id}`, d));
    const recMap = new Map<string, number>();
    recepcionesDetalle
      .filter((d) => d.fecha === dia)
      .forEach((d) =>
        recMap.set(
          `${d.sucursal_id}|${d.insumo_id}`,
          (recMap.get(`${d.sucursal_id}|${d.insumo_id}`) || 0) + d.cantidad_recibida
        )
      );

    return insumosOrden
      .map((ins) => {
        const celdas = sucursales.map((s) => {
          const det = pedMap.get(`${s.id}|${ins}`);
          return {
            sucursal_id: s.id,
            detalleId: det?.id ?? null,
            existencia: det?.existencia ?? 0,
            pedido: det?.cantidad_pedida ?? 0,
            enviado: det ? enviadoDe(det) : null,
            recibido: recMap.get(`${s.id}|${ins}`) ?? 0,
          };
        });
        const totalPed = celdas.reduce((s, c) => s + c.pedido, 0);
        const totalRec = celdas.reduce((s, c) => s + c.recibido, 0);
        return { insumo_id: ins, nombre: nombreInsumo.get(ins) || ins, celdas, totalPed, totalRec };
      })
      .filter(
        (r) =>
          r.totalPed > 0 ||
          r.totalRec > 0 ||
          r.celdas.some((c) => c.enviado != null && c.enviado > 0)
      );
  }, [hasta, pedidosDetalle, recepcionesDetalle, insumosOrden, sucursales, nombreInsumo, enviadoDe]);

  const exportConsolidado = () => {
    const filas = consolidado.map((r) => {
      const fila: Record<string, string | number> = { Insumo: r.nombre };
      r.celdas.forEach((c) => {
        const s = sucursales.find((x) => x.id === c.sucursal_id)?.nombre || "";
        fila[`${s} existencia`] = c.existencia;
        fila[`${s} pedido`] = c.pedido;
        fila[`${s} enviado`] = c.enviado ?? "";
        fila[`${s} recibido`] = c.recibido;
      });
      fila["Total pedido"] = r.totalPed;
      fila["Total recibido"] = r.totalRec;
      return fila;
    });
    exportarExcel(filas, `consolidado_${hasta}`, "Consolidado");
  };

  // ============ Fugas: Enviado (admin) vs Recibido (sucursal) ============
  const fugas = useMemo(() => {
    const env = new Map<string, number>();
    pedidosDetalle.forEach((d) => {
      const e = enviadoDe(d);
      if (e != null)
        env.set(`${d.sucursal_id}|${d.insumo_id}`, (env.get(`${d.sucursal_id}|${d.insumo_id}`) || 0) + e);
    });
    const rec = new Map<string, number>();
    recepcionesDetalle.forEach((d) =>
      rec.set(
        `${d.sucursal_id}|${d.insumo_id}`,
        (rec.get(`${d.sucursal_id}|${d.insumo_id}`) || 0) + d.cantidad_recibida
      )
    );
    const keys = new Set([...env.keys(), ...rec.keys()]);
    return Array.from(keys)
      .map((k) => {
        const [suc, ins] = k.split("|");
        const enviado = env.get(k) || 0;
        const recibido = rec.get(k) || 0;
        return {
          sucursal: sucursales.find((s) => s.id === suc)?.nombre || "",
          insumo: nombreInsumo.get(ins) || ins,
          enviado,
          recibido,
          diferencia: enviado - recibido,
        };
      })
      .filter((r) => r.enviado > 0 || r.recibido > 0)
      .sort((a, b) => Math.abs(b.diferencia) - Math.abs(a.diferencia));
  }, [pedidosDetalle, recepcionesDetalle, sucursales, nombreInsumo, enviadoDe]);

  // ============ 2) Semáforo de estados ============
  const semaforo = useMemo(() => {
    const dia = hasta;
    const prioridad: Record<string, number> = {
      borrador: 0,
      enviado: 1,
      recibido_parcial: 2,
      recibido: 3,
      cerrado: 4,
    };
    return sucursales.map((s) => {
      const ped = pedidos.filter((p) => p.sucursal_id === s.id && p.fecha === dia);
      // El estado más avanzado del día (robusto si hubiera más de un pedido).
      const estado = ped.length
        ? ped.reduce((acc, p) =>
            (prioridad[p.estado] ?? -1) > (prioridad[acc.estado] ?? -1) ? p : acc
          ).estado
        : "sin";
      return { sucursal: s.nombre, estado };
    });
  }, [hasta, sucursales, pedidos]);

  // ============ 3) Tendencia por insumo ============
  const [insumoTend, setInsumoTend] = useState<string>("");
  useEffect(() => {
    if (!insumoTend && insumosOrden.length) setInsumoTend(insumosOrden[0]);
  }, [insumosOrden, insumoTend]);

  const tendencia = useMemo(() => {
    const porFecha = new Map<string, number>();
    pedidosDetalle
      .filter((d) => d.insumo_id === insumoTend)
      .forEach((d) => porFecha.set(d.fecha, (porFecha.get(d.fecha) || 0) + d.cantidad_pedida));
    return Array.from(porFecha.entries())
      .sort((a, b) => a[0].localeCompare(b[0]))
      .map(([fecha, pedido]) => ({ fecha: fecha.slice(5), pedido }));
  }, [pedidosDetalle, insumoTend]);

  const promedioTend = tendencia.length
    ? tendencia.reduce((s, t) => s + t.pedido, 0) / tendencia.length
    : 0;

  // ============ 4) Sugerido vs Pedido ============
  const sugeridoVsPedido = useMemo(() => {
    const agg = new Map<string, { sug: number; ped: number }>();
    pedidosDetalle.forEach((d) => {
      const cur = agg.get(d.insumo_id) || { sug: 0, ped: 0 };
      cur.sug += d.cantidad_sugerida ?? 0;
      cur.ped += d.cantidad_pedida;
      agg.set(d.insumo_id, cur);
    });
    return Array.from(agg.entries())
      .map(([ins, v]) => ({
        insumo: nombreInsumo.get(ins) || ins,
        sugerido: v.sug,
        pedido: v.ped,
        desviacion: v.ped - v.sug,
      }))
      .sort((a, b) => Math.abs(b.desviacion) - Math.abs(a.desviacion));
  }, [pedidosDetalle, nombreInsumo]);

  // ============ 5) Pedido vs Recibido (fill rate) ============
  const pedidoVsRecibido = useMemo(() => {
    const ped = new Map<string, number>();
    const rec = new Map<string, number>();
    pedidosDetalle.forEach((d) =>
      ped.set(d.insumo_id, (ped.get(d.insumo_id) || 0) + d.cantidad_pedida)
    );
    recepcionesDetalle.forEach((d) =>
      rec.set(d.insumo_id, (rec.get(d.insumo_id) || 0) + d.cantidad_recibida)
    );
    const ids = new Set([...ped.keys(), ...rec.keys()]);
    return Array.from(ids)
      .map((ins) => {
        const p = ped.get(ins) || 0;
        const r = rec.get(ins) || 0;
        return {
          insumo: nombreInsumo.get(ins) || ins,
          pedido: p,
          recibido: r,
          fill: p > 0 ? Math.round((r / p) * 100) : 0,
        };
      })
      .filter((x) => x.pedido > 0)
      .sort((a, b) => a.fill - b.fill);
  }, [pedidosDetalle, recepcionesDetalle, nombreInsumo]);

  // ============ 6) Consumo estimado ============
  // existencia(d) + recibido(d) - existencia(d+1) por (sucursal, insumo)
  const consumo = useMemo(() => {
    // Recepciones por (sucursal, insumo) → lista de {fecha, qty}
    const recList = new Map<string, { fecha: string; qty: number }[]>();
    recepcionesDetalle.forEach((d) => {
      const k = `${d.sucursal_id}|${d.insumo_id}`;
      const arr = recList.get(k) || [];
      arr.push({ fecha: d.fecha, qty: d.cantidad_recibida });
      recList.set(k, arr);
    });
    // Existencias por (sucursal, insumo) ordenadas por fecha de conteo
    const series = new Map<string, { fecha: string; exist: number }[]>();
    pedidosDetalle.forEach((d) => {
      const k = `${d.sucursal_id}|${d.insumo_id}`;
      const arr = series.get(k) || [];
      arr.push({ fecha: d.fecha, exist: d.existencia });
      series.set(k, arr);
    });
    const consumoIns = new Map<string, number>();
    series.forEach((arr, k) => {
      const ins = k.split("|")[1];
      const recs = recList.get(k) || [];
      arr.sort((a, b) => a.fecha.localeCompare(b.fecha));
      for (let i = 0; i < arr.length - 1; i++) {
        // Recepciones que llegaron entre este conteo (incl.) y el siguiente (excl.).
        const rec = recs
          .filter((r) => r.fecha >= arr[i].fecha && r.fecha < arr[i + 1].fecha)
          .reduce((s, r) => s + r.qty, 0);
        const c = arr[i].exist + rec - arr[i + 1].exist;
        if (c > 0) consumoIns.set(ins, (consumoIns.get(ins) || 0) + c);
      }
    });
    return Array.from(consumoIns.entries())
      .map(([ins, c]) => ({ insumo: nombreInsumo.get(ins) || ins, consumo: Math.round(c * 100) / 100 }))
      .sort((a, b) => b.consumo - a.consumo);
  }, [pedidosDetalle, recepcionesDetalle, nombreInsumo]);

  // ============ 7) Anomalías ============
  const [umbral, setUmbral] = useState(50); // % sobre el promedio
  const anomalias = useMemo(() => {
    // promedio por (sucursal, insumo)
    const sums = new Map<string, { total: number; n: number }>();
    pedidosDetalle.forEach((d) => {
      const k = `${d.sucursal_id}|${d.insumo_id}`;
      const cur = sums.get(k) || { total: 0, n: 0 };
      cur.total += d.cantidad_pedida;
      cur.n += 1;
      sums.set(k, cur);
    });
    const out: { fecha: string; sucursal: string; insumo: string; pedido: number; promedio: number }[] = [];
    pedidosDetalle.forEach((d) => {
      const k = `${d.sucursal_id}|${d.insumo_id}`;
      const s = sums.get(k);
      if (!s || s.n < 2) return;
      const prom = s.total / s.n;
      if (prom > 0 && d.cantidad_pedida > prom * (1 + umbral / 100)) {
        out.push({
          fecha: d.fecha,
          sucursal: sucursales.find((x) => x.id === d.sucursal_id)?.nombre || "",
          insumo: nombreInsumo.get(d.insumo_id) || d.insumo_id,
          pedido: d.cantidad_pedida,
          promedio: Math.round(prom * 100) / 100,
        });
      }
    });
    return out.sort((a, b) => b.fecha.localeCompare(a.fecha));
  }, [pedidosDetalle, umbral, sucursales, nombreInsumo]);

  // ============ 8) Gasto ============
  const gasto = useMemo(() => {
    const porInsumo = new Map<string, { gasto: number; vol: number }>();
    const porSucursal = new Map<string, number>();
    let total = 0;
    pedidosDetalle.forEach((d) => {
      const costo = costoMap.get(`${d.sucursal_id}|${d.insumo_id}`) || 0;
      const g = d.cantidad_pedida * costo;
      total += g;
      const ci = porInsumo.get(d.insumo_id) || { gasto: 0, vol: 0 };
      ci.gasto += g;
      ci.vol += d.cantidad_pedida;
      porInsumo.set(d.insumo_id, ci);
      porSucursal.set(d.sucursal_id, (porSucursal.get(d.sucursal_id) || 0) + g);
    });
    const insumos = Array.from(porInsumo.entries())
      .map(([ins, v]) => ({ insumo: nombreInsumo.get(ins) || ins, gasto: v.gasto, vol: v.vol }))
      .sort((a, b) => b.gasto - a.gasto);
    const sucs = sucursales.map((s) => ({
      sucursal: s.nombre,
      gasto: porSucursal.get(s.id) || 0,
    }));
    return { insumos, sucs, total };
  }, [pedidosDetalle, costoMap, nombreInsumo, sucursales]);

  const tieneCostos = lista.some((l) => l.costo != null);

  return (
    <div className="min-h-screen bg-gradient-to-br from-primary/5 to-secondary/10">
      <div className="bg-background border-b sticky top-0 z-10">
        <div className="container mx-auto px-3 py-2 flex items-center gap-3">
          <Button variant="ghost" size="icon" onClick={() => navigate("/admin/dashboard")}>
            <ArrowLeft className="h-5 w-5" />
          </Button>
          <img src={logoLaOla} alt="La Ola" className="w-8 h-8 rounded-full object-cover" />
          <div className="flex-1">
            <h1 className="text-base font-semibold">Insumos & Pedidos</h1>
            <p className="text-xs text-muted-foreground">Analítica de compras por sucursal</p>
          </div>
          <Button variant="ghost" size="icon" onClick={refetch}>
            <RefreshCw className="h-4 w-4" />
          </Button>
        </div>
        {/* Rango de fechas */}
        <div className="container mx-auto px-3 pb-2 flex flex-wrap items-end gap-3">
          <div className="space-y-1">
            <Label className="text-xs">Desde</Label>
            <Input type="date" value={desde} max={hasta} onChange={(e) => setDesde(e.target.value)} className="h-9 w-40" />
          </div>
          <div className="space-y-1">
            <Label className="text-xs">Hasta</Label>
            <Input type="date" value={hasta} min={desde} onChange={(e) => setHasta(e.target.value)} className="h-9 w-40" />
          </div>
        </div>
      </div>

      <div className="container mx-auto px-3 py-4 max-w-5xl">
        {loading ? (
          <div className="flex justify-center py-16">
            <Loader2 className="h-8 w-8 animate-spin text-primary" />
          </div>
        ) : (
          <Tabs defaultValue="consolidado">
            <ScrollArea className="w-full whitespace-nowrap">
              <TabsList className="inline-flex w-max mb-4">
                <TabsTrigger value="consolidado" className="gap-1 text-xs"><Grid3x3 className="h-3.5 w-3.5" />Consolidado</TabsTrigger>
                <TabsTrigger value="estados" className="gap-1 text-xs"><TrafficCone className="h-3.5 w-3.5" />Estados</TabsTrigger>
                <TabsTrigger value="tendencia" className="gap-1 text-xs"><TrendingUp className="h-3.5 w-3.5" />Tendencia</TabsTrigger>
                <TabsTrigger value="sugerido" className="gap-1 text-xs"><GitCompareArrows className="h-3.5 w-3.5" />Sugerido</TabsTrigger>
                <TabsTrigger value="fill" className="gap-1 text-xs"><PackageCheck className="h-3.5 w-3.5" />Recibido</TabsTrigger>
                <TabsTrigger value="fugas" className="gap-1 text-xs"><ShieldAlert className="h-3.5 w-3.5" />Fugas</TabsTrigger>
                <TabsTrigger value="consumo" className="gap-1 text-xs"><Flame className="h-3.5 w-3.5" />Consumo</TabsTrigger>
                <TabsTrigger value="anomalias" className="gap-1 text-xs"><AlertTriangle className="h-3.5 w-3.5" />Anomalías</TabsTrigger>
                <TabsTrigger value="gasto" className="gap-1 text-xs"><DollarSign className="h-3.5 w-3.5" />Gasto</TabsTrigger>
                <TabsTrigger value="config" className="gap-1 text-xs"><Settings className="h-3.5 w-3.5" />Configuración</TabsTrigger>
              </TabsList>
            </ScrollArea>

            {/* 1) Consolidado */}
            <TabsContent value="consolidado">
              <Card>
                <CardHeader className="pb-2 flex-row items-center justify-between">
                  <div>
                    <CardTitle className="text-sm">Consolidado del {hasta}</CardTitle>
                    <CardDescription className="text-xs">
                      Cada celda: <b>ex</b>istencia · lo que <b>pide</b> · <b>casilla editable: cuánto envías</b> · lo que <b>rec</b>ibió. En rojo si recibido ≠ enviado.
                    </CardDescription>
                  </div>
                  <Button size="sm" variant="outline" className="gap-1" onClick={exportConsolidado} disabled={!consolidado.length}>
                    <Download className="h-4 w-4" /> Excel
                  </Button>
                </CardHeader>
                <CardContent className="p-0">
                  <ScrollArea className="w-full whitespace-nowrap">
                    <table className="w-full text-sm">
                      <thead>
                        <tr className="border-b text-xs text-muted-foreground">
                          <th className="text-left p-2 sticky left-0 bg-background">Insumo</th>
                          {sucursales.map((s) => (
                            <th key={s.id} className="p-2 text-center min-w-[90px]">{s.nombre}</th>
                          ))}
                          <th className="p-2 text-center">Total</th>
                        </tr>
                      </thead>
                      <tbody>
                        {consolidado.map((r) => (
                          <tr key={r.insumo_id} className="border-b">
                            <td className="p-2 sticky left-0 bg-background font-medium">{r.nombre}</td>
                            {r.celdas.map((c) => {
                              const fuga = c.enviado != null && c.enviado !== c.recibido && (c.enviado > 0 || c.recibido > 0);
                              return (
                                <td key={c.sucursal_id} className="p-2 text-center tabular-nums align-top">
                                  <div className="text-[11px] text-muted-foreground">
                                    ex {num(c.existencia)} · pide {num(c.pedido)}
                                  </div>
                                  {c.detalleId ? (
                                    <Input
                                      type="number"
                                      inputMode="decimal"
                                      defaultValue={c.enviado ?? ""}
                                      placeholder={`→${num(c.pedido)}`}
                                      title="Cuánto envías realmente"
                                      onBlur={(e) =>
                                        saveEnviado(
                                          c.detalleId as string,
                                          e.target.value === "" ? 0 : parseFloat(e.target.value) || 0
                                        )
                                      }
                                      className="h-8 w-16 mx-auto my-1 text-center font-semibold"
                                    />
                                  ) : (
                                    <div className="text-muted-foreground/40 my-1">—</div>
                                  )}
                                  <div className={`text-[11px] ${fuga ? "text-red-600 font-semibold" : "text-muted-foreground"}`}>
                                    rec {num(c.recibido)}
                                  </div>
                                </td>
                              );
                            })}
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
            </TabsContent>

            {/* 2) Estados */}
            <TabsContent value="estados">
              <Card>
                <CardHeader className="pb-2">
                  <CardTitle className="text-sm">Semáforo de estados — {hasta}</CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="grid sm:grid-cols-2 gap-3">
                    {semaforo.map((s) => {
                      const b = ESTADO_BADGE[s.estado] || ESTADO_BADGE.sin;
                      return (
                        <div key={s.sucursal} className="flex items-center justify-between border rounded-lg p-3">
                          <span className="font-medium">{s.sucursal}</span>
                          <span className={`text-xs px-2.5 py-1 rounded-full font-medium ${b.cls}`}>{b.label}</span>
                        </div>
                      );
                    })}
                  </div>
                </CardContent>
              </Card>
            </TabsContent>

            {/* 3) Tendencia */}
            <TabsContent value="tendencia">
              <Card>
                <CardHeader className="pb-2 flex-row items-center justify-between gap-2">
                  <CardTitle className="text-sm">Tendencia de pedido</CardTitle>
                  <Select value={insumoTend} onValueChange={setInsumoTend}>
                    <SelectTrigger className="w-48"><SelectValue /></SelectTrigger>
                    <SelectContent>
                      {insumosOrden.map((ins) => (
                        <SelectItem key={ins} value={ins}>{nombreInsumo.get(ins)}</SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </CardHeader>
                <CardContent>
                  {tendencia.length ? (
                    <ResponsiveContainer width="100%" height={280}>
                      <LineChart data={tendencia}>
                        <CartesianGrid strokeDasharray="3 3" className="stroke-muted" />
                        <XAxis dataKey="fecha" fontSize={12} />
                        <YAxis fontSize={12} />
                        <RTooltip />
                        <Line type="monotone" dataKey="pedido" stroke="hsl(var(--primary))" strokeWidth={2} name="Pedido" />
                      </LineChart>
                    </ResponsiveContainer>
                  ) : (
                    <p className="text-center text-muted-foreground py-10 text-sm">Sin datos en el periodo.</p>
                  )}
                  <p className="text-xs text-muted-foreground mt-2">
                    Promedio en el periodo: <strong>{num(promedioTend)} {unidadInsumo.get(insumoTend)}</strong>
                  </p>
                </CardContent>
              </Card>
            </TabsContent>

            {/* 4) Sugerido vs Pedido */}
            <TabsContent value="sugerido">
              <Card>
                <CardHeader className="pb-2 flex-row items-center justify-between">
                  <CardTitle className="text-sm">Sugerido vs Pedido</CardTitle>
                  <Button size="sm" variant="outline" className="gap-1" onClick={() => exportarExcel(sugeridoVsPedido, `sugerido_vs_pedido_${desde}_${hasta}`)} disabled={!sugeridoVsPedido.length}>
                    <Download className="h-4 w-4" /> Excel
                  </Button>
                </CardHeader>
                <CardContent className="p-0">
                  <table className="w-full text-sm">
                    <thead><tr className="border-b text-xs text-muted-foreground">
                      <th className="text-left p-2">Insumo</th><th className="p-2 text-center">Sugerido</th><th className="p-2 text-center">Pedido</th><th className="p-2 text-center">Desviación</th>
                    </tr></thead>
                    <tbody>
                      {sugeridoVsPedido.map((r) => (
                        <tr key={r.insumo} className="border-b">
                          <td className="p-2 font-medium">{r.insumo}</td>
                          <td className="p-2 text-center">{num(r.sugerido)}</td>
                          <td className="p-2 text-center">{num(r.pedido)}</td>
                          <td className={`p-2 text-center font-semibold ${r.desviacion > 0 ? "text-orange-600" : r.desviacion < 0 ? "text-blue-600" : ""}`}>
                            {r.desviacion > 0 ? "+" : ""}{num(r.desviacion)}
                          </td>
                        </tr>
                      ))}
                      {!sugeridoVsPedido.length && <tr><td colSpan={4} className="p-6 text-center text-muted-foreground">Sin datos.</td></tr>}
                    </tbody>
                  </table>
                </CardContent>
              </Card>
            </TabsContent>

            {/* 5) Pedido vs Recibido */}
            <TabsContent value="fill">
              <Card>
                <CardHeader className="pb-2 flex-row items-center justify-between">
                  <div>
                    <CardTitle className="text-sm">Pedido vs Recibido</CardTitle>
                    <CardDescription className="text-xs">Fill rate del proveedor</CardDescription>
                  </div>
                  <Button size="sm" variant="outline" className="gap-1" onClick={() => exportarExcel(pedidoVsRecibido, `pedido_vs_recibido_${desde}_${hasta}`)} disabled={!pedidoVsRecibido.length}>
                    <Download className="h-4 w-4" /> Excel
                  </Button>
                </CardHeader>
                <CardContent className="p-0">
                  <table className="w-full text-sm">
                    <thead><tr className="border-b text-xs text-muted-foreground">
                      <th className="text-left p-2">Insumo</th><th className="p-2 text-center">Pedido</th><th className="p-2 text-center">Recibido</th><th className="p-2 text-center">Fill</th>
                    </tr></thead>
                    <tbody>
                      {pedidoVsRecibido.map((r) => (
                        <tr key={r.insumo} className="border-b">
                          <td className="p-2 font-medium">{r.insumo}</td>
                          <td className="p-2 text-center">{num(r.pedido)}</td>
                          <td className="p-2 text-center">{num(r.recibido)}</td>
                          <td className="p-2 text-center">
                            <Badge variant={r.fill >= 100 ? "default" : r.fill >= 80 ? "secondary" : "destructive"}>{r.fill}%</Badge>
                          </td>
                        </tr>
                      ))}
                      {!pedidoVsRecibido.length && <tr><td colSpan={4} className="p-6 text-center text-muted-foreground">Sin datos.</td></tr>}
                    </tbody>
                  </table>
                </CardContent>
              </Card>
            </TabsContent>

            {/* Fugas: Enviado (admin) vs Recibido (sucursal) */}
            <TabsContent value="fugas">
              <Card>
                <CardHeader className="pb-2 flex-row items-center justify-between">
                  <div>
                    <CardTitle className="text-sm">Fugas — Enviado vs Recibido</CardTitle>
                    <CardDescription className="text-xs">
                      Lo que el admin declaró que envió vs lo que la sucursal dice que recibió. Diferencia &gt; 0 = no llegó todo.
                    </CardDescription>
                  </div>
                  <Button size="sm" variant="outline" className="gap-1" onClick={() => exportarExcel(fugas, `fugas_${desde}_${hasta}`)} disabled={!fugas.length}>
                    <Download className="h-4 w-4" /> Excel
                  </Button>
                </CardHeader>
                <CardContent className="p-0">
                  <table className="w-full text-sm">
                    <thead><tr className="border-b text-xs text-muted-foreground">
                      <th className="text-left p-2">Sucursal</th><th className="text-left p-2">Insumo</th><th className="p-2 text-center">Enviado</th><th className="p-2 text-center">Recibido</th><th className="p-2 text-center">Diferencia</th>
                    </tr></thead>
                    <tbody>
                      {fugas.map((r, i) => (
                        <tr key={i} className="border-b">
                          <td className="p-2">{r.sucursal}</td>
                          <td className="p-2 font-medium">{r.insumo}</td>
                          <td className="p-2 text-center">{num(r.enviado)}</td>
                          <td className="p-2 text-center">{num(r.recibido)}</td>
                          <td className={`p-2 text-center font-semibold ${r.diferencia > 0 ? "text-red-600" : r.diferencia < 0 ? "text-amber-600" : "text-emerald-600"}`}>
                            {r.diferencia > 0 ? "+" : ""}{num(r.diferencia)}
                          </td>
                        </tr>
                      ))}
                      {!fugas.length && <tr><td colSpan={5} className="p-6 text-center text-muted-foreground">Captura lo enviado en el Consolidado para ver fugas.</td></tr>}
                    </tbody>
                  </table>
                </CardContent>
              </Card>
            </TabsContent>

            {/* 6) Consumo */}
            <TabsContent value="consumo">
              <Card>
                <CardHeader className="pb-2 flex-row items-center justify-between">
                  <div>
                    <CardTitle className="text-sm">Consumo estimado</CardTitle>
                    <CardDescription className="text-xs">existencia + recibido − existencia del siguiente conteo</CardDescription>
                  </div>
                  <Button size="sm" variant="outline" className="gap-1" onClick={() => exportarExcel(consumo, `consumo_${desde}_${hasta}`)} disabled={!consumo.length}>
                    <Download className="h-4 w-4" /> Excel
                  </Button>
                </CardHeader>
                <CardContent className="p-0">
                  <table className="w-full text-sm">
                    <thead><tr className="border-b text-xs text-muted-foreground">
                      <th className="text-left p-2">Insumo</th><th className="p-2 text-center">Consumo estimado</th>
                    </tr></thead>
                    <tbody>
                      {consumo.map((r) => (
                        <tr key={r.insumo} className="border-b">
                          <td className="p-2 font-medium">{r.insumo}</td>
                          <td className="p-2 text-center">{num(r.consumo)}</td>
                        </tr>
                      ))}
                      {!consumo.length && <tr><td colSpan={2} className="p-6 text-center text-muted-foreground">Se necesita existencia de días consecutivos para estimar consumo.</td></tr>}
                    </tbody>
                  </table>
                </CardContent>
              </Card>
            </TabsContent>

            {/* 7) Anomalías */}
            <TabsContent value="anomalias">
              <Card>
                <CardHeader className="pb-2 flex-row items-center justify-between gap-2">
                  <CardTitle className="text-sm">Anomalías de pedido</CardTitle>
                  <div className="flex items-center gap-2">
                    <Label className="text-xs">Umbral %</Label>
                    <Input type="number" value={umbral} onChange={(e) => setUmbral(parseInt(e.target.value) || 0)} className="h-9 w-20" />
                  </div>
                </CardHeader>
                <CardContent className="p-0">
                  <table className="w-full text-sm">
                    <thead><tr className="border-b text-xs text-muted-foreground">
                      <th className="text-left p-2">Fecha</th><th className="text-left p-2">Sucursal</th><th className="text-left p-2">Insumo</th><th className="p-2 text-center">Pedido</th><th className="p-2 text-center">Promedio</th>
                    </tr></thead>
                    <tbody>
                      {anomalias.map((a, i) => (
                        <tr key={i} className="border-b">
                          <td className="p-2">{a.fecha}</td>
                          <td className="p-2">{a.sucursal}</td>
                          <td className="p-2 font-medium">{a.insumo}</td>
                          <td className="p-2 text-center text-orange-600 font-semibold">{num(a.pedido)}</td>
                          <td className="p-2 text-center text-muted-foreground">{num(a.promedio)}</td>
                        </tr>
                      ))}
                      {!anomalias.length && <tr><td colSpan={5} className="p-6 text-center text-muted-foreground">Sin anomalías sobre el umbral.</td></tr>}
                    </tbody>
                  </table>
                </CardContent>
              </Card>
            </TabsContent>

            {/* 8) Gasto */}
            <TabsContent value="gasto">
              {!tieneCostos && (
                <Card className="mb-3 border-amber-300 bg-amber-50">
                  <CardContent className="p-3 text-sm text-amber-800">
                    Aún no hay costos capturados. Agrégalos en <strong>Configuración</strong> para ver el gasto.
                  </CardContent>
                </Card>
              )}
              <div className="grid md:grid-cols-2 gap-4">
                <Card>
                  <CardHeader className="pb-2">
                    <CardTitle className="text-sm">Gasto por sucursal</CardTitle>
                    <CardDescription className="text-xs">Total periodo: {money(gasto.total)}</CardDescription>
                  </CardHeader>
                  <CardContent>
                    <ResponsiveContainer width="100%" height={240}>
                      <BarChart data={gasto.sucs}>
                        <CartesianGrid strokeDasharray="3 3" className="stroke-muted" />
                        <XAxis dataKey="sucursal" fontSize={12} />
                        <YAxis fontSize={12} />
                        <RTooltip formatter={(v: number) => money(v)} />
                        <Bar dataKey="gasto" fill="hsl(var(--primary))" name="Gasto" />
                      </BarChart>
                    </ResponsiveContainer>
                  </CardContent>
                </Card>
                <Card>
                  <CardHeader className="pb-2 flex-row items-center justify-between">
                    <CardTitle className="text-sm">Top insumos por gasto</CardTitle>
                    <Button size="sm" variant="outline" className="gap-1" onClick={() => exportarExcel(gasto.insumos.map((i) => ({ Insumo: i.insumo, Volumen: i.vol, Gasto: i.gasto })), `gasto_${desde}_${hasta}`)} disabled={!gasto.insumos.length}>
                      <Download className="h-4 w-4" /> Excel
                    </Button>
                  </CardHeader>
                  <CardContent className="p-0">
                    <ScrollArea className="h-[240px]">
                      <table className="w-full text-sm">
                        <thead><tr className="border-b text-xs text-muted-foreground">
                          <th className="text-left p-2">Insumo</th><th className="p-2 text-center">Vol.</th><th className="p-2 text-right">Gasto</th>
                        </tr></thead>
                        <tbody>
                          {gasto.insumos.map((r) => (
                            <tr key={r.insumo} className="border-b">
                              <td className="p-2 font-medium">{r.insumo}</td>
                              <td className="p-2 text-center">{num(r.vol)}</td>
                              <td className="p-2 text-right">{money(r.gasto)}</td>
                            </tr>
                          ))}
                          {!gasto.insumos.length && <tr><td colSpan={3} className="p-6 text-center text-muted-foreground">Sin datos.</td></tr>}
                        </tbody>
                      </table>
                    </ScrollArea>
                  </CardContent>
                </Card>
              </div>
            </TabsContent>

            {/* 9) Configuración */}
            <TabsContent value="config">
              <ConfiguracionCatalogo />
            </TabsContent>
          </Tabs>
        )}
      </div>
    </div>
  );
}
