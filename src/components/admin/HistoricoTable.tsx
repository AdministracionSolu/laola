import { useState } from "react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { Store, FileDown, Trash2 } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Corte } from "@/hooks/useCortes";
import { format, parseISO } from "date-fns";
import { es } from "date-fns/locale";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";

interface HistoricoTableProps {
  cortes: Corte[];
  formatMoney: (value: number) => string;
  mostrarFecha?: boolean;
  onDelete?: (corteId: string) => Promise<boolean>;
}

export function HistoricoTable({ cortes, formatMoney, mostrarFecha = false, onDelete }: HistoricoTableProps) {
  const [corteAEliminar, setCorteAEliminar] = useState<Corte | null>(null);
  const [isDeleting, setIsDeleting] = useState(false);

  const handleDelete = async () => {
    if (!corteAEliminar || !onDelete) return;
    
    setIsDeleting(true);
    await onDelete(corteAEliminar.id);
    setIsDeleting(false);
    setCorteAEliminar(null);
  };
  const exportarCSV = () => {
    const headers = ["Fecha Venta", "Registrado", "Sucursal", "Tipo", "Corte X", "Tarjetas", "Efectivo", "Cobradas", "Por Cobrar", "Total", "Pago Proveedores", "Salarios", "Propinas", "Compras", "Pago Servicios"];
    const rows = cortes.map((corte) => [
      corte.fecha_venta,
      format(parseISO(corte.created_at), "yyyy-MM-dd HH:mm"),
      corte.sucursales?.nombre || "",
      corte.tipo_corte,
      corte.corte_x,
      corte.tarjetas,
      corte.efectivo,
      corte.cobradas,
      corte.por_cobrar,
      corte.total,
      corte.pago_proveedores || 0,
      corte.salarios || 0,
      corte.propinas || 0,
      corte.compras || 0,
      corte.pago_servicios || 0,
    ]);
    
    const csv = [headers, ...rows].map((row) => row.join(",")).join("\n");
    const blob = new Blob([csv], { type: "text/csv;charset=utf-8;" });
    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.href = url;
    link.download = `cortes-${format(new Date(), "yyyy-MM-dd")}.csv`;
    link.click();
    URL.revokeObjectURL(url);
  };

  return (
    <Card>
      <CardHeader>
        <div className="flex items-center justify-between">
          <div>
            <CardTitle>Historial de Cortes</CardTitle>
            <CardDescription>
              {cortes.length} registros encontrados
            </CardDescription>
          </div>
          {cortes.length > 0 && (
            <Button variant="outline" size="sm" onClick={exportarCSV} className="gap-2">
              <FileDown className="w-4 h-4" />
              Exportar CSV
            </Button>
          )}
        </div>
      </CardHeader>
      <CardContent>
        {cortes.length === 0 ? (
          <div className="text-center py-12 text-muted-foreground">
            <Store className="w-12 h-12 mx-auto mb-4 opacity-30" />
            <p>No hay cortes en este período</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <Table>
              <TableHeader>
                <TableRow>
                  {mostrarFecha && <TableHead>Fecha Venta</TableHead>}
                  <TableHead>Registrado</TableHead>
                  <TableHead>Sucursal</TableHead>
                  <TableHead>Tipo</TableHead>
                  <TableHead className="text-right">Corte X</TableHead>
                  <TableHead className="text-right">Tarjetas</TableHead>
                  <TableHead className="text-right">Efectivo</TableHead>
                  <TableHead className="text-right">Cobradas</TableHead>
                  <TableHead className="text-right">Por Cobrar</TableHead>
                  <TableHead className="text-right">Total</TableHead>
                  <TableHead className="text-right">Proveedores</TableHead>
                  <TableHead className="text-right">Salarios</TableHead>
                  <TableHead className="text-right">Propinas</TableHead>
                  <TableHead className="text-right">Compras</TableHead>
                  <TableHead className="text-right">Servicios</TableHead>
                  {onDelete && <TableHead className="w-12"></TableHead>}
                </TableRow>
              </TableHeader>
              <TableBody>
                {cortes.map((corte) => (
                  <TableRow key={corte.id}>
                    {mostrarFecha && (
                      <TableCell className="whitespace-nowrap">
                        {format(parseISO(corte.fecha_venta), "d MMM", { locale: es })}
                      </TableCell>
                    )}
                    <TableCell className="text-muted-foreground text-sm">
                      {format(parseISO(corte.created_at), "d MMM HH:mm", { locale: es })}
                    </TableCell>
                    <TableCell className="font-medium">
                      {corte.sucursales?.nombre}
                    </TableCell>
                    <TableCell>
                      <Badge variant={corte.tipo_corte === "cierre" ? "default" : "secondary"}>
                        {corte.tipo_corte === "cierre" ? "Cierre" : "Momento"}
                      </Badge>
                    </TableCell>
                    <TableCell className="text-right">
                      {formatMoney(Number(corte.corte_x))}
                    </TableCell>
                    <TableCell className="text-right">
                      {formatMoney(Number(corte.tarjetas))}
                    </TableCell>
                    <TableCell className="text-right">
                      {formatMoney(Number(corte.efectivo))}
                    </TableCell>
                    <TableCell className="text-right">
                      {formatMoney(Number(corte.cobradas))}
                    </TableCell>
                    <TableCell className="text-right">
                      {formatMoney(Number(corte.por_cobrar))}
                    </TableCell>
                    <TableCell className="text-right font-semibold">
                      {formatMoney(Number(corte.total))}
                    </TableCell>
                    <TableCell className="text-right text-muted-foreground">
                      {formatMoney(Number(corte.pago_proveedores || 0))}
                    </TableCell>
                    <TableCell className="text-right text-muted-foreground">
                      {formatMoney(Number(corte.salarios || 0))}
                    </TableCell>
                    <TableCell className="text-right text-muted-foreground">
                      {formatMoney(Number(corte.propinas || 0))}
                    </TableCell>
                    <TableCell className="text-right text-muted-foreground">
                      {formatMoney(Number(corte.compras || 0))}
                    </TableCell>
                    <TableCell className="text-right text-muted-foreground">
                      {formatMoney(Number(corte.pago_servicios || 0))}
                    </TableCell>
                    {onDelete && (
                      <TableCell>
                        <Button
                          variant="ghost"
                          size="icon"
                          className="h-8 w-8 text-muted-foreground hover:text-destructive"
                          onClick={() => setCorteAEliminar(corte)}
                        >
                          <Trash2 className="w-4 h-4" />
                        </Button>
                      </TableCell>
                    )}
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        )}
      </CardContent>

      {/* Diálogo de confirmación */}
      <AlertDialog open={!!corteAEliminar} onOpenChange={() => setCorteAEliminar(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>¿Eliminar este corte?</AlertDialogTitle>
            <AlertDialogDescription>
              {corteAEliminar && (
                <>
                  Estás por eliminar el corte de <strong>{corteAEliminar.sucursales?.nombre}</strong> del{" "}
                  <strong>{format(parseISO(corteAEliminar.created_at), "d 'de' MMMM 'a las' HH:mm", { locale: es })}</strong>.
                  <br /><br />
                  Esta acción no se puede deshacer.
                </>
              )}
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel disabled={isDeleting}>Cancelar</AlertDialogCancel>
            <AlertDialogAction 
              onClick={handleDelete} 
              disabled={isDeleting}
              className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
            >
              {isDeleting ? "Eliminando..." : "Eliminar"}
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </Card>
  );
}
