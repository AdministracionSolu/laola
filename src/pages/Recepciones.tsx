import { useState, useEffect, useMemo, useCallback } from "react";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import { ArrowLeft, Check, Loader2, MapPin, WifiOff, PackageCheck } from "lucide-react";
import { useNavigate } from "react-router-dom";
import { supabase } from "@/integrations/supabase/client";
import { toast } from "sonner";
import logoLaOla from "@/assets/logo-la-ola.jpeg";
import { useSucursal } from "@/contexts/SucursalContext";
import { useOnlineStatus } from "@/hooks/useOnlineStatus";
import { getFechaCalendario } from "@/lib/fecha";
import { CantidadStepper } from "@/components/operaciones/CantidadStepper";
import { infoProteina } from "@/lib/proteinas";

interface Categoria {
  id: string;
  nombre: string;
  orden: number;
}

interface Renglon {
  insumo_id: string;
  nombre: string;
  unidad: string;
  categoria_id: string;
  pedido_detalle_id: string | null;
  orden: number;
}

export default function Recepciones() {
  const navigate = useNavigate();
  const online = useOnlineStatus();
  const { sucursalId, sucursalNombre, registradoPor, setRegistradoPor } =
    useSucursal();

  const [loading, setLoading] = useState(true);
  const [guardando, setGuardando] = useState(false);
  const [categorias, setCategorias] = useState<Categoria[]>([]);
  const [pedidoId, setPedidoId] = useState<string | null>(null);
  const [proveedor, setProveedor] = useState("");
  const [renglones, setRenglones] = useState<Renglon[]>([]);
  // Lo que se está capturando AHORA (vacío por defecto).
  const [recibido, setRecibido] = useState<Record<string, number>>({});
  // Acumulado ya registrado hoy por insumo (no se compara con el pedido).
  const [yaRecibido, setYaRecibido] = useState<Record<string, number>>({});

  // Suma lo ya recibido hoy por insumo (de recepciones previas del pedido).
  const cargarYaRecibido = useCallback(async (detalleIds: string[]) => {
    if (detalleIds.length === 0) {
      setYaRecibido({});
      return;
    }
    const { data } = await supabase
      .from("recepciones_detalle")
      .select("insumo_id, cantidad_recibida, pedido_detalle_id")
      .in("pedido_detalle_id", detalleIds);
    const acc: Record<string, number> = {};
    (data || []).forEach((r: { insumo_id: string; cantidad_recibida: number }) => {
      acc[r.insumo_id] = (acc[r.insumo_id] || 0) + Number(r.cantidad_recibida || 0);
    });
    setYaRecibido(acc);
  }, []);

  useEffect(() => {
    if (!sucursalId) return;
    let cancelado = false;

    (async () => {
      setLoading(true);
      const [catRes, pedidoRes] = await Promise.all([
        supabase.from("categorias_insumos").select("*").order("orden"),
        // Último pedido ENVIADO (o parcial) de la sucursal = la entrega que se recibe.
        // Se ordena por enviado_at (cuándo se mandó), no por created_at (cuándo se abrió el borrador).
        supabase
          .from("pedidos")
          .select("*")
          .eq("sucursal_id", sucursalId)
          .in("estado", ["enviado", "recibido_parcial"])
          .order("enviado_at", { ascending: false, nullsFirst: false })
          .limit(1)
          .maybeSingle(),
      ]);

      if (cancelado) return;
      if (catRes.data) setCategorias(catRes.data);

      const pedido = pedidoRes.data;
      if (!pedido) {
        setPedidoId(null);
        setRenglones([]);
        setLoading(false);
        return;
      }

      setPedidoId(pedido.id);

      // Renglones = lo que se pidió (nombres, SIN mostrar cantidades).
      const { data: det } = await supabase
        .from("pedidos_detalle")
        .select("id, insumo_id, cantidad_pedida, insumos!inner(nombre, categoria_id, unidad)")
        .eq("pedido_id", pedido.id);

      type DetRow = {
        id: string;
        insumo_id: string;
        cantidad_pedida: number;
        insumos: { nombre: string; categoria_id: string; unidad: string | null };
      };
      const rs: Renglon[] = ((det ?? []) as unknown as DetRow[])
        .filter((d) => Number(d.cantidad_pedida) > 0)
        .map((d) => {
          const p = infoProteina(d.insumos.nombre);
          return {
            insumo_id: d.insumo_id,
            nombre: p?.display ?? d.insumos.nombre,
            unidad: d.insumos.unidad || p?.unidad || "pz",
            categoria_id: d.insumos.categoria_id,
            pedido_detalle_id: d.id,
            orden: p?.orden ?? 999,
          };
        })
        .sort((a, b) => a.orden - b.orden);

      setRenglones(rs);
      await cargarYaRecibido(rs.map((r) => r.pedido_detalle_id!).filter(Boolean));
      setRecibido({});
      setLoading(false);
    })();

    return () => {
      cancelado = true;
    };
  }, [sucursalId, cargarYaRecibido]);

  const setCantidad = (insumoId: string, value: number) =>
    setRecibido((prev) => ({ ...prev, [insumoId]: value }));

  const renglonesPorCategoria = useCallback(
    (categoriaId: string) => renglones.filter((r) => r.categoria_id === categoriaId),
    [renglones]
  );

  const capturados = useMemo(
    () => renglones.filter((r) => (recibido[r.insumo_id] || 0) > 0),
    [renglones, recibido]
  );

  const handleRegistrar = async () => {
    if (!sucursalId || !pedidoId) return;
    if (guardando) return; // guard anti doble-tap
    if (!registradoPor.trim()) {
      toast.error("Escribe quién recibió");
      return;
    }
    if (!proveedor.trim()) {
      toast.error("Escribe el nombre del proveedor");
      return;
    }
    if (capturados.length === 0) {
      toast.error("Pon la cantidad de al menos un insumo que llegó");
      return;
    }
    setGuardando(true);
    try {
      const { data: recepcion, error: recError } = await supabase
        .from("recepciones")
        .insert({
          sucursal_id: sucursalId,
          proveedor: proveedor.trim(),
          fecha: getFechaCalendario(),
          registrado_por: registradoPor.trim(),
        })
        .select()
        .single();
      if (recError) throw recError;

      const detallesInsert = capturados.map((r) => ({
        recepcion_id: recepcion.id,
        insumo_id: r.insumo_id,
        cantidad_recibida: recibido[r.insumo_id],
        pedido_detalle_id: r.pedido_detalle_id,
      }));
      const { error: detError } = await supabase
        .from("recepciones_detalle")
        .insert(detallesInsert);
      if (detError) throw detError;

      // Marca que ya empezó a recibirse (puede seguir llegando más).
      await supabase.from("pedidos").update({ estado: "recibido_parcial" }).eq("id", pedidoId);

      toast.success(`Registrado lo que llegó (${capturados.length}) ✓`);
      // Limpia para la siguiente entrega (otro proveedor / otro momento).
      setRecibido({});
      setProveedor("");
      await cargarYaRecibido(renglones.map((r) => r.pedido_detalle_id!).filter(Boolean));
    } catch (error) {
      console.error("Error al registrar recepción:", error);
      toast.error("No se pudo registrar. Intenta de nuevo.");
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
          <Button variant="ghost" size="icon" onClick={() => navigate("/pedidos")}>
            <ArrowLeft className="h-5 w-5" />
          </Button>
          <img src={logoLaOla} alt="La Ola" className="w-8 h-8 rounded-full object-cover" />
          <div className="flex-1">
            <h1 className="text-base font-semibold leading-tight">Registrar lo que llegó</h1>
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
                No hay un pedido enviado todavía. Primero haz el pedido.
              </p>
              <Button onClick={() => navigate("/pedidos/hacer")}>Ir a hacer pedido</Button>
            </CardContent>
          </Card>
        ) : (
          <>
            <p className="text-xs text-muted-foreground px-1">
              Pon solo lo que llegó ahora. Puedes registrar varias veces durante el día
              (cada entrega/proveedor por separado) y se va sumando.
            </p>

            <Card className={!registradoPor.trim() || !proveedor.trim() ? "border-amber-300" : ""}>
              <CardContent className="p-4 space-y-3">
                <div className="space-y-1.5">
                  <Label className="text-sm">¿Quién recibió? *</Label>
                  <Input
                    placeholder="Escribe tu nombre"
                    value={registradoPor}
                    onChange={(e) => setRegistradoPor(e.target.value)}
                    className="h-11"
                  />
                </div>
                <div className="space-y-1.5">
                  <Label className="text-sm">Proveedor *</Label>
                  <Input
                    placeholder="Nombre del proveedor que entregó"
                    value={proveedor}
                    onChange={(e) => setProveedor(e.target.value)}
                    className="h-11"
                  />
                </div>
              </CardContent>
            </Card>

            {categorias.map((cat) => {
              const rs = renglonesPorCategoria(cat.id);
              if (rs.length === 0) return null;
              return (
                <div key={cat.id} className="space-y-2">
                  <h2 className="text-sm font-bold uppercase tracking-wide text-muted-foreground px-1">
                    {cat.nombre}
                  </h2>
                  {rs.map((r) => (
                    <Card key={r.insumo_id}>
                      <CardContent className="p-4 space-y-3">
                        <div className="flex items-center gap-2">
                          <span className="font-semibold text-base flex-1">{r.nombre}</span>
                          <Badge variant="outline" className="uppercase text-xs">{r.unidad}</Badge>
                        </div>
                        <div className="space-y-1">
                          <Label className="text-xs text-muted-foreground flex items-center gap-2">
                            ¿Cuánto llegó?
                            {(yaRecibido[r.insumo_id] || 0) > 0 && (
                              <span className="text-emerald-600">
                                · ya recibido de este pedido: {yaRecibido[r.insumo_id]} {r.unidad}
                              </span>
                            )}
                          </Label>
                          <CantidadStepper
                            value={recibido[r.insumo_id] || 0}
                            unidad={r.unidad}
                            emphasis
                            onChange={(v) => setCantidad(r.insumo_id, v)}
                          />
                        </div>
                      </CardContent>
                    </Card>
                  ))}
                </div>
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
              onClick={handleRegistrar}
              disabled={guardando || !online || capturados.length === 0 || !registradoPor.trim() || !proveedor.trim()}
            >
              {guardando ? <Loader2 className="h-5 w-5 animate-spin" /> : <Check className="h-5 w-5" />}
              Registrar lo que llegó ({capturados.length})
            </Button>
          </div>
        </div>
      )}
    </div>
  );
}
