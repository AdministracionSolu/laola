import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Calculator, CalendarDays } from "lucide-react";
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
        <CardContent className="space-y-4">
          <Button
            variant="outline"
            className="w-full h-24 flex flex-col gap-2 hover:bg-primary/5 hover:border-primary transition-all"
            onClick={() => navigate("/centro-de-operaciones/cortes")}
          >
            <Calculator className="w-8 h-8 text-primary" />
            <span className="text-lg font-semibold">Cortes de Caja</span>
            <span className="text-xs text-muted-foreground">Registrar cortes del día</span>
          </Button>

          <Button
            variant="outline"
            className="w-full h-24 flex flex-col gap-2 hover:bg-primary/5 hover:border-primary transition-all"
            onClick={() => navigate("/centro-de-operaciones/reservaciones")}
          >
            <CalendarDays className="w-8 h-8 text-primary" />
            <span className="text-lg font-semibold">Reservaciones</span>
            <span className="text-xs text-muted-foreground">Consultar y registrar reservas</span>
          </Button>
        </CardContent>
      </Card>
    </div>
  );
}
