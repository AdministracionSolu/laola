import { useEffect, useState } from "react";
import { useParams, Navigate } from "react-router-dom";
import { supabase } from "@/integrations/supabase/client";
import { Loader2, MapPin, WifiOff } from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";

// Liga/QR por sucursal: fija la sucursal (bloqueada) y entra al destino.
export default function EntrarSucursal({ destino = "/pedidos" }: { destino?: string }) {
  const { sucursalId = "" } = useParams();
  const [estado, setEstado] = useState<"cargando" | "ok" | "error" | "red">("cargando");
  const [intento, setIntento] = useState(0);

  useEffect(() => {
    let cancelado = false;
    setEstado("cargando");
    supabase
      .from("sucursales")
      .select("id, nombre")
      .eq("id", sucursalId)
      .maybeSingle()
      .then(({ data, error }) => {
        if (cancelado) return;
        if (data) {
          localStorage.setItem("laola_sucursal_id", data.id);
          localStorage.setItem("laola_sucursal_nombre", data.nombre);
          localStorage.setItem("laola_sucursal_bloqueada", "1");
          setEstado("ok");
        } else if (error) {
          // Falla de red/servidor: no es que la liga sea inválida.
          setEstado("red");
        } else {
          setEstado("error");
        }
      });
    return () => {
      cancelado = true;
    };
  }, [sucursalId, intento]);

  if (estado === "ok") return <Navigate to={destino} replace />;

  if (estado === "red") {
    return (
      <div className="min-h-screen flex items-center justify-center p-4 bg-gradient-to-br from-primary/5 to-secondary/10">
        <Card className="max-w-sm w-full">
          <CardContent className="p-8 text-center space-y-3">
            <WifiOff className="h-10 w-10 mx-auto text-muted-foreground/40" />
            <p className="font-semibold">Sin conexión</p>
            <p className="text-sm text-muted-foreground">
              No se pudo conectar. Revisa tu internet e inténtalo otra vez.
            </p>
            <Button variant="outline" onClick={() => setIntento((n) => n + 1)}>
              Reintentar
            </Button>
          </CardContent>
        </Card>
      </div>
    );
  }

  if (estado === "error") {
    return (
      <div className="min-h-screen flex items-center justify-center p-4 bg-gradient-to-br from-primary/5 to-secondary/10">
        <Card className="max-w-sm w-full">
          <CardContent className="p-8 text-center space-y-2">
            <MapPin className="h-10 w-10 mx-auto text-muted-foreground/40" />
            <p className="font-semibold">Liga no válida</p>
            <p className="text-sm text-muted-foreground">
              Esta liga de sucursal no existe. Pide el QR correcto al restaurante.
            </p>
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="min-h-screen flex items-center justify-center">
      <Loader2 className="h-8 w-8 animate-spin text-primary" />
    </div>
  );
}
