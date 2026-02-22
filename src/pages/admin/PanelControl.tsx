import { useState, useEffect } from "react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { ArrowLeft, RefreshCw, Package, Truck, CalendarDays, DollarSign, Users, FileUp } from "lucide-react";
import { useNavigate } from "react-router-dom";
import { supabase } from "@/integrations/supabase/client";
import { toast } from "sonner";
import logoLaOla from "@/assets/logo-la-ola.jpeg";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { CargaHistorica } from "@/components/admin/CargaHistorica";
import { ScrollArea } from "@/components/ui/scroll-area";
import { format } from "date-fns";
import { es } from "date-fns/locale";
import { AdminCorteDialog } from "@/components/admin/AdminCorteDialog";

interface Sucursal {
  id: string;
  nombre: string;
}

interface Pedido {
  id: string;
  sucursal_id: string;
  fecha: string;
  estado: string;
  registrado_por: string | null;
  created_at: string;
  sucursales?: { nombre: string };
}

interface PedidoDetalle {
  id: string;
  pedido_id: string;
  insumo_id: string;
  existencia: number;
  cantidad_pedida: number;
  insumos?: { nombre: string; categoria_id: string };
}

interface Recepcion {
  id: string;
  sucursal_id: string;
  proveedor: string;
  fecha: string;
  created_at: string;
  sucursales?: { nombre: string };
}

interface RecepcionDetalle {
  id: string;
  recepcion_id: string;
  insumo_id: string;
  cantidad_recibida: number;
  insumos?: { nombre: string };
}

interface Reservacion {
  id: string;
  sucursal_id: string;
  fecha: string;
  hora: string;
  nombre_cliente: string;
  num_personas: number;
  estado: string;
  sucursales?: { nombre: string };
  zonas_sucursal?: { nombre: string };
}

interface Corte {
  id: string;
  sucursal_id: string;
  fecha_venta: string;
  total: number;
  sucursales?: { nombre: string };
}

export default function PanelControl() {
  const navigate = useNavigate();
  const [sucursales, setSucursales] = useState<Sucursal[]>([]);
  const [pedidos, setPedidos] = useState<Pedido[]>([]);
  const [pedidosDetalle, setPedidosDetalle] = useState<PedidoDetalle[]>([]);
  const [recepciones, setRecepciones] = useState<Recepcion[]>([]);
  const [recepcionesDetalle, setRecepcionesDetalle] = useState<RecepcionDetalle[]>([]);
  const [reservacionesHoy, setReservacionesHoy] = useState<Reservacion[]>([]);
  const [cortesHoy, setCortesHoy] = useState<Corte[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [pedidoSeleccionado, setPedidoSeleccionado] = useState<string | null>(null);

  const hoy = format(new Date(), "yyyy-MM-dd");

  useEffect(() => {
    checkAuth();
    fetchData();
  }, []);

  const checkAuth = async () => {
    const { data: { session } } = await supabase.auth.getSession();
    if (!session) {
      navigate("/admin/login");
    }
  };

  const fetchData = async () => {
    setIsLoading(true);
    
    const [
      sucursalesRes,
      pedidosRes,
      recepcionesRes,
      reservacionesRes,
      cortesRes
    ] = await Promise.all([
      supabase.from("sucursales").select("*").order("nombre"),
      supabase.from("pedidos").select("*, sucursales(nombre)").order("created_at", { ascending: false }).limit(50),
      supabase.from("recepciones").select("*, sucursales(nombre)").order("created_at", { ascending: false }).limit(50),
      supabase.from("reservaciones").select("*, sucursales(nombre), zonas_sucursal(nombre)").eq("fecha", hoy).order("hora"),
      supabase.from("cortes_caja").select("*, sucursales(nombre)").eq("fecha_venta", hoy),
    ]);

    if (sucursalesRes.data) setSucursales(sucursalesRes.data);
    if (pedidosRes.data) setPedidos(pedidosRes.data);
    if (recepcionesRes.data) setRecepciones(recepcionesRes.data);
    if (reservacionesRes.data) setReservacionesHoy(reservacionesRes.data);
    if (cortesRes.data) setCortesHoy(cortesRes.data);

    setIsLoading(false);
  };

  const fetchPedidoDetalle = async (pedidoId: string) => {
    setPedidoSeleccionado(pedidoId);
    const { data } = await supabase
      .from("pedidos_detalle")
      .select("*, insumos(nombre, categoria_id)")
      .eq("pedido_id", pedidoId);
    if (data) setPedidosDetalle(data);
  };

  const handleRefresh = () => {
    fetchData();
    toast.success("Datos actualizados");
  };

  // Estadísticas
  const pedidosPendientes = pedidos.filter(p => p.estado === "pendiente").length;
  const recepcionesHoy = recepciones.filter(r => r.fecha === hoy).length;
  const totalReservasHoy = reservacionesHoy.length;
  const personasEsperadas = reservacionesHoy.reduce((acc, r) => acc + r.num_personas, 0);
  const ventasHoy = cortesHoy.reduce((acc, c) => acc + Number(c.total), 0);

  const formatMoney = (amount: number) => {
    return new Intl.NumberFormat("es-MX", {
      style: "currency",
      currency: "MXN",
    }).format(amount);
  };

  const getEstadoBadge = (estado: string) => {
    switch (estado) {
      case "pendiente":
        return <Badge variant="secondary">Pendiente</Badge>;
      case "recibido":
        return <Badge variant="default">Recibido</Badge>;
      case "parcial":
        return <Badge variant="outline">Parcial</Badge>;
      case "confirmada":
        return <Badge variant="default">Confirmada</Badge>;
      case "cancelada":
        return <Badge variant="destructive">Cancelada</Badge>;
      default:
        return <Badge variant="outline">{estado}</Badge>;
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-primary/5 to-secondary/10">
      {/* Header */}
      <div className="bg-background border-b sticky top-0 z-10">
        <div className="container mx-auto px-3 py-2 flex items-center gap-3">
          <Button
            variant="ghost"
            size="icon"
            onClick={() => navigate("/admin/dashboard")}
          >
            <ArrowLeft className="h-5 w-5" />
          </Button>
          <img
            src={logoLaOla}
            alt="La Ola"
            className="w-8 h-8 rounded-full object-cover"
          />
          <div className="flex-1">
            <h1 className="text-base font-semibold">Panel de Control</h1>
            <p className="text-xs text-muted-foreground">
              Vista general del negocio
            </p>
          </div>
          <AdminCorteDialog onSuccess={fetchData} />
          <Button variant="ghost" size="icon" onClick={handleRefresh}>
            <RefreshCw className="h-4 w-4" />
          </Button>
        </div>
      </div>

      <div className="container mx-auto px-3 py-4 max-w-4xl">
        {/* Estadísticas Rápidas */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-3 mb-4">
          <Card>
            <CardContent className="p-3">
              <div className="flex items-center gap-2">
                <Package className="h-4 w-4 text-primary" />
                <span className="text-xs text-muted-foreground">Pedidos Pend.</span>
              </div>
              <p className="text-xl font-bold mt-1">{pedidosPendientes}</p>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="p-3">
              <div className="flex items-center gap-2">
                <Truck className="h-4 w-4 text-primary" />
                <span className="text-xs text-muted-foreground">Recepciones Hoy</span>
              </div>
              <p className="text-xl font-bold mt-1">{recepcionesHoy}</p>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="p-3">
              <div className="flex items-center gap-2">
                <Users className="h-4 w-4 text-primary" />
                <span className="text-xs text-muted-foreground">Reservas Hoy</span>
              </div>
              <p className="text-xl font-bold mt-1">{totalReservasHoy}</p>
              <p className="text-xs text-muted-foreground">{personasEsperadas} personas</p>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="p-3">
              <div className="flex items-center gap-2">
                <DollarSign className="h-4 w-4 text-primary" />
                <span className="text-xs text-muted-foreground">Ventas Hoy</span>
              </div>
              <p className="text-xl font-bold mt-1">{formatMoney(ventasHoy)}</p>
            </CardContent>
          </Card>
        </div>

        <Tabs defaultValue="pedidos">
          <TabsList className="grid w-full grid-cols-4 mb-4">
            <TabsTrigger value="pedidos" className="gap-1 text-xs">
              <Package className="h-3 w-3" />
              Pedidos
            </TabsTrigger>
            <TabsTrigger value="recepciones" className="gap-1 text-xs">
              <Truck className="h-3 w-3" />
              Recepciones
            </TabsTrigger>
            <TabsTrigger value="reservaciones" className="gap-1 text-xs">
              <CalendarDays className="h-3 w-3" />
              Reservas
            </TabsTrigger>
            <TabsTrigger value="carga" className="gap-1 text-xs">
              <FileUp className="h-3 w-3" />
              Carga
            </TabsTrigger>
          </TabsList>

          {/* Tab Pedidos */}
          <TabsContent value="pedidos">
            <div className="grid md:grid-cols-2 gap-4">
              {/* Lista de Pedidos */}
              <Card>
                <CardHeader className="pb-2">
                  <CardTitle className="text-sm">Pedidos Recientes</CardTitle>
                </CardHeader>
                <CardContent className="p-0">
                  <ScrollArea className="h-[50vh]">
                    <div className="divide-y">
                      {pedidos.map((pedido) => (
                        <div
                          key={pedido.id}
                          className={`p-3 cursor-pointer hover:bg-muted/50 transition-colors ${
                            pedidoSeleccionado === pedido.id ? "bg-muted" : ""
                          }`}
                          onClick={() => fetchPedidoDetalle(pedido.id)}
                        >
                          <div className="flex items-center justify-between mb-1">
                            <p className="font-medium text-sm">
                              {pedido.sucursales?.nombre}
                            </p>
                            {getEstadoBadge(pedido.estado)}
                          </div>
                          <p className="text-xs text-muted-foreground">
                            {format(new Date(pedido.created_at), "dd MMM, HH:mm", { locale: es })}
                            {pedido.registrado_por && ` • ${pedido.registrado_por}`}
                          </p>
                        </div>
                      ))}
                    </div>
                  </ScrollArea>
                </CardContent>
              </Card>

              {/* Detalle del Pedido Seleccionado */}
              <Card>
                <CardHeader className="pb-2">
                  <CardTitle className="text-sm">Detalle del Pedido</CardTitle>
                </CardHeader>
                <CardContent className="p-0">
                  {pedidoSeleccionado ? (
                    <ScrollArea className="h-[50vh]">
                      <div className="p-3 space-y-2">
                        {pedidosDetalle
                          .filter(d => d.cantidad_pedida > 0)
                          .map((detalle) => (
                            <div
                              key={detalle.id}
                              className="flex items-center justify-between text-sm py-1 border-b border-dashed"
                            >
                              <span className="truncate flex-1">
                                {detalle.insumos?.nombre}
                              </span>
                              <div className="flex items-center gap-3 text-right">
                                <span className="text-xs text-muted-foreground">
                                  Exist: {detalle.existencia}
                                </span>
                                <Badge variant="outline">
                                  {detalle.cantidad_pedida}
                                </Badge>
                              </div>
                            </div>
                          ))}
                      </div>
                    </ScrollArea>
                  ) : (
                    <div className="p-8 text-center text-muted-foreground text-sm">
                      Selecciona un pedido para ver el detalle
                    </div>
                  )}
                </CardContent>
              </Card>
            </div>
          </TabsContent>

          {/* Tab Recepciones */}
          <TabsContent value="recepciones">
            <Card>
              <CardHeader className="pb-2">
                <CardTitle className="text-sm">Recepciones Recientes</CardTitle>
                <CardDescription className="text-xs">
                  Entregas de proveedores registradas
                </CardDescription>
              </CardHeader>
              <CardContent className="p-0">
                <ScrollArea className="h-[50vh]">
                  <div className="divide-y">
                    {recepciones.map((recepcion) => (
                      <div key={recepcion.id} className="p-3">
                        <div className="flex items-center justify-between mb-1">
                          <p className="font-medium text-sm">{recepcion.proveedor}</p>
                          <Badge variant="outline" className="text-xs">
                            {recepcion.sucursales?.nombre}
                          </Badge>
                        </div>
                        <p className="text-xs text-muted-foreground">
                          {format(new Date(recepcion.created_at), "dd MMM, HH:mm", { locale: es })}
                        </p>
                      </div>
                    ))}
                  </div>
                </ScrollArea>
              </CardContent>
            </Card>
          </TabsContent>

          {/* Tab Reservaciones */}
          <TabsContent value="reservaciones">
            <Card>
              <CardHeader className="pb-2">
                <CardTitle className="text-sm flex items-center gap-2">
                  <CalendarDays className="h-4 w-4" />
                  Reservaciones de Hoy
                </CardTitle>
                <CardDescription className="text-xs">
                  {totalReservasHoy} reservas • {personasEsperadas} personas esperadas
                </CardDescription>
              </CardHeader>
              <CardContent className="p-0">
                {reservacionesHoy.length === 0 ? (
                  <div className="p-8 text-center text-muted-foreground text-sm">
                    No hay reservaciones para hoy
                  </div>
                ) : (
                  <ScrollArea className="h-[50vh]">
                    <div className="divide-y">
                      {reservacionesHoy.map((reservacion) => (
                        <div key={reservacion.id} className="p-3">
                          <div className="flex items-center justify-between mb-1">
                            <div className="flex items-center gap-2">
                              <span className="font-medium text-sm">{reservacion.hora}</span>
                              <span className="text-sm">{reservacion.nombre_cliente}</span>
                            </div>
                            <div className="flex items-center gap-2">
                              <Badge variant="outline" className="text-xs">
                                {reservacion.num_personas} pax
                              </Badge>
                              {getEstadoBadge(reservacion.estado)}
                            </div>
                          </div>
                          <p className="text-xs text-muted-foreground">
                            {reservacion.sucursales?.nombre} • {reservacion.zonas_sucursal?.nombre}
                          </p>
                        </div>
                      ))}
                    </div>
                  </ScrollArea>
                )}
              </CardContent>
            </Card>
          </TabsContent>
          {/* Tab Carga Histórica */}
          <TabsContent value="carga">
            <CargaHistorica />
          </TabsContent>
        </Tabs>
      </div>
    </div>
  );
}
