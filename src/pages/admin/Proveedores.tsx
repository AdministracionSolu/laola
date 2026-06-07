import { useEffect, useState, useMemo, useCallback } from "react";
import { useNavigate } from "react-router-dom";
import { supabase } from "@/integrations/supabase/client";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { ScrollArea } from "@/components/ui/scroll-area";
import {
  Select, SelectContent, SelectItem, SelectTrigger, SelectValue,
} from "@/components/ui/select";
import { ArrowLeft, RefreshCw, Copy, Loader2, Scale, Link2, GitMerge, Download } from "lucide-react";
import { toast } from "sonner";
import logoLaOla from "@/assets/logo-la-ola.jpeg";
import { infoProteina, esProteina } from "@/lib/proteinas";
import { exportarExcel } from "@/lib/exportar";

const money = (n: number) =>
  new Intl.NumberFormat("es-MX", { style: "currency", currency: "MXN" }).format(n);

interface Proveedor {
  id: string; nombre: string; categoria: string | null;
  contacto: string | null; telefono: string | null; token: string; activo: boolean;
}
interface Producto {
  id: string; proveedor_id: string; nombre: string; unidad: string | null; insumo_id: string | null;
}
interface PrecioRow { proveedor_producto_id: string; precio: number; created_at: string; }
interface InsumoLite { id: string; nombre: string; }

export default function AdminProveedores() {
  const navigate = useNavigate();
  const [loading, setLoading] = useState(true);
  const [proveedores, setProveedores] = useState<Proveedor[]>([]);
  const [productos, setProductos] = useState<Producto[]>([]);
  const [precios, setPrecios] = useState<PrecioRow[]>([]);
  const [insumos, setInsumos] = useState<InsumoLite[]>([]);

  const fetchAll = useCallback(async () => {
    setLoading(true);
    const [provRes, prodRes, preRes, insRes] = await Promise.all([
      supabase.from("proveedores").select("*").order("categoria").order("nombre"),
      supabase.from("proveedor_productos").select("id, proveedor_id, nombre, unidad, insumo_id"),
      supabase.from("proveedor_precios").select("proveedor_producto_id, precio, created_at").order("created_at", { ascending: false }),
      supabase.from("insumos").select("id, nombre").eq("activo", true),
    ]);
    setProveedores((provRes.data ?? []) as Proveedor[]);
    setProductos((prodRes.data ?? []) as Producto[]);
    setPrecios((preRes.data ?? []) as PrecioRow[]);
    setInsumos(((insRes.data ?? []) as InsumoLite[]).filter((i) => esProteina(i.nombre)));
    setLoading(false);
  }, []);

  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => {
      if (!session) navigate("/admin/login");
      else fetchAll();
    });
  }, [navigate, fetchAll]);

  // Precio vigente por producto (el más reciente; precios viene ordenado desc).
  const vigentePorProducto = useMemo(() => {
    const m = new Map<string, { precio: number; fecha: string }>();
    precios.forEach((p) => {
      if (!m.has(p.proveedor_producto_id))
        m.set(p.proveedor_producto_id, { precio: Number(p.precio), fecha: p.created_at });
    });
    return m;
  }, [precios]);

  const provById = useMemo(() => new Map(proveedores.map((p) => [p.id, p])), [proveedores]);
  const nombreInterno = (id: string) => {
    const i = insumos.find((x) => x.id === id);
    return i ? (infoProteina(i.nombre)?.display ?? i.nombre) : "—";
  };

  // ---- Comparativa por insumo interno ----
  const comparativa = useMemo(() => {
    const porInsumo = new Map<string, { proveedor: string; producto: string; precio: number; unidad: string }[]>();
    productos.forEach((prod) => {
      if (!prod.insumo_id) return;
      const vig = vigentePorProducto.get(prod.id);
      if (!vig) return;
      const arr = porInsumo.get(prod.insumo_id) || [];
      arr.push({
        proveedor: provById.get(prod.proveedor_id)?.nombre || "—",
        producto: prod.nombre,
        precio: vig.precio,
        unidad: prod.unidad || "kg",
      });
      porInsumo.set(prod.insumo_id, arr);
    });
    return Array.from(porInsumo.entries())
      .map(([insumoId, ofertas]) => ({
        insumo: nombreInterno(insumoId),
        ofertas: ofertas.sort((a, b) => a.precio - b.precio),
        masBarato: Math.min(...ofertas.map((o) => o.precio)),
      }))
      .sort((a, b) => a.insumo.localeCompare(b.insumo));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [productos, vigentePorProducto, provById, insumos]);

  const exportComparativa = () => {
    const filas = comparativa.flatMap((c) =>
      c.ofertas.map((o) => ({
        Insumo: c.insumo, Proveedor: o.proveedor, Producto: o.producto,
        Precio: o.precio, Unidad: o.unidad, "Más barato": o.precio === c.masBarato ? "SÍ" : "",
      }))
    );
    exportarExcel(filas, "comparativa_precios");
  };

  const sinMapeo = useMemo(
    () => productos.filter((p) => !p.insumo_id),
    [productos]
  );

  const setMapeo = async (productoId: string, insumoId: string | null) => {
    const { error } = await supabase
      .from("proveedor_productos")
      .update({ insumo_id: insumoId })
      .eq("id", productoId);
    if (error) { toast.error("No se pudo guardar el mapeo"); return; }
    setProductos((prev) => prev.map((p) => (p.id === productoId ? { ...p, insumo_id: insumoId } : p)));
    toast.success("Mapeo guardado");
  };

  const copiarLiga = (token: string) => {
    const url = `${window.location.origin}/proveedor/${token}`;
    navigator.clipboard.writeText(url).then(
      () => toast.success("Liga copiada"),
      () => toast.error("No se pudo copiar")
    );
  };

  if (loading) {
    return <div className="min-h-screen flex items-center justify-center"><Loader2 className="h-8 w-8 animate-spin text-primary" /></div>;
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-primary/5 to-secondary/10">
      <div className="bg-background border-b sticky top-0 z-10">
        <div className="container mx-auto px-3 py-2 flex items-center gap-3">
          <Button variant="ghost" size="icon" onClick={() => navigate("/admin/dashboard")}><ArrowLeft className="h-5 w-5" /></Button>
          <img src={logoLaOla} alt="La Ola" className="w-8 h-8 rounded-full object-cover" />
          <div className="flex-1">
            <h1 className="text-base font-semibold">Proveedores & Precios</h1>
            <p className="text-xs text-muted-foreground">Compra estratégica — compara y ahorra</p>
          </div>
          <Button variant="ghost" size="icon" onClick={fetchAll}><RefreshCw className="h-4 w-4" /></Button>
        </div>
      </div>

      <div className="container mx-auto px-3 py-4 max-w-4xl">
        <Tabs defaultValue="comparativa">
          <TabsList className="mb-4">
            <TabsTrigger value="comparativa" className="gap-1 text-xs"><Scale className="h-3.5 w-3.5" />Comparativa</TabsTrigger>
            <TabsTrigger value="proveedores" className="gap-1 text-xs"><Link2 className="h-3.5 w-3.5" />Proveedores</TabsTrigger>
            <TabsTrigger value="mapeo" className="gap-1 text-xs"><GitMerge className="h-3.5 w-3.5" />Mapeo</TabsTrigger>
          </TabsList>

          {/* Comparativa */}
          <TabsContent value="comparativa" className="space-y-3">
            <div className="flex justify-end">
              <Button size="sm" variant="outline" className="gap-1" onClick={exportComparativa} disabled={!comparativa.length}>
                <Download className="h-4 w-4" /> Excel
              </Button>
            </div>
            {comparativa.map((c) => (
              <Card key={c.insumo}>
                <CardHeader className="pb-2"><CardTitle className="text-sm">{c.insumo}</CardTitle></CardHeader>
                <CardContent className="p-0">
                  <div className="divide-y">
                    {c.ofertas.map((o, i) => {
                      const barato = o.precio === c.masBarato;
                      return (
                        <div key={i} className={`flex items-center justify-between px-4 py-2 text-sm ${barato ? "bg-emerald-50" : ""}`}>
                          <div>
                            <span className="font-medium">{o.proveedor}</span>
                            <span className="text-muted-foreground"> · {o.producto}</span>
                          </div>
                          <div className="flex items-center gap-2">
                            <span className="font-semibold tabular-nums">{money(o.precio)} / {o.unidad}</span>
                            {barato && <Badge className="bg-emerald-500 hover:bg-emerald-500">más barato</Badge>}
                          </div>
                        </div>
                      );
                    })}
                  </div>
                </CardContent>
              </Card>
            ))}
            {!comparativa.length && (
              <Card><CardContent className="p-8 text-center text-sm text-muted-foreground">
                Aún no hay precios cargados con productos mapeados. Comparte las ligas a los proveedores y mapea sus productos.
              </CardContent></Card>
            )}
          </TabsContent>

          {/* Proveedores + ligas */}
          <TabsContent value="proveedores">
            <Card>
              <CardHeader className="pb-2">
                <CardTitle className="text-sm">Proveedores</CardTitle>
                <CardDescription className="text-xs">Cada uno tiene una liga única para subir sus precios (sin login).</CardDescription>
              </CardHeader>
              <CardContent className="p-0">
                <ScrollArea className="max-h-[65vh]">
                  <div className="divide-y">
                    {proveedores.map((p) => (
                      <div key={p.id} className="p-3">
                        <div className="flex items-center justify-between gap-2">
                          <div>
                            <span className="font-medium text-sm">{p.nombre}</span>
                            {p.categoria && <Badge variant="outline" className="ml-2 text-xs">{p.categoria}</Badge>}
                            <p className="text-xs text-muted-foreground">
                              {[p.contacto, p.telefono].filter(Boolean).join(" · ") || "—"}
                            </p>
                          </div>
                          <Button size="sm" variant="outline" className="gap-1 shrink-0" onClick={() => copiarLiga(p.token)}>
                            <Copy className="h-3.5 w-3.5" /> Copiar liga
                          </Button>
                        </div>
                        <p className="text-[11px] text-muted-foreground mt-1 truncate">
                          /proveedor/{p.token}
                        </p>
                      </div>
                    ))}
                    {!proveedores.length && (
                      <div className="p-8 text-center text-sm text-muted-foreground">
                        No hay proveedores. Aplica la migración de proveedores.
                      </div>
                    )}
                  </div>
                </ScrollArea>
              </CardContent>
            </Card>
          </TabsContent>

          {/* Mapeo */}
          <TabsContent value="mapeo">
            <Card>
              <CardHeader className="pb-2">
                <CardTitle className="text-sm">Mapeo de productos → insumo interno</CardTitle>
                <CardDescription className="text-xs">
                  Sin mapeo, el producto no entra a la comparativa. {sinMapeo.length} sin mapear.
                </CardDescription>
              </CardHeader>
              <CardContent className="p-0">
                <ScrollArea className="max-h-[65vh]">
                  <div className="divide-y">
                    {productos
                      .slice()
                      .sort((a, b) => Number(!!a.insumo_id) - Number(!!b.insumo_id))
                      .map((prod) => (
                        <div key={prod.id} className="grid grid-cols-12 items-center gap-2 px-4 py-2">
                          <div className="col-span-6 text-sm">
                            {prod.nombre}
                            <span className="text-xs text-muted-foreground"> · {provById.get(prod.proveedor_id)?.nombre}</span>
                          </div>
                          <div className="col-span-6">
                            <Select
                              value={prod.insumo_id ?? "none"}
                              onValueChange={(v) => setMapeo(prod.id, v === "none" ? null : v)}
                            >
                              <SelectTrigger className="h-9"><SelectValue placeholder="Sin mapeo" /></SelectTrigger>
                              <SelectContent>
                                <SelectItem value="none">Sin mapeo</SelectItem>
                                {insumos
                                  .slice()
                                  .sort((a, b) => (infoProteina(a.nombre)?.display ?? a.nombre).localeCompare(infoProteina(b.nombre)?.display ?? b.nombre))
                                  .map((i) => (
                                    <SelectItem key={i.id} value={i.id}>
                                      {infoProteina(i.nombre)?.display ?? i.nombre}
                                    </SelectItem>
                                  ))}
                              </SelectContent>
                            </Select>
                          </div>
                        </div>
                      ))}
                    {!productos.length && (
                      <div className="p-8 text-center text-sm text-muted-foreground">Sin productos de proveedor.</div>
                    )}
                  </div>
                </ScrollArea>
              </CardContent>
            </Card>
          </TabsContent>
        </Tabs>
      </div>
    </div>
  );
}
