import { useState, useEffect } from "react";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group";
import { useToast } from "@/hooks/use-toast";
import { CheckCircle2, Send, Store, AlertCircle } from "lucide-react";
import { z } from "zod";

// Logo de La Ola
import logoLaOla from "@/assets/logo-la-ola.jpeg";

interface Sucursal {
  id: string;
  nombre: string;
}

// Validación con Zod
const corteSchema = z.object({
  sucursal_id: z.string().uuid("Selecciona una sucursal"),
  tipo_corte: z.enum(["momento", "cierre"]),
  corte_x: z.number().min(0, "Debe ser mayor o igual a 0").max(9999999999, "Número muy grande"),
  tarjetas: z.number().min(0, "Debe ser mayor o igual a 0").max(9999999999, "Número muy grande"),
  efectivo: z.number().min(0, "Debe ser mayor o igual a 0").max(9999999999, "Número muy grande"),
  cobradas: z.number().min(0, "Debe ser mayor o igual a 0").max(9999999999, "Número muy grande"),
  por_cobrar: z.number().min(0, "Debe ser mayor o igual a 0").max(9999999999, "Número muy grande"),
  total: z.number().min(0, "Debe ser mayor o igual a 0").max(9999999999, "Número muy grande"),
  // Campos opcionales para cierre
  pago_proveedores: z.number().min(0).max(9999999999).optional(),
  salarios: z.number().min(0).max(9999999999).optional(),
  propinas: z.number().min(0).max(9999999999).optional(),
  compras: z.number().min(0).max(9999999999).optional(),
  pago_servicios: z.number().min(0).max(9999999999).optional(),
});

const TOLERANCIA_MXN = 50;

export default function Corte() {
  const [sucursales, setSucursales] = useState<Sucursal[]>([]);
  const [sucursalId, setSucursalId] = useState("");
  const [tipoCorte, setTipoCorte] = useState<"momento" | "cierre">("momento");
  const [corteX, setCorteX] = useState("");
  const [tarjetas, setTarjetas] = useState("");
  const [efectivo, setEfectivo] = useState("");
  const [cobradas, setCobradas] = useState("");
  const [porCobrar, setPorCobrar] = useState("");
  const [total, setTotal] = useState("");
  
  // Campos opcionales para cierre
  const [pagoProveedores, setPagoProveedores] = useState("");
  const [salarios, setSalarios] = useState("");
  const [propinas, setPropinas] = useState("");
  const [compras, setCompras] = useState("");
  const [pagoServicios, setPagoServicios] = useState("");
  
  const [isLoading, setIsLoading] = useState(false);
  const [isSuccess, setIsSuccess] = useState(false);
  const [errorValidacion, setErrorValidacion] = useState("");
  const { toast } = useToast();

  useEffect(() => {
    fetchSucursales();
  }, []);

  // Calcular total automáticamente
  useEffect(() => {
    const tarjetasNum = parseFloat(tarjetas) || 0;
    const efectivoNum = parseFloat(efectivo) || 0;
    const cobradasNum = parseFloat(cobradas) || 0;
    const porCobrarNum = parseFloat(porCobrar) || 0;
    
    const totalCalculado = tarjetasNum + efectivoNum + cobradasNum + porCobrarNum;
    setTotal(totalCalculado.toFixed(2));
  }, [tarjetas, efectivo, cobradas, porCobrar]);

  // Validar diferencia con Corte X
  useEffect(() => {
    const corteXNum = parseFloat(corteX) || 0;
    const totalNum = parseFloat(total) || 0;
    const diferencia = Math.abs(totalNum - corteXNum);
    
    if (corteXNum > 0 && totalNum > 0 && diferencia > TOLERANCIA_MXN) {
      setErrorValidacion(
        `El Total ($${totalNum.toLocaleString("es-MX", { minimumFractionDigits: 2 })}) difiere del Corte X ($${corteXNum.toLocaleString("es-MX", { minimumFractionDigits: 2 })}) por $${diferencia.toLocaleString("es-MX", { minimumFractionDigits: 2 })}. La diferencia máxima permitida es de $${TOLERANCIA_MXN} MXN.`
      );
    } else {
      setErrorValidacion("");
    }
  }, [corteX, total]);

  const fetchSucursales = async () => {
    const { data, error } = await supabase
      .from("sucursales")
      .select("id, nombre")
      .order("nombre");

    if (error) {
      toast({
        title: "Error",
        description: "No se pudieron cargar las sucursales",
        variant: "destructive",
      });
      return;
    }

    setSucursales(data || []);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    // Verificar tolerancia antes de enviar
    if (errorValidacion) {
      toast({
        title: "No se puede enviar",
        description: errorValidacion,
        variant: "destructive",
      });
      return;
    }
    
    setIsLoading(true);

    // Validar datos
    const result = corteSchema.safeParse({
      sucursal_id: sucursalId,
      tipo_corte: tipoCorte,
      corte_x: parseFloat(corteX) || 0,
      tarjetas: parseFloat(tarjetas) || 0,
      efectivo: parseFloat(efectivo) || 0,
      cobradas: parseFloat(cobradas) || 0,
      por_cobrar: parseFloat(porCobrar) || 0,
      total: parseFloat(total) || 0,
      pago_proveedores: pagoProveedores ? parseFloat(pagoProveedores) : undefined,
      salarios: salarios ? parseFloat(salarios) : undefined,
      propinas: propinas ? parseFloat(propinas) : undefined,
      compras: compras ? parseFloat(compras) : undefined,
      pago_servicios: pagoServicios ? parseFloat(pagoServicios) : undefined,
    });

    if (!result.success) {
      toast({
        title: "Error de validación",
        description: result.error.errors[0]?.message || "Revisa los datos ingresados",
        variant: "destructive",
      });
      setIsLoading(false);
      return;
    }

    const insertData = {
      sucursal_id: sucursalId,
      tipo_corte: tipoCorte as "momento" | "cierre",
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
    };

    const { error } = await supabase.from("cortes_caja").insert(insertData);

    setIsLoading(false);

    if (error) {
      toast({
        title: "Error",
        description: "No se pudo enviar el corte. Intenta de nuevo.",
        variant: "destructive",
      });
      return;
    }

    setIsSuccess(true);
    toast({
      title: "¡Corte enviado!",
      description: "Los datos se registraron correctamente.",
    });
  };

  const handleNuevoCorte = () => {
    setIsSuccess(false);
    setSucursalId("");
    setTipoCorte("momento");
    setCorteX("");
    setTarjetas("");
    setEfectivo("");
    setCobradas("");
    setPorCobrar("");
    setTotal("");
    setPagoProveedores("");
    setSalarios("");
    setPropinas("");
    setCompras("");
    setPagoServicios("");
    setErrorValidacion("");
  };

  if (isSuccess) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-primary/5 to-secondary/10 flex items-center justify-center p-4">
        <Card className="w-full max-w-md text-center">
          <CardContent className="pt-10 pb-8">
            <CheckCircle2 className="w-20 h-20 text-green-500 mx-auto mb-6" />
            <h2 className="text-2xl font-bold text-foreground mb-2">
              ¡Corte Enviado!
            </h2>
            <p className="text-muted-foreground mb-6">
              Los datos se registraron correctamente en el sistema.
            </p>
            <Button onClick={handleNuevoCorte} className="w-full">
              Enviar otro corte
            </Button>
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-primary/5 to-secondary/10 flex items-center justify-center p-4">
      <Card className="w-full max-w-md">
        <CardHeader className="text-center">
          <div className="mx-auto mb-4 w-16 h-16 rounded-full overflow-hidden">
            <img src={logoLaOla} alt="La Ola" className="w-full h-full object-cover" />
          </div>
          <CardTitle className="text-2xl">Corte de Caja</CardTitle>
          <CardDescription>
            Ingresa los datos del corte de tu sucursal
          </CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit} className="space-y-6">
            {/* Selección de Sucursal */}
            <div className="space-y-2">
              <Label htmlFor="sucursal" className="flex items-center gap-2">
                <Store className="w-4 h-4" />
                Sucursal
              </Label>
              <Select value={sucursalId} onValueChange={setSucursalId}>
                <SelectTrigger>
                  <SelectValue placeholder="Selecciona tu sucursal" />
                </SelectTrigger>
                <SelectContent>
                  {sucursales.map((sucursal) => (
                    <SelectItem key={sucursal.id} value={sucursal.id}>
                      {sucursal.nombre}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            {/* Tipo de Corte */}
            <div className="space-y-3">
              <Label>Tipo de Corte</Label>
              <RadioGroup
                value={tipoCorte}
                onValueChange={(value) => setTipoCorte(value as "momento" | "cierre")}
                className="grid grid-cols-2 gap-4"
              >
                <div className="flex items-center space-x-2 border rounded-lg p-3 cursor-pointer hover:bg-accent transition-colors">
                  <RadioGroupItem value="momento" id="momento" />
                  <Label htmlFor="momento" className="cursor-pointer font-normal">
                    Del Momento
                  </Label>
                </div>
                <div className="flex items-center space-x-2 border rounded-lg p-3 cursor-pointer hover:bg-accent transition-colors">
                  <RadioGroupItem value="cierre" id="cierre" />
                  <Label htmlFor="cierre" className="cursor-pointer font-normal">
                    De Cierre
                  </Label>
                </div>
              </RadioGroup>
            </div>

            {/* Campos numéricos principales */}
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="corte_x">Corte X</Label>
                <Input
                  id="corte_x"
                  type="number"
                  step="0.01"
                  min="0"
                  placeholder="0.00"
                  value={corteX}
                  onChange={(e) => setCorteX(e.target.value)}
                  required
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="tarjetas">Cobrado con tarjeta</Label>
                <Input
                  id="tarjetas"
                  type="number"
                  step="0.01"
                  min="0"
                  placeholder="0.00"
                  value={tarjetas}
                  onChange={(e) => setTarjetas(e.target.value)}
                  required
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="efectivo">Cobrado con efectivo</Label>
                <Input
                  id="efectivo"
                  type="number"
                  step="0.01"
                  min="0"
                  placeholder="0.00"
                  value={efectivo}
                  onChange={(e) => setEfectivo(e.target.value)}
                  required
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="cobradas">Cobradas</Label>
                <Input
                  id="cobradas"
                  type="number"
                  step="0.01"
                  min="0"
                  placeholder="0.00"
                  value={cobradas}
                  onChange={(e) => setCobradas(e.target.value)}
                  required
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="por_cobrar">Por cobrar</Label>
                <Input
                  id="por_cobrar"
                  type="number"
                  step="0.01"
                  min="0"
                  placeholder="0.00"
                  value={porCobrar}
                  onChange={(e) => setPorCobrar(e.target.value)}
                  required
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="total">Total (calculado)</Label>
                <Input
                  id="total"
                  type="number"
                  step="0.01"
                  min="0"
                  placeholder="0.00"
                  value={total}
                  readOnly
                  className="bg-muted"
                />
              </div>
            </div>

            {/* Error de validación de tolerancia */}
            {errorValidacion && (
              <div className="flex items-start gap-2 p-3 rounded-lg bg-destructive/10 text-destructive text-sm">
                <AlertCircle className="w-5 h-5 flex-shrink-0 mt-0.5" />
                <span>{errorValidacion}</span>
              </div>
            )}

            {/* Campos opcionales para Cierre */}
            {tipoCorte === "cierre" && (
              <div className="space-y-4 pt-4 border-t">
                <Label className="text-base font-semibold">Gastos del día (opcionales)</Label>
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label htmlFor="pago_proveedores">Pago a proveedores</Label>
                    <Input
                      id="pago_proveedores"
                      type="number"
                      step="0.01"
                      min="0"
                      placeholder="0.00"
                      value={pagoProveedores}
                      onChange={(e) => setPagoProveedores(e.target.value)}
                    />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="salarios">Salarios</Label>
                    <Input
                      id="salarios"
                      type="number"
                      step="0.01"
                      min="0"
                      placeholder="0.00"
                      value={salarios}
                      onChange={(e) => setSalarios(e.target.value)}
                    />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="propinas">Propinas</Label>
                    <Input
                      id="propinas"
                      type="number"
                      step="0.01"
                      min="0"
                      placeholder="0.00"
                      value={propinas}
                      onChange={(e) => setPropinas(e.target.value)}
                    />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="compras">Compras</Label>
                    <Input
                      id="compras"
                      type="number"
                      step="0.01"
                      min="0"
                      placeholder="0.00"
                      value={compras}
                      onChange={(e) => setCompras(e.target.value)}
                    />
                  </div>
                  <div className="space-y-2 col-span-2">
                    <Label htmlFor="pago_servicios">Pago de servicios</Label>
                    <Input
                      id="pago_servicios"
                      type="number"
                      step="0.01"
                      min="0"
                      placeholder="0.00"
                      value={pagoServicios}
                      onChange={(e) => setPagoServicios(e.target.value)}
                    />
                  </div>
                </div>
              </div>
            )}

            <Button
              type="submit"
              className="w-full"
              disabled={isLoading || !sucursalId || !!errorValidacion}
            >
              {isLoading ? (
                "Enviando..."
              ) : (
                <>
                  <Send className="w-4 h-4 mr-2" />
                  Enviar Corte
                </>
              )}
            </Button>
          </form>
        </CardContent>
      </Card>
    </div>
  );
}
