import { useState, useEffect } from "react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Calendar } from "@/components/ui/calendar";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group";
import { CalendarIcon, ArrowLeft, CheckCircle2, AlertTriangle, Lock } from "lucide-react";
import { useNavigate } from "react-router-dom";
import { supabase } from "@/integrations/supabase/client";
import { format } from "date-fns";
import { es } from "date-fns/locale";
import { toast } from "sonner";
import { cn } from "@/lib/utils";
import logoLaOla from "@/assets/logo-la-ola.jpeg";
import { DateRange } from "react-day-picker";

const PIN_CONTADORAS = "8534";

// Sucursales que tienen plataformas de delivery
const SUCURSALES_CON_PLATAFORMAS = ["Solares", "Cervecería"];

interface Sucursal {
  id: string;
  nombre: string;
}

export default function Contadoras() {
  const navigate = useNavigate();
  const [autenticado, setAutenticado] = useState(false);
  const [pin, setPin] = useState("");
  const [pinError, setPinError] = useState(false);
  
  const [sucursales, setSucursales] = useState<Sucursal[]>([]);
  const [sucursalId, setSucursalId] = useState("");
  const [sucursalNombre, setSucursalNombre] = useState("");
  const [dateRange, setDateRange] = useState<DateRange | undefined>(undefined);
  const [plataforma, setPlataforma] = useState<"rappi" | "uber" | "total">("total");
  const [cantidadIngresada, setCantidadIngresada] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const [resultado, setResultado] = useState<{
    cantidadSistema: number;
    diferencia: number;
    tieneDiscrepancia: boolean;
  } | null>(null);

  const tienePlataformas = SUCURSALES_CON_PLATAFORMAS.includes(sucursalNombre);

  useEffect(() => {
    const fetchSucursales = async () => {
      const { data } = await supabase.from("sucursales").select("id, nombre").order("nombre");
      if (data) setSucursales(data);
    };
    fetchSucursales();
  }, []);

  const handleSucursalChange = (id: string) => {
    setSucursalId(id);
    const suc = sucursales.find(s => s.id === id);
    setSucursalNombre(suc?.nombre || "");
    // Resetear plataforma si no tiene plataformas
    if (suc && !SUCURSALES_CON_PLATAFORMAS.includes(suc.nombre)) {
      setPlataforma("total");
    }
  };

  const handlePinSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (pin === PIN_CONTADORAS) {
      setAutenticado(true);
      setPinError(false);
    } else {
      setPinError(true);
      setPin("");
    }
  };

  const handleVerificar = async () => {
    if (!sucursalId || !dateRange?.from || !dateRange?.to || !cantidadIngresada) {
      toast.error("Por favor completa todos los campos");
      return;
    }

    const cantidad = parseFloat(cantidadIngresada);
    if (isNaN(cantidad)) {
      toast.error("La cantidad debe ser un número válido");
      return;
    }

    setIsLoading(true);
    setResultado(null);

    try {
      // Obtener los cortes de cierre del período seleccionado para la sucursal
      const { data: cortes, error } = await supabase
        .from("cortes_caja")
        .select("total, rappi, uber")
        .eq("sucursal_id", sucursalId)
        .eq("tipo_corte", "cierre")
        .gte("fecha_venta", format(dateRange.from, "yyyy-MM-dd"))
        .lte("fecha_venta", format(dateRange.to, "yyyy-MM-dd"));

      if (error) throw error;

      // Calcular según la plataforma seleccionada
      let cantidadSistema = 0;
      if (plataforma === "rappi") {
        cantidadSistema = cortes?.reduce((sum, corte) => sum + Number(corte.rappi || 0), 0) || 0;
      } else if (plataforma === "uber") {
        cantidadSistema = cortes?.reduce((sum, corte) => sum + Number(corte.uber || 0), 0) || 0;
      } else {
        // Total: suma rappi + uber
        cantidadSistema = cortes?.reduce((sum, corte) => 
          sum + Number(corte.rappi || 0) + Number(corte.uber || 0), 0) || 0;
      }

      const diferencia = cantidad - cantidadSistema;
      const tieneDiscrepancia = Math.abs(diferencia) > 100;

      // Guardar el registro con la plataforma
      await supabase.from("verificaciones_plataforma").insert({
        sucursal_id: sucursalId,
        fecha_inicio: format(dateRange.from, "yyyy-MM-dd"),
        fecha_fin: format(dateRange.to, "yyyy-MM-dd"),
        cantidad_reportada: cantidad,
        cantidad_sistema: cantidadSistema,
        diferencia: diferencia,
        tiene_discrepancia: tieneDiscrepancia,
        registrado_por: "Contadora",
        plataforma: plataforma
      });

      setResultado({
        cantidadSistema,
        diferencia,
        tieneDiscrepancia
      });

      if (tieneDiscrepancia) {
        toast.warning("¡Se detectó una discrepancia mayor a $100!");
      } else {
        toast.success("Los montos coinciden correctamente");
      }
    } catch (error) {
      console.error("Error al verificar:", error);
      toast.error("Error al procesar la verificación");
    } finally {
      setIsLoading(false);
    }
  };

  const formatMoney = (value: number) => {
    return new Intl.NumberFormat("es-MX", {
      style: "currency",
      currency: "MXN",
    }).format(value);
  };

  const limpiarFormulario = () => {
    setCantidadIngresada("");
    setDateRange(undefined);
    setResultado(null);
    setPlataforma("total");
  };

  // Pantalla de PIN
  if (!autenticado) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-primary/5 to-secondary/10 flex items-center justify-center p-4">
        <Card className="w-full max-w-sm">
          <CardHeader className="text-center">
            <div className="mx-auto mb-4 w-16 h-16 rounded-full overflow-hidden">
              <img src={logoLaOla} alt="La Ola" className="w-full h-full object-cover" />
            </div>
            <CardTitle className="flex items-center justify-center gap-2">
              <Lock className="w-5 h-5" />
              Contadoras
            </CardTitle>
            <CardDescription>Ingresa tu PIN de acceso</CardDescription>
          </CardHeader>
          <CardContent>
            <form onSubmit={handlePinSubmit} className="space-y-4">
              <div className="space-y-2">
                <Input
                  type="password"
                  inputMode="numeric"
                  maxLength={4}
                  placeholder="••••"
                  value={pin}
                  onChange={(e) => {
                    setPin(e.target.value.replace(/\D/g, ""));
                    setPinError(false);
                  }}
                  className={cn(
                    "text-center text-2xl tracking-widest",
                    pinError && "border-destructive"
                  )}
                  autoFocus
                />
                {pinError && (
                  <p className="text-sm text-destructive text-center">PIN incorrecto</p>
                )}
              </div>
              <Button type="submit" className="w-full" disabled={pin.length !== 4}>
                Ingresar
              </Button>
              <Button
                type="button"
                variant="ghost"
                className="w-full"
                onClick={() => navigate("/centro-de-operaciones")}
              >
                <ArrowLeft className="w-4 h-4 mr-2" />
                Volver
              </Button>
            </form>
          </CardContent>
        </Card>
      </div>
    );
  }

  // Pantalla principal
  return (
    <div className="min-h-screen bg-gradient-to-br from-primary/5 to-secondary/10 p-4">
      <div className="max-w-lg mx-auto space-y-4">
        <Button
          variant="ghost"
          onClick={() => navigate("/centro-de-operaciones")}
          className="mb-2"
        >
          <ArrowLeft className="w-4 h-4 mr-2" />
          Centro de Operaciones
        </Button>

        <Card>
          <CardHeader>
            <CardTitle>Verificación de Ingresos</CardTitle>
            <CardDescription>
              Compara el monto reportado con los cortes registrados
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            {/* Sucursal */}
            <div className="space-y-2">
              <Label>Sucursal</Label>
              <Select value={sucursalId} onValueChange={handleSucursalChange}>
                <SelectTrigger>
                  <SelectValue placeholder="Selecciona sucursal" />
                </SelectTrigger>
                <SelectContent>
                  {sucursales.map((suc) => (
                    <SelectItem key={suc.id} value={suc.id}>
                      {suc.nombre}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            {/* Plataforma (solo para sucursales con delivery) */}
            {tienePlataformas && (
              <div className="space-y-2">
                <Label>Plataforma</Label>
                <RadioGroup
                  value={plataforma}
                  onValueChange={(v) => setPlataforma(v as "rappi" | "uber" | "total")}
                  className="flex gap-4"
                >
                  <div className="flex items-center space-x-2">
                    <RadioGroupItem value="rappi" id="rappi" />
                    <Label htmlFor="rappi" className="cursor-pointer">Rappi</Label>
                  </div>
                  <div className="flex items-center space-x-2">
                    <RadioGroupItem value="uber" id="uber" />
                    <Label htmlFor="uber" className="cursor-pointer">Uber Eats</Label>
                  </div>
                  <div className="flex items-center space-x-2">
                    <RadioGroupItem value="total" id="total" />
                    <Label htmlFor="total" className="cursor-pointer">Ambas</Label>
                  </div>
                </RadioGroup>
              </div>
            )}

            {/* Período */}
            <div className="space-y-2">
              <Label>Período</Label>
              <Popover>
                <PopoverTrigger asChild>
                  <Button
                    variant="outline"
                    className={cn(
                      "w-full justify-start text-left font-normal",
                      !dateRange && "text-muted-foreground"
                    )}
                  >
                    <CalendarIcon className="mr-2 h-4 w-4" />
                    {dateRange?.from ? (
                      dateRange.to ? (
                        <>
                          {format(dateRange.from, "d MMM", { locale: es })} -{" "}
                          {format(dateRange.to, "d MMM yyyy", { locale: es })}
                        </>
                      ) : (
                        format(dateRange.from, "d MMM yyyy", { locale: es })
                      )
                    ) : (
                      "Selecciona fechas"
                    )}
                  </Button>
                </PopoverTrigger>
                <PopoverContent className="w-auto p-0" align="start">
                  <Calendar
                    mode="range"
                    selected={dateRange}
                    onSelect={setDateRange}
                    locale={es}
                    numberOfMonths={1}
                  />
                </PopoverContent>
              </Popover>
            </div>

            {/* Cantidad ingresada */}
            <div className="space-y-2">
              <Label>Cantidad ingresada a la plataforma</Label>
              <Input
                type="text"
                inputMode="decimal"
                placeholder="0.00"
                value={cantidadIngresada}
                onChange={(e) => setCantidadIngresada(e.target.value.replace(/[^0-9.]/g, ""))}
                className="text-lg"
              />
            </div>

            <Button
              onClick={handleVerificar}
              disabled={isLoading || !sucursalId || !dateRange?.from || !dateRange?.to || !cantidadIngresada}
              className="w-full"
            >
              {isLoading ? "Verificando..." : "Verificar"}
            </Button>

            {/* Resultado */}
            {resultado && (
              <Card className={cn(
                "mt-4 border-2",
                resultado.tieneDiscrepancia 
                  ? "border-destructive bg-destructive/5" 
                  : "border-primary bg-primary/5"
              )}>
                <CardContent className="pt-4 space-y-3">
                  <div className="flex items-center gap-2 justify-center">
                    {resultado.tieneDiscrepancia ? (
                      <>
                        <AlertTriangle className="w-6 h-6 text-destructive" />
                        <span className="font-semibold text-destructive">Discrepancia detectada</span>
                      </>
                    ) : (
                      <>
                        <CheckCircle2 className="w-6 h-6 text-primary" />
                        <span className="font-semibold text-primary">Los montos coinciden</span>
                      </>
                    )}
                  </div>

                  <div className="grid grid-cols-2 gap-2 text-sm">
                    <div className="text-muted-foreground">Reportado:</div>
                    <div className="text-right font-medium">
                      {formatMoney(parseFloat(cantidadIngresada) || 0)}
                    </div>
                    <div className="text-muted-foreground">Sistema:</div>
                    <div className="text-right font-medium">
                      {formatMoney(resultado.cantidadSistema)}
                    </div>
                    <div className="text-muted-foreground">Diferencia:</div>
                    <div className={cn(
                      "text-right font-bold",
                      resultado.tieneDiscrepancia ? "text-destructive" : "text-primary"
                    )}>
                      {formatMoney(resultado.diferencia)}
                    </div>
                  </div>

                  <Button
                    variant="outline"
                    className="w-full mt-2"
                    onClick={limpiarFormulario}
                  >
                    Nueva verificación
                  </Button>
                </CardContent>
              </Card>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
