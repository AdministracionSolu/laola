import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { Store, FileDown } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Corte } from "@/hooks/useCortes";
import { format, parseISO } from "date-fns";
import { es } from "date-fns/locale";

interface HistoricoTableProps {
  cortes: Corte[];
  formatMoney: (value: number) => string;
  mostrarFecha?: boolean;
}

export function HistoricoTable({ cortes, formatMoney, mostrarFecha = false }: HistoricoTableProps) {
  const exportarCSV = () => {
    const headers = ["Fecha", "Hora", "Sucursal", "Tipo", "Corte X", "Tarjetas", "Efectivo", "Total"];
    const rows = cortes.map((corte) => [
      format(parseISO(corte.created_at), "yyyy-MM-dd"),
      format(parseISO(corte.created_at), "HH:mm"),
      corte.sucursales?.nombre || "",
      corte.tipo_corte,
      corte.corte_x,
      corte.tarjetas,
      corte.efectivo,
      corte.total,
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
                  {mostrarFecha && <TableHead>Fecha</TableHead>}
                  <TableHead>Hora</TableHead>
                  <TableHead>Sucursal</TableHead>
                  <TableHead>Tipo</TableHead>
                  <TableHead className="text-right">Corte X</TableHead>
                  <TableHead className="text-right">Tarjetas</TableHead>
                  <TableHead className="text-right">Efectivo</TableHead>
                  <TableHead className="text-right">Total</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {cortes.map((corte) => (
                  <TableRow key={corte.id}>
                    {mostrarFecha && (
                      <TableCell className="whitespace-nowrap">
                        {format(parseISO(corte.created_at), "d MMM", { locale: es })}
                      </TableCell>
                    )}
                    <TableCell>
                      {format(parseISO(corte.created_at), "HH:mm", { locale: es })}
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
                    <TableCell className="text-right font-semibold">
                      {formatMoney(Number(corte.total))}
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        )}
      </CardContent>
    </Card>
  );
}
