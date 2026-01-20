import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Badge } from "@/components/ui/badge";
import { useToast } from "@/hooks/use-toast";
import { ArrowLeft, Plus, Users, Clock, Phone, MapPin, Trash2, RefreshCw } from "lucide-react";
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
  const navigate = useNavigate();
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

  // Suscripción a nuevas reservaciones en tiempo real
  useEffect(() => {
    const channel = supabase
      .channel('reservaciones-realtime')
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'reservaciones',
        },
        async (payload) => {
          const nuevaReserva = payload.new as Reservacion;
          
          // Obtener info de sucursal y zona para el mensaje
          const [sucursalInfo, zonaInfo] = await Promise.all([
            supabase.from("sucursales").select("nombre").eq("id", nuevaReserva.sucursal_id).single(),
            supabase.from("zonas_sucursal").select("nombre").eq("id", nuevaReserva.zona_id).single(),
          ]);

          const sucursalNombre = sucursalInfo.data?.nombre || "Sucursal desconocida";
          const zonaNombre = zonaInfo.data?.nombre || "Zona desconocida";
          const fechaFormateada = format(parseISO(nuevaReserva.fecha), "d 'de' MMMM", { locale: es });

          // Mostrar notificación toast
          toast({
            title: "🔔 Nueva Reservación",
            description: `${nuevaReserva.nombre_cliente} en ${zonaNombre} - ${sucursalNombre}, ${fechaFormateada} a las ${nuevaReserva.hora.slice(0, 5)} (${nuevaReserva.num_personas} personas)`,
            duration: 8000,
          });

          // Refrescar lista si estamos viendo la misma fecha
          if (nuevaReserva.fecha === fechaFiltro) {
            fetchReservaciones();
          }
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [fechaFiltro, toast]);

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
        return <Badge className="bg-primary text-primary-foreground text-[10px] sm:text-xs">Confirmada</Badge>;
      case "cancelada":
        return <Badge variant="destructive" className="text-[10px] sm:text-xs">Cancelada</Badge>;
      case "completada":
        return <Badge variant="secondary" className="text-[10px] sm:text-xs">Completada</Badge>;
      default:
        return <Badge className="text-[10px] sm:text-xs">{estado}</Badge>;
    }
  };

  const formatFechaLabel = (fecha: string) => {
    const date = parseISO(fecha);
    if (isToday(date)) return "Hoy";
    if (isTomorrow(date)) return "Mañana";
    return format(date, "EEE d MMM", { locale: es });
  };

  const sucursalActual = sucursales.find((s) => s.id === sucursalSeleccionada);
  const zonasActuales = getZonasBySucursal(sucursalSeleccionada);

  return (
    <div className="min-h-screen bg-gradient-to-br from-primary/5 to-secondary/10 px-3 py-3 sm:p-4">
      <div className="max-w-6xl mx-auto">
        {/* Header - Mobile First */}
        <div className="flex items-center gap-2 mb-3 sm:mb-4">
          <Button variant="ghost" size="icon" className="shrink-0 h-8 w-8 sm:h-9 sm:w-9" onClick={() => onBack ? onBack() : navigate("/centro-de-operaciones")}>
            <ArrowLeft className="w-4 h-4 sm:w-5 sm:h-5" />
          </Button>
          <div className="flex items-center gap-2 flex-1 min-w-0">
            <div className="w-7 h-7 sm:w-10 sm:h-10 rounded-full overflow-hidden shrink-0">
              <img src={logoLaOla} alt="La Ola" className="w-full h-full object-cover" />
            </div>
            <div className="min-w-0">
              <h1 className="text-sm sm:text-xl font-bold truncate">Reservaciones</h1>
              <p className="text-[10px] sm:text-sm text-muted-foreground truncate">
                Todas las sucursales
              </p>
            </div>
          </div>
          <div className="flex items-center gap-1 shrink-0">
            <Button variant="outline" size="icon" className="h-7 w-7 sm:h-9 sm:w-9" onClick={fetchReservaciones}>
              <RefreshCw className="w-3.5 h-3.5 sm:w-4 sm:h-4" />
            </Button>
            <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
              <DialogTrigger asChild>
                <Button size="sm" className="h-7 sm:h-9 px-2 sm:px-4 text-xs sm:text-sm">
                  <Plus className="w-3.5 h-3.5 sm:w-4 sm:h-4 sm:mr-1" />
                  <span className="hidden sm:inline">Nueva</span>
                </Button>
              </DialogTrigger>
              <DialogContent className="w-[calc(100vw-24px)] sm:max-w-md max-h-[85vh] overflow-y-auto rounded-lg">
                <DialogHeader>
                  <DialogTitle className="text-base sm:text-lg">Nueva Reservación</DialogTitle>
                  <DialogDescription className="text-xs sm:text-sm">
                    Registra una reserva para cualquier sucursal
                  </DialogDescription>
                </DialogHeader>
                <form onSubmit={handleSubmit} className="space-y-3 sm:space-y-4">
                  <div className="grid grid-cols-2 gap-2 sm:gap-3">
                    <div className="space-y-1">
                      <Label className="text-xs sm:text-sm">Sucursal *</Label>
                      <Select value={formSucursal} onValueChange={(v) => { setFormSucursal(v); setFormZona(""); }}>
                        <SelectTrigger className="h-8 sm:h-9 text-xs sm:text-sm">
                          <SelectValue placeholder="Seleccionar" />
                        </SelectTrigger>
                        <SelectContent>
                          {sucursales.map((s) => (
                            <SelectItem key={s.id} value={s.id} className="text-xs sm:text-sm">{s.nombre}</SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                    </div>
                    <div className="space-y-1">
                      <Label className="text-xs sm:text-sm">Zona *</Label>
                      <Select value={formZona} onValueChange={setFormZona} disabled={!formSucursal}>
                        <SelectTrigger className="h-8 sm:h-9 text-xs sm:text-sm">
                          <SelectValue placeholder="Seleccionar" />
                        </SelectTrigger>
                        <SelectContent>
                          {getZonasBySucursal(formSucursal).map((z) => (
                            <SelectItem key={z.id} value={z.id} className="text-xs sm:text-sm">{z.nombre}</SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                    </div>
                  </div>

                  <div className="space-y-1">
                    <Label className="text-xs sm:text-sm">Nombre del cliente *</Label>
                    <Input
                      value={formNombre}
                      onChange={(e) => setFormNombre(e.target.value)}
                      placeholder="Nombre completo"
                      required
                      className="h-8 sm:h-9 text-sm"
                    />
                  </div>

                  <div className="grid grid-cols-2 gap-2 sm:gap-3">
                    <div className="space-y-1">
                      <Label className="text-xs sm:text-sm">Teléfono</Label>
                      <Input
                        value={formTelefono}
                        onChange={(e) => setFormTelefono(e.target.value)}
                        placeholder="Opcional"
                        className="h-8 sm:h-9 text-sm"
                      />
                    </div>
                    <div className="space-y-1">
                      <Label className="text-xs sm:text-sm">Personas *</Label>
                      <Input
                        type="number"
                        min="1"
                        max="50"
                        value={formPersonas}
                        onChange={(e) => setFormPersonas(e.target.value)}
                        className="h-8 sm:h-9 text-sm"
                      />
                    </div>
                  </div>

                  <div className="grid grid-cols-2 gap-2 sm:gap-3">
                    <div className="space-y-1">
                      <Label className="text-xs sm:text-sm">Fecha *</Label>
                      <Input
                        type="date"
                        value={formFecha}
                        onChange={(e) => setFormFecha(e.target.value)}
                        min={format(new Date(), "yyyy-MM-dd")}
                        required
                        className="h-8 sm:h-9 text-sm"
                      />
                    </div>
                    <div className="space-y-1">
                      <Label className="text-xs sm:text-sm">Hora *</Label>
                      <Input
                        type="time"
                        value={formHora}
                        onChange={(e) => setFormHora(e.target.value)}
                        required
                        className="h-8 sm:h-9 text-sm"
                      />
                    </div>
                  </div>

                  <div className="space-y-1">
                    <Label className="text-xs sm:text-sm">Notas</Label>
                    <Textarea
                      value={formNotas}
                      onChange={(e) => setFormNotas(e.target.value)}
                      placeholder="Ej: Cumpleaños, mesa especial..."
                      rows={2}
                      className="text-sm"
                    />
                  </div>

                  <div className="space-y-1">
                    <Label className="text-xs sm:text-sm">Registrado por</Label>
                    <Input
                      value={formRegistradoPor}
                      onChange={(e) => setFormRegistradoPor(e.target.value)}
                      placeholder="Tu nombre"
                      className="h-8 sm:h-9 text-sm"
                    />
                  </div>

                  <Button type="submit" className="w-full h-9 sm:h-10" disabled={isLoading}>
                    {isLoading ? "Guardando..." : "Crear Reservación"}
                  </Button>
                </form>
              </DialogContent>
            </Dialog>
          </div>
        </div>

        {/* Filtros - Stacked on mobile */}
        <div className="space-y-2 sm:space-y-3 mb-3 sm:mb-4">
          {/* Sucursales */}
          <div>
            <Label className="text-[10px] sm:text-xs text-muted-foreground mb-1 block">Sucursal</Label>
            <div className="flex flex-wrap gap-1">
              {sucursales.map((s) => (
                <Button
                  key={s.id}
                  variant={sucursalSeleccionada === s.id ? "default" : "outline"}
                  size="sm"
                  className="h-7 sm:h-8 px-2 sm:px-3 text-[11px] sm:text-sm"
                  onClick={() => setSucursalSeleccionada(s.id)}
                >
                  {s.nombre.replace("La Ola ", "").replace("LO ", "")}
                </Button>
              ))}
            </div>
          </div>

          {/* Fecha */}
          <div>
            <Label className="text-[10px] sm:text-xs text-muted-foreground mb-1 block">Fecha</Label>
            <div className="flex flex-wrap gap-1">
              <Button
                variant={isToday(parseISO(fechaFiltro)) ? "default" : "outline"}
                size="sm"
                className="h-7 sm:h-8 px-2 sm:px-3 text-[11px] sm:text-sm"
                onClick={() => setFechaFiltro(format(new Date(), "yyyy-MM-dd"))}
              >
                Hoy
              </Button>
              <Button
                variant={isTomorrow(parseISO(fechaFiltro)) ? "default" : "outline"}
                size="sm"
                className="h-7 sm:h-8 px-2 sm:px-3 text-[11px] sm:text-sm"
                onClick={() => setFechaFiltro(format(addDays(new Date(), 1), "yyyy-MM-dd"))}
              >
                Mañana
              </Button>
              <Input
                type="date"
                value={fechaFiltro}
                onChange={(e) => setFechaFiltro(e.target.value)}
                className="h-7 sm:h-8 w-[115px] sm:w-[130px] text-[11px] sm:text-sm px-2"
              />
            </div>
          </div>
        </div>

        {/* Título de la sección */}
        <div className="mb-2 sm:mb-3">
          <h2 className="text-xs sm:text-lg font-semibold flex items-center gap-1.5 sm:gap-2">
            <MapPin className="w-3.5 h-3.5 sm:w-5 sm:h-5 shrink-0" />
            <span className="truncate">{sucursalActual?.nombre || "Selecciona sucursal"}</span>
            <span className="text-muted-foreground font-normal text-[10px] sm:text-base">— {formatFechaLabel(fechaFiltro)}</span>
          </h2>
        </div>

        {/* Grid de Zonas */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-2 sm:gap-4">
          {zonasActuales.map((zona) => {
            const reservasZona = getReservacionesByZona(zona.id).filter((r) => r.estado !== "cancelada");
            const hayReservas = reservasZona.length > 0;

            return (
              <Card
                key={zona.id}
                className={`${hayReservas ? "border-primary/50 bg-primary/5" : ""}`}
              >
                <CardHeader className="p-3 sm:pb-2 sm:p-4">
                  <div className="flex justify-between items-start gap-2">
                    <CardTitle className="text-sm sm:text-base">{zona.nombre}</CardTitle>
                    <Badge variant={hayReservas ? "default" : "secondary"} className="text-[10px] sm:text-xs shrink-0">
                      {reservasZona.length} reserva{reservasZona.length !== 1 ? "s" : ""}
                    </Badge>
                  </div>
                  <CardDescription className="text-[10px] sm:text-xs">
                    Capacidad: {zona.capacidad} personas
                  </CardDescription>
                </CardHeader>
                <CardContent className="p-3 pt-0 sm:p-4 sm:pt-0">
                  {reservasZona.length === 0 ? (
                    <p className="text-[11px] sm:text-sm text-muted-foreground text-center py-3 sm:py-4">
                      Sin reservas para esta fecha
                    </p>
                  ) : (
                    <div className="space-y-2 sm:space-y-3">
                      {reservasZona.map((reserva) => (
                        <div
                          key={reserva.id}
                          className="p-2 sm:p-3 rounded-lg bg-background border text-xs sm:text-sm"
                        >
                          <div className="flex justify-between items-start mb-1.5 sm:mb-2 gap-2">
                            <span className="font-medium truncate">{reserva.nombre_cliente}</span>
                            {getEstadoBadge(reserva.estado)}
                          </div>
                          <div className="flex flex-wrap gap-x-3 gap-y-0.5 text-muted-foreground text-[10px] sm:text-xs">
                            <span className="flex items-center gap-1">
                              <Clock className="w-2.5 h-2.5 sm:w-3 sm:h-3" />
                              {reserva.hora.slice(0, 5)}
                            </span>
                            <span className="flex items-center gap-1">
                              <Users className="w-2.5 h-2.5 sm:w-3 sm:h-3" />
                              {reserva.num_personas} pers.
                            </span>
                            {reserva.telefono && (
                              <span className="flex items-center gap-1">
                                <Phone className="w-2.5 h-2.5 sm:w-3 sm:h-3" />
                                {reserva.telefono}
                              </span>
                            )}
                          </div>
                          {reserva.notas && (
                            <p className="text-[10px] sm:text-xs text-muted-foreground mt-1.5 sm:mt-2 italic line-clamp-2">
                              {reserva.notas}
                            </p>
                          )}
                          <div className="flex justify-end gap-1 mt-1.5 sm:mt-2">
                            {reserva.estado === "confirmada" && (
                              <Button
                                variant="ghost"
                                size="sm"
                                className="h-6 sm:h-7 text-[10px] sm:text-xs px-2"
                                onClick={() => handleCancelar(reserva.id)}
                              >
                                Cancelar
                              </Button>
                            )}
                            <AlertDialog>
                              <AlertDialogTrigger asChild>
                                <Button variant="ghost" size="icon" className="h-6 w-6 sm:h-7 sm:w-7 text-destructive">
                                  <Trash2 className="w-2.5 h-2.5 sm:w-3 sm:h-3" />
                                </Button>
                              </AlertDialogTrigger>
                              <AlertDialogContent className="w-[calc(100vw-32px)] sm:max-w-md rounded-lg">
                                <AlertDialogHeader>
                                  <AlertDialogTitle className="text-sm sm:text-base">¿Eliminar reservación?</AlertDialogTitle>
                                  <AlertDialogDescription className="text-xs sm:text-sm">
                                    Esta acción no se puede deshacer. Se eliminará la reserva de {reserva.nombre_cliente}.
                                  </AlertDialogDescription>
                                </AlertDialogHeader>
                                <AlertDialogFooter className="gap-2 sm:gap-0">
                                  <AlertDialogCancel className="h-8 sm:h-9 text-xs sm:text-sm">No, conservar</AlertDialogCancel>
                                  <AlertDialogAction onClick={() => handleEliminar(reserva.id)} className="h-8 sm:h-9 text-xs sm:text-sm">
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
          <Card className="text-center py-8 sm:py-12">
            <CardContent>
              <MapPin className="w-8 h-8 sm:w-12 sm:h-12 mx-auto text-muted-foreground mb-3 sm:mb-4" />
              <p className="text-xs sm:text-sm text-muted-foreground">
                Selecciona una sucursal para ver sus zonas
              </p>
            </CardContent>
          </Card>
        )}
      </div>
    </div>
  );
}
