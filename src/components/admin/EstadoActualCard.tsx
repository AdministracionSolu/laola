import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { CreditCard, Banknote, Clock, Store, Receipt, DollarSign } from "lucide-react";
import { format, parseISO } from "date-fns";
import { es } from "date-fns/locale";

interface EstadoSucursal {
  sucursal_id: string;
  nombre: string;
  tipo_corte: "momento" | "cierre";
  corte_x: number;
  tarjetas: number;
  efectivo: number;
  por_cobrar: number;
  total: number;
  created_at: string;
  fecha_venta: string;
  tarjetas_banregio?: number;
  tarjetas_mercadopago?: number;
  tarjetas_haycash?: number;
}

interface EstadoActualCardProps {
  estado: EstadoSucursal;
  formatMoney: (value: number) => string;
}

export function EstadoActualCard({ estado, formatMoney }: EstadoActualCardProps) {
  const esCierre = estado.tipo_corte === "cierre";
  
  return (
    <Card className={`relative overflow-hidden ${esCierre ? "border-green-500/50" : "border-amber-500/50"}`}>
      <div className={`absolute top-0 left-0 right-0 h-1 ${esCierre ? "bg-green-500" : "bg-amber-500"}`} />
      
      <CardHeader className="pb-2">
        <div className="flex items-center justify-between">
          <CardTitle className="text-lg flex items-center gap-2">
            <Store className="w-4 h-4" />
            {estado.nombre}
          </CardTitle>
          <Badge variant={esCierre ? "default" : "secondary"} className={esCierre ? "bg-green-600" : "bg-amber-600"}>
            {esCierre ? "Cierre" : "Momento"}
          </Badge>
        </div>
        <div className="flex items-center gap-1 text-xs text-muted-foreground">
          <Clock className="w-3 h-3" />
          <span>
            {format(parseISO(estado.created_at), "d MMM, HH:mm", { locale: es })}
          </span>
        </div>
      </CardHeader>
      
      <CardContent className="space-y-3">
        <div className="grid grid-cols-2 gap-3">
          <div className="flex items-center gap-2 p-2 rounded-md bg-blue-500/10">
            <CreditCard className="w-4 h-4 text-blue-500" />
            <div>
              <p className="text-xs text-muted-foreground">Tarjetas</p>
              <p className="font-semibold text-sm">{formatMoney(estado.tarjetas)}</p>
            </div>
          </div>
          
          <div className="flex items-center gap-2 p-2 rounded-md bg-green-500/10">
            <Banknote className="w-4 h-4 text-green-500" />
            <div>
              <p className="text-xs text-muted-foreground">Efectivo</p>
              <p className="font-semibold text-sm">{formatMoney(estado.efectivo)}</p>
            </div>
          </div>
        </div>
        
        {esCierre ? (
          /* Para CIERRE: mostrar Corte X en lugar de Por Cobrar */
          <div className="flex items-center gap-2 p-2 rounded-md bg-primary/10">
            <DollarSign className="w-4 h-4 text-primary" />
            <div>
              <p className="text-xs text-muted-foreground">Corte X</p>
              <p className="font-semibold text-sm">{formatMoney(estado.corte_x)}</p>
            </div>
          </div>
        ) : (
          /* Para MOMENTO: mostrar ambos Por Cobrar y Corte X */
          <div className="grid grid-cols-2 gap-3">
            <div className="flex items-center gap-2 p-2 rounded-md bg-muted/50">
              <Receipt className="w-4 h-4 text-muted-foreground" />
              <div>
                <p className="text-xs text-muted-foreground">Por Cobrar</p>
                <p className="font-semibold text-sm">{formatMoney(estado.por_cobrar)}</p>
              </div>
            </div>
            <div className="flex items-center gap-2 p-2 rounded-md bg-primary/10">
              <DollarSign className="w-4 h-4 text-primary" />
              <div>
                <p className="text-xs text-muted-foreground">Corte X</p>
                <p className="font-semibold text-sm">{formatMoney(estado.corte_x)}</p>
              </div>
            </div>
          </div>
        )}
        
        <div className="pt-2 border-t">
          <div className="flex items-center justify-between">
            <span className="text-sm text-muted-foreground">Total</span>
            <span className="text-xl font-bold text-primary">{formatMoney(estado.total)}</span>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
