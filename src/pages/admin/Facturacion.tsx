import { useEffect, useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card, CardContent } from "@/components/ui/card";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Badge } from "@/components/ui/badge";
import { toast } from "sonner";
import { ArrowLeft, LogOut, RefreshCw, Search, Copy, Download, Clock, CheckCircle2, FileText, Store, Image as ImageIcon } from "lucide-react";
import logoLaOla from "@/assets/logo-la-ola.jpeg";

type Solicitud = {
  id: string;
  folio_solicitud: string;
  sucursal_id: string | null;
  sucursal_codigo: string | null;
  rfc: string;
  razon_social: string;
  regimen_fiscal: string;
  codigo_postal: string;
  uso_cfdi: string;
  email: string;
  telefono: string | null;
  forma_pago: string | null;
  ticket_folio: string | null;
  ticket_total: number | null;
  ticket_fecha: string | null;
  ticket_foto_path: string | null;
  estado: "pendiente" | "timbrada" | "rechazada";
  created_at: string;
};
type Sucursal = { id: string; nombre: string; prefijo_folio: string | null };

const db = supabase as any;

export default function AdminFacturacion() {
  const navigate = useNavigate();
  const [cargando, setCargando] = useState(true);
  const [rows, setRows] = useState<Solicitud[]>([]);
  const [sucursales, setSucursales] = useState<Sucursal[]>([]);
  const [busqueda, setBusqueda] = useState("");
  const [fEstado, setFEstado] = useState("pendiente");
  const [fSuc, setFSuc] = useState("todas");
  const [esAdmin, setEsAdmin] = useState(false);

  useEffect(() => {
    (async () => {
      const { data: { session } } = await supabase.auth.getSession();
      if (!session) { navigate("/admin/login"); return; }
      const { data: rolAdmin } = await supabase.rpc("has_role", {
        _user_id: session.user.id,
        _role: "admin",
      });
      setEsAdmin(!!rolAdmin);
      await cargar();
    })();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const cargar = async () => {
    setCargando(true);
    const [sol, suc] = await Promise.all([
      db.from("factura_solicitudes").select("*").order("created_at", { ascending: false }),
      db.from("sucursales").select("id,nombre,prefijo_folio").order("nombre"),
    ]);
    if (sol.error) toast.error("No pudimos cargar las solicitudes.");
    setRows((sol.data ?? []) as Solicitud[]);
    setSucursales((suc.data ?? []) as Sucursal[]);
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
      if (fSuc !== "todas" && r.sucursal_id !== fSuc) return false;
      if (!q) return true;
      return r.rfc.toLowerCase().includes(q) || r.razon_social.toLowerCase().includes(q) || r.folio_solicitud.toLowerCase().includes(q);
    });
  }, [rows, busqueda, fEstado, fSuc]);

  // Agrupa por día (fecha de la solicitud)
  const porDia = useMemo(() => {
    const map = new Map<string, Solicitud[]>();
    for (const r of filtrados) {
      const d = r.created_at.slice(0, 10);
      if (!map.has(d)) map.set(d, []);
      map.get(d)!.push(r);
    }
    return [...map.entries()];
  }, [filtrados]);

  const nombreSuc = (r: Solicitud) =>
    sucursales.find((s) => s.id === r.sucursal_id)?.nombre ?? r.sucursal_codigo ?? "—";

  const setEstado = async (r: Solicitud, estado: Solicitud["estado"]) => {
    const { error } = await db.from("factura_solicitudes").update({ estado }).eq("id", r.id);
    if (error) return toast.error("No se pudo actualizar.");
    setRows((p) => p.map((x) => (x.id === r.id ? { ...x, estado } : x)));
  };

  const verTicket = async (r: Solicitud) => {
    if (!r.ticket_foto_path) return toast.error("Esta solicitud no tiene foto.");
    const { data, error } = await supabase.storage
      .from("factura-tickets")
      .createSignedUrl(r.ticket_foto_path, 3600);
    if (error || !data?.signedUrl) return toast.error("No pudimos abrir la foto.");
    window.open(data.signedUrl, "_blank", "noopener");
  };

  const copiar = (r: Solicitud) => {
    const t = [
      `RFC: ${r.rfc}`,
      `Razón social: ${r.razon_social}`,
      `Régimen fiscal: ${r.regimen_fiscal}`,
      `C.P.: ${r.codigo_postal}`,
      `Uso CFDI: ${r.uso_cfdi}`,
      `Forma de pago: ${r.forma_pago ?? ""}`,
      `Correo: ${r.email}`,
      `Teléfono: ${r.telefono ?? ""}`,
      `Ticket: ${r.ticket_folio ?? ""}`,
      r.ticket_total != null ? `Total: $${r.ticket_total}` : "",
      r.ticket_fecha ? `Fecha: ${r.ticket_fecha}` : "",
    ].filter(Boolean).join("\n");
    navigator.clipboard.writeText(t);
    toast.success("Datos copiados. Pégalos en Compact.");
  };

  const exportarCSV = () => {
    const filas = [
      ["folio", "fecha_solicitud", "sucursal", "rfc", "razon_social", "regimen", "cp", "uso_cfdi", "forma_pago", "correo", "telefono", "ticket", "total", "fecha_consumo", "estado"],
      ...filtrados.map((r) => [
        r.folio_solicitud, r.created_at.slice(0, 10), nombreSuc(r), r.rfc, r.razon_social, r.regimen_fiscal,
        r.codigo_postal, r.uso_cfdi, r.forma_pago ?? "", r.email, r.telefono ?? "", r.ticket_folio ?? "",
        r.ticket_total ?? "", r.ticket_fecha ?? "", r.estado,
      ]),
    ];
    const csv = filas.map((f) => f.map((v) => `"${String(v).replace(/"/g, '""')}"`).join(",")).join("\n");
    const url = URL.createObjectURL(new Blob([csv], { type: "text/csv;charset=utf-8" }));
    const a = document.createElement("a");
    a.href = url; a.download = `facturas-la-ola-${new Date().toISOString().slice(0, 10)}.csv`; a.click();
    URL.revokeObjectURL(url);
  };

  const fmtDia = (iso: string) =>
    new Date(iso + "T12:00:00").toLocaleDateString("es-MX", { weekday: "long", day: "2-digit", month: "long" });

  if (cargando) {
    return <div className="min-h-screen flex items-center justify-center"><div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary" /></div>;
  }

  return (
    <div className="min-h-screen bg-background">
      <header className="bg-card border-b sticky top-0 z-50">
        <div className="container mx-auto px-4 py-4 flex items-center justify-between gap-2">
          <div className="flex items-center gap-3 min-w-0">
            {esAdmin && (
              <Button variant="ghost" size="icon" onClick={() => navigate("/admin/dashboard")}><ArrowLeft className="w-5 h-5" /></Button>
            )}
            <img src={logoLaOla} alt="La Ola" className="w-10 h-10 rounded-full object-cover shrink-0" />
            <h1 className="text-xl font-bold truncate">Facturación</h1>
          </div>
          <div className="flex items-center gap-2">
            <Button variant="outline" onClick={exportarCSV} className="gap-2"><Download className="w-4 h-4" /><span className="hidden sm:inline">CSV</span></Button>
            <Button variant="outline" size="icon" onClick={cargar}><RefreshCw className="w-4 h-4" /></Button>
            <Button variant="outline" onClick={async () => { await supabase.auth.signOut(); navigate("/admin/login"); }}><LogOut className="w-4 h-4 sm:mr-2" /><span className="hidden sm:inline">Salir</span></Button>
          </div>
        </div>
      </header>

      <main className="container mx-auto px-4 py-6 space-y-5">
        <div className="grid grid-cols-3 gap-3">
          <Stat icon={<Clock className="w-4 h-4" />} label="Pendientes" value={stats.pendientes} accent />
          <Stat icon={<CheckCircle2 className="w-4 h-4" />} label="Timbradas hoy" value={stats.timbradasHoy} />
          <Stat icon={<FileText className="w-4 h-4" />} label="Solicitudes hoy" value={stats.hoy} />
        </div>

        <div className="flex flex-col sm:flex-row gap-3">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
            <Input value={busqueda} onChange={(e) => setBusqueda(e.target.value)} placeholder="Buscar por RFC, razón social o folio" className="pl-9 h-11" />
          </div>
          <Select value={fSuc} onValueChange={setFSuc}>
            <SelectTrigger className="sm:max-w-[190px] h-11"><span className="flex items-center gap-2"><Store className="w-4 h-4" /><SelectValue /></span></SelectTrigger>
            <SelectContent>
              <SelectItem value="todas">Todas las sucursales</SelectItem>
              {sucursales.map((s) => <SelectItem key={s.id} value={s.id}>{s.nombre}</SelectItem>)}
            </SelectContent>
          </Select>
          <Select value={fEstado} onValueChange={setFEstado}>
            <SelectTrigger className="sm:max-w-[160px] h-11"><SelectValue /></SelectTrigger>
            <SelectContent>
              <SelectItem value="pendiente">Pendientes</SelectItem>
              <SelectItem value="timbrada">Timbradas</SelectItem>
              <SelectItem value="rechazada">Rechazadas</SelectItem>
              <SelectItem value="todas">Todas</SelectItem>
            </SelectContent>
          </Select>
        </div>

        {porDia.length === 0 && (
          <p className="text-center text-muted-foreground py-16">Sin solicitudes que coincidan.</p>
        )}

        {porDia.map(([dia, items]) => (
          <section key={dia} className="space-y-3">
            <div className="flex items-center gap-3 pt-2">
              <h2 className="text-sm font-semibold capitalize text-muted-foreground">{fmtDia(dia)}</h2>
              <span className="text-xs text-muted-foreground">· {items.length}</span>
              <div className="flex-1 border-t" />
            </div>
            <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-3">
              {items.map((r) => (
                <FacturaCard key={r.id} r={r} sucursal={nombreSuc(r)} onEstado={setEstado} onCopiar={copiar} onVerTicket={verTicket} />
              ))}
            </div>
          </section>
        ))}
      </main>
    </div>
  );
}

function FacturaCard({
  r, sucursal, onEstado, onCopiar, onVerTicket,
}: {
  r: Solicitud; sucursal: string;
  onEstado: (r: Solicitud, e: Solicitud["estado"]) => void;
  onCopiar: (r: Solicitud) => void;
  onVerTicket: (r: Solicitud) => void;
}) {
  const Dato = ({ k, v }: { k: string; v: string }) => (
    <div className="flex justify-between gap-3 py-0.5">
      <span className="text-muted-foreground shrink-0">{k}</span>
      <span className="font-medium text-right break-all">{v}</span>
    </div>
  );
  return (
    <Card className={r.estado === "timbrada" ? "opacity-70" : ""}>
      <CardContent className="p-4 space-y-3">
        <div className="flex items-center justify-between gap-2">
          <div className="min-w-0">
            <p className="font-mono text-xs text-muted-foreground">{r.folio_solicitud}</p>
            <p className="font-semibold truncate" title={r.razon_social}>{r.razon_social}</p>
          </div>
          <Badge variant="secondary" className="shrink-0">{sucursal}</Badge>
        </div>

        <div className="text-sm border-y py-2">
          <Dato k="RFC" v={r.rfc} />
          <Dato k="Régimen" v={r.regimen_fiscal} />
          <Dato k="C.P." v={r.codigo_postal} />
          <Dato k="Uso CFDI" v={r.uso_cfdi} />
          <Dato k="Forma pago" v={r.forma_pago ?? "—"} />
          <Dato k="Ticket" v={`${r.ticket_folio ?? "—"}${r.ticket_total != null ? ` · $${r.ticket_total}` : ""}`} />
          <Dato k="Consumo" v={r.ticket_fecha ?? "—"} />
          <Dato k="Correo" v={r.email} />
          <Dato k="Teléfono" v={r.telefono ?? "—"} />
        </div>

        <div className="flex items-center gap-2">
          <Select value={r.estado} onValueChange={(v) => onEstado(r, v as Solicitud["estado"])}>
            <SelectTrigger className="h-9 flex-1">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="pendiente">Pendiente</SelectItem>
              <SelectItem value="timbrada">Timbrada</SelectItem>
              <SelectItem value="rechazada">Rechazada</SelectItem>
            </SelectContent>
          </Select>
          <Button
            variant="outline" size="sm" className="gap-1 h-9"
            onClick={() => onVerTicket(r)} disabled={!r.ticket_foto_path}
            title={r.ticket_foto_path ? "Ver foto del ticket" : "Sin foto"}
          >
            <ImageIcon className="w-3.5 h-3.5" /> Ticket
          </Button>
          <Button variant="outline" size="sm" className="gap-1 h-9" onClick={() => onCopiar(r)}>
            <Copy className="w-3.5 h-3.5" /> Copiar
          </Button>
        </div>
      </CardContent>
    </Card>
  );
}

function Stat({ icon, label, value, accent }: { icon: React.ReactNode; label: string; value: number; accent?: boolean }) {
  return (
    <Card className={accent ? "border-accent/40" : ""}>
      <CardContent className="pt-5 pb-4">
        <div className="flex items-center gap-2 text-muted-foreground text-xs sm:text-sm">{icon} {label}</div>
        <div className={`mt-1 text-2xl sm:text-3xl font-bold ${accent ? "text-accent" : ""}`}>{value}</div>
      </CardContent>
    </Card>
  );
}
