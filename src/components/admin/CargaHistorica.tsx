import { useState, useCallback } from "react";
import * as XLSX from "xlsx";
import { supabase } from "@/integrations/supabase/client";
import { useToast } from "@/hooks/use-toast";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Progress } from "@/components/ui/progress";
import { Upload, FileSpreadsheet, CheckCircle2, AlertTriangle, Loader2, Trash2 } from "lucide-react";
import { AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle } from "@/components/ui/alert-dialog";

const SUCURSAL_MAP: Record<string, { id: string; nombre: string }> = {
  "V. 161": { id: "f9ef883d-88dc-47e1-945d-af145905a955", nombre: "Del Valle" },
  "V.161":  { id: "f9ef883d-88dc-47e1-945d-af145905a955", nombre: "Del Valle" },
  "R. 955": { id: "dc600e86-cfd8-466a-b0e1-319a836d3af8", nombre: "Las Brisas" },
  "R.955":  { id: "dc600e86-cfd8-466a-b0e1-319a836d3af8", nombre: "Las Brisas" },
  "A. 233": { id: "79324e7b-c8ef-4355-b2b1-6965346a0ab1", nombre: "Cervecería" },
  "A.233":  { id: "79324e7b-c8ef-4355-b2b1-6965346a0ab1", nombre: "Cervecería" },
  "S. 1639": { id: "757d25e0-ce84-4d6f-a68a-d4639d3e409f", nombre: "Solares" },
  "S.1639":  { id: "757d25e0-ce84-4d6f-a68a-d4639d3e409f", nombre: "Solares" },
};

interface ParsedRow {
  fecha: string; // YYYY-MM-DD
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

function cleanMoney(val: unknown): number {
  if (typeof val === "number") return val;
  if (!val) return 0;
  const str = String(val).replace(/[$,]/g, "").trim();
  const n = parseFloat(str);
  return isNaN(n) ? 0 : n;
}

function excelDateToISO(val: unknown, year?: number): string | null {
  // If it's a JS Date (xlsx parses dates)
  if (val instanceof Date && !isNaN(val.getTime())) {
    return val.toISOString().split("T")[0];
  }
  // If it's an Excel serial number
  if (typeof val === "number" && val > 40000) {
    const d = new Date((val - 25569) * 86400 * 1000);
    if (!isNaN(d.getTime())) return d.toISOString().split("T")[0];
  }
  // If it's a string like "1-Dec" or "1-Dec-2025"
  if (typeof val === "string") {
    const str = val.trim();
    if (!str) return null;
    // Try direct parse with year hint
    const withYear = str.includes("202") ? str : `${str}-${year || 2025}`;
    const d = new Date(withYear);
    if (!isNaN(d.getTime())) return d.toISOString().split("T")[0];
    // Try native parse
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

  // Find the header row with sucursal codes and the sub-header with EFECTIVO/TARJETA
  let sucursalHeaderRow = -1;
  let subHeaderRow = -1;
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
          code: match,
          id: SUCURSAL_MAP[match].id,
          nombre: SUCURSAL_MAP[match].nombre,
          dateCol: c,
          efectivoCol: c + 1,
          tarjetaCol: c + 2,
          totalCol: c + 3,
        });
      }
    }
  }

  if (sucursalCols.length === 0) {
    errores.push("No se encontraron códigos de sucursal (V.161, R.955, A.233, S.1639) en el archivo.");
    return { rows: [], mes: "", errores };
  }

  // Find sub-header row (EFECTIVO, TARJETA) to know where data starts
  subHeaderRow = sucursalHeaderRow + 1;
  const dataStartRow = subHeaderRow + 1;

  // Detect year from the title row (e.g., "DICIEMBRE 2025")
  let year = 2025;
  let mes = "";
  for (let r = 0; r < Math.min(raw.length, 5); r++) {
    const firstCell = String(raw[r]?.[0] || "").trim();
    const yearMatch = firstCell.match(/(20\d{2})/);
    if (yearMatch) {
      year = parseInt(yearMatch[1]);
      mes = firstCell;
      break;
    }
  }

  const rows: ParsedRow[] = [];

  for (let r = dataStartRow; r < raw.length; r++) {
    const row = raw[r];
    if (!row) continue;

    // Use the first sucursal's date column to check if this is a data row
    const dateVal = row[sucursalCols[0].dateCol];
    const fecha = excelDateToISO(dateVal, year);
    if (!fecha) continue; // Skip totals row and empty rows

    for (const sc of sucursalCols) {
      const efectivo = cleanMoney(row[sc.efectivoCol]);
      const tarjetas = cleanMoney(row[sc.tarjetaCol]);
      const total = cleanMoney(row[sc.totalCol]);

      // Skip rows where everything is 0
      if (efectivo === 0 && tarjetas === 0 && total === 0) continue;

      rows.push({
        fecha,
        sucursal_id: sc.id,
        sucursal_nombre: sc.nombre,
        efectivo,
        tarjetas,
        total,
      });
    }
  }

  return { rows, mes, errores };
}

const formatMoney = (v: number) =>
  new Intl.NumberFormat("es-MX", { style: "currency", currency: "MXN" }).format(v);

export function CargaHistorica() {
  const { toast } = useToast();
  const [parsedData, setParsedData] = useState<ParsedRow[] | null>(null);
  const [mes, setMes] = useState("");
  const [parseErrors, setParseErrors] = useState<string[]>([]);
  const [isUploading, setIsUploading] = useState(false);
  const [progress, setProgress] = useState(0);
  const [resultado, setResultado] = useState<{ ok: number; errores: number } | null>(null);
  const [duplicados, setDuplicados] = useState<string[] | null>(null);
  const [showReemplazar, setShowReemplazar] = useState(false);
  const [fileName, setFileName] = useState("");

  const handleFile = useCallback(async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setFileName(file.name);
    setResultado(null);
    setDuplicados(null);

    const buffer = await file.arrayBuffer();
    const { rows, mes: mesDetectado, errores } = parseExcel(buffer);

    setParsedData(rows);
    setMes(mesDetectado);
    setParseErrors(errores);

    if (rows.length > 0) {
      // Check for duplicates
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
        if (dups.length > 0) setDuplicados([...new Set(dups)]);
      }
    }

    // Reset file input
    e.target.value = "";
  }, []);

  const insertarDatos = async (reemplazar = false) => {
    if (!parsedData || parsedData.length === 0) return;
    setIsUploading(true);
    setProgress(0);
    setShowReemplazar(false);

    try {
      if (reemplazar) {
        // Delete existing cierre records for this period
        const fechas = [...new Set(parsedData.map((r) => r.fecha))];
        const sucursalIds = [...new Set(parsedData.map((r) => r.sucursal_id))];
        const { error: delErr } = await supabase
          .from("cortes_caja")
          .delete()
          .eq("tipo_corte", "cierre")
          .in("sucursal_id", sucursalIds)
          .gte("fecha_venta", fechas[0])
          .lte("fecha_venta", fechas[fechas.length - 1]);
        if (delErr) throw delErr;
      }

      // Insert in batches of 50
      const batchSize = 50;
      let ok = 0;
      let errCount = 0;

      for (let i = 0; i < parsedData.length; i += batchSize) {
        const batch = parsedData.slice(i, i + batchSize).map((r) => ({
          sucursal_id: r.sucursal_id,
          tipo_corte: "cierre" as const,
          efectivo: r.efectivo,
          tarjetas: r.tarjetas,
          total: r.total,
          fecha_venta: r.fecha,
          corte_x: 0,
          cobradas: 0,
          por_cobrar: 0,
        }));

        const { error } = await supabase.from("cortes_caja").insert(batch);
        if (error) {
          errCount += batch.length;
          console.error("Error inserting batch:", error);
        } else {
          ok += batch.length;
        }
        setProgress(Math.round(((i + batch.length) / parsedData.length) * 100));
      }

      setResultado({ ok, errores: errCount });
      if (errCount === 0) {
        toast({ title: "Carga completada", description: `${ok} registros insertados exitosamente.` });
      } else {
        toast({ title: "Carga parcial", description: `${ok} ok, ${errCount} con error.`, variant: "destructive" });
      }
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : "Error desconocido";
      toast({ title: "Error", description: msg, variant: "destructive" });
    } finally {
      setIsUploading(false);
    }
  };

  const handleConfirm = () => {
    if (duplicados && duplicados.length > 0) {
      setShowReemplazar(true);
    } else {
      insertarDatos(false);
    }
  };

  const limpiar = () => {
    setParsedData(null);
    setMes("");
    setParseErrors([]);
    setResultado(null);
    setDuplicados(null);
    setFileName("");
  };

  // Summary by sucursal
  const resumenSucursal = parsedData
    ? Object.values(
        parsedData.reduce(
          (acc, r) => {
            if (!acc[r.sucursal_id]) acc[r.sucursal_id] = { nombre: r.sucursal_nombre, dias: 0, total: 0 };
            acc[r.sucursal_id].dias++;
            acc[r.sucursal_id].total += r.total;
            return acc;
          },
          {} as Record<string, { nombre: string; dias: number; total: number }>
        )
      )
    : [];

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <FileSpreadsheet className="w-5 h-5" />
            Carga Histórica de Ventas
          </CardTitle>
          <CardDescription>
            Sube un archivo Excel mensual (.xlsx) para cargar los datos históricos como cortes de cierre.
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          {!parsedData && !resultado && (
            <label className="flex flex-col items-center justify-center border-2 border-dashed rounded-lg p-8 cursor-pointer hover:border-primary/50 transition-colors">
              <Upload className="w-10 h-10 text-muted-foreground mb-3" />
              <span className="text-sm font-medium">Seleccionar archivo Excel</span>
              <span className="text-xs text-muted-foreground mt-1">Formato: .xlsx</span>
              <input type="file" accept=".xlsx,.xls" className="hidden" onChange={handleFile} />
            </label>
          )}

          {parseErrors.length > 0 && (
            <div className="p-3 rounded-lg bg-destructive/10 border border-destructive/20 text-sm">
              <p className="font-medium flex items-center gap-2 text-destructive">
                <AlertTriangle className="w-4 h-4" /> Errores al leer archivo
              </p>
              {parseErrors.map((e, i) => (
                <p key={i} className="mt-1">{e}</p>
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Preview */}
      {parsedData && parsedData.length > 0 && !resultado && (
        <Card>
          <CardHeader>
            <CardTitle className="text-lg">Preview: {mes || fileName}</CardTitle>
            <CardDescription>
              {parsedData.length} registros detectados en {resumenSucursal.length} sucursal(es)
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            {/* Resumen por sucursal */}
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Sucursal</TableHead>
                  <TableHead className="text-right">Días</TableHead>
                  <TableHead className="text-right">Total</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {resumenSucursal.map((s) => (
                  <TableRow key={s.nombre}>
                    <TableCell className="font-medium">{s.nombre}</TableCell>
                    <TableCell className="text-right">{s.dias}</TableCell>
                    <TableCell className="text-right">{formatMoney(s.total)}</TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>

            {duplicados && duplicados.length > 0 && (
              <div className="p-3 rounded-lg bg-accent border border-border text-sm">
                <p className="font-medium flex items-center gap-2">
                  <AlertTriangle className="w-4 h-4 text-destructive" />
                  {duplicados.length} registro(s) ya existen en la base de datos
                </p>
                <p className="text-xs text-muted-foreground mt-1">
                  Al confirmar podrás elegir reemplazar los existentes o cancelar.
                </p>
              </div>
            )}

            {isUploading && (
              <div className="space-y-2">
                <Progress value={progress} />
                <p className="text-sm text-muted-foreground text-center">{progress}%</p>
              </div>
            )}

            <div className="flex gap-2 justify-end">
              <Button variant="outline" onClick={limpiar} disabled={isUploading}>
                <Trash2 className="w-4 h-4 mr-2" />
                Cancelar
              </Button>
              <Button onClick={handleConfirm} disabled={isUploading}>
                {isUploading ? (
                  <>
                    <Loader2 className="w-4 h-4 mr-2 animate-spin" />
                    Cargando...
                  </>
                ) : (
                  <>
                    <Upload className="w-4 h-4 mr-2" />
                    Confirmar Carga
                  </>
                )}
              </Button>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Result */}
      {resultado && (
        <Card>
          <CardContent className="pt-6">
            <div className="flex flex-col items-center gap-3 text-center">
              <CheckCircle2 className="w-12 h-12 text-primary" />
              <h3 className="text-lg font-semibold">Carga Completada</h3>
              <p className="text-sm text-muted-foreground">
                {resultado.ok} registros insertados
                {resultado.errores > 0 && `, ${resultado.errores} con error`}
              </p>
              <Button variant="outline" onClick={limpiar} className="mt-2">
                Cargar otro archivo
              </Button>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Replace dialog */}
      <AlertDialog open={showReemplazar} onOpenChange={setShowReemplazar}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Ya existen datos en este período</AlertDialogTitle>
            <AlertDialogDescription>
              Se encontraron {duplicados?.length} registro(s) existentes. ¿Deseas reemplazarlos con los nuevos datos?
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancelar</AlertDialogCancel>
            <AlertDialogAction onClick={() => insertarDatos(true)}>
              Reemplazar
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}
