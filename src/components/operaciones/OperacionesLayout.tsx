import { useEffect, useState } from "react";
import { Outlet } from "react-router-dom";
import { supabase } from "@/integrations/supabase/client";
import { SucursalProvider, useSucursal } from "@/contexts/SucursalContext";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import {
  InputOTP,
  InputOTPGroup,
  InputOTPSlot,
} from "@/components/ui/input-otp";
import { MapPin, Loader2, ArrowLeft } from "lucide-react";
import { toast } from "sonner";
import logoLaOla from "@/assets/logo-la-ola.jpeg";

interface SucursalRow {
  id: string;
  nombre: string;
  pin: string | null;
}

function Gate() {
  const { sucursalId, setSucursal } = useSucursal();
  const [sucursales, setSucursales] = useState<SucursalRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [pendiente, setPendiente] = useState<SucursalRow | null>(null);
  const [pin, setPin] = useState("");

  useEffect(() => {
    if (sucursalId) return;
    (async () => {
      // Intenta con PIN; si la columna aún no existe (migración no aplicada),
      // cae a la consulta básica para no dejar la pantalla vacía.
      let { data, error } = await supabase
        .from("sucursales")
        .select("id, nombre, pin")
        .order("nombre");
      if (error) {
        const fallback = await supabase
          .from("sucursales")
          .select("id, nombre")
          .order("nombre");
        data = (fallback.data || []).map((s) => ({ ...s, pin: null })) as SucursalRow[];
      }
      if (data) setSucursales(data as SucursalRow[]);
      setLoading(false);
    })();
  }, [sucursalId]);

  // Ya hay sucursal fijada: continúa a las pantallas de operaciones.
  if (sucursalId) return <Outlet />;

  const elegir = (s: SucursalRow) => {
    if (s.pin) {
      setPendiente(s);
      setPin("");
    } else {
      setSucursal(s.id, s.nombre);
    }
  };

  const confirmarPin = (valor: string) => {
    if (!pendiente) return;
    if (valor === pendiente.pin) {
      setSucursal(pendiente.id, pendiente.nombre);
    } else {
      toast.error("PIN incorrecto");
      setPin("");
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-primary/5 to-secondary/10 flex items-center justify-center p-4">
      <Card className="w-full max-w-md">
        <CardContent className="p-6">
          <div className="text-center mb-6">
            <div className="mx-auto mb-3 w-16 h-16 rounded-full overflow-hidden">
              <img src={logoLaOla} alt="La Ola" className="w-full h-full object-cover" />
            </div>
            {pendiente ? (
              <>
                <h1 className="text-2xl font-bold">{pendiente.nombre}</h1>
                <p className="text-muted-foreground">Ingresa el PIN de la sucursal</p>
              </>
            ) : (
              <>
                <h1 className="text-2xl font-bold">Selecciona tu sucursal</h1>
                <p className="text-muted-foreground">
                  Se recordará en este dispositivo
                </p>
              </>
            )}
          </div>

          {loading ? (
            <div className="flex justify-center py-10">
              <Loader2 className="h-8 w-8 animate-spin text-primary" />
            </div>
          ) : pendiente ? (
            <div className="flex flex-col items-center gap-5">
              <InputOTP
                maxLength={4}
                value={pin}
                onChange={(v) => {
                  setPin(v);
                  if (v.length === 4) confirmarPin(v);
                }}
                autoFocus
              >
                <InputOTPGroup>
                  <InputOTPSlot index={0} className="h-14 w-14 text-2xl" />
                  <InputOTPSlot index={1} className="h-14 w-14 text-2xl" />
                  <InputOTPSlot index={2} className="h-14 w-14 text-2xl" />
                  <InputOTPSlot index={3} className="h-14 w-14 text-2xl" />
                </InputOTPGroup>
              </InputOTP>
              <Button
                variant="ghost"
                className="gap-2"
                onClick={() => setPendiente(null)}
              >
                <ArrowLeft className="h-4 w-4" /> Cambiar sucursal
              </Button>
            </div>
          ) : (
            <div className="grid gap-3">
              {sucursales.map((s) => (
                <Button
                  key={s.id}
                  variant="outline"
                  className="w-full h-20 text-xl font-semibold gap-3 hover:bg-primary/5 hover:border-primary transition-all"
                  onClick={() => elegir(s)}
                >
                  <MapPin className="w-6 h-6 text-primary" />
                  {s.nombre}
                </Button>
              ))}
              {sucursales.length === 0 && (
                <p className="text-center text-muted-foreground text-sm py-6">
                  No hay sucursales configuradas.
                </p>
              )}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}

export default function OperacionesLayout() {
  return (
    <SucursalProvider>
      <Gate />
    </SucursalProvider>
  );
}
