import { useEffect, useState, useCallback } from "react";
import { useParams } from "react-router-dom";
import { supabase } from "@/integrations/supabase/client";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import { Loader2, Save, Plus, Tag } from "lucide-react";
import { toast } from "sonner";
import logoLaOla from "@/assets/logo-la-ola.jpeg";
import { getHoraNegocio } from "@/lib/fecha";

const money = (n: number) =>
  new Intl.NumberFormat("es-MX", { style: "currency", currency: "MXN" }).format(n);

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

// El cliente generado puede no conocer estos RPC; se llama de forma laxa.
const rpc = (fn: string, args: Record<string, unknown>) =>
  (supabase.rpc as unknown as (f: string, a: Record<string, unknown>) => Promise<{ data: unknown; error: unknown }>)(fn, args);

export default function ProveedorPortal() {
  const { token = "" } = useParams();
  const [loading, setLoading] = useState(true);
  const [catalogo, setCatalogo] = useState<Catalogo | null>(null);
  const [valido, setValido] = useState(true);
  const [precios, setPrecios] = useState<Record<string, string>>({});
  const [guardando, setGuardando] = useState<string | null>(null);
  const [nuevoNombre, setNuevoNombre] = useState("");
  const [nuevaUnidad, setNuevaUnidad] = useState("kg");
  const [agregando, setAgregando] = useState(false);

  const cargar = useCallback(async () => {
    setLoading(true);
    const { data, error } = await rpc("prov_catalogo", { p_token: token });
    if (error || !data) {
      setValido(false);
      setCatalogo(null);
    } else {
      setValido(true);
      setCatalogo(data as Catalogo);
    }
    setLoading(false);
  }, [token]);

  useEffect(() => {
    cargar();
  }, [cargar]);

  const guardarPrecio = async (productoId: string) => {
    const raw = precios[productoId];
    const valor = parseFloat(raw);
    if (isNaN(valor) || valor < 0) {
      toast.error("Pon un precio válido");
      return;
    }
    setGuardando(productoId);
    const { data, error } = await rpc("prov_set_precio", {
      p_token: token,
      p_producto_id: productoId,
      p_precio: valor,
    });
    setGuardando(null);
    if (error || data === false) {
      toast.error("No se pudo guardar el precio");
      return;
    }
    toast.success("Precio guardado ✓");
    setPrecios((prev) => ({ ...prev, [productoId]: "" }));
    cargar();
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
    cargar();
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

  return (
    <div className="min-h-screen bg-gradient-to-br from-primary/5 to-secondary/10 pb-10">
      <div className="bg-background border-b sticky top-0 z-10">
        <div className="container mx-auto px-3 py-3 flex items-center gap-3 max-w-2xl">
          <img src={logoLaOla} alt="La Ola" className="w-9 h-9 rounded-full object-cover" />
          <div>
            <h1 className="text-base font-semibold leading-tight">
              Precios · {catalogo.proveedor.nombre}
            </h1>
            <p className="text-xs text-muted-foreground">
              Actualiza tus precios para La Ola
            </p>
          </div>
        </div>
      </div>

      <div className="container mx-auto px-3 py-4 max-w-2xl space-y-3">
        <p className="text-xs text-muted-foreground px-1">
          Escribe el precio por unidad de cada producto y dale Guardar. Puedes
          actualizarlo cuando cambie.
        </p>

        {catalogo.productos.map((p) => (
          <Card key={p.id}>
            <CardContent className="p-4 space-y-2">
              <div className="flex items-center justify-between gap-2">
                <span className="font-semibold">{p.nombre}</span>
                <Badge variant="outline" className="text-xs uppercase">{p.unidad}</Badge>
              </div>
              {p.precio_vigente != null && (
                <p className="text-xs text-muted-foreground">
                  Precio actual: <b>{money(p.precio_vigente)}</b> / {p.unidad}
                  {p.precio_fecha && ` · ${getHoraNegocio(p.precio_fecha)}`}
                </p>
              )}
              <div className="flex items-center gap-2">
                <span className="text-muted-foreground">$</span>
                <Input
                  type="number"
                  inputMode="decimal"
                  min="0"
                  placeholder={p.precio_vigente != null ? String(p.precio_vigente) : "Nuevo precio"}
                  value={precios[p.id] ?? ""}
                  onChange={(e) => setPrecios((prev) => ({ ...prev, [p.id]: e.target.value }))}
                  className="h-11"
                />
                <Button
                  className="h-11 gap-1 shrink-0"
                  onClick={() => guardarPrecio(p.id)}
                  disabled={guardando === p.id}
                >
                  {guardando === p.id ? <Loader2 className="h-4 w-4 animate-spin" /> : <Save className="h-4 w-4" />}
                  Guardar
                </Button>
              </div>
            </CardContent>
          </Card>
        ))}

        {catalogo.productos.length === 0 && (
          <Card>
            <CardContent className="p-6 text-center text-sm text-muted-foreground">
              Aún no tienes productos. Agrégalos abajo.
            </CardContent>
          </Card>
        )}

        {/* Agregar producto */}
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm">Agregar un producto</CardTitle>
          </CardHeader>
          <CardContent className="space-y-2">
            <div className="grid grid-cols-3 gap-2">
              <div className="col-span-2 space-y-1">
                <Label className="text-xs">Producto</Label>
                <Input
                  placeholder="Ej. Camarón 21/25"
                  value={nuevoNombre}
                  onChange={(e) => setNuevoNombre(e.target.value)}
                  className="h-11"
                />
              </div>
              <div className="space-y-1">
                <Label className="text-xs">Unidad</Label>
                <Input
                  placeholder="kg"
                  value={nuevaUnidad}
                  onChange={(e) => setNuevaUnidad(e.target.value)}
                  className="h-11"
                />
              </div>
            </div>
            <Button className="w-full gap-1" variant="outline" onClick={agregarProducto} disabled={agregando}>
              {agregando ? <Loader2 className="h-4 w-4 animate-spin" /> : <Plus className="h-4 w-4" />}
              Agregar producto
            </Button>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
