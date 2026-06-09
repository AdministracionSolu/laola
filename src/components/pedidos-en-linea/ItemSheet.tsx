import { useEffect, useState } from "react";
import {
  Drawer,
  DrawerContent,
  DrawerDescription,
  DrawerFooter,
  DrawerHeader,
  DrawerTitle,
} from "@/components/ui/drawer";
import { Button } from "@/components/ui/button";
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Minus, Plus } from "lucide-react";
import { dinero } from "@/lib/pedidosEnLinea";
import type { ItemConVariantes } from "@/hooks/useMenuEnLinea";

interface Props {
  item: ItemConVariantes | null;
  abierto: boolean;
  onCerrar: () => void;
  onAgregar: (
    item: ItemConVariantes,
    varianteId: string,
    cantidad: number,
    opciones: Record<string, string> | null,
    notas: string | null
  ) => void;
}

export default function ItemSheet({ item, abierto, onCerrar, onAgregar }: Props) {
  const [varianteId, setVarianteId] = useState<string>("");
  const [opciones, setOpciones] = useState<Record<string, string>>({});
  const [notas, setNotas] = useState("");
  const [cantidad, setCantidad] = useState(1);

  useEffect(() => {
    if (!item) return;
    setVarianteId(item.variantes[0]?.id ?? "");
    // Preselecciona la primera opción de cada grupo (un solo tap para lo común)
    const iniciales: Record<string, string> = {};
    for (const [grupo, valores] of Object.entries(item.opciones ?? {})) {
      if (valores.length > 0) iniciales[grupo] = valores[0];
    }
    setOpciones(iniciales);
    setNotas("");
    setCantidad(1);
  }, [item]);

  if (!item) return null;

  const variante = item.variantes.find((v) => v.id === varianteId) ?? item.variantes[0];
  const total = (variante?.precio ?? 0) * cantidad;
  const grupos = Object.entries(item.opciones ?? {});

  const agregar = () => {
    if (!variante) return;
    onAgregar(item, variante.id, cantidad, grupos.length > 0 ? opciones : null, notas.trim() || null);
    onCerrar();
  };

  return (
    <Drawer open={abierto} onOpenChange={(v) => !v && onCerrar()}>
      <DrawerContent className="max-h-[90dvh]">
        <div className="overflow-y-auto">
          <DrawerHeader className="text-left pb-2">
            <DrawerTitle className="text-xl">{item.nombre}</DrawerTitle>
            {item.descripcion && (
              <DrawerDescription className="text-base">{item.descripcion}</DrawerDescription>
            )}
          </DrawerHeader>

          <div className="px-4 space-y-5 pb-2">
            {/* Variantes (tamaños) */}
            {item.variantes.length > 1 && (
              <div>
                <p className="font-semibold mb-2">Tamaño</p>
                <RadioGroup value={varianteId} onValueChange={setVarianteId} className="gap-2">
                  {item.variantes.map((v) => (
                    <Label
                      key={v.id}
                      htmlFor={`var-${v.id}`}
                      className="flex items-center justify-between rounded-lg border p-4 text-base cursor-pointer has-[[data-state=checked]]:border-primary has-[[data-state=checked]]:bg-primary/5"
                    >
                      <span className="flex items-center gap-3">
                        <RadioGroupItem value={v.id} id={`var-${v.id}`} />
                        {v.nombre}
                      </span>
                      <span className="font-semibold">{dinero(v.precio)}</span>
                    </Label>
                  ))}
                </RadioGroup>
              </div>
            )}

            {/* Grupos de opciones del item (jsonb) */}
            {grupos.map(([grupo, valores]) => (
              <div key={grupo}>
                <p className="font-semibold mb-2 capitalize">{grupo}</p>
                <RadioGroup
                  value={opciones[grupo] ?? ""}
                  onValueChange={(v) => setOpciones((prev) => ({ ...prev, [grupo]: v }))}
                  className="gap-2"
                >
                  {valores.map((valor) => (
                    <Label
                      key={valor}
                      htmlFor={`op-${grupo}-${valor}`}
                      className="flex items-center gap-3 rounded-lg border p-4 text-base cursor-pointer has-[[data-state=checked]]:border-primary has-[[data-state=checked]]:bg-primary/5"
                    >
                      <RadioGroupItem value={valor} id={`op-${grupo}-${valor}`} />
                      {valor}
                    </Label>
                  ))}
                </RadioGroup>
              </div>
            ))}

            {/* Notas */}
            <div>
              <p className="font-semibold mb-2">Notas (opcional)</p>
              <Textarea
                placeholder='Ej. "sin cebolla"'
                value={notas}
                onChange={(e) => setNotas(e.target.value)}
                maxLength={200}
                className="text-base"
              />
            </div>

            {/* Cantidad */}
            <div className="flex items-center justify-center gap-6">
              <Button
                variant="outline"
                size="icon"
                className="h-12 w-12 rounded-full"
                onClick={() => setCantidad((c) => Math.max(1, c - 1))}
                aria-label="Quitar uno"
              >
                <Minus className="h-5 w-5" />
              </Button>
              <span className="text-2xl font-bold w-10 text-center">{cantidad}</span>
              <Button
                variant="outline"
                size="icon"
                className="h-12 w-12 rounded-full"
                onClick={() => setCantidad((c) => Math.min(99, c + 1))}
                aria-label="Agregar uno"
              >
                <Plus className="h-5 w-5" />
              </Button>
            </div>
          </div>
        </div>

        <DrawerFooter className="pt-2">
          <Button className="h-14 text-lg font-bold" onClick={agregar}>
            Agregar {dinero(total)}
          </Button>
        </DrawerFooter>
      </DrawerContent>
    </Drawer>
  );
}
