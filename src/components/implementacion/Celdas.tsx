import { CheckCircle2, XCircle, MinusCircle, Clock, AlertTriangle } from "lucide-react";
import { colorPct } from "./tipos";

export type Estado = "ok" | "parcial" | "falta" | "curso" | "na";

const ICONO: Record<Estado, JSX.Element> = {
  ok: <CheckCircle2 className="h-4 w-4 text-emerald-600" />,
  parcial: <AlertTriangle className="h-4 w-4 text-amber-500" />,
  falta: <XCircle className="h-4 w-4 text-red-500" />,
  curso: <Clock className="h-4 w-4 text-muted-foreground/60" />,
  na: <MinusCircle className="h-4 w-4 text-muted-foreground/30" />,
};

/** Celda de la rejilla: un icono con tooltip nativo (title) que cuenta el detalle. */
export function Celda({ estado, detalle }: { estado: Estado; detalle?: string }) {
  return (
    <div className="flex items-center justify-center" title={detalle}>
      {ICONO[estado]}
    </div>
  );
}

/** Porcentaje grande con su leyenda, coloreado por umbral. */
export function Porcentaje({
  valor,
  leyenda,
  tamano = "md",
}: {
  valor: number | null;
  leyenda?: string;
  tamano?: "sm" | "md" | "lg";
}) {
  const clases = tamano === "lg" ? "text-3xl" : tamano === "sm" ? "text-base" : "text-xl";
  return (
    <div>
      <div className={`font-bold tabular-nums ${clases} ${colorPct(valor)}`}>
        {valor === null ? "—" : `${valor}%`}
      </div>
      {leyenda && <div className="text-xs text-muted-foreground">{leyenda}</div>}
    </div>
  );
}

/** Tarjeta de indicador para la tira de arriba. */
export function Indicador({
  titulo,
  valor,
  leyenda,
  icono,
}: {
  titulo: string;
  valor: number | null | string;
  leyenda?: string;
  icono?: JSX.Element;
}) {
  const esPct = typeof valor === "number" || valor === null;
  return (
    <div className="rounded-lg border bg-card p-4">
      <div className="flex items-center gap-2 text-xs font-medium text-muted-foreground uppercase tracking-wide">
        {icono}
        {titulo}
      </div>
      <div
        className={`mt-2 text-3xl font-bold tabular-nums ${
          esPct ? colorPct(valor as number | null) : ""
        }`}
      >
        {valor === null ? "—" : esPct ? `${valor}%` : valor}
      </div>
      {leyenda && <div className="mt-1 text-xs text-muted-foreground">{leyenda}</div>}
    </div>
  );
}

/** Leyenda de iconos, para que nadie tenga que adivinar qué significa cada marca. */
export function LeyendaIconos() {
  return (
    <div className="flex flex-wrap items-center gap-4 text-xs text-muted-foreground">
      <span className="flex items-center gap-1">{ICONO.ok} Completo</span>
      <span className="flex items-center gap-1">{ICONO.parcial} Incompleto</span>
      <span className="flex items-center gap-1">{ICONO.falta} No se hizo</span>
      <span className="flex items-center gap-1">{ICONO.curso} Día en curso</span>
    </div>
  );
}
