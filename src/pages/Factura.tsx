import { useEffect, useMemo, useState } from "react";
import { Link, useSearchParams } from "react-router-dom";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Loader2, CheckCircle2, FileText } from "lucide-react";
import { toast } from "sonner";
import { supabase } from "@/integrations/supabase/client";
import logoLaOla from "@/assets/logo-la-ola.jpeg";

// Catálogos SAT (subconjunto usual para consumo en restaurante)
const REGIMENES = [
  { v: "605", l: "605 · Sueldos y salarios" },
  { v: "612", l: "612 · Personas físicas con actividad empresarial y profesional" },
  { v: "626", l: "626 · Régimen Simplificado de Confianza (RESICO)" },
  { v: "601", l: "601 · General de Ley Personas Morales" },
  { v: "603", l: "603 · Personas Morales con Fines no Lucrativos" },
  { v: "616", l: "616 · Sin obligaciones fiscales" },
];
const USOS = [
  { v: "G03", l: "G03 · Gastos en general" },
  { v: "G01", l: "G01 · Adquisición de mercancías" },
  { v: "S01", l: "S01 · Sin efectos fiscales" },
  { v: "D10", l: "D10 · Pagos por servicios educativos" },
  { v: "CP01", l: "CP01 · Pagos" },
];

const RFC_RE = /^[A-ZÑ&]{3,4}\d{6}[A-Z0-9]{3}$/;

export default function Factura() {
  const [params] = useSearchParams();
  const suc = (params.get("suc") ?? "").trim().toUpperCase();

  const [sucursalNombre, setSucursalNombre] = useState<string | null>(null);
  const [rfc, setRfc] = useState("");
  const [razon, setRazon] = useState("");
  const [regimen, setRegimen] = useState("");
  const [cp, setCp] = useState("");
  const [uso, setUso] = useState("G03");
  const [email, setEmail] = useState("");
  const [ticket, setTicket] = useState("");
  const [total, setTotal] = useState("");
  const [fecha, setFecha] = useState("");
  const [enviando, setEnviando] = useState(false);
  const [folio, setFolio] = useState<string | null>(null);

  useEffect(() => {
    if (!suc) return;
    supabase.from("sucursales").select("nombre,prefijo_folio").eq("prefijo_folio", suc).maybeSingle()
      .then(({ data }) => setSucursalNombre(data?.nombre ?? null));
  }, [suc]);

  const rfcUpper = useMemo(() => rfc.toUpperCase().replace(/\s/g, ""), [rfc]);
  const rfcOk = RFC_RE.test(rfcUpper);
  const cpOk = /^\d{5}$/.test(cp);
  const emailOk = /^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email.trim());
  const puedeEnviar = rfcOk && razon.trim().length >= 3 && regimen && cpOk && uso && emailOk && !enviando;

  const solicitar = async () => {
    if (!puedeEnviar) return;
    setEnviando(true);
    const { data, error } = await (supabase.rpc as any)("factura_solicitar", {
      p_rfc: rfcUpper,
      p_razon_social: razon.trim(),
      p_regimen_fiscal: regimen,
      p_codigo_postal: cp,
      p_uso_cfdi: uso,
      p_email: email.trim().toLowerCase(),
      p_sucursal_codigo: suc || null,
      p_ticket_folio: ticket.trim() || null,
      p_ticket_total: total ? Number(total) : null,
      p_ticket_fecha: fecha || null,
    });
    setEnviando(false);
    if (error) {
      const m = error.message || "";
      if (m.includes("RFC_INVALIDO")) toast.error("Revisa tu RFC.");
      else if (m.includes("CP_INVALIDO")) toast.error("El código postal debe tener 5 dígitos.");
      else if (m.includes("EMAIL_INVALIDO")) toast.error("Revisa tu correo.");
      else toast.error("No pudimos registrar tu solicitud. Intenta de nuevo.");
      return;
    }
    setFolio((data as any)?.folio ?? "—");
    window.scrollTo({ top: 0 });
  };

  if (folio) {
    return (
      <div className="min-h-screen bg-gradient-to-b from-primary/10 via-background to-background flex items-center justify-center p-4">
        <div className="max-w-md w-full text-center">
          <div className="w-20 h-20 rounded-full overflow-hidden mx-auto mb-4 ring-4 ring-primary/20 shadow-lg">
            <img src={logoLaOla} alt="La Ola" className="w-full h-full object-cover" />
          </div>
          <div className="inline-flex items-center justify-center w-16 h-16 rounded-full bg-primary/10 text-primary mb-4">
            <CheckCircle2 className="h-8 w-8" />
          </div>
          <h1 className="text-3xl font-bold font-display text-primary">Solicitud recibida</h1>
          <p className="text-muted-foreground mt-2">
            Tu factura se está procesando. Te la enviaremos a <b>{email.trim().toLowerCase()}</b> en cuanto se timbre.
          </p>
          <div className="mt-6 rounded-2xl border bg-card p-5 shadow-sm">
            <p className="text-sm text-muted-foreground">Folio de seguimiento</p>
            <p className="text-2xl font-bold tracking-wide text-primary mt-1">{folio}</p>
          </div>
          <Link to="/" className="inline-block mt-6 text-primary font-semibold">Volver al inicio</Link>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-b from-primary/10 via-background to-background">
      <div className="max-w-md mx-auto px-4 py-8">
        <div className="flex flex-col items-center text-center mb-6">
          <div className="w-20 h-20 rounded-full overflow-hidden mb-3 ring-4 ring-primary/20 shadow-lg">
            <img src={logoLaOla} alt="La Ola" className="w-full h-full object-cover" />
          </div>
          <h1 className="text-3xl font-bold font-display text-primary flex items-center gap-2">
            <FileText className="h-7 w-7" /> Tu factura
          </h1>
          <p className="text-muted-foreground mt-1">Captura tus datos fiscales y te la enviamos por correo.</p>
          {sucursalNombre && (
            <span className="mt-3 inline-block bg-accent text-accent-foreground text-sm font-semibold px-4 py-1 rounded-full">
              {sucursalNombre}
            </span>
          )}
        </div>

        <div className="rounded-2xl border bg-card p-5 shadow-sm space-y-4">
          <div className="space-y-1.5">
            <Label htmlFor="rfc">RFC</Label>
            <Input id="rfc" value={rfc} onChange={(e) => setRfc(e.target.value)}
              placeholder="XAXX010101000" className="h-12 text-base uppercase" autoCapitalize="characters" />
            {rfc.length > 0 && !rfcOk && <p className="text-xs text-destructive">RFC no válido.</p>}
          </div>

          <div className="space-y-1.5">
            <Label htmlFor="razon">Razón social / Nombre</Label>
            <Input id="razon" value={razon} onChange={(e) => setRazon(e.target.value)}
              placeholder="Tal cual tu constancia SAT" className="h-12 text-base" />
            <p className="text-[11px] text-muted-foreground">Debe coincidir exacto con tu constancia de situación fiscal.</p>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div className="space-y-1.5">
              <Label>Régimen fiscal</Label>
              <Select value={regimen} onValueChange={setRegimen}>
                <SelectTrigger className="h-12"><SelectValue placeholder="Elige" /></SelectTrigger>
                <SelectContent>
                  {REGIMENES.map((r) => <SelectItem key={r.v} value={r.v}>{r.l}</SelectItem>)}
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-1.5">
              <Label htmlFor="cp">C.P. fiscal</Label>
              <Input id="cp" value={cp} onChange={(e) => setCp(e.target.value.replace(/\D/g, ""))}
                placeholder="00000" inputMode="numeric" maxLength={5} className="h-12 text-base" />
            </div>
          </div>

          <div className="space-y-1.5">
            <Label>Uso de CFDI</Label>
            <Select value={uso} onValueChange={setUso}>
              <SelectTrigger className="h-12"><SelectValue /></SelectTrigger>
              <SelectContent>
                {USOS.map((u) => <SelectItem key={u.v} value={u.v}>{u.l}</SelectItem>)}
              </SelectContent>
            </Select>
          </div>

          <div className="space-y-1.5">
            <Label htmlFor="email">Correo (para enviarte la factura)</Label>
            <Input id="email" type="email" value={email} onChange={(e) => setEmail(e.target.value)}
              placeholder="tu@correo.com" className="h-12 text-base" autoComplete="email" />
          </div>

          <div className="pt-2 border-t">
            <p className="text-xs font-semibold text-muted-foreground mb-2">Tu consumo (opcional, agiliza el proceso)</p>
            <div className="grid grid-cols-3 gap-3">
              <div className="space-y-1.5 col-span-1">
                <Label htmlFor="ticket" className="text-xs">Ticket</Label>
                <Input id="ticket" value={ticket} onChange={(e) => setTicket(e.target.value)} placeholder="Folio" className="h-11" />
              </div>
              <div className="space-y-1.5 col-span-1">
                <Label htmlFor="total" className="text-xs">Total $</Label>
                <Input id="total" value={total} onChange={(e) => setTotal(e.target.value.replace(/[^\d.]/g, ""))} placeholder="0.00" inputMode="decimal" className="h-11" />
              </div>
              <div className="space-y-1.5 col-span-1">
                <Label htmlFor="fecha" className="text-xs">Fecha</Label>
                <Input id="fecha" type="date" value={fecha} onChange={(e) => setFecha(e.target.value)} className="h-11" />
              </div>
            </div>
          </div>

          <Button className="w-full h-12 text-base font-semibold" disabled={!puedeEnviar} onClick={solicitar}>
            {enviando ? <Loader2 className="h-5 w-5 animate-spin" /> : "Solicitar mi factura"}
          </Button>
        </div>

        <p className="text-center text-xs text-muted-foreground mt-4">
          Solicita tu factura el mismo día de tu consumo. Cualquier duda, con tu mesero.
        </p>
      </div>
    </div>
  );
}
