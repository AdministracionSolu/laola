import { useEffect, useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Minus, Plus } from "lucide-react";

interface CantidadStepperProps {
  value: number;
  onChange: (value: number) => void;
  /** Solo define de cuánto son los brincos de los botones: "kg" de medio, el resto de uno. */
  unidad?: string | null;
  className?: string;
  /** Estilo destacado (ej. campo "Pides"). */
  emphasis?: boolean;
}

/** Quita el ruido de coma flotante: 10.299999999 → 10.3 */
const limpiaDecimales = (n: number) => Math.round(n * 1000) / 1000;

export function CantidadStepper({
  value,
  onChange,
  unidad,
  className,
  emphasis,
}: CantidadStepperProps) {
  // Los botones brincan de medio en kg y de uno en piezas, pero lo que se
  // escribe a mano se respeta tal cual: 10.3 kg de callo es un dato válido.
  const step = (unidad || "").toLowerCase() === "kg" ? 0.5 : 1;

  // El texto vive aparte del número para no estorbar mientras se teclea:
  // "10." es un estado intermedio legítimo camino a "10.3".
  const [texto, setTexto] = useState(value ? String(value) : "");

  useEffect(() => {
    const n = parseFloat(texto);
    if ((Number.isFinite(n) ? n : 0) !== value) setTexto(value ? String(value) : "");
    // Solo cuando el valor cambia desde afuera (reset del formulario, carga).
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [value]);

  const escribir = (crudo: string) => {
    // Acepta coma o punto, un solo separador, sin negativos.
    const soloNumeros = crudo.replace(",", ".").replace(/[^\d.]/g, "");
    const partes = soloNumeros.split(".");
    const normalizado =
      partes.length > 2 ? `${partes[0]}.${partes.slice(1).join("")}` : soloNumeros;
    setTexto(normalizado);
    const n = parseFloat(normalizado);
    onChange(Number.isFinite(n) ? n : 0);
  };

  const mover = (delta: number) => {
    const n = Math.max(0, limpiaDecimales(value + delta));
    setTexto(n ? String(n) : "");
    onChange(n);
  };

  return (
    <div className={`flex items-center gap-2 ${className || ""}`}>
      <Button
        type="button"
        variant="outline"
        size="icon"
        className="h-12 w-12 shrink-0 rounded-full"
        onClick={() => mover(-step)}
        aria-label="Restar"
      >
        <Minus className="h-5 w-5" />
      </Button>
      <Input
        type="text"
        inputMode="decimal"
        value={texto}
        placeholder="0"
        onChange={(e) => escribir(e.target.value)}
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
        onClick={() => mover(step)}
        aria-label="Sumar"
      >
        <Plus className="h-5 w-5" />
      </Button>
    </div>
  );
}
