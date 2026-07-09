import { useEffect, useMemo, useState } from "react";
import { Link, useSearchParams } from "react-router-dom";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Checkbox } from "@/components/ui/checkbox";
import { Loader2, Gift, ChevronDown, Waves, Trophy, Check } from "lucide-react";
import { toast } from "sonner";
import { supabase } from "@/integrations/supabase/client";
import logoLaOla from "@/assets/logo-la-ola.jpeg";

// URL del aviso de privacidad (ajústala a la real cuando exista)
const AVISO_PRIVACIDAD = "/privacidad";

type Perfil = {
  status: string;
  nombre: string;
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

type Paso = "telefono" | "registro" | "progreso";

export default function Lealtad() {
  const [params] = useSearchParams();
  const suc = (params.get("suc") ?? "").trim().toUpperCase();

  const [sucursalNombre, setSucursalNombre] = useState<string | null>(null);
  const [paso, setPaso] = useState<Paso>("telefono");
  const [telefono, setTelefono] = useState("");
  const [nombre, setNombre] = useState("");
  const [cumple, setCumple] = useState("");
  const [mostrarCumple, setMostrarCumple] = useState(false);
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

  const llamarVisita = async (conNombre: boolean) => {
    setEnviando(true);
    const { data, error } = await (supabase.rpc as any)("lealtad_visita", {
      p_telefono: telLimpio,
      p_sucursal_codigo: suc || null,
      p_nombre: conNombre ? nombre.trim() : null,
      p_cumpleanos: conNombre ? (cumple || null) : null,
      p_consentimiento: conNombre ? acepto : null,
    });
    setEnviando(false);

    if (error) {
      const msg = error.message || "";
      if (msg.includes("TELEFONO_INVALIDO")) toast.error("Revisa tu teléfono: deben ser 10 dígitos.");
      else if (msg.includes("CONSENTIMIENTO")) toast.error("Necesitas aceptar el aviso para registrarte.");
      else toast.error("No pudimos registrar tu visita. Intenta de nuevo.");
      return;
    }

    const r = data as Perfil;
    if (r.status === "necesita_registro") {
      setPaso("registro"); // es nuevo: pedimos nombre
      return;
    }
    setPerfil(r);
    setPaso("progreso");
    window.scrollTo({ top: 0 });
  };

  const puedeRegistrar = nombre.trim().length >= 2 && acepto && !enviando;

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

    return (
      <div className="min-h-screen bg-gradient-to-b from-primary/10 via-background to-background">
        <div className="max-w-md mx-auto px-4 py-8">
          <Header titulo={`¡Hola, ${perfil.nombre.split(" ")[0]}!`} sub={mensaje} />

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
            <button
              onClick={() => { setPaso("telefono"); setTelefono(""); setNombre(""); setPerfil(null); setAcepto(false); }}
              className="text-xs text-muted-foreground underline"
            >
              Registrar otra visita
            </button>
          </div>
        </div>
      </div>
    );
  }

  // ============================================================
  // PASO 2 — Registro (cliente nuevo)
  // ============================================================
  if (paso === "registro") {
    return (
      <div className="min-h-screen bg-gradient-to-b from-primary/10 via-background to-background">
        <div className="max-w-md mx-auto px-4 py-8">
          <Header titulo="Únete a La Ola" sub={<>Es tu primera vez con este número. Cuéntanos quién eres y empieza a sumar visitas 🦐</>} />
          <div className="rounded-2xl border bg-card p-5 shadow-sm space-y-4">
            <div className="space-y-1.5">
              <Label htmlFor="nombre">Tu nombre</Label>
              <Input id="nombre" value={nombre} onChange={(e) => setNombre(e.target.value)}
                placeholder="¿Cómo te llamas?" className="h-12 text-base" autoComplete="given-name" />
            </div>

            {!mostrarCumple ? (
              <button type="button" onClick={() => setMostrarCumple(true)}
                className="flex items-center gap-1.5 text-sm text-primary font-medium">
                <ChevronDown className="h-4 w-4" /> Agrega tu cumpleaños y te cae algo ese día
              </button>
            ) : (
              <div className="space-y-1.5">
                <Label htmlFor="cumple">Tu cumpleaños (opcional)</Label>
                <Input id="cumple" type="date" value={cumple} onChange={(e) => setCumple(e.target.value)} className="h-12 text-base" />
              </div>
            )}

            <label className="flex items-start gap-3 pt-1 cursor-pointer">
              <Checkbox checked={acepto} onCheckedChange={(v) => setAcepto(v === true)} className="mt-0.5" />
              <span className="text-sm text-muted-foreground leading-snug">
                Acepto recibir promociones de La Ola y el{" "}
                <a href={AVISO_PRIVACIDAD} target="_blank" rel="noreferrer" className="text-primary underline">aviso de privacidad</a>.
                Puedo darme de baja cuando quiera.
              </span>
            </label>

            <Button className="w-full h-12 text-base font-semibold" disabled={!puedeRegistrar} onClick={() => llamarVisita(true)}>
              {enviando ? <Loader2 className="h-5 w-5 animate-spin" /> : "Unirme a La Ola"}
            </Button>
            <button onClick={() => setPaso("telefono")} className="w-full text-xs text-muted-foreground underline">
              Volver
            </button>
          </div>
        </div>
      </div>
    );
  }

  // ============================================================
  // PASO 1 — Teléfono
  // ============================================================
  return (
    <div className="min-h-screen bg-gradient-to-b from-primary/10 via-background to-background">
      <div className="max-w-md mx-auto px-4 py-8">
        <Header titulo="La Ola · Recompensas" sub={<>Suma visitas y gana premios 🦐</>} />
        <div className="rounded-2xl border bg-card p-5 shadow-sm space-y-4">
          <div className="space-y-1.5">
            <Label htmlFor="tel">Tu WhatsApp (10 dígitos)</Label>
            <Input id="tel" value={telefono} onChange={(e) => setTelefono(e.target.value)}
              placeholder="311 123 4567" className="h-12 text-base" inputMode="numeric" autoComplete="tel" autoFocus />
            {telefono.length > 0 && !telValido && (
              <p className="text-xs text-destructive">Deben ser 10 dígitos.</p>
            )}
          </div>
          <Button className="w-full h-12 text-base font-semibold" disabled={!telValido || enviando} onClick={() => llamarVisita(false)}>
            {enviando ? <Loader2 className="h-5 w-5 animate-spin" /> : "Registrar mi visita"}
          </Button>
        </div>
        <p className="text-center text-xs text-muted-foreground mt-4">
          Un teléfono, un perfil. Te reconocemos en cualquiera de nuestras sucursales.
        </p>
      </div>
    </div>
  );
}
