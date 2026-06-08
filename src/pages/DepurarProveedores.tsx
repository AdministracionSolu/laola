import { useEffect, useState, useCallback } from "react";
import { useParams } from "react-router-dom";
import { supabase } from "@/integrations/supabase/client";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import {
  Accordion, AccordionContent, AccordionItem, AccordionTrigger,
} from "@/components/ui/accordion";
import { Loader2, Tag, Trash2, RotateCcw, Save, CheckCircle2 } from "lucide-react";
import { toast } from "sonner";
import logoLaOla from "@/assets/logo-la-ola.jpeg";

interface Prod { id: string; nombre: string; unidad: string; }
interface Prov { id: string; nombre: string; categoria: string | null; depurado: boolean; productos: Prod[]; }

const rpc = (fn: string, args: Record<string, unknown>) =>
  (supabase.rpc as unknown as (f: string, a: Record<string, unknown>) => Promise<{ data: unknown; error: unknown }>)(fn, args);

export default function DepurarProveedores() {
  const { token = "" } = useParams();
  const [loading, setLoading] = useState(true);
  const [valido, setValido] = useState(true);
  const [proveedores, setProveedores] = useState<Prov[]>([]);
  const [quitar, setQuitar] = useState<Set<string>>(new Set());
  const [guardando, setGuardando] = useState(false);

  const cargar = useCallback(async () => {
    setLoading(true);
    const { data, error } = await rpc("depurar_listar", { p_token: token });
    if (error || !data) {
      setValido(false);
      setProveedores([]);
    } else {
      setValido(true);
      setProveedores(data as Prov[]);
    }
    setQuitar(new Set());
    setLoading(false);
  }, [token]);

  useEffect(() => { cargar(); }, [cargar]);

  const toggle = (id: string) =>
    setQuitar((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });

  const marcarRevisado = async (provId: string, value: boolean) => {
    const { data, error } = await rpc("depurar_marcar", {
      p_token: token,
      p_proveedor_id: provId,
      p_depurado: value,
    });
    if (error || data === false) {
      toast.error("No se pudo marcar");
      return;
    }
    setProveedores((prev) => prev.map((p) => (p.id === provId ? { ...p, depurado: value } : p)));
  };

  const guardar = async () => {
    if (quitar.size === 0) {
      toast.error("No marcaste nada para quitar");
      return;
    }
    if (!window.confirm(`Vas a quitar ${quitar.size} producto(s) de forma permanente. ¿Continuar?`)) {
      return;
    }
    setGuardando(true);
    const { data, error } = await rpc("depurar_eliminar", { p_token: token, p_ids: [...quitar] });
    setGuardando(false);
    if (error || typeof data !== "number" || data < 0) {
      toast.error("No se pudo guardar");
      return;
    }
    toast.success(`${data} producto(s) quitados ✓`);
    cargar();
  };

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <Loader2 className="h-8 w-8 animate-spin text-primary" />
      </div>
    );
  }

  if (!valido) {
    return (
      <div className="min-h-screen flex items-center justify-center p-4 bg-gradient-to-br from-primary/5 to-secondary/10">
        <Card className="max-w-sm w-full">
          <CardContent className="p-8 text-center space-y-2">
            <Tag className="h-10 w-10 mx-auto text-muted-foreground/40" />
            <p className="font-semibold">Liga no válida</p>
            <p className="text-sm text-muted-foreground">Esta liga de depuración no existe o fue revocada.</p>
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-primary/5 to-secondary/10 pb-28">
      <div className="bg-background border-b sticky top-0 z-20">
        <div className="container mx-auto px-3 py-3 flex items-center gap-3 max-w-2xl">
          <img src={logoLaOla} alt="La Ola" className="w-9 h-9 rounded-full object-cover" />
          <div>
            <h1 className="text-base font-semibold leading-tight">Depurar proveedores</h1>
            <p className="text-xs text-muted-foreground">
              Deja a cada proveedor solo lo que sí le vamos a preguntar.
            </p>
          </div>
        </div>
      </div>

      <div className="container mx-auto px-3 py-3 max-w-2xl">
        <div className="flex items-center justify-between px-1 mb-2">
          <p className="text-xs text-muted-foreground">
            Toca un proveedor, dale <b>Quitar</b> a lo que NO vende y <b>Guardar</b>.
          </p>
          <Badge variant="secondary" className="shrink-0">
            {proveedores.filter((p) => p.depurado).length}/{proveedores.length} revisados
          </Badge>
        </div>
        <Accordion type="multiple" className="space-y-2">
          {proveedores.map((p) => {
            const porQuitar = p.productos.filter((x) => quitar.has(x.id)).length;
            const quedan = p.productos.length - porQuitar;
            return (
              <AccordionItem key={p.id} value={p.id} className={`border rounded-lg ${p.depurado ? "bg-emerald-50 border-emerald-300" : "bg-background"}`}>
                <AccordionTrigger className="px-3 py-3 hover:no-underline">
                  <div className="flex items-center gap-2 text-left flex-wrap">
                    {p.depurado && <CheckCircle2 className="h-4 w-4 text-emerald-500 shrink-0" />}
                    <span className="font-semibold">{p.nombre}</span>
                    {p.categoria && <Badge variant="outline" className="text-xs">{p.categoria}</Badge>}
                    <Badge variant="secondary" className="text-xs">{quedan} quedan</Badge>
                  </div>
                </AccordionTrigger>
                <AccordionContent className="px-0 pb-0">
                  <div className="divide-y">
                    {p.productos.map((prod) => {
                      const marcado = quitar.has(prod.id);
                      return (
                        <div
                          key={prod.id}
                          className={`flex items-center gap-2 px-3 py-2.5 ${marcado ? "bg-red-50" : ""}`}
                        >
                          {marcado ? (
                            <Trash2 className="h-4 w-4 text-red-500 shrink-0" />
                          ) : (
                            <CheckCircle2 className="h-4 w-4 text-emerald-500 shrink-0" />
                          )}
                          <span className={`flex-1 text-sm ${marcado ? "line-through text-muted-foreground" : ""}`}>
                            {prod.nombre} <span className="text-muted-foreground text-xs">/{prod.unidad}</span>
                          </span>
                          <Button
                            size="sm"
                            variant={marcado ? "outline" : "ghost"}
                            className="gap-1 text-xs h-9"
                            onClick={() => toggle(prod.id)}
                          >
                            {marcado ? <><RotateCcw className="h-3.5 w-3.5" />Dejar</> : <><Trash2 className="h-3.5 w-3.5" />Quitar</>}
                          </Button>
                        </div>
                      );
                    })}
                    {p.productos.length === 0 && (
                      <div className="px-3 py-4 text-center text-xs text-muted-foreground">Sin productos.</div>
                    )}
                  </div>
                  <div className="p-3 border-t">
                    <Button
                      variant={p.depurado ? "outline" : "secondary"}
                      className="w-full gap-2"
                      onClick={() => marcarRevisado(p.id, !p.depurado)}
                    >
                      {p.depurado ? <><RotateCcw className="h-4 w-4" />Marcar como pendiente</> : <><CheckCircle2 className="h-4 w-4" />Marcar como revisado</>}
                    </Button>
                  </div>
                </AccordionContent>
              </AccordionItem>
            );
          })}
        </Accordion>
      </div>

      <div className="fixed bottom-0 inset-x-0 bg-background border-t z-30">
        <div className="container mx-auto px-3 py-3 max-w-2xl">
          <Button
            className="w-full h-14 text-lg gap-2"
            onClick={guardar}
            disabled={guardando || quitar.size === 0}
          >
            {guardando ? <Loader2 className="h-5 w-5 animate-spin" /> : <Save className="h-5 w-5" />}
            Guardar (quitar {quitar.size})
          </Button>
        </div>
      </div>
    </div>
  );
}
