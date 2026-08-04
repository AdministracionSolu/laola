import { useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Switch } from "@/components/ui/switch";
import { Input } from "@/components/ui/input";
import { CreditCard, Send, Settings2, Store, CheckCircle2 } from "lucide-react";
import { format, parseISO } from "date-fns";
import { useTerminalesDia } from "@/hooks/useTerminalesDia";

/**
 * Terminales del día, dentro de la Apertura: qué terminal punto de venta
 * usa hoy cada sucursal. A la hora configurada (11:00 de Tepic por
 * omisión) sale solo al grupo de cajas por WhatsApp, vía Makatea.
 *
 * Dos modos en la misma reja de botones:
 *   - normal:  qué usa HOY cada sucursal
 *   - ajustes: qué terminal TIENE cada sucursal (Espiral solo en Valle)
 */
export function TerminalesDelDia() {
  const {
    terminales,
    porSucursal,
    hayCaptura,
    config,
    enviadoHoy,
    mensaje,
    isLoading,
    enviando,
    alternarHoy,
    alternarDisponible,
    guardarConfig,
    enviarAhora,
  } = useTerminalesDia();

  const [modoAjustes, setModoAjustes] = useState(false);

  if (isLoading) return null;

  return (
    <Card>
      <CardHeader className="pb-3">
        <div className="flex flex-wrap items-start justify-between gap-3">
          <div>
            <CardTitle className="text-xl flex items-center gap-2">
              <CreditCard className="w-5 h-5 text-primary" />
              Terminales de hoy
            </CardTitle>
            <p className="text-sm text-muted-foreground mt-1">
              Qué terminal punto de venta usa hoy cada sucursal. A las{" "}
              {config?.hora?.slice(0, 5) ?? "11:00"} hora de Tepic se manda solo al grupo de cajas.
            </p>
          </div>
          <Button
            variant={modoAjustes ? "default" : "ghost"}
            size="sm"
            className="gap-2"
            onClick={() => setModoAjustes((v) => !v)}
          >
            <Settings2 className="w-4 h-4" />
            {modoAjustes ? "Listo" : "Qué tiene cada una"}
          </Button>
        </div>
      </CardHeader>

      <CardContent className="space-y-5">
        {modoAjustes && (
          <p className="text-xs text-muted-foreground bg-muted/50 rounded-md p-3">
            Estás editando qué terminales <strong>tiene</strong> cada sucursal, no las de hoy. Solo
            las que enciendas aquí aparecen como opción cada mañana.
          </p>
        )}

        {/* Una fila por sucursal, con sus terminales como botones */}
        <div className="space-y-3">
          {porSucursal.map((s) => {
            const opciones = modoAjustes ? terminales : terminales.filter((t) => s.disponibles.includes(t.id));
            return (
              <div
                key={s.id}
                className="flex flex-wrap items-center gap-3 border-b pb-3 last:border-b-0 last:pb-0"
              >
                <span className="font-medium w-32 flex items-center gap-2">
                  <Store className="w-4 h-4 text-muted-foreground" />
                  {s.nombre}
                </span>

                <div className="flex flex-wrap gap-2">
                  {opciones.length === 0 && (
                    <span className="text-xs text-amber-600 dark:text-amber-500">
                      Sin terminales dadas de alta
                    </span>
                  )}
                  {opciones.map((t) => {
                    const activa = modoAjustes ? s.disponibles.includes(t.id) : s.hoy.includes(t.id);
                    return (
                      <Button
                        key={t.id}
                        type="button"
                        size="sm"
                        variant={activa ? "default" : "outline"}
                        className="h-8"
                        onClick={() =>
                          modoAjustes ? alternarDisponible(s.id, t.id) : alternarHoy(s.id, t.id)
                        }
                      >
                        {t.nombre}
                      </Button>
                    );
                  })}
                </div>

                {!modoAjustes && s.hoy.length === 0 && s.disponibles.length > 0 && (
                  <Badge variant="secondary" className="ml-auto">
                    Sin asignar
                  </Badge>
                )}
              </div>
            );
          })}
        </div>

        {!modoAjustes && !hayCaptura && (
          <p className="text-sm text-amber-600 dark:text-amber-500 bg-amber-500/10 rounded-md p-3">
            Nadie ha marcado terminales para hoy. Mientras esté así no sale ningún mensaje al grupo.
          </p>
        )}

        {/* Lo que va a llegar al grupo, tal cual */}
        {!modoAjustes && mensaje && (
          <div className="rounded-md border bg-muted/40 p-3">
            <p className="text-xs text-muted-foreground mb-2">
              Así llega al grupo de cajas. Los asteriscos ponen el nombre en negritas en WhatsApp.
            </p>
            <pre className="text-sm whitespace-pre-wrap font-sans leading-relaxed">{mensaje}</pre>
          </div>
        )}

        {/* Hora, interruptor y envío manual */}
        <div className="flex flex-wrap items-center gap-3 pt-1">
          <div className="flex items-center gap-2">
            <span className="text-xs text-muted-foreground">Hora (Tepic)</span>
            <Input
              type="time"
              className="h-8 w-28"
              value={config?.hora?.slice(0, 5) ?? "11:00"}
              onChange={(e) => e.target.value && guardarConfig({ hora: e.target.value })}
            />
          </div>
          <div className="flex items-center gap-2">
            <Switch
              checked={config?.activo ?? false}
              onCheckedChange={(v) => guardarConfig({ activo: v })}
            />
            <span className="text-xs text-muted-foreground">Aviso automático</span>
          </div>

          <div className="flex items-center gap-3 ml-auto">
            {enviadoHoy && (
              <span className="text-xs text-muted-foreground flex items-center gap-1">
                <CheckCircle2 className="w-3.5 h-3.5 text-green-500" />
                Enviado hoy {format(parseISO(enviadoHoy.created_at), "HH:mm")}
              </span>
            )}
            <Button
              size="sm"
              variant="outline"
              className="gap-2"
              disabled={enviando || !hayCaptura}
              onClick={enviarAhora}
            >
              <Send className="w-4 h-4" />
              {enviadoHoy ? "Reenviar" : "Enviar ahora"}
            </Button>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
