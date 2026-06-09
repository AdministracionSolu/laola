import { useEffect, useState, type FormEvent } from "react";
import { useNavigate } from "react-router-dom";
import type { Session } from "@supabase/supabase-js";
import { supabase } from "@/integrations/supabase/client";
import { useSucursal } from "@/contexts/SucursalContext";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { ArrowLeft, Loader2, Lock, MapPin } from "lucide-react";
import { toast } from "sonner";
import logoLaOla from "@/assets/logo-la-ola.jpeg";
import TableroPedidos from "@/components/panel-pedidos-en-linea/TableroPedidos";
import HistorialPedidos from "@/components/panel-pedidos-en-linea/HistorialPedidos";
import ConfiguracionPedidos from "@/components/panel-pedidos-en-linea/ConfiguracionPedidos";

/**
 * Las tablas de pedidos en línea exigen sesión de Supabase (rol authenticated)
 * por RLS: el PIN de sucursal por sí solo no protege datos de clientes.
 */
function LoginStaff({ onListo }: { onListo: () => void }) {
  const [correo, setCorreo] = useState("");
  const [contrasena, setContrasena] = useState("");
  const [enviando, setEnviando] = useState(false);

  const entrar = async (e: FormEvent) => {
    e.preventDefault();
    if (enviando) return;
    setEnviando(true);
    const { error } = await supabase.auth.signInWithPassword({
      email: correo.trim(),
      password: contrasena,
    });
    setEnviando(false);
    if (error) {
      toast.error("Correo o contraseña incorrectos");
      return;
    }
    onListo();
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-primary/5 to-secondary/10 flex items-center justify-center p-4">
      <Card className="w-full max-w-md">
        <CardContent className="p-6">
          <div className="text-center mb-6">
            <div className="mx-auto mb-3 w-16 h-16 rounded-full overflow-hidden">
              <img src={logoLaOla} alt="La Ola" className="w-full h-full object-cover" />
            </div>
            <h1 className="text-2xl font-bold flex items-center justify-center gap-2">
              <Lock className="h-5 w-5" /> Pedidos en línea
            </h1>
            <p className="text-muted-foreground">
              Inicia sesión con la cuenta del equipo (se recuerda en este dispositivo)
            </p>
          </div>
          <form onSubmit={entrar} className="space-y-4">
            <div>
              <Label htmlFor="correo">Correo</Label>
              <Input
                id="correo"
                type="email"
                value={correo}
                onChange={(e) => setCorreo(e.target.value)}
                className="h-12 text-base mt-1"
                autoComplete="username"
              />
            </div>
            <div>
              <Label htmlFor="contrasena">Contraseña</Label>
              <Input
                id="contrasena"
                type="password"
                value={contrasena}
                onChange={(e) => setContrasena(e.target.value)}
                className="h-12 text-base mt-1"
                autoComplete="current-password"
              />
            </div>
            <Button type="submit" className="w-full h-12 text-base font-bold" disabled={enviando}>
              {enviando ? <Loader2 className="h-5 w-5 animate-spin" /> : "Entrar"}
            </Button>
          </form>
        </CardContent>
      </Card>
    </div>
  );
}

export default function PanelPedidosEnLinea() {
  const navigate = useNavigate();
  const { sucursalId, sucursalNombre } = useSucursal();
  const [sesion, setSesion] = useState<Session | null>(null);
  const [cargandoSesion, setCargandoSesion] = useState(true);

  useEffect(() => {
    supabase.auth.getSession().then(({ data }) => {
      setSesion(data.session);
      setCargandoSesion(false);
    });
    const { data: escucha } = supabase.auth.onAuthStateChange((_evento, nuevaSesion) => {
      setSesion(nuevaSesion);
    });
    return () => escucha.subscription.unsubscribe();
  }, []);

  if (cargandoSesion) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <Loader2 className="h-8 w-8 animate-spin text-primary" />
      </div>
    );
  }

  if (!sesion) {
    return <LoginStaff onListo={() => undefined} />;
  }

  if (!sucursalId) return null; // OperacionesLayout muestra el selector

  return (
    <div className="min-h-screen bg-gradient-to-br from-primary/5 to-secondary/10">
      <div className="max-w-6xl mx-auto p-4">
        {/* Encabezado */}
        <div className="flex items-center gap-3 mb-4">
          <Button variant="ghost" size="icon" onClick={() => navigate("/pedidos")} aria-label="Volver">
            <ArrowLeft className="h-5 w-5" />
          </Button>
          <div className="w-10 h-10 rounded-full overflow-hidden shrink-0">
            <img src={logoLaOla} alt="La Ola" className="w-full h-full object-cover" />
          </div>
          <div className="flex-1">
            <h1 className="text-lg font-bold leading-tight">Pedidos en línea</h1>
            <p className="text-sm text-muted-foreground flex items-center gap-1">
              <MapPin className="h-3.5 w-3.5 text-primary" /> {sucursalNombre}
            </p>
          </div>
        </div>

        <Tabs defaultValue="pedidos">
          <TabsList className="grid w-full grid-cols-3 h-12">
            <TabsTrigger value="pedidos" className="text-base font-semibold">
              Pedidos
            </TabsTrigger>
            <TabsTrigger value="historial" className="text-base font-semibold">
              Historial
            </TabsTrigger>
            <TabsTrigger value="configuracion" className="text-base font-semibold">
              Configuración
            </TabsTrigger>
          </TabsList>
          <TabsContent value="pedidos" className="mt-4">
            <TableroPedidos sucursalId={sucursalId} sucursalNombre={sucursalNombre ?? ""} />
          </TabsContent>
          <TabsContent value="historial" className="mt-4">
            <HistorialPedidos sucursalId={sucursalId} />
          </TabsContent>
          <TabsContent value="configuracion" className="mt-4">
            <ConfiguracionPedidos sucursalId={sucursalId} />
          </TabsContent>
        </Tabs>
      </div>
    </div>
  );
}
