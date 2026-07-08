import { useState, useEffect, useCallback } from "react";
import { useNavigate } from "react-router-dom";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import {
  Select, SelectContent, SelectItem, SelectTrigger, SelectValue,
} from "@/components/ui/select";
import {
  Dialog, DialogContent, DialogHeader, DialogTitle,
} from "@/components/ui/dialog";
import { InputOTP, InputOTPGroup, InputOTPSlot } from "@/components/ui/input-otp";
import { useToast } from "@/hooks/use-toast";
import { ArrowLeft, Clock, LogIn, LogOut, Loader2 } from "lucide-react";
import logoLaOla from "@/assets/logo-la-ola.jpeg";

const db = supabase as any;

interface Sucursal { id: string; nombre: string }
interface EmpEstado {
  empleado_id: string;
  nombre: string;
  area: "mesero" | "cocina" | "caja";
  orden: number;
  estado: "dentro" | "fuera";
  entrada_at: string | null;
}

const AREA_LABEL: Record<string, string> = {
  mesero: "Meseros",
  cocina: "Cocina",
  caja: "Cajas",
};
const AREA_ORDER = ["mesero", "cocina", "caja"];
const LS_ID = "laola_sucursal_id";
const LS_NOMBRE = "laola_sucursal_nombre";

function horaCorta(iso: string | null): string {
  if (!iso) return "";
  return new Date(iso).toLocaleTimeString("es-MX", {
    hour: "2-digit", minute: "2-digit", timeZone: "America/Mexico_City",
  });
}

export default function Checador() {
  const navigate = useNavigate();
  const { toast } = useToast();
  const [sucursales, setSucursales] = useState<Sucursal[]>([]);
  const [sucursalId, setSucursalId] = useState<string>(
    () => localStorage.getItem(LS_ID) || ""
  );
  const [empleados, setEmpleados] = useState<EmpEstado[]>([]);
  const [cargando, setCargando] = useState(false);
  const [seleccion, setSeleccion] = useState<EmpEstado | null>(null);
  const [pin, setPin] = useState("");
  const [enviando, setEnviando] = useState(false);

  // Reloj en pantalla
  const [ahora, setAhora] = useState(() => new Date());
  useEffect(() => {
    const t = setInterval(() => setAhora(new Date()), 1000 * 30);
    return () => clearInterval(t);
  }, []);

  useEffect(() => {
    supabase.from("sucursales").select("id, nombre").order("nombre")
      .then(({ data }) => setSucursales((data as Sucursal[]) || []));
  }, []);

  const cargar = useCallback(async () => {
    if (!sucursalId) { setEmpleados([]); return; }
    setCargando(true);
    const { data, error } = await db.rpc("checador_listar", {
      p_sucursal_id: sucursalId,
    });
    if (error) {
      toast({ title: "No se pudo cargar el personal", description: error.message, variant: "destructive" });
    } else {
      setEmpleados((data as EmpEstado[]) || []);
    }
    setCargando(false);
  }, [sucursalId, toast]);

  useEffect(() => { cargar(); }, [cargar]);

  const elegirSucursal = (id: string) => {
    setSucursalId(id);
    const s = sucursales.find((x) => x.id === id);
    localStorage.setItem(LS_ID, id);
    if (s) localStorage.setItem(LS_NOMBRE, s.nombre);
  };

  const abrir = (e: EmpEstado) => { setSeleccion(e); setPin(""); };

  const enviarChecada = async (value: string) => {
    if (!seleccion || value.length !== 4 || enviando) return;
    setEnviando(true);
    const { data, error } = await db.rpc("checar", {
      p_empleado_id: seleccion.empleado_id,
      p_pin: value,
      p_sucursal_id: sucursalId,
    });
    setEnviando(false);
    if (error) {
      const msg = error.message.includes("PIN_INCORRECTO")
        ? "PIN incorrecto"
        : error.message.includes("EMPLEADO_NO_ENCONTRADO")
        ? "Empleado no encontrado"
        : "No se pudo registrar";
      toast({ title: msg, variant: "destructive" });
      setPin("");
      return;
    }
    const r = data as any;
    if (r?.tipo === "entrada") {
      const retardo = r.minutos_retardo;
      toast({
        title: `Entrada · ${r.nombre}`,
        description:
          retardo == null
            ? `Registrada a las ${r.hora} (sin turno programado)`
            : retardo > 0
            ? `Registrada a las ${r.hora} · ${retardo} min tarde (turno ${r.turno})`
            : `Registrada a las ${r.hora} · a tiempo 👍`,
        variant: retardo && retardo > 5 ? "destructive" : "default",
      });
    } else {
      const h = r.minutos_trabajados ? Math.floor(r.minutos_trabajados / 60) : 0;
      const m = r.minutos_trabajados ? r.minutos_trabajados % 60 : 0;
      toast({
        title: `Salida · ${r.nombre}`,
        description: `Registrada a las ${r.hora} · trabajó ${h}h ${m}m`,
      });
    }
    setSeleccion(null);
    setPin("");
    cargar();
  };

  const porArea = AREA_ORDER.map((area) => ({
    area,
    lista: empleados.filter((e) => e.area === area),
  })).filter((g) => g.lista.length > 0);

  return (
    <div className="min-h-screen bg-gradient-to-br from-primary/5 to-secondary/10 p-4">
      <div className="max-w-3xl mx-auto">
        {/* Encabezado */}
        <div className="flex items-center justify-between mb-4">
          <Button variant="ghost" size="sm" onClick={() => navigate("/centro-de-operaciones")}>
            <ArrowLeft className="w-4 h-4 mr-1" /> Volver
          </Button>
          <div className="flex items-center gap-2 text-2xl font-bold tabular-nums">
            <Clock className="w-6 h-6 text-primary" />
            {ahora.toLocaleTimeString("es-MX", { hour: "2-digit", minute: "2-digit", timeZone: "America/Mexico_City" })}
          </div>
        </div>

        <Card className="mb-4">
          <CardContent className="pt-6 flex flex-col sm:flex-row items-center gap-4">
            <img src={logoLaOla} alt="La Ola" className="w-14 h-14 rounded-full object-cover" />
            <div className="flex-1">
              <h1 className="text-xl font-bold">Checador de asistencia</h1>
              <p className="text-sm text-muted-foreground">
                Toca tu nombre y captura tu PIN para marcar entrada o salida.
              </p>
            </div>
            <div className="w-full sm:w-56">
              <Select value={sucursalId} onValueChange={elegirSucursal}>
                <SelectTrigger><SelectValue placeholder="Sucursal" /></SelectTrigger>
                <SelectContent>
                  {sucursales.map((s) => (
                    <SelectItem key={s.id} value={s.id}>{s.nombre}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </CardContent>
        </Card>

        {!sucursalId ? (
          <p className="text-center text-muted-foreground py-12">Selecciona una sucursal para empezar.</p>
        ) : cargando ? (
          <div className="flex justify-center py-12"><Loader2 className="w-6 h-6 animate-spin text-primary" /></div>
        ) : empleados.length === 0 ? (
          <p className="text-center text-muted-foreground py-12">
            No hay personal con turnos asignados en esta sucursal. Configúralo en el panel de Horarios.
          </p>
        ) : (
          <div className="space-y-6">
            {porArea.map((g) => (
              <div key={g.area}>
                <h2 className="text-sm font-semibold text-muted-foreground uppercase tracking-wide mb-2">
                  {AREA_LABEL[g.area]}
                </h2>
                <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
                  {g.lista.map((e) => (
                    <button
                      key={e.empleado_id}
                      onClick={() => abrir(e)}
                      className={`rounded-xl border p-4 text-left transition-all hover:border-primary hover:shadow-md ${
                        e.estado === "dentro" ? "bg-primary/5 border-primary/40" : "bg-card"
                      }`}
                    >
                      <div className="font-semibold truncate">{e.nombre}</div>
                      {e.estado === "dentro" ? (
                        <Badge variant="default" className="mt-2 gap-1">
                          <LogIn className="w-3 h-3" /> Dentro · {horaCorta(e.entrada_at)}
                        </Badge>
                      ) : (
                        <Badge variant="secondary" className="mt-2">Fuera</Badge>
                      )}
                    </button>
                  ))}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* PIN */}
      <Dialog open={!!seleccion} onOpenChange={(o) => { if (!o) { setSeleccion(null); setPin(""); } }}>
        <DialogContent className="sm:max-w-xs">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              {seleccion?.estado === "dentro" ? (
                <><LogOut className="w-5 h-5 text-primary" /> Salida</>
              ) : (
                <><LogIn className="w-5 h-5 text-primary" /> Entrada</>
              )}
              {" · "}{seleccion?.nombre}
            </DialogTitle>
          </DialogHeader>
          <div className="flex flex-col items-center gap-5 py-2">
            <p className="text-sm text-muted-foreground">Captura tu PIN de 4 dígitos</p>
            <InputOTP
              maxLength={4}
              value={pin}
              onChange={setPin}
              onComplete={enviarChecada}
              disabled={enviando}
              autoFocus
            >
              <InputOTPGroup>
                <InputOTPSlot index={0} className="w-12 h-12 text-xl" />
                <InputOTPSlot index={1} className="w-12 h-12 text-xl" />
                <InputOTPSlot index={2} className="w-12 h-12 text-xl" />
                <InputOTPSlot index={3} className="w-12 h-12 text-xl" />
              </InputOTPGroup>
            </InputOTP>
            <Button className="w-full" disabled={pin.length !== 4 || enviando} onClick={() => enviarChecada(pin)}>
              {enviando ? <Loader2 className="w-4 h-4 animate-spin" /> : "Registrar"}
            </Button>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
}
