import { useEffect, useMemo, useRef, useState } from "react";
import { useNavigate } from "react-router-dom";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { InputOTP, InputOTPGroup, InputOTPSlot } from "@/components/ui/input-otp";
import { toast } from "sonner";
import {
  ArrowLeft, MapPin, Loader2, UploadCloud, CalendarDays, Check, ChevronLeft, ChevronRight,
} from "lucide-react";
import logoLaOla from "@/assets/logo-la-ola.jpeg";
import {
  AREAS_HORARIO, areaLabel, rotuloSemana, semanaSugerida, semanaDesplazada,
  estadoSemana,
} from "@/lib/horariosSemana";
import { nombreCorto } from "@/lib/sucursales";

const db = supabase as any;

type SucursalRow = { id: string; nombre: string; prefijo_folio: string | null };
type EstadoArea = { area: string; subido_por: string | null; created_at: string; version: number };

const MAX_BYTES = 20 * 1024 * 1024;
const CLAVE_FIRMA = "laola_horarios_subido_por";

export default function HorariosSubir() {
  const navigate = useNavigate();
  const [sucursales, setSucursales] = useState<SucursalRow[]>([]);
  const [cargando, setCargando] = useState(true);

  const [suc, setSuc] = useState<SucursalRow | null>(null);
  const [pin, setPin] = useState("");
  const [pinOk, setPinOk] = useState(false);
  const [verificando, setVerificando] = useState(false);

  const [semana, setSemana] = useState<string>(semanaSugerida());
  const [estado, setEstado] = useState<EstadoArea[]>([]);
  const [subiendo, setSubiendo] = useState<string | null>(null);
  const [firma, setFirma] = useState<string>(
    () => (typeof localStorage !== "undefined" && localStorage.getItem(CLAVE_FIRMA)) || ""
  );
  const inputs = useRef<Record<string, HTMLInputElement | null>>({});

  useEffect(() => {
    (async () => {
      const { data } = await db
        .from("sucursales")
        .select("id,nombre,prefijo_folio")
        .order("nombre");
      setSucursales((data ?? []) as SucursalRow[]);
      setCargando(false);
    })();
  }, []);

  // Estado de la semana: qué áreas ya entregaron. El mismo RPC valida el PIN.
  const cargarEstado = async (sucursal: SucursalRow, elPin: string, laSemana: string) => {
    const { data, error } = await db.rpc("horarios_semana_publico", {
      p_sucursal_id: sucursal.id,
      p_pin: elPin,
      p_semana_inicio: laSemana,
    });
    if (error) {
      if ((error.message || "").includes("PIN_INVALIDO")) return { ok: false as const };
      toast.error("No pudimos consultar la semana.");
      return { ok: false as const };
    }
    setEstado(((data?.areas ?? []) as EstadoArea[]) || []);
    return { ok: true as const };
  };

  const confirmarPin = async (valor: string) => {
    if (!suc) return;
    setVerificando(true);
    const r = await cargarEstado(suc, valor, semana);
    setVerificando(false);
    if (!r.ok) {
      toast.error("PIN incorrecto");
      setPin("");
      return;
    }
    setPinOk(true);
  };

  const cambiarSemana = async (delta: number) => {
    if (!suc) return;
    const nueva = semanaDesplazada(semana, delta);
    setSemana(nueva);
    await cargarEstado(suc, pin, nueva);
  };

  const subir = async (area: string, file: File) => {
    if (!suc) return;
    if (file.size > MAX_BYTES) {
      toast.error("El archivo pesa más de 20 MB.");
      return;
    }
    setSubiendo(area);
    const ext = (file.name.split(".").pop() || "pdf").toLowerCase().slice(0, 8);
    const code = (suc.prefijo_folio || suc.id).toLowerCase();
    const path = `${code}/${semana}/${area}-${crypto.randomUUID()}.${ext}`;

    const up = await supabase.storage.from("horarios").upload(path, file, {
      contentType: file.type || undefined,
      upsert: false,
    });
    if (up.error) {
      setSubiendo(null);
      toast.error("No pudimos subir el archivo. Revisa tu conexión e intenta de nuevo.");
      return;
    }

    const { data, error } = await db.rpc("horarios_archivo_registrar", {
      p_sucursal_id: suc.id,
      p_pin: pin,
      p_area: area,
      p_semana_inicio: semana,
      p_path: path,
      p_nombre: file.name,
      p_mime: file.type || null,
      p_tamano_bytes: file.size,
      p_subido_por: firma.trim() || null,
      p_nota: null,
    });
    setSubiendo(null);

    if (error) {
      toast.error(
        (error.message || "").includes("PIN_INVALIDO")
          ? "El PIN dejó de ser válido. Vuelve a entrar."
          : "El archivo subió pero no se registró. Avisa a administración."
      );
      return;
    }
    if (firma.trim()) localStorage.setItem(CLAVE_FIRMA, firma.trim());
    toast.success(
      data?.reemplazo
        ? `Horario de ${areaLabel(area)} reemplazado.`
        : `Horario de ${areaLabel(area)} cargado.`
    );
    await cargarEstado(suc, pin, semana);
  };

  const porArea = useMemo(() => {
    const m = new Map<string, EstadoArea>();
    estado.forEach((e) => m.set(e.area, e));
    return m;
  }, [estado]);

  if (cargando) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <Loader2 className="h-8 w-8 animate-spin text-primary" />
      </div>
    );
  }

  // ---------- Paso 1: sucursal ----------
  if (!suc) {
    return (
      <Marco titulo="Horario de la semana" subtitulo="Selecciona tu sucursal" onSalir={() => navigate("/centro-de-operaciones")}>
        <div className="grid gap-3">
          {sucursales.map((s) => (
            <Button
              key={s.id}
              variant="outline"
              className="w-full h-20 text-xl font-semibold gap-3 hover:bg-primary/5 hover:border-primary transition-all"
              onClick={() => { setSuc(s); setPin(""); }}
            >
              <MapPin className="w-6 h-6 text-primary" />
              {nombreCorto(s.nombre)}
            </Button>
          ))}
        </div>
      </Marco>
    );
  }

  // ---------- Paso 2: PIN ----------
  if (!pinOk) {
    return (
      <Marco titulo={nombreCorto(suc.nombre)} subtitulo="Ingresa el PIN de la sucursal" onSalir={() => setSuc(null)}>
        <div className="flex flex-col items-center gap-5">
          <InputOTP
            maxLength={4}
            value={pin}
            onChange={(v) => { setPin(v); if (v.length === 4) confirmarPin(v); }}
            disabled={verificando}
            autoFocus
          >
            <InputOTPGroup>
              {[0, 1, 2, 3].map((i) => (
                <InputOTPSlot key={i} index={i} className="h-14 w-14 text-2xl" />
              ))}
            </InputOTPGroup>
          </InputOTP>
          {verificando && <Loader2 className="h-5 w-5 animate-spin text-primary" />}
        </div>
      </Marco>
    );
  }

  // ---------- Paso 3: semana + áreas ----------
  const marca = estadoSemana(semana);
  return (
    <div className="min-h-screen bg-muted/30">
      <div className="bg-card border-b sticky top-0 z-10">
        <div className="max-w-2xl mx-auto px-4 py-3 flex items-center justify-between gap-2">
          <div className="flex items-center gap-3 min-w-0">
            <Button variant="ghost" size="icon" onClick={() => { setPinOk(false); setSuc(null); }}>
              <ArrowLeft className="w-5 h-5" />
            </Button>
            <img src={logoLaOla} alt="La Ola" className="w-9 h-9 rounded-full object-cover shrink-0" />
            <div className="min-w-0">
              <h1 className="text-base font-bold leading-tight truncate">Horario de la semana</h1>
              <p className="text-xs text-muted-foreground truncate">{nombreCorto(suc.nombre)}</p>
            </div>
          </div>
        </div>
      </div>

      <main className="max-w-2xl mx-auto px-4 py-5 space-y-4">
        {/* Semana que se está entregando */}
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between gap-2">
              <Button variant="ghost" size="icon" onClick={() => cambiarSemana(-1)}>
                <ChevronLeft className="w-5 h-5" />
              </Button>
              <div className="text-center min-w-0">
                <div className="flex items-center justify-center gap-2">
                  <CalendarDays className="w-4 h-4 text-primary shrink-0" />
                  <span className="font-semibold truncate">{rotuloSemana(semana)}</span>
                </div>
                <Badge variant={marca === "próxima" ? "default" : "secondary"} className="mt-1">
                  {marca === "próxima" ? "Semana que entra" : marca === "en curso" ? "Semana en curso" : "Semana pasada"}
                </Badge>
              </div>
              <Button variant="ghost" size="icon" onClick={() => cambiarSemana(1)}>
                <ChevronRight className="w-5 h-5" />
              </Button>
            </div>
          </CardContent>
        </Card>

        <div className="space-y-1">
          <Label htmlFor="firma" className="text-xs text-muted-foreground">¿Quién entrega? (para saber a quién preguntarle)</Label>
          <Input
            id="firma" value={firma} onChange={(e) => setFirma(e.target.value)}
            placeholder="Tu nombre" className="h-11"
          />
        </div>

        <div className="space-y-2">
          {AREAS_HORARIO.map((area) => {
            const ya = porArea.get(area);
            const busy = subiendo === area;
            return (
              <Card key={area} className={ya ? "border-primary/40" : undefined}>
                <CardContent className="p-4 flex items-center justify-between gap-3">
                  <div className="min-w-0">
                    <div className="flex items-center gap-2">
                      <span className="font-semibold truncate">{areaLabel(area)}</span>
                      {ya ? (
                        <Badge className="gap-1 shrink-0"><Check className="w-3 h-3" /> Entregado</Badge>
                      ) : (
                        <Badge variant="outline" className="shrink-0 text-muted-foreground">Falta</Badge>
                      )}
                    </div>
                    {ya && (
                      <p className="text-xs text-muted-foreground truncate">
                        {ya.subido_por ? `Lo subió ${ya.subido_por}` : "Cargado"}
                        {ya.version > 1 ? ` · versión ${ya.version}` : ""}
                      </p>
                    )}
                  </div>
                  <input
                    ref={(el) => (inputs.current[area] = el)}
                    type="file"
                    accept=".pdf,.xlsx,.xls,.doc,.docx,image/*,application/pdf"
                    className="sr-only"
                    onChange={(e) => {
                      const f = e.target.files?.[0];
                      e.target.value = "";
                      if (f) subir(area, f);
                    }}
                  />
                  <Button
                    variant={ya ? "outline" : "default"}
                    className="gap-2 shrink-0"
                    disabled={busy}
                    onClick={() => inputs.current[area]?.click()}
                  >
                    {busy ? <Loader2 className="w-4 h-4 animate-spin" /> : <UploadCloud className="w-4 h-4" />}
                    {ya ? "Reemplazar" : "Subir"}
                  </Button>
                </CardContent>
              </Card>
            );
          })}
        </div>

        <p className="text-xs text-muted-foreground text-center">
          PDF, foto, Excel o Word. Hasta 20 MB. Si vuelves a subir, se guarda como versión nueva
          y administración ve la más reciente.
        </p>
      </main>
    </div>
  );
}

// Marco de los pasos previos (sucursal y PIN), igual al gate de operaciones.
function Marco({ titulo, subtitulo, children, onSalir }: {
  titulo: string; subtitulo: string; children: React.ReactNode; onSalir: () => void;
}) {
  return (
    <div className="min-h-screen bg-gradient-to-br from-primary/5 to-secondary/10 flex items-center justify-center p-4">
      <Card className="w-full max-w-md">
        <CardContent className="p-6">
          <div className="text-center mb-6">
            <div className="mx-auto mb-3 w-16 h-16 rounded-full overflow-hidden">
              <img src={logoLaOla} alt="La Ola" className="w-full h-full object-cover" />
            </div>
            <h1 className="text-2xl font-bold">{titulo}</h1>
            <p className="text-muted-foreground">{subtitulo}</p>
          </div>
          {children}
          <Button variant="ghost" className="w-full mt-4 gap-2 text-muted-foreground" onClick={onSalir}>
            <ArrowLeft className="h-4 w-4" /> Regresar
          </Button>
        </CardContent>
      </Card>
    </div>
  );
}
