import { useEffect, useState } from "react";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent } from "@/components/ui/card";
import {
  Dialog,
  DialogContent,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Textarea } from "@/components/ui/textarea";
import { Bike, Check, Phone, Printer, Store, X } from "lucide-react";
import {
  dinero,
  ETIQUETA_ESTADO,
  MOTIVOS_CANCELACION,
  siguienteEstado,
  type EstadoPedido,
  type PedidoEnLinea,
} from "@/lib/pedidosEnLinea";
import { imprimirTicket } from "./ticket";

const ETIQUETA_ACCION: Partial<Record<EstadoPedido, string>> = {
  confirmado: "CONFIRMAR",
  preparando: "PREPARANDO",
  listo: "LISTO",
  en_reparto: "SALIÓ A REPARTO",
  entregado: "ENTREGADO",
};

const COLOR_ESTADO: Record<string, string> = {
  nuevo: "bg-coral text-white",
  confirmado: "bg-ocean text-white",
  preparando: "bg-amber-500 text-white",
  listo: "bg-green-600 text-white",
  en_reparto: "bg-purple-600 text-white",
};

function minutosTranscurridos(desde: string): number {
  return Math.floor((Date.now() - new Date(desde).getTime()) / 60000);
}

interface Props {
  pedido: PedidoEnLinea;
  sucursalNombre: string;
  onCambiarEstado: (pedido: PedidoEnLinea, estado: EstadoPedido, motivo?: string) => Promise<void>;
}

export default function TarjetaPedido({ pedido, sucursalNombre, onCambiarEstado }: Props) {
  const [cancelando, setCancelando] = useState(false);
  const [motivo, setMotivo] = useState<string>("");
  const [motivoOtro, setMotivoOtro] = useState("");
  const [guardando, setGuardando] = useState(false);
  // re-render cada 30 s para el tiempo transcurrido
  const [, setTic] = useState(0);
  useEffect(() => {
    const id = window.setInterval(() => setTic((t) => t + 1), 30_000);
    return () => window.clearInterval(id);
  }, []);

  const minutos = minutosTranscurridos(pedido.created_at);
  const urgente = pedido.estado === "nuevo" && minutos > 10;
  const siguiente = siguienteEstado(pedido.estado, pedido.tipo);

  const avanzar = async () => {
    if (!siguiente || guardando) return;
    setGuardando(true);
    try {
      await onCambiarEstado(pedido, siguiente);
    } finally {
      setGuardando(false);
    }
  };

  const cancelar = async () => {
    const motivoFinal = motivo === "Otro" ? motivoOtro.trim() || "Otro" : motivo;
    if (!motivoFinal || guardando) return;
    setGuardando(true);
    try {
      await onCambiarEstado(pedido, "cancelado", motivoFinal);
      setCancelando(false);
    } finally {
      setGuardando(false);
    }
  };

  return (
    <Card className={urgente ? "border-destructive border-2" : pedido.estado === "nuevo" ? "border-coral border-2" : ""}>
      <CardContent className="p-4 space-y-3">
        {/* Encabezado */}
        <div className="flex items-start justify-between gap-2">
          <div>
            <div className="flex items-center gap-2 flex-wrap">
              <span className="text-xl font-extrabold">{pedido.folio}</span>
              <Badge className={COLOR_ESTADO[pedido.estado] ?? ""}>
                {ETIQUETA_ESTADO[pedido.estado]}
              </Badge>
            </div>
            <p className={`text-sm ${urgente ? "text-destructive font-bold" : "text-muted-foreground"}`}>
              hace {minutos} min
              {urgente ? " · ¡ATENDER YA!" : ""}
            </p>
          </div>
          <div className="flex items-center gap-1 text-sm font-medium shrink-0">
            {pedido.tipo === "reparto" ? (
              <>
                <Bike className="h-4 w-4 text-purple-600" /> Reparto
              </>
            ) : (
              <>
                <Store className="h-4 w-4 text-ocean" /> Recoger
              </>
            )}
          </div>
        </div>

        {/* Cliente */}
        <div className="text-sm">
          <p className="font-semibold">{pedido.nombre_cliente}</p>
          <a
            href={`tel:${pedido.telefono}`}
            className="text-primary font-semibold inline-flex items-center gap-1"
          >
            <Phone className="h-3.5 w-3.5" /> {pedido.telefono}
          </a>
          {pedido.tipo === "reparto" && (
            <p className="text-muted-foreground mt-1">
              {pedido.zonas_reparto?.nombre ? `${pedido.zonas_reparto.nombre} · ` : ""}
              {pedido.direccion}
              {pedido.referencias ? ` · Ref: ${pedido.referencias}` : ""}
            </p>
          )}
        </div>

        {/* Items */}
        <div className="rounded-md bg-muted/50 p-3 space-y-1.5">
          {(pedido.pedidos_en_linea_items ?? []).map((item) => (
            <div key={item.id} className="flex justify-between gap-2 text-sm">
              <div>
                <span className="font-bold">{item.cantidad}×</span> {item.nombre_item}
                {item.nombre_variante !== "Única" && (
                  <span className="text-muted-foreground"> ({item.nombre_variante})</span>
                )}
                {item.opciones_elegidas && (
                  <span className="text-ocean font-medium">
                    {" "}
                    · {Object.values(item.opciones_elegidas).join(" · ")}
                  </span>
                )}
                {item.notas && <p className="text-amber-700 italic">“{item.notas}”</p>}
              </div>
              <span className="whitespace-nowrap text-muted-foreground">
                {dinero(item.precio_unitario * item.cantidad)}
              </span>
            </div>
          ))}
          {pedido.notas_generales && (
            <p className="text-sm text-amber-700 italic border-t pt-1">“{pedido.notas_generales}”</p>
          )}
          <div className="flex justify-between font-bold border-t pt-1.5">
            <span>Total {Number(pedido.costo_envio) > 0 ? `(envío ${dinero(pedido.costo_envio)})` : ""}</span>
            <span>{dinero(pedido.total)}</span>
          </div>
        </div>

        {/* Acciones de un tap */}
        <div className="flex gap-2">
          {siguiente && (
            <Button
              className="flex-1 h-14 text-base font-bold gap-2"
              disabled={guardando}
              onClick={avanzar}
            >
              <Check className="h-5 w-5" />
              {ETIQUETA_ACCION[siguiente]}
            </Button>
          )}
          <Button
            variant="outline"
            size="icon"
            className="h-14 w-14 shrink-0"
            onClick={() => imprimirTicket(pedido, sucursalNombre)}
            aria-label="Imprimir ticket"
          >
            <Printer className="h-5 w-5" />
          </Button>
          {pedido.estado !== "entregado" && pedido.estado !== "cancelado" && (
            <Button
              variant="outline"
              size="icon"
              className="h-14 w-14 shrink-0 text-destructive hover:text-destructive"
              onClick={() => setCancelando(true)}
              aria-label="Cancelar pedido"
            >
              <X className="h-5 w-5" />
            </Button>
          )}
        </div>
      </CardContent>

      {/* Cancelación con motivo */}
      <Dialog open={cancelando} onOpenChange={setCancelando}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Cancelar pedido {pedido.folio}</DialogTitle>
          </DialogHeader>
          <div className="space-y-3">
            <Select value={motivo} onValueChange={setMotivo}>
              <SelectTrigger className="h-12 text-base">
                <SelectValue placeholder="¿Por qué se cancela?" />
              </SelectTrigger>
              <SelectContent>
                {MOTIVOS_CANCELACION.map((m) => (
                  <SelectItem key={m} value={m} className="text-base">
                    {m}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
            {motivo === "Otro" && (
              <Textarea
                value={motivoOtro}
                onChange={(e) => setMotivoOtro(e.target.value)}
                placeholder="Escribe el motivo"
                maxLength={200}
              />
            )}
          </div>
          <DialogFooter className="gap-2">
            <Button variant="outline" onClick={() => setCancelando(false)}>
              Volver
            </Button>
            <Button variant="destructive" disabled={!motivo || guardando} onClick={cancelar}>
              Cancelar pedido
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </Card>
  );
}
