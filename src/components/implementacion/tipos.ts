// Tipos y ayudas del Portal de Implementación (/implementacion).
// La forma la define panel_implementacion() en
// supabase/migrations/20260806120000_portal_implementacion.sql

export type Sucursal = {
  id: string;
  nombre: string;
  prefijo_folio: string | null;
  es_valle: boolean;
};

export type DiaCorte = {
  fecha: string;
  cierre: boolean;
  momentos: number;
  capturado_at: string | null;
  alertado: boolean;
};

export type FilaCortes = {
  sucursal_id: string;
  nombre: string;
  hora_limite: string | null;
  dias: DiaCorte[];
};

export type DiaProveedor = {
  fecha: string;
  productos: number;
  hora: string | null;
};

export type FilaProveedor = {
  id: string;
  nombre: string;
  telefono: string | null;
  categoria: string | null;
  productos_activos: number;
  dias: DiaProveedor[];
  intentos: number;
  fallidos: number;
  ultimo_precio_at: string | null;
};

export type PedidoDia = {
  estado: string;
  registrado_por: string | null;
  enviado_at: string | null;
  renglones: number;
  pedidos: number;
  con_existencia: number;
  con_sugerida: number;
} | null;

export type RecepcionDia = {
  proveedor: string;
  registrado_por: string | null;
  hora: string;
  renglones: number;
};

export type DiaOperacion = {
  fecha: string;
  pedido: PedidoDia;
  recepciones: RecepcionDia[];
};

export type FilaOperacion = {
  sucursal_id: string;
  nombre: string;
  dias: DiaOperacion[];
};

export type FilaFacturas = {
  sucursal_id: string;
  nombre: string;
  dias: { fecha: string; solicitadas: number; timbradas: number }[];
  pendientes_totales: number;
  rechazadas: number;
  historico: number;
};

export type Responsable = {
  id: string;
  sucursal_id: string | null;
  sucursal: string | null;
  proceso: string;
  persona: string;
  puesto: string | null;
  telefono: string | null;
  notas: string | null;
};

export type Pendiente = {
  id: string;
  titulo: string;
  sucursal_id: string | null;
  sucursal: string | null;
  area: string | null;
  estado: "pendiente" | "en_curso" | "hecho" | "bloqueado";
  semana_objetivo: string | null;
  responsable: string | null;
  notas: string | null;
  updated_at: string;
};

export type PanelData = {
  ok: true;
  hoy: string;
  desde: string;
  hasta: string;
  dias: string[];
  sucursales: Sucursal[];
  cortes: FilaCortes[];
  proveedores: FilaProveedor[];
  operacion: FilaOperacion[];
  facturas: FilaFacturas[];
  facturas_sin_sucursal: number;
  responsables: Responsable[];
  pendientes: Pendiente[];
};

export const PROCESOS: { valor: string; etiqueta: string }[] = [
  { valor: "corte", etiqueta: "Corte de cierre" },
  { valor: "pedido", etiqueta: "Pedido sugerido" },
  { valor: "existencia", etiqueta: "Existencias" },
  { valor: "recepcion", etiqueta: "Recepciones" },
  { valor: "precios", etiqueta: "Precios de proveedor" },
  { valor: "factura", etiqueta: "Facturación (QR)" },
  { valor: "horario", etiqueta: "Horarios" },
];

export const ESTADOS_PENDIENTE: { valor: Pendiente["estado"]; etiqueta: string }[] = [
  { valor: "pendiente", etiqueta: "Pendiente" },
  { valor: "en_curso", etiqueta: "En curso" },
  { valor: "hecho", etiqueta: "Hecho" },
  { valor: "bloqueado", etiqueta: "Bloqueado" },
];

/** Etiqueta corta de un día ISO: "Lun 4". Se parsea a mano para no correr la fecha por zona horaria. */
export function etiquetaDia(iso: string): string {
  const [a, m, d] = iso.split("-").map(Number);
  const f = new Date(a, m - 1, d);
  const dias = ["Dom", "Lun", "Mar", "Mié", "Jue", "Vie", "Sáb"];
  return `${dias[f.getDay()]} ${d}`;
}

export function etiquetaFechaLarga(iso: string): string {
  const [a, m, d] = iso.split("-").map(Number);
  const meses = ["ene", "feb", "mar", "abr", "may", "jun", "jul", "ago", "sep", "oct", "nov", "dic"];
  return `${d} ${meses[m - 1]} ${a}`;
}

/** Hora local corta de un timestamp ISO ("18:42"). */
export function hora(ts: string | null): string {
  if (!ts) return "";
  const f = new Date(ts);
  return f.toLocaleTimeString("es-MX", { hour: "2-digit", minute: "2-digit", hour12: false });
}

/**
 * Días que ya se pueden calificar: los anteriores a hoy.
 * El día en curso no cuenta en el porcentaje — su información aún se
 * está capturando y contarlo pintaría de rojo una jornada que va bien.
 */
export function diasEvaluables(dias: string[], hoy: string): string[] {
  return dias.filter((d) => d < hoy);
}

export function pct(hechos: number, total: number): number | null {
  if (total <= 0) return null;
  return Math.round((hechos / total) * 100);
}

/** Color del porcentaje: verde ≥90, ámbar ≥70, rojo abajo. */
export function colorPct(p: number | null): string {
  if (p === null) return "text-muted-foreground";
  if (p >= 90) return "text-emerald-600";
  if (p >= 70) return "text-amber-600";
  return "text-red-600";
}
