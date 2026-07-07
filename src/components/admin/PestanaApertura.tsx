import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import {
  Banknote,
  ChevronLeft,
  ChevronRight,
  Store,
  Sunrise,
  CheckCircle2,
  AlertCircle,
  Clock,
  RotateCcw,
  MapPin,
} from "lucide-react";
import { format, parseISO } from "date-fns";
import { es } from "date-fns/locale";
import { useApertura } from "@/hooks/useApertura";

interface PestanaAperturaProps {
  formatMoney: (value: number) => string;
}

export function PestanaApertura({ formatMoney }: PestanaAperturaProps) {
  const {
    porPlaza,
    totalCaja,
    totalVendido,
    reportadas,
    sinReporte,
    totalSucursales,
    fechaObjetivo,
    esDiaAnterior,
    puedeAvanzar,
    isLoading,
    irDiaAnterior,
    irDiaSiguiente,
    volverADiaAnterior,
  } = useApertura();

  const fechaLarga = format(fechaObjetivo, "EEEE d 'de' MMMM", { locale: es });
  const fechaCapitalizada = fechaLarga.charAt(0).toUpperCase() + fechaLarga.slice(1);

  if (isLoading) {
    return (
      <div className="flex items-center justify-center py-16">
        <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-primary" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Encabezado + navegador de día */}
      <Card>
        <CardHeader className="pb-3">
          <div className="flex flex-col gap-1">
            <CardTitle className="text-xl flex items-center gap-2">
              <Sunrise className="w-5 h-5 text-primary" />
              Con cuánto amanecimos
            </CardTitle>
            <p className="text-sm text-muted-foreground">
              Efectivo en caja (Corte X) con el que cada sucursal cerró y amaneció.
            </p>
          </div>
        </CardHeader>
        <CardContent>
          <div className="flex flex-wrap items-center justify-between gap-3">
            <div className="flex items-center gap-2">
              <Button variant="outline" size="icon" onClick={irDiaAnterior} aria-label="Día anterior">
                <ChevronLeft className="w-4 h-4" />
              </Button>
              <div className="min-w-[180px] text-center">
                <p className="font-semibold leading-tight">{fechaCapitalizada}</p>
                <p className="text-xs text-muted-foreground">
                  {esDiaAnterior ? "Cierre del día anterior" : "Día seleccionado"}
                </p>
              </div>
              <Button
                variant="outline"
                size="icon"
                onClick={irDiaSiguiente}
                disabled={!puedeAvanzar}
                aria-label="Día siguiente"
              >
                <ChevronRight className="w-4 h-4" />
              </Button>
            </div>

            {!esDiaAnterior && (
              <Button variant="ghost" size="sm" onClick={volverADiaAnterior} className="gap-2">
                <RotateCcw className="w-4 h-4" />
                Volver a ayer
              </Button>
            )}
          </div>
        </CardContent>
      </Card>

      {/* Total en cajas */}
      <Card className="border-primary/40 bg-primary/5">
        <CardContent className="pt-6">
          <div className="flex flex-wrap items-end justify-between gap-4">
            <div>
              <p className="text-sm text-muted-foreground flex items-center gap-2">
                <Banknote className="w-4 h-4 text-primary" />
                Efectivo total en cajas
              </p>
              <p className="text-4xl font-bold text-primary mt-1">{formatMoney(totalCaja)}</p>
              <p className="text-xs text-muted-foreground mt-1">
                Suma del Corte X de las {reportadas} sucursal{reportadas === 1 ? "" : "es"} que reportaron.
              </p>
            </div>
            <div className="flex flex-col gap-1 text-sm">
              <span className="flex items-center gap-2">
                <CheckCircle2 className="w-4 h-4 text-green-500" />
                <strong>{reportadas}</strong> de {totalSucursales} reportaron
              </span>
              {sinReporte > 0 && (
                <span className="flex items-center gap-2 text-muted-foreground">
                  <AlertCircle className="w-4 h-4 text-amber-500" />
                  <strong>{sinReporte}</strong> sin reportar
                </span>
              )}
              {totalVendido > 0 && (
                <span className="text-xs text-muted-foreground mt-1">
                  Vendido ese día: {formatMoney(totalVendido)}
                </span>
              )}
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Desglose por plaza (ciudad): la operación no es la misma en cada una */}
      {porPlaza.length > 1 && (
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          {porPlaza.map((p) => (
            <Card key={p.plaza}>
              <CardContent className="pt-6">
                <p className="text-sm text-muted-foreground flex items-center gap-2">
                  <MapPin className="w-4 h-4 text-primary" />
                  Efectivo en {p.plaza}
                </p>
                <p className="text-3xl font-bold mt-1">{formatMoney(p.totalCaja)}</p>
                <p className="text-xs text-muted-foreground mt-1">
                  {p.sucursales.map((s) => s.nombre).join(" · ")}
                </p>
                <p className="text-xs text-muted-foreground mt-1">
                  {p.reportadas} de {p.sucursales.length} reportaron
                  {p.sinReporte > 0 ? ` · ${p.sinReporte} sin dato` : ""}
                </p>
              </CardContent>
            </Card>
          ))}
        </div>
      )}

      {/* Tarjetas por sucursal, agrupadas por plaza */}
      {porPlaza.map((p) => (
        <div key={p.plaza} className="space-y-3">
          <h3 className="text-sm font-semibold text-muted-foreground flex items-center gap-2">
            <MapPin className="w-4 h-4" />
            {p.plaza}
          </h3>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {p.sucursales.map((s) => (
              <Card
                key={s.sucursal_id}
                className={
                  s.reportado
                    ? "border-green-500/40"
                    : "border-dashed border-amber-500/40 bg-muted/30"
                }
              >
                <CardHeader className="pb-2">
                  <div className="flex items-center justify-between">
                    <CardTitle className="text-base flex items-center gap-2">
                      <Store className="w-4 h-4" />
                      {s.nombre}
                    </CardTitle>
                    {s.reportado ? (
                      <Badge className="bg-green-600">Cerró</Badge>
                    ) : (
                      <Badge variant="secondary">Sin dato</Badge>
                    )}
                  </div>
                </CardHeader>
                <CardContent>
                  {s.reportado ? (
                    <div className="space-y-2">
                      <div>
                        <p className="text-xs text-muted-foreground">Amaneció con (Corte X)</p>
                        <p className="text-2xl font-bold text-primary">
                          {formatMoney(s.corte_x || 0)}
                        </p>
                      </div>
                      <div className="flex items-center justify-between text-xs text-muted-foreground pt-2 border-t">
                        <span>Vendió {formatMoney(s.total || 0)}</span>
                        {s.hora_cierre && (
                          <span className="flex items-center gap-1">
                            <Clock className="w-3 h-3" />
                            {format(parseISO(s.hora_cierre), "HH:mm", { locale: es })}
                          </span>
                        )}
                      </div>
                    </div>
                  ) : (
                    <div className="py-3">
                      <p className="text-sm font-medium text-amber-600 dark:text-amber-500">
                        Dato no reportado
                      </p>
                      <p className="text-xs text-muted-foreground mt-1">
                        No hay corte de cierre registrado para este día.
                      </p>
                    </div>
                  )}
                </CardContent>
              </Card>
            ))}
          </div>
        </div>
      ))}
    </div>
  );
}
