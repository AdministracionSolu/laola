import { useEffect, useMemo, useState } from "react";
import { Link, useNavigate, useSearchParams } from "react-router-dom";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Checkbox } from "@/components/ui/checkbox";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Loader2, Waves, Ticket, PartyPopper, Sparkles, ChevronRight } from "lucide-react";
import { toast } from "sonner";
import { supabase } from "@/integrations/supabase/client";
import ActivarWhatsApp from "@/components/ActivarWhatsApp";
import logoLaOla from "@/assets/logo-la-ola.jpeg";
import { telefonoMx10 } from "@/lib/telefono";

// URL del aviso de privacidad (ajústala a la real cuando exista)
const AVISO_PRIVACIDAD = "/privacidad";

const MESES = [
  "Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio",
  "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre",
];

export default function Lealtad() {
  const [params] = useSearchParams();
  const navigate = useNavigate();
  const suc = (params.get("suc") ?? "").trim().toUpperCase();

  // El mismo QR sirve para dos caminos: inscribirse por primera vez o
  // registrar una visita. ?modo=registro brinca directo al formulario.
  const [modo, setModo] = useState<"elige" | "registro">(
    params.get("modo") === "registro" ? "registro" : "elige"
  );
  const [sucursalNombre, setSucursalNombre] = useState<string | null>(null);
  const [listo, setListo] = useState(false);
  const [nombreOk, setNombreOk] = useState("");
  // El teléfono ya existía: no es alta nueva y no le toca regalo otra vez.
  const [yaEstaba, setYaEstaba] = useState(false);

  const [primerNombre, setPrimerNombre] = useState("");
  const [segundoNombre, setSegundoNombre] = useState("");
  const [apellidoPaterno, setApellidoPaterno] = useState("");
  const [apellidoMaterno, setApellidoMaterno] = useState("");
  const [telefono, setTelefono] = useState("");
  const [nacDia, setNacDia] = useState("");
  const [nacMes, setNacMes] = useState("");
  const [nacAnio, setNacAnio] = useState("");
  const [acepto, setAcepto] = useState(false);
  const [enviando, setEnviando] = useState(false);

  useEffect(() => {
    if (!suc) return;
    supabase
      .from("sucursales")
      .select("nombre,prefijo_folio")
      .eq("prefijo_folio", suc)
      .maybeSingle()
      .then(({ data }) => setSucursalNombre(data?.nombre ?? null));
  }, [suc]);

  // Se acepta con lada ("+52 311..."), no sólo diez dígitos pelones: la
  // regla vive en lib/telefono.ts y es la misma que usa el backend.
  const telLimpio = useMemo(() => telefonoMx10(telefono) ?? "", [telefono]);
  const telValido = telLimpio.length === 10;

  const anioActual = new Date().getFullYear();
  const anios = useMemo(
    () => Array.from({ length: 96 }, (_, i) => anioActual - 5 - i),
    [anioActual]
  );
  const diasDelMes = useMemo(() => {
    const m = Number(nacMes), y = Number(nacAnio);
    const n = m && y ? new Date(y, m, 0).getDate() : 31;
    return Array.from({ length: n }, (_, i) => i + 1);
  }, [nacMes, nacAnio]);

  const fechaNacimiento = useMemo(() => {
    if (!nacDia || !nacMes || !nacAnio) return null;
    return `${nacAnio}-${String(nacMes).padStart(2, "0")}-${String(nacDia).padStart(2, "0")}`;
  }, [nacDia, nacMes, nacAnio]);

  const puedeRegistrar =
    primerNombre.trim().length >= 2 &&
    apellidoPaterno.trim().length >= 2 &&
    apellidoMaterno.trim().length >= 2 &&
    telValido &&
    !!fechaNacimiento &&
    acepto &&
    !enviando;

  const registrar = async () => {
    setEnviando(true);
    const { data, error } = await (supabase.rpc as any)("lealtad_registrar", {
      p_primer_nombre: primerNombre.trim(),
      p_segundo_nombre: segundoNombre.trim() || null,
      p_apellido_paterno: apellidoPaterno.trim(),
      p_apellido_materno: apellidoMaterno.trim(),
      p_telefono: telLimpio,
      p_cumpleanos: fechaNacimiento,
      p_sucursal_codigo: suc || null,
      p_consentimiento: acepto,
    });
    setEnviando(false);

    if (error) {
      const msg = error.message || "";
      if (msg.includes("TELEFONO_INVALIDO")) toast.error("Revisa tu teléfono: deben ser 10 dígitos.");
      else if (msg.includes("CUMPLE_REQUERIDO")) toast.error("Falta tu fecha de nacimiento.");
      else if (msg.includes("NOMBRE")) toast.error("Completa tu nombre y apellidos.");
      else if (msg.includes("CONSENTIMIENTO")) toast.error("Necesitas aceptar el aviso para registrarte.");
      else toast.error("No pudimos registrarte. Intenta de nuevo.");
      return;
    }

    setNombreOk((data?.nombre ?? primerNombre.trim()).split(" ")[0]);
    setYaEstaba(data?.nuevo === false);
    setListo(true);
    window.scrollTo({ top: 0 });
  };

  const Header = ({ titulo, sub }: { titulo: string; sub?: React.ReactNode }) => (
    <div className="flex flex-col items-center text-center mb-6">
      <div className="w-20 h-20 rounded-full overflow-hidden mb-3 ring-4 ring-primary/20 shadow-lg">
        <img src={logoLaOla} alt="La Ola" className="w-full h-full object-cover" />
      </div>
      <h1 className="text-3xl font-bold font-display text-primary">{titulo}</h1>
      {sub && <p className="text-muted-foreground mt-1">{sub}</p>}
      {sucursalNombre && (
        <span className="mt-3 inline-block bg-accent text-accent-foreground text-sm font-semibold px-4 py-1 rounded-md">
          {sucursalNombre}
        </span>
      )}
    </div>
  );

  // ============================================================
  // Ya estaba registrado: no es alta nueva, se le manda a su visita.
  // La Recompensa inicial es una sola vez, así que aquí no se promete.
  // ============================================================
  if (listo && yaEstaba) {
    return (
      <div className="min-h-screen bg-gradient-to-b from-primary/10 via-background to-background">
        <div className="max-w-md mx-auto px-4 py-8">
          <Header titulo={`¡Qué gusto verte, ${nombreOk}!`} sub="Ya eras parte de La Ola 🌊" />
          <div className="rounded-2xl border bg-card p-6 shadow-sm text-center space-y-4">
            <Waves className="h-12 w-12 mx-auto text-primary" />
            <p className="text-muted-foreground">
              Tu teléfono ya estaba registrado, así que no hace falta inscribirte de nuevo.
              Dejamos tus datos al día.
            </p>
            <Button
              className="w-full font-semibold"
              size="lg"
              onClick={() => navigate(`/visita${suc ? `?suc=${suc}` : ""}`)}
            >
              <Ticket className="h-4 w-4 mr-2" />
              Registrar mi visita de hoy
            </Button>
            <ActivarWhatsApp nombre={nombreOk} contexto="alta" />
            <div className="flex items-center justify-center gap-2 rounded-xl bg-primary/5 border border-primary/10 p-3 text-sm text-primary font-medium">
              <Ticket className="h-4 w-4" /> Tu visita se valida con el ticket de tu cuenta.
            </div>
            <p className="text-[11px] leading-snug text-muted-foreground/70">
              La Recompensa inicial es una sola vez. Si todavía no la canjeas, ahí te aparece.
            </p>
            <Link to="/menu" className="inline-block text-primary font-semibold pt-1">Ver el menú</Link>
          </div>
        </div>
      </div>
    );
  }

  // ============================================================
  // Confirmación
  // ============================================================
  if (listo) {
    return (
      <div className="min-h-screen bg-gradient-to-b from-primary/10 via-background to-background">
        <div className="max-w-md mx-auto px-4 py-8">
          <Header titulo={`¡Bienvenido, ${nombreOk}!`} sub="Ya eres parte de La Ola 🌊" />
          <div className="rounded-2xl border bg-card p-6 shadow-sm text-center space-y-4">
            <PartyPopper className="h-12 w-12 mx-auto text-accent" />
            <div className="rounded-xl border-2 border-accent bg-accent/10 p-3">
              <p className="font-semibold text-accent">🥂 Tu Recompensa inicial</p>
              <p className="text-sm text-accent/90 mt-0.5">
                Un balazo de tu elección + cerveza o refresco
              </p>
              {/* Se canjea en esta misma visita, no en la siguiente. */}
              <p className="text-xs text-muted-foreground mt-1.5">Canjéalo ahora con tu mesero.</p>
              <p className="text-[11px] leading-snug text-muted-foreground/70 mt-1.5">
                No incluye balazo de callo de hacha ni cerveza premium.
              </p>
            </div>
            <ActivarWhatsApp nombre={nombreOk} contexto="alta" />
            <p className="text-muted-foreground">
              La próxima vez que nos visites, vuelve a escanear este QR y entra por{" "}
              <b>"Ya soy miembro"</b> para sumar tu visita. Cada 3 visitas ganas una recompensa 🦐
            </p>
            <div className="flex items-center justify-center gap-2 rounded-xl bg-primary/5 border border-primary/10 p-3 text-sm text-primary font-medium">
              <Ticket className="h-4 w-4" /> Tu visita se valida con el ticket de tu cuenta.
            </div>
            <Link to="/menu" className="inline-block text-primary font-semibold pt-2">Ver el menú</Link>
          </div>
        </div>
      </div>
    );
  }

  // ============================================================
  // Bifurcación: ¿primera vez o registrar visita?
  // ============================================================
  if (modo === "elige") {
    return (
      <div className="min-h-screen bg-gradient-to-b from-primary/10 via-background to-background">
        <div className="max-w-md mx-auto px-4 py-8">
          <Header titulo="Programa de Lealtad" sub="Tus visitas a La Ola tienen premio 🦐" />
          <div className="space-y-4">
            <button
              onClick={() => setModo("registro")}
              className="w-full rounded-2xl border-2 border-primary/20 bg-card p-5 shadow-sm text-left flex items-center gap-4 transition-all hover:border-primary hover:shadow-md active:scale-[0.99]"
            >
              <div className="w-12 h-12 rounded-lg bg-primary/10 flex items-center justify-center shrink-0">
                <Sparkles className="h-6 w-6 text-primary" />
              </div>
              <div className="min-w-0 flex-1">
                <p className="font-bold text-lg leading-tight">Es mi primera vez</p>
                <p className="text-sm text-muted-foreground mt-0.5">
                  Únete al programa y llévate tu Recompensa inicial.
                </p>
              </div>
              <ChevronRight className="h-5 w-5 text-muted-foreground shrink-0" />
            </button>

            <button
              onClick={() => navigate(`/visita${suc ? `?suc=${suc}` : ""}`)}
              className="w-full rounded-2xl border-2 border-accent/30 bg-card p-5 shadow-sm text-left flex items-center gap-4 transition-all hover:border-accent hover:shadow-md active:scale-[0.99]"
            >
              <div className="w-12 h-12 rounded-lg bg-accent/10 flex items-center justify-center shrink-0">
                <Ticket className="h-6 w-6 text-accent" />
              </div>
              <div className="min-w-0 flex-1">
                <p className="font-bold text-lg leading-tight">Ya soy miembro</p>
                <p className="text-sm text-muted-foreground mt-0.5">
                  Registra tu visita de hoy con el folio de tu ticket.
                </p>
              </div>
              <ChevronRight className="h-5 w-5 text-muted-foreground shrink-0" />
            </button>
          </div>
          <p className="text-center text-xs text-muted-foreground mt-6 flex items-center justify-center gap-1.5">
            <Waves className="h-3.5 w-3.5" /> Cada 3 visitas ganas una recompensa.
          </p>
        </div>
      </div>
    );
  }

  // ============================================================
  // Formulario de inscripción
  // ============================================================
  return (
    <div className="min-h-screen bg-gradient-to-b from-primary/10 via-background to-background">
      <div className="max-w-md mx-auto px-4 py-8">
        <Header titulo="Únete a La Ola" sub={<>Regístrate y recibe premios por tus visitas 🦐</>} />
        <div className="rounded-2xl border bg-card p-5 shadow-sm space-y-4">
          <div className="grid grid-cols-2 gap-3">
            <div className="space-y-1.5">
              <Label htmlFor="pn">Primer nombre</Label>
              <Input id="pn" value={primerNombre} onChange={(e) => setPrimerNombre(e.target.value)}
                placeholder="Juan" className="h-12 text-base" autoComplete="given-name" />
            </div>
            <div className="space-y-1.5">
              <Label htmlFor="sn">Segundo nombre <span className="text-muted-foreground font-normal">(opcional)</span></Label>
              <Input id="sn" value={segundoNombre} onChange={(e) => setSegundoNombre(e.target.value)}
                placeholder="Carlos" className="h-12 text-base" autoComplete="additional-name" />
            </div>
            <div className="space-y-1.5">
              <Label htmlFor="ap">Apellido paterno</Label>
              <Input id="ap" value={apellidoPaterno} onChange={(e) => setApellidoPaterno(e.target.value)}
                placeholder="Pérez" className="h-12 text-base" />
            </div>
            <div className="space-y-1.5">
              <Label htmlFor="am">Apellido materno</Label>
              <Input id="am" value={apellidoMaterno} onChange={(e) => setApellidoMaterno(e.target.value)}
                placeholder="López" className="h-12 text-base" />
            </div>
          </div>

          <div className="space-y-1.5">
            <Label htmlFor="tel">Tu WhatsApp (10 dígitos)</Label>
            <Input id="tel" value={telefono} onChange={(e) => setTelefono(e.target.value)}
              placeholder="311 123 4567" className="h-12 text-base" inputMode="numeric" autoComplete="tel" />
            {telefono.length > 0 && !telValido && (
              <p className="text-xs text-destructive">Deben ser 10 dígitos.</p>
            )}
          </div>

          <div className="space-y-1.5">
            <Label>Fecha de nacimiento</Label>
            <div className="grid grid-cols-3 gap-2">
              <Select value={nacDia} onValueChange={setNacDia}>
                <SelectTrigger className="h-12"><SelectValue placeholder="Día" /></SelectTrigger>
                <SelectContent className="max-h-60">
                  {diasDelMes.map((d) => <SelectItem key={d} value={String(d)}>{d}</SelectItem>)}
                </SelectContent>
              </Select>
              <Select value={nacMes} onValueChange={setNacMes}>
                <SelectTrigger className="h-12"><SelectValue placeholder="Mes" /></SelectTrigger>
                <SelectContent className="max-h-60">
                  {MESES.map((m, i) => <SelectItem key={m} value={String(i + 1)}>{m}</SelectItem>)}
                </SelectContent>
              </Select>
              <Select value={nacAnio} onValueChange={setNacAnio}>
                <SelectTrigger className="h-12"><SelectValue placeholder="Año" /></SelectTrigger>
                <SelectContent className="max-h-60">
                  {anios.map((a) => <SelectItem key={a} value={String(a)}>{a}</SelectItem>)}
                </SelectContent>
              </Select>
            </div>
          </div>

          <label className="flex items-start gap-3 pt-1 cursor-pointer">
            <Checkbox checked={acepto} onCheckedChange={(v) => setAcepto(v === true)} className="mt-0.5" />
            <span className="text-sm text-muted-foreground leading-snug">
              Acepto recibir promociones de La Ola y el{" "}
              <a href={AVISO_PRIVACIDAD} target="_blank" rel="noreferrer" className="text-primary underline">aviso de privacidad</a>.
              Puedo darme de baja cuando quiera.
            </span>
          </label>

          <Button className="w-full h-12 text-base font-semibold" disabled={!puedeRegistrar} onClick={registrar}>
            {enviando ? <Loader2 className="h-5 w-5 animate-spin" /> : "Unirme a La Ola"}
          </Button>
        </div>
        <p className="text-center text-xs text-muted-foreground mt-4 flex items-center justify-center gap-1.5">
          <Waves className="h-3.5 w-3.5" /> Un teléfono, un perfil. Te reconocemos en cualquiera de nuestras sucursales.
        </p>
      </div>
    </div>
  );
}
