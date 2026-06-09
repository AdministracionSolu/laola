import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import { Loader2 } from "lucide-react";
import {
  db,
  dinero,
  ETIQUETA_ESTADO,
  type PedidoEnLinea,
} from "@/lib/pedidosEnLinea";

function hoyLocal(): string {
  const ahora = new Date();
  const mes = String(ahora.getMonth() + 1).padStart(2, "0");
  const dia = String(ahora.getDate()).padStart(2, "0");
  return `${ahora.getFullYear()}-${mes}-${dia}`;
}

export default function HistorialPedidos({ sucursalId }: { sucursalId: string }) {
  const [fecha, setFecha] = useState(hoyLocal());

  const { data: pedidos, isLoading } = useQuery({
    queryKey: ["panel-historial", sucursalId, fecha],
    queryFn: async (): Promise<PedidoEnLinea[]> => {
      // Rango del día en hora local del dispositivo (el staff está en la sucursal)
      const inicio = new Date(`${fecha}T00:00:00`);
      const fin = new Date(inicio.getTime() + 24 * 60 * 60 * 1000);
      const { data, error } = await db
        .from("pedidos_en_linea")
        .select("*, pedidos_en_linea_items(*), zonas_reparto(nombre)")
        .eq("sucursal_id", sucursalId)
        .gte("created_at", inicio.toISOString())
        .lt("created_at", fin.toISOString())
        .order("created_at", { ascending: false });
      if (error) throw error;
      return (data ?? []) as PedidoEnLinea[];
    },
  });

  const lista = pedidos ?? [];
  const validos = lista.filter((p) => p.estado !== "cancelado");
  const ventaTotal = validos.reduce((acc, p) => acc + Number(p.total), 0);
  const ticketPromedio = validos.length > 0 ? ventaTotal / validos.length : 0;

  return (
    <div className="space-y-4">
      <div className="flex items-center gap-3">
        <Input
          type="date"
          value={fecha}
          onChange={(e) => setFecha(e.target.value)}
          className="h-11 w-44 text-base"
        />
      </div>

      {/* Totales del día */}
      <div className="grid grid-cols-3 gap-3">
        <Card>
          <CardContent className="p-4 text-center">
            <p className="text-2xl font-extrabold">{validos.length}</p>
            <p className="text-xs text-muted-foreground">Pedidos</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4 text-center">
            <p className="text-2xl font-extrabold">{dinero(ventaTotal)}</p>
            <p className="text-xs text-muted-foreground">Venta total</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4 text-center">
            <p className="text-2xl font-extrabold">{dinero(ticketPromedio)}</p>
            <p className="text-xs text-muted-foreground">Ticket promedio</p>
          </CardContent>
        </Card>
      </div>

      {isLoading ? (
        <div className="flex justify-center py-10">
          <Loader2 className="h-8 w-8 animate-spin text-primary" />
        </div>
      ) : lista.length === 0 ? (
        <p className="text-center text-muted-foreground py-10">Sin pedidos en esta fecha.</p>
      ) : (
        <div className="space-y-2">
          {lista.map((pedido) => (
            <Card key={pedido.id} className={pedido.estado === "cancelado" ? "opacity-60" : ""}>
              <CardContent className="p-3 flex items-center justify-between gap-3">
                <div className="min-w-0">
                  <p className="font-bold">
                    {pedido.folio}{" "}
                    <span className="font-normal text-muted-foreground">
                      · {pedido.nombre_cliente} ·{" "}
                      {new Date(pedido.created_at).toLocaleTimeString("es-MX", {
                        hour: "2-digit",
                        minute: "2-digit",
                      })}
                    </span>
                  </p>
                  <p className="text-sm text-muted-foreground truncate">
                    {(pedido.pedidos_en_linea_items ?? [])
                      .map((i) => `${i.cantidad}× ${i.nombre_item}`)
                      .join(", ")}
                  </p>
                  {pedido.estado === "cancelado" && pedido.motivo_cancelacion && (
                    <p className="text-sm text-destructive">Cancelado: {pedido.motivo_cancelacion}</p>
                  )}
                </div>
                <div className="text-right shrink-0">
                  <p className="font-bold">{dinero(pedido.total)}</p>
                  <Badge variant={pedido.estado === "cancelado" ? "destructive" : "secondary"}>
                    {ETIQUETA_ESTADO[pedido.estado]}
                  </Badge>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}
