import { useEffect, useState } from "react";
import { supabase } from "@/integrations/supabase/client";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Switch } from "@/components/ui/switch";
import { Badge } from "@/components/ui/badge";
import { toast } from "sonner";
import { Siren } from "lucide-react";

type Sucursal = { id: string; nombre: string };
type Config = { sucursal_id: string; hora_limite: string; hora_limite_finde: string | null; activo: boolean };
type Alerta = { sucursal_id: string; fecha_negocio: string; created_at: string };

const db = supabase as any;

// Día de negocio de La Ola: rueda a las 4 AM CDMX.
const fechaNegocioHoy = () =>
  new Date(Date.now() - 4 * 3600e3).toLocaleDateString("en-CA", { timeZone: "America/Mexico_City" });

/**
 * Semáforo de cortes del día de negocio: quién ya registró su corte de
 * cierre, quién sigue en tiempo y a quién ya se le mandó la alerta al
 * grupo de cajas (vía Makatea). Aquí mismo se configura la hora límite.
 */
export function SemaforoCortes({ sucursales }: { sucursales: Sucursal[] }) {
  const [configs, setConfigs] = useState<Config[]>([]);
  const [alertas, setAlertas] = useState<Alerta[]>([]);
  const [conCierre, setConCierre] = useState<Set<string>>(new Set());
  const fecha = fechaNegocioHoy();

  const cargar = async () => {
    const [cfg, alr, cie] = await Promise.all([
      db.from("cortes_alertas_config").select("*"),
      db.from("cortes_alertas_enviadas").select("*").eq("fecha_negocio", fecha),
      db.from("cortes_caja").select("sucursal_id").eq("tipo_corte", "cierre").eq("fecha_venta", fecha),
    ]);
    setConfigs((cfg.data ?? []) as Config[]);
    setAlertas((alr.data ?? []) as Alerta[]);
    setConCierre(new Set(((cie.data ?? []) as { sucursal_id: string }[]).map((c) => c.sucursal_id)));
  };

  useEffect(() => {
    cargar();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const guardar = async (sucursalId: string, cambios: Partial<Config>) => {
    const { error } = await db.from("cortes_alertas_config")
      .update({ ...cambios, updated_at: new Date().toISOString() })
      .eq("sucursal_id", sucursalId);
    if (error) return toast.error("No se pudo guardar la configuración de alertas.");
    setConfigs((p) => p.map((c) => (c.sucursal_id === sucursalId ? { ...c, ...cambios } : c)));
  };

  const estadoDe = (s: Sucursal) => {
    if (conCierre.has(s.id)) return { chip: "✅ Cierre registrado", clase: "bg-green-600 hover:bg-green-600" };
    const alerta = alertas.find((a) => a.sucursal_id === s.id);
    if (alerta) return { chip: "❌ Alerta enviada", clase: "bg-destructive hover:bg-destructive" };
    const cfg = configs.find((c) => c.sucursal_id === s.id);
    if (!cfg?.activo) return { chip: "🔕 Sin vigilancia", clase: "" };
    return { chip: "⏳ En tiempo", clase: "bg-amber-500 hover:bg-amber-500" };
  };

  return (
    <Card>
      <CardHeader className="pb-3">
        <CardTitle className="text-lg flex items-center gap-2">
          <Siren className="w-4 h-4" /> Cortes de hoy ({fecha})
        </CardTitle>
        <p className="text-xs text-muted-foreground">
          Si una sucursal pasa su hora límite sin corte de cierre, se avisa una vez al grupo de cajas por WhatsApp (vía Makatea).
        </p>
      </CardHeader>
      <CardContent className="space-y-2">
        {sucursales.map((s) => {
          const cfg = configs.find((c) => c.sucursal_id === s.id);
          const e = estadoDe(s);
          return (
            <div key={s.id} className="flex flex-wrap items-center gap-3 border-b pb-2 last:border-b-0">
              <span className="font-medium w-28">{s.nombre}</span>
              <Badge className={e.clase} variant={e.clase ? "default" : "secondary"}>{e.chip}</Badge>
              {cfg && (
                <div className="flex items-center gap-2 ml-auto">
                  <span className="text-xs text-muted-foreground">Hora límite</span>
                  <Input
                    type="time"
                    className="h-8 w-28"
                    value={cfg.hora_limite.slice(0, 5)}
                    onChange={(ev) => guardar(s.id, { hora_limite: ev.target.value })}
                  />
                  <span className="text-xs text-muted-foreground" title="Hora especial para viernes y sábado (día de negocio). Vacío = usa la hora normal.">Vie/Sáb</span>
                  <Input
                    type="time"
                    className="h-8 w-28"
                    value={cfg.hora_limite_finde?.slice(0, 5) ?? ""}
                    onChange={(ev) => guardar(s.id, { hora_limite_finde: ev.target.value || null })}
                  />
                  <Switch
                    checked={cfg.activo}
                    onCheckedChange={(v) => guardar(s.id, { activo: v })}
                  />
                </div>
              )}
            </div>
          );
        })}
      </CardContent>
    </Card>
  );
}
