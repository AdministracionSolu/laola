import { useEffect, useMemo, useState } from "react";
import { Link, useSearchParams } from "react-router-dom";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Loader2, CheckCircle2, FileText, Camera, X } from "lucide-react";
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

const FORMAS_PAGO = ["Efectivo", "Tarjeta de débito", "Tarjeta de crédito", "Transferencia"];

const RFC_RE = /^[A-ZÑ&]{3,4}\d{6}[A-Z0-9]{3}$/;

// Fecha de hoy en horario local (YYYY-MM-DD), para pre-llenar el campo.
const hoyLocal = () => new Date().toLocaleDateString("en-CA");

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
  const [telefono, setTelefono] = useState("");
  const [formaPago, setFormaPago] = useState("");
  const [ticket, setTicket] = useState("");
  const [total, setTotal] = useState("");
  const [fecha, setFecha] = useState(hoyLocal);
  const [foto, setFoto] = useState<File | null>(null);
  const [fotoPreview, setFotoPreview] = useState<string | null>(null);
  const [enviando, setEnviando] = useState(false);
  const [folio, setFolio] = useState<string | null>(null);

  useEffect(() => {
    if (!foto) { setFotoPreview(null); return; }
    const url = URL.createObjectURL(foto);
    setFotoPreview(url);
    return () => URL.revokeObjectURL(url);
  }, [foto]);

  const elegirFoto = (f: File | null) => {
    if (!f) return;
    if (!f.type.startsWith("image/")) { toast.error("Sube una imagen del ticket."); return; }
    if (f.size > 10 * 1024 * 1024) { toast.error("La foto pesa más de 10 MB. Toma otra."); return; }
    setFoto(f);
  };

  useEffect(() => {
    if (!suc) return;
    supabase.from("sucursales").select("nombre,prefijo_folio").eq("prefijo_folio", suc).maybeSingle()
      .then(({ data }) => setSucursalNombre(data?.nombre ?? null));
  }, [suc]);

  const rfcUpper = useMemo(() => rfc.toUpperCase().replace(/\s/g, ""), [rfc]);
  const telLimpio = useMemo(() => telefono.replace(/\D/g, ""), [telefono]);
  const rfcOk = RFC_RE.test(rfcUpper);
  const cpOk = /^\d{5}$/.test(cp);
  const emailOk = /^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email.trim());
  const telOk = telLimpio.length === 10;
  const consumoOk = ticket.trim().length > 0 && Number(total) > 0 && !!fecha && !!foto;
  const puedeEnviar =
    rfcOk && razon.trim().length >= 3 && regimen && cpOk && uso && emailOk &&
    telOk && formaPago && consumoOk && !enviando;

  const solicitar = async () => {
    if (!puedeEnviar || !foto) return;
    setEnviando(true);

    // 1) Sube la foto del ticket al bucket privado.
    const ext = (foto.name.split(".").pop() || "jpg").toLowerCase().replace(/[^a-z0-9]/g, "") || "jpg";
    const path = `${suc || "GEN"}/${crypto.randomUUID()}.${ext}`;
    const up = await supabase.storage.from("factura-tickets").upload(path, foto, {
      contentType: foto.type || "image/jpeg",
      upsert: false,
    });
    if (up.error) {
      setEnviando(false);
      toast.error("No pudimos subir la foto del ticket. Intenta de nuevo.");
      return;
    }

    // 2) Registra la solicitud con la ruta de la foto.
    const { data, error } = await (supabase.rpc as any)("factura_solicitar", {
      p_rfc: rfcUpper,
      p_razon_social: razon.trim(),
      p_regimen_fiscal: regimen,
      p_codigo_postal: cp,
      p_uso_cfdi: uso,
      p_email: email.trim().toLowerCase(),
      p_telefono: telLimpio,
      p_forma_pago: formaPago,
      p_ticket_foto_path: path,
      p_sucursal_codigo: suc || null,
      p_ticket_folio: ticket.trim(),
      p_ticket_total: Number(total),
      p_ticket_fecha: fecha,
    });
    setEnviando(false);
    if (error) {
      const m = error.message || "";
      if (m.includes("RFC_INVALIDO")) toast.error("Revisa tu RFC.");
      else if (m.includes("CP_INVALIDO")) toast.error("El código postal debe tener 5 dígitos.");
      else if (m.includes("EMAIL_INVALIDO")) toast.error("Revisa tu correo.");
      else if (m.includes("TELEFONO_INVALIDO")) toast.error("El teléfono debe tener 10 dígitos.");
      else if (m.includes("FOTO_REQUERIDA")) toast.error("Falta la foto de tu ticket.");
      else if (m.includes("TICKET") || m.includes("TOTAL") || m.includes("FECHA")) toast.error("Faltan datos de tu consumo (ticket, total y fecha).");
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

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <div className="space-y-1.5">
              <Label htmlFor="email">Correo</Label>
              <Input id="email" type="email" value={email} onChange={(e) => setEmail(e.target.value)}
                placeholder="tu@correo.com" className="h-12 text-base" autoComplete="email" />
            </div>
            <div className="space-y-1.5">
              <Label htmlFor="tel">Teléfono (10 dígitos)</Label>
              <Input id="tel" value={telefono} onChange={(e) => setTelefono(e.target.value)}
                placeholder="311 123 4567" inputMode="numeric" autoComplete="tel" className="h-12 text-base" />
              {telefono.length > 0 && !telOk && <p className="text-xs text-destructive">Deben ser 10 dígitos.</p>}
            </div>
          </div>

          <div className="space-y-1.5">
            <Label>Forma de pago</Label>
            <div className="grid grid-cols-2 gap-2">
              {FORMAS_PAGO.map((f) => (
                <button
                  key={f}
                  type="button"
                  onClick={() => setFormaPago(f)}
                  className={`h-12 rounded-xl border text-sm font-semibold transition-all active:scale-[0.98] ${
                    formaPago === f
                      ? "bg-primary text-primary-foreground border-primary shadow"
                      : "bg-card text-foreground/80 hover:border-primary/60"
                  }`}
                >
                  {f}
                </button>
              ))}
            </div>
          </div>

          <div className="pt-2 border-t">
            <p className="text-sm font-semibold mb-2">Tu consumo</p>
            <div className="grid grid-cols-2 gap-3">
              <div className="space-y-1.5">
                <Label htmlFor="ticket" className="text-xs">Número de ticket</Label>
                <Input id="ticket" value={ticket} onChange={(e) => setTicket(e.target.value)} placeholder="Ej. 0154" className="h-12 text-base" />
              </div>
              <div className="space-y-1.5">
                <Label htmlFor="total" className="text-xs">Total $</Label>
                <Input id="total" value={total} onChange={(e) => setTotal(e.target.value.replace(/[^\d.]/g, ""))} placeholder="0.00" inputMode="decimal" className="h-12 text-base" />
              </div>
            </div>
            <div className="space-y-1.5 mt-3">
              <Label htmlFor="fecha" className="text-xs">Fecha de tu visita</Label>
              <Input id="fecha" type="date" value={fecha} onChange={(e) => setFecha(e.target.value)} className="h-12 text-base" />
              <p className="text-[11px] text-muted-foreground">Ya pusimos la fecha de hoy. Cámbiala solo si tu consumo fue otro día.</p>
            </div>

            <div className="space-y-1.5 mt-3">
              <Label className="text-xs">Foto de tu ticket</Label>
              {fotoPreview ? (
                <div className="relative rounded-xl border overflow-hidden">
                  <img src={fotoPreview} alt="Ticket" className="w-full max-h-64 object-contain bg-muted" />
                  <button
                    type="button"
                    onClick={() => setFoto(null)}
                    className="absolute top-2 right-2 inline-flex items-center justify-center w-8 h-8 rounded-full bg-background/90 border shadow text-foreground/80 active:scale-95"
                    aria-label="Quitar foto"
                  >
                    <X className="h-4 w-4" />
                  </button>
                </div>
              ) : (
                <label
                  htmlFor="foto-ticket"
                  className="flex flex-col items-center justify-center gap-1.5 h-28 rounded-xl border-2 border-dashed cursor-pointer text-muted-foreground hover:border-primary/60 hover:text-primary transition-colors active:scale-[0.99]"
                >
                  <Camera className="h-6 w-6" />
                  <span className="text-sm font-semibold">Tomar o subir foto</span>
                </label>
              )}
              <input
                id="foto-ticket"
                type="file"
                accept="image/*"
                capture="environment"
                className="sr-only"
                onChange={(e) => { elegirFoto(e.target.files?.[0] ?? null); e.target.value = ""; }}
              />
              <p className="text-[11px] text-muted-foreground">Una foto clara del ticket, donde se lea el total. Nos ayuda a validar tu consumo.</p>
            </div>
          </div>

          <Button className="w-full h-12 text-base font-semibold" disabled={!puedeEnviar} onClick={solicitar}>
            {enviando ? <Loader2 className="h-5 w-5 animate-spin" /> : "Solicitar mi factura"}
          </Button>
        </div>

        <p className="text-center text-xs text-muted-foreground mt-4">
          Solicita tu factura el mismo mes de tu consumo. Cualquier duda, con tu mesero.
        </p>
      </div>
    </div>
  );
}
