import { useEffect, useState } from "react";
import { Button } from "@/components/ui/button";
import { Package, Truck, MapPin, RefreshCw } from "lucide-react";
import { useNavigate } from "react-router-dom";
import logoLaOla from "@/assets/logo-la-ola.jpeg";
import { useSucursal } from "@/contexts/SucursalContext";
import { supabase } from "@/integrations/supabase/client";
import { getFechaNegocio } from "@/lib/fecha";

export default function PedidosHome() {
  const navigate = useNavigate();
  const { sucursalId, sucursalNombre, clearSucursal } = useSucursal();
  const [estado, setEstado] = useState<string | null>(null);

  useEffect(() => {
    if (!sucursalId) return;
    supabase
      .from("pedidos")
      .select("estado")
      .eq("sucursal_id", sucursalId)
      .eq("fecha", getFechaNegocio())
      .order("created_at", { ascending: false })
      .limit(1)
      .maybeSingle()
      .then(({ data }) => {
        setEstado(data?.estado ?? null);
      });
  }, [sucursalId]);

  const yaRecibido =
    estado === "recibido" || estado === "recibido_parcial" || estado === "cerrado";
  const yaEnviado = estado === "enviado" || yaRecibido;

  return (
    <div className="min-h-screen bg-gradient-to-br from-primary/5 to-secondary/10 p-4">
      <div className="max-w-md mx-auto">
        {/* Encabezado con sucursal */}
        <div className="flex items-center gap-3 mb-4">
          <div className="w-12 h-12 rounded-full overflow-hidden shrink-0">
            <img src={logoLaOla} alt="La Ola" className="w-full h-full object-cover" />
          </div>
          <div className="flex-1">
            <h1 className="text-lg font-bold leading-tight">Pedidos</h1>
            <p className="text-sm text-muted-foreground flex items-center gap-1">
              <MapPin className="h-3.5 w-3.5 text-primary" /> {sucursalNombre}
            </p>
          </div>
          <Button variant="ghost" size="sm" className="text-xs gap-1" onClick={clearSucursal}>
            <RefreshCw className="h-3.5 w-3.5" /> Cambiar
          </Button>
        </div>

        {/* 2 acciones — nada más */}
        <div className="grid gap-3">
          <Button
            className="w-full h-24 flex flex-col gap-1 text-lg"
            onClick={() => navigate("/pedidos/hacer")}
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
            onClick={() => navigate("/pedidos/recepcion")}
          >
            <Truck className="w-7 h-7" />
            <span className="font-bold">REGISTRAR LO QUE LLEGÓ</span>
            {yaRecibido && (
              <span className="text-xs font-normal opacity-90">Recibido ✓</span>
            )}
          </Button>
        </div>
      </div>
    </div>
  );
}
