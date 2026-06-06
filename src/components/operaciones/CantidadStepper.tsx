import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Minus, Plus } from "lucide-react";

interface CantidadStepperProps {
  value: number;
  onChange: (value: number) => void;
  /** "kg" permite medios; "pz"/"bolsa" enteros. */
  unidad?: string | null;
  className?: string;
  /** Estilo destacado (ej. campo "Pides"). */
  emphasis?: boolean;
}

export function CantidadStepper({
  value,
  onChange,
  unidad,
  className,
  emphasis,
}: CantidadStepperProps) {
  const permiteDecimales = (unidad || "").toLowerCase() === "kg";
  const step = permiteDecimales ? 0.5 : 1;

  const round = (n: number) => {
    const r = permiteDecimales ? Math.round(n * 2) / 2 : Math.round(n);
    return Math.max(0, r);
  };

  const set = (n: number) => onChange(round(n));

  return (
    <div className={`flex items-center gap-2 ${className || ""}`}>
      <Button
        type="button"
        variant="outline"
        size="icon"
        className="h-12 w-12 shrink-0 rounded-full"
        onClick={() => set(value - step)}
        aria-label="Restar"
      >
        <Minus className="h-5 w-5" />
      </Button>
      <Input
        type="number"
        inputMode="decimal"
        min="0"
        step={step}
        value={value === 0 ? "" : value}
        placeholder="0"
        onChange={(e) => set(parseFloat(e.target.value) || 0)}
        onFocus={(e) => e.target.select()}
        className={`h-12 text-center ${
          emphasis ? "text-2xl font-bold" : "text-xl font-semibold"
        }`}
      />
      <Button
        type="button"
        variant="outline"
        size="icon"
        className="h-12 w-12 shrink-0 rounded-full"
        onClick={() => set(value + step)}
        aria-label="Sumar"
      >
        <Plus className="h-5 w-5" />
      </Button>
    </div>
  );
}
