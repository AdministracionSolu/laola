import { useCallback, useEffect, useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import { supabase } from "@/integrations/supabase/client";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { InputOTP, InputOTPGroup, InputOTPSlot } from "@/components/ui/input-otp";
import {
  ArrowLeft,
  ChevronLeft,
  ChevronRight,
  Loader2,
  Lock,
  RefreshCw,
  Store,
} from "lucide-react";
import { toast } from "sonner";
import logoLaOla from "@/assets/logo-la-ola.jpeg";
import { Indicador } from "@/components/implementacion/Celdas";
import { PanelOperacion } from "@/components/implementacion/PanelOperacion";
import { PanelLealtad } from "@/components/implementacion/PanelLealtad";
import { PanelData, etiquetaFechaLarga, pct } from "@/components/implementacion/tipos";

const rpc = (fn: string, args: Record<string, unknown>) =>
  (supabase.rpc as unknown as (
    f: string,
    a: Record<string, unknown>
  ) => Promise<{ data: unknown; error: { message: string } | null }>)(fn, args);

const SS_PIN = "laola_impl_pin";

/** Suma días a una fecha ISO sin que la zona horaria la mueva. */
function sumarDias(iso: string, dias: number): string {
  const [a, m, d] = iso.split("-").map(Number);
  const f = new Date(Date.UTC(a, m - 1, d));
  f.setUTCDate(f.getUTCDate() + dias);
  return f.toISOString().slice(0, 10);
}

export default function Implementacion() {
  const navigate = useNavigate();
  const [pin, setPin] = useState<string>(() => sessionStorage.getItem(SS_PIN) || "");
  const [autorizado, setAutorizado] = useState<boolean>(() => !!sessionStorage.getItem(SS_PIN));
  const [intento, setIntento] = useState("");
  const [validando, setValidando] = useState(false);

  const [rango, setRango] = useState<{ desde: string; hasta: string } | null>(null);
  const [data, setData] = useState<PanelData | null>(null);
  const [cargando, setCargando] = useState(false);
  const [sucursalId, setSucursalId] = useState<string>("");
  const [hayAdmin, setHayAdmin] = useState(false);
  // Sube en cada recarga: es lo que hace que la pestaña de Lealtad, que
  // trae sus datos por su cuenta, también obedezca al botón de refrescar.
  const [tick, setTick] = useState(0);

  const cargar = useCallback(
    async (r: { desde: string; hasta: string } | null, elPin: string, silencioso = false) => {
      setCargando(true);
      const { data: res, error } = await rpc("panel_implementacion", {
        p_pin: elPin,
        p_desde: r?.desde ?? null,
        p_hasta: r?.hasta ?? null,
      });
      setCargando(false);
      if (error) {
        if (!silencioso) toast.error("No se pudo cargar el panel");
        return false;
      }
      const payload = res as PanelData | { ok: false; error: string } | null;
      if (!payload || payload.ok !== true) {
        if (!silencioso) {
          sessionStorage.removeItem(SS_PIN);
          setAutorizado(false);
          toast.error("Tu acceso ya no es válido");
        }
        return false;
      }
      setData(payload);
      setTick((t) => t + 1);
      setRango({ desde: payload.desde, hasta: payload.hasta });
      setSucursalId((actual) => {
        if (actual && payload.sucursales.some((s) => s.id === actual)) return actual;
        const valle = payload.sucursales.find((s) => s.es_valle);
        return valle?.id ?? payload.sucursales[0]?.id ?? "";
      });
      return true;
    },
    []
  );

  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => setHayAdmin(!!session));
  }, []);

  useEffect(() => {
    if (autorizado && pin) {
      cargar(null, pin);
      return;
    }
    if (autorizado) return;
    // Quien llega desde el dashboard ya trae sesión de admin: el RPC lo deja
    // pasar sin PIN. Si no lo deja, cae al teclado de siempre sin avisar nada.
    (async () => {
      const {
        data: { session },
      } = await supabase.auth.getSession();
      if (!session) return;
      setHayAdmin(true);
      if (await cargar(null, "", true)) setAutorizado(true);
    })();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [autorizado]);

  const validar = async (valor: string) => {
    setValidando(true);
    const { data: ok, error } = await rpc("impl_validar_pin", { p_pin: valor });
    setValidando(false);
    if (ok === true) {
      sessionStorage.setItem(SS_PIN, valor);
      setPin(valor);
      setAutorizado(true);
      return;
    }
    // Sin la migración corrida, la función ni existe: decirle "código
    // incorrecto" a quien teclea bien el PIN manda a buscar el problema al
    // lugar equivocado.
    toast.error(
      error ? "El panel todavía no está instalado en la base de datos" : "Código incorrecto"
    );
    setIntento("");
  };

  const moverSemana = (dias: number) => {
    if (!rango) return;
    const nuevo = { desde: sumarDias(rango.desde, dias), hasta: sumarDias(rango.hasta, dias) };
    setRango(nuevo);
    cargar(nuevo, pin);
  };

  const estaSemana = () => {
    setRango(null);
    cargar(null, pin);
  };

  const resumen = useMemo(() => {
    if (!data) return null;

    // Operación de la sucursal seleccionada: los tres pasos juntos.
    // Es lo único que se calcula desde que el panel se quedó en Sucursal y
    // Lealtad; el resto del payload sigue llegando de la RPC pero ya no se
    // pinta en ningún lado.
    const op = data.operacion.find((o) => o.sucursal_id === sucursalId);
    let opTotal = 0;
    let opHechos = 0;
    if (op) {
      for (const d of op.dias) {
        if (d.fecha >= data.hoy) continue;
        opTotal += 3;
        if (d.pedido?.enviado_at) opHechos++;
        if (d.pedido && d.pedido.renglones > 0 && d.pedido.con_existencia > 0) opHechos++;
        if (d.recepciones.length > 0) opHechos++;
      }
    }

    return { operacion: pct(opHechos, opTotal) };
  }, [data, sucursalId]);

  if (!autorizado) {
    return (
      <div className="min-h-screen flex items-center justify-center p-4 bg-gradient-to-br from-primary/5 to-secondary/10">
        <Card className="w-full max-w-sm">
          <CardContent className="p-6 text-center space-y-5">
            <div className="mx-auto w-16 h-16 rounded-full overflow-hidden">
              <img src={logoLaOla} alt="La Ola" className="w-full h-full object-cover" />
            </div>
            <div>
              <h1 className="text-xl font-bold flex items-center justify-center gap-2">
                <Lock className="h-5 w-5" /> Implementación
              </h1>
              <p className="text-sm text-muted-foreground">Ingresa tu código de acceso</p>
            </div>
            <div className="flex justify-center">
              <InputOTP
                maxLength={4}
                value={intento}
                onChange={(v) => {
                  setIntento(v);
                  if (v.length === 4) validar(v);
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
            </div>
            {validando && <Loader2 className="h-4 w-4 animate-spin mx-auto" />}
          </CardContent>
        </Card>
      </div>
    );
  }

  if (!data) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <Loader2 className="h-6 w-6 animate-spin text-muted-foreground" />
      </div>
    );
  }

  const sucursalNombre =
    data.sucursales.find((s) => s.id === sucursalId)?.nombre ?? "la sucursal";

  return (
    <div className="min-h-screen bg-muted/30">
      <header className="border-b bg-background">
        <div className="mx-auto max-w-7xl px-4 py-4 flex flex-wrap items-center justify-between gap-3">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-full overflow-hidden shrink-0">
              <img src={logoLaOla} alt="La Ola" className="w-full h-full object-cover" />
            </div>
            <div>
              <h1 className="text-lg font-bold leading-tight">Panel de Implementación</h1>
              <p className="text-xs text-muted-foreground">
                Cumplimiento de la operación · La Ola
              </p>
            </div>
          </div>
          <div className="flex flex-wrap items-center gap-2">
            {hayAdmin && (
              <Button variant="ghost" size="sm" onClick={() => navigate("/admin/dashboard")} className="gap-1">
                <ArrowLeft className="h-4 w-4" />
                <span className="hidden sm:inline">Dashboard</span>
              </Button>
            )}
            <Button variant="outline" size="icon" onClick={() => moverSemana(-7)} title="Semana anterior">
              <ChevronLeft className="h-4 w-4" />
            </Button>
            <div className="text-sm font-medium tabular-nums px-2 whitespace-nowrap">
              {etiquetaFechaLarga(data.desde)} — {etiquetaFechaLarga(data.hasta)}
            </div>
            <Button variant="outline" size="icon" onClick={() => moverSemana(7)} title="Semana siguiente">
              <ChevronRight className="h-4 w-4" />
            </Button>
            <Button variant="ghost" size="sm" onClick={estaSemana}>
              Esta semana
            </Button>
            <Button variant="outline" size="icon" onClick={() => cargar(rango, pin)} title="Actualizar">
              <RefreshCw className={`h-4 w-4 ${cargando ? "animate-spin" : ""}`} />
            </Button>
          </div>
        </div>
      </header>

      <main className="mx-auto max-w-7xl px-4 py-6 space-y-6">
        {/* Quedó un solo indicador: los de cortes, proveedores y facturas se
            fueron con sus pestañas. Dejarlos arriba habría sido quitar la
            sección y seguir enseñando el número. */}
        {resumen && (
          <div className="grid gap-3 sm:max-w-xs">
            <Indicador
              titulo={`Operación ${sucursalNombre}`}
              valor={resumen.operacion}
              leyenda="pedido + existencias + recepción"
              icono={<Store className="h-3.5 w-3.5" />}
            />
          </div>
        )}

        {/* Dos pestañas y nada más (Diego, 26-ago-2026): Cortes, Proveedores,
            Facturas, Equipo y Pendientes salieron de aquí. No es el trabajo de
            implementación — se sigue viendo completo en /admin. */}
        <Tabs defaultValue="sucursal">
          <div className="flex flex-wrap items-center justify-between gap-3">
            <TabsList className="flex-wrap h-auto">
              <TabsTrigger value="sucursal">Sucursal</TabsTrigger>
              <TabsTrigger value="lealtad">Lealtad</TabsTrigger>
            </TabsList>
            <Select value={sucursalId} onValueChange={setSucursalId}>
              <SelectTrigger className="w-[200px]">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                {data.sucursales.map((s) => (
                  <SelectItem key={s.id} value={s.id}>
                    {s.nombre}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>

          <TabsContent value="sucursal" className="mt-4">
            <PanelOperacion data={data} sucursalId={sucursalId} />
          </TabsContent>
          <TabsContent value="lealtad" className="mt-4">
            <PanelLealtad key={tick} pin={pin} desde={data.desde} hasta={data.hasta} />
          </TabsContent>
        </Tabs>
      </main>
    </div>
  );
}
