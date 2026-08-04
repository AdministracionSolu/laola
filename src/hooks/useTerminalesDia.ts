import { useCallback, useEffect, useMemo, useState } from "react";
import { supabase } from "@/integrations/supabase/client";
import { toast } from "sonner";

/**
 * Terminales del día: qué terminal punto de venta usa hoy cada sucursal.
 *
 * Tres capas (ver migración 20260804120000_terminales_del_dia.sql):
 *   - terminales            catálogo
 *   - terminales_sucursal   qué terminal TIENE cada sucursal (Espiral solo Valle)
 *   - terminales_asignacion cuál USA hoy
 *
 * Si una sucursal no tiene captura de hoy, hereda las suyas de planta: el
 * mensaje a cajas nunca sale vacío. Por eso nunca dejamos quitar la última
 * terminal de una sucursal, si no volvería a la herencia sin avisar.
 */

const db = supabase as any;

// Día de negocio de La Ola: rueda a las 4 AM CDMX (igual que la BD).
const fechaNegocioHoy = () =>
  new Date(Date.now() - 4 * 3600e3).toLocaleDateString("en-CA", { timeZone: "America/Mexico_City" });

// Orden en que las sucursales se muestran y se listan en el mensaje.
const ORDEN_SUCURSALES = ["VAL", "CER", "BRI", "SOL"];

export type Terminal = { id: string; nombre: string; orden: number; activa: boolean };
export type SucursalTerminales = {
  id: string;
  nombre: string;
  codigo: string;
  /** Terminales que la sucursal tiene de planta */
  disponibles: string[];
  /** Terminales que usa hoy (heredadas si no hay captura) */
  hoy: string[];
  /** false = está heredando; true = alguien capturó hoy */
  capturadoHoy: boolean;
};
export type AvisoConfig = { hora: string; zona: string; activo: boolean };

export function useTerminalesDia() {
  const fecha = fechaNegocioHoy();
  const [terminales, setTerminales] = useState<Terminal[]>([]);
  const [sucursales, setSucursales] = useState<{ id: string; nombre: string; codigo: string }[]>([]);
  const [disponibles, setDisponibles] = useState<Record<string, string[]>>({});
  const [asignadas, setAsignadas] = useState<Record<string, string[]>>({});
  const [config, setConfig] = useState<AvisoConfig | null>(null);
  const [enviadoHoy, setEnviadoHoy] = useState<{ created_at: string } | null>(null);
  const [mensaje, setMensaje] = useState<string>("");
  const [isLoading, setIsLoading] = useState(true);
  const [enviando, setEnviando] = useState(false);

  const cargarMensaje = useCallback(async () => {
    const { data } = await db.rpc("terminales_mensaje_dia", { p_fecha: fecha });
    setMensaje((data as string) ?? "");
  }, [fecha]);

  const cargar = useCallback(async () => {
    setIsLoading(true);
    const [term, suc, disp, asig, cfg, env] = await Promise.all([
      db.from("terminales").select("id, nombre, orden, activa").order("orden"),
      db.from("sucursales").select("id, nombre, prefijo_folio"),
      db.from("terminales_sucursal").select("sucursal_id, terminal_id"),
      db.from("terminales_asignacion").select("sucursal_id, terminal_id").eq("fecha", fecha),
      db.from("terminales_aviso_config").select("hora, zona, activo").eq("id", 1).maybeSingle(),
      db.from("terminales_aviso_enviado").select("created_at").eq("fecha", fecha).maybeSingle(),
    ]);

    if (term.error || suc.error) {
      toast.error("No se pudieron cargar las terminales del día.");
      setIsLoading(false);
      return;
    }

    setTerminales((term.data ?? []) as Terminal[]);
    setSucursales(
      ((suc.data ?? []) as { id: string; nombre: string; prefijo_folio: string | null }[])
        .map((s) => ({ id: s.id, nombre: s.nombre, codigo: (s.prefijo_folio ?? "").toUpperCase() }))
        .sort((a, b) => {
          const ia = ORDEN_SUCURSALES.indexOf(a.codigo);
          const ib = ORDEN_SUCURSALES.indexOf(b.codigo);
          return (ia === -1 ? 99 : ia) - (ib === -1 ? 99 : ib) || a.nombre.localeCompare(b.nombre);
        })
    );

    const agrupa = (filas: { sucursal_id: string; terminal_id: string }[]) => {
      const mapa: Record<string, string[]> = {};
      for (const f of filas) (mapa[f.sucursal_id] ||= []).push(f.terminal_id);
      return mapa;
    };
    setDisponibles(agrupa((disp.data ?? []) as any[]));
    setAsignadas(agrupa((asig.data ?? []) as any[]));
    setConfig((cfg.data as AvisoConfig) ?? null);
    setEnviadoHoy((env.data as { created_at: string }) ?? null);
    setIsLoading(false);
    void cargarMensaje();
  }, [fecha, cargarMensaje]);

  useEffect(() => {
    void cargar();
  }, [cargar]);

  const porSucursal = useMemo<SucursalTerminales[]>(
    () =>
      sucursales.map((s) => {
        const disp = disponibles[s.id] ?? [];
        const asig = asignadas[s.id];
        return {
          ...s,
          disponibles: disp,
          hoy: asig?.length ? asig : disp,
          capturadoHoy: Boolean(asig?.length),
        };
      }),
    [sucursales, disponibles, asignadas]
  );

  /** Prende o apaga una terminal para HOY. Escribe el set completo del día. */
  const alternarHoy = async (sucursalId: string, terminalId: string) => {
    const fila = porSucursal.find((s) => s.id === sucursalId);
    if (!fila) return;
    const siguiente = new Set(fila.hoy);
    if (siguiente.has(terminalId)) {
      if (siguiente.size === 1) {
        toast.error("Cada sucursal debe quedar con al menos una terminal.");
        return;
      }
      siguiente.delete(terminalId);
    } else {
      siguiente.add(terminalId);
    }

    const lista = [...siguiente];
    setAsignadas((p) => ({ ...p, [sucursalId]: lista })); // optimista

    const del = await db
      .from("terminales_asignacion")
      .delete()
      .eq("fecha", fecha)
      .eq("sucursal_id", sucursalId);
    const ins = lista.length
      ? await db.from("terminales_asignacion").insert(
          lista.map((t) => ({ fecha, sucursal_id: sucursalId, terminal_id: t }))
        )
      : { error: null };

    if (del.error || ins.error) {
      toast.error("No se pudo guardar la terminal del día.");
      void cargar();
      return;
    }
    void cargarMensaje();
  };

  /** Prende o apaga una terminal de planta (qué tiene la sucursal). */
  const alternarDisponible = async (sucursalId: string, terminalId: string) => {
    const actuales = disponibles[sucursalId] ?? [];
    const tiene = actuales.includes(terminalId);

    if (tiene) {
      const { error } = await db
        .from("terminales_sucursal")
        .delete()
        .eq("sucursal_id", sucursalId)
        .eq("terminal_id", terminalId);
      if (error) return toast.error("No se pudo quitar la terminal de la sucursal.");
      // Si la traía puesta hoy, también sale de la asignación del día.
      await db
        .from("terminales_asignacion")
        .delete()
        .eq("fecha", fecha)
        .eq("sucursal_id", sucursalId)
        .eq("terminal_id", terminalId);
      setDisponibles((p) => ({ ...p, [sucursalId]: actuales.filter((t) => t !== terminalId) }));
      setAsignadas((p) => ({ ...p, [sucursalId]: (p[sucursalId] ?? []).filter((t) => t !== terminalId) }));
    } else {
      const { error } = await db
        .from("terminales_sucursal")
        .insert({ sucursal_id: sucursalId, terminal_id: terminalId });
      if (error) return toast.error("No se pudo dar de alta la terminal en la sucursal.");
      setDisponibles((p) => ({ ...p, [sucursalId]: [...actuales, terminalId] }));
    }
    void cargarMensaje();
  };

  const guardarConfig = async (cambios: Partial<AvisoConfig>) => {
    const { error } = await db
      .from("terminales_aviso_config")
      .update({ ...cambios, updated_at: new Date().toISOString() })
      .eq("id", 1);
    if (error) return toast.error("No se pudo guardar la hora del aviso.");
    setConfig((p) => (p ? { ...p, ...cambios } : p));
  };

  /** Botón "Enviar ahora": ignora la hora y reenvía aunque ya haya salido. */
  const enviarAhora = async () => {
    setEnviando(true);
    const { data, error } = await db.rpc("avisar_terminales_dia", { p_forzar: true });
    setEnviando(false);
    if (error || !data) {
      toast.error("No se pudo enviar el aviso al grupo de cajas.");
      return;
    }
    toast.success("Aviso enviado al grupo de cajas.");
    void cargar();
  };

  return {
    fecha,
    terminales: terminales.filter((t) => t.activa),
    porSucursal,
    config,
    enviadoHoy,
    mensaje,
    isLoading,
    enviando,
    alternarHoy,
    alternarDisponible,
    guardarConfig,
    enviarAhora,
    refetch: cargar,
  };
}
