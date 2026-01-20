import { useState, useEffect } from "react";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Badge } from "@/components/ui/badge";
import { useToast } from "@/hooks/use-toast";
import { ArrowLeft, Plus, Users, Clock, Phone, Calendar, MapPin, Trash2, RefreshCw } from "lucide-react";
import { format, parseISO, isToday, isTomorrow, addDays } from "date-fns";
import { es } from "date-fns/locale";
import logoLaOla from "@/assets/logo-la-ola.jpeg";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from "@/components/ui/alert-dialog";
import { Textarea } from "@/components/ui/textarea";

interface Sucursal {
  id: string;
  nombre: string;
}

interface Zona {
  id: string;
  sucursal_id: string;
  nombre: string;
  capacidad: number;
}

interface Reservacion {
  id: string;
  sucursal_id: string;
  zona_id: string;
  nombre_cliente: string;
  telefono: string | null;
  num_personas: number;
  fecha: string;
  hora: string;
  notas: string | null;
  estado: string;
  registrado_por: string | null;
  created_at: string;
}

interface Props {
  onBack?: () => void;
}

export default function Reservaciones({ onBack }: Props) {
  const [sucursales, setSucursales] = useState<Sucursal[]>([]);
  const [zonas, setZonas] = useState<Zona[]>([]);
  const [reservaciones, setReservaciones] = useState<Reservacion[]>([]);
  const [sucursalSeleccionada, setSucursalSeleccionada] = useState<string>("");
  const [fechaFiltro, setFechaFiltro] = useState<string>(format(new Date(), "yyyy-MM-dd"));
  const [isLoading, setIsLoading] = useState(false);
  const [dialogOpen, setDialogOpen] = useState(false);

  // Form state
  const [formSucursal, setFormSucursal] = useState("");
  const [formZona, setFormZona] = useState("");
  const [formNombre, setFormNombre] = useState("");
  const [formTelefono, setFormTelefono] = useState("");
  const [formPersonas, setFormPersonas] = useState("2");
  const [formFecha, setFormFecha] = useState(format(new Date(), "yyyy-MM-dd"));
  const [formHora, setFormHora] = useState("14:00");
  const [formNotas, setFormNotas] = useState("");
  const [formRegistradoPor, setFormRegistradoPor] = useState("");

  const { toast } = useToast();

  useEffect(() => {
    fetchData();
  }, []);

  useEffect(() => {
    if (sucursalSeleccionada) {
      fetchReservaciones();
    }
  }, [sucursalSeleccionada, fechaFiltro]);

  const fetchData = async () => {
    const [sucursalesRes, zonasRes] = await Promise.all([
      supabase.from("sucursales").select("id, nombre").order("nombre"),
      supabase.from("zonas_sucursal").select("*").order("nombre"),
    ]);

    if (sucursalesRes.data) setSucursales(sucursalesRes.data);
    if (zonasRes.data) setZonas(zonasRes.data as Zona[]);

    // Seleccionar primera sucursal por defecto
    if (sucursalesRes.data && sucursalesRes.data.length > 0) {
      setSucursalSeleccionada(sucursalesRes.data[0].id);
    }
  };

  const fetchReservaciones = async () => {
    const { data, error } = await supabase
      .from("reservaciones")
      .select("*")
      .eq("fecha", fechaFiltro)
      .order("hora");

    if (error) {
      toast({
        title: "Error",
        description: "No se pudieron cargar las reservaciones",
        variant: "destructive",
      });
      return;
    }

    setReservaciones((data as Reservacion[]) || []);
  };

  const getZonasBySucursal = (sucursalId: string) => {
    return zonas.filter((z) => z.sucursal_id === sucursalId);
  };

  const getReservacionesByZona = (zonaId: string) => {
    return reservaciones.filter((r) => r.zona_id === zonaId);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);

    if (!formSucursal || !formZona || !formNombre || !formFecha || !formHora) {
      toast({
        title: "Error",
        description: "Completa todos los campos requeridos",
        variant: "destructive",
      });
      setIsLoading(false);
      return;
    }

    const { error } = await supabase.from("reservaciones").insert({
      sucursal_id: formSucursal,
      zona_id: formZona,
      nombre_cliente: formNombre.trim(),
      telefono: formTelefono.trim() || null,
      num_personas: parseInt(formPersonas) || 2,
      fecha: formFecha,
      hora: formHora,
      notas: formNotas.trim() || null,
      estado: "confirmada",
      registrado_por: formRegistradoPor.trim() || null,
    } as any);

    setIsLoading(false);

    if (error) {
      toast({
        title: "Error",
        description: "No se pudo crear la reservación",
        variant: "destructive",
      });
      return;
    }

    toast({
      title: "¡Reservación creada!",
      description: `Reserva para ${formNombre} registrada correctamente.`,
    });

    // Reset form
    setFormNombre("");
    setFormTelefono("");
    setFormPersonas("2");
    setFormNotas("");
    setDialogOpen(false);
    fetchReservaciones();
  };

  const handleCancelar = async (id: string) => {
    const { error } = await supabase
      .from("reservaciones")
      .update({ estado: "cancelada" } as any)
      .eq("id", id);

    if (error) {
      toast({
        title: "Error",
        description: "No se pudo cancelar la reservación",
        variant: "destructive",
      });
      return;
    }

    toast({
      title: "Reservación cancelada",
      description: "La reservación ha sido cancelada.",
    });
    fetchReservaciones();
  };

  const handleEliminar = async (id: string) => {
    const { error } = await supabase.from("reservaciones").delete().eq("id", id);

    if (error) {
      toast({
        title: "Error",
        description: "No se pudo eliminar la reservación",
        variant: "destructive",
      });
      return;
    }

    toast({
      title: "Reservación eliminada",
    });
    fetchReservaciones();
  };

  const getEstadoBadge = (estado: string) => {
    switch (estado) {
      case "confirmada":
        return <Badge className="bg-green-500">Confirmada</Badge>;
      case "cancelada":
        return <Badge variant="destructive">Cancelada</Badge>;
      case "completada":
        return <Badge variant="secondary">Completada</Badge>;
      default:
        return <Badge>{estado}</Badge>;
    }
  };

  const formatFechaLabel = (fecha: string) => {
    const date = parseISO(fecha);
    if (isToday(date)) return "Hoy";
    if (isTomorrow(date)) return "Mañana";
    return format(date, "EEEE d 'de' MMMM", { locale: es });
  };

  const sucursalActual = sucursales.find((s) => s.id === sucursalSeleccionada);
  const zonasActuales = getZonasBySucursal(sucursalSeleccionada);

  return (
    <div className="min-h-screen bg-gradient-to-br from-primary/5 to-secondary/10 p-4">
      <div className="max-w-6xl mx-auto">
        {/* Header */}
        <div className="flex items-center justify-between mb-6">
          <div className="flex items-center gap-4">
            {onBack && (
              <Button variant="ghost" size="icon" onClick={onBack}>
                <ArrowLeft className="w-5 h-5" />
              </Button>
            )}
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-full overflow-hidden">
                <img src={logoLaOla} alt="La Ola" className="w-full h-full object-cover" />
              </div>
              <div>
                <h1 className="text-xl font-bold">Centro de Reservaciones</h1>
                <p className="text-sm text-muted-foreground">
                  Consulta y registra reservas de todas las sucursales
                </p>
              </div>
            </div>
          </div>
          <div className="flex items-center gap-2">
            <Button variant="outline" size="icon" onClick={fetchReservaciones}>
              <RefreshCw className="w-4 h-4" />
            </Button>
            <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
              <DialogTrigger asChild>
                <Button>
                  <Plus className="w-4 h-4 mr-2" />
                  Nueva Reserva
                </Button>
              </DialogTrigger>
              <DialogContent className="max-w-md">
                <DialogHeader>
                  <DialogTitle>Nueva Reservación</DialogTitle>
                  <DialogDescription>
                    Registra una nueva reserva para cualquier sucursal
                  </DialogDescription>
                </DialogHeader>
                <form onSubmit={handleSubmit} className="space-y-4">
                  <div className="grid grid-cols-2 gap-4">
                    <div className="space-y-2">
                      <Label>Sucursal *</Label>
                      <Select value={formSucursal} onValueChange={(v) => { setFormSucursal(v); setFormZona(""); }}>
                        <SelectTrigger>
                          <SelectValue placeholder="Seleccionar" />
                        </SelectTrigger>
                        <SelectContent>
                          {sucursales.map((s) => (
                            <SelectItem key={s.id} value={s.id}>{s.nombre}</SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                    </div>
                    <div className="space-y-2">
                      <Label>Zona *</Label>
                      <Select value={formZona} onValueChange={setFormZona} disabled={!formSucursal}>
                        <SelectTrigger>
                          <SelectValue placeholder="Seleccionar" />
                        </SelectTrigger>
                        <SelectContent>
                          {getZonasBySucursal(formSucursal).map((z) => (
                            <SelectItem key={z.id} value={z.id}>{z.nombre}</SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                    </div>
                  </div>

                  <div className="space-y-2">
                    <Label>Nombre del cliente *</Label>
                    <Input
                      value={formNombre}
                      onChange={(e) => setFormNombre(e.target.value)}
                      placeholder="Nombre completo"
                      required
                    />
                  </div>

                  <div className="grid grid-cols-2 gap-4">
                    <div className="space-y-2">
                      <Label>Teléfono</Label>
                      <Input
                        value={formTelefono}
                        onChange={(e) => setFormTelefono(e.target.value)}
                        placeholder="Opcional"
                      />
                    </div>
                    <div className="space-y-2">
                      <Label>Personas *</Label>
                      <Input
                        type="number"
                        min="1"
                        max="50"
                        value={formPersonas}
                        onChange={(e) => setFormPersonas(e.target.value)}
                      />
                    </div>
                  </div>

                  <div className="grid grid-cols-2 gap-4">
                    <div className="space-y-2">
                      <Label>Fecha *</Label>
                      <Input
                        type="date"
                        value={formFecha}
                        onChange={(e) => setFormFecha(e.target.value)}
                        min={format(new Date(), "yyyy-MM-dd")}
                        required
                      />
                    </div>
                    <div className="space-y-2">
                      <Label>Hora *</Label>
                      <Input
                        type="time"
                        value={formHora}
                        onChange={(e) => setFormHora(e.target.value)}
                        required
                      />
                    </div>
                  </div>

                  <div className="space-y-2">
                    <Label>Notas</Label>
                    <Textarea
                      value={formNotas}
                      onChange={(e) => setFormNotas(e.target.value)}
                      placeholder="Ej: Cumpleaños, mesa especial..."
                      rows={2}
                    />
                  </div>

                  <div className="space-y-2">
                    <Label>Registrado por</Label>
                    <Input
                      value={formRegistradoPor}
                      onChange={(e) => setFormRegistradoPor(e.target.value)}
                      placeholder="Tu nombre"
                    />
                  </div>

                  <Button type="submit" className="w-full" disabled={isLoading}>
                    {isLoading ? "Guardando..." : "Crear Reservación"}
                  </Button>
                </form>
              </DialogContent>
            </Dialog>
          </div>
        </div>

        {/* Filtros */}
        <div className="flex flex-wrap gap-4 mb-6">
          <div className="flex-1 min-w-[200px]">
            <Label className="text-xs text-muted-foreground mb-1 block">Sucursal</Label>
            <Tabs value={sucursalSeleccionada} onValueChange={setSucursalSeleccionada}>
              <TabsList className="w-full flex-wrap h-auto">
                {sucursales.map((s) => (
                  <TabsTrigger key={s.id} value={s.id} className="flex-1 min-w-[80px]">
                    {s.nombre.replace("La Ola ", "").replace("LO ", "")}
                  </TabsTrigger>
                ))}
              </TabsList>
            </Tabs>
          </div>
          <div className="flex gap-2 items-end">
            <div>
              <Label className="text-xs text-muted-foreground mb-1 block">Fecha</Label>
              <div className="flex gap-1">
                <Button
                  variant={isToday(parseISO(fechaFiltro)) ? "default" : "outline"}
                  size="sm"
                  onClick={() => setFechaFiltro(format(new Date(), "yyyy-MM-dd"))}
                >
                  Hoy
                </Button>
                <Button
                  variant={isTomorrow(parseISO(fechaFiltro)) ? "default" : "outline"}
                  size="sm"
                  onClick={() => setFechaFiltro(format(addDays(new Date(), 1), "yyyy-MM-dd"))}
                >
                  Mañana
                </Button>
                <Input
                  type="date"
                  value={fechaFiltro}
                  onChange={(e) => setFechaFiltro(e.target.value)}
                  className="w-[140px]"
                />
              </div>
            </div>
          </div>
        </div>

        {/* Mapa de Zonas */}
        <div className="mb-4">
          <h2 className="text-lg font-semibold flex items-center gap-2 mb-3">
            <MapPin className="w-5 h-5" />
            {sucursalActual?.nombre || "Selecciona una sucursal"} — {formatFechaLabel(fechaFiltro)}
          </h2>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {zonasActuales.map((zona) => {
            const reservasZona = getReservacionesByZona(zona.id).filter((r) => r.estado !== "cancelada");
            const hayReservas = reservasZona.length > 0;

            return (
              <Card
                key={zona.id}
                className={`${hayReservas ? "border-primary/50 bg-primary/5" : ""}`}
              >
                <CardHeader className="pb-2">
                  <div className="flex justify-between items-start">
                    <CardTitle className="text-base">{zona.nombre}</CardTitle>
                    <Badge variant={hayReservas ? "default" : "secondary"}>
                      {reservasZona.length} reserva{reservasZona.length !== 1 ? "s" : ""}
                    </Badge>
                  </div>
                  <CardDescription className="text-xs">
                    Capacidad: {zona.capacidad} personas
                  </CardDescription>
                </CardHeader>
                <CardContent>
                  {reservasZona.length === 0 ? (
                    <p className="text-sm text-muted-foreground text-center py-4">
                      Sin reservas para esta fecha
                    </p>
                  ) : (
                    <div className="space-y-3">
                      {reservasZona.map((reserva) => (
                        <div
                          key={reserva.id}
                          className="p-3 rounded-lg bg-background border text-sm"
                        >
                          <div className="flex justify-between items-start mb-2">
                            <span className="font-medium">{reserva.nombre_cliente}</span>
                            {getEstadoBadge(reserva.estado)}
                          </div>
                          <div className="flex flex-wrap gap-x-4 gap-y-1 text-muted-foreground text-xs">
                            <span className="flex items-center gap-1">
                              <Clock className="w-3 h-3" />
                              {reserva.hora.slice(0, 5)}
                            </span>
                            <span className="flex items-center gap-1">
                              <Users className="w-3 h-3" />
                              {reserva.num_personas} pers.
                            </span>
                            {reserva.telefono && (
                              <span className="flex items-center gap-1">
                                <Phone className="w-3 h-3" />
                                {reserva.telefono}
                              </span>
                            )}
                          </div>
                          {reserva.notas && (
                            <p className="text-xs text-muted-foreground mt-2 italic">
                              {reserva.notas}
                            </p>
                          )}
                          <div className="flex justify-end gap-1 mt-2">
                            {reserva.estado === "confirmada" && (
                              <Button
                                variant="ghost"
                                size="sm"
                                className="h-7 text-xs"
                                onClick={() => handleCancelar(reserva.id)}
                              >
                                Cancelar
                              </Button>
                            )}
                            <AlertDialog>
                              <AlertDialogTrigger asChild>
                                <Button variant="ghost" size="icon" className="h-7 w-7 text-destructive">
                                  <Trash2 className="w-3 h-3" />
                                </Button>
                              </AlertDialogTrigger>
                              <AlertDialogContent>
                                <AlertDialogHeader>
                                  <AlertDialogTitle>¿Eliminar reservación?</AlertDialogTitle>
                                  <AlertDialogDescription>
                                    Esta acción no se puede deshacer. Se eliminará permanentemente la reserva de {reserva.nombre_cliente}.
                                  </AlertDialogDescription>
                                </AlertDialogHeader>
                                <AlertDialogFooter>
                                  <AlertDialogCancel>No, conservar</AlertDialogCancel>
                                  <AlertDialogAction onClick={() => handleEliminar(reserva.id)}>
                                    Sí, eliminar
                                  </AlertDialogAction>
                                </AlertDialogFooter>
                              </AlertDialogContent>
                            </AlertDialog>
                          </div>
                        </div>
                      ))}
                    </div>
                  )}
                </CardContent>
              </Card>
            );
          })}
        </div>

        {zonasActuales.length === 0 && (
          <Card className="text-center py-12">
            <CardContent>
              <MapPin className="w-12 h-12 mx-auto text-muted-foreground mb-4" />
              <p className="text-muted-foreground">
                Selecciona una sucursal para ver sus zonas
              </p>
            </CardContent>
          </Card>
        )}
      </div>
    </div>
  );
}
