import { useState, useEffect, useMemo } from "react";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import {
  ArrowLeft,
  Check,
  Loader2,
  MapPin,
  PackageCheck,
  WifiOff,
} from "lucide-react";
import { useNavigate } from "react-router-dom";
import { supabase } from "@/integrations/supabase/client";
import { toast } from "sonner";
import logoLaOla from "@/assets/logo-la-ola.jpeg";
import { useSucursal } from "@/contexts/SucursalContext";
import { useOnlineStatus } from "@/hooks/useOnlineStatus";
import { getFechaNegocio, getHoraNegocio } from "@/lib/fecha";
import { CantidadStepper } from "@/components/operaciones/CantidadStepper";

interface Renglon {
  pedido_detalle_id: string;
  insumo_id: string;
  nombre: string;
  unidad: string;
  cantidad_pedida: number;
  cantidad_recibida: number;
}

export default function Recepciones() {
  const navigate = useNavigate();
  const online = useOnlineStatus();
  const { sucursalId, sucursalNombre, registradoPor, setRegistradoPor } =
    useSucursal();
  const fecha = getFechaNegocio();

  const [loading, setLoading] = useState(true);
  const [guardando, setGuardando] = useState(false);
  const [pedidoId, setPedidoId] = useState<string | null>(null);
  const [estadoPedido, setEstadoPedido] = useState<string | null>(null);
  const [enviadoAt, setEnviadoAt] = useState<string | null>(null);
  const [renglones, setRenglones] = useState<Renglon[]>([]);

  useEffect(() => {
    if (!sucursalId) return;
    let cancelado = false;

    (async () => {
      setLoading(true);
      const { data: pedido } = await supabase
        .from("pedidos")
        .select("*")
        .eq("sucursal_id", sucursalId)
        .eq("fecha", fecha)
        .order("created_at", { ascending: false })
        .limit(1)
        .maybeSingle();

      if (cancelado) return;

      if (!pedido || pedido.estado === "borrador") {
        setPedidoId(null);
        setEstadoPedido(pedido?.estado ?? null);
        setRenglones([]);
        setLoading(false);
        return;
      }

      setPedidoId(pedido.id);
      setEstadoPedido(pedido.estado);
      setEnviadoAt(pedido.enviado_at);

      const { data: det } = await supabase
        .from("pedidos_detalle")
        .select("id, insumo_id, cantidad_pedida, insumos!inner(nombre, unidad)")
        .eq("pedido_id", pedido.id);

      type DetRow = {
        id: string;
        insumo_id: string;
        cantidad_pedida: number;
        insumos: { nombre: string; unidad: string | null };
      };
      const rs: Renglon[] = ((det ?? []) as unknown as DetRow[])
        .filter((d) => Number(d.cantidad_pedida) > 0)
        .map((d) => ({
          pedido_detalle_id: d.id,
          insumo_id: d.insumo_id,
          nombre: d.insumos.nombre,
          unidad: d.insumos.unidad || "pz",
          cantidad_pedida: Number(d.cantidad_pedida) || 0,
          // Pre-llenado: llegó todo lo pedido (caso normal).
          cantidad_recibida: Number(d.cantidad_pedida) || 0,
        }));

      setRenglones(rs);
      setLoading(false);
    })();

    return () => {
      cancelado = true;
    };
  }, [sucursalId, fecha]);

  const setRecibida = (insumoId: string, value: number) => {
    setRenglones((prev) =>
      prev.map((r) =>
        r.insumo_id === insumoId ? { ...r, cantidad_recibida: value } : r
      )
    );
  };

  const hayDiferencias = useMemo(
    () => renglones.some((r) => r.cantidad_recibida !== r.cantidad_pedida),
    [renglones]
  );

  const yaRecibido =
    estadoPedido === "recibido" ||
    estadoPedido === "recibido_parcial" ||
    estadoPedido === "cerrado";

  const handleConfirmar = async () => {
    if (!sucursalId || !pedidoId) return;
    setGuardando(true);
    try {
      const ahora = new Date().toISOString();
      const { data: recepcion, error: recError } = await supabase
        .from("recepciones")
        .insert({
          sucursal_id: sucursalId,
          proveedor: "Pescadería",
          fecha,
          registrado_por: registradoPor || null,
        })
        .select()
        .single();
      if (recError) throw recError;

      const detallesInsert = renglones.map((r) => ({
        recepcion_id: recepcion.id,
        insumo_id: r.insumo_id,
        cantidad_recibida: r.cantidad_recibida,
        pedido_detalle_id: r.pedido_detalle_id,
      }));
      const { error: detError } = await supabase
        .from("recepciones_detalle")
        .insert(detallesInsert);
      if (detError) throw detError;

      const nuevoEstado = hayDiferencias ? "recibido_parcial" : "recibido";
      const { error: pedError } = await supabase
        .from("pedidos")
        .update({ estado: nuevoEstado })
        .eq("id", pedidoId);
      if (pedError) throw pedError;

      setEstadoPedido(nuevoEstado);
      toast.success(
        hayDiferencias
          ? "Recepción registrada (con diferencias) ✓"
          : "Recepción registrada ✓"
      );
    } catch (error) {
      console.error("Error al registrar recepción:", error);
      toast.error("No se pudo registrar la recepción. Intenta de nuevo.");
    } finally {
      setGuardando(false);
    }
  };

  if (!sucursalId) return null;

  return (
    <div className="min-h-screen bg-gradient-to-br from-primary/5 to-secondary/10 pb-28">
      {/* Header */}
      <div className="bg-background border-b sticky top-0 z-20">
        <div className="container mx-auto px-3 py-2 flex items-center gap-3 max-w-2xl">
          <Button variant="ghost" size="icon" onClick={() => navigate("/centro-de-operaciones")}>
            <ArrowLeft className="h-5 w-5" />
          </Button>
          <img src={logoLaOla} alt="La Ola" className="w-8 h-8 rounded-full object-cover" />
          <div className="flex-1">
            <h1 className="text-base font-semibold leading-tight">
              Registrar lo que llegó
            </h1>
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
      </div>

      <div className="container mx-auto px-3 py-4 max-w-2xl space-y-4">
        {loading ? (
          <div className="flex justify-center py-16">
            <Loader2 className="h-8 w-8 animate-spin text-primary" />
          </div>
        ) : !pedidoId ? (
          <Card>
            <CardContent className="p-8 text-center space-y-3">
              <PackageCheck className="h-10 w-10 mx-auto text-muted-foreground/50" />
              <p className="text-sm text-muted-foreground">
                No hay un pedido enviado hoy. Primero haz el pedido para poder
                registrar lo que llegó.
              </p>
              <Button onClick={() => navigate("/centro-de-operaciones/pedidos")}>
                Ir a hacer pedido
              </Button>
            </CardContent>
          </Card>
        ) : (
          <>
            {yaRecibido && (
              <Card className="border-emerald-300 bg-emerald-50">
                <CardContent className="p-4 text-sm text-emerald-800">
                  Ya registraste lo que llegó para el pedido de hoy. Puedes
                  corregir y volver a confirmar si hubo un ajuste.
                </CardContent>
              </Card>
            )}

            {enviadoAt && (
              <p className="text-xs text-muted-foreground px-1">
                Pedido enviado {getHoraNegocio(enviadoAt)} — confirma las
                cantidades que llegaron.
              </p>
            )}

            <Card>
              <CardContent className="p-4 space-y-1.5">
                <Label className="text-sm">¿Quién recibió?</Label>
                <Input
                  placeholder="Tu nombre"
                  value={registradoPor}
                  onChange={(e) => setRegistradoPor(e.target.value)}
                  className="h-11"
                />
              </CardContent>
            </Card>

            {renglones.map((r) => {
              const diff = r.cantidad_recibida !== r.cantidad_pedida;
              return (
                <Card
                  key={r.insumo_id}
                  className={diff ? "border-amber-300 bg-amber-50/50" : ""}
                >
                  <CardContent className="p-4 space-y-3">
                    <div className="flex items-center gap-2">
                      <span className="font-semibold text-base flex-1">
                        {r.nombre}
                      </span>
                      <Badge variant="outline" className="text-xs">
                        Pedido: {r.cantidad_pedida} {r.unidad}
                      </Badge>
                    </div>
                    <div className="space-y-1">
                      <Label className="text-xs text-muted-foreground">
                        ¿Cuánto llegó?
                        {diff && (
                          <span className="ml-2 text-amber-600 font-medium">
                            ≠ pedido
                          </span>
                        )}
                      </Label>
                      <CantidadStepper
                        value={r.cantidad_recibida}
                        unidad={r.unidad}
                        emphasis
                        onChange={(v) => setRecibida(r.insumo_id, v)}
                      />
                    </div>
                  </CardContent>
                </Card>
              );
            })}
          </>
        )}
      </div>

      {/* Barra inferior fija */}
      {!loading && pedidoId && renglones.length > 0 && (
        <div className="fixed bottom-0 inset-x-0 bg-background border-t z-20">
          <div className="container mx-auto px-3 py-3 max-w-2xl">
            <Button
              className="w-full h-14 text-lg gap-2"
              onClick={handleConfirmar}
              disabled={guardando}
            >
              {guardando ? (
                <Loader2 className="h-5 w-5 animate-spin" />
              ) : (
                <Check className="h-5 w-5" />
              )}
              Confirmar recibido
            </Button>
          </div>
        </div>
      )}
    </div>
  );
}
