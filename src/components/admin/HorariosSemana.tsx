import { useCallback, useEffect, useMemo, useState } from "react";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { toast } from "sonner";
import {
  CalendarDays, ChevronLeft, ChevronRight, Check, Eye, Download, History,
  Loader2, AlertCircle, RefreshCw,
} from "lucide-react";
import { format, parseISO } from "date-fns";
import { es } from "date-fns/locale";
import {
  AREAS_HORARIO, areaLabel, rotuloSemana, semanaActual, semanaDesplazada,
  estadoSemana, rotuloSemanaLargo,
} from "@/lib/horariosSemana";
import { nombreCorto } from "@/lib/sucursales";

const db = supabase as any;

type Sucursal = { id: string; nombre: string };
type Empleado = { id: string; area: string; sucursal_principal_id: string | null; activo: boolean };
type Archivo = {
  id: string; sucursal_id: string; area: string; semana_inicio: string;
  archivo_path: string; archivo_nombre: string; mime: string | null;
  subido_por: string | null; version: number; vigente: boolean; created_at: string;
};

// ============================================================
// Horarios de la semana (entregados como archivo)
//
// Cada área sube su horario desde el Centro de Operaciones. Aquí se ve, por
// semana y sucursal, quién ya entregó y quién no. Lo importante de esta
// pantalla no es el archivo: es el hueco.
// ============================================================
export default function HorariosSemana({ sucursales, empleados }: {
  sucursales: Sucursal[]; empleados: Empleado[];
}) {
  const [semana, setSemana] = useState<string>(semanaActual());
  const [sucSel, setSucSel] = useState<string>("");
  const [archivos, setArchivos] = useState<Archivo[]>([]);
  const [cargando, setCargando] = useState(true);
  const [abriendo, setAbriendo] = useState<string | null>(null);
  const [historialDe, setHistorialDe] = useState<string | null>(null);
  const [historial, setHistorial] = useState<Archivo[]>([]);

  useEffect(() => {
    if (!sucSel && sucursales[0]) setSucSel(sucursales[0].id);
  }, [sucursales, sucSel]);

  const cargar = useCallback(async () => {
    setCargando(true);
    const { data, error } = await db
      .from("horarios_archivos")
      .select("*")
      .eq("semana_inicio", semana)
      .eq("vigente", true);
    if (error) toast.error("No pudimos cargar los horarios de la semana.");
    setArchivos((data ?? []) as Archivo[]);
    setHistorialDe(null);
    setCargando(false);
  }, [semana]);

  useEffect(() => { cargar(); }, [cargar]);

  // Áreas que se le piden a cada sucursal: las que tienen gente activa ahí.
  // Si una sucursal todavía no tiene personal cargado, se le piden todas.
  const areasEsperadas = useMemo(() => {
    const m = new Map<string, string[]>();
    sucursales.forEach((s) => {
      const suyas = new Set(
        empleados
          .filter((e) => e.activo && e.sucursal_principal_id === s.id && e.area)
          .map((e) => e.area)
      );
      // Un área que entregó archivo cuenta como esperada aunque no tenga
      // gente asignada en el catálogo.
      archivos.filter((a) => a.sucursal_id === s.id).forEach((a) => suyas.add(a.area));
      const conocidas: string[] = AREAS_HORARIO.filter((a) => suyas.has(a));
      const otras = [...suyas].filter((a) => !(AREAS_HORARIO as readonly string[]).includes(a)).sort();
      const lista: string[] = suyas.size ? [...conocidas, ...otras] : [...AREAS_HORARIO];
      m.set(s.id, lista);
    });
    return m;
  }, [sucursales, empleados, archivos]);

  const porSucursalArea = useMemo(() => {
    const m = new Map<string, Archivo>();
    archivos.forEach((a) => m.set(`${a.sucursal_id}|${a.area}`, a));
    return m;
  }, [archivos]);

  const conteo = (sucursalId: string) => {
    const esperadas = areasEsperadas.get(sucursalId) ?? [];
    const listas = esperadas.filter((a) => porSucursalArea.has(`${sucursalId}|${a}`)).length;
    return { listas, total: esperadas.length };
  };

  const abrir = async (a: Archivo, descargar = false) => {
    setAbriendo(a.id);
    const { data, error } = await supabase.storage
      .from("horarios")
      .createSignedUrl(a.archivo_path, 600, descargar ? { download: a.archivo_nombre } : undefined);
    setAbriendo(null);
    if (error || !data?.signedUrl) {
      toast.error("No pudimos abrir el archivo.");
      return;
    }
    window.open(data.signedUrl, "_blank", "noopener,noreferrer");
  };

  const verHistorial = async (sucursalId: string, area: string) => {
    const clave = `${sucursalId}|${area}`;
    if (historialDe === clave) { setHistorialDe(null); return; }
    const { data } = await db
      .from("horarios_archivos")
      .select("*")
      .eq("sucursal_id", sucursalId)
      .eq("area", area)
      .eq("semana_inicio", semana)
      .order("version", { ascending: false });
    setHistorial((data ?? []) as Archivo[]);
    setHistorialDe(clave);
  };

  const marca = estadoSemana(semana);
  const esperadasSel = areasEsperadas.get(sucSel) ?? [];

  return (
    <div className="space-y-4">
      {/* Semana */}
      <Card>
        <CardContent className="p-3 flex items-center justify-between gap-2">
          <Button variant="ghost" size="icon" onClick={() => setSemana(semanaDesplazada(semana, -1))}>
            <ChevronLeft className="w-5 h-5" />
          </Button>
          <div className="text-center min-w-0">
            <div className="flex items-center justify-center gap-2">
              <CalendarDays className="w-4 h-4 text-primary shrink-0" />
              <span className="font-semibold truncate">Semana del {rotuloSemana(semana)}</span>
            </div>
            <div className="flex items-center justify-center gap-2 mt-1">
              <Badge variant={marca === "en curso" ? "default" : "secondary"}>
                {marca === "en curso" ? "En curso" : marca === "próxima" ? "Próxima" : "Pasada"}
              </Badge>
              {semana !== semanaActual() && (
                <Button variant="link" size="sm" className="h-auto p-0 text-xs"
                  onClick={() => setSemana(semanaActual())}>
                  Ir a esta semana
                </Button>
              )}
            </div>
          </div>
          <div className="flex items-center gap-1">
            <Button variant="ghost" size="icon" onClick={cargar} title="Actualizar">
              <RefreshCw className={`w-4 h-4 ${cargando ? "animate-spin" : ""}`} />
            </Button>
            <Button variant="ghost" size="icon" onClick={() => setSemana(semanaDesplazada(semana, 1))}>
              <ChevronRight className="w-5 h-5" />
            </Button>
          </div>
        </CardContent>
      </Card>

      {/* Sucursales: el hueco se ve desde aquí */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-2">
        {sucursales.map((s) => {
          const { listas, total } = conteo(s.id);
          const completa = total > 0 && listas === total;
          const activa = sucSel === s.id;
          return (
            <button
              key={s.id}
              onClick={() => { setSucSel(s.id); setHistorialDe(null); }}
              className={`rounded-lg border p-3 text-left transition-all ${
                activa ? "border-primary ring-1 ring-primary bg-primary/5" : "hover:border-primary/50"
              }`}
            >
              <div className="flex items-center justify-between gap-2">
                <span className="font-semibold truncate">{nombreCorto(s.nombre)}</span>
                {completa ? (
                  <Check className="w-4 h-4 text-primary shrink-0" />
                ) : (
                  <AlertCircle className="w-4 h-4 text-muted-foreground shrink-0" />
                )}
              </div>
              <p className={`text-sm mt-0.5 ${completa ? "text-primary" : "text-muted-foreground"}`}>
                {listas} de {total} áreas
              </p>
            </button>
          );
        })}
      </div>

      {/* Áreas de la sucursal elegida */}
      {cargando ? (
        <div className="flex justify-center py-10"><Loader2 className="w-6 h-6 animate-spin text-primary" /></div>
      ) : (
        <div className="space-y-2">
          {esperadasSel.length === 0 && (
            <p className="text-sm text-muted-foreground py-6 text-center">
              Esta sucursal no tiene personal cargado todavía.
            </p>
          )}
          {esperadasSel.map((area) => {
            const a = porSucursalArea.get(`${sucSel}|${area}`);
            const clave = `${sucSel}|${area}`;
            return (
              <Card key={area} className={a ? undefined : "border-dashed"}>
                <CardContent className="p-4">
                  <div className="flex items-start justify-between gap-3">
                    <div className="min-w-0">
                      <div className="flex items-center gap-2 flex-wrap">
                        <span className="font-semibold">{areaLabel(area)}</span>
                        {a ? (
                          <Badge className="gap-1"><Check className="w-3 h-3" /> Entregado</Badge>
                        ) : (
                          <Badge variant="outline" className="text-muted-foreground">Falta</Badge>
                        )}
                        {a && a.version > 1 && (
                          <Badge variant="secondary">versión {a.version}</Badge>
                        )}
                      </div>
                      {a ? (
                        <p className="text-xs text-muted-foreground mt-1 truncate">
                          {a.subido_por ? `${a.subido_por} · ` : ""}
                          {format(parseISO(a.created_at), "EEE d 'de' MMM, HH:mm", { locale: es })}
                          {" · "}
                          <span className="font-mono">{a.archivo_nombre}</span>
                        </p>
                      ) : (
                        <p className="text-xs text-muted-foreground mt-1">Nadie ha subido este horario.</p>
                      )}
                    </div>

                    {a && (
                      <div className="flex items-center gap-1 shrink-0">
                        <Button variant="default" size="sm" className="gap-1"
                          disabled={abriendo === a.id} onClick={() => abrir(a)}>
                          {abriendo === a.id ? <Loader2 className="w-3.5 h-3.5 animate-spin" /> : <Eye className="w-3.5 h-3.5" />}
                          Ver
                        </Button>
                        <Button variant="outline" size="icon" title="Descargar"
                          disabled={abriendo === a.id} onClick={() => abrir(a, true)}>
                          <Download className="w-4 h-4" />
                        </Button>
                        {a.version > 1 && (
                          <Button variant="ghost" size="icon" title="Versiones anteriores"
                            onClick={() => verHistorial(sucSel, area)}>
                            <History className="w-4 h-4" />
                          </Button>
                        )}
                      </div>
                    )}
                  </div>

                  {historialDe === clave && historial.length > 0 && (
                    <div className="mt-3 border-t pt-3 space-y-1">
                      <p className="text-xs font-semibold text-muted-foreground">
                        Versiones de la semana del {rotuloSemanaLargo(semana)}
                      </p>
                      {historial.map((h) => (
                        <div key={h.id} className="flex items-center justify-between gap-2 text-xs">
                          <span className="truncate">
                            v{h.version} · {h.subido_por || "sin nombre"} ·{" "}
                            {format(parseISO(h.created_at), "d MMM HH:mm", { locale: es })}
                            {h.vigente && <span className="text-primary font-semibold"> (vigente)</span>}
                          </span>
                          <Button variant="ghost" size="sm" className="h-7 shrink-0"
                            disabled={abriendo === h.id} onClick={() => abrir(h)}>
                            Abrir
                          </Button>
                        </div>
                      ))}
                    </div>
                  )}
                </CardContent>
              </Card>
            );
          })}
        </div>
      )}

      <p className="text-xs text-muted-foreground">
        Las áreas suben su horario desde el Centro de Operaciones →{" "}
        <span className="font-medium">Horario de la semana</span>. El archivo se guarda contra la
        semana que cubre, así que lo que suban el domingo aparece aquí en la semana que arranca el lunes.
      </p>
    </div>
  );
}
