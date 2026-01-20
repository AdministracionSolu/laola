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
import { ArrowLeft, Plus, Users, Clock, Phone, MapPin, Trash2, RefreshCw, CalendarDays, Store, Edit2, X } from "lucide-react";
import { format, parseISO, isToday, isTomorrow, addDays } from "date-fns";
import { es } from "date-fns/locale";
import logoLaOla from "@/assets/logo-la-ola.jpeg";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
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
  updated_at: string;
}

interface Props {
  onBack?: () => void;
}

export default function Reservaciones({ onBack }: Props) {
  const navigate = useNavigate();
  const [sucursales, setSucursales] = useState<Sucursal[]>([]);
  const [zonas, setZonas] = useState<Zona[]>([]);
  const [reservaciones, setReservaciones] = useState<Reservacion[]>([]);
  const [ultimasReservas, setUltimasReservas] = useState<Reservacion[]>([]);
  const [sucursalFiltro, setSucursalFiltro] = useState<string>("todas");
  const [fechaFiltro, setFechaFiltro] = useState<string>(format(new Date(), "yyyy-MM-dd"));
  const [isLoading, setIsLoading] = useState(false);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editingReserva, setEditingReserva] = useState<Reservacion | null>(null);

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
    fetchUltimasReservas();
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
          
          const [sucursalInfo, zonaInfo] = await Promise.all([
            supabase.from("sucursales").select("nombre").eq("id", nuevaReserva.sucursal_id).single(),
            supabase.from("zonas_sucursal").select("nombre").eq("id", nuevaReserva.zona_id).single(),
          ]);

          const sucursalNombre = sucursalInfo.data?.nombre || "Sucursal desconocida";
          const zonaNombre = zonaInfo.data?.nombre || "Zona desconocida";
          const fechaFormateada = format(parseISO(nuevaReserva.fecha), "d 'de' MMMM", { locale: es });

          toast({
            title: "🔔 Nueva Reservación",
            description: `${nuevaReserva.nombre_cliente} en ${zonaNombre} - ${sucursalNombre}, ${fechaFormateada} a las ${nuevaReserva.hora.slice(0, 5)} (${nuevaReserva.num_personas} personas)`,
            duration: 8000,
          });

          if (nuevaReserva.fecha === fechaFiltro) {
            fetchReservaciones();
          }
          fetchUltimasReservas();
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [fechaFiltro, toast]);

  useEffect(() => {
    fetchReservaciones();
  }, [fechaFiltro]);

  const fetchData = async () => {
    const [sucursalesRes, zonasRes] = await Promise.all([
      supabase.from("sucursales").select("id, nombre").order("nombre"),
      supabase.from("zonas_sucursal").select("*").order("nombre"),
    ]);

    if (sucursalesRes.data) setSucursales(sucursalesRes.data);
    if (zonasRes.data) setZonas(zonasRes.data as Zona[]);
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

  const fetchUltimasReservas = async () => {
    const { data } = await supabase
      .from("reservaciones")
      .select("*")
      .order("updated_at", { ascending: false })
      .limit(5);

    setUltimasReservas((data as Reservacion[]) || []);
  };

  const getZonasBySucursal = (sucursalId: string) => {
    return zonas.filter((z) => z.sucursal_id === sucursalId);
  };

  const getSucursalNombre = (sucursalId: string) => {
    return sucursales.find((s) => s.id === sucursalId)?.nombre || "";
  };

  const getZonaNombre = (zonaId: string) => {
    return zonas.find((z) => z.id === zonaId)?.nombre || "";
  };

  const openNewReservaDialog = () => {
    setEditingReserva(null);
    setFormSucursal("");
    setFormZona("");
    setFormNombre("");
    setFormTelefono("");
    setFormPersonas("2");
    setFormFecha(format(new Date(), "yyyy-MM-dd"));
    setFormHora("14:00");
    setFormNotas("");
    setFormRegistradoPor("");
    setDialogOpen(true);
  };

  const openEditReservaDialog = (reserva: Reservacion) => {
    setEditingReserva(reserva);
    setFormSucursal(reserva.sucursal_id);
    setFormZona(reserva.zona_id);
    setFormNombre(reserva.nombre_cliente);
    setFormTelefono(reserva.telefono || "");
    setFormPersonas(reserva.num_personas.toString());
    setFormFecha(reserva.fecha);
    setFormHora(reserva.hora);
    setFormNotas(reserva.notas || "");
    setFormRegistradoPor(reserva.registrado_por || "");
    setDialogOpen(true);
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

    const reservaData = {
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
    };

    let error;
    if (editingReserva) {
      const result = await supabase
        .from("reservaciones")
        .update(reservaData as any)
        .eq("id", editingReserva.id);
      error = result.error;
    } else {
      const result = await supabase.from("reservaciones").insert(reservaData as any);
      error = result.error;
    }

    setIsLoading(false);

    if (error) {
      toast({
        title: "Error",
        description: editingReserva ? "No se pudo actualizar la reservación" : "No se pudo crear la reservación",
        variant: "destructive",
      });
      return;
    }

    toast({
      title: editingReserva ? "¡Reservación actualizada!" : "¡Reservación creada!",
      description: `Reserva para ${formNombre} ${editingReserva ? "actualizada" : "registrada"} correctamente.`,
    });

    setDialogOpen(false);
    setEditingReserva(null);
    fetchReservaciones();
    fetchUltimasReservas();
  };

  const handleCancelar = async (id: string) => {
    const { error } = await supabase
      .from("reservaciones")
      .update({ estado: "cancelada" } as any)
      .eq("id", id);

    if (error) {
      toast({ title: "Error", description: "No se pudo cancelar la reservación", variant: "destructive" });
      return;
    }

    toast({ title: "Reservación cancelada" });
    fetchReservaciones();
    fetchUltimasReservas();
  };

  const handleEliminar = async (id: string) => {
    const { error } = await supabase.from("reservaciones").delete().eq("id", id);

    if (error) {
      toast({ title: "Error", description: "No se pudo eliminar la reservación", variant: "destructive" });
      return;
    }

    toast({ title: "Reservación eliminada" });
    fetchReservaciones();
    fetchUltimasReservas();
  };

  const getEstadoBadge = (estado: string) => {
    switch (estado) {
      case "confirmada":
        return <Badge className="bg-primary text-primary-foreground text-[10px]">Confirmada</Badge>;
      case "cancelada":
        return <Badge variant="destructive" className="text-[10px]">Cancelada</Badge>;
      case "completada":
        return <Badge variant="secondary" className="text-[10px]">Completada</Badge>;
      default:
        return <Badge className="text-[10px]">{estado}</Badge>;
    }
  };

  const formatFechaLabel = (fecha: string) => {
    const date = parseISO(fecha);
    if (isToday(date)) return "Hoy";
    if (isTomorrow(date)) return "Mañana";
    return format(date, "EEE d MMM", { locale: es });
  };

  // Dashboard stats
  const reservasHoy = reservaciones.filter((r) => r.estado !== "cancelada");
  const totalPersonasHoy = reservasHoy.reduce((acc, r) => acc + r.num_personas, 0);
  const sucursalesConReservas = [...new Set(reservasHoy.map((r) => r.sucursal_id))];

  // Filtrar reservas por sucursal
  const reservasFiltradas = sucursalFiltro === "todas" 
    ? reservaciones 
    : reservaciones.filter((r) => r.sucursal_id === sucursalFiltro);

  // Agrupar por sucursal para mostrar
  const reservasPorSucursal = sucursales.map((suc) => ({
    sucursal: suc,
    reservas: reservasFiltradas.filter((r) => r.sucursal_id === suc.id && r.estado !== "cancelada"),
  })).filter((g) => sucursalFiltro === "todas" || g.sucursal.id === sucursalFiltro);

  return (
    <div className="min-h-screen bg-gradient-to-br from-primary/5 to-secondary/10 px-3 py-3 sm:p-4">
      <div className="max-w-4xl mx-auto">
        {/* Header */}
        <div className="flex items-center gap-2 mb-4">
          <Button variant="ghost" size="icon" className="shrink-0 h-8 w-8" onClick={() => onBack ? onBack() : navigate("/centro-de-operaciones")}>
            <ArrowLeft className="w-4 h-4" />
          </Button>
          <div className="flex items-center gap-2 flex-1 min-w-0">
            <div className="w-8 h-8 rounded-full overflow-hidden shrink-0">
              <img src={logoLaOla} alt="La Ola" className="w-full h-full object-cover" />
            </div>
            <div className="min-w-0">
              <h1 className="text-base sm:text-lg font-bold">Panel de Reservaciones</h1>
              <p className="text-[10px] sm:text-xs text-muted-foreground">Sistema interno de operaciones</p>
            </div>
          </div>
          <Button variant="outline" size="icon" className="h-8 w-8" onClick={fetchReservaciones}>
            <RefreshCw className="w-4 h-4" />
          </Button>
        </div>

        {/* CTA Principal - Registrar Reserva */}
        <Card className="mb-4 border-primary bg-primary/5 cursor-pointer hover:bg-primary/10 transition-colors" onClick={openNewReservaDialog}>
          <CardContent className="p-4 flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 sm:w-12 sm:h-12 rounded-full bg-primary flex items-center justify-center">
                <Plus className="w-5 h-5 sm:w-6 sm:h-6 text-primary-foreground" />
              </div>
              <div>
                <h2 className="font-semibold text-sm sm:text-base">Registrar Nueva Reserva</h2>
                <p className="text-[11px] sm:text-xs text-muted-foreground">Cualquier sucursal o zona</p>
              </div>
            </div>
            <Plus className="w-5 h-5 text-primary" />
          </CardContent>
        </Card>

        {/* Dashboard Stats */}
        <div className="grid grid-cols-3 gap-2 sm:gap-3 mb-4">
          <Card className="p-3">
            <div className="flex items-center gap-2">
              <CalendarDays className="w-4 h-4 text-primary shrink-0" />
              <div className="min-w-0">
                <p className="text-lg sm:text-2xl font-bold">{reservasHoy.length}</p>
                <p className="text-[10px] sm:text-xs text-muted-foreground truncate">Reservas {formatFechaLabel(fechaFiltro)}</p>
              </div>
            </div>
          </Card>
          <Card className="p-3">
            <div className="flex items-center gap-2">
              <Users className="w-4 h-4 text-primary shrink-0" />
              <div className="min-w-0">
                <p className="text-lg sm:text-2xl font-bold">{totalPersonasHoy}</p>
                <p className="text-[10px] sm:text-xs text-muted-foreground truncate">Personas esperadas</p>
              </div>
            </div>
          </Card>
          <Card className="p-3">
            <div className="flex items-center gap-2">
              <Store className="w-4 h-4 text-primary shrink-0" />
              <div className="min-w-0">
                <p className="text-lg sm:text-2xl font-bold">{sucursalesConReservas.length}</p>
                <p className="text-[10px] sm:text-xs text-muted-foreground truncate">Sucursales activas</p>
              </div>
            </div>
          </Card>
        </div>

        {/* Últimas Reservas Registradas */}
        {ultimasReservas.length > 0 && (
          <Card className="mb-4">
            <CardHeader className="p-3 pb-2">
              <CardTitle className="text-sm flex items-center gap-2">
                <Clock className="w-4 h-4" />
                Últimas Reservas Registradas
              </CardTitle>
            </CardHeader>
            <CardContent className="p-3 pt-0">
              <div className="space-y-1.5">
                {ultimasReservas.map((reserva) => (
                  <div
                    key={reserva.id}
                    className="flex items-center justify-between p-2 rounded bg-muted/50 text-xs cursor-pointer hover:bg-muted transition-colors"
                    onClick={() => openEditReservaDialog(reserva)}
                  >
                    <div className="flex items-center gap-2 min-w-0 flex-1">
                      <span className="font-medium truncate">{reserva.nombre_cliente}</span>
                      <span className="text-muted-foreground">·</span>
                      <span className="text-muted-foreground truncate">{getZonaNombre(reserva.zona_id)}</span>
                      <span className="text-muted-foreground">·</span>
                      <span className="text-muted-foreground">{getSucursalNombre(reserva.sucursal_id).replace("La Ola ", "")}</span>
                    </div>
                    <div className="flex items-center gap-2 shrink-0 text-muted-foreground">
                      <span>{format(parseISO(reserva.fecha), "d MMM", { locale: es })}</span>
                      <span>{reserva.hora.slice(0, 5)}</span>
                      {getEstadoBadge(reserva.estado)}
                    </div>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        )}

        {/* Filtros */}
        <div className="space-y-2 mb-4">
          {/* Sucursales en una sola fila con scroll horizontal si es necesario */}
          <div className="flex items-center gap-2">
            <span className="text-[10px] text-muted-foreground shrink-0">Sucursal:</span>
            <div className="flex gap-1 overflow-x-auto pb-1 scrollbar-hide">
              <Button
                variant={sucursalFiltro === "todas" ? "default" : "outline"}
                size="sm"
                className="h-6 px-2 text-[10px] shrink-0"
                onClick={() => setSucursalFiltro("todas")}
              >
                Todas
              </Button>
              {sucursales.map((s) => (
                <Button
                  key={s.id}
                  variant={sucursalFiltro === s.id ? "default" : "outline"}
                  size="sm"
                  className="h-6 px-2 text-[10px] shrink-0"
                  onClick={() => setSucursalFiltro(s.id)}
                >
                  {s.nombre.replace("La Ola ", "").replace("LO ", "")}
                </Button>
              ))}
            </div>
          </div>
          {/* Fecha */}
          <div className="flex items-center gap-2">
            <span className="text-[10px] text-muted-foreground shrink-0">Fecha:</span>
            <div className="flex gap-1">
              <Button
                variant={isToday(parseISO(fechaFiltro)) ? "default" : "outline"}
                size="sm"
                className="h-6 px-2 text-[10px]"
                onClick={() => setFechaFiltro(format(new Date(), "yyyy-MM-dd"))}
              >
                Hoy
              </Button>
              <Button
                variant={isTomorrow(parseISO(fechaFiltro)) ? "default" : "outline"}
                size="sm"
                className="h-6 px-2 text-[10px]"
                onClick={() => setFechaFiltro(format(addDays(new Date(), 1), "yyyy-MM-dd"))}
              >
                Mañana
              </Button>
              <Input
                type="date"
                value={fechaFiltro}
                onChange={(e) => setFechaFiltro(e.target.value)}
                className="h-6 w-[105px] text-[10px] px-1.5"
              />
            </div>
          </div>
        </div>

        {/* Lista de Reservas por Sucursal */}
        <div className="space-y-3">
          {reservasPorSucursal.map(({ sucursal, reservas }) => (
            <Card key={sucursal.id}>
              <CardHeader className="p-3 pb-2">
                <div className="flex items-center justify-between">
                  <CardTitle className="text-sm flex items-center gap-2">
                    <MapPin className="w-4 h-4" />
                    {sucursal.nombre}
                  </CardTitle>
                  <Badge variant={reservas.length > 0 ? "default" : "secondary"} className="text-[10px]">
                    {reservas.length} reserva{reservas.length !== 1 ? "s" : ""}
                  </Badge>
                </div>
              </CardHeader>
              <CardContent className="p-3 pt-0">
                {reservas.length === 0 ? (
                  <p className="text-xs text-muted-foreground text-center py-3">Sin reservas para {formatFechaLabel(fechaFiltro)}</p>
                ) : (
                  <div className="space-y-2">
                    {reservas.map((reserva) => (
                      <div
                        key={reserva.id}
                        className="p-2.5 rounded-lg bg-muted/50 border text-xs"
                      >
                        <div className="flex justify-between items-start gap-2 mb-1.5">
                          <div className="flex-1 min-w-0">
                            <span className="font-medium">{reserva.nombre_cliente}</span>
                            <span className="text-muted-foreground ml-2">· {getZonaNombre(reserva.zona_id)}</span>
                          </div>
                          {getEstadoBadge(reserva.estado)}
                        </div>
                        <div className="flex flex-wrap gap-x-3 gap-y-0.5 text-muted-foreground text-[10px] mb-1.5">
                          <span className="flex items-center gap-1">
                            <Clock className="w-2.5 h-2.5" />
                            {reserva.hora.slice(0, 5)}
                          </span>
                          <span className="flex items-center gap-1">
                            <Users className="w-2.5 h-2.5" />
                            {reserva.num_personas} personas
                          </span>
                          {reserva.telefono && (
                            <a href={`tel:${reserva.telefono}`} className="flex items-center gap-1 text-primary">
                              <Phone className="w-2.5 h-2.5" />
                              {reserva.telefono}
                            </a>
                          )}
                        </div>
                        {reserva.notas && (
                          <p className="text-[10px] text-muted-foreground italic mb-1.5 line-clamp-1">{reserva.notas}</p>
                        )}
                        <div className="flex justify-end gap-1">
                          <Button
                            variant="ghost"
                            size="sm"
                            className="h-6 px-2 text-[10px]"
                            onClick={() => openEditReservaDialog(reserva)}
                          >
                            <Edit2 className="w-2.5 h-2.5 mr-1" />
                            Editar
                          </Button>
                          {reserva.estado === "confirmada" && (
                            <Button
                              variant="ghost"
                              size="sm"
                              className="h-6 px-2 text-[10px] text-destructive"
                              onClick={() => handleCancelar(reserva.id)}
                            >
                              <X className="w-2.5 h-2.5 mr-1" />
                              Cancelar
                            </Button>
                          )}
                          <AlertDialog>
                            <AlertDialogTrigger asChild>
                              <Button variant="ghost" size="icon" className="h-6 w-6 text-destructive">
                                <Trash2 className="w-2.5 h-2.5" />
                              </Button>
                            </AlertDialogTrigger>
                            <AlertDialogContent className="w-[calc(100vw-32px)] sm:max-w-md rounded-lg">
                              <AlertDialogHeader>
                                <AlertDialogTitle className="text-sm">¿Eliminar reservación?</AlertDialogTitle>
                                <AlertDialogDescription className="text-xs">
                                  Se eliminará permanentemente la reserva de {reserva.nombre_cliente}.
                                </AlertDialogDescription>
                              </AlertDialogHeader>
                              <AlertDialogFooter className="gap-2">
                                <AlertDialogCancel className="h-8 text-xs">No</AlertDialogCancel>
                                <AlertDialogAction onClick={() => handleEliminar(reserva.id)} className="h-8 text-xs">
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
          ))}
        </div>

        {reservasPorSucursal.length === 0 && (
          <Card className="text-center py-8">
            <CardContent>
              <CalendarDays className="w-10 h-10 mx-auto text-muted-foreground mb-3" />
              <p className="text-sm text-muted-foreground">No hay reservaciones para mostrar</p>
            </CardContent>
          </Card>
        )}

        {/* Dialog para crear/editar reserva */}
        <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
          <DialogContent className="w-[calc(100vw-24px)] sm:max-w-md max-h-[85vh] overflow-y-auto rounded-lg">
            <DialogHeader>
              <DialogTitle className="text-base">
                {editingReserva ? "Editar Reservación" : "Nueva Reservación"}
              </DialogTitle>
              <DialogDescription className="text-xs">
                {editingReserva ? "Modifica los datos de la reserva" : "Registra una reserva para cualquier sucursal"}
              </DialogDescription>
            </DialogHeader>
            <form onSubmit={handleSubmit} className="space-y-3">
              <div className="grid grid-cols-2 gap-2">
                <div className="space-y-1">
                  <Label className="text-xs">Sucursal *</Label>
                  <Select value={formSucursal} onValueChange={(v) => { setFormSucursal(v); setFormZona(""); }}>
                    <SelectTrigger className="h-8 text-xs">
                      <SelectValue placeholder="Seleccionar" />
                    </SelectTrigger>
                    <SelectContent>
                      {sucursales.map((s) => (
                        <SelectItem key={s.id} value={s.id} className="text-xs">{s.nombre}</SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
                <div className="space-y-1">
                  <Label className="text-xs">Zona *</Label>
                  <Select value={formZona} onValueChange={setFormZona} disabled={!formSucursal}>
                    <SelectTrigger className="h-8 text-xs">
                      <SelectValue placeholder="Seleccionar" />
                    </SelectTrigger>
                    <SelectContent>
                      {getZonasBySucursal(formSucursal).map((z) => (
                        <SelectItem key={z.id} value={z.id} className="text-xs">{z.nombre}</SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
              </div>

              <div className="space-y-1">
                <Label className="text-xs">Nombre del cliente *</Label>
                <Input
                  value={formNombre}
                  onChange={(e) => setFormNombre(e.target.value)}
                  placeholder="Nombre completo"
                  required
                  className="h-8 text-sm"
                />
              </div>

              <div className="grid grid-cols-2 gap-2">
                <div className="space-y-1">
                  <Label className="text-xs">Teléfono</Label>
                  <Input
                    value={formTelefono}
                    onChange={(e) => setFormTelefono(e.target.value)}
                    placeholder="Opcional"
                    className="h-8 text-sm"
                  />
                </div>
                <div className="space-y-1">
                  <Label className="text-xs">Personas *</Label>
                  <Input
                    type="number"
                    min="1"
                    max="50"
                    value={formPersonas}
                    onChange={(e) => setFormPersonas(e.target.value)}
                    className="h-8 text-sm"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-2">
                <div className="space-y-1">
                  <Label className="text-xs">Fecha *</Label>
                  <Input
                    type="date"
                    value={formFecha}
                    onChange={(e) => setFormFecha(e.target.value)}
                    required
                    className="h-8 text-sm"
                  />
                </div>
                <div className="space-y-1">
                  <Label className="text-xs">Hora *</Label>
                  <Input
                    type="time"
                    value={formHora}
                    onChange={(e) => setFormHora(e.target.value)}
                    required
                    className="h-8 text-sm"
                  />
                </div>
              </div>

              <div className="space-y-1">
                <Label className="text-xs">Notas</Label>
                <Textarea
                  value={formNotas}
                  onChange={(e) => setFormNotas(e.target.value)}
                  placeholder="Ej: Cumpleaños, mesa especial..."
                  rows={2}
                  className="text-sm"
                />
              </div>

              <div className="space-y-1">
                <Label className="text-xs">Registrado por</Label>
                <Input
                  value={formRegistradoPor}
                  onChange={(e) => setFormRegistradoPor(e.target.value)}
                  placeholder="Tu nombre"
                  className="h-8 text-sm"
                />
              </div>

              <Button type="submit" className="w-full h-9" disabled={isLoading}>
                {isLoading ? "Guardando..." : editingReserva ? "Guardar Cambios" : "Crear Reservación"}
              </Button>
            </form>
          </DialogContent>
        </Dialog>
      </div>
    </div>
  );
}
