import {
  Drawer,
  DrawerContent,
  DrawerFooter,
  DrawerHeader,
  DrawerTitle,
} from "@/components/ui/drawer";
import { Button } from "@/components/ui/button";
import { Minus, Plus, ShoppingBag, Trash2 } from "lucide-react";
import { dinero, type LineaCarrito } from "@/lib/pedidosEnLinea";

interface PropsBarra {
  numItems: number;
  subtotal: number;
  onVerCarrito: () => void;
}

/** Barra inferior fija y persistente mientras hay items en el carrito. */
export function CarritoBar({ numItems, subtotal, onVerCarrito }: PropsBarra) {
  if (numItems === 0) return null;
  return (
    <div className="fixed bottom-0 inset-x-0 z-40 p-3 pb-[calc(env(safe-area-inset-bottom)+0.75rem)] bg-gradient-to-t from-background via-background to-transparent">
      <Button
        className="w-full h-14 text-lg font-bold shadow-lg gap-3"
        onClick={onVerCarrito}
      >
        <ShoppingBag className="h-5 w-5" />
        Ver carrito · {numItems} {numItems === 1 ? "item" : "items"} · {dinero(subtotal)}
      </Button>
    </div>
  );
}

interface PropsSheet {
  abierto: boolean;
  onCerrar: () => void;
  lineas: LineaCarrito[];
  subtotal: number;
  onCambiarCantidad: (uid: string, cantidad: number) => void;
  onQuitar: (uid: string) => void;
  onContinuar: () => void;
}

export function CarritoSheet({
  abierto,
  onCerrar,
  lineas,
  subtotal,
  onCambiarCantidad,
  onQuitar,
  onContinuar,
}: PropsSheet) {
  const hayAgotados = lineas.some((l) => l.agotado);
  return (
    <Drawer open={abierto} onOpenChange={(v) => !v && onCerrar()}>
      <DrawerContent className="max-h-[90dvh]">
        <DrawerHeader className="text-left pb-2">
          <DrawerTitle className="text-xl">Tu pedido</DrawerTitle>
        </DrawerHeader>
        <div className="overflow-y-auto px-4 space-y-3 pb-2">
          {lineas.length === 0 && (
            <p className="text-center text-muted-foreground py-8">Tu carrito está vacío.</p>
          )}
          {lineas.map((linea) => (
            <div
              key={linea.uid}
              className={`rounded-lg border p-3 ${linea.agotado ? "border-destructive bg-destructive/5" : ""}`}
            >
              <div className="flex items-start justify-between gap-2">
                <div className="min-w-0">
                  <p className="font-semibold leading-tight">{linea.nombre_item}</p>
                  <p className="text-sm text-muted-foreground">
                    {linea.nombre_variante !== "Única" ? linea.nombre_variante : ""}
                    {linea.opciones_elegidas &&
                      Object.values(linea.opciones_elegidas).map((v) => ` · ${v}`)}
                  </p>
                  {linea.notas && (
                    <p className="text-sm text-muted-foreground italic">“{linea.notas}”</p>
                  )}
                  {linea.agotado && (
                    <p className="text-sm font-semibold text-destructive mt-1">
                      Se agotó — quítalo para continuar
                    </p>
                  )}
                </div>
                <p className="font-semibold whitespace-nowrap">
                  {dinero(linea.precio * linea.cantidad)}
                </p>
              </div>
              <div className="flex items-center justify-between mt-2">
                <Button
                  variant="ghost"
                  size="sm"
                  className="text-destructive gap-1 px-2"
                  onClick={() => onQuitar(linea.uid)}
                >
                  <Trash2 className="h-4 w-4" /> Quitar
                </Button>
                <div className="flex items-center gap-3">
                  <Button
                    variant="outline"
                    size="icon"
                    className="h-10 w-10 rounded-full"
                    onClick={() => onCambiarCantidad(linea.uid, linea.cantidad - 1)}
                    aria-label="Quitar uno"
                  >
                    <Minus className="h-4 w-4" />
                  </Button>
                  <span className="font-bold w-6 text-center">{linea.cantidad}</span>
                  <Button
                    variant="outline"
                    size="icon"
                    className="h-10 w-10 rounded-full"
                    onClick={() => onCambiarCantidad(linea.uid, linea.cantidad + 1)}
                    aria-label="Agregar uno"
                  >
                    <Plus className="h-4 w-4" />
                  </Button>
                </div>
              </div>
            </div>
          ))}
        </div>
        <DrawerFooter className="pt-2">
          <div className="flex items-center justify-between text-lg font-bold px-1">
            <span>Subtotal</span>
            <span>{dinero(subtotal)}</span>
          </div>
          <Button
            className="h-14 text-lg font-bold"
            disabled={lineas.length === 0 || hayAgotados}
            onClick={onContinuar}
          >
            Continuar
          </Button>
          {hayAgotados && (
            <p className="text-sm text-center text-destructive">
              Quita los productos agotados para continuar.
            </p>
          )}
        </DrawerFooter>
      </DrawerContent>
    </Drawer>
  );
}
