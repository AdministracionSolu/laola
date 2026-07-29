import { useEffect, useState, useCallback, useMemo } from "react";
import { useParams } from "react-router-dom";
import { supabase } from "@/integrations/supabase/client";
import { Card, CardContent } from "@/components/ui/card";
import { Loader2, AlertTriangle, ChevronDown } from "lucide-react";
import { toast } from "sonner";
import logoLaOla from "@/assets/logo-la-ola.jpeg";

// Captura del horario semanal de UN área, por liga con token (sin login).
// Persona-primero: se toca a una persona y se arma su semana completa
// (Lun: Abre, Mar: Cierra, Mié: Intermedio…) con un toque por día.
// Sin horas: el equipo ya sabe qué significa Abre / Intermedio / Cierra.
// "Descansa" = la persona no tiene rol ese día.

interface Persona { id: string; nombre: string; }
interface Asignacion { dia: number; rol: string; empleado_id: string; }
interface RolDef { rol: string; hora_entrada: string | null; hora_salida: string | null; }
interface Info { sucursal: string; area: string; roles?: RolDef[]; equipo: Persona[]; asignaciones: Asignacion[]; }

const DIAS = [
  { dow: 1, label: "Lunes", corto: "Lu" }, { dow: 2, label: "Martes", corto: "Ma" },
  { dow: 3, label: "Miércoles", corto: "Mi" }, { dow: 4, label: "Jueves", corto: "Ju" },
  { dow: 5, label: "Viernes", corto: "Vi" }, { dow: 6, label: "Sábado", corto: "Sá" },
  { dow: 0, label: "Domingo", corto: "Do" },
];
const ROLES = [
  { key: "abre", label: "Abre", corto: "A" },
  { key: "intermedio", label: "Interm.", corto: "I" },
  { key: "cierra", label: "Cierra", corto: "C" },
];
const rolLabel = (key: string) => ROLES.find((r) => r.key === key)?.label ?? key;
const AREA_LABEL: Record<string, string> = {
  mesero: "Meseros", cocina: "Cocina", caja: "Caja", repartidor: "Repartidores",
  barman: "Barra", contabilidad: "Contabilidad", valet: "Valet parking",
};

const rpc = (fn: string, args: Record<string, unknown>) =>
  (supabase.rpc as unknown as (f: string, a: Record<string, unknown>) => Promise<{ data: unknown; error: unknown }>)(fn, args);

// Fechas reales de la semana (lunes a domingo) para que quien captura vea
// en qué día del mes cae cada columna (quincenas, fechas importantes).
function fechasDeSemana(cual: "esta" | "proxima"): Map<number, Date> {
  const hoy = new Date();
  const lunes = new Date(hoy);
  lunes.setDate(hoy.getDate() - ((hoy.getDay() + 6) % 7) + (cual === "proxima" ? 7 : 0));
  const m = new Map<number, Date>();
  for (let i = 0; i < 7; i++) {
    const d = new Date(lunes);
    d.setDate(lunes.getDate() + i);
    m.set(d.getDay(), d);
  }
  return m;
}

const esQuincena = (d: Date) => {
  const ultimo = new Date(d.getFullYear(), d.getMonth() + 1, 0).getDate();
  return d.getDate() === 15 || d.getDate() === ultimo;
};

const MESES_CORTOS = ["ene", "feb", "mar", "abr", "may", "jun", "jul", "ago", "sep", "oct", "nov", "dic"];

export default function HorariosCaptura() {
  const { token = "" } = useParams();
  const [loading, setLoading] = useState(true);
  const [valido, setValido] = useState(true);
  const [info, setInfo] = useState<Info | null>(null);
  // Persona cuya semana está abierta (acordeón: una a la vez).
  const [abierta, setAbierta] = useState<string | null>(null);
  // Semana cuyas fechas se muestran (el horario es la plantilla semanal).
  const [semana, setSemana] = useState<"esta" | "proxima">("proxima");
  const fechas = useMemo(() => fechasDeSemana(semana), [semana]);

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

  // Mapa "dia|rol" -> empleado_id.
  const asign = useMemo(() => {
    const m = new Map<string, string>();
    info?.asignaciones.forEach((a) => m.set(`${a.dia}|${a.rol}`, a.empleado_id));
    return m;
  }, [info]);

  const nombreDe = (id: string | undefined) =>
    info?.equipo.find((p) => p.id === id)?.nombre;

  const rolDe = (personaId: string, dia: number) =>
    ROLES.find((r) => asign.get(`${dia}|${r.key}`) === personaId)?.key;

  // Roles disponibles en esta área (p. ej. barra no tiene intermedio).
  // Sin definición en la base, se muestran los 3 como siempre.
  const rolesArea = useMemo(() => {
    if (!info?.roles?.length) return ROLES;
    return ROLES.filter((r) => info.roles!.some((d) => d.rol === r.key));
  }, [info]);

  const horasDe = (rolKey: string) => {
    const d = info?.roles?.find((x) => x.rol === rolKey);
    if (!d?.hora_entrada || !d?.hora_salida) return null;
    return `${d.hora_entrada.slice(0, 5)}–${d.hora_salida.slice(0, 5)}`;
  };

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
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [info, asign]);

  // Un toque = un guardado. Actualiza local de inmediato y sincroniza atrás;
  // si el servidor falla, recarga para volver a la verdad.
  const setRol = async (persona: Persona, dia: number, nuevoRol: string | null) => {
    if (!info) return;
    const rolActual = rolDe(persona.id, dia);
    if (nuevoRol === (rolActual ?? null)) return;

    const desplazadoId = nuevoRol ? asign.get(`${dia}|${nuevoRol}`) : undefined;

    // Optimista: fuera lo que esta persona tenía ese día y quien ocupaba el rol destino.
    const nuevas = info.asignaciones.filter((a) =>
      !(a.dia === dia && (a.empleado_id === persona.id || (nuevoRol && a.rol === nuevoRol))));
    if (nuevoRol) nuevas.push({ dia, rol: nuevoRol, empleado_id: persona.id });
    setInfo({ ...info, asignaciones: nuevas });

    if (desplazadoId && desplazadoId !== persona.id) {
      const diaLabel = DIAS.find((d) => d.dow === dia)?.label ?? "";
      toast.info(`${nombreDe(desplazadoId)} quedó sin rol el ${diaLabel.toLowerCase()} (lo reemplazó ${persona.nombre}).`);
    }

    // Descansar = vaciar la celda del rol que tenía.
    const { error } = nuevoRol
      ? await rpc("horarios_captura_set", { p_token: token, p_dia: dia, p_rol: nuevoRol, p_empleado_id: persona.id })
      : await rpc("horarios_captura_set", { p_token: token, p_dia: dia, p_rol: rolActual, p_empleado_id: null });
    if (error) {
      toast.error("No se pudo guardar, intenta de nuevo.");
      await cargar();
    }
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
            <p className="text-xs text-muted-foreground">{info.sucursal} · toca a una persona y arma su semana</p>
          </div>
        </div>
      </div>

      <div className="max-w-lg mx-auto px-4 pt-4 space-y-3">
        {/* Semana de referencia: fechas reales para ubicar quincenas */}
        <div className="flex items-center justify-between gap-2">
          <div className="flex rounded-lg border overflow-hidden text-xs">
            {(["esta", "proxima"] as const).map((s) => (
              <button
                key={s}
                onClick={() => setSemana(s)}
                className={`px-3 py-1.5 ${semana === s ? "bg-primary text-primary-foreground font-semibold" : "bg-card text-muted-foreground"}`}
              >
                {s === "esta" ? "Esta semana" : "Próxima semana"}
              </button>
            ))}
          </div>
          <p className="text-xs text-muted-foreground text-right">
            {fechas.get(1)!.getDate()} {MESES_CORTOS[fechas.get(1)!.getMonth()]} – {fechas.get(0)!.getDate()} {MESES_CORTOS[fechas.get(0)!.getMonth()]}
          </p>
        </div>

        {/* Horas de cada rol en esta área (si están definidas) */}
        {rolesArea.some((r) => horasDe(r.key)) && (
          <Card>
            <CardContent className="p-3 flex flex-wrap gap-x-4 gap-y-1">
              {rolesArea.map((r) => {
                const h = horasDe(r.key);
                return (
                  <p key={r.key} className="text-xs">
                    <span className="font-semibold text-primary">{r.label}</span>{" "}
                    <span className="text-muted-foreground">{h ?? "horario del área"}</span>
                  </p>
                );
              })}
            </CardContent>
          </Card>
        )}

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

        {info.equipo.length === 0 && (
          <Card><CardContent className="p-4 text-center text-sm text-muted-foreground">
            No hay personal de {areaLabel.toLowerCase()} dado de alta en esta sucursal.
          </CardContent></Card>
        )}

        {/* Una tarjeta por persona: cerrada muestra su semana en chico, abierta la edita. */}
        {info.equipo.map((p) => {
          const estaAbierta = abierta === p.id;
          return (
            <Card key={p.id}>
              <CardContent className="p-3">
                <button
                  className="w-full flex items-center justify-between gap-2 text-left"
                  onClick={() => setAbierta(estaAbierta ? null : p.id)}
                >
                  <span className="font-semibold">{p.nombre}</span>
                  <span className="flex items-center gap-1.5">
                    {!estaAbierta && (
                      <span className="flex gap-1">
                        {DIAS.map((d) => {
                          const r = rolDe(p.id, d.dow);
                          return (
                            <span
                              key={d.dow}
                              className={`w-6 rounded text-center text-[10px] leading-4 py-0.5 ${
                                r ? "bg-primary/10 text-primary font-semibold" : "bg-muted text-muted-foreground/60"
                              }`}
                            >
                              {d.corto}
                              <br />
                              {r ? ROLES.find((x) => x.key === r)?.corto : "—"}
                            </span>
                          );
                        })}
                      </span>
                    )}
                    <ChevronDown className={`h-4 w-4 text-muted-foreground transition-transform ${estaAbierta ? "rotate-180" : ""}`} />
                  </span>
                </button>

                {estaAbierta && (
                  <div className="mt-3 space-y-1.5">
                    {DIAS.map((d) => {
                      const rolActual = rolDe(p.id, d.dow);
                      const f = fechas.get(d.dow)!;
                      return (
                        <div key={d.dow} className="flex items-center gap-1.5">
                          <span className={`w-11 shrink-0 text-xs font-medium leading-tight ${esQuincena(f) ? "text-amber-600" : "text-muted-foreground"}`}>
                            {d.corto} {f.getDate()}
                            {esQuincena(f) && <span className="block text-[9px] font-semibold">quincena</span>}
                          </span>
                          {rolesArea.map((r) => {
                            const ocupanteId = asign.get(`${d.dow}|${r.key}`);
                            const esMio = ocupanteId === p.id;
                            const ocupadoPorOtro = !!ocupanteId && !esMio;
                            return (
                              <button
                                key={r.key}
                                onClick={() => setRol(p, d.dow, r.key)}
                                className={`flex-1 rounded-md border px-1 py-1.5 text-center leading-tight ${
                                  esMio
                                    ? "bg-primary text-primary-foreground border-primary font-semibold"
                                    : "hover:border-primary hover:bg-primary/5"
                                }`}
                              >
                                <span className="text-xs">{r.label}</span>
                                {ocupadoPorOtro && (
                                  <span className="block text-[10px] text-muted-foreground truncate max-w-[72px] mx-auto">
                                    {nombreDe(ocupanteId)}
                                  </span>
                                )}
                              </button>
                            );
                          })}
                          <button
                            onClick={() => setRol(p, d.dow, null)}
                            className={`flex-1 rounded-md border px-1 py-1.5 text-xs text-center ${
                              !rolActual
                                ? "bg-muted font-semibold border-muted-foreground/30"
                                : "text-muted-foreground hover:bg-muted"
                            }`}
                          >
                            Desc.
                          </button>
                        </div>
                      );
                    })}
                    <p className="text-[11px] text-muted-foreground pt-1">
                      Un toque guarda. Si el rol ya era de alguien más, esa persona queda sin rol ese día.
                    </p>
                  </div>
                )}
              </CardContent>
            </Card>
          );
        })}

        {/* Resumen por día, para no perder el panorama de la semana. */}
        {info.equipo.length > 0 && (
          <Card>
            <CardContent className="p-3">
              <p className="font-semibold mb-2 text-sm">Resumen de la semana</p>
              <div className="space-y-1">
                {DIAS.map((d) => (
                  <div key={d.dow} className="flex gap-2 text-xs">
                    <span className="w-11 shrink-0 font-medium text-muted-foreground">
                      {d.corto} {fechas.get(d.dow)!.getDate()}
                    </span>
                    <span className="min-w-0">
                      {rolesArea.map((r) => {
                        const quien = nombreDe(asign.get(`${d.dow}|${r.key}`));
                        return (
                          <span key={r.key} className="mr-2 whitespace-nowrap">
                            <span className="text-muted-foreground">{rolLabel(r.key)}:</span>{" "}
                            {quien ?? <span className="text-destructive/70">falta</span>}
                          </span>
                        );
                      })}
                    </span>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        )}
      </div>
    </div>
  );
}
