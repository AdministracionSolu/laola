import { useState, useEffect, useMemo, useCallback } from "react";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import { Progress } from "@/components/ui/progress";
import {
  Sheet,
  SheetContent,
  SheetHeader,
  SheetTitle,
  SheetFooter,
} from "@/components/ui/sheet";
import {
  ArrowLeft,
  Send,
  CheckCircle2,
  Circle,
  Loader2,
  ClipboardList,
  WifiOff,
  MapPin,
} from "lucide-react";
import { useNavigate } from "react-router-dom";
import { supabase } from "@/integrations/supabase/client";
import { toast } from "sonner";
import logoLaOla from "@/assets/logo-la-ola.jpeg";
import { useSucursal } from "@/contexts/SucursalContext";
import { useOnlineStatus } from "@/hooks/useOnlineStatus";
import { getFechaNegocio, getHoraNegocio } from "@/lib/fecha";
import { CantidadStepper } from "@/components/operaciones/CantidadStepper";
import { infoProteina } from "@/lib/proteinas";

interface Categoria {
  id: string;
  nombre: string;
  orden: number;
}

interface ItemSucursal {
  insumo_id: string;
  nombre: string;
  categoria_id: string;
  unidad: string;
  nivel_par: number | null;
  costo: number | null;
  orden: number;
}

interface Detalle {
  existencia: number;
  cantidad_pedida: number;
  cantidad_sugerida: number | null;
  // El encargado capturó la existencia (la tarjeta queda "lista").
  capturado: boolean;
  // El encargado editó "Pides" a mano (no volver a sobreescribir con sugerido).
  pedidoManual: boolean;
}

type ItemRow = {
  orden: number;
  nivel_par: number | null;
  costo: number | null;
  unidad: string | null;
  insumos: { id: string; nombre: string; categoria_id: string; unidad: string | null };
};

type DetRow = {
  insumo_id: string;
  existencia: number | null;
  cantidad_pedida: number;
  cantidad_sugerida: number | null;
};

const detalleVacio = (): Detalle => ({
  existencia: 0,
  cantidad_pedida: 0,
  cantidad_sugerida: null,
  capturado: false,
  pedidoManual: false,
});

export default function Pedidos() {
  const navigate = useNavigate();
  const online = useOnlineStatus();
  const { sucursalId, sucursalNombre, registradoPor, setRegistradoPor } =
    useSucursal();

  // Fecha de negocio fijada AL MONTAR: no cambia a media captura al cruzar el
  // corte de la 1pm (evita perder el borrador en marcha).
  const [fecha] = useState(getFechaNegocio);
  const draftKey = `laola_pedido_draft_${sucursalId}_${fecha}`;

  const [categorias, setCategorias] = useState<Categoria[]>([]);
  const [items, setItems] = useState<ItemSucursal[]>([]);
  const [detalles, setDetalles] = useState<Record<string, Detalle>>({});
  const [notas, setNotas] = useState("");
  const [pedidoId, setPedidoId] = useState<string | null>(null);
  const [estadoPedido, setEstadoPedido] = useState<string | null>(null);
  const [enviadoAt, setEnviadoAt] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [enviando, setEnviando] = useState(false);
  const [revisar, setRevisar] = useState(false);
  const [draftCargado, setDraftCargado] = useState(false);

  // ---- Carga inicial ----
  useEffect(() => {
    if (!sucursalId) return;
    let cancelado = false;

    (async () => {
      setLoading(true);
      const [catRes, itemsRes, pedidoRes] = await Promise.all([
        supabase.from("categorias_insumos").select("*").order("orden"),
        supabase
          .from("insumo_sucursal")
          .select("orden, nivel_par, costo, unidad, insumos!inner(id, nombre, categoria_id, unidad)")
          .eq("sucursal_id", sucursalId)
          .eq("activo", true)
          .order("orden"),
        supabase
          .from("pedidos")
          .select("*")
          .eq("sucursal_id", sucursalId)
          .eq("fecha", fecha)
          .order("created_at", { ascending: false })
          .limit(1)
          .maybeSingle(),
      ]);

      if (cancelado) return;

      if (catRes.data) setCategorias(catRes.data);

      const itemRows = (itemsRes.data ?? []) as unknown as ItemRow[];
      const mapped: ItemSucursal[] = itemRows
        // Solo proteínas de la lista oficial: oculta el resto del catálogo
        // aunque la base las tenga asignadas a la sucursal.
        .map((r) => {
          const p = infoProteina(r.insumos.nombre);
          if (!p) return null;
          return {
            insumo_id: r.insumos.id,
            nombre: p.display,
            categoria_id: r.insumos.categoria_id,
            unidad: r.unidad || p.unidad || r.insumos.unidad || "pz",
            nivel_par: r.nivel_par,
            costo: r.costo,
            orden: p.orden,
          } as ItemSucursal;
        })
        .filter((x): x is ItemSucursal => x !== null)
        .sort((a, b) => a.orden - b.orden);
      setItems(mapped);

      // Estado base de detalles
      const base: Record<string, Detalle> = {};
      mapped.forEach((it) => (base[it.insumo_id] = detalleVacio()));

      const pedido = pedidoRes.data;
      if (pedido) {
        setPedidoId(pedido.id);
        setEstadoPedido(pedido.estado);
        setEnviadoAt(pedido.enviado_at);
        setNotas(pedido.notas || "");
        const { data: det } = await supabase
          .from("pedidos_detalle")
          .select("*")
          .eq("pedido_id", pedido.id);
        ((det ?? []) as unknown as DetRow[]).forEach((d) => {
          const sug =
            d.cantidad_sugerida === null ? null : Number(d.cantidad_sugerida);
          const ped = Number(d.cantidad_pedida) || 0;
          // El campo "Pedido" de cocina = la solicitud de la sucursal
          // (cantidad_sugerida). cantidad_pedida la maneja el admin aparte.
          const solicitud = sug ?? ped;
          base[d.insumo_id] = {
            existencia: Number(d.existencia) || 0,
            cantidad_pedida: solicitud,
            cantidad_sugerida: sug,
            capturado: true,
            // Ya capturado: no recalcular el sugerido al editar existencia.
            pedidoManual: true,
          };
        });
      }

      // Borrador local (lo más reciente capturado en el dispositivo)
      try {
        const raw = localStorage.getItem(draftKey);
        if (raw && (!pedido || pedido.estado === "borrador" || pedido.estado === "enviado")) {
          const parsed = JSON.parse(raw);
          if (parsed.detalles) {
            Object.entries(parsed.detalles).forEach(([k, v]) => {
              if (base[k]) base[k] = { ...base[k], ...(v as Detalle) };
            });
          }
          // No sobreescribir notas del servidor con un borrador vacío.
          if (typeof parsed.notas === "string" && parsed.notas) setNotas(parsed.notas);
        }
      } catch {
        /* ignorar borrador corrupto */
      }

      setDetalles(base);
      setLoading(false);
      setDraftCargado(true);
    })();

    return () => {
      cancelado = true;
    };
  }, [sucursalId, fecha, draftKey]);

  // ---- Autoguardado del borrador en el dispositivo ----
  useEffect(() => {
    if (!draftCargado || !sucursalId) return;
    try {
      localStorage.setItem(draftKey, JSON.stringify({ detalles, notas }));
    } catch {
      /* almacenamiento lleno: ignorar */
    }
  }, [detalles, notas, draftCargado, draftKey, sucursalId]);

  const itemsPorCategoria = useCallback(
    (categoriaId: string) =>
      items.filter((i) => i.categoria_id === categoriaId),
    [items]
  );

  const setExistencia = (item: ItemSucursal, value: number) => {
    setDetalles((prev) => {
      const cur = prev[item.insumo_id] || detalleVacio();
      const sugerido =
        item.nivel_par != null ? Math.max(0, item.nivel_par - value) : null;
      return {
        ...prev,
        [item.insumo_id]: {
          ...cur,
          existencia: value,
          capturado: true,
          cantidad_sugerida: sugerido,
          // Pre-llenar "Pides" con el sugerido salvo que el encargado ya lo haya tocado.
          cantidad_pedida: cur.pedidoManual
            ? cur.cantidad_pedida
            : sugerido ?? cur.cantidad_pedida,
        },
      };
    });
  };

  const setPedida = (item: ItemSucursal, value: number) => {
    setDetalles((prev) => {
      const cur = prev[item.insumo_id] || detalleVacio();
      return {
        ...prev,
        [item.insumo_id]: {
          ...cur,
          cantidad_pedida: value,
          pedidoManual: true,
          capturado: true,
        },
      };
    });
  };

  const total = items.length;
  const listos = useMemo(
    () => items.filter((i) => detalles[i.insumo_id]?.capturado).length,
    [items, detalles]
  );
  const renglonesPedido = useMemo(
    () => items.filter((i) => (detalles[i.insumo_id]?.cantidad_pedida || 0) > 0),
    [items, detalles]
  );

  const yaRecibido = estadoPedido === "recibido" || estadoPedido === "recibido_parcial" || estadoPedido === "cerrado";

  const handleEnviar = async () => {
    if (!sucursalId) return;
    if (!registradoPor.trim()) {
      toast.error("Escribe quién hace el pedido");
      return;
    }
    if (renglonesPedido.length === 0) {
      toast.error("Agrega al menos un insumo con cantidad a pedir");
      return;
    }
    setEnviando(true);
    try {
      let id = pedidoId;
      const ahora = new Date().toISOString();

      // 1) Asegurar el pedido (si es nuevo, como borrador). El paso a "enviado"
      //    se hace AL FINAL, para no dejar un pedido enviado con detalle parcial.
      if (!id) {
        const { data, error } = await supabase
          .from("pedidos")
          .insert({
            sucursal_id: sucursalId,
            fecha,
            estado: "borrador",
            registrado_por: registradoPor || null,
            notas: notas || null,
          })
          .select()
          .single();
        if (error) {
          // Otro dispositivo/exhibición ya creó el pedido del día (choca el
          // único sucursal+fecha): reusamos ese en vez de fallar.
          const { data: existente } = await supabase
            .from("pedidos")
            .select("id")
            .eq("sucursal_id", sucursalId)
            .eq("fecha", fecha)
            .order("created_at", { ascending: false })
            .limit(1)
            .maybeSingle();
          if (!existente) throw error;
          id = existente.id;
        } else {
          id = data.id;
        }
        setPedidoId(id);
      }

      const aGuardar = items.filter((i) => {
        const d = detalles[i.insumo_id];
        return d && (d.cantidad_pedida > 0 || d.capturado);
      });

      // Renglones que ya existen en este pedido (para no pisar lo que el admin
      // haya capturado en cantidad_pedida).
      const { data: existRows } = await supabase
        .from("pedidos_detalle")
        .select("id, insumo_id")
        .eq("pedido_id", id);
      const existentes = new Map(
        ((existRows ?? []) as { id: string; insumo_id: string }[]).map((r) => [r.insumo_id, r.id])
      );

      // Nuevos: se insertan con cantidad_pedida = la solicitud (default a ajustar).
      const nuevos = aGuardar
        .filter((i) => !existentes.has(i.insumo_id))
        .map((i) => {
          const d = detalles[i.insumo_id];
          return {
            pedido_id: id,
            insumo_id: i.insumo_id,
            existencia: d.existencia,
            cantidad_sugerida: d.cantidad_pedida,
            cantidad_pedida: d.cantidad_pedida,
          };
        });
      if (nuevos.length) {
        const { error } = await supabase.from("pedidos_detalle").insert(nuevos);
        if (error) throw error;
      }

      // Existentes: solo existencia + solicitud (NO cantidad_pedida del admin).
      const actualizaciones = aGuardar
        .filter((i) => existentes.has(i.insumo_id))
        .map((i) => {
          const d = detalles[i.insumo_id];
          return supabase
            .from("pedidos_detalle")
            .update({ existencia: d.existencia, cantidad_sugerida: d.cantidad_pedida })
            .eq("id", existentes.get(i.insumo_id) as string);
        });
      const resultados = await Promise.all(actualizaciones);
      const errUpd = resultados.find((r) => r.error);
      if (errUpd?.error) throw errUpd.error;

      // 3) Último paso: marcar enviado (detalle ya quedó completo).
      const { error: estadoErr } = await supabase
        .from("pedidos")
        .update({
          estado: "enviado",
          enviado_at: ahora,
          registrado_por: registradoPor || null,
          notas: notas || null,
        })
        .eq("id", id);
      if (estadoErr) throw estadoErr;

      setEstadoPedido("enviado");
      setEnviadoAt(ahora);
      localStorage.removeItem(draftKey);
      setRevisar(false);
      toast.success(`Pedido enviado a las ${getHoraNegocio(ahora)} ✓`);
    } catch (error) {
      console.error("Error al enviar pedido:", error);
      toast.error("No se pudo enviar el pedido. Intenta de nuevo.");
    } finally {
      setEnviando(false);
    }
  };

  if (!sucursalId) return null;

  return (
    <div className="min-h-screen bg-gradient-to-br from-primary/5 to-secondary/10 pb-28">
      {/* Header */}
      <div className="bg-background border-b sticky top-0 z-20">
        <div className="container mx-auto px-3 py-2 flex items-center gap-3 max-w-2xl">
          <Button variant="ghost" size="icon" onClick={() => navigate("/pedidos")}>
            <ArrowLeft className="h-5 w-5" />
          </Button>
          <img src={logoLaOla} alt="La Ola" className="w-8 h-8 rounded-full object-cover" />
          <div className="flex-1">
            <h1 className="text-base font-semibold leading-tight">Hacer Pedido</h1>
            <p className="text-xs text-muted-foreground flex items-center gap-1">
              <MapPin className="h-3 w-3" /> {sucursalNombre}
            </p>
          </div>
          {!online && (
            <Badge variant="secondary" className="gap-1">
              <WifiOff className="h-3 w-3" /> Sin conexión
            </Badge>
          )}
        </div>
        {/* Barra de progreso */}
        {!loading && total > 0 && (
          <div className="container mx-auto px-3 pb-2 max-w-2xl">
            <div className="flex items-center justify-between text-xs mb-1">
              <span className="font-medium">
                {listos} de {total} listos
              </span>
              {estadoPedido === "enviado" && enviadoAt && (
                <span className="text-emerald-600 font-medium">
                  Enviado {getHoraNegocio(enviadoAt)}
                </span>
              )}
            </div>
            <Progress value={total ? (listos / total) * 100 : 0} className="h-2" />
          </div>
        )}
      </div>

      <div className="container mx-auto px-3 py-4 max-w-2xl space-y-4">
        {loading ? (
          <div className="flex justify-center py-16">
            <Loader2 className="h-8 w-8 animate-spin text-primary" />
          </div>
        ) : items.length === 0 ? (
          <Card>
            <CardContent className="p-8 text-center text-muted-foreground text-sm">
              Esta sucursal no tiene insumos asignados todavía. El administrador
              debe configurar la lista desde el panel.
            </CardContent>
          </Card>
        ) : (
          <>
            {yaRecibido && (
              <Card className="border-emerald-300 bg-emerald-50">
                <CardContent className="p-4 text-sm text-emerald-800">
                  El pedido de hoy ya fue recibido. Lo que captures aquí
                  reabrirá el pedido como nuevo envío.
                </CardContent>
              </Card>
            )}

            {/* Encargado */}
            <Card className={!registradoPor.trim() ? "border-amber-300" : ""}>
              <CardContent className="p-4 space-y-1.5">
                <Label className="text-sm">¿Quién hace el pedido? *</Label>
                <Input
                  placeholder="Escribe tu nombre"
                  value={registradoPor}
                  onChange={(e) => setRegistradoPor(e.target.value)}
                  className="h-11"
                />
              </CardContent>
            </Card>

            {/* Insumos por categoría */}
            {categorias.map((cat) => {
              const its = itemsPorCategoria(cat.id);
              if (its.length === 0) return null;
              return (
                <div key={cat.id} className="space-y-2">
                  <h2 className="text-sm font-bold uppercase tracking-wide text-muted-foreground px-1">
                    {cat.nombre}
                  </h2>
                  {its.map((item) => {
                    const d = detalles[item.insumo_id] || detalleVacio();
                    return (
                      <Card
                        key={item.insumo_id}
                        className={
                          d.capturado ? "border-emerald-300 bg-emerald-50/40" : ""
                        }
                      >
                        <CardContent className="p-4 space-y-3">
                          <div className="flex items-center gap-2">
                            {d.capturado ? (
                              <CheckCircle2 className="h-5 w-5 text-emerald-500 shrink-0" />
                            ) : (
                              <Circle className="h-5 w-5 text-muted-foreground/40 shrink-0" />
                            )}
                            <span className="font-semibold text-base flex-1">
                              {item.nombre}
                            </span>
                            <Badge variant="outline" className="uppercase text-xs">
                              {item.unidad}
                            </Badge>
                          </div>

                          <div className="grid grid-cols-2 gap-3">
                            <div className="space-y-1">
                              <Label className="text-xs text-muted-foreground">
                                Existencia
                              </Label>
                              <CantidadStepper
                                value={d.existencia}
                                unidad={item.unidad}
                                onChange={(v) => setExistencia(item, v)}
                              />
                            </div>
                            <div className="space-y-1">
                              <Label className="text-xs text-muted-foreground">
                                Pedido
                                {item.nivel_par != null && (
                                  <span className="ml-1 text-muted-foreground/70">
                                    (par {item.nivel_par})
                                  </span>
                                )}
                              </Label>
                              <CantidadStepper
                                value={d.cantidad_pedida}
                                unidad={item.unidad}
                                emphasis
                                onChange={(v) => setPedida(item, v)}
                              />
                            </div>
                          </div>
                        </CardContent>
                      </Card>
                    );
                  })}
                </div>
              );
            })}
          </>
        )}
      </div>

      {/* Barra inferior fija */}
      {!loading && items.length > 0 && (
        <div className="fixed bottom-0 inset-x-0 bg-background border-t z-20">
          <div className="container mx-auto px-3 py-3 max-w-2xl">
            <Button
              className="w-full h-14 text-lg gap-2"
              onClick={() => setRevisar(true)}
              disabled={renglonesPedido.length === 0}
            >
              <ClipboardList className="h-5 w-5" />
              Revisar pedido ({renglonesPedido.length})
            </Button>
          </div>
        </div>
      )}

      {/* Hoja de revisión */}
      <Sheet open={revisar} onOpenChange={setRevisar}>
        <SheetContent side="bottom" className="max-h-[85vh] flex flex-col">
          <SheetHeader>
            <SheetTitle>Revisar pedido · {sucursalNombre}</SheetTitle>
          </SheetHeader>
          <div className="flex-1 overflow-y-auto py-2 divide-y">
            {renglonesPedido.length === 0 ? (
              <p className="text-center text-muted-foreground py-8 text-sm">
                No hay insumos con cantidad a pedir.
              </p>
            ) : (
              renglonesPedido.map((item) => {
                const d = detalles[item.insumo_id];
                return (
                  <div
                    key={item.insumo_id}
                    className="flex items-center justify-between py-2.5"
                  >
                    <span className="text-sm">{item.nombre}</span>
                    <span className="font-semibold">
                      {d.cantidad_pedida} {item.unidad}
                    </span>
                  </div>
                );
              })
            )}
          </div>
          <div className="space-y-1.5 py-2">
            <Label className="text-sm">¿Quién hace el pedido? *</Label>
            <Input
              placeholder="Escribe tu nombre"
              value={registradoPor}
              onChange={(e) => setRegistradoPor(e.target.value)}
              className={`h-11 ${!registradoPor.trim() ? "border-amber-400" : ""}`}
            />
            <Label className="text-sm pt-1">Notas (opcional)</Label>
            <Input
              placeholder="Observaciones del pedido…"
              value={notas}
              onChange={(e) => setNotas(e.target.value)}
              className="h-11"
            />
          </div>
          <SheetFooter>
            <Button
              className="w-full h-14 text-lg gap-2"
              onClick={handleEnviar}
              disabled={enviando || !online || renglonesPedido.length === 0 || !registradoPor.trim()}
            >
              {enviando ? (
                <Loader2 className="h-5 w-5 animate-spin" />
              ) : (
                <Send className="h-5 w-5" />
              )}
              {estadoPedido === "enviado" ? "Actualizar pedido" : "Enviar pedido"}
            </Button>
          </SheetFooter>
        </SheetContent>
      </Sheet>
    </div>
  );
}
