import { useEffect, useMemo, useState } from "react";
import { Link, useSearchParams } from "react-router-dom";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Checkbox } from "@/components/ui/checkbox";
import { Loader2, PartyPopper, Gift, ChevronDown } from "lucide-react";
import { toast } from "sonner";
import { supabase } from "@/integrations/supabase/client";
import logoLaOla from "@/assets/logo-la-ola.jpeg";

// URL del aviso de privacidad (ajústala a la real cuando exista)
const AVISO_PRIVACIDAD = "/privacidad";

export default function Lealtad() {
  const [params] = useSearchParams();
  const suc = (params.get("suc") ?? "").trim().toUpperCase();

  const [sucursalNombre, setSucursalNombre] = useState<string | null>(null);
  const [nombre, setNombre] = useState("");
  const [telefono, setTelefono] = useState("");
  const [cumple, setCumple] = useState("");
  const [mostrarCumple, setMostrarCumple] = useState(false);
  const [acepto, setAcepto] = useState(false);
  const [enviando, setEnviando] = useState(false);
  const [listo, setListo] = useState(false);

  // Nombre de la sucursal (para el saludo). No bloquea si falla.
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
  const puedeEnviar = nombre.trim().length >= 2 && telValido && acepto && !enviando;

  const registrar = async () => {
    if (!puedeEnviar) return;
    setEnviando(true);
    // La función es nueva; los tipos generados aún no la incluyen (se regeneran al
    // aplicar la migración). Cast para no depender de eso.
    const { error } = await (supabase.rpc as any)("lealtad_registrar", {
      p_nombre: nombre.trim(),
      p_telefono: telLimpio,
      p_sucursal_codigo: suc || null,
      p_cumpleanos: cumple || null,
      p_consentimiento: true,
    });
    setEnviando(false);

    if (error) {
      const msg = error.message || "";
      if (msg.includes("TELEFONO_INVALIDO")) toast.error("Revisa tu teléfono: deben ser 10 dígitos.");
      else if (msg.includes("NOMBRE_REQUERIDO")) toast.error("Escribe tu nombre.");
      else toast.error("No pudimos registrarte. Intenta de nuevo en un momento.");
      return;
    }
    setListo(true);
    window.scrollTo({ top: 0 });
  };

  // ---------- Pantalla de gracias ----------
  if (listo) {
    return (
      <div className="min-h-screen bg-gradient-to-b from-primary/10 via-background to-background flex items-center justify-center p-4">
        <div className="max-w-md w-full text-center">
          <div className="w-20 h-20 rounded-full overflow-hidden mx-auto mb-4 ring-4 ring-primary/20 shadow-lg">
            <img src={logoLaOla} alt="La Ola" className="w-full h-full object-cover" />
          </div>
          <div className="inline-flex items-center justify-center w-16 h-16 rounded-full bg-accent/15 text-accent mb-4">
            <PartyPopper className="h-8 w-8" />
          </div>
          <h1 className="text-3xl font-bold font-display text-primary">
            ¡Ya eres parte de La Ola! 🌊
          </h1>
          <p className="text-muted-foreground mt-2">
            {nombre.trim().split(" ")[0]}, te registramos
            {sucursalNombre ? ` en ${sucursalNombre}` : ""}. Gracias por unirte.
          </p>

          <div className="mt-6 rounded-2xl border bg-card p-5 text-left shadow-sm">
            <div className="flex items-center gap-2 text-accent font-semibold">
              <Gift className="h-5 w-5" /> Tu regalo de bienvenida
            </div>
            <p className="text-sm text-muted-foreground mt-1.5">
              Muéstralo en tu próxima visita para que el mesero te lo aplique. Y de vez en cuando
              te mandaremos promos por WhatsApp. 🦐
            </p>
          </div>

          <Link to="/menu" className="inline-block mt-6 text-primary font-semibold">
            Ver el menú
          </Link>
        </div>
      </div>
    );
  }

  // ---------- Formulario ----------
  return (
    <div className="min-h-screen bg-gradient-to-b from-primary/10 via-background to-background">
      <div className="max-w-md mx-auto px-4 py-8">
        <div className="flex flex-col items-center text-center mb-6">
          <div className="w-20 h-20 rounded-full overflow-hidden mb-3 ring-4 ring-primary/20 shadow-lg">
            <img src={logoLaOla} alt="La Ola" className="w-full h-full object-cover" />
          </div>
          <h1 className="text-3xl font-bold font-display text-primary">Únete a La Ola</h1>
          <p className="text-muted-foreground mt-1">
            Regístrate y recibe tu <span className="text-accent font-semibold">regalo de bienvenida</span> 🦐
          </p>
          {sucursalNombre && (
            <span className="mt-3 inline-block bg-accent text-accent-foreground text-sm font-semibold px-4 py-1 rounded-full">
              {sucursalNombre}
            </span>
          )}
        </div>

        <div className="rounded-2xl border bg-card p-5 shadow-sm space-y-4">
          <div className="space-y-1.5">
            <Label htmlFor="nombre">Tu nombre</Label>
            <Input
              id="nombre"
              value={nombre}
              onChange={(e) => setNombre(e.target.value)}
              placeholder="¿Cómo te llamas?"
              className="h-12 text-base"
              autoComplete="given-name"
            />
          </div>

          <div className="space-y-1.5">
            <Label htmlFor="tel">WhatsApp (10 dígitos)</Label>
            <Input
              id="tel"
              value={telefono}
              onChange={(e) => setTelefono(e.target.value)}
              placeholder="311 123 4567"
              className="h-12 text-base"
              inputMode="numeric"
              autoComplete="tel"
            />
            {telefono.length > 0 && !telValido && (
              <p className="text-xs text-destructive">Deben ser 10 dígitos.</p>
            )}
          </div>

          {/* Cumpleaños opcional, colgado del beneficio */}
          {!mostrarCumple ? (
            <button
              type="button"
              onClick={() => setMostrarCumple(true)}
              className="flex items-center gap-1.5 text-sm text-primary font-medium"
            >
              <ChevronDown className="h-4 w-4" />
              Agrega tu cumpleaños y te cae algo ese día
            </button>
          ) : (
            <div className="space-y-1.5">
              <Label htmlFor="cumple">Tu cumpleaños (opcional)</Label>
              <Input
                id="cumple"
                type="date"
                value={cumple}
                onChange={(e) => setCumple(e.target.value)}
                className="h-12 text-base"
              />
            </div>
          )}

          <label className="flex items-start gap-3 pt-1 cursor-pointer">
            <Checkbox
              checked={acepto}
              onCheckedChange={(v) => setAcepto(v === true)}
              className="mt-0.5"
            />
            <span className="text-sm text-muted-foreground leading-snug">
              Acepto recibir promociones de La Ola y el{" "}
              <a href={AVISO_PRIVACIDAD} target="_blank" rel="noreferrer" className="text-primary underline">
                aviso de privacidad
              </a>
              . Puedo darme de baja cuando quiera.
            </span>
          </label>

          <Button
            className="w-full h-12 text-base font-semibold"
            disabled={!puedeEnviar}
            onClick={registrar}
          >
            {enviando ? <Loader2 className="h-5 w-5 animate-spin" /> : "Unirme a La Ola"}
          </Button>
        </div>

        <p className="text-center text-xs text-muted-foreground mt-4">
          Un teléfono, un perfil. Te reconocemos en cualquiera de nuestras sucursales.
        </p>
      </div>
    </div>
  );
}
