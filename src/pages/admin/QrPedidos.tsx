import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { QRCodeSVG } from "qrcode.react";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { ArrowLeft, Printer, Loader2 } from "lucide-react";
import logoLaOla from "@/assets/logo-la-ola.jpeg";

interface Sucursal {
  id: string;
  nombre: string;
}

export default function QrPedidos() {
  const navigate = useNavigate();
  const [sucursales, setSucursales] = useState<Sucursal[]>([]);
  const [loading, setLoading] = useState(true);
  const origin = typeof window !== "undefined" ? window.location.origin : "";

  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => {
      if (!session) {
        navigate("/admin/login");
        return;
      }
      supabase
        .from("sucursales")
        .select("id, nombre")
        .order("nombre")
        .then(({ data }) => {
          setSucursales((data ?? []) as Sucursal[]);
          setLoading(false);
        });
    });
  }, [navigate]);

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <Loader2 className="h-8 w-8 animate-spin text-primary" />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-primary/5 to-secondary/10">
      {/* Barra (se oculta al imprimir) */}
      <div className="bg-background border-b sticky top-0 z-10 print:hidden">
        <div className="container mx-auto px-3 py-2 flex items-center gap-3">
          <Button variant="ghost" size="icon" onClick={() => navigate("/admin/dashboard")}>
            <ArrowLeft className="h-5 w-5" />
          </Button>
          <div className="flex-1">
            <h1 className="text-base font-semibold">QR de Pedidos por sucursal</h1>
            <p className="text-xs text-muted-foreground">Imprime, plastifica y pégalos en cada cocina</p>
          </div>
          <Button className="gap-2" onClick={() => window.print()}>
            <Printer className="h-4 w-4" /> Imprimir
          </Button>
        </div>
      </div>

      <div className="container mx-auto px-3 py-4 max-w-4xl">
        <p className="text-sm text-muted-foreground mb-4 print:hidden">
          Cada QR abre directo el pedido de su sucursal (sin poder cambiarla). Al imprimir,
          sale uno por hoja.
        </p>
        <div className="grid sm:grid-cols-2 gap-4 print:block">
          {sucursales.map((s) => {
            const url = `${origin}/pedidos/s/${s.id}`;
            return (
              <Card
                key={s.id}
                className="print:break-after-page print:shadow-none print:border-2 print:min-h-screen print:flex print:items-center"
              >
                <CardContent className="p-6 flex flex-col items-center text-center gap-3 w-full">
                  <img src={logoLaOla} alt="La Ola" className="w-14 h-14 rounded-full object-cover" />
                  <div>
                    <p className="text-sm text-muted-foreground">La Ola — Pedidos</p>
                    <h2 className="text-3xl font-bold">{s.nombre}</h2>
                  </div>
                  <div className="bg-white p-3 rounded-lg border">
                    <QRCodeSVG value={url} size={220} level="M" marginSize={2} />
                  </div>
                  <p className="text-base font-medium">Escanea para hacer el pedido</p>
                  <p className="text-xs text-muted-foreground break-all">{url}</p>
                </CardContent>
              </Card>
            );
          })}
        </div>
      </div>
    </div>
  );
}
