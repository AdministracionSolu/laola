import { useEffect, useState } from "react";
import { useParams, Navigate } from "react-router-dom";
import { supabase } from "@/integrations/supabase/client";
import { Loader2, MapPin } from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";

// Liga/QR por sucursal: fija la sucursal (bloqueada) y entra al destino.
export default function EntrarSucursal({ destino = "/pedidos" }: { destino?: string }) {
  const { sucursalId = "" } = useParams();
  const [estado, setEstado] = useState<"cargando" | "ok" | "error">("cargando");

  useEffect(() => {
    supabase
      .from("sucursales")
      .select("id, nombre")
      .eq("id", sucursalId)
      .maybeSingle()
      .then(({ data }) => {
        if (data) {
          localStorage.setItem("laola_sucursal_id", data.id);
          localStorage.setItem("laola_sucursal_nombre", data.nombre);
          localStorage.setItem("laola_sucursal_bloqueada", "1");
          setEstado("ok");
        } else {
          setEstado("error");
        }
      });
  }, [sucursalId]);

  if (estado === "ok") return <Navigate to={destino} replace />;

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
