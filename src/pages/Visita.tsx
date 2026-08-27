import { useEffect, useMemo, useState } from "react";
import { Link, useLocation, useSearchParams } from "react-router-dom";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Checkbox } from "@/components/ui/checkbox";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Loader2, Gift, Waves, Trophy, Check, Ticket } from "lucide-react";
import { toast } from "sonner";
import { supabase } from "@/integrations/supabase/client";
import { recompensaDeCiclo, nivelDePosicion, textoSobre, RECOMPENSA_INICIAL_ID } from "@/lib/lealtad";
import ActivarWhatsApp from "@/components/ActivarWhatsApp";
import logoLaOla from "@/assets/logo-la-ola.jpeg";
import { telefonoMx10 } from "@/lib/telefono";

// URL del aviso de privacidad (ajústala a la real cuando exista)
const AVISO_PRIVACIDAD = "/privacidad";

// La pantalla del canje vale 20 minutos: con el negocio lleno, el mesero
// puede tardar en llegar a la mesa. No es para apurar al cliente, es para
// que una captura de pantalla no sirva mañana en otra sucursal.
const VIGENCIA_CANJE = 20 * 60;

type Perfil = {
  status: string;
  nombre: string;
  primer_nombre?: string;
  visitas_total: number;
  nivel: string;
  nivel_posicion?: number | null;
  nivel_beneficio: string | null;
  nivel_color: string;
  anio?: number;
  visitas_anio?: number;
  meta_visitas: number;
  sellos: number;
  faltan_recompensa: number;
  recompensas_disponibles: number;
  recompensa_posicion?: number | null;
  recompensa_titulo?: string | null;
  bienvenida_disponible?: boolean;
};

type Canje = { titulo: string; hora: Date; posicion: number | null; nombre: string };

type Paso = "captura" | "registro" | "progreso" | "canjeado";

const MESES = [
  "Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio",
  "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre",
];

export default function Visita() {
  const [params] = useSearchParams();
  const location = useLocation();
  const suc = (params.get("suc") ?? "").trim().toUpperCase();

  // Llega de acabarse de inscribir en /lealtad: la inscripción ES la visita 1
  // y la RPC ya devolvió el perfil, así que esta pantalla abre en su
  // promoción sin pedir folio. La bandera además decide qué se puede canjear
  // aquí: solo la Recompensa inicial (ver más abajo).
  const entrada = (location.state ?? {}) as {
    perfil?: Perfil;
    telefono?: string;
    desdeRegistro?: boolean;
  };
  const desdeRegistro = entrada.desdeRegistro === true && !!entrada.perfil;

  const [sucursalNombre, setSucursalNombre] = useState<string | null>(null);
  const [paso, setPaso] = useState<Paso>(desdeRegistro ? "progreso" : "captura");

  // Paso 1
  const [folio, setFolio] = useState("");
  const [telefono, setTelefono] = useState(entrada.telefono ?? "");

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
  const [perfil, setPerfil] = useState<Perfil | null>(entrada.perfil ?? null);
  const [canje, setCanje] = useState<Canje | null>(null);
  const [confirmando, setConfirmando] = useState<"recompensa" | null>(null);
  const [canjeando, setCanjeando] = useState(false);
  // Late una vez por segundo mientras hay un canje en pantalla.
  const [ahora, setAhora] = useState(() => Date.now());

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
    if (r.status === "folio_invalido") {
      toast.error("Ese folio no parece de un ticket. Revísalo en tu cuenta.");
      return;
    }
    setPerfil(r);
    setPaso("progreso");
    window.scrollTo({ top: 0 });
  };

  useEffect(() => {
    if (paso !== "canjeado") return;
    const t = setInterval(() => setAhora(Date.now()), 1000);
    return () => clearInterval(t);
  }, [paso]);

  // Canje self-serve: deja registro interno para empatar contra el comandero.
  // Sólo las del ciclo. La Recompensa inicial ya no se canjea: se entrega en
  // la mesa el día del alta, así que no tiene botón ni registro que conciliar.
  const canjear = async () => {
    // La posición se toma del perfil ACTUAL: después del canje ya avanzó
    // al siguiente escalón del ciclo.
    const posicionCanjeada = perfil?.recompensa_posicion ?? null;
    setCanjeando(true);
    const { data, error } = await (supabase.rpc as any)("lealtad_canjear_cliente", {
      p_telefono: telLimpio,
      p_sucursal_codigo: suc || null,
    });
    setCanjeando(false);
    setConfirmando(null);

    if (error) {
      const msg = error.message || "";
      if (msg.includes("SIN_RECOMPENSAS")) toast.error("Aún no tienes recompensa disponible.");
      else toast.error("No pudimos registrar el canje. Intenta de nuevo.");
      return;
    }

    const r = data as Perfil & { canje_titulo: string };
    setPerfil(r);
    setCanje({ titulo: r.canje_titulo, hora: new Date(), posicion: posicionCanjeada, nombre: r.nombre });
    setAhora(Date.now());
    setPaso("canjeado");
    window.scrollTo({ top: 0 });
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
        <span className="mt-3 inline-block bg-accent text-accent-foreground text-sm font-semibold px-4 py-1 rounded-md">
          {sucursalNombre}
        </span>
      )}
    </div>
  );

  // ============================================================
  // PASO 4 — Canje registrado: pantalla para enseñar al mesero
  // ============================================================
  if (paso === "canjeado" && perfil && canje) {
    const rec = recompensaDeCiclo(canje.posicion);
    const transcurrido = Math.floor((ahora - canje.hora.getTime()) / 1000);
    const restante = VIGENCIA_CANJE - transcurrido;
    const vigente = restante > 0;
    const mm = Math.floor(Math.max(0, restante) / 60);
    const ss = String(Math.max(0, restante) % 60).padStart(2, "0");

    return (
      <div className="min-h-screen bg-gradient-to-b from-primary/10 via-background to-background">
        <div className="max-w-md mx-auto px-4 py-8">
          <Header
            titulo={vigente ? "¡Canje registrado!" : "Canje vencido"}
            sub={vigente ? "Enséñale esta pantalla a tu mesero 🌊" : "Vuelve a abrirlo frente a tu mesero"}
          />
          <div
            className={`rounded-2xl border-2 p-6 text-center shadow-sm ${
              vigente ? "border-primary bg-primary/5" : "border-muted bg-muted/40 opacity-70"
            }`}
          >
            <div
              className={`mx-auto w-16 h-16 rounded-lg flex items-center justify-center mb-4 ${
                vigente ? "bg-primary text-white" : "bg-muted-foreground/30 text-white"
              }`}
            >
              <Check className="h-9 w-9" />
            </div>

            {/* Identificador y color: el mesero lo reconoce sin leer el detalle */}
            <div
              className={`inline-flex items-center gap-2 font-bold px-4 py-1.5 rounded-md border-2 mb-3 ${
                rec ? `${rec.bg} ${rec.texto} ${rec.borde}` : "bg-card text-foreground border-border"
              }`}
            >
              <Gift className="h-4 w-4" />
              {rec ? rec.identificador : RECOMPENSA_INICIAL_ID}
            </div>

            <p className="text-xl font-bold">{canje.titulo}</p>
            <p className="text-sm font-medium mt-1">{canje.nombre}</p>
            <p className="text-sm text-muted-foreground mt-1">
              {sucursalNombre ? <>{sucursalNombre} · </> : null}
              {canje.hora.toLocaleString("es-MX", { day: "2-digit", month: "short", hour: "2-digit", minute: "2-digit" })}
            </p>

            {/* Reloj vivo: una captura de pantalla se queda congelada */}
            {vigente ? (
              <div className="mt-4 rounded-xl bg-background border-2 border-primary/30 p-3">
                <p className="text-3xl font-bold tabular-nums text-primary">
                  {mm}:{ss}
                </p>
                <p className="text-[11px] text-muted-foreground mt-1">
                  Mesero: los segundos tienen que ir corriendo. Una captura de pantalla no se mueve.
                </p>
              </div>
            ) : (
              <div className="mt-4 rounded-xl bg-background border-2 border-destructive/40 p-3">
                <p className="font-bold text-destructive">Ya no es válido</p>
                <p className="text-[11px] text-muted-foreground mt-1">
                  Este canje ya se entregó. Si algo falta, el mesero lo revisa en el sistema.
                </p>
              </div>
            )}

            <p className="text-xs text-muted-foreground mt-3">
              Tu mesero registra la entrega en el sistema. ¡Disfrútalo!
            </p>
          </div>
          <div className="flex flex-col items-center gap-3 mt-6">
            <button onClick={() => setPaso("progreso")} className="text-primary font-semibold">Ver mi progreso</button>
            <Link to="/menu" className="text-sm text-muted-foreground underline">Ver el menú</Link>
          </div>
        </div>
      </div>
    );
  }

  // ============================================================
  // PASO 3 — Progreso / tarjeta de sellos
  // ============================================================
  if (paso === "progreso" && perfil) {
    const mensaje =
      perfil.status === "registrado" ? "Ya eres parte de La Ola. Ésta es tu visita 1 🌊"
      : perfil.status === "ya_estaba" ? "Ya eras parte de La Ola 🌊"
      : perfil.status === "ya_hoy" ? "Ya contamos tu visita de hoy 😉"
      : "¡Visita registrada! 🌊";
    const meta = perfil.meta_visitas;
    const sellos = perfil.sellos;
    const saludo = perfil.primer_nombre || perfil.nombre.split(" ")[0];
    const titulo = perfil.status === "registrado" ? `¡Bienvenido, ${saludo}!` : `¡Hola, ${saludo}!`;

    return (
      <div className="min-h-screen bg-gradient-to-b from-primary/10 via-background to-background">
        <div className="max-w-md mx-auto px-4 py-8">
          <Header titulo={titulo} sub={mensaje} />

          {/* Nivel = la parada del ciclo hacia la que va, con su color */}
          <div className="rounded-2xl border bg-card p-5 shadow-sm text-center">
            {(() => {
              // Sin nivel_posicion (base todavía sin la migración v5) se
              // pinta con el hex que mande la base, como siempre.
              if (perfil.nivel_posicion == null) {
                return (
                  <div
                    className="inline-flex items-center gap-2 font-semibold px-4 py-1.5 rounded-md border-2 border-black/10"
                    style={{ backgroundColor: perfil.nivel_color, color: textoSobre(perfil.nivel_color) }}
                  >
                    <Trophy className="h-4 w-4" /> Nivel {perfil.nivel}
                  </div>
                );
              }
              const niv = nivelDePosicion(perfil.nivel_posicion);
              return (
                <div
                  className={`inline-flex items-center gap-2 font-semibold px-4 py-1.5 rounded-md border-2 ${niv.bg} ${niv.texto} ${niv.borde}`}
                >
                  <Trophy className="h-4 w-4" /> Nivel {perfil.nivel}
                </div>
              );
            })()}
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
              {perfil.recompensas_disponibles > 0
                ? "¡Completaste tu tarjeta! 🎉"
                : perfil.recompensa_titulo
                  ? `Vas por: ${perfil.recompensa_titulo}. Te ${perfil.faltan_recompensa === 1 ? "falta 1 visita" : `faltan ${perfil.faltan_recompensa} visitas`}.`
                  : `Te faltan ${perfil.faltan_recompensa} ${perfil.faltan_recompensa === 1 ? "visita" : "visitas"} para tu recompensa.`}
            </p>
            <p className="text-center text-xs text-muted-foreground mt-1">
              Tus visitas y recompensas cuentan durante {perfil.anio ?? new Date().getFullYear()}.
            </p>
          </div>

          {/* Recompensa disponible: canje self-serve frente al mesero.
              Aquí NO cuando se viene del alta: esa pantalla se abre sin
              folio, y las recompensas del ciclo sí se ganan con tickets.
              Quien acaba de inscribirse no tiene ninguna todavía; el
              candado es para el que ya venía sumando y vuelve a llenar el
              formulario de inscripción. */}
          {!desdeRegistro && perfil.recompensas_disponibles > 0 && perfil.recompensa_titulo && (
            <div className="rounded-2xl border-2 border-accent bg-accent/10 p-4 mt-4 text-center">
              {(() => {
                const rec = recompensaDeCiclo(perfil.recompensa_posicion);
                return rec ? (
                  <div
                    className={`inline-flex items-center gap-2 font-bold px-3 py-1 rounded-md border-2 mb-2 text-sm ${rec.bg} ${rec.texto} ${rec.borde}`}
                  >
                    <Gift className="h-3.5 w-3.5" /> {rec.identificador}
                  </div>
                ) : null;
              })()}
              <p className="font-semibold text-accent">🎁 Te toca: {perfil.recompensa_titulo}</p>
              <p className="text-sm text-muted-foreground mt-1">Elige con tu mesero.</p>
              {confirmando === "recompensa" ? (
                <div className="mt-3 space-y-2">
                  <p className="text-sm font-medium">Canjéalo solo frente a tu mesero. ¿Registrar el canje ahora?</p>
                  <div className="flex gap-2 justify-center">
                    <Button size="sm" disabled={canjeando} onClick={() => canjear()}>
                      {canjeando ? <Loader2 className="h-4 w-4 animate-spin" /> : "Sí, canjear"}
                    </Button>
                    <Button size="sm" variant="outline" onClick={() => setConfirmando(null)}>Todavía no</Button>
                  </div>
                </div>
              ) : (
                <Button className="mt-3 font-semibold" onClick={() => setConfirmando("recompensa")}>
                  Canjear con mi mesero
                </Button>
              )}
            </div>
          )}

          {/* Recompensa inicial: ya no se canjea, se entrega ahí mismo.
              Quien llena el formulario está sentado en una mesa, así que el
              regalo se lo da el mesero en el momento y el alta ya nace con
              él entregado. Por eso esto es un aviso, no un botón, y sale
              sólo cuando se viene del registro: en visitas posteriores ya
              no hay nada que enseñar. */}
          {desdeRegistro && (
            <div className="rounded-2xl border-2 border-primary/40 bg-primary/5 p-4 mt-4 text-center">
              <p className="font-semibold text-primary">🥂 Tu Recompensa inicial ya es tuya</p>
              <p className="text-sm text-primary/90 mt-0.5">
                Un balazo de tu elección + cerveza o refresco
              </p>
              <p className="text-[11px] leading-snug text-muted-foreground/70 mt-1.5">
                No incluye balazo de callo de hacha ni cerveza premium.
              </p>
              <p className="text-sm font-medium text-primary mt-3">
                Enséñale esta pantalla a tu mesero.
              </p>
            </div>
          )}

          {desdeRegistro && (
            <div className="mt-4 rounded-xl bg-primary/5 border border-primary/10 p-3 text-sm text-primary text-center font-medium flex items-center justify-center gap-2">
              <Ticket className="h-4 w-4 shrink-0" />
              De la próxima visita en adelante, súmala con el folio de tu ticket.
            </div>
          )}

          <div className="mt-6">
            <ActivarWhatsApp nombre={saludo} contexto={perfil.status === "registrado" ? "alta" : "visita"} />
          </div>

          <div className="flex flex-col items-center gap-3 mt-6">
            {desdeRegistro && perfil.status === "ya_estaba" && (
              <button
                onClick={() => { setPaso("captura"); window.scrollTo({ top: 0 }); }}
                className="text-primary font-semibold"
              >
                Registrar mi visita de hoy
              </button>
            )}
            <Link to="/menu" className="text-primary font-semibold">Ver el menú</Link>
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
