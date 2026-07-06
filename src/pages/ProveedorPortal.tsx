import { useEffect, useState, useCallback } from "react";
import { useParams } from "react-router-dom";
import { supabase } from "@/integrations/supabase/client";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { Loader2, Save, Tag, CheckCircle2 } from "lucide-react";
import { toast } from "sonner";
import { format } from "date-fns";
import { es } from "date-fns/locale";
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
  // Los precios SIEMPRE arrancan en blanco: el proveedor escribe el de hoy.
  // No se pre-llena ni se muestra el precio anterior.
  const [precios, setPrecios] = useState<Record<string, string>>({});
  const [guardando, setGuardando] = useState(false);

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
    if (ok === items.length) {
      toast.success(`${ok} precios guardados ✓`);
      setPrecios({}); // Vuelve a dejar todo en blanco.
    } else {
      toast.error(`Se guardaron ${ok} de ${items.length}. Reintenta.`);
    }
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

  const hoy = format(new Date(), "EEEE d 'de' MMMM", { locale: es });
  const hoyCap = hoy.charAt(0).toUpperCase() + hoy.slice(1);

  return (
    <div className="min-h-screen bg-gradient-to-br from-primary/5 to-secondary/10 pb-28">
      {/* Encabezado personalizado */}
      <div className="bg-background border-b sticky top-0 z-10">
        <div className="container mx-auto px-3 py-3 flex items-center gap-3 max-w-2xl">
          <img src={logoLaOla} alt="La Ola" className="w-10 h-10 rounded-full object-cover shrink-0" />
          <div className="flex-1 min-w-0">
            <h1 className="text-base font-semibold leading-tight truncate">
              Hola, {catalogo.proveedor.nombre}
            </h1>
            <p className="text-xs text-muted-foreground">
              Precios para La Ola · {hoyCap}
            </p>
          </div>
          <Badge variant="secondary" className="shrink-0">
            {capturados}/{catalogo.productos.length}
          </Badge>
        </div>
      </div>

      <div className="container mx-auto px-3 py-3 max-w-2xl">
        <p className="text-sm text-muted-foreground px-1 mb-3">
          Escribe el precio de <b>hoy</b> de cada producto y dale Guardar. Toma menos de 1 minuto.
        </p>

        {catalogo.productos.length === 0 ? (
          <Card>
            <CardContent className="p-6 text-center text-sm text-muted-foreground">
              Aún no tienes productos asignados. El restaurante los configura.
            </CardContent>
          </Card>
        ) : (
          <Card>
            <CardContent className="p-0 divide-y">
              {catalogo.productos.map((p) => {
                const lleno = !isNaN(parseFloat(precios[p.id] ?? ""));
                return (
                  <div key={p.id} className="flex items-center gap-3 px-3 py-3">
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
                      className="h-12 w-24 text-center text-base font-semibold"
                    />
                    <span className="text-xs text-muted-foreground w-10 shrink-0">/{p.unidad}</span>
                  </div>
                );
              })}
            </CardContent>
          </Card>
        )}
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
            Guardar precios de hoy ({capturados})
          </Button>
        </div>
      </div>
    </div>
  );
}
