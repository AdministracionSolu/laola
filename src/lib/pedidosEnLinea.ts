import { supabase } from "@/integrations/supabase/client";
import type { SupabaseClient } from "@supabase/supabase-js";

// Las tablas de este módulo todavía no existen en types.ts (lo regenera Lovable
// al aplicar el SQL), por lo que se usa un cliente sin tipos generados y se
// tipan explícitamente los resultados de cada consulta.
export const db = supabase as unknown as SupabaseClient;

// ---------- Tipos de catálogo ----------
export interface SucursalEnLinea {
  id: string;
  nombre: string;
  direccion: string | null;
  slug: string | null;
  telefono_contacto: string | null;
  pedidos_en_linea_activos: boolean;
  pedidos_pausados_hasta: string | null;
  venta_alcohol_en_linea: boolean;
  tiempo_estimado_min: number;
  prefijo_folio: string | null;
  zona_horaria: string | null;
}

export interface HorarioSucursal {
  id: string;
  sucursal_id: string;
  dia_semana: number; // 0 = domingo
  hora_apertura: string; // 'HH:MM:SS'
  hora_cierre: string;
  activo: boolean;
}

export interface ZonaReparto {
  id: string;
  sucursal_id: string;
  nombre: string;
  costo_envio: number;
  pedido_minimo: number;
  activa: boolean;
}

export interface MenuCategoria {
  id: string;
  nombre: string;
  orden: number;
  activa: boolean;
}

export interface MenuItem {
  id: string;
  categoria_id: string;
  nombre: string;
  descripcion: string | null;
  es_alcohol: boolean;
  opciones: Record<string, string[]> | null;
  orden: number;
}

export interface MenuVariante {
  id: string;
  item_id: string;
  nombre: string;
  orden: number;
}

export interface PrecioVarianteSucursal {
  variante_id: string;
  sucursal_id: string;
  precio: number;
  disponible: boolean;
}

// ---------- Tipos de pedidos ----------
export interface PedidoEnLineaItem {
  id: string;
  pedido_id: string;
  variante_id: string | null;
  nombre_item: string;
  nombre_variante: string;
  precio_unitario: number;
  cantidad: number;
  opciones_elegidas: Record<string, string> | null;
  notas: string | null;
}

export interface PedidoEnLinea {
  id: string;
  folio: string;
  token: string;
  sucursal_id: string;
  tipo: "recoger" | "reparto";
  estado: EstadoPedido;
  nombre_cliente: string;
  telefono: string;
  zona_id: string | null;
  direccion: string | null;
  referencias: string | null;
  subtotal: number;
  costo_envio: number;
  total: number;
  notas_generales: string | null;
  motivo_cancelacion: string | null;
  created_at: string;
  updated_at: string;
  confirmado_at: string | null;
  listo_at: string | null;
  entregado_at: string | null;
  pedidos_en_linea_items?: PedidoEnLineaItem[];
  zonas_reparto?: { nombre: string } | null;
}

export type EstadoPedido =
  | "nuevo"
  | "confirmado"
  | "preparando"
  | "listo"
  | "en_reparto"
  | "entregado"
  | "cancelado";

export const ETIQUETA_ESTADO: Record<EstadoPedido, string> = {
  nuevo: "Nuevo",
  confirmado: "Confirmado",
  preparando: "Preparando",
  listo: "Listo",
  en_reparto: "En reparto",
  entregado: "Entregado",
  cancelado: "Cancelado",
};

/** Siguiente estado del flujo según el tipo de pedido. */
export function siguienteEstado(estado: EstadoPedido, tipo: "recoger" | "reparto"): EstadoPedido | null {
  switch (estado) {
    case "nuevo":
      return "confirmado";
    case "confirmado":
      return "preparando";
    case "preparando":
      return "listo";
    case "listo":
      return tipo === "reparto" ? "en_reparto" : "entregado";
    case "en_reparto":
      return "entregado";
    default:
      return null;
  }
}

export const MOTIVOS_CANCELACION = [
  "Cliente no localizable",
  "Sin insumos",
  "Fuera de zona",
  "Otro",
] as const;

// ---------- Carrito ----------
export interface LineaCarrito {
  /** id local de la línea (variante + opciones + notas pueden repetirse) */
  uid: string;
  variante_id: string;
  item_id: string;
  nombre_item: string;
  nombre_variante: string;
  precio: number;
  cantidad: number;
  opciones_elegidas: Record<string, string> | null;
  notas: string | null;
  /** Marcada por la RPC cuando se agotó mientras el carrito estaba abierto */
  agotado?: boolean;
}

// ---------- Datos del cliente (registro ligero, sin cuentas) ----------
// Se recuerdan en el dispositivo para precargar el checkout la próxima vez.
export interface DatosCliente {
  nombre: string;
  telefono: string;
  direccion: string;
  referencias: string;
}

const LS_CLIENTE = "laola_datos_cliente";

export function leerDatosCliente(): DatosCliente | null {
  try {
    const crudo = localStorage.getItem(LS_CLIENTE);
    if (!crudo) return null;
    const datos = JSON.parse(crudo) as DatosCliente;
    return typeof datos.nombre === "string" ? datos : null;
  } catch {
    return null;
  }
}

export function guardarDatosCliente(datos: DatosCliente): void {
  try {
    localStorage.setItem(LS_CLIENTE, JSON.stringify(datos));
  } catch {
    // almacenamiento lleno o bloqueado: no es crítico
  }
}

export function olvidarDatosCliente(): void {
  localStorage.removeItem(LS_CLIENTE);
}

// ---------- Utilerías ----------
export function dinero(n: number): string {
  return `$${Number(n).toLocaleString("es-MX", {
    minimumFractionDigits: 0,
    maximumFractionDigits: 2,
  })}`;
}

export function normalizarTelefono(telefono: string): string {
  let digitos = telefono.replace(/\D/g, "");
  if (digitos.length === 13 && digitos.startsWith("521")) digitos = digitos.slice(3);
  else if (digitos.length === 12 && digitos.startsWith("52")) digitos = digitos.slice(2);
  return digitos;
}

export const DIAS_SEMANA = ["Domingo", "Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado"];

/** 'HH:MM:SS' → 'HH:MM' */
export function horaCorta(hora: string): string {
  return hora.slice(0, 5);
}

/** Día de la semana y minutos transcurridos del día en la zona horaria de la sucursal. */
export function horaLocalSucursal(zonaHoraria: string | null): { dia: number; minutos: number } {
  const tz = zonaHoraria || "America/Mexico_City";
  const partes = new Intl.DateTimeFormat("en-US", {
    timeZone: tz,
    weekday: "short",
    hour: "2-digit",
    minute: "2-digit",
    hour12: false,
  }).formatToParts(new Date());
  const valor = (tipo: string) => partes.find((p) => p.type === tipo)?.value ?? "";
  const dias: Record<string, number> = { Sun: 0, Mon: 1, Tue: 2, Wed: 3, Thu: 4, Fri: 5, Sat: 6 };
  const hora = Number(valor("hour")) % 24; // Intl puede regresar '24' a medianoche
  return { dia: dias[valor("weekday")] ?? 0, minutos: hora * 60 + Number(valor("minute")) };
}

function minutosDe(hora: string): number {
  const [h, m] = hora.split(":").map(Number);
  return h * 60 + m;
}

export interface EstadoSucursal {
  abierta: boolean;
  motivo: "ok" | "desactivado" | "pausada" | "horario";
  /** Texto auxiliar: hora de reapertura o rangos de hoy */
  detalle: string | null;
}

/** Mismo criterio que valida la RPC server-side (el front solo lo refleja). */
export function estadoSucursal(
  sucursal: SucursalEnLinea,
  horarios: HorarioSucursal[]
): EstadoSucursal {
  if (!sucursal.pedidos_en_linea_activos) {
    return { abierta: false, motivo: "desactivado", detalle: null };
  }
  if (sucursal.pedidos_pausados_hasta && new Date(sucursal.pedidos_pausados_hasta) > new Date()) {
    const hora = new Intl.DateTimeFormat("es-MX", {
      timeZone: sucursal.zona_horaria || "America/Mexico_City",
      hour: "2-digit",
      minute: "2-digit",
      hour12: false,
    }).format(new Date(sucursal.pedidos_pausados_hasta));
    return { abierta: false, motivo: "pausada", detalle: hora };
  }
  const { dia, minutos } = horaLocalSucursal(sucursal.zona_horaria);
  const deHoy = horarios.filter((h) => h.sucursal_id === sucursal.id && h.activo && h.dia_semana === dia);
  const abierta = deHoy.some((h) => {
    const apertura = minutosDe(h.hora_apertura);
    const cierre = minutosDe(h.hora_cierre);
    if (apertura <= cierre) return minutos >= apertura && minutos < cierre;
    return minutos >= apertura || minutos < cierre; // rango que cruza medianoche
  });
  const rangos = deHoy
    .map((h) => `${horaCorta(h.hora_apertura)}–${horaCorta(h.hora_cierre)}`)
    .join(", ");
  return {
    abierta,
    motivo: abierta ? "ok" : "horario",
    detalle: rangos || null,
  };
}

// ---------- Errores de RPC → mensaje para el cliente ----------
export function mensajeErrorPedido(mensaje: string, telefonoSucursal?: string | null): string {
  const limpio = mensaje.replace(/^.*?(SUCURSAL_|PEDIDOS_|FUERA_|TIPO_|NOMBRE_|TELEFONO_|LIMITE_|ZONA_|DIRECCION_|CARRITO_|CANTIDAD_|ITEM_|ALCOHOL_|PEDIDO_MINIMO)/, "$1");
  const [codigo, detalle] = limpio.split("|");
  const llamanos = telefonoSucursal ? ` Si necesitas ayuda, llámanos al ${telefonoSucursal}.` : "";
  switch (codigo) {
    case "SUCURSAL_NO_ENCONTRADA":
      return "No encontramos la sucursal. Recarga la página.";
    case "PEDIDOS_DESACTIVADOS":
      return "Esta sucursal no está recibiendo pedidos en línea por ahora." + llamanos;
    case "SUCURSAL_PAUSADA":
      return `La cocina está saturada en este momento. Volvemos a recibir pedidos a las ${detalle}.` + llamanos;
    case "FUERA_DE_HORARIO":
      return "La sucursal está cerrada en este momento. Revisa el horario e inténtalo de nuevo." + llamanos;
    case "TIPO_INVALIDO":
      return "Elige si quieres recoger o que te lo llevemos.";
    case "NOMBRE_REQUERIDO":
      return "Escribe tu nombre para continuar.";
    case "TELEFONO_INVALIDO":
      return "El teléfono debe tener 10 dígitos.";
    case "LIMITE_PEDIDOS":
      return "Ya hiciste varios pedidos con este teléfono en la última hora. Espera un poco o llámanos directo." + llamanos;
    case "ZONA_INVALIDA":
      return "Elige una zona de reparto válida.";
    case "DIRECCION_REQUERIDA":
      return "Escribe tu dirección completa para el reparto.";
    case "CARRITO_VACIO":
      return "Tu carrito está vacío.";
    case "CARRITO_DEMASIADO_GRANDE":
      return "Tu pedido tiene demasiados productos. Para pedidos grandes llámanos directo." + llamanos;
    case "CANTIDAD_INVALIDA":
      return "Hay una cantidad inválida en tu carrito.";
    case "ITEM_NO_DISPONIBLE":
      return `"${detalle}" se acaba de agotar. Quítalo del carrito para continuar.`;
    case "ALCOHOL_NO_DISPONIBLE":
      return `"${detalle}" no está disponible para pedidos en línea en esta sucursal.`;
    default:
      return "No pudimos enviar tu pedido. Inténtalo de nuevo." + llamanos;
  }
}

/** Extrae el nombre del item agotado del mensaje de error de la RPC, si aplica. */
export function itemAgotadoDeError(mensaje: string): string | null {
  const idx = mensaje.indexOf("ITEM_NO_DISPONIBLE|");
  if (idx < 0) return null;
  return mensaje.slice(idx + "ITEM_NO_DISPONIBLE|".length).trim() || null;
}
