import { useState, useEffect } from "react";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group";
import { Calendar } from "@/components/ui/calendar";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { toast } from "sonner";
import { CalendarIcon, DollarSign, CheckCircle2 } from "lucide-react";
import { format } from "date-fns";
import { es } from "date-fns/locale";
import { cn } from "@/lib/utils";

interface Sucursal {
  id: string;
  nombre: string;
}

interface AdminCorteDialogProps {
  onSuccess?: () => void;
}

export function AdminCorteDialog({ onSuccess }: AdminCorteDialogProps) {
  const [open, setOpen] = useState(false);
  const [isSuccess, setIsSuccess] = useState(false);
  const [sucursales, setSucursales] = useState<Sucursal[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  
  // Form state
  const [fechaVenta, setFechaVenta] = useState<Date>(new Date());
  const [sucursalId, setSucursalId] = useState("");
  const [tipoCorte, setTipoCorte] = useState<"momento" | "cierre">("cierre");
  const [corteX, setCorteX] = useState("");
  const [tarjetas, setTarjetas] = useState("");
  const [efectivo, setEfectivo] = useState("");
  const [cobradas, setCobradas] = useState("");
  const [porCobrar, setPorCobrar] = useState("");
  const [total, setTotal] = useState("");
  
  // Desglose tarjetas
  const [tarjetasBanregio, setTarjetasBanregio] = useState("");
  const [tarjetasMercadopago, setTarjetasMercadopago] = useState("");
  const [tarjetasHaycash, setTarjetasHaycash] = useState("");
  
  // Apps delivery
  const [rappi, setRappi] = useState("");
  const [uber, setUber] = useState("");
  
  // Gastos cierre
  const [pagoProveedores, setPagoProveedores] = useState("");
  const [salarios, setSalarios] = useState("");
  const [propinas, setPropinas] = useState("");
  const [compras, setCompras] = useState("");
  const [pagoServicios, setPagoServicios] = useState("");

  const SOLARES_ID = "757d25e0-ce84-4d6f-a68a-d4639d3e409f";
  const CERVECERIA_ID = "79324e7b-c8ef-4355-b2b1-6965346a0ab1";
  const esConPlataformas = sucursalId === SOLARES_ID || sucursalId === CERVECERIA_ID;

  useEffect(() => {
    if (open) {
      fetchSucursales();
    }
  }, [open]);

  // Auto-calculate tarjetas for cierre
  useEffect(() => {
    if (tipoCorte === "cierre") {
      const banregio = parseFloat(tarjetasBanregio) || 0;
      const mercadopago = parseFloat(tarjetasMercadopago) || 0;
      const haycash = parseFloat(tarjetasHaycash) || 0;
      setTarjetas((banregio + mercadopago + haycash).toFixed(2));
    }
  }, [tipoCorte, tarjetasBanregio, tarjetasMercadopago, tarjetasHaycash]);

  // Auto-calculate total
  useEffect(() => {
    const tarjetasNum = parseFloat(tarjetas) || 0;
    const efectivoNum = parseFloat(efectivo) || 0;
    const porCobrarNum = parseFloat(porCobrar) || 0;
    setTotal((tarjetasNum + efectivoNum + porCobrarNum).toFixed(2));
  }, [tarjetas, efectivo, porCobrar]);

  const fetchSucursales = async () => {
    const { data } = await supabase.from("sucursales").select("id, nombre").order("nombre");
    if (data) setSucursales(data);
  };

  const resetForm = () => {
    setFechaVenta(new Date());
    setSucursalId("");
    setTipoCorte("cierre");
    setCorteX("");
    setTarjetas("");
    setEfectivo("");
    setCobradas("");
    setPorCobrar("");
    setTotal("");
    setTarjetasBanregio("");
    setTarjetasMercadopago("");
    setTarjetasHaycash("");
    setRappi("");
    setUber("");
    setPagoProveedores("");
    setSalarios("");
    setPropinas("");
    setCompras("");
    setPagoServicios("");
    setIsSuccess(false);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!sucursalId) {
      toast.error("Selecciona una sucursal");
      return;
    }

    setIsLoading(true);

    const insertData = {
      sucursal_id: sucursalId,
      tipo_corte: tipoCorte,
      fecha_venta: format(fechaVenta, "yyyy-MM-dd"),
      corte_x: parseFloat(corteX) || 0,
      tarjetas: parseFloat(tarjetas) || 0,
      efectivo: parseFloat(efectivo) || 0,
      cobradas: parseFloat(cobradas) || 0,
      por_cobrar: parseFloat(porCobrar) || 0,
      total: parseFloat(total) || 0,
      pago_proveedores: tipoCorte === "cierre" ? (parseFloat(pagoProveedores) || 0) : 0,
      salarios: tipoCorte === "cierre" ? (parseFloat(salarios) || 0) : 0,
      propinas: tipoCorte === "cierre" ? (parseFloat(propinas) || 0) : 0,
      compras: tipoCorte === "cierre" ? (parseFloat(compras) || 0) : 0,
      pago_servicios: tipoCorte === "cierre" ? (parseFloat(pagoServicios) || 0) : 0,
      tarjetas_banregio: tipoCorte === "cierre" ? (parseFloat(tarjetasBanregio) || 0) : 0,
      tarjetas_mercadopago: tipoCorte === "cierre" ? (parseFloat(tarjetasMercadopago) || 0) : 0,
      tarjetas_haycash: tipoCorte === "cierre" ? (parseFloat(tarjetasHaycash) || 0) : 0,
      rappi: esConPlataformas ? (parseFloat(rappi) || 0) : 0,
      uber: esConPlataformas ? (parseFloat(uber) || 0) : 0,
    };

    const { error } = await supabase.from("cortes_caja").insert(insertData as any);
    setIsLoading(false);

    if (error) {
      toast.error("Error al guardar el corte");
      return;
    }

    setIsSuccess(true);
    toast.success("Corte registrado correctamente");
    onSuccess?.();
  };

  const handleClose = () => {
    setOpen(false);
    setTimeout(resetForm, 300);
  };

  const handleInputChange = (setter: (val: string) => void) => (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value.replace(",", ".");
    if (/^[0-9]*\.?[0-9]*$/.test(value) || value === "") {
      setter(value);
    }
  };

  return (
    <Dialog open={open} onOpenChange={(val) => val ? setOpen(true) : handleClose()}>
      <DialogTrigger asChild>
        <Button variant="outline" className="gap-2">
          <DollarSign className="h-4 w-4" />
          Registrar Corte (Admin)
        </Button>
      </DialogTrigger>
      <DialogContent className="max-w-lg max-h-[90vh] overflow-y-auto">
        {isSuccess ? (
          <div className="py-8 text-center">
            <CheckCircle2 className="w-16 h-16 text-primary mx-auto mb-4" />
            <h3 className="text-xl font-bold mb-2">¡Corte Registrado!</h3>
            <p className="text-muted-foreground mb-4">
              Fecha: {format(fechaVenta, "dd MMMM yyyy", { locale: es })}
            </p>
            <div className="flex gap-2 justify-center">
              <Button variant="outline" onClick={handleClose}>Cerrar</Button>
              <Button onClick={resetForm}>Registrar otro</Button>
            </div>
          </div>
        ) : (
          <>
            <DialogHeader>
              <DialogTitle>Registrar Corte (Admin)</DialogTitle>
              <DialogDescription>
                Registra un corte de caja con fecha personalizada
              </DialogDescription>
            </DialogHeader>
            
            <form onSubmit={handleSubmit} className="space-y-4">
              {/* Fecha de venta */}
              <div className="space-y-2">
                <Label>Fecha de Venta</Label>
                <Popover>
                  <PopoverTrigger asChild>
                    <Button variant="outline" className="w-full justify-start text-left font-normal">
                      <CalendarIcon className="mr-2 h-4 w-4" />
                      {format(fechaVenta, "PPP", { locale: es })}
                    </Button>
                  </PopoverTrigger>
                  <PopoverContent className="w-auto p-0" align="start">
                    <Calendar
                      mode="single"
                      selected={fechaVenta}
                      onSelect={(date) => date && setFechaVenta(date)}
                      locale={es}
                      className="pointer-events-auto"
                    />
                  </PopoverContent>
                </Popover>
              </div>

              {/* Sucursal */}
              <div className="space-y-2">
                <Label>Sucursal</Label>
                <Select value={sucursalId} onValueChange={setSucursalId}>
                  <SelectTrigger>
                    <SelectValue placeholder="Selecciona sucursal" />
                  </SelectTrigger>
                  <SelectContent>
                    {sucursales.map((s) => (
                      <SelectItem key={s.id} value={s.id}>{s.nombre}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              {/* Tipo de corte */}
              <div className="space-y-2">
                <Label>Tipo de Corte</Label>
                <RadioGroup value={tipoCorte} onValueChange={(v) => setTipoCorte(v as "momento" | "cierre")} className="flex gap-4">
                  <div className="flex items-center space-x-2">
                    <RadioGroupItem value="momento" id="admin-momento" />
                    <Label htmlFor="admin-momento" className="font-normal cursor-pointer">Del Momento</Label>
                  </div>
                  <div className="flex items-center space-x-2">
                    <RadioGroupItem value="cierre" id="admin-cierre" />
                    <Label htmlFor="admin-cierre" className="font-normal cursor-pointer">De Cierre</Label>
                  </div>
                </RadioGroup>
              </div>

              {/* Campos principales */}
              <div className="grid grid-cols-2 gap-3">
                <div className="space-y-1">
                  <Label className="text-xs">Corte X</Label>
                  <Input type="text" inputMode="decimal" placeholder="0.00" value={corteX} onChange={handleInputChange(setCorteX)} />
                </div>
                <div className="space-y-1">
                  <Label className="text-xs">Efectivo</Label>
                  <Input type="text" inputMode="decimal" placeholder="0.00" value={efectivo} onChange={handleInputChange(setEfectivo)} />
                </div>
              </div>

              {/* Desglose tarjetas para cierre */}
              {tipoCorte === "cierre" ? (
                <div className="space-y-3 border-t pt-3">
                  <Label className="text-sm font-medium">Desglose de Tarjetas</Label>
                  <div className="grid grid-cols-2 gap-3">
                    <div className="space-y-1">
                      <Label className="text-xs">Banregio</Label>
                      <Input type="text" inputMode="decimal" placeholder="0.00" value={tarjetasBanregio} onChange={handleInputChange(setTarjetasBanregio)} />
                    </div>
                    <div className="space-y-1">
                      <Label className="text-xs">MercadoPago</Label>
                      <Input type="text" inputMode="decimal" placeholder="0.00" value={tarjetasMercadopago} onChange={handleInputChange(setTarjetasMercadopago)} />
                    </div>
                    <div className="space-y-1">
                      <Label className="text-xs">HayCash</Label>
                      <Input type="text" inputMode="decimal" placeholder="0.00" value={tarjetasHaycash} onChange={handleInputChange(setTarjetasHaycash)} />
                    </div>
                    <div className="space-y-1">
                      <Label className="text-xs">Total Tarjetas</Label>
                      <Input type="text" value={tarjetas} readOnly className="bg-muted" />
                    </div>
                  </div>
                </div>
              ) : (
                <div className="space-y-1">
                  <Label className="text-xs">Tarjetas</Label>
                  <Input type="text" inputMode="decimal" placeholder="0.00" value={tarjetas} onChange={handleInputChange(setTarjetas)} />
                </div>
              )}

              {/* Cobradas / Por cobrar o Rappi/Uber */}
              {esConPlataformas ? (
                <div className="grid grid-cols-2 gap-3">
                  <div className="space-y-1">
                    <Label className="text-xs">Rappi</Label>
                    <Input type="text" inputMode="decimal" placeholder="0.00" value={rappi} onChange={handleInputChange(setRappi)} />
                  </div>
                  <div className="space-y-1">
                    <Label className="text-xs">Uber</Label>
                    <Input type="text" inputMode="decimal" placeholder="0.00" value={uber} onChange={handleInputChange(setUber)} />
                  </div>
                </div>
              ) : (
                <div className="grid grid-cols-2 gap-3">
                  <div className="space-y-1">
                    <Label className="text-xs">Cobradas</Label>
                    <Input type="text" inputMode="decimal" placeholder="0.00" value={cobradas} onChange={handleInputChange(setCobradas)} />
                  </div>
                  <div className="space-y-1">
                    <Label className="text-xs">Por Cobrar</Label>
                    <Input type="text" inputMode="decimal" placeholder="0.00" value={porCobrar} onChange={handleInputChange(setPorCobrar)} />
                  </div>
                </div>
              )}

              {/* Gastos (solo cierre) */}
              {tipoCorte === "cierre" && (
                <div className="space-y-3 border-t pt-3">
                  <Label className="text-sm font-medium">Gastos del día</Label>
                  <div className="grid grid-cols-2 gap-3">
                    <div className="space-y-1">
                      <Label className="text-xs">Pago Proveedores</Label>
                      <Input type="text" inputMode="decimal" placeholder="0.00" value={pagoProveedores} onChange={handleInputChange(setPagoProveedores)} />
                    </div>
                    <div className="space-y-1">
                      <Label className="text-xs">Salarios</Label>
                      <Input type="text" inputMode="decimal" placeholder="0.00" value={salarios} onChange={handleInputChange(setSalarios)} />
                    </div>
                    <div className="space-y-1">
                      <Label className="text-xs">Propinas</Label>
                      <Input type="text" inputMode="decimal" placeholder="0.00" value={propinas} onChange={handleInputChange(setPropinas)} />
                    </div>
                    <div className="space-y-1">
                      <Label className="text-xs">Compras</Label>
                      <Input type="text" inputMode="decimal" placeholder="0.00" value={compras} onChange={handleInputChange(setCompras)} />
                    </div>
                    <div className="space-y-1 col-span-2">
                      <Label className="text-xs">Pago de Servicios</Label>
                      <Input type="text" inputMode="decimal" placeholder="0.00" value={pagoServicios} onChange={handleInputChange(setPagoServicios)} />
                    </div>
                  </div>
                </div>
              )}

              {/* Total */}
              <div className="space-y-2 border-t pt-3">
                <Label className="text-sm font-medium">Total Calculado</Label>
                <Input type="text" value={total} readOnly className="bg-muted text-lg font-bold" />
              </div>

              <Button type="submit" className="w-full" disabled={isLoading}>
                {isLoading ? "Guardando..." : "Registrar Corte"}
              </Button>
            </form>
          </>
        )}
      </DialogContent>
    </Dialog>
  );
}
