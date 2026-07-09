import { useState, useEffect, useCallback, useRef } from "react";
import { useNavigate } from "react-router-dom";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import {
  Select, SelectContent, SelectItem, SelectTrigger, SelectValue,
} from "@/components/ui/select";
import { useToast } from "@/hooks/use-toast";
import { ArrowLeft, Clock, LogIn, LogOut, Loader2, Delete, Users } from "lucide-react";
import logoLaOla from "@/assets/logo-la-ola.jpeg";

const db = supabase as any;

interface Sucursal { id: string; nombre: string }
interface EnTurno { nombre: string; area: string; entrada_at: string }

interface Resultado {
  tipo: "entrada" | "salida";
  nombre: string;
  hora: string;
  minutos_retardo?: number | null;
  turno?: string | null;
  minutos_trabajados?: number;
}

const AREA_LABEL: Record<string, string> = {
  mesero: "Mesero", cocina: "Cocina", caja: "Caja", repartidor: "Repartidor", barman: "Barman",
};
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
  const [sucursalId, setSucursalId] = useState<string>(() => localStorage.getItem(LS_ID) || "");
  const [pin, setPin] = useState("");
  const [enviando, setEnviando] = useState(false);
  const [resultado, setResultado] = useState<Resultado | null>(null);
  const [dentro, setDentro] = useState<EnTurno[]>([]);
  const resetTimer = useRef<ReturnType<typeof setTimeout> | null>(null);

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

  const cargarDentro = useCallback(async () => {
    if (!sucursalId) { setDentro([]); return; }
    const { data } = await db.rpc("checador_estado", { p_sucursal_id: sucursalId });
    setDentro((data as EnTurno[]) || []);
  }, [sucursalId]);

  // Refresca la lista "dentro ahora" al entrar y cada minuto.
  useEffect(() => { cargarDentro(); }, [cargarDentro]);
  useEffect(() => {
    const t = setInterval(cargarDentro, 1000 * 60);
    return () => clearInterval(t);
  }, [cargarDentro]);

  const elegirSucursal = (id: string) => {
    setSucursalId(id);
    const s = sucursales.find((x) => x.id === id);
    localStorage.setItem(LS_ID, id);
    if (s) localStorage.setItem(LS_NOMBRE, s.nombre);
  };

  const enviar = useCallback(async (value: string) => {
    if (enviando || !sucursalId) return;
    setEnviando(true);
    const { data, error } = await db.rpc("checar_pin", {
      p_pin: value,
      p_sucursal_id: sucursalId,
    });
    setEnviando(false);
    setPin("");
    if (error) {
      const msg = error.message.includes("PIN_DUPLICADO")
        ? "Ese PIN está repetido. Avisa al encargado."
        : "PIN no reconocido";
      toast({ title: msg, variant: "destructive" });
      return;
    }
    const r = data as Resultado;
    setResultado(r);
    cargarDentro();
    if (resetTimer.current) clearTimeout(resetTimer.current);
    resetTimer.current = setTimeout(() => setResultado(null), 4500);
  }, [enviando, sucursalId, toast, cargarDentro]);

  const teclear = useCallback((d: string) => {
    if (enviando) return;
    setResultado(null);
    setPin((prev) => {
      if (prev.length >= 4) return prev;
      const next = prev + d;
      if (next.length === 4) enviar(next);
      return next;
    });
  }, [enviando, enviar]);

  const borrar = useCallback(() => setPin((p) => p.slice(0, -1)), []);

  // Teclado físico del monitor (por si lo tiene): números, Backspace.
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key >= "0" && e.key <= "9") teclear(e.key);
      else if (e.key === "Backspace") borrar();
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [teclear, borrar]);

  return (
    <div className="min-h-screen bg-gradient-to-br from-primary/5 to-secondary/10 p-4">
      <div className="max-w-4xl mx-auto">
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
            <div className="flex-1 text-center sm:text-left">
              <h1 className="text-xl font-bold">Checador de asistencia</h1>
              <p className="text-sm text-muted-foreground">Teclea tu PIN para marcar entrada o salida.</p>
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
        ) : (
          <div className="grid md:grid-cols-2 gap-4">
            {/* Teclado PIN */}
            <Card>
              <CardContent className="pt-6">
                {/* Resultado de la última checada, o los puntos del PIN */}
                <div className="h-24 flex items-center justify-center mb-4">
                  {resultado ? (
                    <div className={`w-full text-center rounded-xl py-3 ${resultado.tipo === "entrada" ? "bg-primary/10" : "bg-secondary/40"}`}>
                      <div className="flex items-center justify-center gap-2 font-bold text-lg">
                        {resultado.tipo === "entrada"
                          ? <><LogIn className="w-5 h-5 text-primary" /> Entrada</>
                          : <><LogOut className="w-5 h-5" /> Salida</>}
                      </div>
                      <div className="text-xl font-semibold mt-1">{resultado.nombre}</div>
                      <div className="text-sm text-muted-foreground">
                        {resultado.tipo === "entrada"
                          ? (resultado.minutos_retardo == null
                              ? `${resultado.hora} · sin turno programado`
                              : resultado.minutos_retardo > 5
                                ? `${resultado.hora} · ${resultado.minutos_retardo} min tarde`
                                : `${resultado.hora} · a tiempo 👍`)
                          : `${resultado.hora} · trabajó ${Math.floor((resultado.minutos_trabajados ?? 0) / 60)}h ${(resultado.minutos_trabajados ?? 0) % 60}m`}
                      </div>
                    </div>
                  ) : (
                    <div className="flex gap-3">
                      {[0, 1, 2, 3].map((i) => (
                        <div key={i}
                          className={`w-5 h-5 rounded-full border-2 transition-colors ${i < pin.length ? "bg-primary border-primary" : "border-muted-foreground/40"}`}
                        />
                      ))}
                    </div>
                  )}
                </div>

                {/* Teclado numérico */}
                <div className="grid grid-cols-3 gap-3">
                  {["1", "2", "3", "4", "5", "6", "7", "8", "9"].map((d) => (
                    <button key={d} onClick={() => teclear(d)} disabled={enviando}
                      className="h-16 rounded-xl border bg-card text-2xl font-semibold hover:bg-primary/5 active:scale-95 transition disabled:opacity-50">
                      {d}
                    </button>
                  ))}
                  <button onClick={borrar} disabled={enviando}
                    className="h-16 rounded-xl border bg-muted/40 flex items-center justify-center hover:bg-muted active:scale-95 transition disabled:opacity-50">
                    <Delete className="w-6 h-6" />
                  </button>
                  <button onClick={() => teclear("0")} disabled={enviando}
                    className="h-16 rounded-xl border bg-card text-2xl font-semibold hover:bg-primary/5 active:scale-95 transition disabled:opacity-50">
                    0
                  </button>
                  <div className="h-16 flex items-center justify-center">
                    {enviando && <Loader2 className="w-6 h-6 animate-spin text-primary" />}
                  </div>
                </div>
              </CardContent>
            </Card>

            {/* Dentro ahora */}
            <Card>
              <CardContent className="pt-6">
                <h2 className="text-sm font-semibold text-muted-foreground uppercase tracking-wide mb-3 flex items-center gap-2">
                  <Users className="w-4 h-4" /> Dentro ahora ({dentro.length})
                </h2>
                {dentro.length === 0 ? (
                  <p className="text-sm text-muted-foreground py-6 text-center">Nadie ha marcado entrada todavía.</p>
                ) : (
                  <div className="space-y-2 max-h-[420px] overflow-y-auto">
                    {dentro.map((e, i) => (
                      <div key={i} className="flex items-center justify-between rounded-lg border bg-card px-3 py-2">
                        <div>
                          <div className="font-medium leading-tight">{e.nombre}</div>
                          <div className="text-xs text-muted-foreground">{AREA_LABEL[e.area] ?? e.area}</div>
                        </div>
                        <div className="text-sm text-primary font-medium flex items-center gap-1">
                          <LogIn className="w-3.5 h-3.5" /> {horaCorta(e.entrada_at)}
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </CardContent>
            </Card>
          </div>
        )}
      </div>
    </div>
  );
}
