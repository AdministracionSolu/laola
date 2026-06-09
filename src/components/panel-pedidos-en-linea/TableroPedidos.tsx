import { useCallback, useEffect } from "react";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { Loader2 } from "lucide-react";
import { toast } from "sonner";
import {
  db,
  type EstadoPedido,
  type PedidoEnLinea,
} from "@/lib/pedidosEnLinea";
import { useAlertaNuevoPedido } from "@/hooks/useAlertaNuevoPedido";
import TarjetaPedido from "./TarjetaPedido";

const ESTADOS_ACTIVOS: EstadoPedido[] = ["nuevo", "confirmado", "preparando", "listo", "en_reparto"];
const SELECT_PEDIDO = "*, pedidos_en_linea_items(*), zonas_reparto(nombre)";

interface Props {
  sucursalId: string;
  sucursalNombre: string;
}

export default function TableroPedidos({ sucursalId, sucursalNombre }: Props) {
  const queryClient = useQueryClient();
  const { iniciar: iniciarAlerta } = useAlertaNuevoPedido();

  const { data: pedidos, isLoading, isError, refetch } = useQuery({
    queryKey: ["panel-pedidos-activos", sucursalId],
    queryFn: async (): Promise<PedidoEnLinea[]> => {
      const { data, error } = await db
        .from("pedidos_en_linea")
        .select(SELECT_PEDIDO)
        .eq("sucursal_id", sucursalId)
        .in("estado", ESTADOS_ACTIVOS)
        .order("created_at", { ascending: true });
      if (error) throw error;
      return (data ?? []) as PedidoEnLinea[];
    },
    refetchInterval: 30_000, // respaldo por si Realtime se cae
  });

  const invalidar = useCallback(() => {
    queryClient.invalidateQueries({ queryKey: ["panel-pedidos-activos", sucursalId] });
    queryClient.invalidateQueries({ queryKey: ["panel-historial", sucursalId] });
  }, [queryClient, sucursalId]);

  // Realtime: pedidos nuevos y cambios de estado de esta sucursal
  useEffect(() => {
    const canal = db
      .channel(`pedidos-en-linea-${sucursalId}`)
      .on(
        "postgres_changes",
        {
          event: "INSERT",
          schema: "public",
          table: "pedidos_en_linea",
          filter: `sucursal_id=eq.${sucursalId}`,
        },
        (payload) => {
          const nuevo = payload.new as PedidoEnLinea;
          invalidar();
          toast.success(`🔔 Pedido nuevo ${nuevo.folio}`, { duration: 10000 });
          iniciarAlerta();
        }
      )
      .on(
        "postgres_changes",
        {
          event: "UPDATE",
          schema: "public",
          table: "pedidos_en_linea",
          filter: `sucursal_id=eq.${sucursalId}`,
        },
        () => invalidar()
      )
      .subscribe();
    return () => {
      void canal.unsubscribe();
    };
  }, [sucursalId, invalidar, iniciarAlerta]);

  const cambiarEstado = useCallback(
    async (pedido: PedidoEnLinea, estado: EstadoPedido, motivo?: string) => {
      const cambios: Record<string, unknown> = { estado };
      if (estado === "cancelado") cambios.motivo_cancelacion = motivo ?? null;
      const { error } = await db
        .from("pedidos_en_linea")
        .update(cambios)
        .eq("id", pedido.id);
      if (error) {
        toast.error(`No se pudo actualizar el pedido: ${error.message}`);
        return;
      }
      invalidar();
    },
    [invalidar]
  );

  if (isLoading) {
    return (
      <div className="flex justify-center py-16">
        <Loader2 className="h-8 w-8 animate-spin text-primary" />
      </div>
    );
  }
  if (isError) {
    return (
      <div className="text-center py-16">
        <p className="text-muted-foreground mb-3">No se pudieron cargar los pedidos.</p>
        <button className="text-primary font-semibold" onClick={() => refetch()}>
          Reintentar
        </button>
      </div>
    );
  }

  const lista = pedidos ?? [];
  // Nuevos primero, luego por orden de llegada
  const ordenados = [...lista].sort((a, b) => {
    if (a.estado === "nuevo" && b.estado !== "nuevo") return -1;
    if (b.estado === "nuevo" && a.estado !== "nuevo") return 1;
    return a.created_at.localeCompare(b.created_at);
  });

  if (ordenados.length === 0) {
    return (
      <div className="text-center py-16 text-muted-foreground">
        <p className="text-4xl mb-2">🌊</p>
        <p className="text-lg">Sin pedidos activos.</p>
        <p className="text-sm">Cuando entre un pedido sonará la alerta.</p>
      </div>
    );
  }

  return (
    <div className="grid gap-3 md:grid-cols-2 xl:grid-cols-3 items-start">
      {ordenados.map((pedido) => (
        <TarjetaPedido
          key={pedido.id}
          pedido={pedido}
          sucursalNombre={sucursalNombre}
          onCambiarEstado={cambiarEstado}
        />
      ))}
    </div>
  );
}
