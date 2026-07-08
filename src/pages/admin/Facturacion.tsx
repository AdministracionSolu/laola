import { useEffect, useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card, CardContent } from "@/components/ui/card";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Badge } from "@/components/ui/badge";
import { toast } from "sonner";
import { ArrowLeft, LogOut, RefreshCw, Search, Copy, Download, Clock, CheckCircle2, FileText } from "lucide-react";
import logoLaOla from "@/assets/logo-la-ola.jpeg";

type Solicitud = {
  id: string;
  folio_solicitud: string;
  sucursal_codigo: string | null;
  rfc: string;
  razon_social: string;
  regimen_fiscal: string;
  codigo_postal: string;
  uso_cfdi: string;
  email: string;
  ticket_folio: string | null;
  ticket_total: number | null;
  ticket_fecha: string | null;
  estado: "pendiente" | "timbrada" | "rechazada";
  cfdi_uuid: string | null;
  created_at: string;
};

const db = supabase as any;
const ESTADOS = ["pendiente", "timbrada", "rechazada"] as const;

export default function AdminFacturacion() {
  const navigate = useNavigate();
  const [cargando, setCargando] = useState(true);
  const [rows, setRows] = useState<Solicitud[]>([]);
  const [busqueda, setBusqueda] = useState("");
  const [fEstado, setFEstado] = useState("pendiente");

  useEffect(() => {
    (async () => {
      const { data: { session } } = await supabase.auth.getSession();
      if (!session) { navigate("/admin/login"); return; }
      await cargar();
    })();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const cargar = async () => {
    setCargando(true);
    const { data, error } = await db.from("factura_solicitudes").select("*").order("created_at", { ascending: false });
    if (error) toast.error("No pudimos cargar las solicitudes.");
    setRows((data ?? []) as Solicitud[]);
    setCargando(false);
  };

  const stats = useMemo(() => {
    const hoy = new Date().toISOString().slice(0, 10);
    return {
      pendientes: rows.filter((r) => r.estado === "pendiente").length,
      timbradasHoy: rows.filter((r) => r.estado === "timbrada" && r.created_at.slice(0, 10) === hoy).length,
      hoy: rows.filter((r) => r.created_at.slice(0, 10) === hoy).length,
    };
  }, [rows]);

  const filtrados = useMemo(() => {
    const q = busqueda.trim().toLowerCase();
    return rows.filter((r) => {
      if (fEstado !== "todas" && r.estado !== fEstado) return false;
      if (!q) return true;
      return r.rfc.toLowerCase().includes(q) || r.razon_social.toLowerCase().includes(q) || r.folio_solicitud.toLowerCase().includes(q);
    });
  }, [rows, busqueda, fEstado]);

  const setEstado = async (r: Solicitud, estado: Solicitud["estado"]) => {
    const { error } = await db.from("factura_solicitudes").update({ estado }).eq("id", r.id);
    if (error) return toast.error("No se pudo actualizar.");
    setRows((p) => p.map((x) => (x.id === r.id ? { ...x, estado } : x)));
  };

  const guardarUuid = async (r: Solicitud, cfdi_uuid: string) => {
    const val = cfdi_uuid.trim() || null;
    const { error } = await db.from("factura_solicitudes").update({ cfdi_uuid: val }).eq("id", r.id);
    if (error) return toast.error("No se pudo guardar el folio fiscal.");
    setRows((p) => p.map((x) => (x.id === r.id ? { ...x, cfdi_uuid: val } : x)));
  };

  const copiarFiscal = (r: Solicitud) => {
    const t = [
      `RFC: ${r.rfc}`,
      `Razón social: ${r.razon_social}`,
      `Régimen fiscal: ${r.regimen_fiscal}`,
      `C.P.: ${r.codigo_postal}`,
      `Uso CFDI: ${r.uso_cfdi}`,
      `Correo: ${r.email}`,
      r.ticket_total != null ? `Total: $${r.ticket_total}` : "",
    ].filter(Boolean).join("\n");
    navigator.clipboard.writeText(t);
    toast.success("Datos fiscales copiados. Pégalos en Compact.");
  };

  const exportarCSV = () => {
    const filas = [
      ["folio_solicitud", "fecha", "sucursal", "rfc", "razon_social", "regimen", "cp", "uso_cfdi", "email", "ticket", "total", "estado", "cfdi_uuid"],
      ...filtrados.map((r) => [
        r.folio_solicitud, r.created_at.slice(0, 10), r.sucursal_codigo ?? "", r.rfc, r.razon_social,
        r.regimen_fiscal, r.codigo_postal, r.uso_cfdi, r.email, r.ticket_folio ?? "",
        r.ticket_total ?? "", r.estado, r.cfdi_uuid ?? "",
      ]),
    ];
    const csv = filas.map((f) => f.map((v) => `"${String(v).replace(/"/g, '""')}"`).join(",")).join("\n");
    const url = URL.createObjectURL(new Blob([csv], { type: "text/csv;charset=utf-8" }));
    const a = document.createElement("a");
    a.href = url; a.download = `facturas-la-ola-${new Date().toISOString().slice(0, 10)}.csv`; a.click();
    URL.revokeObjectURL(url);
  };

  const fmt = (iso: string) => new Date(iso).toLocaleDateString("es-MX", { day: "2-digit", month: "short" });
  const badgeEstado = (e: string) =>
    e === "timbrada" ? <Badge className="bg-green-600 hover:bg-green-600">Timbrada</Badge>
    : e === "rechazada" ? <Badge variant="destructive">Rechazada</Badge>
    : <Badge variant="secondary">Pendiente</Badge>;

  if (cargando) {
    return <div className="min-h-screen flex items-center justify-center"><div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary" /></div>;
  }

  return (
    <div className="min-h-screen bg-background">
      <header className="bg-card border-b sticky top-0 z-50">
        <div className="container mx-auto px-4 py-4 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <Button variant="ghost" size="icon" onClick={() => navigate("/admin/dashboard")}><ArrowLeft className="w-5 h-5" /></Button>
            <img src={logoLaOla} alt="La Ola" className="w-10 h-10 rounded-full object-cover" />
            <div>
              <h1 className="text-xl font-bold">Facturación</h1>
              <p className="text-sm text-muted-foreground">Solicitudes de factura</p>
            </div>
          </div>
          <div className="flex items-center gap-2">
            <Button variant="outline" onClick={exportarCSV} className="gap-2"><Download className="w-4 h-4" /><span className="hidden sm:inline">Exportar CSV</span></Button>
            <Button variant="outline" size="icon" onClick={cargar}><RefreshCw className="w-4 h-4" /></Button>
            <Button variant="outline" onClick={async () => { await supabase.auth.signOut(); navigate("/admin/login"); }}><LogOut className="w-4 h-4 mr-2" />Salir</Button>
          </div>
        </div>
      </header>

      <main className="container mx-auto px-4 py-8 space-y-6">
        <div className="grid grid-cols-3 gap-4">
          <Stat icon={<Clock className="w-5 h-5" />} label="Pendientes" value={stats.pendientes} accent />
          <Stat icon={<CheckCircle2 className="w-5 h-5" />} label="Timbradas hoy" value={stats.timbradasHoy} />
          <Stat icon={<FileText className="w-5 h-5" />} label="Solicitudes hoy" value={stats.hoy} />
        </div>

        <div className="flex flex-col sm:flex-row gap-3">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
            <Input value={busqueda} onChange={(e) => setBusqueda(e.target.value)} placeholder="Buscar por RFC, razón social o folio" className="pl-9 h-11" />
          </div>
          <Select value={fEstado} onValueChange={setFEstado}>
            <SelectTrigger className="sm:max-w-[200px] h-11"><SelectValue /></SelectTrigger>
            <SelectContent>
              <SelectItem value="pendiente">Pendientes</SelectItem>
              <SelectItem value="timbrada">Timbradas</SelectItem>
              <SelectItem value="rechazada">Rechazadas</SelectItem>
              <SelectItem value="todas">Todas</SelectItem>
            </SelectContent>
          </Select>
        </div>

        <Card>
          <CardContent className="p-0">
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead className="bg-muted/50 text-left">
                  <tr>
                    <th className="px-3 py-3 font-semibold">Folio</th>
                    <th className="px-3 py-3 font-semibold">Fecha</th>
                    <th className="px-3 py-3 font-semibold">Suc</th>
                    <th className="px-3 py-3 font-semibold">RFC</th>
                    <th className="px-3 py-3 font-semibold">Razón social</th>
                    <th className="px-3 py-3 font-semibold">Rég</th>
                    <th className="px-3 py-3 font-semibold">C.P.</th>
                    <th className="px-3 py-3 font-semibold">Uso</th>
                    <th className="px-3 py-3 font-semibold">Total</th>
                    <th className="px-3 py-3 font-semibold">Estado</th>
                    <th className="px-3 py-3 font-semibold">Folio fiscal (UUID)</th>
                    <th className="px-3 py-3" />
                  </tr>
                </thead>
                <tbody>
                  {filtrados.map((r) => (
                    <tr key={r.id} className="border-t align-top">
                      <td className="px-3 py-3 font-mono text-xs whitespace-nowrap">{r.folio_solicitud}</td>
                      <td className="px-3 py-3 text-muted-foreground whitespace-nowrap">{fmt(r.created_at)}</td>
                      <td className="px-3 py-3">{r.sucursal_codigo}</td>
                      <td className="px-3 py-3 font-mono">{r.rfc}</td>
                      <td className="px-3 py-3 max-w-[180px]">
                        <div className="font-medium truncate" title={r.razon_social}>{r.razon_social}</div>
                        <div className="text-xs text-muted-foreground truncate">{r.email}</div>
                      </td>
                      <td className="px-3 py-3">{r.regimen_fiscal}</td>
                      <td className="px-3 py-3">{r.codigo_postal}</td>
                      <td className="px-3 py-3">{r.uso_cfdi}</td>
                      <td className="px-3 py-3 whitespace-nowrap">{r.ticket_total != null ? `$${r.ticket_total}` : "—"}</td>
                      <td className="px-3 py-3">
                        <Select value={r.estado} onValueChange={(v) => setEstado(r, v as Solicitud["estado"])}>
                          <SelectTrigger className="h-8 w-[120px]">{badgeEstado(r.estado)}</SelectTrigger>
                          <SelectContent>
                            {ESTADOS.map((e) => <SelectItem key={e} value={e} className="capitalize">{e}</SelectItem>)}
                          </SelectContent>
                        </Select>
                      </td>
                      <td className="px-3 py-3">
                        <Input
                          defaultValue={r.cfdi_uuid ?? ""}
                          placeholder="Pega el UUID"
                          className="h-8 w-[210px] font-mono text-xs"
                          onBlur={(e) => { if (e.target.value.trim() !== (r.cfdi_uuid ?? "")) guardarUuid(r, e.target.value); }}
                        />
                      </td>
                      <td className="px-3 py-3">
                        <Button variant="ghost" size="sm" className="gap-1" onClick={() => copiarFiscal(r)}>
                          <Copy className="w-3.5 h-3.5" /> Copiar
                        </Button>
                      </td>
                    </tr>
                  ))}
                  {filtrados.length === 0 && (
                    <tr><td colSpan={12} className="px-4 py-10 text-center text-muted-foreground">Sin solicitudes.</td></tr>
                  )}
                </tbody>
              </table>
            </div>
          </CardContent>
        </Card>

        <p className="text-xs text-muted-foreground">
          {filtrados.length} de {rows.length} · "Copiar" pone los datos fiscales listos para pegar en Compact. Marca "Timbrada" y pega el folio fiscal cuando la emitas.
        </p>
      </main>
    </div>
  );
}

function Stat({ icon, label, value, accent }: { icon: React.ReactNode; label: string; value: number; accent?: boolean }) {
  return (
    <Card className={accent ? "border-accent/40" : ""}>
      <CardContent className="pt-6">
        <div className="flex items-center gap-2 text-muted-foreground text-sm">{icon} {label}</div>
        <div className={`mt-1 text-3xl font-bold ${accent ? "text-accent" : ""}`}>{value}</div>
      </CardContent>
    </Card>
  );
}
