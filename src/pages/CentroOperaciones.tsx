import { useEffect, useState } from "react";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import {
  Calculator,
  CalendarDays,
  Package,
  Truck,
  ClipboardCheck,
  MapPin,
  RefreshCw,
} from "lucide-react";
import { useNavigate } from "react-router-dom";
import logoLaOla from "@/assets/logo-la-ola.jpeg";
import { useSucursal } from "@/contexts/SucursalContext";
import { supabase } from "@/integrations/supabase/client";
import { getFechaNegocio, getHoraNegocio } from "@/lib/fecha";

const ESTADO_LABEL: Record<string, string> = {
  borrador: "Borrador sin enviar",
  enviado: "Enviado",
  recibido: "Recibido",
  recibido_parcial: "Recibido (con diferencias)",
  cerrado: "Cerrado",
};

export default function CentroOperaciones() {
  const navigate = useNavigate();
  const { sucursalId, sucursalNombre, clearSucursal } = useSucursal();
  const [estado, setEstado] = useState<string | null>(null);
  const [enviadoAt, setEnviadoAt] = useState<string | null>(null);

  useEffect(() => {
    if (!sucursalId) return;
    supabase
      .from("pedidos")
      .select("estado, enviado_at")
      .eq("sucursal_id", sucursalId)
      .eq("fecha", getFechaNegocio())
      .order("created_at", { ascending: false })
      .limit(1)
      .maybeSingle()
      .then(({ data }) => {
        setEstado(data?.estado ?? null);
        setEnviadoAt(data?.enviado_at ?? null);
      });
  }, [sucursalId]);

  const yaRecibido =
    estado === "recibido" || estado === "recibido_parcial" || estado === "cerrado";
  const yaEnviado = estado === "enviado" || yaRecibido;

  const estadoTexto = () => {
    if (!estado || estado === "borrador") return "Pedido de hoy: pendiente";
    if (estado === "enviado")
      return `Enviado ${enviadoAt ? getHoraNegocio(enviadoAt) : ""} — esperando entrega`;
    return ESTADO_LABEL[estado] || estado;
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-primary/5 to-secondary/10 p-4">
      <div className="max-w-md mx-auto">
        {/* Encabezado con sucursal */}
        <div className="flex items-center gap-3 mb-4">
          <div className="w-12 h-12 rounded-full overflow-hidden shrink-0">
            <img src={logoLaOla} alt="La Ola" className="w-full h-full object-cover" />
          </div>
          <div className="flex-1">
            <h1 className="text-lg font-bold leading-tight">Centro de Operaciones</h1>
            <p className="text-sm text-muted-foreground flex items-center gap-1">
              <MapPin className="h-3.5 w-3.5 text-primary" /> {sucursalNombre}
            </p>
          </div>
          <Button
            variant="ghost"
            size="sm"
            className="text-xs gap-1"
            onClick={clearSucursal}
          >
            <RefreshCw className="h-3.5 w-3.5" /> Cambiar
          </Button>
        </div>

        {/* Estado del pedido del día */}
        <Card className="mb-3">
          <CardContent className="p-3 flex items-center justify-between">
            <span className="text-sm font-medium">{estadoTexto()}</span>
            {estado && estado !== "borrador" && (
              <Badge
                variant={yaRecibido ? "default" : "secondary"}
                className={yaRecibido ? "bg-emerald-500 hover:bg-emerald-500" : ""}
              >
                {ESTADO_LABEL[estado] || estado}
              </Badge>
            )}
          </CardContent>
        </Card>

        {/* 2 acciones principales */}
        <div className="grid gap-3 mb-3">
          <Button
            className="w-full h-24 flex flex-col gap-1 text-lg"
            onClick={() => navigate("/centro-de-operaciones/pedidos")}
          >
            <Package className="w-7 h-7" />
            <span className="font-bold">HACER PEDIDO</span>
            {yaEnviado && (
              <span className="text-xs font-normal opacity-90">Ya enviado hoy · editar</span>
            )}
          </Button>

          <Button
            variant={yaEnviado ? "default" : "outline"}
            className="w-full h-24 flex flex-col gap-1 text-lg"
            onClick={() => navigate("/centro-de-operaciones/recepciones")}
          >
            <Truck className="w-7 h-7" />
            <span className="font-bold">REGISTRAR LO QUE LLEGÓ</span>
            {yaRecibido && (
              <span className="text-xs font-normal opacity-90">Recibido ✓</span>
            )}
          </Button>
        </div>

        {/* Otros módulos */}
        <div className="grid grid-cols-3 gap-3">
          <Button
            variant="outline"
            className="h-20 flex flex-col gap-1"
            onClick={() => navigate("/centro-de-operaciones/cortes")}
          >
            <Calculator className="w-5 h-5 text-primary" />
            <span className="text-xs font-medium">Cortes</span>
          </Button>
          <Button
            variant="outline"
            className="h-20 flex flex-col gap-1"
            onClick={() => navigate("/centro-de-operaciones/reservaciones")}
          >
            <CalendarDays className="w-5 h-5 text-primary" />
            <span className="text-xs font-medium">Reservas</span>
          </Button>
          <Button
            variant="outline"
            className="h-20 flex flex-col gap-1"
            onClick={() => navigate("/centro-de-operaciones/contadoras")}
          >
            <ClipboardCheck className="w-5 h-5 text-primary" />
            <span className="text-xs font-medium">Contadoras</span>
          </Button>
        </div>
      </div>
    </div>
  );
}
