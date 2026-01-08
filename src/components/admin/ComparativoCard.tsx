import { Card, CardContent } from "@/components/ui/card";
import { LucideIcon, TrendingDown, TrendingUp, Minus } from "lucide-react";
import { cn } from "@/lib/utils";

interface ComparativoCardProps {
  titulo: string;
  valor: number;
  valorAnterior: number;
  formatMoney: (value: number) => string;
  icon: LucideIcon;
  iconColor?: string;
  destacado?: boolean;
}

export function ComparativoCard({
  titulo,
  valor,
  valorAnterior,
  formatMoney,
  icon: Icon,
  iconColor = "text-muted-foreground/30",
  destacado = false,
}: ComparativoCardProps) {
  const diferencia = valorAnterior > 0 ? ((valor - valorAnterior) / valorAnterior) * 100 : 0;
  const esPositivo = diferencia > 0;
  const esNeutro = Math.abs(diferencia) < 0.5;

  const TendenciaIcon = esNeutro ? Minus : esPositivo ? TrendingUp : TrendingDown;
  
  return (
    <Card className={cn(
      destacado && "bg-primary text-primary-foreground"
    )}>
      <CardContent className="pt-6">
        <div className="flex items-center justify-between">
          <div className="space-y-1">
            <p className={cn(
              "text-sm",
              destacado ? "opacity-80" : "text-muted-foreground"
            )}>
              {titulo}
            </p>
            <p className="text-2xl font-bold">{formatMoney(valor)}</p>
            
            {/* Comparativo */}
            {valorAnterior > 0 && (
              <div className={cn(
                "flex items-center gap-1 text-xs",
                destacado ? "opacity-70" : (
                  esNeutro ? "text-muted-foreground" :
                  esPositivo ? "text-green-600 dark:text-green-400" : 
                  "text-red-600 dark:text-red-400"
                )
              )}>
                <TendenciaIcon className="w-3 h-3" />
                <span>
                  {esNeutro ? "Sin cambio" : `${Math.abs(diferencia).toFixed(1)}% vs anterior`}
                </span>
              </div>
            )}
          </div>
          <Icon className={cn(
            "w-10 h-10",
            destacado ? "opacity-30" : iconColor
          )} />
        </div>
      </CardContent>
    </Card>
  );
}
