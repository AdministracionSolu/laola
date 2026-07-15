import { useEffect, useMemo, useState } from "react";
import { Link, useSearchParams } from "react-router-dom";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Checkbox } from "@/components/ui/checkbox";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Loader2, Gift, Waves, Trophy, Check, Ticket } from "lucide-react";
import { toast } from "sonner";
import { supabase } from "@/integrations/supabase/client";
import logoLaOla from "@/assets/logo-la-ola.jpeg";

// URL del aviso de privacidad (ajústala a la real cuando exista)
const AVISO_PRIVACIDAD = "/privacidad";

type Perfil = {
  status: string;
  nombre: string;
  primer_nombre?: string;
  visitas_total: number;
  nivel: string;
  nivel_beneficio: string | null;
  nivel_color: string;
  siguiente_nivel: string | null;
  faltan_siguiente_nivel: number | null;
  meta_visitas: number;
  sellos: number;
  faltan_recompensa: number;
  recompensas_disponibles: number;
};

type Paso = "captura" | "registro" | "progreso";

const MESES = [
  "Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio",
  "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre",
];

export default function Visita() {
  const [params] = useSearchParams();
  const suc = (params.get("suc") ?? "").trim().toUpperCase();

  const [sucursalNombre, setSucursalNombre] = useState<string | null>(null);
  const [paso, setPaso] = useState<Paso>("captura");

  // Paso 1
  const [folio, setFolio] = useState("");
  const [telefono, setTelefono] = useState("");

  // Paso 2 (alta)
  const [primerNombre, setPrimerNombre] = useState("");
  const [segundoNombre, setSegundoNombre] = useState("");
  const [apellidoPaterno, setApellidoPaterno] = useState("");
  const [apellidoMaterno, setApellidoMaterno] = useState("");
  const [nacDia, setNacDia] = useState("");
  const [nacMes, setNacMes] = useState("");
  const [nacAnio, setNacAnio] = useState("");
  const [acepto, setAcepto] = useState(false);

  const [enviando, setEnviando] = useState(false);
  const [perfil, setPerfil] = useState<Perfil | null>(null);

  useEffect(() => {
    if (!suc) return;
    supabase
      .from("sucursales")
      .select("nombre,prefijo_folio")
      .eq("prefijo_folio", suc)
      .maybeSingle()
      .then(({ data }) => setSucursalNombre(data?.nombre ?? null));
  }, [suc]);

  const telLimpio = useMemo(() => telefono.replace(/\D/g, ""), [telefono]);
  const telValido = telLimpio.length === 10;
  const folioLimpio = useMemo(() => folio.replace(/\s/g, ""), [folio]);
  const folioValido = folioLimpio.length >= 1;

  // Años seleccionables: de hace 100 años hasta hace 5 (evita años futuros/absurdos)
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

  const registrarValido =
    primerNombre.trim().length >= 2 &&
    apellidoPaterno.trim().length >= 2 &&
    apellidoMaterno.trim().length >= 2 &&
    !!fechaNacimiento &&
    acepto &&
    !enviando;

  const llamarVisita = async (conNombre: boolean) => {
    setEnviando(true);
    const { data, error } = await (supabase.rpc as any)("lealtad_visita", {
      p_telefono: telLimpio,
      p_sucursal_codigo: suc || null,
      p_folio: folioLimpio,
      p_primer_nombre: conNombre ? primerNombre.trim() : null,
      p_segundo_nombre: conNombre ? (segundoNombre.trim() || null) : null,
      p_apellido_paterno: conNombre ? apellidoPaterno.trim() : null,
      p_apellido_materno: conNombre ? apellidoMaterno.trim() : null,
      p_cumpleanos: conNombre ? fechaNacimiento : null,
      p_consentimiento: conNombre ? acepto : null,
    });
    setEnviando(false);

    if (error) {
      const msg = error.message || "";
      if (msg.includes("TELEFONO_INVALIDO")) toast.error("Revisa tu teléfono: deben ser 10 dígitos.");
      else if (msg.includes("FOLIO_REQUERIDO") || msg.includes("FOLIO_INVALIDO")) toast.error("Escribe el folio de tu ticket.");
      else if (msg.includes("CUMPLE_REQUERIDO")) toast.error("Falta tu fecha de nacimiento.");
      else if (msg.includes("CONSENTIMIENTO")) toast.error("Necesitas aceptar el aviso para registrarte.");
      else if (msg.includes("NOMBRE")) toast.error("Completa tu nombre y apellidos.");
      else toast.error("No pudimos registrar tu visita. Intenta de nuevo.");
      return;
    }

    const r = data as Perfil;
    if (r.status === "necesita_registro") {
      setPaso("registro"); // teléfono nuevo: pedimos nombre completo
      window.scrollTo({ top: 0 });
      return;
    }
    if (r.status === "folio_usado") {
      toast.error("Ese folio ya se registró. Cada ticket cuenta una sola vez.");
      return;
    }
    setPerfil(r);
    setPaso("progreso");
    window.scrollTo({ top: 0 });
  };

  const reiniciar = () => {
    setPaso("captura");
    setFolio(""); setTelefono("");
    setPrimerNombre(""); setSegundoNombre(""); setApellidoPaterno(""); setApellidoMaterno("");
    setNacDia(""); setNacMes(""); setNacAnio(""); setAcepto(false);
    setPerfil(null);
  };

  // ---------- Encabezado con logo ----------
  const Header = ({ titulo, sub }: { titulo: string; sub?: React.ReactNode }) => (
    <div className="flex flex-col items-center text-center mb-6">
      <div className="w-20 h-20 rounded-full overflow-hidden mb-3 ring-4 ring-primary/20 shadow-lg">
        <img src={logoLaOla} alt="La Ola" className="w-full h-full object-cover" />
      </div>
      <h1 className="text-3xl font-bold font-display text-primary">{titulo}</h1>
      {sub && <p className="text-muted-foreground mt-1">{sub}</p>}
      {sucursalNombre && (
        <span className="mt-3 inline-block bg-accent text-accent-foreground text-sm font-semibold px-4 py-1 rounded-full">
          {sucursalNombre}
        </span>
      )}
    </div>
  );

  // ============================================================
  // PASO 3 — Progreso / tarjeta de sellos
  // ============================================================
  if (paso === "progreso" && perfil) {
    const mensaje =
      perfil.status === "registrado" ? "¡Bienvenido! Contamos tu primera visita 🌊"
      : perfil.status === "ya_hoy" ? "Ya contamos tu visita de hoy 😉"
      : "¡Visita registrada! 🌊";
    const meta = perfil.meta_visitas;
    const sellos = perfil.sellos;
    const saludo = perfil.primer_nombre || perfil.nombre.split(" ")[0];

    return (
      <div className="min-h-screen bg-gradient-to-b from-primary/10 via-background to-background">
        <div className="max-w-md mx-auto px-4 py-8">
          <Header titulo={`¡Hola, ${saludo}!`} sub={mensaje} />

          {/* Nivel */}
          <div className="rounded-2xl border bg-card p-5 shadow-sm text-center">
            <div className="inline-flex items-center gap-2 font-semibold px-4 py-1.5 rounded-full text-white"
                 style={{ backgroundColor: perfil.nivel_color }}>
              <Trophy className="h-4 w-4" /> Nivel {perfil.nivel}
            </div>
            {perfil.nivel_beneficio && (
              <p className="text-sm text-muted-foreground mt-2">{perfil.nivel_beneficio}</p>
            )}
            <p className="text-xs text-muted-foreground mt-1">{perfil.visitas_total} visitas en total</p>
          </div>

          {/* Sellos hacia la recompensa */}
          <div className="rounded-2xl border bg-card p-5 shadow-sm mt-4">
            <div className="flex items-center gap-2 text-accent font-semibold mb-3">
              <Gift className="h-5 w-5" /> Tu tarjeta de sellos
            </div>
            <div className="flex flex-wrap gap-2 justify-center">
              {Array.from({ length: meta }).map((_, i) => (
                <div key={i}
                  className={`w-9 h-9 rounded-full border-2 flex items-center justify-center ${
                    i < sellos ? "bg-primary border-primary text-white" : "border-muted-foreground/30 text-muted-foreground/40"
                  }`}>
                  {i < sellos ? <Check className="h-4 w-4" /> : <Waves className="h-4 w-4" />}
                </div>
              ))}
            </div>
            <p className="text-center text-sm text-muted-foreground mt-3">
              {perfil.faltan_recompensa === 0
                ? "¡Completaste tu tarjeta! 🎉"
                : `Te faltan ${perfil.faltan_recompensa} ${perfil.faltan_recompensa === 1 ? "visita" : "visitas"} para tu recompensa.`}
            </p>
          </div>

          {/* Recompensas disponibles */}
          {perfil.recompensas_disponibles > 0 && (
            <div className="rounded-2xl border-2 border-accent bg-accent/10 p-4 mt-4 text-center">
              <p className="font-semibold text-accent">
                🎁 Tienes {perfil.recompensas_disponibles} recompensa{perfil.recompensas_disponibles > 1 ? "s" : ""} disponible{perfil.recompensas_disponibles > 1 ? "s" : ""}
              </p>
              <p className="text-sm text-muted-foreground mt-1">Pídela con tu mesero o en caja.</p>
            </div>
          )}

          {/* Siguiente nivel */}
          {perfil.siguiente_nivel && perfil.faltan_siguiente_nivel != null && (
            <p className="text-center text-sm text-muted-foreground mt-4">
              A {perfil.faltan_siguiente_nivel} {perfil.faltan_siguiente_nivel === 1 ? "visita" : "visitas"} de subir a <b>{perfil.siguiente_nivel}</b>.
            </p>
          )}

          <div className="flex flex-col items-center gap-3 mt-6">
            <Link to="/menu" className="text-primary font-semibold">Ver el menú</Link>
            <button onClick={reiniciar} className="text-xs text-muted-foreground underline">
              Registrar otro ticket
            </button>
          </div>
        </div>
      </div>
    );
  }

  // ============================================================
  // PASO 2 — Registro (cliente nuevo): nombre completo + nacimiento
  // ============================================================
  if (paso === "registro") {
    return (
      <div className="min-h-screen bg-gradient-to-b from-primary/10 via-background to-background">
        <div className="max-w-md mx-auto px-4 py-8">
          <Header titulo="Únete a La Ola" sub={<>Es tu primera vez con este número. Cuéntanos quién eres y empieza a sumar visitas 🦐</>} />
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

            <Button className="w-full h-12 text-base font-semibold" disabled={!registrarValido} onClick={() => llamarVisita(true)}>
              {enviando ? <Loader2 className="h-5 w-5 animate-spin" /> : "Unirme a La Ola"}
            </Button>
            <button onClick={() => setPaso("captura")} className="w-full text-xs text-muted-foreground underline">
              Volver
            </button>
          </div>
        </div>
      </div>
    );
  }

  // ============================================================
  // PASO 1 — Folio del ticket + teléfono
  // ============================================================
  return (
    <div className="min-h-screen bg-gradient-to-b from-primary/10 via-background to-background">
      <div className="max-w-md mx-auto px-4 py-8">
        <Header titulo="La Ola · Recompensas" sub={<>Registra tu ticket y suma visitas 🦐</>} />
        <div className="rounded-2xl border bg-card p-5 shadow-sm space-y-4">
          <div className="space-y-1.5">
            <Label htmlFor="folio" className="flex items-center gap-1.5">
              <Ticket className="h-4 w-4 text-primary" /> Folio de tu ticket
            </Label>
            <Input id="folio" value={folio} onChange={(e) => setFolio(e.target.value)}
              placeholder="Ej. 4512" className="h-12 text-base" autoFocus />
            <p className="text-xs text-muted-foreground">Lo encuentras impreso en tu ticket.</p>
          </div>
          <div className="space-y-1.5">
            <Label htmlFor="tel">Tu WhatsApp (10 dígitos)</Label>
            <Input id="tel" value={telefono} onChange={(e) => setTelefono(e.target.value)}
              placeholder="311 123 4567" className="h-12 text-base" inputMode="numeric" autoComplete="tel" />
            {telefono.length > 0 && !telValido && (
              <p className="text-xs text-destructive">Deben ser 10 dígitos.</p>
            )}
          </div>
          <Button className="w-full h-12 text-base font-semibold" disabled={!telValido || !folioValido || enviando} onClick={() => llamarVisita(false)}>
            {enviando ? <Loader2 className="h-5 w-5 animate-spin" /> : "Registrar mi visita"}
          </Button>
        </div>
        <p className="text-center text-xs text-muted-foreground mt-4">
          Un teléfono, un perfil. Cada ticket cuenta una sola vez. Te reconocemos en cualquiera de nuestras sucursales.
        </p>
      </div>
    </div>
  );
}
