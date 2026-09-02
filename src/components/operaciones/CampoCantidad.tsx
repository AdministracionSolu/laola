import { useEffect, useState } from "react";
import { Input } from "@/components/ui/input";

/**
 * Tope de captura de cantidades. Nadie recibe ni tiene 100 kg de un insumo:
 * medido sobre todo el histórico, el máximo real fueron 80 kg de pulpo y le
 * sigue 60. Lo que pasó de ahí resultó ser un dedazo — 800 de atún, 60,470 de
 * camarón, 7,600 de sierra (gramos tecleados como kilos).
 */
export const MAXIMO = 99;

/**
 * Deja el texto en un número válido: acepta coma o punto y no pasa del tope.
 *
 * Lo que pasa del tope se PEGA en 99, no se recorta a los primeros dígitos:
 * recortar 7300 a "73" deja un número plausible que nadie vuelve a mirar,
 * mientras que un 99 pegado se ve raro y se corrige. "7." es un estado
 * intermedio legítimo camino a "7.3" y por eso el texto se devuelve tal cual.
 */
export function normalizaCantidad(crudo: string, max = MAXIMO) {
  const limpio = crudo.replace(",", ".").replace(/[^\d.]/g, "");
  const partes = limpio.split(".");
  let texto = partes.length > 2 ? `${partes[0]}.${partes.slice(1).join("")}` : limpio;
  const n0 = parseFloat(texto);
  if (Number.isFinite(n0) && n0 > max) texto = String(max);
  const n = parseFloat(texto);
  return { texto, valor: Number.isFinite(n) ? n : 0 };
}

interface Props {
  value: number;
  onChange: (v: number) => void;
  className?: string;
  ariaLabel?: string;
  max?: number;
}

/**
 * Campo de cantidad para las tablas de revisión (existencia, a comprar,
 * recibido). El texto vive aparte del número: "7." es un estado intermedio
 * legítimo camino a "7.3", y sin esa memoria la coma se traga y el siguiente
 * dígito se pega — "7,3" acababa siendo 73.
 */
export function CampoCantidad({ value, onChange, className, ariaLabel, max = MAXIMO }: Props) {
  const [texto, setTexto] = useState(String(value ?? 0));

  useEffect(() => {
    const n = parseFloat(texto);
    if ((Number.isFinite(n) ? n : 0) !== value) setTexto(String(value ?? 0));
    // Sólo cuando el valor cambia desde afuera (recarga, guardado).
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [value]);

  return (
    <Input
      type="text"
      inputMode="decimal"
      maxLength={6}
      aria-label={ariaLabel}
      value={texto}
      onFocus={(e) => e.target.select()}
      onChange={(e) => {
        const { texto: t, valor } = normalizaCantidad(e.target.value, max);
        setTexto(t);
        onChange(valor);
      }}
      className={className}
    />
  );
}
