import { useEffect, useState, useMemo, useCallback } from "react";
import { useNavigate } from "react-router-dom";
import { supabase } from "@/integrations/supabase/client";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Select, SelectContent, SelectItem, SelectTrigger, SelectValue,
} from "@/components/ui/select";
import { ArrowLeft, RefreshCw, Copy, Loader2, Scale, Link2, Download, Package, Plus, Trash2 } from "lucide-react";
import { toast } from "sonner";
import { differenceInCalendarDays, parseISO } from "date-fns";
import logoLaOla from "@/assets/logo-la-ola.jpeg";
import { claveProducto, etiquetaProducto } from "@/lib/proteinas";
import { exportarExcel } from "@/lib/exportar";

const money = (n: number) =>
  new Intl.NumberFormat("es-MX", { style: "currency", currency: "MXN" }).format(n);

interface Proveedor {
  id: string; nombre: string; categoria: string | null;
  contacto: string | null; telefono: string | null; token: string; activo: boolean;
}
interface Producto {
  id: string; proveedor_id: string; nombre: string; unidad: string | null; insumo_id: string | null; activo: boolean;
}
interface PrecioRow { proveedor_producto_id: string; precio: number; created_at: string; }

// Etiqueta de frescura del precio: hoy / ayer / hace N días.
function frescura(fecha: string | null): { hoy: boolean; label: string } | null {
  if (!fecha) return null;
  const dias = differenceInCalendarDays(new Date(), parseISO(fecha));
  if (dias <= 0) return { hoy: true, label: "hoy" };
  if (dias === 1) return { hoy: false, label: "ayer" };
  return { hoy: false, label: `hace ${dias} días` };
}

export default function AdminProveedores() {
  const navigate = useNavigate();
  const [loading, setLoading] = useState(true);
  const [proveedores, setProveedores] = useState<Proveedor[]>([]);
  const [productos, setProductos] = useState<Producto[]>([]);
  const [precios, setPrecios] = useState<PrecioRow[]>([]);

  const fetchAll = useCallback(async () => {
    setLoading(true);
    const [provRes, prodRes, preRes] = await Promise.all([
      supabase.from("proveedores").select("*").order("categoria").order("nombre"),
      supabase.from("proveedor_productos").select("id, proveedor_id, nombre, unidad, insumo_id, activo"),
      supabase.from("proveedor_precios").select("proveedor_producto_id, precio, created_at").order("created_at", { ascending: false }),
    ]);
    setProveedores((provRes.data ?? []) as Proveedor[]);
    setProductos((prodRes.data ?? []) as Producto[]);
    setPrecios((preRes.data ?? []) as PrecioRow[]);
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

  // ---- Comparativa: agrupa por nombre de producto (sin mapeo manual) ----
  const comparativa = useMemo(() => {
    interface Oferta { proveedor: string; producto: string; precio: number | null; unidad: string; fecha: string | null; }
    const grupos = new Map<string, { label: string; ofertas: Oferta[] }>();
    productos.forEach((prod) => {
      if (!prod.activo) return;
      const clave = claveProducto(prod.nombre);
      const vig = vigentePorProducto.get(prod.id);
      const g = grupos.get(clave) ?? { label: etiquetaProducto(prod.nombre), ofertas: [] };
      g.ofertas.push({
        proveedor: provById.get(prod.proveedor_id)?.nombre || "—",
        producto: prod.nombre,
        precio: vig ? vig.precio : null,
        unidad: prod.unidad || "kg",
        fecha: vig ? vig.fecha : null,
      });
      grupos.set(clave, g);
    });
    return Array.from(grupos.values())
      .map((g) => {
        const conPrecio = g.ofertas.filter((o) => o.precio != null) as (Oferta & { precio: number })[];
        const pendientes = g.ofertas.filter((o) => o.precio == null);
        return {
          label: g.label,
          ofertas: conPrecio.sort((a, b) => a.precio - b.precio),
          pendientes,
          masBarato: conPrecio.length ? Math.min(...conPrecio.map((o) => o.precio)) : null,
          numProveedores: g.ofertas.length,
        };
      })
      // Primero los que se pueden comparar (2+ proveedores), luego alfabético.
      .sort((a, b) => (b.numProveedores > 1 ? 1 : 0) - (a.numProveedores > 1 ? 1 : 0) || a.label.localeCompare(b.label));
  }, [productos, vigentePorProducto, provById]);

  const exportComparativa = () => {
    const filas = comparativa.flatMap((c) =>
      c.ofertas.map((o) => ({
        Producto: c.label, Proveedor: o.proveedor, "Nombre en su lista": o.producto,
        Precio: o.precio, Unidad: o.unidad,
        "Más barato": o.precio === c.masBarato ? "SÍ" : "",
        Actualizado: frescura(o.fecha)?.label ?? "",
      }))
    );
    exportarExcel(filas, "comparativa_precios");
  };

  // ---- Edición de productos por proveedor ----
  const [provSel, setProvSel] = useState<string>("");
  const [nuevoNombre, setNuevoNombre] = useState("");
  const [nuevaUnidad, setNuevaUnidad] = useState("kg");
  useEffect(() => {
    if (!provSel && proveedores.length) setProvSel(proveedores[0].id);
  }, [proveedores, provSel]);

  const productosProv = useMemo(
    () => productos
      .filter((p) => p.proveedor_id === provSel && p.activo)
      .sort((a, b) => a.nombre.localeCompare(b.nombre)),
    [productos, provSel]
  );

  const agregarProducto = async () => {
    if (!provSel || !nuevoNombre.trim()) { toast.error("Escribe el nombre del producto"); return; }
    const { data, error } = await supabase
      .from("proveedor_productos")
      .insert({
        proveedor_id: provSel,
        nombre: nuevoNombre.trim(),
        unidad: nuevaUnidad.trim() || "kg",
      })
      .select()
      .single();
    if (error || !data) { toast.error("No se pudo agregar (¿nombre repetido?)"); return; }
    setProductos((prev) => [...prev, data as Producto]);
    setNuevoNombre("");
    toast.success("Producto agregado");
  };

  // Guarda nombre/unidad si cambiaron (al salir del campo).
  const actualizarProducto = async (prod: Producto, campos: { nombre?: string; unidad?: string }) => {
    const nombre = campos.nombre?.trim() ?? prod.nombre;
    const unidad = campos.unidad?.trim() ?? prod.unidad;
    if (nombre === prod.nombre && unidad === prod.unidad) return;
    if (!nombre) { toast.error("El nombre no puede quedar vacío"); return; }
    const { error } = await supabase
      .from("proveedor_productos")
      .update({ nombre, unidad })
      .eq("id", prod.id);
    if (error) { toast.error("No se pudo guardar (¿nombre repetido?)"); return; }
    setProductos((prev) => prev.map((p) => (p.id === prod.id ? { ...p, nombre, unidad } : p)));
  };

  // "Quitar" = ocultar (activo=false); conserva el histórico de precios.
  const quitarProducto = async (prod: Producto) => {
    const { error } = await supabase
      .from("proveedor_productos")
      .update({ activo: false })
      .eq("id", prod.id);
    if (error) { toast.error("No se pudo quitar"); return; }
    setProductos((prev) => prev.map((p) => (p.id === prod.id ? { ...p, activo: false } : p)));
    toast.success("Producto quitado de la liga");
  };

  const copiarLiga = (token: string) => {
    const url = `${window.location.origin}/proveedor/${token}`;
    navigator.clipboard.writeText(url).then(
      () => toast.success("Liga copiada"),
      () => toast.error("No se pudo copiar")
    );
  };

  // Resumen por proveedor para la pestaña Ligas: # productos activos + último precio.
  const resumenProveedor = useCallback(
    (provId: string) => {
      const prods = productos.filter((p) => p.proveedor_id === provId && p.activo);
      let ultima: string | null = null;
      prods.forEach((p) => {
        const vig = vigentePorProducto.get(p.id);
        if (vig && (!ultima || vig.fecha > ultima)) ultima = vig.fecha;
      });
      return { total: prods.length, ultima };
    },
    [productos, vigentePorProducto]
  );

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
            <TabsTrigger value="listas" className="gap-1 text-xs"><Package className="h-3.5 w-3.5" />Listas</TabsTrigger>
            <TabsTrigger value="ligas" className="gap-1 text-xs"><Link2 className="h-3.5 w-3.5" />Ligas</TabsTrigger>
          </TabsList>

          {/* ============ Comparativa ============ */}
          <TabsContent value="comparativa" className="space-y-3">
            <div className="flex items-center justify-between">
              <p className="text-xs text-muted-foreground">
                Mismo producto entre proveedores. En verde, el más barato.
              </p>
              <Button size="sm" variant="outline" className="gap-1" onClick={exportComparativa} disabled={!comparativa.length}>
                <Download className="h-4 w-4" /> Excel
              </Button>
            </div>
            {comparativa.map((c) => (
              <Card key={c.label}>
                <CardHeader className="pb-2"><CardTitle className="text-sm">{c.label}</CardTitle></CardHeader>
                <CardContent className="p-0">
                  <div className="divide-y">
                    {c.ofertas.map((o, i) => {
                      const barato = o.precio === c.masBarato && c.ofertas.length > 1;
                      const fr = frescura(o.fecha);
                      return (
                        <div key={i} className={`flex items-center justify-between px-4 py-2 text-sm ${barato ? "bg-emerald-50" : ""}`}>
                          <div className="min-w-0">
                            <span className="font-medium">{o.proveedor}</span>
                            <span className="text-muted-foreground"> · {o.producto}</span>
                            {fr && !fr.hoy && (
                              <span className="text-[11px] text-amber-600 ml-1">({fr.label})</span>
                            )}
                          </div>
                          <div className="flex items-center gap-2 shrink-0">
                            <span className="font-semibold tabular-nums">{money(o.precio)} / {o.unidad}</span>
                            {barato && <Badge className="bg-emerald-500 hover:bg-emerald-500">más barato</Badge>}
                          </div>
                        </div>
                      );
                    })}
                    {c.pendientes.map((o, i) => (
                      <div key={`p-${i}`} className="flex items-center justify-between px-4 py-2 text-sm opacity-60">
                        <div className="min-w-0">
                          <span className="font-medium">{o.proveedor}</span>
                          <span className="text-muted-foreground"> · {o.producto}</span>
                        </div>
                        <span className="text-xs text-muted-foreground shrink-0">sin precio aún</span>
                      </div>
                    ))}
                  </div>
                </CardContent>
              </Card>
            ))}
            {!comparativa.length && (
              <Card><CardContent className="p-8 text-center text-sm text-muted-foreground">
                Aún no hay productos. Ve a <b>Listas</b> y comparte las ligas a los proveedores.
              </CardContent></Card>
            )}
          </TabsContent>

          {/* ============ Listas (productos por proveedor) ============ */}
          <TabsContent value="listas">
            <Card>
              <CardHeader className="pb-2">
                <CardTitle className="text-sm flex items-center justify-between gap-2">
                  <span>Lista de</span>
                  <Select value={provSel} onValueChange={setProvSel}>
                    <SelectTrigger className="w-48"><SelectValue /></SelectTrigger>
                    <SelectContent>
                      {proveedores.map((p) => (
                        <SelectItem key={p.id} value={p.id}>{p.nombre}</SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </CardTitle>
                <CardDescription className="text-xs">
                  Esto es lo que verá este proveedor en su liga. Puedes editar el nombre y la unidad, agregar o quitar.
                </CardDescription>
              </CardHeader>
              <CardContent className="p-0">
                {/* Agregar producto */}
                <div className="p-3 border-b bg-muted/30 grid grid-cols-12 gap-2 items-end">
                  <div className="col-span-7 space-y-1">
                    <Label className="text-xs">Nuevo producto</Label>
                    <Input value={nuevoNombre} onChange={(e) => setNuevoNombre(e.target.value)}
                      onKeyDown={(e) => { if (e.key === "Enter") agregarProducto(); }}
                      placeholder="Ej. Camarón 21/25" className="h-9" />
                  </div>
                  <div className="col-span-3 space-y-1">
                    <Label className="text-xs">Unidad</Label>
                    <Input value={nuevaUnidad} onChange={(e) => setNuevaUnidad(e.target.value)} placeholder="kg" className="h-9" />
                  </div>
                  <div className="col-span-2">
                    <Button className="w-full gap-1 h-9" onClick={agregarProducto}><Plus className="h-4 w-4" />Agregar</Button>
                  </div>
                </div>
                {/* Lista de productos del proveedor */}
                <div className="divide-y">
                  {productosProv.map((prod) => {
                    const vig = vigentePorProducto.get(prod.id);
                    return (
                      <div key={prod.id} className="grid grid-cols-12 items-center gap-2 px-3 py-2">
                        <Input
                          defaultValue={prod.nombre}
                          onBlur={(e) => actualizarProducto(prod, { nombre: e.target.value })}
                          onKeyDown={(e) => { if (e.key === "Enter") (e.target as HTMLInputElement).blur(); }}
                          className="col-span-6 h-9 text-sm"
                        />
                        <Input
                          defaultValue={prod.unidad ?? ""}
                          onBlur={(e) => actualizarProducto(prod, { unidad: e.target.value })}
                          onKeyDown={(e) => { if (e.key === "Enter") (e.target as HTMLInputElement).blur(); }}
                          className="col-span-2 h-9 text-sm text-center"
                        />
                        <div className="col-span-2 text-xs text-right">
                          {vig ? <span className="text-emerald-600 font-medium">{money(vig.precio)}</span> : <span className="text-muted-foreground">sin precio</span>}
                        </div>
                        <div className="col-span-2 text-right">
                          <Button size="sm" variant="ghost" className="gap-1 text-xs text-destructive hover:text-destructive" onClick={() => quitarProducto(prod)}>
                            <Trash2 className="h-3.5 w-3.5" />Quitar
                          </Button>
                        </div>
                      </div>
                    );
                  })}
                  {productosProv.length === 0 && (
                    <div className="p-8 text-center text-sm text-muted-foreground">Este proveedor no tiene productos. Agrégalos arriba.</div>
                  )}
                </div>
              </CardContent>
            </Card>
          </TabsContent>

          {/* ============ Ligas ============ */}
          <TabsContent value="ligas">
            <Card>
              <CardHeader className="pb-2">
                <CardTitle className="text-sm">Ligas de proveedores</CardTitle>
                <CardDescription className="text-xs">Cada uno tiene una liga única para subir sus precios (sin login). El envío se hace por fuera.</CardDescription>
              </CardHeader>
              <CardContent className="p-0">
                <div className="divide-y">
                  {proveedores.map((p) => {
                    const r = resumenProveedor(p.id);
                    const fr = frescura(r.ultima);
                    return (
                      <div key={p.id} className="p-3">
                        <div className="flex items-center justify-between gap-2">
                          <div className="min-w-0">
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
                        <div className="flex items-center gap-2 mt-1 flex-wrap">
                          <p className="text-[11px] text-muted-foreground truncate">/proveedor/{p.token}</p>
                          <Badge variant="secondary" className="text-[10px]">{r.total} productos</Badge>
                          {fr ? (
                            <Badge variant="outline" className={`text-[10px] ${fr.hoy ? "text-emerald-600 border-emerald-300" : "text-amber-600 border-amber-300"}`}>
                              precio {fr.label}
                            </Badge>
                          ) : (
                            <Badge variant="outline" className="text-[10px] text-muted-foreground">sin precio</Badge>
                          )}
                        </div>
                      </div>
                    );
                  })}
                  {!proveedores.length && (
                    <div className="p-8 text-center text-sm text-muted-foreground">
                      No hay proveedores. Aplica la migración de proveedores.
                    </div>
                  )}
                </div>
              </CardContent>
            </Card>
          </TabsContent>
        </Tabs>
      </div>
    </div>
  );
}
