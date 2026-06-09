import { useMemo, useState } from "react";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Switch } from "@/components/ui/switch";
import { Badge } from "@/components/ui/badge";
import { Loader2, Minus, Pause, Play, Plus, Search, Trash2 } from "lucide-react";
import { toast } from "sonner";
import {
  db,
  DIAS_SEMANA,
  dinero,
  horaCorta,
  type HorarioSucursal,
  type SucursalEnLinea,
  type ZonaReparto,
} from "@/lib/pedidosEnLinea";

// ============ Controles generales (toggle, pausa, tiempo, alcohol) ============
function ControlesSucursal({ sucursal, onRecargar }: { sucursal: SucursalEnLinea; onRecargar: () => void }) {
  const [guardando, setGuardando] = useState(false);

  const actualizar = async (cambios: Partial<SucursalEnLinea>, mensaje: string) => {
    setGuardando(true);
    const { error } = await db.from("sucursales").update(cambios).eq("id", sucursal.id);
    setGuardando(false);
    if (error) {
      toast.error(`No se pudo guardar: ${error.message}`);
      return;
    }
    toast.success(mensaje);
    onRecargar();
  };

  const pausada =
    sucursal.pedidos_pausados_hasta && new Date(sucursal.pedidos_pausados_hasta) > new Date();

  const pausar = (minutos: number) => {
    const hasta = new Date(Date.now() + minutos * 60000).toISOString();
    void actualizar({ pedidos_pausados_hasta: hasta }, `Pedidos pausados ${minutos} min`);
  };

  return (
    <Card>
      <CardHeader className="pb-3">
        <CardTitle className="text-lg">Pedidos en línea</CardTitle>
      </CardHeader>
      <CardContent className="space-y-5">
        {/* Switch maestro */}
        <div className="flex items-center justify-between">
          <div>
            <p className="font-semibold">Recibir pedidos en línea</p>
            <p className="text-sm text-muted-foreground">Apaga esto y la sucursal deja de aparecer disponible</p>
          </div>
          <Switch
            checked={sucursal.pedidos_en_linea_activos}
            disabled={guardando}
            onCheckedChange={(v) =>
              actualizar({ pedidos_en_linea_activos: v }, v ? "Pedidos en línea ACTIVADOS" : "Pedidos en línea APAGADOS")
            }
          />
        </div>

        {/* Pausa temporal */}
        <div>
          <p className="font-semibold mb-1">Pausa temporal (cocina saturada)</p>
          {pausada ? (
            <div className="flex items-center gap-3">
              <Badge variant="destructive" className="text-sm">
                Pausado hasta{" "}
                {new Date(sucursal.pedidos_pausados_hasta as string).toLocaleTimeString("es-MX", {
                  hour: "2-digit",
                  minute: "2-digit",
                })}
              </Badge>
              <Button
                variant="outline"
                className="gap-2 h-12"
                disabled={guardando}
                onClick={() => actualizar({ pedidos_pausados_hasta: null }, "Pedidos reanudados")}
              >
                <Play className="h-4 w-4" /> Reanudar ya
              </Button>
            </div>
          ) : (
            <div className="grid grid-cols-3 gap-2">
              {[15, 30, 60].map((min) => (
                <Button
                  key={min}
                  variant="outline"
                  className="h-12 gap-1 font-bold"
                  disabled={guardando || !sucursal.pedidos_en_linea_activos}
                  onClick={() => pausar(min)}
                >
                  <Pause className="h-4 w-4" /> {min} min
                </Button>
              ))}
            </div>
          )}
          <p className="text-xs text-muted-foreground mt-1">Se reactiva sola al terminar el tiempo.</p>
        </div>

        {/* Tiempo estimado */}
        <div className="flex items-center justify-between">
          <div>
            <p className="font-semibold">Tiempo estimado</p>
            <p className="text-sm text-muted-foreground">Lo que ve el cliente al ordenar</p>
          </div>
          <div className="flex items-center gap-2">
            <Button
              variant="outline"
              size="icon"
              className="h-11 w-11"
              disabled={guardando || sucursal.tiempo_estimado_min <= 10}
              onClick={() =>
                actualizar({ tiempo_estimado_min: sucursal.tiempo_estimado_min - 5 }, "Tiempo actualizado")
              }
            >
              <Minus className="h-4 w-4" />
            </Button>
            <span className="font-bold w-16 text-center">{sucursal.tiempo_estimado_min} min</span>
            <Button
              variant="outline"
              size="icon"
              className="h-11 w-11"
              disabled={guardando || sucursal.tiempo_estimado_min >= 120}
              onClick={() =>
                actualizar({ tiempo_estimado_min: sucursal.tiempo_estimado_min + 5 }, "Tiempo actualizado")
              }
            >
              <Plus className="h-4 w-4" />
            </Button>
          </div>
        </div>

        {/* Alcohol */}
        <div className="flex items-center justify-between">
          <div>
            <p className="font-semibold">Vender alcohol en línea</p>
            <p className="text-sm text-muted-foreground">
              Solo activar con permiso de venta para llevar/domicilio del municipio
            </p>
          </div>
          <Switch
            checked={sucursal.venta_alcohol_en_linea}
            disabled={guardando}
            onCheckedChange={(v) =>
              actualizar({ venta_alcohol_en_linea: v }, v ? "Alcohol visible en el menú" : "Alcohol oculto del menú")
            }
          />
        </div>
      </CardContent>
    </Card>
  );
}

// ============ Disponibilidad de items (agotados) ============
interface FilaDisponibilidad {
  variante_id: string;
  nombre_item: string;
  nombre_variante: string;
  precio: number;
  disponible: boolean;
}

function DisponibilidadItems({ sucursalId }: { sucursalId: string }) {
  const queryClient = useQueryClient();
  const [busqueda, setBusqueda] = useState("");

  const { data: filas, isLoading } = useQuery({
    queryKey: ["panel-disponibilidad", sucursalId],
    queryFn: async (): Promise<FilaDisponibilidad[]> => {
      const { data, error } = await db
        .from("menu_variante_sucursal")
        .select("variante_id, precio, disponible, menu_variantes(nombre, orden, menu_items(nombre, orden))")
        .eq("sucursal_id", sucursalId);
      if (error) throw error;
      interface Cruda {
        variante_id: string;
        precio: number;
        disponible: boolean;
        menu_variantes: { nombre: string; orden: number; menu_items: { nombre: string; orden: number } | null } | null;
      }
      return ((data ?? []) as unknown as Cruda[])
        .map((f) => ({
          variante_id: f.variante_id,
          nombre_item: f.menu_variantes?.menu_items?.nombre ?? "?",
          nombre_variante: f.menu_variantes?.nombre ?? "?",
          precio: Number(f.precio),
          disponible: f.disponible,
        }))
        .sort((a, b) => a.nombre_item.localeCompare(b.nombre_item, "es"));
    },
  });

  const filtradas = useMemo(() => {
    const q = busqueda.trim().toLowerCase();
    const lista = filas ?? [];
    if (!q) return lista;
    return lista.filter((f) => f.nombre_item.toLowerCase().includes(q));
  }, [filas, busqueda]);

  const alternar = async (fila: FilaDisponibilidad, disponible: boolean) => {
    const { error } = await db
      .from("menu_variante_sucursal")
      .update({ disponible })
      .eq("variante_id", fila.variante_id)
      .eq("sucursal_id", sucursalId);
    if (error) {
      toast.error(`No se pudo guardar: ${error.message}`);
      return;
    }
    toast.success(
      disponible
        ? `${fila.nombre_item} disponible otra vez`
        : `${fila.nombre_item} marcado como AGOTADO`
    );
    queryClient.invalidateQueries({ queryKey: ["panel-disponibilidad", sucursalId] });
  };

  return (
    <Card>
      <CardHeader className="pb-3">
        <CardTitle className="text-lg">Agotados de hoy</CardTitle>
        <p className="text-sm text-muted-foreground">
          ¿Se acabó algo? Búscalo y apágalo. Desaparece del menú del cliente al instante.
        </p>
      </CardHeader>
      <CardContent>
        <div className="relative mb-3">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
          <Input
            value={busqueda}
            onChange={(e) => setBusqueda(e.target.value)}
            placeholder="Buscar producto… ej. callo"
            className="pl-9 h-12 text-base"
          />
        </div>
        {isLoading ? (
          <div className="flex justify-center py-8">
            <Loader2 className="h-6 w-6 animate-spin text-primary" />
          </div>
        ) : (
          <div className="max-h-96 overflow-y-auto divide-y">
            {filtradas.map((fila) => (
              <div key={fila.variante_id} className="flex items-center justify-between gap-3 py-2.5">
                <div className="min-w-0">
                  <p className={`font-medium leading-tight ${!fila.disponible ? "text-destructive" : ""}`}>
                    {fila.nombre_item}
                    {fila.nombre_variante !== "Única" && (
                      <span className="text-muted-foreground font-normal"> · {fila.nombre_variante}</span>
                    )}
                  </p>
                  <p className="text-sm text-muted-foreground">
                    {dinero(fila.precio)}
                    {!fila.disponible && <span className="text-destructive font-semibold"> · AGOTADO</span>}
                  </p>
                </div>
                <Switch
                  checked={fila.disponible}
                  onCheckedChange={(v) => alternar(fila, v)}
                />
              </div>
            ))}
            {filtradas.length === 0 && (
              <p className="text-center text-muted-foreground py-6">Sin resultados.</p>
            )}
          </div>
        )}
      </CardContent>
    </Card>
  );
}

// ============ Zonas de reparto ============
function ZonasReparto({ sucursalId }: { sucursalId: string }) {
  const queryClient = useQueryClient();
  const [nueva, setNueva] = useState({ nombre: "", costo: "35", minimo: "0" });

  const { data: zonas, isLoading } = useQuery({
    queryKey: ["panel-zonas", sucursalId],
    queryFn: async (): Promise<ZonaReparto[]> => {
      const { data, error } = await db
        .from("zonas_reparto")
        .select("*")
        .eq("sucursal_id", sucursalId)
        .order("nombre");
      if (error) throw error;
      return (data ?? []) as ZonaReparto[];
    },
  });

  const recargar = () => queryClient.invalidateQueries({ queryKey: ["panel-zonas", sucursalId] });

  const guardarCampo = async (zona: ZonaReparto, cambios: Partial<ZonaReparto>) => {
    const { error } = await db.from("zonas_reparto").update(cambios).eq("id", zona.id);
    if (error) toast.error(`No se pudo guardar: ${error.message}`);
    else recargar();
  };

  const eliminar = async (zona: ZonaReparto) => {
    if (!window.confirm(`¿Eliminar la zona "${zona.nombre}"?`)) return;
    const { error } = await db.from("zonas_reparto").delete().eq("id", zona.id);
    if (error) toast.error(`No se pudo eliminar (puede tener pedidos): ${error.message}`);
    else {
      toast.success("Zona eliminada");
      recargar();
    }
  };

  const agregar = async () => {
    if (nueva.nombre.trim().length < 2) {
      toast.error("Escribe el nombre de la zona");
      return;
    }
    const { error } = await db.from("zonas_reparto").insert({
      sucursal_id: sucursalId,
      nombre: nueva.nombre.trim(),
      costo_envio: Number(nueva.costo) || 0,
      pedido_minimo: Number(nueva.minimo) || 0,
      activa: true,
    });
    if (error) toast.error(`No se pudo agregar: ${error.message}`);
    else {
      toast.success("Zona agregada");
      setNueva({ nombre: "", costo: "35", minimo: "0" });
      recargar();
    }
  };

  return (
    <Card>
      <CardHeader className="pb-3">
        <CardTitle className="text-lg">Zonas de reparto</CardTitle>
        <p className="text-sm text-muted-foreground">
          El cliente solo puede pedir reparto a zonas activas.
        </p>
      </CardHeader>
      <CardContent className="space-y-3">
        {isLoading ? (
          <div className="flex justify-center py-6">
            <Loader2 className="h-6 w-6 animate-spin text-primary" />
          </div>
        ) : (
          (zonas ?? []).map((zona) => (
            <div key={zona.id} className="rounded-lg border p-3 space-y-2">
              <div className="flex items-center justify-between gap-2">
                <Input
                  defaultValue={zona.nombre}
                  className="h-11 text-base font-medium"
                  onBlur={(e) => {
                    const v = e.target.value.trim();
                    if (v && v !== zona.nombre) void guardarCampo(zona, { nombre: v });
                  }}
                />
                <Switch
                  checked={zona.activa}
                  onCheckedChange={(v) => guardarCampo(zona, { activa: v })}
                />
                <Button
                  variant="ghost"
                  size="icon"
                  className="text-destructive shrink-0"
                  onClick={() => eliminar(zona)}
                  aria-label="Eliminar zona"
                >
                  <Trash2 className="h-4 w-4" />
                </Button>
              </div>
              <div className="grid grid-cols-2 gap-2">
                <div>
                  <p className="text-xs text-muted-foreground mb-1">Costo de envío ($)</p>
                  <Input
                    type="number"
                    inputMode="decimal"
                    defaultValue={String(zona.costo_envio)}
                    className="h-11 text-base"
                    onBlur={(e) => {
                      const v = Number(e.target.value);
                      if (!Number.isNaN(v) && v !== Number(zona.costo_envio))
                        void guardarCampo(zona, { costo_envio: v });
                    }}
                  />
                </div>
                <div>
                  <p className="text-xs text-muted-foreground mb-1">Pedido mínimo ($)</p>
                  <Input
                    type="number"
                    inputMode="decimal"
                    defaultValue={String(zona.pedido_minimo)}
                    className="h-11 text-base"
                    onBlur={(e) => {
                      const v = Number(e.target.value);
                      if (!Number.isNaN(v) && v !== Number(zona.pedido_minimo))
                        void guardarCampo(zona, { pedido_minimo: v });
                    }}
                  />
                </div>
              </div>
            </div>
          ))
        )}

        {/* Agregar zona */}
        <div className="rounded-lg border border-dashed p-3 space-y-2">
          <p className="font-semibold text-sm">Agregar zona</p>
          <Input
            value={nueva.nombre}
            onChange={(e) => setNueva((n) => ({ ...n, nombre: e.target.value }))}
            placeholder="Nombre, ej. Col. Versalles"
            className="h-11 text-base"
          />
          <div className="grid grid-cols-2 gap-2">
            <Input
              type="number"
              inputMode="decimal"
              value={nueva.costo}
              onChange={(e) => setNueva((n) => ({ ...n, costo: e.target.value }))}
              placeholder="Costo envío"
              className="h-11 text-base"
            />
            <Input
              type="number"
              inputMode="decimal"
              value={nueva.minimo}
              onChange={(e) => setNueva((n) => ({ ...n, minimo: e.target.value }))}
              placeholder="Pedido mínimo"
              className="h-11 text-base"
            />
          </div>
          <Button className="w-full h-11 gap-2" onClick={agregar}>
            <Plus className="h-4 w-4" /> Agregar zona
          </Button>
        </div>
      </CardContent>
    </Card>
  );
}

// ============ Horarios ============
function HorariosSucursal({ sucursalId }: { sucursalId: string }) {
  const queryClient = useQueryClient();

  const { data: horarios, isLoading } = useQuery({
    queryKey: ["panel-horarios", sucursalId],
    queryFn: async (): Promise<HorarioSucursal[]> => {
      const { data, error } = await db
        .from("horarios_sucursal")
        .select("*")
        .eq("sucursal_id", sucursalId)
        .order("dia_semana")
        .order("hora_apertura");
      if (error) throw error;
      return (data ?? []) as HorarioSucursal[];
    },
  });

  const recargar = () => queryClient.invalidateQueries({ queryKey: ["panel-horarios", sucursalId] });

  const actualizar = async (horario: HorarioSucursal, cambios: Partial<HorarioSucursal>) => {
    const { error } = await db.from("horarios_sucursal").update(cambios).eq("id", horario.id);
    if (error) toast.error(`No se pudo guardar: ${error.message}`);
    else recargar();
  };

  const agregarRango = async (dia: number) => {
    const { error } = await db.from("horarios_sucursal").insert({
      sucursal_id: sucursalId,
      dia_semana: dia,
      hora_apertura: "11:00",
      hora_cierre: "21:00",
      activo: true,
    });
    if (error) toast.error(`No se pudo agregar: ${error.message}`);
    else recargar();
  };

  const eliminarRango = async (horario: HorarioSucursal) => {
    const { error } = await db.from("horarios_sucursal").delete().eq("id", horario.id);
    if (error) toast.error(`No se pudo eliminar: ${error.message}`);
    else recargar();
  };

  return (
    <Card>
      <CardHeader className="pb-3">
        <CardTitle className="text-lg">Horario de pedidos en línea</CardTitle>
        <p className="text-sm text-muted-foreground">
          Fuera de este horario el cliente ve la sucursal cerrada.
        </p>
      </CardHeader>
      <CardContent>
        {isLoading ? (
          <div className="flex justify-center py-6">
            <Loader2 className="h-6 w-6 animate-spin text-primary" />
          </div>
        ) : (
          <div className="space-y-3">
            {DIAS_SEMANA.map((nombreDia, dia) => {
              const rangos = (horarios ?? []).filter((h) => h.dia_semana === dia);
              return (
                <div key={dia} className="flex flex-wrap items-center gap-2 border-b pb-2 last:border-b-0">
                  <p className="font-semibold w-24 shrink-0">{nombreDia}</p>
                  {rangos.length === 0 && (
                    <span className="text-sm text-muted-foreground">Cerrado</span>
                  )}
                  {rangos.map((horario) => (
                    <div
                      key={horario.id}
                      className={`flex items-center gap-1.5 rounded-lg border p-1.5 ${!horario.activo ? "opacity-50" : ""}`}
                    >
                      <Input
                        type="time"
                        defaultValue={horaCorta(horario.hora_apertura)}
                        className="h-10 w-[6.5rem] text-base"
                        onBlur={(e) => {
                          if (e.target.value && e.target.value !== horaCorta(horario.hora_apertura))
                            void actualizar(horario, { hora_apertura: e.target.value });
                        }}
                      />
                      <span>–</span>
                      <Input
                        type="time"
                        defaultValue={horaCorta(horario.hora_cierre)}
                        className="h-10 w-[6.5rem] text-base"
                        onBlur={(e) => {
                          if (e.target.value && e.target.value !== horaCorta(horario.hora_cierre))
                            void actualizar(horario, { hora_cierre: e.target.value });
                        }}
                      />
                      <Switch
                        checked={horario.activo}
                        onCheckedChange={(v) => actualizar(horario, { activo: v })}
                      />
                      <Button
                        variant="ghost"
                        size="icon"
                        className="h-9 w-9 text-destructive"
                        onClick={() => eliminarRango(horario)}
                        aria-label="Eliminar rango"
                      >
                        <Trash2 className="h-4 w-4" />
                      </Button>
                    </div>
                  ))}
                  <Button
                    variant="ghost"
                    size="sm"
                    className="gap-1 text-primary"
                    onClick={() => agregarRango(dia)}
                  >
                    <Plus className="h-4 w-4" /> Rango
                  </Button>
                </div>
              );
            })}
          </div>
        )}
      </CardContent>
    </Card>
  );
}

// ============ Pestaña completa ============
export default function ConfiguracionPedidos({ sucursalId }: { sucursalId: string }) {
  const queryClient = useQueryClient();

  const { data: sucursal, isLoading } = useQuery({
    queryKey: ["panel-sucursal", sucursalId],
    queryFn: async (): Promise<SucursalEnLinea> => {
      const { data, error } = await db
        .from("sucursales")
        .select(
          "id, nombre, direccion, slug, telefono_contacto, pedidos_en_linea_activos, pedidos_pausados_hasta, venta_alcohol_en_linea, tiempo_estimado_min, prefijo_folio, zona_horaria"
        )
        .eq("id", sucursalId)
        .single();
      if (error) throw error;
      return data as SucursalEnLinea;
    },
  });

  if (isLoading || !sucursal) {
    return (
      <div className="flex justify-center py-16">
        <Loader2 className="h-8 w-8 animate-spin text-primary" />
      </div>
    );
  }

  return (
    <div className="space-y-4 max-w-2xl">
      <ControlesSucursal
        sucursal={sucursal}
        onRecargar={() => {
          queryClient.invalidateQueries({ queryKey: ["panel-sucursal", sucursalId] });
          queryClient.invalidateQueries({ queryKey: ["sucursales-en-linea"] });
        }}
      />
      <DisponibilidadItems sucursalId={sucursalId} />
      <ZonasReparto sucursalId={sucursalId} />
      <HorariosSucursal sucursalId={sucursalId} />
    </div>
  );
}
