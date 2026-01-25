import { useState, useEffect } from "react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Textarea } from "@/components/ui/textarea";
import { Badge } from "@/components/ui/badge";
import { ArrowLeft, Truck, Check, History, Package } from "lucide-react";
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

interface RecepcionDetalle {
  insumo_id: string;
  cantidad_recibida: number;
}

interface Recepcion {
  id: string;
  sucursal_id: string;
  proveedor: string;
  fecha: string;
  registrado_por: string | null;
  notas: string | null;
  created_at: string;
  sucursales?: { nombre: string };
}

const PROVEEDORES = [
  "Pescadería",
  "Abarrotes General",
  "Frutas y Verduras",
  "Desechables",
  "Limpieza",
  "Carnes",
  "Otro",
];

export default function Recepciones() {
  const navigate = useNavigate();
  const [sucursales, setSucursales] = useState<Sucursal[]>([]);
  const [categorias, setCategorias] = useState<Categoria[]>([]);
  const [insumos, setInsumos] = useState<Insumo[]>([]);
  const [sucursalSeleccionada, setSucursalSeleccionada] = useState<string>("");
  const [proveedor, setProveedor] = useState("");
  const [registradoPor, setRegistradoPor] = useState("");
  const [notas, setNotas] = useState("");
  const [detalles, setDetalles] = useState<Record<string, RecepcionDetalle>>({});
  const [isLoading, setIsLoading] = useState(false);
  const [recepcionesRecientes, setRecepcionesRecientes] = useState<Recepcion[]>([]);
  const [activeTab, setActiveTab] = useState("nuevo");

  useEffect(() => {
    fetchData();
    fetchRecepcionesRecientes();
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

  const fetchRecepcionesRecientes = async () => {
    const { data } = await supabase
      .from("recepciones")
      .select("*, sucursales(nombre)")
      .order("created_at", { ascending: false })
      .limit(10);
    if (data) setRecepcionesRecientes(data);
  };

  const getInsumosByCategoria = (categoriaId: string) => {
    return insumos.filter((i) => i.categoria_id === categoriaId);
  };

  const updateDetalle = (insumoId: string, cantidad: number) => {
    if (cantidad <= 0) {
      const newDetalles = { ...detalles };
      delete newDetalles[insumoId];
      setDetalles(newDetalles);
    } else {
      setDetalles((prev) => ({
        ...prev,
        [insumoId]: {
          insumo_id: insumoId,
          cantidad_recibida: cantidad,
        },
      }));
    }
  };

  const handleSubmit = async () => {
    if (!sucursalSeleccionada) {
      toast.error("Selecciona una sucursal");
      return;
    }

    if (!proveedor) {
      toast.error("Selecciona un proveedor");
      return;
    }

    const detallesConCantidad = Object.values(detalles).filter(
      (d) => d.cantidad_recibida > 0
    );

    if (detallesConCantidad.length === 0) {
      toast.error("Registra al menos un insumo recibido");
      return;
    }

    setIsLoading(true);

    try {
      // Crear recepción
      const { data: recepcion, error: recepcionError } = await supabase
        .from("recepciones")
        .insert({
          sucursal_id: sucursalSeleccionada,
          proveedor,
          registrado_por: registradoPor || null,
          notas: notas || null,
        })
        .select()
        .single();

      if (recepcionError) throw recepcionError;

      // Crear detalles
      const detallesInsert = detallesConCantidad.map((d) => ({
        recepcion_id: recepcion.id,
        insumo_id: d.insumo_id,
        cantidad_recibida: d.cantidad_recibida,
      }));

      const { error: detallesError } = await supabase
        .from("recepciones_detalle")
        .insert(detallesInsert);

      if (detallesError) throw detallesError;

      toast.success("Recepción registrada correctamente");
      
      // Limpiar formulario
      setDetalles({});
      setNotas("");
      setRegistradoPor("");
      setProveedor("");
      fetchRecepcionesRecientes();
      setActiveTab("historial");
    } catch (error) {
      console.error("Error:", error);
      toast.error("Error al registrar la recepción");
    } finally {
      setIsLoading(false);
    }
  };

  const getTotalItems = () => {
    return Object.values(detalles).filter((d) => d.cantidad_recibida > 0).length;
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
            <h1 className="text-base font-semibold">Recepción de Mercancía</h1>
            <p className="text-xs text-muted-foreground">
              Registrar llegada de proveedores
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
              <Truck className="h-4 w-4" />
              Nueva Recepción
            </TabsTrigger>
            <TabsTrigger value="historial" className="gap-2">
              <History className="h-4 w-4" />
              Historial
            </TabsTrigger>
          </TabsList>

          <TabsContent value="nuevo" className="space-y-4">
            {/* Información de recepción */}
            <Card>
              <CardHeader className="pb-3">
                <CardTitle className="text-base">Información</CardTitle>
              </CardHeader>
              <CardContent className="space-y-3">
                <div className="grid grid-cols-2 gap-3">
                  <div className="space-y-1.5">
                    <Label className="text-sm">Sucursal *</Label>
                    <Select
                      value={sucursalSeleccionada}
                      onValueChange={setSucursalSeleccionada}
                    >
                      <SelectTrigger>
                        <SelectValue placeholder="Sucursal" />
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
                    <Label className="text-sm">Proveedor *</Label>
                    <Select value={proveedor} onValueChange={setProveedor}>
                      <SelectTrigger>
                        <SelectValue placeholder="Proveedor" />
                      </SelectTrigger>
                      <SelectContent>
                        {PROVEEDORES.map((p) => (
                          <SelectItem key={p} value={p}>
                            {p}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>
                </div>

                <div className="space-y-1.5">
                  <Label className="text-sm">Recibido por</Label>
                  <Input
                    placeholder="Tu nombre"
                    value={registradoPor}
                    onChange={(e) => setRegistradoPor(e.target.value)}
                  />
                </div>

                <div className="space-y-1.5">
                  <Label className="text-sm">Notas</Label>
                  <Textarea
                    placeholder="Observaciones de la entrega..."
                    value={notas}
                    onChange={(e) => setNotas(e.target.value)}
                    rows={2}
                  />
                </div>
              </CardContent>
            </Card>

            {/* Lista de Insumos */}
            <Card>
              <CardHeader className="pb-3">
                <CardTitle className="text-base">Insumos Recibidos</CardTitle>
                <CardDescription>
                  Ingresa las cantidades recibidas
                </CardDescription>
              </CardHeader>
              <CardContent className="p-0">
                <ScrollArea className="h-[45vh]">
                  <Accordion type="multiple" className="w-full">
                    {categorias.map((categoria) => {
                      const insumosCategoria = getInsumosByCategoria(categoria.id);
                      if (insumosCategoria.length === 0) return null;

                      const itemsRecibidos = insumosCategoria.filter(
                        (i) => detalles[i.id]?.cantidad_recibida > 0
                      ).length;

                      return (
                        <AccordionItem key={categoria.id} value={categoria.id}>
                          <AccordionTrigger className="px-4 py-3 hover:no-underline">
                            <div className="flex items-center gap-2">
                              <span className="font-medium">{categoria.nombre}</span>
                              {itemsRecibidos > 0 && (
                                <Badge variant="default" className="text-xs">
                                  {itemsRecibidos}
                                </Badge>
                              )}
                            </div>
                          </AccordionTrigger>
                          <AccordionContent className="px-4 pb-4">
                            <div className="space-y-3">
                              {/* Header */}
                              <div className="grid grid-cols-12 gap-2 text-xs text-muted-foreground font-medium">
                                <div className="col-span-8">Insumo</div>
                                <div className="col-span-4 text-center">Cantidad</div>
                              </div>
                              
                              {insumosCategoria.map((insumo) => (
                                <div
                                  key={insumo.id}
                                  className="grid grid-cols-12 gap-2 items-center"
                                >
                                  <div className="col-span-8 text-sm truncate">
                                    {insumo.nombre}
                                  </div>
                                  <div className="col-span-4">
                                    <Input
                                      type="number"
                                      min="0"
                                      placeholder="0"
                                      className="h-8 text-center text-sm"
                                      value={detalles[insumo.id]?.cantidad_recibida || ""}
                                      onChange={(e) =>
                                        updateDetalle(
                                          insumo.id,
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

            {/* Botón Registrar */}
            <Button
              className="w-full h-12 text-base gap-2"
              onClick={handleSubmit}
              disabled={isLoading || !sucursalSeleccionada || !proveedor}
            >
              <Check className="h-5 w-5" />
              {isLoading ? "Registrando..." : "Registrar Recepción"}
            </Button>
          </TabsContent>

          <TabsContent value="historial" className="space-y-3">
            <Card>
              <CardHeader className="pb-3">
                <CardTitle className="text-base">Últimas Recepciones</CardTitle>
              </CardHeader>
              <CardContent className="p-0">
                {recepcionesRecientes.length === 0 ? (
                  <div className="p-4 text-center text-muted-foreground text-sm">
                    No hay recepciones registradas
                  </div>
                ) : (
                  <div className="divide-y">
                    {recepcionesRecientes.map((recepcion) => (
                      <div
                        key={recepcion.id}
                        className="p-4"
                      >
                        <div className="flex items-center justify-between mb-1">
                          <p className="font-medium text-sm">
                            {recepcion.proveedor}
                          </p>
                          <Badge variant="outline" className="text-xs">
                            {recepcion.sucursales?.nombre}
                          </Badge>
                        </div>
                        <p className="text-xs text-muted-foreground">
                          {new Date(recepcion.created_at).toLocaleDateString("es-MX", {
                            day: "numeric",
                            month: "short",
                            hour: "2-digit",
                            minute: "2-digit",
                          })}
                          {recepcion.registrado_por && ` • ${recepcion.registrado_por}`}
                        </p>
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
