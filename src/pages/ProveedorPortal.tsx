import { useEffect, useState, useCallback } from "react";
import { useParams } from "react-router-dom";
import { supabase } from "@/integrations/supabase/client";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { Loader2, Save, Plus, Tag, CheckCircle2 } from "lucide-react";
import { toast } from "sonner";
import logoLaOla from "@/assets/logo-la-ola.jpeg";

interface Producto {
  id: string;
  nombre: string;
  unidad: string;
  precio_vigente: number | null;
  precio_fecha: string | null;
}
interface Catalogo {
  proveedor: { nombre: string; categoria: string | null };
  productos: Producto[];
}

const rpc = (fn: string, args: Record<string, unknown>) =>
  (supabase.rpc as unknown as (f: string, a: Record<string, unknown>) => Promise<{ data: unknown; error: unknown }>)(fn, args);

export default function ProveedorPortal() {
  const { token = "" } = useParams();
  const [loading, setLoading] = useState(true);
  const [catalogo, setCatalogo] = useState<Catalogo | null>(null);
  const [valido, setValido] = useState(true);
  const [precios, setPrecios] = useState<Record<string, string>>({});
  const [guardando, setGuardando] = useState(false);
  const [nuevoNombre, setNuevoNombre] = useState("");
  const [nuevaUnidad, setNuevaUnidad] = useState("kg");
  const [agregando, setAgregando] = useState(false);

  const cargar = useCallback(
    async (prefill = true) => {
      setLoading(true);
      const { data, error } = await rpc("prov_catalogo", { p_token: token });
      if (error || !data) {
        setValido(false);
        setCatalogo(null);
      } else {
        setValido(true);
        const c = data as Catalogo;
        setCatalogo(c);
        setPrecios((prev) => {
          const next: Record<string, string> = prefill ? {} : { ...prev };
          c.productos.forEach((p) => {
            if (prefill || !(p.id in next)) {
              next[p.id] = p.precio_vigente != null ? String(p.precio_vigente) : (next[p.id] ?? "");
            }
          });
          return next;
        });
      }
      setLoading(false);
    },
    [token]
  );

  useEffect(() => {
    cargar();
  }, [cargar]);

  // Guarda TODOS los precios capturados de una sola vez.
  const guardarTodo = async () => {
    if (!catalogo) return;
    const items = catalogo.productos
      .map((p) => ({ id: p.id, valor: parseFloat(precios[p.id] ?? "") }))
      .filter((x) => !isNaN(x.valor) && x.valor > 0);
    if (items.length === 0) {
      toast.error("Pon al menos un precio");
      return;
    }
    setGuardando(true);
    const results = await Promise.all(
      items.map((it) => rpc("prov_set_precio", { p_token: token, p_producto_id: it.id, p_precio: it.valor }))
    );
    setGuardando(false);
    const ok = results.filter((r) => !r.error && r.data !== false).length;
    if (ok === items.length) toast.success(`${ok} precios guardados ✓`);
    else toast.error(`Se guardaron ${ok} de ${items.length}. Reintenta.`);
    cargar(true);
  };

  const agregarProducto = async () => {
    if (!nuevoNombre.trim()) {
      toast.error("Escribe el nombre del producto");
      return;
    }
    setAgregando(true);
    const { data, error } = await rpc("prov_add_producto", {
      p_token: token,
      p_nombre: nuevoNombre.trim(),
      p_unidad: nuevaUnidad,
    });
    setAgregando(false);
    if (error || !data) {
      toast.error("No se pudo agregar");
      return;
    }
    setNuevoNombre("");
    toast.success("Producto agregado");
    cargar(false);
  };

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <Loader2 className="h-8 w-8 animate-spin text-primary" />
      </div>
    );
  }

  if (!valido || !catalogo) {
    return (
      <div className="min-h-screen flex items-center justify-center p-4 bg-gradient-to-br from-primary/5 to-secondary/10">
        <Card className="max-w-sm w-full">
          <CardContent className="p-8 text-center space-y-2">
            <Tag className="h-10 w-10 mx-auto text-muted-foreground/40" />
            <p className="font-semibold">Liga no válida</p>
            <p className="text-sm text-muted-foreground">
              Esta liga de proveedor no existe o fue desactivada. Pide una nueva al
              restaurante.
            </p>
          </CardContent>
        </Card>
      </div>
    );
  }

  const capturados = catalogo.productos.filter((p) => {
    const v = parseFloat(precios[p.id] ?? "");
    return !isNaN(v) && v > 0;
  }).length;

  return (
    <div className="min-h-screen bg-gradient-to-br from-primary/5 to-secondary/10 pb-28">
      <div className="bg-background border-b sticky top-0 z-10">
        <div className="container mx-auto px-3 py-3 flex items-center gap-3 max-w-2xl">
          <img src={logoLaOla} alt="La Ola" className="w-9 h-9 rounded-full object-cover" />
          <div className="flex-1">
            <h1 className="text-base font-semibold leading-tight">
              Precios · {catalogo.proveedor.nombre}
            </h1>
            <p className="text-xs text-muted-foreground">
              Pon el precio de hoy y dale Guardar. Toma menos de 1 minuto.
            </p>
          </div>
          <Badge variant="secondary">{capturados}/{catalogo.productos.length}</Badge>
        </div>
      </div>

      <div className="container mx-auto px-3 py-3 max-w-2xl">
        {catalogo.productos.length === 0 ? (
          <Card>
            <CardContent className="p-6 text-center text-sm text-muted-foreground">
              Aún no tienes productos. Agrégalos abajo.
            </CardContent>
          </Card>
        ) : (
          <Card>
            <CardContent className="p-0 divide-y">
              {catalogo.productos.map((p) => {
                const lleno = !isNaN(parseFloat(precios[p.id] ?? ""));
                return (
                  <div key={p.id} className="flex items-center gap-3 px-3 py-2.5">
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-1.5">
                        {lleno ? (
                          <CheckCircle2 className="h-4 w-4 text-emerald-500 shrink-0" />
                        ) : (
                          <span className="h-4 w-4 shrink-0" />
                        )}
                        <span className="font-medium truncate">{p.nombre}</span>
                      </div>
                    </div>
                    <span className="text-muted-foreground text-sm">$</span>
                    <Input
                      type="number"
                      inputMode="decimal"
                      min="0"
                      placeholder="0"
                      value={precios[p.id] ?? ""}
                      onChange={(e) => setPrecios((prev) => ({ ...prev, [p.id]: e.target.value }))}
                      className="h-11 w-24 text-center text-base font-semibold"
                    />
                    <span className="text-xs text-muted-foreground w-10 shrink-0">/{p.unidad}</span>
                  </div>
                );
              })}
            </CardContent>
          </Card>
        )}

        {/* Agregar producto (secundario) */}
        <details className="mt-3">
          <summary className="text-sm text-muted-foreground cursor-pointer px-1">
            ¿Falta un producto? Agregarlo
          </summary>
          <Card className="mt-2">
            <CardContent className="p-3 flex items-end gap-2">
              <div className="flex-1">
                <Input
                  placeholder="Ej. Camarón U-15"
                  value={nuevoNombre}
                  onChange={(e) => setNuevoNombre(e.target.value)}
                  className="h-10"
                />
              </div>
              <Input
                placeholder="kg"
                value={nuevaUnidad}
                onChange={(e) => setNuevaUnidad(e.target.value)}
                className="h-10 w-20"
              />
              <Button variant="outline" className="h-10 gap-1" onClick={agregarProducto} disabled={agregando}>
                {agregando ? <Loader2 className="h-4 w-4 animate-spin" /> : <Plus className="h-4 w-4" />}
              </Button>
            </CardContent>
          </Card>
        </details>
      </div>

      {/* Un solo botón: guarda TODO */}
      <div className="fixed bottom-0 inset-x-0 bg-background border-t z-20">
        <div className="container mx-auto px-3 py-3 max-w-2xl">
          <Button
            className="w-full h-14 text-lg gap-2"
            onClick={guardarTodo}
            disabled={guardando || capturados === 0}
          >
            {guardando ? <Loader2 className="h-5 w-5 animate-spin" /> : <Save className="h-5 w-5" />}
            Guardar precios ({capturados})
          </Button>
        </div>
      </div>
    </div>
  );
}
