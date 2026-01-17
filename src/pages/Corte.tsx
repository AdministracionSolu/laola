import { useState, useEffect } from "react";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group";
import { useToast } from "@/hooks/use-toast";
import { CheckCircle2, Send, Store } from "lucide-react";
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
  
  // Desglose de tarjetas para cierre
  const [tarjetasBanregio, setTarjetasBanregio] = useState("");
  const [tarjetasMercadopago, setTarjetasMercadopago] = useState("");
  const [tarjetasHaycash, setTarjetasHaycash] = useState("");
  
  // Apps de delivery (solo Solares)
  const [rappi, setRappi] = useState("");
  const [uber, setUber] = useState("");
  
  // Campos opcionales para cierre
  const [pagoProveedores, setPagoProveedores] = useState("");
  const [salarios, setSalarios] = useState("");
  const [propinas, setPropinas] = useState("");
  const [compras, setCompras] = useState("");
  const [pagoServicios, setPagoServicios] = useState("");
  
  // IDs de sucursales con plataformas de delivery
  const SOLARES_ID = "757d25e0-ce84-4d6f-a68a-d4639d3e409f";
  const CERVECERIA_ID = "79324e7b-c8ef-4355-b2b1-6965346a0ab1";
  const esConPlataformas = sucursalId === SOLARES_ID || sucursalId === CERVECERIA_ID;
  const [isLoading, setIsLoading] = useState(false);
  const [isSuccess, setIsSuccess] = useState(false);
  
  const { toast } = useToast();

  useEffect(() => {
    fetchSucursales();
  }, []);

  // Calcular tarjetas automáticamente para cierre (suma de terminales)
  useEffect(() => {
    if (tipoCorte === "cierre") {
      const banregio = parseFloat(tarjetasBanregio) || 0;
      const mercadopago = parseFloat(tarjetasMercadopago) || 0;
      const haycash = parseFloat(tarjetasHaycash) || 0;
      const totalTarjetas = banregio + mercadopago + haycash;
      setTarjetas(totalTarjetas.toFixed(2));
    }
  }, [tipoCorte, tarjetasBanregio, tarjetasMercadopago, tarjetasHaycash]);

  // Calcular total automáticamente: tarjetas + efectivo + por_cobrar + rappi + uber
  useEffect(() => {
    const tarjetasNum = parseFloat(tarjetas) || 0;
    const efectivoNum = parseFloat(efectivo) || 0;
    const porCobrarNum = parseFloat(porCobrar) || 0;
    const rappiNum = esConPlataformas ? (parseFloat(rappi) || 0) : 0;
    const uberNum = esConPlataformas ? (parseFloat(uber) || 0) : 0;
    
    const totalCalculado = tarjetasNum + efectivoNum + porCobrarNum + rappiNum + uberNum;
    setTotal(totalCalculado.toFixed(2));
  }, [tarjetas, efectivo, porCobrar, rappi, uber, esConPlataformas]);

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
      // Desglose de tarjetas (solo para cierre)
      tarjetas_banregio: tipoCorte === "cierre" ? (parseFloat(tarjetasBanregio) || 0) : 0,
      tarjetas_mercadopago: tipoCorte === "cierre" ? (parseFloat(tarjetasMercadopago) || 0) : 0,
      tarjetas_haycash: tipoCorte === "cierre" ? (parseFloat(tarjetasHaycash) || 0) : 0,
      // Apps de delivery (Solares y Cervecería)
      rappi: esConPlataformas ? (parseFloat(rappi) || 0) : 0,
      uber: esConPlataformas ? (parseFloat(uber) || 0) : 0,
    };

    const { error } = await supabase.from("cortes_caja").insert(insertData as any);

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
    // Reset desglose tarjetas
    setTarjetasBanregio("");
    setTarjetasMercadopago("");
    setTarjetasHaycash("");
    // Reset apps delivery
    setRappi("");
    setUber("");
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
                <div className="space-y-2">
                  <div className="flex items-center space-x-2 border rounded-lg p-3 cursor-pointer hover:bg-accent transition-colors">
                    <RadioGroupItem value="momento" id="momento" />
                    <Label htmlFor="momento" className="cursor-pointer font-normal">
                      Del Momento
                    </Label>
                  </div>
                  {tipoCorte === "momento" && (
                    <p className="text-xs text-muted-foreground px-1">
                      📸 Reporte parcial durante el turno. Usa este si aún no terminas el día.
                    </p>
                  )}
                </div>
                <div className="space-y-2">
                  <div className="flex items-center space-x-2 border rounded-lg p-3 cursor-pointer hover:bg-accent transition-colors">
                    <RadioGroupItem value="cierre" id="cierre" />
                    <Label htmlFor="cierre" className="cursor-pointer font-normal">
                      De Cierre
                    </Label>
                  </div>
                  {tipoCorte === "cierre" && (
                    <p className="text-xs text-muted-foreground px-1">
                      🔒 Reporte final del día. Solo usa este al cerrar la sucursal.
                    </p>
                  )}
                </div>
              </RadioGroup>
            </div>

            {/* Campos numéricos principales */}
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="corte_x">Corte X</Label>
                <Input
                  id="corte_x"
                  type="text"
                  inputMode="decimal"
                  placeholder="0.00"
                  value={corteX}
                  onChange={(e) => {
                    const value = e.target.value.replace(",", ".");
                    if (/^[0-9]*\.?[0-9]*$/.test(value) || value === "") {
                      setCorteX(value);
                    }
                  }}
                  required
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="efectivo">Cobrado con efectivo</Label>
                <Input
                  id="efectivo"
                  type="text"
                  inputMode="decimal"
                  placeholder="0.00"
                  value={efectivo}
                  onChange={(e) => {
                    const value = e.target.value.replace(",", ".");
                    if (/^[0-9]*\.?[0-9]*$/.test(value) || value === "") {
                      setEfectivo(value);
                    }
                  }}
                  required
                />
              </div>
            </div>

            {/* Desglose de tarjetas - solo para cierre */}
            {tipoCorte === "cierre" ? (
              <div className="space-y-4 pt-4 border-t">
                <Label className="text-base font-semibold">Desglose de Tarjetas</Label>
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label htmlFor="tarjetas_banregio">Banregio</Label>
                    <Input
                      id="tarjetas_banregio"
                      type="text"
                      inputMode="decimal"
                      placeholder="0.00"
                      value={tarjetasBanregio}
                      onChange={(e) => {
                        const value = e.target.value.replace(",", ".");
                        if (/^[0-9]*\.?[0-9]*$/.test(value) || value === "") {
                          setTarjetasBanregio(value);
                        }
                      }}
                      required
                    />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="tarjetas_mercadopago">MercadoPago</Label>
                    <Input
                      id="tarjetas_mercadopago"
                      type="text"
                      inputMode="decimal"
                      placeholder="0.00"
                      value={tarjetasMercadopago}
                      onChange={(e) => {
                        const value = e.target.value.replace(",", ".");
                        if (/^[0-9]*\.?[0-9]*$/.test(value) || value === "") {
                          setTarjetasMercadopago(value);
                        }
                      }}
                      required
                    />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="tarjetas_haycash">HayCash</Label>
                    <Input
                      id="tarjetas_haycash"
                      type="text"
                      inputMode="decimal"
                      placeholder="0.00"
                      value={tarjetasHaycash}
                      onChange={(e) => {
                        const value = e.target.value.replace(",", ".");
                        if (/^[0-9]*\.?[0-9]*$/.test(value) || value === "") {
                          setTarjetasHaycash(value);
                        }
                      }}
                      required
                    />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="tarjetas">Total Tarjetas (auto)</Label>
                    <Input
                      id="tarjetas"
                      type="text"
                      inputMode="decimal"
                      placeholder="0.00"
                      value={tarjetas}
                      readOnly
                      className="bg-muted"
                    />
                  </div>
                </div>
              </div>
            ) : (
              /* Para momento: campo único de tarjetas */
              <div className="space-y-2">
                <Label htmlFor="tarjetas">Cobrado con tarjeta</Label>
                <Input
                  id="tarjetas"
                  type="text"
                  inputMode="decimal"
                  placeholder="0.00"
                  value={tarjetas}
                  onChange={(e) => {
                    const value = e.target.value.replace(",", ".");
                    if (/^[0-9]*\.?[0-9]*$/.test(value) || value === "") {
                      setTarjetas(value);
                    }
                  }}
                  required
                />
              </div>
            )}

            {/* Apps de delivery - Solares y Cervecería */}
            {esConPlataformas && (
              <div className="space-y-4 pt-4 border-t">
                <Label className="text-base font-semibold">Apps de Delivery</Label>
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label htmlFor="rappi">Rappi</Label>
                    <Input
                      id="rappi"
                      type="text"
                      inputMode="decimal"
                      placeholder="0.00"
                      value={rappi}
                      onChange={(e) => {
                        const value = e.target.value.replace(",", ".");
                        if (/^[0-9]*\.?[0-9]*$/.test(value) || value === "") {
                          setRappi(value);
                        }
                      }}
                    />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="uber">Uber</Label>
                    <Input
                      id="uber"
                      type="text"
                      inputMode="decimal"
                      placeholder="0.00"
                      value={uber}
                      onChange={(e) => {
                        const value = e.target.value.replace(",", ".");
                        if (/^[0-9]*\.?[0-9]*$/.test(value) || value === "") {
                          setUber(value);
                        }
                      }}
                    />
                  </div>
                </div>
                <div className="space-y-2">
                  <Label htmlFor="total_plataformas">Total Plataformas (auto)</Label>
                  <Input
                    id="total_plataformas"
                    type="text"
                    inputMode="decimal"
                    placeholder="0.00"
                    value={((parseFloat(rappi) || 0) + (parseFloat(uber) || 0)).toFixed(2)}
                    readOnly
                    className="bg-muted"
                  />
                </div>
              </div>
            )}

            {/* Cobradas y Por cobrar - para todas las sucursales */}
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="cobradas">Cobradas</Label>
                <Input
                  id="cobradas"
                  type="text"
                  inputMode="decimal"
                  placeholder="0.00"
                  value={cobradas}
                  onChange={(e) => {
                    const value = e.target.value.replace(",", ".");
                    if (/^[0-9]*\.?[0-9]*$/.test(value) || value === "") {
                      setCobradas(value);
                    }
                  }}
                  required
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="por_cobrar">Por cobrar</Label>
                <Input
                  id="por_cobrar"
                  type="text"
                  inputMode="decimal"
                  placeholder="0.00"
                  value={porCobrar}
                  onChange={(e) => {
                    const value = e.target.value.replace(",", ".");
                    if (/^[0-9]*\.?[0-9]*$/.test(value) || value === "") {
                      setPorCobrar(value);
                    }
                  }}
                  required
                />
              </div>
            </div>

            {/* Total */}
            <div className="space-y-2">
              <Label htmlFor="total">Total Vendido (calculado)</Label>
              <Input
                id="total"
                type="text"
                inputMode="decimal"
                placeholder="0.00"
                value={total}
                readOnly
                className="bg-muted font-semibold text-lg"
              />
            </div>


            {/* Campos opcionales para Cierre */}
            {tipoCorte === "cierre" && (
              <div className="space-y-4 pt-4 border-t">
                <Label className="text-base font-semibold">Gastos del día (opcionales)</Label>
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label htmlFor="pago_proveedores">Pago a proveedores</Label>
                    <Input
                      id="pago_proveedores"
                      type="text"
                      inputMode="decimal"
                      placeholder="0.00"
                      value={pagoProveedores}
                      onChange={(e) => {
                        const value = e.target.value.replace(",", ".");
                        if (/^[0-9]*\.?[0-9]*$/.test(value) || value === "") {
                          setPagoProveedores(value);
                        }
                      }}
                    />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="salarios">Salarios</Label>
                    <Input
                      id="salarios"
                      type="text"
                      inputMode="decimal"
                      placeholder="0.00"
                      value={salarios}
                      onChange={(e) => {
                        const value = e.target.value.replace(",", ".");
                        if (/^[0-9]*\.?[0-9]*$/.test(value) || value === "") {
                          setSalarios(value);
                        }
                      }}
                    />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="propinas">Propinas</Label>
                    <Input
                      id="propinas"
                      type="text"
                      inputMode="decimal"
                      placeholder="0.00"
                      value={propinas}
                      onChange={(e) => {
                        const value = e.target.value.replace(",", ".");
                        if (/^[0-9]*\.?[0-9]*$/.test(value) || value === "") {
                          setPropinas(value);
                        }
                      }}
                    />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="compras">Compras</Label>
                    <Input
                      id="compras"
                      type="text"
                      inputMode="decimal"
                      placeholder="0.00"
                      value={compras}
                      onChange={(e) => {
                        const value = e.target.value.replace(",", ".");
                        if (/^[0-9]*\.?[0-9]*$/.test(value) || value === "") {
                          setCompras(value);
                        }
                      }}
                    />
                  </div>
                  <div className="space-y-2 col-span-2">
                    <Label htmlFor="pago_servicios">Pago de servicios</Label>
                    <Input
                      id="pago_servicios"
                      type="text"
                      inputMode="decimal"
                      placeholder="0.00"
                      value={pagoServicios}
                      onChange={(e) => {
                        const value = e.target.value.replace(",", ".");
                        if (/^[0-9]*\.?[0-9]*$/.test(value) || value === "") {
                          setPagoServicios(value);
                        }
                      }}
                    />
                  </div>
                </div>
              </div>
            )}

            <Button
              type="submit"
              className="w-full"
              disabled={isLoading || !sucursalId}
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
