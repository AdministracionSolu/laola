import { useCallback, useEffect, useMemo, useState } from "react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { AlertTriangle, Loader2, Save } from "lucide-react";
import { toast } from "sonner";
import { supabase } from "@/integrations/supabase/client";
import { CampoCantidad, MAXIMO } from "@/components/operaciones/CampoCantidad";
import type { SucursalLite } from "@/hooks/useAnaliticaPedidos";

// Lo que la sucursal capturó al recibir, para corregirlo. Es la única pantalla
// donde se puede: el capturista sube y ya no vuelve a entrar, y los dedazos
// (800 de atún, 60,470 de camarón) sólo se ven desde aquí.

interface Props {
  dia: string;
  sucursales: SucursalLite[];
  nombreInsumo: Map<string, string>;
}

interface Renglon {
  id: string;
  recepcion_id: string;
  insumo_id: string;
  cantidad_recibida: number;
}

interface Recepcion {
  id: string;
  sucursal_id: string;
  proveedor: string | null;
  registrado_por: string | null;
  notas: string | null;
}

export function RecepcionesPanel({ dia, sucursales, nombreInsumo }: Props) {
  const [recepciones, setRecepciones] = useState<Recepcion[]>([]);
  const [renglones, setRenglones] = useState<Renglon[]>([]);
  const [cantEdits, setCantEdits] = useState<Record<string, number>>({});
  const [provEdits, setProvEdits] = useState<Record<string, string>>({});
  const [loading, setLoading] = useState(true);
  const [guardando, setGuardando] = useState(false);

  const nombreSucursal = useMemo(() => {
    const m = new Map<string, string>();
    sucursales.forEach((s) => m.set(s.id, s.nombre));
    return m;
  }, [sucursales]);

  const cargar = useCallback(async () => {
    setLoading(true);
    const { data: recs } = await supabase
      .from("recepciones")
      .select("id, sucursal_id, proveedor, registrado_por, notas")
      .eq("fecha", dia)
      .order("created_at");
    const lista = (recs || []) as Recepcion[];
    setRecepciones(lista);
    if (lista.length === 0) {
      setRenglones([]);
      setLoading(false);
      return;
    }
    const { data: dets } = await supabase
      .from("recepciones_detalle")
      .select("id, recepcion_id, insumo_id, cantidad_recibida")
      .in(
        "recepcion_id",
        lista.map((r) => r.id)
      );
    setRenglones((dets || []) as Renglon[]);
    setCantEdits({});
    setProvEdits({});
    setLoading(false);
  }, [dia]);

  useEffect(() => {
    cargar();
  }, [cargar]);

  const porRecepcion = useMemo(() => {
    const m = new Map<string, Renglon[]>();
    renglones.forEach((r) => {
      const arr = m.get(r.recepcion_id) || [];
      arr.push(r);
      m.set(r.recepcion_id, arr);
    });
    return m;
  }, [renglones]);

  const cantidadDe = (r: Renglon) => cantEdits[r.id] ?? r.cantidad_recibida ?? 0;

  const cambios = Object.keys(cantEdits).length + Object.keys(provEdits).length;

  const guardar = async () => {
    setGuardando(true);
    const results = await Promise.all([
      ...Object.entries(cantEdits).map(([id, v]) =>
        supabase.from("recepciones_detalle").update({ cantidad_recibida: v }).eq("id", id)
      ),
      ...Object.entries(provEdits).map(([id, v]) =>
        supabase.from("recepciones").update({ proveedor: v.trim() }).eq("id", id)
      ),
    ]);
    setGuardando(false);
    if (results.find((r) => r.error)) {
      toast.error("No se pudieron guardar todos los cambios");
      return;
    }
    toast.success("Recepciones corregidas ✓");
    cargar();
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
      <CardHeader className="flex flex-row items-start justify-between gap-3 space-y-0">
        <div>
          <CardTitle className="text-base">Recepciones del día</CardTitle>
          <CardDescription>
            Lo que capturó cada sucursal al recibir. Se puede corregir la cantidad y el nombre
            del proveedor. El tope de captura es {MAXIMO}.
          </CardDescription>
        </div>
        <Button size="sm" onClick={guardar} disabled={guardando || cambios === 0} className="gap-1 shrink-0">
          {guardando ? <Loader2 className="h-4 w-4 animate-spin" /> : <Save className="h-4 w-4" />}
          Guardar{cambios ? ` (${cambios})` : ""}
        </Button>
      </CardHeader>
      <CardContent>
        {recepciones.length === 0 ? (
          <p className="text-sm text-muted-foreground py-8 text-center">
            Nadie registró recepciones este día.
          </p>
        ) : (
          <div className="space-y-4">
            {recepciones.map((rec) => {
              const dets = porRecepcion.get(rec.id) || [];
              return (
                <div key={rec.id} className="border rounded-lg overflow-hidden">
                  <div className="bg-muted/40 px-3 py-2 flex flex-wrap items-center gap-2">
                    <Badge variant="secondary">{nombreSucursal.get(rec.sucursal_id) || "?"}</Badge>
                    <Input
                      value={provEdits[rec.id] ?? rec.proveedor ?? ""}
                      placeholder="Proveedor"
                      aria-label="Proveedor"
                      onChange={(e) =>
                        setProvEdits((p) => ({ ...p, [rec.id]: e.target.value }))
                      }
                      className={`h-8 w-56 ${rec.id in provEdits ? "border-primary font-medium" : ""}`}
                    />
                    <span className="text-xs text-muted-foreground">
                      capturó {rec.registrado_por || "—"}
                    </span>
                  </div>
                  <table className="w-full text-sm">
                    <tbody>
                      {dets.map((d) => {
                        const v = cantidadDe(d);
                        // Se marca lo que llega al tope: casi siempre es un
                        // dedazo que quedó recortado y hay que revisar.
                        const sospechoso = v >= MAXIMO;
                        return (
                          <tr key={d.id} className="border-t">
                            <td className="p-2">{nombreInsumo.get(d.insumo_id) || d.insumo_id}</td>
                            <td className="p-2 w-32 text-right">
                              <div className="flex items-center justify-end gap-1">
                                {sospechoso && (
                                  <AlertTriangle className="h-4 w-4 text-amber-500 shrink-0" />
                                )}
                                <CampoCantidad
                                  ariaLabel="Cantidad recibida"
                                  value={v}
                                  onChange={(nv) => setCantEdits((p) => ({ ...p, [d.id]: nv }))}
                                  className={`h-8 w-20 text-center ${
                                    d.id in cantEdits ? "border-primary font-semibold" : ""
                                  }`}
                                />
                              </div>
                            </td>
                          </tr>
                        );
                      })}
                      {dets.length === 0 && (
                        <tr>
                          <td className="p-2 text-muted-foreground text-xs" colSpan={2}>
                            Sin renglones.
                          </td>
                        </tr>
                      )}
                    </tbody>
                  </table>
                </div>
              );
            })}
          </div>
        )}
      </CardContent>
    </Card>
  );
}
