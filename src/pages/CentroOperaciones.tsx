import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Calculator, CalendarDays, Package, ClipboardCheck, Clock } from "lucide-react";
import { useNavigate } from "react-router-dom";
import logoLaOla from "@/assets/logo-la-ola.jpeg";

type Modulo = {
  ruta: string;
  icono: React.ReactNode;
  titulo: string;
  descripcion: string;
};

// Agrupado por quién lo usa: cada área encuentra lo suyo sin revolverse
// con las demás. Las rutas son las mismas de siempre (están en producción).
const SECCIONES: { area: string; modulos: Modulo[] }[] = [
  {
    area: "Caja",
    modulos: [
      {
        ruta: "/centro-de-operaciones/cortes",
        icono: <Calculator className="w-6 h-6 text-primary" />,
        titulo: "Cortes de Caja",
        descripcion: "Registrar cortes del día",
      },
      {
        ruta: "/centro-de-operaciones/contadoras",
        icono: <ClipboardCheck className="w-6 h-6 text-primary" />,
        titulo: "Contadoras",
        descripcion: "Verificar ingresos vs sistema",
      },
    ],
  },
  {
    area: "Cocina",
    modulos: [
      {
        ruta: "/pedidos",
        icono: <Package className="w-6 h-6 text-primary" />,
        titulo: "Pedidos e insumos",
        descripcion: "Pedido y recepción de insumos",
      },
    ],
  },
  {
    area: "Capitán",
    modulos: [
      {
        ruta: "/centro-de-operaciones/reservaciones",
        icono: <CalendarDays className="w-6 h-6 text-primary" />,
        titulo: "Reservaciones",
        descripcion: "Consultar y registrar reservas",
      },
    ],
  },
  {
    area: "Todo el personal",
    modulos: [
      {
        ruta: "/centro-de-operaciones/checador",
        icono: <Clock className="w-6 h-6 text-primary" />,
        titulo: "Checador",
        descripcion: "Marcar entrada y salida del personal",
      },
    ],
  },
];

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
            Selecciona el módulo de tu área
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          {SECCIONES.map((s) => (
            <div key={s.area}>
              <p className="text-xs font-semibold uppercase tracking-wide text-muted-foreground mb-2">
                {s.area}
              </p>
              <div className="space-y-2">
                {s.modulos.map((m) => (
                  <Button
                    key={m.ruta}
                    variant="outline"
                    className="w-full h-20 flex flex-col gap-1 hover:bg-primary/5 hover:border-primary transition-all"
                    onClick={() => navigate(m.ruta)}
                  >
                    {m.icono}
                    <span className="text-base font-semibold">{m.titulo}</span>
                    <span className="text-xs text-muted-foreground">{m.descripcion}</span>
                  </Button>
                ))}
              </div>
            </div>
          ))}
        </CardContent>
      </Card>
    </div>
  );
}
