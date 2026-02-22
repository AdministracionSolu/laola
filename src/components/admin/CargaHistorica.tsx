import { useState, useCallback } from "react";
import * as XLSX from "xlsx";
import { supabase } from "@/integrations/supabase/client";
import { useToast } from "@/hooks/use-toast";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Progress } from "@/components/ui/progress";
import { Upload, FileSpreadsheet, CheckCircle2, AlertTriangle, Loader2, Trash2, X } from "lucide-react";
import { AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle } from "@/components/ui/alert-dialog";

const SUCURSAL_MAP: Record<string, { id: string; nombre: string }> = {
  "V. 161":        { id: "f9ef883d-88dc-47e1-945d-af145905a955", nombre: "Del Valle" },
  "V.161":         { id: "f9ef883d-88dc-47e1-945d-af145905a955", nombre: "Del Valle" },
  "VALLE 161":     { id: "f9ef883d-88dc-47e1-945d-af145905a955", nombre: "Del Valle" },
  "R. 955":        { id: "dc600e86-cfd8-466a-b0e1-319a836d3af8", nombre: "Las Brisas" },
  "R.955":         { id: "dc600e86-cfd8-466a-b0e1-319a836d3af8", nombre: "Las Brisas" },
  "INSURGENTES 955": { id: "dc600e86-cfd8-466a-b0e1-319a836d3af8", nombre: "Las Brisas" },
  "A. 233":        { id: "79324e7b-c8ef-4355-b2b1-6965346a0ab1", nombre: "Cervecería" },
  "A.233":         { id: "79324e7b-c8ef-4355-b2b1-6965346a0ab1", nombre: "Cervecería" },
  "ALAMEDA 233":   { id: "79324e7b-c8ef-4355-b2b1-6965346a0ab1", nombre: "Cervecería" },
  "S. 1639":       { id: "757d25e0-ce84-4d6f-a68a-d4639d3e409f", nombre: "Solares" },
  "S.1639":        { id: "757d25e0-ce84-4d6f-a68a-d4639d3e409f", nombre: "Solares" },
  "GUADALAJARA":   { id: "757d25e0-ce84-4d6f-a68a-d4639d3e409f", nombre: "Solares" },
};

interface ParsedRow {
  fecha: string;
  sucursal_id: string;
  sucursal_nombre: string;
  efectivo: number;
  tarjetas: number;
  total: number;
}

interface SucursalColumns {
  code: string;
  id: string;
  nombre: string;
  dateCol: number;
  efectivoCol: number;
  tarjetaCol: number;
  totalCol: number;
}

interface ParsedFile {
  fileName: string;
  mes: string;
  rows: ParsedRow[];
  errores: string[];
  duplicados: string[];
  status: "pending" | "uploading" | "done" | "error";
  progress: number;
  resultado: { ok: number; errores: number } | null;
}

function cleanMoney(val: unknown): number {
  if (typeof val === "number") return val;
  if (!val) return 0;
  const str = String(val).replace(/[$,]/g, "").trim();
  const n = parseFloat(str);
  return isNaN(n) ? 0 : n;
}

function excelDateToISO(val: unknown, year?: number): string | null {
  if (val instanceof Date && !isNaN(val.getTime())) {
    return val.toISOString().split("T")[0];
  }
  if (typeof val === "number" && val > 40000) {
    const d = new Date((val - 25569) * 86400 * 1000);
    if (!isNaN(d.getTime())) return d.toISOString().split("T")[0];
  }
  if (typeof val === "string") {
    const str = val.trim();
    if (!str) return null;
    const withYear = str.includes("202") ? str : `${str}-${year || 2025}`;
    const d = new Date(withYear);
    if (!isNaN(d.getTime())) return d.toISOString().split("T")[0];
    const d2 = new Date(str);
    if (!isNaN(d2.getTime())) return d2.toISOString().split("T")[0];
  }
  return null;
}

function parseExcel(data: ArrayBuffer): { rows: ParsedRow[]; mes: string; errores: string[] } {
  const wb = XLSX.read(data, { type: "array", cellDates: true });
  const ws = wb.Sheets[wb.SheetNames[0]];
  const raw: unknown[][] = XLSX.utils.sheet_to_json(ws, { header: 1, defval: "" });

  const errores: string[] = [];
  let sucursalHeaderRow = -1;
  const sucursalCols: SucursalColumns[] = [];

  for (let r = 0; r < Math.min(raw.length, 10); r++) {
    const row = raw[r];
    if (!row) continue;
    for (let c = 0; c < row.length; c++) {
      const cell = String(row[c] || "").trim();
      const match = Object.keys(SUCURSAL_MAP).find(
        (k) => cell.toUpperCase().replace(/\s+/g, " ") === k.toUpperCase().replace(/\s+/g, " ")
      );
      if (match && !sucursalCols.find((s) => s.code === match)) {
        sucursalHeaderRow = r;
        sucursalCols.push({
          code: match, id: SUCURSAL_MAP[match].id, nombre: SUCURSAL_MAP[match].nombre,
          dateCol: c, efectivoCol: c + 1, tarjetaCol: c + 2, totalCol: c + 3,
        });
      }
    }
  }

  if (sucursalCols.length === 0) {
    errores.push("No se encontraron códigos de sucursal en el archivo.");
    return { rows: [], mes: "", errores };
  }

  const dataStartRow = sucursalHeaderRow + 2;

  let year = 2025;
  let mes = "";
  for (let r = 0; r < Math.min(raw.length, 5); r++) {
    const firstCell = String(raw[r]?.[0] || "").trim();
    const yearMatch = firstCell.match(/(20\d{2})/);
    if (yearMatch) { year = parseInt(yearMatch[1]); mes = firstCell; break; }
  }

  const rows: ParsedRow[] = [];
  for (let r = dataStartRow; r < raw.length; r++) {
    const row = raw[r];
    if (!row) continue;
    const dateVal = row[sucursalCols[0].dateCol];
    const fecha = excelDateToISO(dateVal, year);
    if (!fecha) continue;

    for (const sc of sucursalCols) {
      const efectivo = cleanMoney(row[sc.efectivoCol]);
      const tarjetas = cleanMoney(row[sc.tarjetaCol]);
      const total = cleanMoney(row[sc.totalCol]);
      if (efectivo === 0 && tarjetas === 0 && total === 0) continue;
      rows.push({ fecha, sucursal_id: sc.id, sucursal_nombre: sc.nombre, efectivo, tarjetas, total });
    }
  }

  return { rows, mes, errores };
}

async function checkDuplicates(rows: ParsedRow[]): Promise<string[]> {
  if (rows.length === 0) return [];
  const fechas = [...new Set(rows.map((r) => r.fecha))];
  const sucursalIds = [...new Set(rows.map((r) => r.sucursal_id))];
  const { data: existentes } = await supabase
    .from("cortes_caja")
    .select("fecha_venta, sucursal_id")
    .eq("tipo_corte", "cierre")
    .in("sucursal_id", sucursalIds)
    .gte("fecha_venta", fechas[0])
    .lte("fecha_venta", fechas[fechas.length - 1]);

  if (existentes && existentes.length > 0) {
    const dupsSet = new Set(existentes.map((e) => `${e.fecha_venta}_${e.sucursal_id}`));
    const dups = rows
      .filter((r) => dupsSet.has(`${r.fecha}_${r.sucursal_id}`))
      .map((r) => `${r.fecha} - ${r.sucursal_nombre}`);
    return [...new Set(dups)];
  }
  return [];
}

const formatMoney = (v: number) =>
  new Intl.NumberFormat("es-MX", { style: "currency", currency: "MXN" }).format(v);

export function CargaHistorica() {
  const { toast } = useToast();
  const [files, setFiles] = useState<ParsedFile[]>([]);
  const [isProcessing, setIsProcessing] = useState(false);
  const [showReemplazar, setShowReemplazar] = useState(false);
  const [globalProgress, setGlobalProgress] = useState(0);

  const allDone = files.length > 0 && files.every((f) => f.status === "done" || f.status === "error");
  const hasDuplicates = files.some((f) => f.duplicados.length > 0 && f.status === "pending");
  const hasData = files.some((f) => f.rows.length > 0);

  const handleFiles = useCallback(async (e: React.ChangeEvent<HTMLInputElement>) => {
    const selectedFiles = Array.from(e.target.files || []).slice(0, 12);
    if (selectedFiles.length === 0) return;

    const parsed: ParsedFile[] = [];
    for (const file of selectedFiles) {
      const buffer = await file.arrayBuffer();
      const { rows, mes, errores } = parseExcel(buffer);
      const duplicados = await checkDuplicates(rows);
      parsed.push({
        fileName: file.name, mes, rows, errores, duplicados,
        status: "pending", progress: 0, resultado: null,
      });
    }
    setFiles(parsed);
    e.target.value = "";
  }, []);

  const insertFile = async (pf: ParsedFile, reemplazar: boolean): Promise<ParsedFile> => {
    if (pf.rows.length === 0) return { ...pf, status: "done", progress: 100, resultado: { ok: 0, errores: 0 } };

    try {
      if (reemplazar && pf.duplicados.length > 0) {
        const fechas = [...new Set(pf.rows.map((r) => r.fecha))];
        const sucursalIds = [...new Set(pf.rows.map((r) => r.sucursal_id))];
        await supabase.from("cortes_caja").delete()
          .eq("tipo_corte", "cierre").in("sucursal_id", sucursalIds)
          .gte("fecha_venta", fechas[0]).lte("fecha_venta", fechas[fechas.length - 1]);
      }

      const batchSize = 50;
      let ok = 0, errCount = 0;
      for (let i = 0; i < pf.rows.length; i += batchSize) {
        const batch = pf.rows.slice(i, i + batchSize).map((r) => ({
          sucursal_id: r.sucursal_id, tipo_corte: "cierre" as const,
          efectivo: r.efectivo, tarjetas: r.tarjetas, total: r.total,
          fecha_venta: r.fecha, corte_x: 0, cobradas: 0, por_cobrar: 0,
        }));
        const { error } = await supabase.from("cortes_caja").insert(batch);
        if (error) { errCount += batch.length; } else { ok += batch.length; }
        pf.progress = Math.round(((i + batch.length) / pf.rows.length) * 100);
      }
      return { ...pf, status: "done", progress: 100, resultado: { ok, errores: errCount } };
    } catch {
      return { ...pf, status: "error", progress: 100, resultado: { ok: 0, errores: pf.rows.length } };
    }
  };

  const startUpload = async (reemplazar = false) => {
    setIsProcessing(true);
    setShowReemplazar(false);
    setGlobalProgress(0);

    const updated = [...files];
    for (let i = 0; i < updated.length; i++) {
      if (updated[i].rows.length === 0) {
        updated[i] = { ...updated[i], status: "done", progress: 100, resultado: { ok: 0, errores: 0 } };
        continue;
      }
      updated[i] = { ...updated[i], status: "uploading" };
      setFiles([...updated]);
      updated[i] = await insertFile(updated[i], reemplazar);
      setFiles([...updated]);
      setGlobalProgress(Math.round(((i + 1) / updated.length) * 100));
    }

    const totalOk = updated.reduce((s, f) => s + (f.resultado?.ok || 0), 0);
    const totalErr = updated.reduce((s, f) => s + (f.resultado?.errores || 0), 0);
    toast({
      title: totalErr === 0 ? "Carga completada" : "Carga con errores",
      description: `${totalOk} registros insertados${totalErr > 0 ? `, ${totalErr} con error` : ""}`,
      variant: totalErr > 0 ? "destructive" : undefined,
    });
    setIsProcessing(false);
  };

  const handleConfirm = () => {
    if (hasDuplicates) { setShowReemplazar(true); } else { startUpload(false); }
  };

  const removeFile = (idx: number) => {
    setFiles((prev) => prev.filter((_, i) => i !== idx));
  };

  const limpiar = () => { setFiles([]); setGlobalProgress(0); };

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <FileSpreadsheet className="w-5 h-5" />
            Carga Histórica de Ventas
          </CardTitle>
          <CardDescription>
            Sube hasta 12 archivos Excel mensuales (.xlsx) para cargar los datos históricos como cortes de cierre.
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          {files.length === 0 && (
            <label className="flex flex-col items-center justify-center border-2 border-dashed rounded-lg p-8 cursor-pointer hover:border-primary/50 transition-colors">
              <Upload className="w-10 h-10 text-muted-foreground mb-3" />
              <span className="text-sm font-medium">Seleccionar archivos Excel</span>
              <span className="text-xs text-muted-foreground mt-1">Hasta 12 archivos .xlsx</span>
              <input type="file" accept=".xlsx,.xls" multiple className="hidden" onChange={handleFiles} />
            </label>
          )}
        </CardContent>
      </Card>

      {files.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle className="text-lg">
              {allDone ? "Resultado de la carga" : `${files.length} archivo(s) listos`}
            </CardTitle>
            {!allDone && (
              <CardDescription>
                {files.reduce((s, f) => s + f.rows.length, 0)} registros totales detectados
              </CardDescription>
            )}
          </CardHeader>
          <CardContent className="space-y-4">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Archivo</TableHead>
                  <TableHead>Mes</TableHead>
                  <TableHead className="text-right">Registros</TableHead>
                  <TableHead className="text-right">Total Ventas</TableHead>
                  <TableHead className="text-center">Estado</TableHead>
                  {!allDone && !isProcessing && <TableHead className="w-10" />}
                </TableRow>
              </TableHeader>
              <TableBody>
                {files.map((f, idx) => {
                  const totalVentas = f.rows.reduce((s, r) => s + r.total, 0);
                  return (
                    <TableRow key={idx}>
                      <TableCell className="font-medium text-xs max-w-[200px] truncate">{f.fileName}</TableCell>
                      <TableCell className="text-xs">{f.mes || "—"}</TableCell>
                      <TableCell className="text-right">{f.rows.length}</TableCell>
                      <TableCell className="text-right text-xs">{formatMoney(totalVentas)}</TableCell>
                      <TableCell className="text-center">
                        {f.errores.length > 0 && f.rows.length === 0 ? (
                          <span className="text-destructive text-xs flex items-center justify-center gap-1">
                            <AlertTriangle className="w-3 h-3" /> Error
                          </span>
                        ) : f.status === "done" ? (
                          <span className="text-primary text-xs flex items-center justify-center gap-1">
                            <CheckCircle2 className="w-3 h-3" /> {f.resultado?.ok || 0} ok
                          </span>
                        ) : f.status === "uploading" ? (
                          <span className="text-xs flex items-center justify-center gap-1">
                            <Loader2 className="w-3 h-3 animate-spin" /> {f.progress}%
                          </span>
                        ) : f.duplicados.length > 0 ? (
                          <span className="text-xs text-muted-foreground flex items-center justify-center gap-1">
                            <AlertTriangle className="w-3 h-3 text-destructive" /> {f.duplicados.length} dup
                          </span>
                        ) : (
                          <span className="text-xs text-muted-foreground">Listo</span>
                        )}
                      </TableCell>
                      {!allDone && !isProcessing && (
                        <TableCell>
                          <button onClick={() => removeFile(idx)} className="text-muted-foreground hover:text-destructive">
                            <X className="w-4 h-4" />
                          </button>
                        </TableCell>
                      )}
                    </TableRow>
                  );
                })}
              </TableBody>
            </Table>

            {isProcessing && (
              <div className="space-y-2">
                <Progress value={globalProgress} />
                <p className="text-sm text-muted-foreground text-center">
                  Procesando archivos... {globalProgress}%
                </p>
              </div>
            )}

            <div className="flex gap-2 justify-end">
              <Button variant="outline" onClick={limpiar} disabled={isProcessing}>
                <Trash2 className="w-4 h-4 mr-2" />
                {allDone ? "Cargar más archivos" : "Cancelar"}
              </Button>
              {!allDone && hasData && (
                <Button onClick={handleConfirm} disabled={isProcessing}>
                  {isProcessing ? (
                    <><Loader2 className="w-4 h-4 mr-2 animate-spin" /> Cargando...</>
                  ) : (
                    <><Upload className="w-4 h-4 mr-2" /> Confirmar Carga ({files.length} archivos)</>
                  )}
                </Button>
              )}
            </div>
          </CardContent>
        </Card>
      )}

      <AlertDialog open={showReemplazar} onOpenChange={setShowReemplazar}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Ya existen datos en algunos períodos</AlertDialogTitle>
            <AlertDialogDescription>
              Se encontraron registros duplicados en {files.filter((f) => f.duplicados.length > 0).length} archivo(s). ¿Deseas reemplazar los existentes con los nuevos datos?
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancelar</AlertDialogCancel>
            <AlertDialogAction onClick={() => startUpload(true)}>Reemplazar</AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}
