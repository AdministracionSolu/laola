import * as XLSX from "xlsx";

/** Exporta un arreglo de objetos planos a un archivo .xlsx. */
export function exportarExcel(
  filas: Record<string, string | number | null>[],
  nombreArchivo: string,
  nombreHoja = "Datos"
) {
  const ws = XLSX.utils.json_to_sheet(filas);
  const wb = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(wb, ws, nombreHoja);
  XLSX.writeFile(wb, `${nombreArchivo}.xlsx`);
}
