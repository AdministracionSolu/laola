import { useEffect, useMemo, useState } from "react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { Store, FileDown, Trash2, ArrowRightLeft, CalendarDays, History, Pencil } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Corte } from "@/hooks/useCortes";
import { tieneEspiral } from "@/lib/terminales";
import { supabase } from "@/integrations/supabase/client";
import { format, parseISO } from "date-fns";
import { es } from "date-fns/locale";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
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
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";

interface HistoricoTableProps {
  cortes: Corte[];
  formatMoney: (value: number) => string;
  mostrarFecha?: boolean;
  onDelete?: (corteId: string) => Promise<boolean>;
  onCambiarTipo?: (corteId: string, nuevoTipo: "momento" | "cierre") => Promise<boolean>;
  onCambiarFecha?: (corteId: string, nuevaFecha: string) => Promise<boolean>;
  onEditar?: (corteId: string, campos: Record<string, number>) => Promise<boolean>;
}

export function HistoricoTable({ cortes, formatMoney, mostrarFecha = false, onDelete, onCambiarTipo, onCambiarFecha, onEditar }: HistoricoTableProps) {
  const [corteAEliminar, setCorteAEliminar] = useState<Corte | null>(null);
  const [corteACambiar, setCorteACambiar] = useState<{ corte: Corte; nuevoTipo: "momento" | "cierre" } | null>(null);
  const [corteAFechar, setCorteAFechar] = useState<Corte | null>(null);
  const [nuevaFecha, setNuevaFecha] = useState("");
  const [corteAEditar, setCorteAEditar] = useState<Corte | null>(null);
  const [formEdit, setFormEdit] = useState<Record<string, string>>({});
  const [fechaEdit, setFechaEdit] = useState("");

  const [isDeleting, setIsDeleting] = useState(false);
  const [isCambiando, setIsCambiando] = useState(false);
  const [isFechando, setIsFechando] = useState(false);
  const [isEditando, setIsEditando] = useState(false);
  const [bitacoraAbierta, setBitacoraAbierta] = useState(false);

  // Cierres duplicados (misma sucursal, mismo día de negocio): se marcan
  // para que contabilidad mueva la fecha del que quedó en el día equivocado.
  const duplicados = useMemo(() => {
    const conteo = new Map<string, number>();
    for (const c of cortes) {
      if (c.tipo_corte !== "cierre") continue;
      const k = `${c.sucursal_id}|${c.fecha_venta}`;
      conteo.set(k, (conteo.get(k) ?? 0) + 1);
    }
    return new Set([...conteo.entries()].filter(([, n]) => n > 1).map(([k]) => k));
  }, [cortes]);

  const esDuplicado = (c: Corte) =>
    c.tipo_corte === "cierre" && duplicados.has(`${c.sucursal_id}|${c.fecha_venta}`);

  // ---- Edición de montos (queda en la bitácora vía trigger) ----
  const num = (v: string | undefined) => {
    const n = parseFloat(v ?? "");
    return Number.isFinite(n) && n >= 0 ? n : 0;
  };

  const abrirEdicion = (corte: Corte) => {
    setFormEdit({
      corte_x: String(corte.corte_x ?? 0),
      tarjetas_banregio: String(corte.tarjetas_banregio ?? 0),
      tarjetas_mercadopago: String(corte.tarjetas_mercadopago ?? 0),
      tarjetas_haycash: String(corte.tarjetas_haycash ?? 0),
      tarjetas_espiral: String(corte.tarjetas_espiral ?? 0),
      tarjetas: String(corte.tarjetas ?? 0),
      efectivo: String(corte.efectivo ?? 0),
      cobradas: String(corte.cobradas ?? 0),
      por_cobrar: String(corte.por_cobrar ?? 0),
      pago_proveedores: String(corte.pago_proveedores ?? 0),
      salarios: String(corte.salarios ?? 0),
      propinas: String(corte.propinas ?? 0),
      compras: String(corte.compras ?? 0),
      pago_servicios: String(corte.pago_servicios ?? 0),
      rappi: String(corte.rappi ?? 0),
      uber: String(corte.uber ?? 0),
    });
    setCorteAEditar(corte);
  };

  // Mismas reglas que la captura: si hay desglose de tarjetas, tarjetas es
  // la suma; el total siempre es tarjetas + efectivo + por cobrar.
  const desgloseTarjetas =
    num(formEdit.tarjetas_banregio) +
    num(formEdit.tarjetas_mercadopago) +
    num(formEdit.tarjetas_haycash) +
    num(formEdit.tarjetas_espiral);
  const tarjetasCalc = desgloseTarjetas > 0 ? desgloseTarjetas : num(formEdit.tarjetas);
  const totalCalc = tarjetasCalc + num(formEdit.efectivo) + num(formEdit.por_cobrar);

  const handleEditar = async () => {
    if (!corteAEditar || !onEditar) return;

    setIsEditando(true);
    const ok = await onEditar(corteAEditar.id, {
      corte_x: num(formEdit.corte_x),
      tarjetas_banregio: num(formEdit.tarjetas_banregio),
      tarjetas_mercadopago: num(formEdit.tarjetas_mercadopago),
      tarjetas_haycash: num(formEdit.tarjetas_haycash),
      tarjetas_espiral: num(formEdit.tarjetas_espiral),
      tarjetas: tarjetasCalc,
      efectivo: num(formEdit.efectivo),
      cobradas: num(formEdit.cobradas),
      por_cobrar: num(formEdit.por_cobrar),
      total: totalCalc,
      pago_proveedores: num(formEdit.pago_proveedores),
      salarios: num(formEdit.salarios),
      propinas: num(formEdit.propinas),
      compras: num(formEdit.compras),
      pago_servicios: num(formEdit.pago_servicios),
      rappi: num(formEdit.rappi),
      uber: num(formEdit.uber),
    });
    setIsEditando(false);
    if (ok) setCorteAEditar(null);
  };

  const handleCambiarFecha = async () => {
    if (!corteAFechar || !onCambiarFecha || !nuevaFecha) return;

    setIsFechando(true);
    await onCambiarFecha(corteAFechar.id, nuevaFecha);
    setIsFechando(false);
    setCorteAFechar(null);
  };

  const handleDelete = async () => {
    if (!corteAEliminar || !onDelete) return;
    
    setIsDeleting(true);
    await onDelete(corteAEliminar.id);
    setIsDeleting(false);
    setCorteAEliminar(null);
  };

  const handleCambiarTipo = async () => {
    if (!corteACambiar || !onCambiarTipo) return;
    
    setIsCambiando(true);
    await onCambiarTipo(corteACambiar.corte.id, corteACambiar.nuevoTipo);
    setIsCambiando(false);
    setCorteACambiar(null);
  };
  const exportarCSV = () => {
    const headers = ["Fecha Venta", "Registrado", "Sucursal", "Tipo", "Corte X", "Tarjetas", "Efectivo", "Cobradas", "Por Cobrar", "Total", "Proveedores", "Salarios", "Propinas", "Compras", "Servicios", "Rappi", "Uber"];
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
      corte.rappi || 0,
      corte.uber || 0,
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
          <div className="flex gap-2">
            {onCambiarFecha && (
              <Button variant="outline" size="sm" onClick={() => setBitacoraAbierta(true)} className="gap-2">
                <History className="w-4 h-4" />
                Bitácora
              </Button>
            )}
            {cortes.length > 0 && (
              <Button variant="outline" size="sm" onClick={exportarCSV} className="gap-2">
                <FileDown className="w-4 h-4" />
                Exportar CSV
              </Button>
            )}
          </div>
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
                  <TableHead className="text-right">Rappi</TableHead>
                  <TableHead className="text-right">Uber</TableHead>
                  {(onEditar || onDelete) && <TableHead className="w-20"></TableHead>}
                </TableRow>
              </TableHeader>
              <TableBody>
                {cortes.map((corte) => (
                  <TableRow key={corte.id}>
                    {mostrarFecha && (
                      <TableCell className="whitespace-nowrap">
                        {onCambiarFecha ? (
                          <button
                            className="inline-flex items-center gap-1 hover:text-primary hover:underline"
                            title="Mover este corte a otro día (queda en la bitácora)"
                            onClick={() => { setNuevaFecha(corte.fecha_venta); setCorteAFechar(corte); }}
                          >
                            {format(parseISO(corte.fecha_venta), "d MMM", { locale: es })}
                            <CalendarDays className="w-3 h-3 opacity-50" />
                          </button>
                        ) : (
                          format(parseISO(corte.fecha_venta), "d MMM", { locale: es })
                        )}
                        {esDuplicado(corte) && (
                          <Badge variant="destructive" className="ml-1.5 text-[10px] px-1.5 py-0">Duplicado</Badge>
                        )}
                      </TableCell>
                    )}
                    <TableCell className="text-muted-foreground text-sm">
                      {format(parseISO(corte.created_at), "d MMM HH:mm", { locale: es })}
                    </TableCell>
                    <TableCell className="font-medium">
                      {corte.sucursales?.nombre}
                    </TableCell>
                    <TableCell>
                      <DropdownMenu>
                        <DropdownMenuTrigger asChild>
                          <Badge 
                            variant={corte.tipo_corte === "cierre" ? "default" : "secondary"}
                            className="cursor-pointer hover:opacity-80"
                          >
                            {corte.tipo_corte === "cierre" ? "Cierre" : "Momento"}
                          </Badge>
                        </DropdownMenuTrigger>
                        {onCambiarTipo && (
                          <DropdownMenuContent align="start">
                            <DropdownMenuItem
                              onClick={() => setCorteACambiar({ 
                                corte, 
                                nuevoTipo: corte.tipo_corte === "cierre" ? "momento" : "cierre" 
                              })}
                              className="gap-2"
                            >
                              <ArrowRightLeft className="w-4 h-4" />
                              Cambiar a {corte.tipo_corte === "cierre" ? "Momento" : "Cierre"}
                            </DropdownMenuItem>
                          </DropdownMenuContent>
                        )}
                      </DropdownMenu>
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
                    <TableCell className="text-right text-muted-foreground">
                      {formatMoney(Number(corte.rappi || 0))}
                    </TableCell>
                    <TableCell className="text-right text-muted-foreground">
                      {formatMoney(Number(corte.uber || 0))}
                    </TableCell>
                    {(onEditar || onDelete) && (
                      <TableCell>
                        <div className="flex items-center">
                          {onEditar && (
                            <Button
                              variant="ghost"
                              size="icon"
                              className="h-8 w-8 text-muted-foreground hover:text-primary"
                              title="Editar montos (queda en la bitácora)"
                              onClick={() => abrirEdicion(corte)}
                            >
                              <Pencil className="w-4 h-4" />
                            </Button>
                          )}
                          {onDelete && (
                            <Button
                              variant="ghost"
                              size="icon"
                              className="h-8 w-8 text-muted-foreground hover:text-destructive"
                              onClick={() => setCorteAEliminar(corte)}
                            >
                              <Trash2 className="w-4 h-4" />
                            </Button>
                          )}
                        </div>
                      </TableCell>
                    )}
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        )}
      </CardContent>

      {/* Diálogo de confirmación para eliminar */}
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

      {/* Diálogo de confirmación para cambiar tipo */}
      <AlertDialog open={!!corteACambiar} onOpenChange={() => setCorteACambiar(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>¿Cambiar tipo de corte?</AlertDialogTitle>
            <AlertDialogDescription>
              {corteACambiar && (
                <>
                  Estás por cambiar el corte de <strong>{corteACambiar.corte.sucursales?.nombre}</strong> del{" "}
                  <strong>{format(parseISO(corteACambiar.corte.created_at), "d 'de' MMMM 'a las' HH:mm", { locale: es })}</strong>
                  <br /><br />
                  de <strong>"{corteACambiar.corte.tipo_corte === "cierre" ? "Cierre" : "Del Momento"}"</strong> a{" "}
                  <strong>"{corteACambiar.nuevoTipo === "cierre" ? "Cierre" : "Del Momento"}"</strong>.
                </>
              )}
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel disabled={isCambiando}>Cancelar</AlertDialogCancel>
            <AlertDialogAction
              onClick={handleCambiarTipo}
              disabled={isCambiando}
            >
              {isCambiando ? "Cambiando..." : "Cambiar"}
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>

      {/* Diálogo para mover un corte a otro día de negocio */}
      <Dialog open={!!corteAFechar} onOpenChange={(o) => !o && setCorteAFechar(null)}>
        <DialogContent className="max-w-sm">
          <DialogHeader>
            <DialogTitle>Mover corte de día</DialogTitle>
            <DialogDescription>
              {corteAFechar && (
                <>
                  Corte de <strong>{corteAFechar.sucursales?.nombre}</strong> registrado el{" "}
                  {format(parseISO(corteAFechar.created_at), "d 'de' MMMM 'a las' HH:mm", { locale: es })},
                  hoy asignado al <strong>{format(parseISO(corteAFechar.fecha_venta), "d 'de' MMMM", { locale: es })}</strong>.
                  Úsalo cuando un corte se subió tarde y quedó en el día equivocado.
                  El cambio queda registrado en la bitácora.
                </>
              )}
            </DialogDescription>
          </DialogHeader>
          <Input type="date" value={nuevaFecha} onChange={(e) => setNuevaFecha(e.target.value)} />
          <DialogFooter>
            <Button variant="ghost" onClick={() => setCorteAFechar(null)} disabled={isFechando}>Cancelar</Button>
            <Button
              onClick={handleCambiarFecha}
              disabled={isFechando || !nuevaFecha || nuevaFecha === corteAFechar?.fecha_venta}
            >
              {isFechando ? "Moviendo..." : "Mover"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Diálogo para editar los montos de un corte */}
      <Dialog open={!!corteAEditar} onOpenChange={(o) => !o && setCorteAEditar(null)}>
        <DialogContent className="max-w-lg max-h-[85vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>Editar corte</DialogTitle>
            <DialogDescription>
              {corteAEditar && (
                <>
                  Corte de <strong>{corteAEditar.sucursales?.nombre}</strong> del{" "}
                  <strong>{format(parseISO(corteAEditar.fecha_venta), "d 'de' MMMM", { locale: es })}</strong>,
                  registrado a las {format(parseISO(corteAEditar.created_at), "HH:mm")}.
                  Todo cambio queda en la bitácora con tu usuario.
                </>
              )}
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-4">
            {onCambiarFecha && (
              <div className="space-y-1">
                <Label htmlFor="edit_fecha">Fecha de venta</Label>
                <Input
                  id="edit_fecha"
                  type="date"
                  value={fechaEdit}
                  onChange={(e) => setFechaEdit(e.target.value)}
                />
              </div>
            )}
            <div className="grid grid-cols-2 gap-3">

              {([
                ["corte_x", "Corte X"],
                ["efectivo", "Efectivo"],
                ["cobradas", "Cobradas"],
                ["por_cobrar", "Por Cobrar"],
              ] as const).map(([campo, label]) => (
                <div key={campo} className="space-y-1">
                  <Label htmlFor={`edit_${campo}`}>{label}</Label>
                  <Input
                    id={`edit_${campo}`}
                    type="number"
                    min="0"
                    step="0.01"
                    value={formEdit[campo] ?? ""}
                    onChange={(e) => setFormEdit((f) => ({ ...f, [campo]: e.target.value }))}
                  />
                </div>
              ))}
            </div>

            <div>
              <p className="text-sm font-medium mb-2">Tarjetas</p>
              <div className="grid grid-cols-3 gap-3">
                {([
                  ["tarjetas_banregio", "Banregio"],
                  ["tarjetas_mercadopago", "MercadoPago"],
                  ["tarjetas_haycash", "HayCash"],
                  // Espiral solo existe en Valle
                  ...(tieneEspiral(corteAEditar?.sucursales)
                    ? ([["tarjetas_espiral", "Espiral"]] as const)
                    : []),
                ] as const).map(([campo, label]) => (
                  <div key={campo} className="space-y-1">
                    <Label htmlFor={`edit_${campo}`}>{label}</Label>
                    <Input
                      id={`edit_${campo}`}
                      type="number"
                      min="0"
                      step="0.01"
                      value={formEdit[campo] ?? ""}
                      onChange={(e) => setFormEdit((f) => ({ ...f, [campo]: e.target.value }))}
                    />
                  </div>
                ))}
              </div>
              <div className="mt-3 space-y-1">
                <Label htmlFor="edit_tarjetas">
                  Total tarjetas {desgloseTarjetas > 0 && "(suma del desglose)"}
                </Label>
                <Input
                  id="edit_tarjetas"
                  type="number"
                  min="0"
                  step="0.01"
                  disabled={desgloseTarjetas > 0}
                  value={desgloseTarjetas > 0 ? desgloseTarjetas.toFixed(2) : (formEdit.tarjetas ?? "")}
                  onChange={(e) => setFormEdit((f) => ({ ...f, tarjetas: e.target.value }))}
                />
              </div>
            </div>

            <div>
              <p className="text-sm font-medium mb-2">Gastos y otros</p>
              <div className="grid grid-cols-2 gap-3">
                {([
                  ["pago_proveedores", "Proveedores"],
                  ["salarios", "Salarios"],
                  ["propinas", "Propinas"],
                  ["compras", "Compras"],
                  ["pago_servicios", "Servicios"],
                  ["rappi", "Rappi"],
                  ["uber", "Uber"],
                ] as const).map(([campo, label]) => (
                  <div key={campo} className="space-y-1">
                    <Label htmlFor={`edit_${campo}`}>{label}</Label>
                    <Input
                      id={`edit_${campo}`}
                      type="number"
                      min="0"
                      step="0.01"
                      value={formEdit[campo] ?? ""}
                      onChange={(e) => setFormEdit((f) => ({ ...f, [campo]: e.target.value }))}
                    />
                  </div>
                ))}
              </div>
            </div>

            <div className="rounded-md bg-muted px-3 py-2 text-sm flex items-center justify-between">
              <span className="text-muted-foreground">Total vendido (tarjetas + efectivo + por cobrar)</span>
              <span className="font-semibold">{formatMoney(totalCalc)}</span>
            </div>
          </div>

          <DialogFooter>
            <Button variant="ghost" onClick={() => setCorteAEditar(null)} disabled={isEditando}>Cancelar</Button>
            <Button onClick={handleEditar} disabled={isEditando}>
              {isEditando ? "Guardando..." : "Guardar cambios"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {bitacoraAbierta && <BitacoraCortes onClose={() => setBitacoraAbierta(false)} />}
    </Card>
  );
}

// ============================================================
// Bitácora: rastro inmutable de ediciones y borrados de cortes
// (tabla cortes_audit, la llena un trigger en la base).
// ============================================================
interface AuditRow {
  id: string;
  accion: "editar" | "eliminar";
  quien: string | null;
  antes: Record<string, unknown>;
  despues: Record<string, unknown> | null;
  created_at: string;
}

function BitacoraCortes({ onClose }: { onClose: () => void }) {
  const [filas, setFilas] = useState<AuditRow[]>([]);
  const [sucursales, setSucursales] = useState<Map<string, string>>(new Map());
  const [cargando, setCargando] = useState(true);

  useEffect(() => {
    (async () => {
      const db = supabase as any;
      const [audit, sucs] = await Promise.all([
        db.from("cortes_audit").select("*").order("created_at", { ascending: false }).limit(100),
        db.from("sucursales").select("id, nombre"),
      ]);
      setFilas((audit.data ?? []) as AuditRow[]);
      setSucursales(new Map(((sucs.data ?? []) as { id: string; nombre: string }[]).map((s) => [s.id, s.nombre])));
      setCargando(false);
    })();
  }, []);

  // Resume qué cambió entre antes y después (fecha, tipo, montos).
  const resumen = (f: AuditRow): string => {
    if (f.accion === "eliminar") {
      return `Eliminó el corte de ${f.antes.tipo_corte} del ${f.antes.fecha_venta} (total $${f.antes.total})`;
    }
    const cambios: string[] = [];
    const campos: [string, string][] = [
      ["fecha_venta", "fecha"], ["tipo_corte", "tipo"], ["total", "total"],
      ["efectivo", "efectivo"], ["tarjetas", "tarjetas"], ["corte_x", "corte X"],
      ["cobradas", "cobradas"], ["por_cobrar", "por cobrar"],
      ["pago_proveedores", "proveedores"], ["salarios", "salarios"],
      ["propinas", "propinas"], ["compras", "compras"],
      ["pago_servicios", "servicios"], ["rappi", "Rappi"], ["uber", "Uber"],
      ["tarjetas_banregio", "Banregio"], ["tarjetas_mercadopago", "MercadoPago"],
      ["tarjetas_haycash", "HayCash"], ["tarjetas_espiral", "Espiral"],
    ];
    for (const [campo, label] of campos) {
      const a = f.antes?.[campo];
      const d = f.despues?.[campo];
      if (String(a) !== String(d)) cambios.push(`${label}: ${a} → ${d}`);
    }
    return cambios.length ? `Cambió ${cambios.join(", ")}` : "Editó el corte (sin cambios visibles)";
  };

  return (
    <Dialog open onOpenChange={(o) => !o && onClose()}>
      <DialogContent className="max-w-2xl max-h-[80vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2"><History className="w-4 h-4" /> Bitácora de cortes</DialogTitle>
          <DialogDescription>
            Todo cambio o borrado de un corte queda aquí, con quién lo hizo. Este registro no se puede editar.
          </DialogDescription>
        </DialogHeader>
        {cargando ? (
          <p className="text-sm text-muted-foreground py-6 text-center">Cargando…</p>
        ) : filas.length === 0 ? (
          <p className="text-sm text-muted-foreground py-6 text-center">Sin movimientos registrados todavía.</p>
        ) : (
          <div className="space-y-2">
            {filas.map((f) => (
              <div key={f.id} className="rounded border px-3 py-2 text-sm">
                <div className="flex flex-wrap items-center gap-2">
                  <Badge variant={f.accion === "eliminar" ? "destructive" : "secondary"}>
                    {f.accion === "eliminar" ? "Eliminado" : "Editado"}
                  </Badge>
                  <span className="font-medium">{sucursales.get(String(f.antes?.sucursal_id)) ?? "—"}</span>
                  <span className="text-muted-foreground text-xs ml-auto">
                    {format(parseISO(f.created_at), "d MMM yyyy HH:mm", { locale: es })} · {f.quien ?? "—"}
                  </span>
                </div>
                <p className="text-muted-foreground mt-1">{resumen(f)}</p>
              </div>
            ))}
          </div>
        )}
      </DialogContent>
    </Dialog>
  );
}
