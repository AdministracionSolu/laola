import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Calculator, CalendarDays, Package, Truck, ClipboardCheck } from "lucide-react";
import { useNavigate } from "react-router-dom";
import logoLaOla from "@/assets/logo-la-ola.jpeg";

export default function CentroOperaciones() {
  const navigate = useNavigate();

  return (
    <div className="min-h-screen bg-gradient-to-br from-primary/5 to-secondary/10 flex items-center justify-center p-4">
      <Card className="w-full max-w-md">
        <CardHeader className="text-center">
          <div className="mx-auto mb-4 w-20 h-20 rounded-full overflow-hidden">
            <img src={logoLaOla} alt="La Ola" className="w-full h-full object-cover" />
          </div>
          <CardTitle className="text-2xl">Centro de Operaciones</CardTitle>
          <CardDescription>
            Selecciona el módulo que deseas usar
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-3">
          <Button
            variant="outline"
            className="w-full h-20 flex flex-col gap-1 hover:bg-primary/5 hover:border-primary transition-all"
            onClick={() => navigate("/centro-de-operaciones/cortes")}
          >
            <Calculator className="w-6 h-6 text-primary" />
            <span className="text-base font-semibold">Cortes de Caja</span>
            <span className="text-xs text-muted-foreground">Registrar cortes del día</span>
          </Button>

          <Button
            variant="outline"
            className="w-full h-20 flex flex-col gap-1 hover:bg-primary/5 hover:border-primary transition-all"
            onClick={() => navigate("/centro-de-operaciones/reservaciones")}
          >
            <CalendarDays className="w-6 h-6 text-primary" />
            <span className="text-base font-semibold">Reservaciones</span>
            <span className="text-xs text-muted-foreground">Consultar y registrar reservas</span>
          </Button>

          <Button
            variant="outline"
            className="w-full h-20 flex flex-col gap-1 hover:bg-primary/5 hover:border-primary transition-all"
            onClick={() => navigate("/centro-de-operaciones/pedidos")}
          >
            <Package className="w-6 h-6 text-primary" />
            <span className="text-base font-semibold">Pedidos</span>
            <span className="text-xs text-muted-foreground">Registrar pedidos de insumos</span>
          </Button>

          <Button
            variant="outline"
            className="w-full h-20 flex flex-col gap-1 hover:bg-primary/5 hover:border-primary transition-all"
            onClick={() => navigate("/centro-de-operaciones/recepciones")}
          >
            <Truck className="w-6 h-6 text-primary" />
            <span className="text-base font-semibold">Recepción</span>
            <span className="text-xs text-muted-foreground">Registrar llegada de mercancía</span>
          </Button>

          <Button
            variant="outline"
            className="w-full h-20 flex flex-col gap-1 hover:bg-primary/5 hover:border-primary transition-all"
            onClick={() => navigate("/centro-de-operaciones/contadoras")}
          >
            <ClipboardCheck className="w-6 h-6 text-primary" />
            <span className="text-base font-semibold">Contadoras</span>
            <span className="text-xs text-muted-foreground">Verificar ingresos vs sistema</span>
          </Button>
        </CardContent>
      </Card>
    </div>
  );
}
