import { useEffect, useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Badge } from "@/components/ui/badge";
import { toast } from "sonner";
import { ArrowLeft, LogOut, RefreshCw, Search, Users, UserPlus, Cake, Store, Download } from "lucide-react";
import logoLaOla from "@/assets/logo-la-ola.jpeg";

type Cliente = {
  id: string;
  telefono: string;
  nombre: string;
  cumpleanos: string | null;
  sucursal_captacion_id: string | null;
  sucursal_captacion_codigo: string | null;
  consentimiento_marketing: boolean;
  activo: boolean;
  created_at: string;
};
type Sucursal = { id: string; nombre: string; prefijo_folio: string | null };

const db = supabase as any;

export default function AdminLealtad() {
  const navigate = useNavigate();
  const [cargando, setCargando] = useState(true);
  const [clientes, setClientes] = useState<Cliente[]>([]);
  const [sucursales, setSucursales] = useState<Sucursal[]>([]);
  const [busqueda, setBusqueda] = useState("");
  const [filtroSuc, setFiltroSuc] = useState("todas");

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
    const [cli, suc] = await Promise.all([
      db.from("lealtad_clientes").select("*").order("created_at", { ascending: false }),
      db.from("sucursales").select("id,nombre,prefijo_folio").order("nombre"),
    ]);
    if (cli.error) toast.error("No pudimos cargar los clientes.");
    setClientes((cli.data ?? []) as Cliente[]);
    setSucursales((suc.data ?? []) as Sucursal[]);
    setCargando(false);
  };

  const nombreSucursal = (c: Cliente) =>
    sucursales.find((s) => s.id === c.sucursal_captacion_id)?.nombre ??
    c.sucursal_captacion_codigo ?? "Sin sucursal";

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
      ["nombre", "telefono", "sucursal_captacion", "cumpleanos", "consentimiento", "activo", "fecha_registro"],
      ...filtrados.map((c) => [
        c.nombre,
        c.telefono,
        nombreSucursal(c),
        c.cumpleanos ?? "",
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

  const fmtFecha = (iso: string) =>
    new Date(iso).toLocaleDateString("es-MX", { day: "2-digit", month: "short", year: "numeric" });

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
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          <StatCard icon={<Users className="w-5 h-5" />} label="Clientes activos" value={stats.total} />
          <StatCard icon={<UserPlus className="w-5 h-5" />} label="Altas hoy" value={stats.altasHoy} />
          <StatCard icon={<UserPlus className="w-5 h-5" />} label="Altas (7 días)" value={stats.altas7} />
          <StatCard
            icon={<Cake className="w-5 h-5" />}
            label="Con cumpleaños"
            value={stats.conCumple}
            sub={stats.total ? `${Math.round((stats.conCumple / stats.total) * 100)}%` : "0%"}
          />
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
                    <th className="px-4 py-3 font-semibold">Sucursal</th>
                    <th className="px-4 py-3 font-semibold">Cumple</th>
                    <th className="px-4 py-3 font-semibold">Registro</th>
                    <th className="px-4 py-3 font-semibold">Estado</th>
                    <th className="px-4 py-3" />
                  </tr>
                </thead>
                <tbody>
                  {filtrados.map((c) => (
                    <tr key={c.id} className={`border-t ${!c.activo ? "opacity-50" : ""}`}>
                      <td className="px-4 py-3 font-medium">{c.nombre}</td>
                      <td className="px-4 py-3 tabular-nums">{c.telefono}</td>
                      <td className="px-4 py-3">{nombreSucursal(c)}</td>
                      <td className="px-4 py-3">{c.cumpleanos ? c.cumpleanos.slice(5) : "—"}</td>
                      <td className="px-4 py-3 text-muted-foreground">{fmtFecha(c.created_at)}</td>
                      <td className="px-4 py-3">
                        {c.activo
                          ? <Badge className="bg-green-600 hover:bg-green-600">Activo</Badge>
                          : <Badge variant="secondary">Baja</Badge>}
                      </td>
                      <td className="px-4 py-3 text-right">
                        <Button variant="ghost" size="sm" onClick={() => darBaja(c)}>
                          {c.activo ? "Dar de baja" : "Reactivar"}
                        </Button>
                      </td>
                    </tr>
                  ))}
                  {filtrados.length === 0 && (
                    <tr>
                      <td colSpan={7} className="px-4 py-10 text-center text-muted-foreground">
                        Sin clientes que coincidan.
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
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
