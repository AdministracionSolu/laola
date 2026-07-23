import { useEffect, useState, useCallback, Fragment } from "react";
import { useNavigate } from "react-router-dom";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import {
  Select, SelectContent, SelectItem, SelectTrigger, SelectValue,
} from "@/components/ui/select";
import {
  Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter, DialogTrigger,
} from "@/components/ui/dialog";
import {
  Table, TableBody, TableCell, TableHead, TableHeader, TableRow,
} from "@/components/ui/table";
import { toast } from "sonner";
import {
  ArrowLeft, LogOut, Plus, Trash2, Users, CalendarClock, ClipboardList, Clock, Pencil,
} from "lucide-react";
import logoLaOla from "@/assets/logo-la-ola.jpeg";

const db = supabase as any;

// ---------- Tipos ----------
type Puesto = "mesero" | "cocina" | "caja" | "repartidor" | "barman" | "contabilidad" | "valet";
type Sucursal = { id: string; nombre: string };
type Empleado = {
  id: string; nombre: string; area: Puesto;
  pin: string | null; sucursal_principal_id: string | null;
  telefono: string | null; orden: number; activo: boolean;
};
type Turno = {
  id: string; empleado_id: string; sucursal_id: string; dia_semana: number;
  hora_entrada: string; hora_salida: string; catalogo_turno_id: string | null; activo: boolean;
};
type CatTurno = {
  id: string; sucursal_id: string | null; nombre: string;
  hora_entrada: string; hora_salida: string; color: string; orden: number; activo: boolean;
};
type Asistencia = {
  id: string; empleado_id: string; sucursal_id: string; fecha_negocio: string;
  entrada_at: string; salida_at: string | null; turno_entrada: string | null;
  minutos_retardo: number | null; nota: string | null;
};

// Puesto individual de cada persona (lo que el admin asigna).
const PUESTOS: Puesto[] = ["mesero", "cocina", "caja", "repartidor", "barman", "contabilidad", "valet"];
const PUESTO_LABEL: Record<Puesto, string> = {
  mesero: "Mesero", cocina: "Cocina", caja: "Caja", repartidor: "Repartidor", barman: "Barman",
  contabilidad: "Contabilidad", valet: "Valet parking",
};
// Las 3 secciones en que se agrupa el personal para mostrarlo.
const SECCIONES: { key: string; label: string; puestos: Puesto[] }[] = [
  { key: "meseros", label: "Meseros", puestos: ["mesero"] },
  { key: "cocina", label: "Cocina", puestos: ["cocina"] },
  { key: "servicio", label: "Caja, barra y otros", puestos: ["caja", "repartidor", "barman", "contabilidad", "valet"] },
];
const seccionDe = (p: Puesto) => SECCIONES.find((s) => s.puestos.includes(p));
// Columnas Lun..Dom -> dia_semana (0=Dom)
const DIAS = [
  { dow: 1, label: "Lun" }, { dow: 2, label: "Mar" }, { dow: 3, label: "Mié" },
  { dow: 4, label: "Jue" }, { dow: 5, label: "Vie" }, { dow: 6, label: "Sáb" }, { dow: 0, label: "Dom" },
];
const TOLERANCIA_MIN = 5;

const hhmm = (t: string | null) => (t ? t.slice(0, 5) : "");
const horaLocal = (iso: string | null) =>
  iso ? new Date(iso).toLocaleTimeString("es-MX", { hour: "2-digit", minute: "2-digit", timeZone: "America/Mexico_City" }) : "—";

export default function AdminHorarios() {
  const navigate = useNavigate();
  const [sucursales, setSucursales] = useState<Sucursal[]>([]);
  const [empleados, setEmpleados] = useState<Empleado[]>([]);
  const [sucSel, setSucSel] = useState<string>("");

  useEffect(() => {
    (async () => {
      const { data: { session } } = await supabase.auth.getSession();
      if (!session) { navigate("/admin/login"); return; }
      const { data } = await db.from("sucursales").select("id,nombre").order("nombre");
      const sucs = (data ?? []) as Sucursal[];
      setSucursales(sucs);
      if (sucs[0]) setSucSel(sucs[0].id);
      await cargarEmpleados();
    })();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const cargarEmpleados = useCallback(async () => {
    const { data } = await db.from("empleados").select("*").order("orden");
    setEmpleados((data ?? []) as Empleado[]);
  }, []);

  return (
    <div className="min-h-screen bg-muted/30">
      {/* Header */}
      <div className="bg-card border-b sticky top-0 z-10">
        <div className="max-w-6xl mx-auto px-4 py-3 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <Button variant="ghost" size="sm" onClick={() => navigate("/admin/dashboard")}>
              <ArrowLeft className="w-4 h-4 mr-1" /> Panel
            </Button>
            <img src={logoLaOla} alt="La Ola" className="w-9 h-9 rounded-full object-cover" />
            <h1 className="text-lg font-bold">Horarios y checador</h1>
          </div>
          <Button variant="ghost" size="sm" onClick={async () => { await supabase.auth.signOut(); navigate("/admin/login"); }}>
            <LogOut className="w-4 h-4 mr-1" /> Salir
          </Button>
        </div>
      </div>

      <div className="max-w-6xl mx-auto px-4 py-6">
        <Tabs defaultValue="horarios">
          <TabsList className="mb-4 flex-wrap h-auto">
            <TabsTrigger value="horarios"><CalendarClock className="w-4 h-4 mr-1" /> Horarios</TabsTrigger>
            <TabsTrigger value="personal"><Users className="w-4 h-4 mr-1" /> Personal</TabsTrigger>
            <TabsTrigger value="asistencias"><ClipboardList className="w-4 h-4 mr-1" /> Asistencias</TabsTrigger>
          </TabsList>

          {/* Selector de sucursal compartido (excepto Personal) */}
          <TabsContent value="horarios">
            <SucursalBar sucursales={sucursales} value={sucSel} onChange={setSucSel} />
            <GridHorarios sucursalId={sucSel} empleados={empleados} />
          </TabsContent>

          <TabsContent value="personal">
            <PanelPersonal
              empleados={empleados} sucursales={sucursales} onChange={cargarEmpleados}
            />
          </TabsContent>

          <TabsContent value="asistencias">
            <SucursalBar sucursales={sucursales} value={sucSel} onChange={setSucSel} />
            <PanelAsistencias sucursalId={sucSel} empleados={empleados} />
          </TabsContent>
        </Tabs>
      </div>
    </div>
  );
}

// ============================================================
function SucursalBar({ sucursales, value, onChange }: {
  sucursales: Sucursal[]; value: string; onChange: (v: string) => void;
}) {
  return (
    <div className="mb-4 w-full sm:w-64">
      <Label className="text-xs text-muted-foreground">Sucursal</Label>
      <Select value={value} onValueChange={onChange}>
        <SelectTrigger><SelectValue placeholder="Selecciona sucursal" /></SelectTrigger>
        <SelectContent>
          {sucursales.map((s) => <SelectItem key={s.id} value={s.id}>{s.nombre}</SelectItem>)}
        </SelectContent>
      </Select>
    </div>
  );
}

// ============================================================
// PERSONAL
// ============================================================
function PanelPersonal({ empleados, sucursales, onChange }: {
  empleados: Empleado[]; sucursales: Sucursal[]; onChange: () => void;
}) {
  const [editando, setEditando] = useState<Partial<Empleado> | null>(null);

  const guardar = async () => {
    if (!editando?.nombre?.trim()) { toast.error("El nombre es obligatorio."); return; }
    if (!editando.area) { toast.error("Elige un puesto."); return; }
    if (editando.pin && !/^\d{4}$/.test(editando.pin)) { toast.error("El PIN debe ser de 4 dígitos."); return; }
    const payload = {
      nombre: editando.nombre.trim(),
      area: editando.area,
      pin: editando.pin || null,
      sucursal_principal_id: editando.sucursal_principal_id || null,
      telefono: editando.telefono || null,
      activo: editando.activo ?? true,
    };
    const res = editando.id
      ? await db.from("empleados").update(payload).eq("id", editando.id)
      : await db.from("empleados").insert(payload);
    if (res.error) { toast.error("No se pudo guardar: " + res.error.message); return; }
    toast.success("Personal guardado.");
    setEditando(null);
    onChange();
  };

  const eliminar = async (id: string) => {
    const res = await db.from("empleados").delete().eq("id", id);
    if (res.error) { toast.error("No se pudo eliminar (¿tiene turnos/asistencias?). " + res.error.message); return; }
    toast.success("Empleado eliminado.");
    onChange();
  };

  return (
    <div>
      <div className="flex items-center justify-between mb-3">
        <p className="text-sm text-muted-foreground">{empleados.length} personas registradas</p>
        <Button onClick={() => setEditando({ area: "mesero", activo: true })}>
          <Plus className="w-4 h-4 mr-1" /> Agregar
        </Button>
      </div>

      {SECCIONES.map((sec) => {
        const lista = empleados
          .filter((e) => sec.puestos.includes(e.area))
          .sort((a, b) => a.area.localeCompare(b.area) || a.orden - b.orden);
        if (!lista.length) return null;
        const mostrarPuesto = sec.puestos.length > 1; // solo en la sección mixta
        return (
          <div key={sec.key} className="mb-5">
            <h3 className="text-sm font-semibold text-muted-foreground uppercase tracking-wide mb-2">{sec.label}</h3>
            <Card>
              <CardContent className="p-0">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Nombre</TableHead>
                      {mostrarPuesto && <TableHead>Puesto</TableHead>}
                      <TableHead>Sucursal base</TableHead>
                      <TableHead>PIN</TableHead>
                      <TableHead>Estado</TableHead>
                      <TableHead className="text-right">Acciones</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {lista.map((e) => (
                      <TableRow key={e.id}>
                        <TableCell className="font-medium">{e.nombre}</TableCell>
                        {mostrarPuesto && <TableCell><Badge variant="outline">{PUESTO_LABEL[e.area]}</Badge></TableCell>}
                        <TableCell>{sucursales.find((s) => s.id === e.sucursal_principal_id)?.nombre ?? "—"}</TableCell>
                        <TableCell>{e.pin ? "••••" : <span className="text-destructive text-xs">sin PIN</span>}</TableCell>
                        <TableCell>{e.activo ? <Badge>Activo</Badge> : <Badge variant="secondary">Baja</Badge>}</TableCell>
                        <TableCell className="text-right">
                          <Button variant="ghost" size="icon" onClick={() => setEditando(e)}><Pencil className="w-4 h-4" /></Button>
                          <Button variant="ghost" size="icon" onClick={() => eliminar(e.id)}><Trash2 className="w-4 h-4 text-destructive" /></Button>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </CardContent>
            </Card>
          </div>
        );
      })}

      <Dialog open={!!editando} onOpenChange={(o) => !o && setEditando(null)}>
        <DialogContent>
          <DialogHeader><DialogTitle>{editando?.id ? "Editar" : "Nuevo"} empleado</DialogTitle></DialogHeader>
          {editando && (
            <div className="space-y-3">
              <div>
                <Label>Nombre</Label>
                <Input value={editando.nombre ?? ""} onChange={(e) => setEditando({ ...editando, nombre: e.target.value })} />
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <Label>Puesto</Label>
                  <Select value={editando.area} onValueChange={(v) => setEditando({ ...editando, area: v as Puesto })}>
                    <SelectTrigger><SelectValue /></SelectTrigger>
                    <SelectContent>
                      {PUESTOS.map((a) => <SelectItem key={a} value={a}>{PUESTO_LABEL[a]}</SelectItem>)}
                    </SelectContent>
                  </Select>
                </div>
                <div>
                  <Label>Sucursal base</Label>
                  <Select value={editando.sucursal_principal_id ?? "none"} onValueChange={(v) => setEditando({ ...editando, sucursal_principal_id: v === "none" ? null : v })}>
                    <SelectTrigger><SelectValue placeholder="—" /></SelectTrigger>
                    <SelectContent>
                      <SelectItem value="none">— Ninguna —</SelectItem>
                      {sucursales.map((s) => <SelectItem key={s.id} value={s.id}>{s.nombre}</SelectItem>)}
                    </SelectContent>
                  </Select>
                </div>
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <Label>PIN (4 dígitos)</Label>
                  <Input inputMode="numeric" maxLength={4} value={editando.pin ?? ""} onChange={(e) => setEditando({ ...editando, pin: e.target.value.replace(/\D/g, "") })} placeholder="Para el checador" />
                </div>
                <div>
                  <Label>Teléfono (opcional)</Label>
                  <Input value={editando.telefono ?? ""} onChange={(e) => setEditando({ ...editando, telefono: e.target.value })} />
                </div>
              </div>
              <div className="flex items-center gap-2">
                <Switch checked={editando.activo ?? true} onCheckedChange={(v) => setEditando({ ...editando, activo: v })} />
                <Label>Activo</Label>
              </div>
            </div>
          )}
          <DialogFooter>
            <Button variant="ghost" onClick={() => setEditando(null)}>Cancelar</Button>
            <Button onClick={guardar}>Guardar</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}

// ============================================================
// HORARIOS (cuadrícula semanal)
// ============================================================
function GridHorarios({ sucursalId, empleados }: { sucursalId: string; empleados: Empleado[] }) {
  const [turnos, setTurnos] = useState<Turno[]>([]);
  const [catalogo, setCatalogo] = useState<CatTurno[]>([]);
  const [editCelda, setEditCelda] = useState<{ empleado: Empleado; dow: number } | null>(null);

  const cargar = useCallback(async () => {
    if (!sucursalId) return;
    const [t, c] = await Promise.all([
      db.from("turnos").select("*").eq("sucursal_id", sucursalId).eq("activo", true),
      db.from("catalogo_turnos").select("*").or(`sucursal_id.eq.${sucursalId},sucursal_id.is.null`).eq("activo", true).order("orden"),
    ]);
    setTurnos((t.data ?? []) as Turno[]);
    setCatalogo((c.data ?? []) as CatTurno[]);
  }, [sucursalId]);
  useEffect(() => { cargar(); }, [cargar]);

  // Empleados que se muestran: los que ya tienen turno aquí, los que tienen esta
  // sucursal como base, y los "flotantes" (sin sucursal base) para poder agendarlos.
  const empIds = new Set(turnos.map((t) => t.empleado_id));
  const visibles = empleados.filter((e) =>
    e.activo && (empIds.has(e.id) || e.sucursal_principal_id === sucursalId || e.sucursal_principal_id === null));

  const turnosDe = (empId: string, dow: number) =>
    turnos.filter((t) => t.empleado_id === empId && t.dia_semana === dow)
      .sort((a, b) => a.hora_entrada.localeCompare(b.hora_entrada));

  if (!sucursalId) return <p className="text-muted-foreground">Selecciona una sucursal.</p>;

  return (
    <div>
      <p className="text-sm text-muted-foreground mb-3">
        Abre de lunes a domingo. Toca una celda para asignar turnos (puedes poner varios el mismo día: turno partido / hasta 3).
      </p>

      {visibles.length === 0 ? (
        <Card><CardContent className="py-8 text-center text-muted-foreground">
          No hay personal con turnos aquí todavía. Agrega gente en <b>Personal</b> (con esta sucursal como base) o asígnale un turno tocando una celda tras crearla.
        </CardContent></Card>
      ) : (
        <div className="overflow-x-auto">
          <table className="w-full border-collapse text-sm">
            <thead>
              <tr>
                <th className="text-left p-2 sticky left-0 bg-muted/30 min-w-[140px]">Empleado</th>
                {DIAS.map((d) => <th key={d.dow} className="p-2 text-center min-w-[110px]">{d.label}</th>)}
              </tr>
            </thead>
            <tbody>
              {SECCIONES.map((sec) => {
                const grupo = visibles
                  .filter((e) => sec.puestos.includes(e.area))
                  .sort((a, b) => a.area.localeCompare(b.area) || a.orden - b.orden);
                if (!grupo.length) return null;
                return (
                  <Fragment key={sec.key}>
                    <tr>
                      <td colSpan={8} className="bg-muted/50 text-xs font-semibold uppercase tracking-wide p-1.5 text-muted-foreground">{sec.label}</td>
                    </tr>
                    {grupo.map((e) => (
                      <tr key={e.id} className="border-b">
                        <td className="p-2 font-medium sticky left-0 bg-card">{e.nombre}</td>
                        {DIAS.map((d) => {
                          const cel = turnosDe(e.id, d.dow);
                          return (
                            <td key={d.dow} className="p-1 align-top">
                              <button
                                onClick={() => setEditCelda({ empleado: e, dow: d.dow })}
                                className="w-full min-h-[42px] rounded-md border border-dashed hover:border-primary hover:bg-primary/5 p-1 flex flex-col gap-1 items-stretch"
                              >
                                {cel.length === 0 ? (
                                  <span className="text-muted-foreground text-xs m-auto">+</span>
                                ) : cel.map((t) => (
                                  <span key={t.id} className="text-xs rounded bg-primary/10 text-primary px-1 py-0.5 whitespace-nowrap">
                                    {hhmm(t.hora_entrada)}–{hhmm(t.hora_salida)}
                                  </span>
                                ))}
                              </button>
                            </td>
                          );
                        })}
                      </tr>
                    ))}
                  </Fragment>
                );
              })}
            </tbody>
          </table>
        </div>
      )}

      <CatalogoTurnos sucursalId={sucursalId} catalogo={catalogo} onChange={cargar} />

      {editCelda && (
        <CeldaDialog
          empleado={editCelda.empleado} dow={editCelda.dow} sucursalId={sucursalId}
          turnos={turnosDe(editCelda.empleado.id, editCelda.dow)} catalogo={catalogo}
          onClose={() => setEditCelda(null)} onChange={cargar}
        />
      )}
    </div>
  );
}

function CeldaDialog({ empleado, dow, sucursalId, turnos, catalogo, onClose, onChange }: {
  empleado: Empleado; dow: number; sucursalId: string; turnos: Turno[]; catalogo: CatTurno[];
  onClose: () => void; onChange: () => void;
}) {
  const [entrada, setEntrada] = useState("");
  const [salida, setSalida] = useState("");
  const diaLabel = DIAS.find((d) => d.dow === dow)?.label;

  const agregar = async (e: string, s: string, catId?: string) => {
    if (!e || !s) { toast.error("Pon hora de entrada y salida."); return; }
    const res = await db.from("turnos").insert({
      empleado_id: empleado.id, sucursal_id: sucursalId, dia_semana: dow,
      hora_entrada: e, hora_salida: s, catalogo_turno_id: catId ?? null, activo: true,
    });
    if (res.error) { toast.error(res.error.message); return; }
    setEntrada(""); setSalida("");
    onChange();
  };

  const quitar = async (id: string) => {
    const res = await db.from("turnos").delete().eq("id", id);
    if (res.error) { toast.error(res.error.message); return; }
    onChange();
  };

  return (
    <Dialog open onOpenChange={(o) => !o && onClose()}>
      <DialogContent>
        <DialogHeader><DialogTitle>{empleado.nombre} · {diaLabel}</DialogTitle></DialogHeader>
        <div className="space-y-4">
          {turnos.length > 0 && (
            <div className="space-y-1">
              <Label className="text-xs text-muted-foreground">Turnos de este día</Label>
              {turnos.map((t) => (
                <div key={t.id} className="flex items-center justify-between rounded border px-2 py-1">
                  <span className="text-sm">{hhmm(t.hora_entrada)}–{hhmm(t.hora_salida)}</span>
                  <Button variant="ghost" size="icon" onClick={() => quitar(t.id)}><Trash2 className="w-4 h-4 text-destructive" /></Button>
                </div>
              ))}
            </div>
          )}

          {catalogo.length > 0 && (
            <div>
              <Label className="text-xs text-muted-foreground">Turnos guardados (toca para agregar)</Label>
              <div className="flex flex-wrap gap-2 mt-1">
                {catalogo.map((c) => (
                  <button key={c.id} onClick={() => agregar(c.hora_entrada, c.hora_salida, c.id)}
                    className="text-xs rounded-full border px-2 py-1 hover:bg-primary/5"
                    style={{ borderColor: c.color, color: c.color }}>
                    {c.nombre} · {hhmm(c.hora_entrada)}–{hhmm(c.hora_salida)}
                  </button>
                ))}
              </div>
            </div>
          )}

          <div>
            <Label className="text-xs text-muted-foreground">Agregar turno manual</Label>
            <div className="flex items-end gap-2 mt-1">
              <div><Label className="text-xs">Entrada</Label><Input type="time" value={entrada} onChange={(e) => setEntrada(e.target.value)} /></div>
              <div><Label className="text-xs">Salida</Label><Input type="time" value={salida} onChange={(e) => setSalida(e.target.value)} /></div>
              <Button onClick={() => agregar(entrada, salida)}><Plus className="w-4 h-4" /></Button>
            </div>
          </div>
        </div>
        <DialogFooter><Button variant="ghost" onClick={onClose}>Listo</Button></DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

function CatalogoTurnos({ sucursalId, catalogo, onChange }: {
  sucursalId: string; catalogo: CatTurno[]; onChange: () => void;
}) {
  const [nombre, setNombre] = useState("");
  const [entrada, setEntrada] = useState("");
  const [salida, setSalida] = useState("");

  const crear = async () => {
    if (!nombre.trim() || !entrada || !salida) { toast.error("Completa nombre, entrada y salida."); return; }
    const res = await db.from("catalogo_turnos").insert({
      sucursal_id: sucursalId, nombre: nombre.trim(), hora_entrada: entrada, hora_salida: salida,
    });
    if (res.error) { toast.error(res.error.message); return; }
    setNombre(""); setEntrada(""); setSalida("");
    onChange();
  };
  const borrar = async (id: string) => {
    const res = await db.from("catalogo_turnos").delete().eq("id", id);
    if (res.error) { toast.error(res.error.message); return; }
    onChange();
  };

  return (
    <Card className="mt-6">
      <CardHeader className="pb-2"><CardTitle className="text-base flex items-center gap-2"><Clock className="w-4 h-4" /> Turnos guardados</CardTitle></CardHeader>
      <CardContent>
        <p className="text-xs text-muted-foreground mb-3">Define turnos con nombre (Matutino, Vespertino, Nocturno…) para llenar la cuadrícula con un toque.</p>
        <div className="flex flex-wrap gap-2 mb-3">
          {catalogo.map((c) => (
            <span key={c.id} className="text-xs rounded-full border px-2 py-1 flex items-center gap-1" style={{ borderColor: c.color, color: c.color }}>
              {c.nombre} · {hhmm(c.hora_entrada)}–{hhmm(c.hora_salida)}
              <button onClick={() => borrar(c.id)}><Trash2 className="w-3 h-3" /></button>
            </span>
          ))}
        </div>
        <div className="flex flex-wrap items-end gap-2">
          <div><Label className="text-xs">Nombre</Label><Input className="w-32" value={nombre} onChange={(e) => setNombre(e.target.value)} placeholder="Matutino" /></div>
          <div><Label className="text-xs">Entrada</Label><Input type="time" value={entrada} onChange={(e) => setEntrada(e.target.value)} /></div>
          <div><Label className="text-xs">Salida</Label><Input type="time" value={salida} onChange={(e) => setSalida(e.target.value)} /></div>
          <Button variant="outline" onClick={crear}><Plus className="w-4 h-4 mr-1" /> Guardar turno</Button>
        </div>
      </CardContent>
    </Card>
  );
}

// ============================================================
// ASISTENCIAS
// ============================================================
function PanelAsistencias({ sucursalId, empleados }: { sucursalId: string; empleados: Empleado[] }) {
  const hoyMX = new Date().toLocaleDateString("en-CA", { timeZone: "America/Mexico_City" });
  const [fecha, setFecha] = useState(hoyMX);
  const [lista, setLista] = useState<Asistencia[]>([]);

  const cargar = useCallback(async () => {
    if (!sucursalId || !fecha) return;
    const { data } = await db.from("asistencias").select("*")
      .eq("sucursal_id", sucursalId).eq("fecha_negocio", fecha).order("entrada_at");
    setLista((data ?? []) as Asistencia[]);
  }, [sucursalId, fecha]);
  useEffect(() => { cargar(); }, [cargar]);

  const nombre = (id: string) => empleados.find((e) => e.id === id)?.nombre ?? "—";
  const horas = (a: Asistencia) => {
    if (!a.salida_at) return "en turno";
    const min = Math.round((new Date(a.salida_at).getTime() - new Date(a.entrada_at).getTime()) / 60000);
    return `${Math.floor(min / 60)}h ${min % 60}m`;
  };

  if (!sucursalId) return <p className="text-muted-foreground">Selecciona una sucursal.</p>;

  return (
    <div>
      <div className="mb-3 w-full sm:w-48">
        <Label className="text-xs text-muted-foreground">Día de negocio</Label>
        <Input type="date" value={fecha} onChange={(e) => setFecha(e.target.value)} />
      </div>
      <Card>
        <CardContent className="p-0">
          <Table>
            <TableHeader><TableRow>
              <TableHead>Empleado</TableHead><TableHead>Entrada</TableHead><TableHead>Turno</TableHead>
              <TableHead>Retardo</TableHead><TableHead>Salida</TableHead><TableHead>Trabajado</TableHead>
            </TableRow></TableHeader>
            <TableBody>
              {lista.length === 0 ? (
                <TableRow><TableCell colSpan={6} className="text-center text-muted-foreground py-6">Sin registros este día.</TableCell></TableRow>
              ) : lista.map((a) => (
                <TableRow key={a.id}>
                  <TableCell className="font-medium">{nombre(a.empleado_id)}</TableCell>
                  <TableCell>{horaLocal(a.entrada_at)}</TableCell>
                  <TableCell>{a.turno_entrada ? hhmm(a.turno_entrada) : "—"}</TableCell>
                  <TableCell>
                    {a.minutos_retardo == null ? "—"
                      : a.minutos_retardo > TOLERANCIA_MIN
                      ? <Badge variant="destructive">{a.minutos_retardo} min</Badge>
                      : <Badge>a tiempo</Badge>}
                  </TableCell>
                  <TableCell>{horaLocal(a.salida_at)}</TableCell>
                  <TableCell>{horas(a)}</TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </CardContent>
      </Card>
    </div>
  );
}
