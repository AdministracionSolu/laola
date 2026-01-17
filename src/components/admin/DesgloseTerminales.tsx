import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { CreditCard, Building2 } from "lucide-react";

interface Corte {
  id: string;
  sucursal_id: string;
  tipo_corte: "momento" | "cierre";
  tarjetas: number;
  tarjetas_banregio?: number;
  tarjetas_mercadopago?: number;
  tarjetas_haycash?: number;
  fecha_venta: string;
  sucursales: {
    nombre: string;
  };
}

interface Sucursal {
  id: string;
  nombre: string;
}

interface DesgloseTerminalesProps {
  cortesCierre: Corte[];
  sucursales: Sucursal[];
  formatMoney: (value: number) => string;
}

export function DesgloseTerminales({ cortesCierre, sucursales, formatMoney }: DesgloseTerminalesProps) {
  // Agrupar cortes por sucursal
  const desglosePorSucursal = sucursales.map(sucursal => {
    const cortesDeEsta = cortesCierre.filter(c => c.sucursal_id === sucursal.id);
    
    const totales = cortesDeEsta.reduce((acc, c) => ({
      banregio: acc.banregio + (Number(c.tarjetas_banregio) || 0),
      mercadopago: acc.mercadopago + (Number(c.tarjetas_mercadopago) || 0),
      haycash: acc.haycash + (Number(c.tarjetas_haycash) || 0),
      total: acc.total + (Number(c.tarjetas) || 0),
    }), { banregio: 0, mercadopago: 0, haycash: 0, total: 0 });
    
    return {
      nombre: sucursal.nombre,
      ...totales,
    };
  }).filter(s => s.total > 0); // Solo mostrar sucursales con datos

  // Totales generales
  const totalesGenerales = desglosePorSucursal.reduce((acc, s) => ({
    banregio: acc.banregio + s.banregio,
    mercadopago: acc.mercadopago + s.mercadopago,
    haycash: acc.haycash + s.haycash,
    total: acc.total + s.total,
  }), { banregio: 0, mercadopago: 0, haycash: 0, total: 0 });

  if (desglosePorSucursal.length === 0) {
    return null;
  }

  return (
    <Card>
      <CardHeader className="pb-3">
        <CardTitle className="text-lg flex items-center gap-2">
          <CreditCard className="w-5 h-5" />
          Desglose de Tarjetas por Terminal
        </CardTitle>
      </CardHeader>
      <CardContent>
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead className="w-[180px]">
                <div className="flex items-center gap-2">
                  <Building2 className="w-4 h-4" />
                  Sucursal
                </div>
              </TableHead>
              <TableHead className="text-right">Banregio</TableHead>
              <TableHead className="text-right">Mercadopago</TableHead>
              <TableHead className="text-right">Haycash</TableHead>
              <TableHead className="text-right font-semibold">Total</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {desglosePorSucursal.map((sucursal) => (
              <TableRow key={sucursal.nombre}>
                <TableCell className="font-medium">{sucursal.nombre}</TableCell>
                <TableCell className="text-right">{formatMoney(sucursal.banregio)}</TableCell>
                <TableCell className="text-right">{formatMoney(sucursal.mercadopago)}</TableCell>
                <TableCell className="text-right">{formatMoney(sucursal.haycash)}</TableCell>
                <TableCell className="text-right font-semibold">{formatMoney(sucursal.total)}</TableCell>
              </TableRow>
            ))}
            {/* Fila de totales */}
            <TableRow className="bg-muted/50 font-semibold">
              <TableCell>TOTAL</TableCell>
              <TableCell className="text-right">{formatMoney(totalesGenerales.banregio)}</TableCell>
              <TableCell className="text-right">{formatMoney(totalesGenerales.mercadopago)}</TableCell>
              <TableCell className="text-right">{formatMoney(totalesGenerales.haycash)}</TableCell>
              <TableCell className="text-right text-primary">{formatMoney(totalesGenerales.total)}</TableCell>
            </TableRow>
          </TableBody>
        </Table>
      </CardContent>
    </Card>
  );
}
