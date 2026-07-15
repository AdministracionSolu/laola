import { useEffect, useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Badge } from "@/components/ui/badge";
import { toast } from "sonner";
import { ArrowLeft, LogOut, RefreshCw, Search, Users, UserPlus, Cake, Store, Download, Trophy, Gift, Ticket, Plus, Trash2, Save, Clock } from "lucide-react";
import logoLaOla from "@/assets/logo-la-ola.jpeg";

type Cliente = {
  id: string;
  telefono: string;
  nombre: string;
  primer_nombre: string | null;
  segundo_nombre: string | null;
  apellido_paterno: string | null;
  apellido_materno: string | null;
  cumpleanos: string | null;
  sucursal_captacion_id: string | null;
  sucursal_captacion_codigo: string | null;
  consentimiento_marketing: boolean;
  activo: boolean;
  created_at: string;
  visitas_total: number;
  recompensas_usadas: number;
};
type Sucursal = { id: string; nombre: string; prefijo_folio: string | null };
type Nivel = { id: string; nombre: string; min_visitas: number; beneficio: string | null; color: string; orden: number; activo: boolean };
type Config = { id: number; meta_visitas: number; tope_visitas_dia: number; recompensa_texto: string };
type Visita = { id: string; cliente_id: string; sucursal_id: string | null; fecha_negocio: string; origen: string; folio: string | null; created_at: string };

const db = supabase as any;

export default function AdminLealtad() {
  const navigate = useNavigate();
  const [cargando, setCargando] = useState(true);
  const [clientes, setClientes] = useState<Cliente[]>([]);
  const [sucursales, setSucursales] = useState<Sucursal[]>([]);
  const [busqueda, setBusqueda] = useState("");
  const [filtroSuc, setFiltroSuc] = useState("todas");
  const [niveles, setNiveles] = useState<Nivel[]>([]);
  const [config, setConfig] = useState<Config | null>(null);
  const [visitas, setVisitas] = useState<Visita[]>([]);

  useEffect(() => {
    (async () => {
      const { data: { session } } = await supabase.auth.getSession();
      if (!session) {
        navigate("/admin/login");
        return;
      }
      await cargar();
    })();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const cargar = async () => {
    setCargando(true);
    const [cli, suc, niv, cfg, vis] = await Promise.all([
      db.from("lealtad_clientes").select("*").order("visitas_total", { ascending: false }),
      db.from("sucursales").select("id,nombre,prefijo_folio").order("nombre"),
      db.from("lealtad_niveles").select("*").order("min_visitas"),
      db.from("lealtad_config").select("*").eq("id", 1).maybeSingle(),
      db.from("lealtad_visitas").select("*").order("created_at", { ascending: false }).limit(60),
    ]);
    if (cli.error) toast.error("No pudimos cargar los clientes.");
    setClientes((cli.data ?? []) as Cliente[]);
    setSucursales((suc.data ?? []) as Sucursal[]);
    setNiveles((niv.data ?? []) as Nivel[]);
    setConfig((cfg.data ?? null) as Config | null);
    setVisitas((vis.data ?? []) as Visita[]);
    setCargando(false);
  };

  const nombreSucursal = (c: Cliente) =>
    sucursales.find((s) => s.id === c.sucursal_captacion_id)?.nombre ??
    c.sucursal_captacion_codigo ?? "Sin sucursal";
  const nombreSucId = (id: string | null) => sucursales.find((s) => s.id === id)?.nombre ?? "—";

  // Nivel de un cliente según sus visitas acumuladas.
  const nivelDe = (total: number): Nivel | null => {
    const alcanzados = niveles.filter((n) => n.activo && n.min_visitas <= total);
    return alcanzados.length ? alcanzados[alcanzados.length - 1] : null;
  };
  const meta = Math.max(1, config?.meta_visitas ?? 10);
  const recompDisp = (c: Cliente) => Math.max(0, Math.floor(c.visitas_total / meta) - c.recompensas_usadas);

  const canjear = async (c: Cliente) => {
    const { data, error } = await db.rpc("lealtad_canjear", { p_telefono: c.telefono });
    if (error) {
      toast.error(error.message.includes("SIN_RECOMPENSAS") ? "No tiene recompensas disponibles." : "No se pudo canjear.");
      return;
    }
    toast.success(`Recompensa canjeada a ${c.nombre}.`);
    const r = data as any;
    setClientes((prev) => prev.map((x) => x.id === c.id ? { ...x, recompensas_usadas: x.recompensas_usadas + 1 } : x));
    void r;
  };

  const guardarConfig = async () => {
    if (!config) return;
    const { error } = await db.from("lealtad_config").update({
      meta_visitas: config.meta_visitas, tope_visitas_dia: config.tope_visitas_dia,
      recompensa_texto: config.recompensa_texto, updated_at: new Date().toISOString(),
    }).eq("id", 1);
    if (error) return toast.error("No se pudo guardar la configuración.");
    toast.success("Configuración guardada.");
  };

  const guardarNivel = async (n: Nivel) => {
    const payload = { nombre: n.nombre, min_visitas: n.min_visitas, beneficio: n.beneficio, color: n.color, orden: n.orden, activo: n.activo };
    const res = n.id.startsWith("nuevo-")
      ? await db.from("lealtad_niveles").insert(payload)
      : await db.from("lealtad_niveles").update(payload).eq("id", n.id);
    if (res.error) return toast.error("No se pudo guardar el nivel.");
    toast.success("Nivel guardado.");
    cargar();
  };
  const borrarNivel = async (id: string) => {
    if (id.startsWith("nuevo-")) { setNiveles((p) => p.filter((n) => n.id !== id)); return; }
    const { error } = await db.from("lealtad_niveles").delete().eq("id", id);
    if (error) return toast.error("No se pudo borrar.");
    cargar();
  };

  // ---------- Métricas ----------
  const stats = useMemo(() => {
    const activos = clientes.filter((c) => c.activo);
    const hoy = new Date().toISOString().slice(0, 10);
    const hace7 = new Date(Date.now() - 7 * 864e5).toISOString();
    const porSuc = new Map<string, number>();
    for (const c of activos) {
      const k = nombreSucursal(c);
      porSuc.set(k, (porSuc.get(k) ?? 0) + 1);
    }
    return {
      total: activos.length,
      altasHoy: activos.filter((c) => c.created_at.slice(0, 10) === hoy).length,
      altas7: activos.filter((c) => c.created_at >= hace7).length,
      conCumple: activos.filter((c) => c.cumpleanos).length,
      porSuc: [...porSuc.entries()].sort((a, b) => b[1] - a[1]),
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [clientes, sucursales]);

  // ---------- Tabla filtrada ----------
  const filtrados = useMemo(() => {
    const q = busqueda.trim().toLowerCase();
    return clientes.filter((c) => {
      if (filtroSuc !== "todas" && c.sucursal_captacion_id !== filtroSuc) return false;
      if (!q) return true;
      return c.nombre.toLowerCase().includes(q) || c.telefono.includes(q.replace(/\D/g, ""));
    });
  }, [clientes, busqueda, filtroSuc]);

  const darBaja = async (c: Cliente) => {
    const { error } = await db
      .from("lealtad_clientes")
      .update({ activo: !c.activo })
      .eq("id", c.id);
    if (error) return toast.error("No se pudo actualizar.");
    toast.success(c.activo ? "Cliente dado de baja." : "Cliente reactivado.");
    setClientes((prev) => prev.map((x) => (x.id === c.id ? { ...x, activo: !x.activo } : x)));
  };

  const exportarCSV = () => {
    const filas = [
      ["primer_nombre", "segundo_nombre", "apellido_paterno", "apellido_materno", "nombre", "telefono", "sucursal_captacion", "cumpleanos", "visitas", "consentimiento", "activo", "fecha_registro"],
      ...filtrados.map((c) => [
        c.primer_nombre ?? "",
        c.segundo_nombre ?? "",
        c.apellido_paterno ?? "",
        c.apellido_materno ?? "",
        c.nombre,
        c.telefono,
        nombreSucursal(c),
        c.cumpleanos ?? "",
        c.visitas_total ?? 0,
        c.consentimiento_marketing ? "si" : "no",
        c.activo ? "si" : "no",
        c.created_at.slice(0, 10),
      ]),
    ];
    const csv = filas.map((f) => f.map((v) => `"${String(v).replace(/"/g, '""')}"`).join(",")).join("\n");
    const url = URL.createObjectURL(new Blob([csv], { type: "text/csv;charset=utf-8" }));
    const a = document.createElement("a");
    a.href = url;
    a.download = `lealtad-la-ola-${new Date().toISOString().slice(0, 10)}.csv`;
    a.click();
    URL.revokeObjectURL(url);
  };

  if (cargando) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary" />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background">
      {/* Header */}
      <header className="bg-card border-b sticky top-0 z-50">
        <div className="container mx-auto px-4 py-4 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <Button variant="ghost" size="icon" onClick={() => navigate("/admin/dashboard")}>
              <ArrowLeft className="w-5 h-5" />
            </Button>
            <img src={logoLaOla} alt="La Ola" className="w-10 h-10 rounded-full object-cover" />
            <div>
              <h1 className="text-xl font-bold">Programa de Lealtad</h1>
              <p className="text-sm text-muted-foreground">Clientes registrados</p>
            </div>
          </div>
          <div className="flex items-center gap-2">
            <Button variant="outline" onClick={exportarCSV} className="gap-2">
              <Download className="w-4 h-4" />
              <span className="hidden sm:inline">Exportar CSV</span>
            </Button>
            <Button variant="outline" size="icon" onClick={cargar}>
              <RefreshCw className="w-4 h-4" />
            </Button>
            <Button variant="outline" onClick={async () => { await supabase.auth.signOut(); navigate("/admin/login"); }}>
              <LogOut className="w-4 h-4 mr-2" /> Salir
            </Button>
          </div>
        </div>
      </header>

      <main className="container mx-auto px-4 py-8 space-y-6">
        {/* Métricas */}
        <div className="grid grid-cols-2 lg:grid-cols-3 gap-4">
          <StatCard icon={<Users className="w-5 h-5" />} label="Clientes activos" value={stats.total} />
          <StatCard icon={<UserPlus className="w-5 h-5" />} label="Altas hoy" value={stats.altasHoy} />
          <StatCard icon={<UserPlus className="w-5 h-5" />} label="Altas (7 días)" value={stats.altas7} />
          <StatCard
            icon={<Cake className="w-5 h-5" />}
            label="Con cumpleaños"
            value={stats.conCumple}
            sub={stats.total ? `${Math.round((stats.conCumple / stats.total) * 100)}%` : "0%"}
          />
          <StatCard icon={<Trophy className="w-5 h-5" />} label="Visitas acumuladas" value={clientes.reduce((s, c) => s + (c.visitas_total || 0), 0)} />
          <StatCard icon={<Ticket className="w-5 h-5" />} label="Recompensas por canjear" value={clientes.reduce((s, c) => s + recompDisp(c), 0)} />
        </div>

        {/* Por sucursal */}
        <Card>
          <CardHeader className="pb-3">
            <CardTitle className="text-lg flex items-center gap-2">
              <Store className="w-4 h-4" /> Registros por sucursal
            </CardTitle>
          </CardHeader>
          <CardContent>
            {stats.porSuc.length === 0 ? (
              <p className="text-sm text-muted-foreground">Aún no hay registros.</p>
            ) : (
              <div className="flex flex-wrap gap-2">
                {stats.porSuc.map(([nombre, n]) => (
                  <Badge key={nombre} variant="secondary" className="text-sm py-1.5 px-3">
                    {nombre}: <span className="font-bold ml-1">{n}</span>
                  </Badge>
                ))}
              </div>
            )}
          </CardContent>
        </Card>

        {/* Configuración del programa + Niveles */}
        <div className="grid lg:grid-cols-2 gap-4">
          <Card>
            <CardHeader className="pb-3"><CardTitle className="text-lg flex items-center gap-2"><Gift className="w-4 h-4" /> Reglas del programa</CardTitle></CardHeader>
            <CardContent className="space-y-3">
              {config && (
                <>
                  <div className="grid grid-cols-2 gap-3">
                    <div>
                      <label className="text-xs text-muted-foreground">Visitas por recompensa</label>
                      <Input type="number" min={1} value={config.meta_visitas}
                        onChange={(e) => setConfig({ ...config, meta_visitas: Math.max(1, Number(e.target.value) || 1) })} />
                    </div>
                    <div>
                      <label className="text-xs text-muted-foreground">Cap de visitas por día (por tel.)</label>
                      <Input type="number" min={1} value={config.tope_visitas_dia}
                        onChange={(e) => setConfig({ ...config, tope_visitas_dia: Math.max(1, Number(e.target.value) || 1) })} />
                    </div>
                  </div>
                  <div>
                    <label className="text-xs text-muted-foreground">Recompensa (texto que ve la caja)</label>
                    <Input value={config.recompensa_texto}
                      onChange={(e) => setConfig({ ...config, recompensa_texto: e.target.value })} />
                  </div>
                  <Button onClick={guardarConfig} className="gap-2"><Save className="w-4 h-4" /> Guardar reglas</Button>
                  <p className="text-xs text-muted-foreground">
                    El blindaje principal es el folio del ticket: cada folio cuenta una sola visita por sucursal por día. El cap por día es un límite extra anti-abuso: aunque tenga varios tickets, un mismo teléfono no suma más de esta cantidad de visitas al día.
                  </p>
                </>
              )}
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="pb-3"><CardTitle className="text-lg flex items-center gap-2"><Trophy className="w-4 h-4" /> Niveles</CardTitle></CardHeader>
            <CardContent className="space-y-2">
              {niveles.map((n, i) => (
                <div key={n.id} className="flex flex-wrap items-end gap-2 border-b pb-2">
                  <div className="w-24">
                    <label className="text-[10px] text-muted-foreground">Nombre</label>
                    <Input className="h-9" value={n.nombre} onChange={(e) => setNiveles((p) => p.map((x, j) => j === i ? { ...x, nombre: e.target.value } : x))} />
                  </div>
                  <div className="w-20">
                    <label className="text-[10px] text-muted-foreground">Desde (visitas)</label>
                    <Input className="h-9" type="number" min={0} value={n.min_visitas} onChange={(e) => setNiveles((p) => p.map((x, j) => j === i ? { ...x, min_visitas: Number(e.target.value) || 0 } : x))} />
                  </div>
                  <div className="flex-1 min-w-[120px]">
                    <label className="text-[10px] text-muted-foreground">Beneficio</label>
                    <Input className="h-9" value={n.beneficio ?? ""} onChange={(e) => setNiveles((p) => p.map((x, j) => j === i ? { ...x, beneficio: e.target.value } : x))} />
                  </div>
                  <input type="color" value={n.color} className="h-9 w-9 rounded border" onChange={(e) => setNiveles((p) => p.map((x, j) => j === i ? { ...x, color: e.target.value } : x))} />
                  <Button size="icon" variant="ghost" onClick={() => guardarNivel(n)}><Save className="w-4 h-4" /></Button>
                  <Button size="icon" variant="ghost" onClick={() => borrarNivel(n.id)}><Trash2 className="w-4 h-4 text-destructive" /></Button>
                </div>
              ))}
              <Button variant="outline" size="sm" className="gap-1"
                onClick={() => setNiveles((p) => [...p, { id: `nuevo-${p.length}`, nombre: "Nuevo nivel", min_visitas: 0, beneficio: "", color: "#0ea5e9", orden: p.length + 1, activo: true }])}>
                <Plus className="w-4 h-4" /> Agregar nivel
              </Button>
            </CardContent>
          </Card>
        </div>

        {/* Filtros */}
        <div className="flex flex-col sm:flex-row gap-3">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
            <Input
              value={busqueda}
              onChange={(e) => setBusqueda(e.target.value)}
              placeholder="Buscar por nombre o teléfono"
              className="pl-9 h-11"
            />
          </div>
          <Select value={filtroSuc} onValueChange={setFiltroSuc}>
            <SelectTrigger className="sm:max-w-xs h-11">
              <SelectValue placeholder="Todas las sucursales" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="todas">Todas las sucursales</SelectItem>
              {sucursales.map((s) => (
                <SelectItem key={s.id} value={s.id}>{s.nombre}</SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>

        {/* Tabla */}
        <Card>
          <CardContent className="p-0">
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead className="bg-muted/50 text-left">
                  <tr>
                    <th className="px-4 py-3 font-semibold">Nombre</th>
                    <th className="px-4 py-3 font-semibold">Teléfono</th>
                    <th className="px-4 py-3 font-semibold">Visitas</th>
                    <th className="px-4 py-3 font-semibold">Nivel</th>
                    <th className="px-4 py-3 font-semibold">Sucursal</th>
                    <th className="px-4 py-3 font-semibold">Cumple</th>
                    <th className="px-4 py-3 font-semibold">Estado</th>
                    <th className="px-4 py-3" />
                  </tr>
                </thead>
                <tbody>
                  {filtrados.map((c) => (
                    <tr key={c.id} className={`border-t ${!c.activo ? "opacity-50" : ""}`}>
                      <td className="px-4 py-3 font-medium">{c.nombre}</td>
                      <td className="px-4 py-3 tabular-nums">{c.telefono}</td>
                      <td className="px-4 py-3 tabular-nums font-semibold">{c.visitas_total ?? 0}</td>
                      <td className="px-4 py-3">
                        {(() => { const n = nivelDe(c.visitas_total ?? 0); return n
                          ? <Badge style={{ backgroundColor: n.color }} className="text-white">{n.nombre}</Badge>
                          : <span className="text-muted-foreground">—</span>; })()}
                      </td>
                      <td className="px-4 py-3">{nombreSucursal(c)}</td>
                      <td className="px-4 py-3">{c.cumpleanos ? c.cumpleanos.slice(5) : "—"}</td>
                      <td className="px-4 py-3">
                        {c.activo
                          ? <Badge className="bg-green-600 hover:bg-green-600">Activo</Badge>
                          : <Badge variant="secondary">Baja</Badge>}
                      </td>
                      <td className="px-4 py-3 text-right whitespace-nowrap">
                        {recompDisp(c) > 0 && (
                          <Button variant="outline" size="sm" className="mr-1 gap-1" onClick={() => canjear(c)}>
                            <Ticket className="w-3.5 h-3.5" /> Canjear ({recompDisp(c)})
                          </Button>
                        )}
                        <Button variant="ghost" size="sm" onClick={() => darBaja(c)}>
                          {c.activo ? "Dar de baja" : "Reactivar"}
                        </Button>
                      </td>
                    </tr>
                  ))}
                  {filtrados.length === 0 && (
                    <tr>
                      <td colSpan={8} className="px-4 py-10 text-center text-muted-foreground">
                        Sin clientes que coincidan.
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          </CardContent>
        </Card>

        {/* Actividad reciente (anti-tranza) */}
        <Card>
          <CardHeader className="pb-3">
            <CardTitle className="text-lg flex items-center gap-2"><Clock className="w-4 h-4" /> Actividad reciente</CardTitle>
            <p className="text-xs text-muted-foreground">Últimas visitas registradas. Sirve para detectar usos raros de un mismo número.</p>
          </CardHeader>
          <CardContent className="p-0">
            <div className="max-h-80 overflow-y-auto divide-y">
              {visitas.length === 0 ? (
                <p className="p-4 text-sm text-muted-foreground">Sin visitas registradas todavía.</p>
              ) : visitas.map((v) => {
                const cli = clientes.find((c) => c.id === v.cliente_id);
                return (
                  <div key={v.id} className="flex items-center justify-between px-4 py-2 text-sm">
                    <div>
                      <span className="font-medium">{cli?.nombre ?? "—"}</span>
                      <span className="text-muted-foreground tabular-nums"> · {cli?.telefono ?? ""}</span>
                    </div>
                    <div className="text-muted-foreground text-xs text-right">
                      {nombreSucId(v.sucursal_id)}
                      {v.folio ? <> · <span className="font-medium">folio {v.folio}</span></> : null}
                      {" · "}{new Date(v.created_at).toLocaleString("es-MX", { day: "2-digit", month: "short", hour: "2-digit", minute: "2-digit", timeZone: "America/Mexico_City" })}
                    </div>
                  </div>
                );
              })}
            </div>
          </CardContent>
        </Card>

        <p className="text-xs text-muted-foreground">
          {filtrados.length} de {clientes.length} clientes · Makatea jala esta lista para las comunicaciones.
        </p>
      </main>
    </div>
  );
}

function StatCard({ icon, label, value, sub }: { icon: React.ReactNode; label: string; value: number; sub?: string }) {
  return (
    <Card>
      <CardContent className="pt-6">
        <div className="flex items-center gap-2 text-muted-foreground text-sm">
          {icon} {label}
        </div>
        <div className="mt-1 flex items-baseline gap-2">
          <span className="text-3xl font-bold">{value}</span>
          {sub && <span className="text-sm text-muted-foreground">{sub}</span>}
        </div>
      </CardContent>
    </Card>
  );
}
