import { useEffect } from "react";
import { Link, useParams } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Check, Clock, Loader2, MapPin, Phone, XCircle } from "lucide-react";
import logoLaOla from "@/assets/logo-la-ola.jpeg";
import { db, dinero, type EstadoPedido } from "@/lib/pedidosEnLinea";

interface PedidoPublico {
  folio: string;
  estado: EstadoPedido;
  tipo: "recoger" | "reparto";
  nombre_cliente: string;
  direccion: string | null;
  referencias: string | null;
  subtotal: number;
  costo_envio: number;
  total: number;
  motivo_cancelacion: string | null;
  created_at: string;
  zona: string | null;
  sucursal: {
    nombre: string;
    direccion: string | null;
    telefono: string | null;
    tiempo_estimado_min: number;
  };
  items: Array<{
    nombre_item: string;
    nombre_variante: string;
    precio_unitario: number;
    cantidad: number;
    opciones_elegidas: Record<string, string> | null;
    notas: string | null;
  }>;
}

const ESTADO_FINAL: EstadoPedido[] = ["entregado", "cancelado"];

function pasosPara(tipo: "recoger" | "reparto"): Array<{ estado: EstadoPedido; etiqueta: string }> {
  return [
    { estado: "nuevo", etiqueta: "Recibido" },
    { estado: "confirmado", etiqueta: "Confirmado" },
    { estado: "preparando", etiqueta: "Preparando" },
    tipo === "reparto"
      ? { estado: "en_reparto" as EstadoPedido, etiqueta: "En reparto" }
      : { estado: "listo" as EstadoPedido, etiqueta: "Listo para recoger" },
    { estado: "entregado", etiqueta: "Entregado" },
  ];
}

function indiceEstado(estado: EstadoPedido, tipo: "recoger" | "reparto"): number {
  const orden: EstadoPedido[] =
    tipo === "reparto"
      ? ["nuevo", "confirmado", "preparando", "listo", "en_reparto", "entregado"]
      : ["nuevo", "confirmado", "preparando", "listo", "entregado"];
  const pasos = pasosPara(tipo);
  const idxReal = orden.indexOf(estado);
  // 'listo' en reparto se muestra dentro del paso "Preparando→En reparto"
  let visible = 0;
  for (let i = 0; i < pasos.length; i++) {
    if (orden.indexOf(pasos[i].estado) <= idxReal) visible = i;
  }
  return visible;
}

export default function SeguimientoPedido() {
  const { token } = useParams();

  const { data: pedido, isLoading, isError, refetch } = useQuery({
    queryKey: ["pedido-token", token],
    enabled: !!token,
    queryFn: async (): Promise<PedidoPublico | null> => {
      const { data, error } = await db.rpc("obtener_pedido_por_token", { p_token: token });
      if (error) throw error;
      return (data as PedidoPublico | null) ?? null;
    },
    // Estado en vivo: se consulta cada 10 s mientras el pedido siga activo
    refetchInterval: (consulta) => {
      const datos = consulta.state.data as PedidoPublico | null | undefined;
      if (datos && ESTADO_FINAL.includes(datos.estado)) return false;
      return 10_000;
    },
  });

  // Refresca al volver a la pestaña (el cliente regresa a checar su pedido)
  useEffect(() => {
    const alVolver = () => {
      if (document.visibilityState === "visible") refetch();
    };
    document.addEventListener("visibilitychange", alVolver);
    return () => document.removeEventListener("visibilitychange", alVolver);
  }, [refetch]);

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <Loader2 className="h-8 w-8 animate-spin text-primary" />
      </div>
    );
  }

  if (isError || !pedido) {
    return (
      <div className="min-h-screen flex flex-col items-center justify-center gap-3 p-4 text-center">
        <p className="text-muted-foreground">
          {isError ? "No pudimos cargar tu pedido." : "No encontramos este pedido."}
        </p>
        {isError && <Button onClick={() => refetch()}>Reintentar</Button>}
        <Link to="/ordenar" className="text-primary font-semibold">Hacer un pedido</Link>
      </div>
    );
  }

  const pasos = pasosPara(pedido.tipo);
  const idxActual = indiceEstado(pedido.estado, pedido.tipo);
  const cancelado = pedido.estado === "cancelado";

  return (
    <div className="min-h-screen bg-gradient-to-br from-primary/5 to-secondary/10">
      <div className="max-w-lg mx-auto p-4 pb-12">
        <div className="flex flex-col items-center text-center pt-6 mb-5">
          <div className="w-16 h-16 rounded-full overflow-hidden mb-3">
            <img src={logoLaOla} alt="La Ola" className="w-full h-full object-cover" />
          </div>
          <p className="text-muted-foreground">Tu pedido</p>
          <h1 className="text-4xl font-extrabold tracking-wide">{pedido.folio}</h1>
          {!cancelado && pedido.estado !== "entregado" && (
            <p className="text-muted-foreground flex items-center gap-1 mt-1">
              <Clock className="h-4 w-4" />
              Tiempo estimado: {pedido.sucursal.tiempo_estimado_min} min
            </p>
          )}
          <p className="text-xs text-muted-foreground mt-2">
            Guarda esta página: es tu comprobante.
          </p>
        </div>

        {/* Estado */}
        <Card className="mb-4">
          <CardContent className="p-5">
            {cancelado ? (
              <div className="flex items-center gap-3 text-destructive">
                <XCircle className="h-8 w-8 shrink-0" />
                <div>
                  <p className="font-bold text-lg">Pedido cancelado</p>
                  {pedido.motivo_cancelacion && (
                    <p className="text-sm">{pedido.motivo_cancelacion}</p>
                  )}
                  {pedido.sucursal.telefono && (
                    <a href={`tel:${pedido.sucursal.telefono}`} className="text-sm text-primary font-semibold">
                      ¿Dudas? Llámanos al {pedido.sucursal.telefono}
                    </a>
                  )}
                </div>
              </div>
            ) : (
              <ol className="space-y-0">
                {pasos.map((paso, i) => {
                  const completado = i < idxActual;
                  const actual = i === idxActual;
                  return (
                    <li key={paso.estado} className="flex gap-3">
                      <div className="flex flex-col items-center">
                        <div
                          className={`h-8 w-8 rounded-full flex items-center justify-center border-2 shrink-0 ${
                            completado
                              ? "bg-primary border-primary text-primary-foreground"
                              : actual
                                ? "border-primary text-primary"
                                : "border-muted-foreground/30 text-muted-foreground/40"
                          }`}
                        >
                          {completado ? (
                            <Check className="h-4 w-4" />
                          ) : actual ? (
                            <span className="h-2.5 w-2.5 rounded-full bg-primary animate-pulse" />
                          ) : (
                            <span className="text-xs">{i + 1}</span>
                          )}
                        </div>
                        {i < pasos.length - 1 && (
                          <div className={`w-0.5 h-6 ${completado ? "bg-primary" : "bg-muted-foreground/20"}`} />
                        )}
                      </div>
                      <p
                        className={`pt-1 font-medium ${
                          actual ? "text-primary font-bold" : completado ? "" : "text-muted-foreground/60"
                        }`}
                      >
                        {paso.etiqueta}
                      </p>
                    </li>
                  );
                })}
              </ol>
            )}
          </CardContent>
        </Card>

        {/* Sucursal */}
        <Card className="mb-4">
          <CardContent className="p-5 space-y-1">
            <p className="font-bold">
              {pedido.tipo === "recoger" ? "Recoges en" : "Te lo lleva"} {pedido.sucursal.nombre}
            </p>
            {pedido.sucursal.direccion && (
              <p className="text-sm text-muted-foreground flex items-center gap-1">
                <MapPin className="h-3.5 w-3.5 shrink-0" /> {pedido.sucursal.direccion}
              </p>
            )}
            {pedido.sucursal.telefono && (
              <a
                href={`tel:${pedido.sucursal.telefono}`}
                className="text-sm text-primary font-semibold flex items-center gap-1"
              >
                <Phone className="h-3.5 w-3.5 shrink-0" /> {pedido.sucursal.telefono}
              </a>
            )}
            {pedido.tipo === "reparto" && pedido.direccion && (
              <p className="text-sm text-muted-foreground pt-1">
                Entrega en: {pedido.direccion}
                {pedido.zona ? ` (${pedido.zona})` : ""}
              </p>
            )}
          </CardContent>
        </Card>

        {/* Resumen */}
        <Card>
          <CardContent className="p-5 space-y-2">
            {pedido.items.map((item, i) => (
              <div key={i} className="flex justify-between gap-3 text-sm">
                <div>
                  <p className="font-medium">
                    {item.cantidad}× {item.nombre_item}
                    {item.nombre_variante !== "Única" ? ` (${item.nombre_variante})` : ""}
                  </p>
                  {item.opciones_elegidas && (
                    <p className="text-muted-foreground">
                      {Object.values(item.opciones_elegidas).join(" · ")}
                    </p>
                  )}
                  {item.notas && <p className="text-muted-foreground italic">“{item.notas}”</p>}
                </div>
                <p className="whitespace-nowrap">{dinero(item.precio_unitario * item.cantidad)}</p>
              </div>
            ))}
            <div className="border-t pt-2 flex justify-between text-sm">
              <span>Subtotal</span>
              <span>{dinero(pedido.subtotal)}</span>
            </div>
            {Number(pedido.costo_envio) > 0 && (
              <div className="flex justify-between text-sm">
                <span>Envío</span>
                <span>{dinero(pedido.costo_envio)}</span>
              </div>
            )}
            <div className="flex justify-between font-bold text-lg">
              <span>Total</span>
              <span>{dinero(pedido.total)}</span>
            </div>
            <p className="text-sm text-muted-foreground">
              {pedido.tipo === "recoger"
                ? "Pagas al recoger (efectivo o tarjeta)."
                : "Pagas al recibir (efectivo o tarjeta)."}
            </p>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
