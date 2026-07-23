import { useEffect, useState, useCallback, useMemo } from "react";
import { useParams } from "react-router-dom";
import { supabase } from "@/integrations/supabase/client";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import {
  Dialog, DialogContent, DialogHeader, DialogTitle,
} from "@/components/ui/dialog";
import { Loader2, AlertTriangle } from "lucide-react";
import { toast } from "sonner";
import logoLaOla from "@/assets/logo-la-ola.jpeg";

// Captura del horario semanal de UN área, por liga con token (sin login).
// La persona encargada del área toca la celda del rol y elige el nombre.
// Sin horas: el equipo ya sabe qué significa Abre / Intermedio / Cierra.
// Quien no aparece en ningún rol un día, descansa ese día (se deriva solo).

interface Persona { id: string; nombre: string; }
interface Asignacion { dia: number; rol: string; empleado_id: string; }
interface Info { sucursal: string; area: string; equipo: Persona[]; asignaciones: Asignacion[]; }

const DIAS = [
  { dow: 1, label: "Lunes" }, { dow: 2, label: "Martes" }, { dow: 3, label: "Miércoles" },
  { dow: 4, label: "Jueves" }, { dow: 5, label: "Viernes" }, { dow: 6, label: "Sábado" },
  { dow: 0, label: "Domingo" },
];
const ROLES = [
  { key: "abre", label: "Abre" },
  { key: "intermedio", label: "Intermedio" },
  { key: "cierra", label: "Cierra" },
];
const AREA_LABEL: Record<string, string> = {
  mesero: "Meseros", cocina: "Cocina", caja: "Caja", repartidor: "Repartidores",
  barman: "Barra", contabilidad: "Contabilidad", valet: "Valet parking",
};

const rpc = (fn: string, args: Record<string, unknown>) =>
  (supabase.rpc as unknown as (f: string, a: Record<string, unknown>) => Promise<{ data: unknown; error: unknown }>)(fn, args);

export default function HorariosCaptura() {
  const { token = "" } = useParams();
  const [loading, setLoading] = useState(true);
  const [valido, setValido] = useState(true);
  const [info, setInfo] = useState<Info | null>(null);
  // Celda abierta en el selector de nombres.
  const [celda, setCelda] = useState<{ dia: number; rol: string } | null>(null);
  const [guardando, setGuardando] = useState(false);

  const cargar = useCallback(async () => {
    const { data, error } = await rpc("horarios_captura_info", { p_token: token });
    if (error || !data) {
      setValido(false);
      setInfo(null);
    } else {
      setValido(true);
      setInfo(data as Info);
    }
    setLoading(false);
  }, [token]);

  useEffect(() => { cargar(); }, [cargar]);

  // Mapa "dia|rol" -> empleado_id para pintar la cuadrícula.
  const asign = useMemo(() => {
    const m = new Map<string, string>();
    info?.asignaciones.forEach((a) => m.set(`${a.dia}|${a.rol}`, a.empleado_id));
    return m;
  }, [info]);

  const nombreDe = (id: string | undefined) =>
    info?.equipo.find((p) => p.id === id)?.nombre;

  // Rol que ya tiene una persona en un día dado (para avisar al moverla).
  const rolDe = (personaId: string, dia: number) =>
    ROLES.find((r) => asign.get(`${dia}|${r.key}`) === personaId)?.key;

  const descansanEl = (dia: number) =>
    (info?.equipo ?? []).filter((p) => !rolDe(p.id, dia));

  // Avisos que no bloquean: días sin quien abra/cierre y gente sin descanso.
  const avisos = useMemo(() => {
    if (!info) return [];
    const out: string[] = [];
    DIAS.forEach((d) => {
      if (!asign.get(`${d.dow}|abre`)) out.push(`${d.label}: nadie abre`);
      if (!asign.get(`${d.dow}|cierra`)) out.push(`${d.label}: nadie cierra`);
    });
    info.equipo.forEach((p) => {
      if (DIAS.every((d) => rolDe(p.id, d.dow))) out.push(`${p.nombre} no tiene día de descanso`);
    });
    return out;
  }, [info, asign]);

  const asignar = async (empleadoId: string | null) => {
    if (!celda) return;
    setGuardando(true);
    const { error } = await rpc("horarios_captura_set", {
      p_token: token, p_dia: celda.dia, p_rol: celda.rol, p_empleado_id: empleadoId,
    });
    setGuardando(false);
    if (error) {
      toast.error("No se pudo guardar, intenta de nuevo.");
      return;
    }
    setCelda(null);
    await cargar();
  };

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <Loader2 className="h-8 w-8 animate-spin text-primary" />
      </div>
    );
  }

  if (!valido || !info) {
    return (
      <div className="min-h-screen flex items-center justify-center p-6 text-center">
        <div>
          <img src={logoLaOla} alt="La Ola" className="w-16 h-16 rounded-full object-cover mx-auto mb-4" />
          <p className="font-semibold">Liga no válida</p>
          <p className="text-sm text-muted-foreground">Pide la liga correcta al administrador.</p>
        </div>
      </div>
    );
  }

  const areaLabel = AREA_LABEL[info.area] ?? info.area;

  return (
    <div className="min-h-screen bg-muted/30 pb-10">
      <div className="bg-card border-b sticky top-0 z-10">
        <div className="max-w-lg mx-auto px-4 py-3 flex items-center gap-3">
          <img src={logoLaOla} alt="La Ola" className="w-9 h-9 rounded-full object-cover" />
          <div>
            <h1 className="font-bold leading-tight">Horario · {areaLabel}</h1>
            <p className="text-xs text-muted-foreground">{info.sucursal} · toca un rol y elige a la persona</p>
          </div>
        </div>
      </div>

      <div className="max-w-lg mx-auto px-4 pt-4 space-y-3">
        {avisos.length > 0 && (
          <Card className="border-amber-300 bg-amber-50/60">
            <CardContent className="p-3 space-y-1">
              {avisos.map((a) => (
                <p key={a} className="text-xs text-amber-700 flex items-center gap-1.5">
                  <AlertTriangle className="h-3.5 w-3.5 shrink-0" /> {a}
                </p>
              ))}
            </CardContent>
          </Card>
        )}

        {DIAS.map((d) => (
          <Card key={d.dow}>
            <CardContent className="p-3">
              <p className="font-semibold mb-2">{d.label}</p>
              <div className="space-y-1.5">
                {ROLES.map((r) => {
                  const quien = nombreDe(asign.get(`${d.dow}|${r.key}`));
                  return (
                    <button
                      key={r.key}
                      onClick={() => setCelda({ dia: d.dow, rol: r.key })}
                      className="w-full flex items-center justify-between rounded-md border px-3 py-2.5 text-left hover:border-primary hover:bg-primary/5"
                    >
                      <span className="text-sm text-muted-foreground">{r.label}</span>
                      {quien
                        ? <span className="font-semibold">{quien}</span>
                        : <span className="text-muted-foreground/50 text-sm">— elegir —</span>}
                    </button>
                  );
                })}
              </div>
              <p className="text-xs text-muted-foreground mt-2">
                Descansan: {descansanEl(d.dow).map((p) => p.nombre).join(", ") || "nadie"}
              </p>
            </CardContent>
          </Card>
        ))}
      </div>

      <Dialog open={!!celda} onOpenChange={(o) => !o && !guardando && setCelda(null)}>
        <DialogContent className="max-w-sm">
          <DialogHeader>
            <DialogTitle>
              {celda && `${ROLES.find((r) => r.key === celda.rol)?.label} · ${DIAS.find((d) => d.dow === celda.dia)?.label}`}
            </DialogTitle>
          </DialogHeader>
          {celda && (
            <div className="space-y-2">
              {info.equipo.map((p) => {
                const rolActual = rolDe(p.id, celda.dia);
                const esLaCelda = asign.get(`${celda.dia}|${celda.rol}`) === p.id;
                return (
                  <Button
                    key={p.id}
                    variant={esLaCelda ? "default" : "outline"}
                    className="w-full justify-between h-11"
                    disabled={guardando}
                    onClick={() => asignar(p.id)}
                  >
                    {p.nombre}
                    {rolActual && !esLaCelda && (
                      <Badge variant="secondary" className="ml-2">
                        ya {ROLES.find((r) => r.key === rolActual)?.label.toLowerCase()}
                      </Badge>
                    )}
                  </Button>
                );
              })}
              {asign.get(`${celda.dia}|${celda.rol}`) && (
                <Button variant="ghost" className="w-full text-destructive" disabled={guardando} onClick={() => asignar(null)}>
                  Dejar vacío
                </Button>
              )}
              {info.equipo.length === 0 && (
                <p className="text-sm text-muted-foreground text-center py-2">
                  No hay personal de {areaLabel.toLowerCase()} dado de alta en esta sucursal.
                </p>
              )}
            </div>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
}
