import { useEffect, useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Badge } from "@/components/ui/badge";
import { toast } from "sonner";
import {
  recompensaDeCiclo,
  nivelDePosicion,
  textoSobre,
  CICLO_RECOMPENSAS,
  RECOMPENSA_INICIAL_ID,
} from "@/lib/lealtad";
import { ArrowLeft, LogOut, RefreshCw, Search, Users, UserPlus, Cake, Store, Download, Trophy, Gift, Ticket, Save, Clock } from "lucide-react";
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
  bienvenida_canjeada_at: string | null;
};
type Sucursal = { id: string; nombre: string; prefijo_folio: string | null };
/** posicion: 0 = Recompensa inicial, 1..4 = paradas del ciclo. */
type Nivel = { id: string; nombre: string; posicion: number | null; min_visitas: number; beneficio: string | null; color: string; orden: number; activo: boolean };
type Config = { id: number; meta_visitas: number; tope_visitas_dia: number; recompensa_texto: string };
type Visita = { id: string; cliente_id: string; sucursal_id: string | null; fecha_negocio: string; origen: string; folio: string | null; created_at: string };
type Recompensa = { posicion: number; titulo: string; activo: boolean };
type Canje = { id: string; cliente_id: string; posicion: number; titulo: string; sucursal_id: string | null; fecha_negocio: string; origen: string; created_at: string };
type Intento = { id: string; telefono: string; folio_norm: string | null; sucursal_id: string | null; motivo: string; fecha_negocio: string; created_at: string };

const db = supabase as any;

// Día de negocio de La Ola: rueda a las 4 AM CDMX.
const fechaNegocioHoy = () =>
  new Date(Date.now() - 4 * 3600e3).toLocaleDateString("en-CA", { timeZone: "America/Mexico_City" });

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
  const [recompensas, setRecompensas] = useState<Recompensa[]>([]);
  const [intentos, setIntentos] = useState<Intento[]>([]);
  const [visitas30, setVisitas30] = useState<Visita[]>([]);
  const [fechaConc, setFechaConc] = useState(fechaNegocioHoy());
  const [canjesDia, setCanjesDia] = useState<Canje[]>([]);
  // Teléfonos de colaboradores (grupo de WhatsApp del equipo). Identificación
  // solamente: si la tabla aún no existe, el panel funciona igual.
  const [colaboradores, setColaboradores] = useState<Set<string>>(new Set());
  const [totalColaboradores, setTotalColaboradores] = useState(0);

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
    const hace30 = new Date(Date.now() - 30 * 864e5).toISOString().slice(0, 10);
    const [cli, suc, niv, cfg, vis, rec, int, v30] = await Promise.all([
      db.from("lealtad_clientes").select("*").order("visitas_total", { ascending: false }),
      db.from("sucursales").select("id,nombre,prefijo_folio").order("nombre"),
      db.from("lealtad_niveles").select("*").order("posicion"),
      db.from("lealtad_config").select("*").eq("id", 1).maybeSingle(),
      db.from("lealtad_visitas").select("*").order("created_at", { ascending: false }).limit(60),
      db.from("lealtad_recompensas").select("*").order("posicion"),
      db.from("lealtad_intentos").select("*").order("created_at", { ascending: false }).limit(200),
      db.from("lealtad_visitas").select("id,cliente_id,sucursal_id,fecha_negocio,origen,folio,created_at").gte("fecha_negocio", hace30),
    ]);
    if (cli.error) toast.error("No pudimos cargar los clientes.");
    setClientes((cli.data ?? []) as Cliente[]);
    setSucursales((suc.data ?? []) as Sucursal[]);
    setNiveles((niv.data ?? []) as Nivel[]);
    setConfig((cfg.data ?? null) as Config | null);
    setVisitas((vis.data ?? []) as Visita[]);
    setRecompensas((rec.data ?? []) as Recompensa[]);
    setIntentos((int.data ?? []) as Intento[]);
    setVisitas30((v30.data ?? []) as Visita[]);
    const col = await db.from("lealtad_colaboradores").select("telefono").eq("activo", true);
    if (!col.error) {
      const tels = (col.data ?? []).map((r: { telefono: string }) => r.telefono);
      setColaboradores(new Set(tels));
      setTotalColaboradores(tels.length);
    }
    setCargando(false);
  };

  // Canjes del día seleccionado (conciliación contra el comandero)
  useEffect(() => {
    db.from("lealtad_canjes").select("*").eq("fecha_negocio", fechaConc).order("created_at")
      .then(({ data }: { data: Canje[] | null }) => setCanjesDia(data ?? []));
  }, [fechaConc]);

  // Ciclo del AÑO en curso (v4): visitas y canjes por cliente desde el 1 de enero
  const [visAnio, setVisAnio] = useState<Map<string, number>>(new Map());
  const [canAnio, setCanAnio] = useState<Map<string, number>>(new Map());
  useEffect(() => {
    const inicio = `${fechaNegocioHoy().slice(0, 4)}-01-01`;
    Promise.all([
      db.from("lealtad_visitas").select("cliente_id").gte("fecha_negocio", inicio),
      db.from("lealtad_canjes").select("cliente_id").gt("posicion", 0).gte("fecha_negocio", inicio),
    ]).then(([v, c]: any[]) => {
      const cuenta = (rows: { cliente_id: string }[] | null) => {
        const m = new Map<string, number>();
        for (const r of rows ?? []) m.set(r.cliente_id, (m.get(r.cliente_id) ?? 0) + 1);
        return m;
      };
      setVisAnio(cuenta(v.data));
      setCanAnio(cuenta(c.data));
    });
  }, [cargando]);

  const nombreSucursal = (c: Cliente) =>
    sucursales.find((s) => s.id === c.sucursal_captacion_id)?.nombre ??
    c.sucursal_captacion_codigo ?? "Sin sucursal";
  const nombreSucId = (id: string | null) => sucursales.find((s) => s.id === id)?.nombre ?? "—";

  const meta = Math.max(1, config?.meta_visitas ?? 3);
  const nRecs = Math.max(1, recompensas.filter((r) => r.activo).length || CICLO_RECOMPENSAS.length);

  /**
   * Nivel de un cliente = la parada del ciclo hacia la que va, no su
   * acumulado de por vida (misma regla que lealtad_perfil_json). Quien no
   * ha canjeado su Recompensa inicial se queda en la parada 0.
   */
  const nivelDe = (c: Cliente) => {
    const pos = c.bienvenida_canjeada_at ? ((canAnio.get(c.id) ?? 0) % nRecs) + 1 : 0;
    const fila = niveles.find((n) => n.posicion === pos);
    const chip = nivelDePosicion(pos);
    return { pos, nombre: fila?.nombre ?? chip.identificador, color: fila?.color ?? chip.hex };
  };
  // v4: recompensas disponibles = ciclo del AÑO natural (visitas y canjes del año)
  const recompDisp = (c: Cliente) =>
    Math.max(0, Math.floor((visAnio.get(c.id) ?? 0) / meta) - (canAnio.get(c.id) ?? 0));

  const canjear = async (c: Cliente) => {
    const { data, error } = await db.rpc("lealtad_canjear", { p_telefono: c.telefono });
    if (error) {
      toast.error(error.message.includes("SIN_RECOMPENSAS") ? "No tiene recompensas disponibles." : "No se pudo canjear.");
      return;
    }
    toast.success(`Canjeado a ${c.nombre}: ${(data as any)?.canje_titulo ?? "recompensa"}.`);
    cargar();
  };

  const guardarRecompensa = async (r: Recompensa) => {
    const { error } = await db.from("lealtad_recompensas")
      .update({ titulo: r.titulo, activo: r.activo, updated_at: new Date().toISOString() })
      .eq("posicion", r.posicion);
    if (error) return toast.error("No se pudo guardar la recompensa.");
    toast.success(`Recompensa ${r.posicion} guardada.`);
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

  // Las paradas no se agregan ni se borran desde aquí: son las mismas del
  // ciclo de recompensas. Aquí solo se corrige cómo se llaman y de qué color.
  const guardarNivel = async (n: Nivel) => {
    const { error } = await db.from("lealtad_niveles")
      .update({ nombre: n.nombre, color: n.color })
      .eq("id", n.id);
    if (error) return toast.error("No se pudo guardar el nivel.");
    toast.success("Nivel guardado.");
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

  // ---------- Conciliación del día (empatar vs comandero) ----------
  const conciliacion = useMemo(() => {
    // Se agrupa por identificador del ciclo (Visita 3, 6, 9, 12) para que
    // la conciliación se lea igual que lo que vio el mesero en pantalla.
    const porSuc = new Map<string, { total: number; porTitulo: Map<string, { n: number; posicion: number }> }>();
    for (const c of canjesDia) {
      const k = nombreSucId(c.sucursal_id) === "—" ? "Sin sucursal" : nombreSucId(c.sucursal_id);
      const e = porSuc.get(k) ?? { total: 0, porTitulo: new Map() };
      e.total += 1;
      const prev = e.porTitulo.get(c.titulo) ?? { n: 0, posicion: c.posicion };
      e.porTitulo.set(c.titulo, { n: prev.n + 1, posicion: c.posicion });
      porSuc.set(k, e);
    }
    return [...porSuc.entries()].sort((a, b) => b[1].total - a[1].total);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [canjesDia, sucursales]);

  // ---------- Anomalías ----------
  const anomalias = useMemo(() => {
    // 1) Teléfonos que topan el límite diario repetidamente (rotación de folios)
    const porTel = new Map<string, number>();
    for (const i of intentos) if (i.motivo === "ya_hoy") porTel.set(i.telefono, (porTel.get(i.telefono) ?? 0) + 1);
    const topeRepetido = [...porTel.entries()].filter(([, n]) => n >= 3).sort((a, b) => b[1] - a[1]);

    // 2) Mismo cliente con visitas en 2+ sucursales el mismo día de negocio
    const porClienteDia = new Map<string, Set<string>>();
    for (const v of visitas30) {
      if (!v.sucursal_id) continue;
      const k = `${v.cliente_id}|${v.fecha_negocio}`;
      const s = porClienteDia.get(k) ?? new Set<string>();
      s.add(v.sucursal_id);
      porClienteDia.set(k, s);
    }
    const multiSucursal = [...porClienteDia.entries()]
      .filter(([, s]) => s.size > 1)
      .map(([k, s]) => {
        const [clienteId, fecha] = k.split("|");
        return { clienteId, fecha, sucursales: [...s].map((id) => nombreSucId(id)).join(", ") };
      });

    // 3) Folios que otros teléfonos intentaron reutilizar (cuentas compartidas)
    //    y tickets que alguien quiso volver a cobrar en otro día.
    const folioConflicto = intentos.filter(
      (i) => i.motivo === "folio_usado" || i.motivo === "folio_repetido"
    );

    // 4) Folios inventados: no tienen forma de ticket. Señal fuerte.
    const folioInventado = intentos.filter((i) => i.motivo === "folio_invalido");

    return { topeRepetido, multiSucursal, folioConflicto, folioInventado };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [intentos, visitas30, sucursales]);

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
      ["primer_nombre", "segundo_nombre", "apellido_paterno", "apellido_materno", "nombre", "telefono", "sucursal_captacion", "cumpleanos", "visitas", "consentimiento", "activo", "fecha_registro", "colaborador"],
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
        colaboradores.has(c.telefono) ? "si" : "no",
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
          {totalColaboradores > 0 && (
            <StatCard
              icon={<Users className="w-5 h-5" />}
              label="Colaboradores en el programa"
              value={clientes.filter((c) => c.activo && colaboradores.has(c.telefono)).length}
              sub={`de ${totalColaboradores} identificados`}
            />
          )}
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

        {/* Conciliación diaria: canjes en sistema vs comandero */}
        <Card>
          <CardHeader className="pb-3">
            <div className="flex flex-wrap items-center justify-between gap-3">
              <CardTitle className="text-lg flex items-center gap-2">
                <Ticket className="w-4 h-4" /> Conciliación de canjes
              </CardTitle>
              <Input type="date" value={fechaConc} onChange={(e) => setFechaConc(e.target.value)} className="w-44 h-9" />
            </div>
            <p className="text-xs text-muted-foreground">
              Beneficios canjeados en sistema por día de negocio. Empátalo contra lo que registró el comandero: si el comandero tiene más cortesías que esto, se están entregando beneficios de más.
            </p>
          </CardHeader>
          <CardContent>
            {canjesDia.length === 0 ? (
              <p className="text-sm text-muted-foreground">Sin canjes registrados el {fechaConc}.</p>
            ) : (
              <div className="space-y-3">
                <div className="flex flex-wrap gap-2">
                  <Badge className="text-sm py-1.5 px-3">Total del día: {canjesDia.length}</Badge>
                  {conciliacion.map(([suc, e]) => (
                    <Badge key={suc} variant="secondary" className="text-sm py-1.5 px-3">
                      {suc}: <span className="font-bold ml-1">{e.total}</span>
                    </Badge>
                  ))}
                </div>
                <div className="overflow-x-auto">
                  <table className="w-full text-sm">
                    <thead className="bg-muted/50 text-left">
                      <tr>
                        <th className="px-3 py-2 font-semibold">Sucursal</th>
                        <th className="px-3 py-2 font-semibold">Identificador</th>
                        <th className="px-3 py-2 font-semibold">Beneficio</th>
                        <th className="px-3 py-2 font-semibold text-right">Canjes</th>
                      </tr>
                    </thead>
                    <tbody>
                      {conciliacion.flatMap(([suc, e]) =>
                        [...e.porTitulo.entries()].map(([titulo, d]) => {
                          const rec = recompensaDeCiclo(d.posicion);
                          return (
                            <tr key={`${suc}-${titulo}`} className="border-t">
                              <td className="px-3 py-2">{suc}</td>
                              <td className="px-3 py-2">
                                <span
                                  className={`inline-block px-2 py-0.5 rounded-full border-2 text-xs font-bold ${
                                    rec ? `${rec.bg} ${rec.texto} ${rec.borde}` : "bg-card text-foreground border-border"
                                  }`}
                                >
                                  {rec ? rec.identificador : RECOMPENSA_INICIAL_ID}
                                </span>
                              </td>
                              <td className="px-3 py-2">{titulo}</td>
                              <td className="px-3 py-2 text-right font-semibold tabular-nums">{d.n}</td>
                            </tr>
                          );
                        })
                      )}
                    </tbody>
                  </table>
                </div>
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
                  <Button onClick={guardarConfig} className="gap-2"><Save className="w-4 h-4" /> Guardar reglas</Button>
                  <div className="pt-2 border-t">
                    <p className="text-xs font-semibold text-muted-foreground mb-2">Ciclo de recompensas (en loop, la elección se hace en el comandero)</p>
                    <div className="space-y-2">
                      {recompensas.map((r) => {
                        const rec = recompensaDeCiclo(r.posicion);
                        return (
                        <div key={r.posicion} className="flex items-center gap-2">
                          <span className={`shrink-0 px-2 py-0.5 rounded-full border-2 text-[11px] font-bold whitespace-nowrap ${
                            rec ? `${rec.bg} ${rec.texto} ${rec.borde}` : "bg-card text-foreground border-border"
                          }`}>
                            {rec ? rec.identificador : `#${r.posicion}`}
                          </span>
                          <Input className="h-9" value={r.titulo}
                            onChange={(e) => setRecompensas((p) => p.map((x) => x.posicion === r.posicion ? { ...x, titulo: e.target.value } : x))} />
                          <Button size="icon" variant="ghost" onClick={() => guardarRecompensa(r)}><Save className="w-4 h-4" /></Button>
                        </div>
                        );
                      })}
                    </div>
                  </div>
                  <p className="text-xs text-muted-foreground">
                    Regla dura: un folio por teléfono por día. El ciclo y las recompensas cuentan por año natural; el 1 de enero todos arrancan de nuevo. La Recompensa inicial (un balazo de tu elección + cerveza o refresco, sin callo de hacha ni cerveza premium) es una sola vez, de por vida, y se canjea en la misma visita del registro.
                  </p>
                </>
              )}
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="pb-3">
              <CardTitle className="text-lg flex items-center gap-2"><Trophy className="w-4 h-4" /> Niveles</CardTitle>
              <p className="text-xs text-muted-foreground">
                Los niveles SON las paradas del ciclo: el color es el que se
                imprime y el que el mesero reconoce. El beneficio se edita
                arriba, en el ciclo de recompensas, para que no haya dos
                textos que se contradigan.
              </p>
            </CardHeader>
            <CardContent className="space-y-2">
              {niveles.map((n, i) => {
                const rec = recompensas.find((r) => r.posicion === n.posicion);
                return (
                  <div key={n.id} className="flex flex-wrap items-end gap-2 border-b pb-2">
                    <div className="w-28">
                      <label className="text-[10px] text-muted-foreground">
                        {n.posicion === 0 ? "Al inscribirse" : `Visita ${n.min_visitas} del ciclo`}
                      </label>
                      <Input className="h-9" value={n.nombre} onChange={(e) => setNiveles((p) => p.map((x, j) => j === i ? { ...x, nombre: e.target.value } : x))} />
                    </div>
                    <div className="flex-1 min-w-[160px]">
                      <label className="text-[10px] text-muted-foreground">Beneficio</label>
                      <p className="h-9 flex items-center text-sm text-muted-foreground truncate">
                        {n.beneficio ?? rec?.titulo ?? "—"}
                      </p>
                    </div>
                    <input type="color" value={n.color} className="h-9 w-9 rounded border" title="Color del nivel"
                      onChange={(e) => setNiveles((p) => p.map((x, j) => j === i ? { ...x, color: e.target.value } : x))} />
                    <Button size="icon" variant="ghost" onClick={() => guardarNivel(n)}><Save className="w-4 h-4" /></Button>
                  </div>
                );
              })}
              <p className="text-xs text-muted-foreground pt-1">
                Al llegar a <b>{niveles[niveles.length - 1]?.nombre ?? "Visita 12"}</b> el
                ciclo vuelve a arrancar en <b>{niveles[1]?.nombre ?? "Visita 3"}</b>. La
                Recompensa inicial es una sola vez de por vida y no vuelve.
              </p>
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
                      <td className="px-4 py-3 font-medium">
                        {c.nombre}
                        {colaboradores.has(c.telefono) && (
                          <Badge variant="outline" className="ml-2 align-middle text-xs border-sky-400 text-sky-700">
                            Colaborador
                          </Badge>
                        )}
                      </td>
                      <td className="px-4 py-3 tabular-nums">{c.telefono}</td>
                      <td className="px-4 py-3 tabular-nums font-semibold">{c.visitas_total ?? 0}</td>
                      <td className="px-4 py-3">
                        {(() => {
                          const n = nivelDe(c);
                          return (
                            <Badge
                              className="border"
                              style={{ backgroundColor: n.color, color: textoSobre(n.color), borderColor: "rgba(0,0,0,.15)" }}
                            >
                              {n.nombre}
                            </Badge>
                          );
                        })()}
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

        {/* Anomalías (anti-fraude) */}
        <Card>
          <CardHeader className="pb-3">
            <CardTitle className="text-lg flex items-center gap-2"><Search className="w-4 h-4" /> Anomalías</CardTitle>
            <p className="text-xs text-muted-foreground">
              Señales de abuso: números rotando folios, cuentas compartidas entre sucursales, tickets reutilizados y folios inventados. Últimos 30 días.
            </p>
          </CardHeader>
          <CardContent className="space-y-4">
            <div>
              <p className="text-sm font-semibold mb-1">Teléfonos topando el límite diario (3+ intentos rechazados)</p>
              {anomalias.topeRepetido.length === 0 ? (
                <p className="text-sm text-muted-foreground">Sin casos.</p>
              ) : (
                <div className="flex flex-wrap gap-2">
                  {anomalias.topeRepetido.map(([tel, n]) => {
                    const cli = clientes.find((c) => c.telefono === tel);
                    return (
                      <Badge key={tel} variant="destructive" className="text-sm py-1.5 px-3">
                        {cli?.nombre ?? tel} · {tel} · {n} intentos
                      </Badge>
                    );
                  })}
                </div>
              )}
            </div>
            <div>
              <p className="text-sm font-semibold mb-1">Mismo número en 2+ sucursales el mismo día</p>
              {anomalias.multiSucursal.length === 0 ? (
                <p className="text-sm text-muted-foreground">Sin casos.</p>
              ) : (
                <div className="space-y-1">
                  {anomalias.multiSucursal.map((m) => {
                    const cli = clientes.find((c) => c.id === m.clienteId);
                    return (
                      <p key={`${m.clienteId}-${m.fecha}`} className="text-sm">
                        <span className="font-medium">{cli?.nombre ?? "—"}</span>
                        <span className="text-muted-foreground"> · {cli?.telefono ?? ""} · {m.fecha} · {m.sucursales}</span>
                      </p>
                    );
                  })}
                </div>
              )}
            </div>
            <div>
              <p className="text-sm font-semibold mb-1">Folios inventados (no tienen forma de ticket)</p>
              {anomalias.folioInventado.length === 0 ? (
                <p className="text-sm text-muted-foreground">Sin casos.</p>
              ) : (
                <div className="space-y-1">
                  {anomalias.folioInventado.map((i) => {
                    const cli = clientes.find((c) => c.telefono === i.telefono);
                    return (
                      <p key={i.id} className="text-sm">
                        <span className="font-medium">{cli?.nombre ?? i.telefono}</span>
                        <span className="text-muted-foreground">
                          {" "}· {i.telefono} · escribió "{i.folio_norm}" · {i.fecha_negocio}
                        </span>
                      </p>
                    );
                  })}
                </div>
              )}
            </div>
            <div>
              <p className="text-sm font-semibold mb-1">Folios que otro teléfono intentó reutilizar</p>
              {anomalias.folioConflicto.length === 0 ? (
                <p className="text-sm text-muted-foreground">Sin casos.</p>
              ) : (
                <div className="max-h-60 overflow-y-auto divide-y">
                  {anomalias.folioConflicto.map((i) => (
                    <div key={i.id} className="flex items-center justify-between py-1.5 text-sm">
                      <span>folio <b>{i.folio_norm}</b> · intentó {i.telefono}</span>
                      <span className="text-muted-foreground text-xs">
                        {nombreSucId(i.sucursal_id)} · {i.fecha_negocio}
                      </span>
                    </div>
                  ))}
                </div>
              )}
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
