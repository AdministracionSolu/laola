import { useState, useEffect } from "react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Textarea } from "@/components/ui/textarea";
import { Badge } from "@/components/ui/badge";
import { ArrowLeft, Package, Send, History, Save } from "lucide-react";
import { useNavigate } from "react-router-dom";
import { supabase } from "@/integrations/supabase/client";
import { toast } from "sonner";
import logoLaOla from "@/assets/logo-la-ola.jpeg";
import { Accordion, AccordionContent, AccordionItem, AccordionTrigger } from "@/components/ui/accordion";
import { ScrollArea } from "@/components/ui/scroll-area";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";

interface Sucursal {
  id: string;
  nombre: string;
}

interface Categoria {
  id: string;
  nombre: string;
  orden: number;
}

interface Insumo {
  id: string;
  nombre: string;
  categoria_id: string;
  unidad: string;
}

interface PedidoDetalle {
  insumo_id: string;
  existencia: number;
  cantidad_pedida: number;
}

interface Pedido {
  id: string;
  sucursal_id: string;
  fecha: string;
  estado: string;
  registrado_por: string | null;
  notas: string | null;
  created_at: string;
  sucursales?: { nombre: string };
}

export default function Pedidos() {
  const navigate = useNavigate();
  const [sucursales, setSucursales] = useState<Sucursal[]>([]);
  const [categorias, setCategorias] = useState<Categoria[]>([]);
  const [insumos, setInsumos] = useState<Insumo[]>([]);
  const [sucursalSeleccionada, setSucursalSeleccionada] = useState<string>("");
  const [registradoPor, setRegistradoPor] = useState("");
  const [notas, setNotas] = useState("");
  const [detalles, setDetalles] = useState<Record<string, PedidoDetalle>>({});
  const [isLoading, setIsLoading] = useState(false);
  const [pedidosRecientes, setPedidosRecientes] = useState<Pedido[]>([]);
  const [activeTab, setActiveTab] = useState("nuevo");

  useEffect(() => {
    fetchData();
    fetchPedidosRecientes();
  }, []);

  const fetchData = async () => {
    const [sucursalesRes, categoriasRes, insumosRes] = await Promise.all([
      supabase.from("sucursales").select("*").order("nombre"),
      supabase.from("categorias_insumos").select("*").order("orden"),
      supabase.from("insumos").select("*").eq("activo", true).order("nombre"),
    ]);

    if (sucursalesRes.data) setSucursales(sucursalesRes.data);
    if (categoriasRes.data) setCategorias(categoriasRes.data);
    if (insumosRes.data) setInsumos(insumosRes.data);
  };

  const fetchPedidosRecientes = async () => {
    const { data } = await supabase
      .from("pedidos")
      .select("*, sucursales(nombre)")
      .order("created_at", { ascending: false })
      .limit(10);
    if (data) setPedidosRecientes(data);
  };

  const getInsumosByCategoria = (categoriaId: string) => {
    return insumos.filter((i) => i.categoria_id === categoriaId);
  };

  const updateDetalle = (insumoId: string, field: "existencia" | "cantidad_pedida", value: number) => {
    setDetalles((prev) => ({
      ...prev,
      [insumoId]: {
        ...prev[insumoId],
        insumo_id: insumoId,
        existencia: prev[insumoId]?.existencia || 0,
        cantidad_pedida: prev[insumoId]?.cantidad_pedida || 0,
        [field]: value,
      },
    }));
  };

  const handleSubmit = async () => {
    if (!sucursalSeleccionada) {
      toast.error("Selecciona una sucursal");
      return;
    }

    const detallesConCantidad = Object.values(detalles).filter(
      (d) => d.cantidad_pedida > 0 || d.existencia > 0
    );

    if (detallesConCantidad.length === 0) {
      toast.error("Agrega al menos un insumo al pedido");
      return;
    }

    setIsLoading(true);

    try {
      // Crear pedido
      const { data: pedido, error: pedidoError } = await supabase
        .from("pedidos")
        .insert({
          sucursal_id: sucursalSeleccionada,
          registrado_por: registradoPor || null,
          notas: notas || null,
          estado: "pendiente",
        })
        .select()
        .single();

      if (pedidoError) throw pedidoError;

      // Crear detalles
      const detallesInsert = detallesConCantidad.map((d) => ({
        pedido_id: pedido.id,
        insumo_id: d.insumo_id,
        existencia: d.existencia,
        cantidad_pedida: d.cantidad_pedida,
      }));

      const { error: detallesError } = await supabase
        .from("pedidos_detalle")
        .insert(detallesInsert);

      if (detallesError) throw detallesError;

      toast.success("Pedido registrado correctamente");
      
      // Limpiar formulario
      setDetalles({});
      setNotas("");
      setRegistradoPor("");
      fetchPedidosRecientes();
      setActiveTab("historial");
    } catch (error) {
      console.error("Error:", error);
      toast.error("Error al registrar el pedido");
    } finally {
      setIsLoading(false);
    }
  };

  const getEstadoBadge = (estado: string) => {
    switch (estado) {
      case "pendiente":
        return <Badge variant="secondary">Pendiente</Badge>;
      case "recibido":
        return <Badge variant="default">Recibido</Badge>;
      case "parcial":
        return <Badge variant="outline">Parcial</Badge>;
      default:
        return <Badge variant="outline">{estado}</Badge>;
    }
  };

  const getTotalItems = () => {
    return Object.values(detalles).filter((d) => d.cantidad_pedida > 0).length;
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-primary/5 to-secondary/10">
      {/* Header */}
      <div className="bg-background border-b sticky top-0 z-10">
        <div className="container mx-auto px-3 py-2 flex items-center gap-3">
          <Button
            variant="ghost"
            size="icon"
            onClick={() => navigate("/centro-de-operaciones")}
          >
            <ArrowLeft className="h-5 w-5" />
          </Button>
          <img
            src={logoLaOla}
            alt="La Ola"
            className="w-8 h-8 rounded-full object-cover"
          />
          <div className="flex-1">
            <h1 className="text-base font-semibold">Pedidos</h1>
            <p className="text-xs text-muted-foreground">
              Registrar pedidos de insumos
            </p>
          </div>
          {getTotalItems() > 0 && (
            <Badge variant="default" className="text-sm">
              {getTotalItems()} items
            </Badge>
          )}
        </div>
      </div>

      <div className="container mx-auto px-3 py-4 max-w-2xl">
        <Tabs value={activeTab} onValueChange={setActiveTab}>
          <TabsList className="grid w-full grid-cols-2 mb-4">
            <TabsTrigger value="nuevo" className="gap-2">
              <Package className="h-4 w-4" />
              Nuevo Pedido
            </TabsTrigger>
            <TabsTrigger value="historial" className="gap-2">
              <History className="h-4 w-4" />
              Historial
            </TabsTrigger>
          </TabsList>

          <TabsContent value="nuevo" className="space-y-4">
            {/* Sucursal y Quien Registra */}
            <Card>
              <CardHeader className="pb-3">
                <CardTitle className="text-base">Información</CardTitle>
              </CardHeader>
              <CardContent className="space-y-3">
                <div className="space-y-1.5">
                  <Label className="text-sm">Sucursal *</Label>
                  <Select
                    value={sucursalSeleccionada}
                    onValueChange={setSucursalSeleccionada}
                  >
                    <SelectTrigger>
                      <SelectValue placeholder="Selecciona sucursal" />
                    </SelectTrigger>
                    <SelectContent>
                      {sucursales.map((s) => (
                        <SelectItem key={s.id} value={s.id}>
                          {s.nombre}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>

                <div className="space-y-1.5">
                  <Label className="text-sm">Registrado por</Label>
                  <Input
                    placeholder="Tu nombre"
                    value={registradoPor}
                    onChange={(e) => setRegistradoPor(e.target.value)}
                  />
                </div>

                <div className="space-y-1.5">
                  <Label className="text-sm">Notas</Label>
                  <Textarea
                    placeholder="Observaciones del pedido..."
                    value={notas}
                    onChange={(e) => setNotas(e.target.value)}
                    rows={2}
                  />
                </div>
              </CardContent>
            </Card>

            {/* Lista de Insumos por Categoría */}
            <Card>
              <CardHeader className="pb-3">
                <CardTitle className="text-base">Insumos</CardTitle>
                <CardDescription>
                  Ingresa existencia y cantidad a pedir
                </CardDescription>
              </CardHeader>
              <CardContent className="p-0">
                <ScrollArea className="h-[50vh]">
                  <Accordion type="multiple" className="w-full">
                    {categorias.map((categoria) => {
                      const insumosCategoria = getInsumosByCategoria(categoria.id);
                      if (insumosCategoria.length === 0) return null;

                      const itemsConPedido = insumosCategoria.filter(
                        (i) => detalles[i.id]?.cantidad_pedida > 0
                      ).length;

                      return (
                        <AccordionItem key={categoria.id} value={categoria.id}>
                          <AccordionTrigger className="px-4 py-3 hover:no-underline">
                            <div className="flex items-center gap-2">
                              <span className="font-medium">{categoria.nombre}</span>
                              {itemsConPedido > 0 && (
                                <Badge variant="secondary" className="text-xs">
                                  {itemsConPedido}
                                </Badge>
                              )}
                            </div>
                          </AccordionTrigger>
                          <AccordionContent className="px-4 pb-4">
                            <div className="space-y-3">
                              {/* Header */}
                              <div className="grid grid-cols-12 gap-2 text-xs text-muted-foreground font-medium">
                                <div className="col-span-6">Insumo</div>
                                <div className="col-span-3 text-center">Exist.</div>
                                <div className="col-span-3 text-center">Pedido</div>
                              </div>
                              
                              {insumosCategoria.map((insumo) => (
                                <div
                                  key={insumo.id}
                                  className="grid grid-cols-12 gap-2 items-center"
                                >
                                  <div className="col-span-6 text-sm truncate">
                                    {insumo.nombre}
                                  </div>
                                  <div className="col-span-3">
                                    <Input
                                      type="number"
                                      min="0"
                                      placeholder="0"
                                      className="h-8 text-center text-sm"
                                      value={detalles[insumo.id]?.existencia || ""}
                                      onChange={(e) =>
                                        updateDetalle(
                                          insumo.id,
                                          "existencia",
                                          parseFloat(e.target.value) || 0
                                        )
                                      }
                                    />
                                  </div>
                                  <div className="col-span-3">
                                    <Input
                                      type="number"
                                      min="0"
                                      placeholder="0"
                                      className="h-8 text-center text-sm font-medium"
                                      value={detalles[insumo.id]?.cantidad_pedida || ""}
                                      onChange={(e) =>
                                        updateDetalle(
                                          insumo.id,
                                          "cantidad_pedida",
                                          parseFloat(e.target.value) || 0
                                        )
                                      }
                                    />
                                  </div>
                                </div>
                              ))}
                            </div>
                          </AccordionContent>
                        </AccordionItem>
                      );
                    })}
                  </Accordion>
                </ScrollArea>
              </CardContent>
            </Card>

            {/* Botón Enviar */}
            <Button
              className="w-full h-12 text-base gap-2"
              onClick={handleSubmit}
              disabled={isLoading || !sucursalSeleccionada}
            >
              <Send className="h-5 w-5" />
              {isLoading ? "Enviando..." : "Enviar Pedido"}
            </Button>
          </TabsContent>

          <TabsContent value="historial" className="space-y-3">
            <Card>
              <CardHeader className="pb-3">
                <CardTitle className="text-base">Últimos Pedidos</CardTitle>
              </CardHeader>
              <CardContent className="p-0">
                {pedidosRecientes.length === 0 ? (
                  <div className="p-4 text-center text-muted-foreground text-sm">
                    No hay pedidos registrados
                  </div>
                ) : (
                  <div className="divide-y">
                    {pedidosRecientes.map((pedido) => (
                      <div
                        key={pedido.id}
                        className="p-4 flex items-center justify-between"
                      >
                        <div>
                          <p className="font-medium text-sm">
                            {pedido.sucursales?.nombre}
                          </p>
                          <p className="text-xs text-muted-foreground">
                            {new Date(pedido.created_at).toLocaleDateString("es-MX", {
                              day: "numeric",
                              month: "short",
                              hour: "2-digit",
                              minute: "2-digit",
                            })}
                            {pedido.registrado_por && ` • ${pedido.registrado_por}`}
                          </p>
                        </div>
                        {getEstadoBadge(pedido.estado)}
                      </div>
                    ))}
                  </div>
                )}
              </CardContent>
            </Card>
          </TabsContent>
        </Tabs>
      </div>
    </div>
  );
}
