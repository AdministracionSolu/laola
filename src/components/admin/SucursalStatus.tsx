import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { CheckCircle2, Clock, Store } from "lucide-react";
import { cn } from "@/lib/utils";

interface EstadoSucursal {
  nombre: string;
  cerrado: boolean;
  ultimoCorte: string | null;
}

interface SucursalStatusProps {
  estados: EstadoSucursal[];
  mostrarSoloDia?: boolean;
}

export function SucursalStatus({ estados, mostrarSoloDia = true }: SucursalStatusProps) {
  if (!mostrarSoloDia) return null;

  const cerradas = estados.filter((e) => e.cerrado).length;
  const pendientes = estados.length - cerradas;

  return (
    <Card>
      <CardHeader className="pb-3">
        <div className="flex items-center justify-between">
          <div>
            <CardTitle className="text-base">Estado de Sucursales</CardTitle>
            <CardDescription>
              {cerradas} de {estados.length} cerradas hoy
            </CardDescription>
          </div>
          <div className="flex gap-2">
            <Badge variant="default" className="gap-1">
              <CheckCircle2 className="w-3 h-3" />
              {cerradas}
            </Badge>
            {pendientes > 0 && (
              <Badge variant="secondary" className="gap-1">
                <Clock className="w-3 h-3" />
                {pendientes}
              </Badge>
            )}
          </div>
        </div>
      </CardHeader>
      <CardContent>
        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-3">
          {estados.map((estado) => (
            <div
              key={estado.nombre}
              className={cn(
                "flex items-center gap-2 p-2 rounded-lg border",
                estado.cerrado 
                  ? "bg-green-50 border-green-200 dark:bg-green-950/30 dark:border-green-800"
                  : "bg-muted/50 border-border"
              )}
            >
              {estado.cerrado ? (
                <CheckCircle2 className="w-4 h-4 text-green-600 dark:text-green-400 shrink-0" />
              ) : (
                <Store className="w-4 h-4 text-muted-foreground shrink-0" />
              )}
              <div className="min-w-0">
                <p className="text-sm font-medium truncate">{estado.nombre}</p>
                {estado.ultimoCorte && (
                  <p className="text-xs text-muted-foreground">
                    Último: {estado.ultimoCorte}
                  </p>
                )}
              </div>
            </div>
          ))}
        </div>
      </CardContent>
    </Card>
  );
}
