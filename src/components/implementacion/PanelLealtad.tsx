// Pestaña "Lealtad" del Portal de Implementación.
//
// Es el programa de lealtad completo, de SOLO LECTURA: niveles con su
// color, reglas, rejilla de altas/visitas/canjes por sucursal, la
// conciliación de canjes, la actividad reciente, las anomalías y el
// padrón. Canjear, editar reglas y dar de baja siguen en /admin/lealtad.
//
// La forma la define panel_implementacion_lealtad() en
// supabase/migrations/20260810120000_lealtad_v5_niveles_ciclo.sql
import { useEffect, useState } from "react";
import { supabase } from "@/integrations/supabase/client";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import {
  AlertTriangle,
  Clock,
  Gift,
  Loader2,
  Store,
  Ticket,
  Trophy,
  Users,
} from "lucide-react";
import { textoSobre, recompensaDeCiclo } from "@/lib/lealtad";
import { etiquetaDia, etiquetaFechaLarga } from "./tipos";

const rpc = (fn: string, args: Record<string, unknown>) =>
  (supabase.rpc as unknown as (
    f: string,
    a: Record<string, unknown>
  ) => Promise<{ data: unknown; error: { message: string } | null }>)(fn, args);

type NivelFila = {
  posicion: number;
  nombre: string;
  color: string;
  beneficio: string | null;
  activo: boolean;
};

type LealtadData = {
  ok: true;
  hoy: string;
  desde: string;
  hasta: string;
  anio: number;
  dias: string[];
  reglas: { meta_visitas: number; tope_visitas_dia: number; recompensas_ciclo: number };
  niveles: NivelFila[];
  ciclo: { posicion: number; titulo: string; activo: boolean }[];
  resumen: {
    clientes: number;
    bajas: number;
    altas_periodo: number;
    altas_hoy: number;
    con_cumple: number;
    visitas_periodo: number;
    visitas_anio: number;
    canjes_periodo: number;
    recompensas_pendientes: number;
    bienvenidas_pendientes: number;
  };
  sucursales: {
    sucursal_id: string;
    nombre: string;
    clientes: number;
    dias: { fecha: string; altas: number; visitas: number; canjes: number }[];
  }[];
  canjes: { sucursal: string; posicion: number; titulo: string; n: number }[];
  actividad: {
    cliente: string;
    telefono: string;
    sucursal: string;
    folio: string | null;
    fecha: string;
    hora: string;
  }[];
  anomalias: {
    tope_repetido: { cliente: string; telefono: string; n: number }[];
    multi_sucursal: { cliente: string; fecha: string; sucursales: string }[];
    folios: { telefono: string; folio: string | null; motivo: string; sucursal: string; fecha: string }[];
  };
  clientes: {
    nombre: string;
    telefono: string;
    sucursal: string;
    activo: boolean;
    visitas_total: number;
    visitas_anio: number;
    canjes_anio: number;
    bienvenida_pendiente: boolean;
    disponibles: number;
    nivel_posicion: number | null;
    sellos: number;
    ultima_visita: string | null;
  }[];
};

const MOTIVOS: Record<string, string> = {
  folio_usado: "otro teléfono quiso reusar el folio",
  folio_repetido: "ticket repetido",
  folio_invalido: "folio inventado",
};

export function PanelLealtad({
  pin,
  desde,
  hasta,
}: {
  pin: string;
  desde: string;
  hasta: string;
}) {
  const [data, setData] = useState<LealtadData | null>(null);
  const [cargando, setCargando] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let vivo = true;
    setCargando(true);
    rpc("panel_implementacion_lealtad", { p_pin: pin, p_desde: desde, p_hasta: hasta }).then(
      ({ data: res, error: err }) => {
        if (!vivo) return;
        setCargando(false);
        const payload = res as LealtadData | { ok: false; error: string } | null;
        if (err || !payload || payload.ok !== true) {
          setError(
            err
              ? "El programa de lealtad todavía no está instalado en la base de datos"
              : "Tu acceso ya no es válido"
          );
          return;
        }
        setError(null);
        setData(payload);
      }
    );
    return () => {
      vivo = false;
    };
  }, [pin, desde, hasta]);

  if (cargando && !data) {
    return (
      <div className="flex justify-center py-16">
        <Loader2 className="h-6 w-6 animate-spin text-muted-foreground" />
      </div>
    );
  }

  if (error) {
    return (
      <Card>
        <CardContent className="py-10 text-center text-sm text-muted-foreground">
          {error}
        </CardContent>
      </Card>
    );
  }

  if (!data) return null;

  const chip = (posicion: number | null, nombre: string, color: string) => (
    <span
      className="inline-block px-2 py-0.5 rounded-full border text-xs font-bold whitespace-nowrap"
      style={{ backgroundColor: color, color: textoSobre(color), borderColor: "rgba(0,0,0,.2)" }}
      title={posicion === 0 ? "Solo una vez de por vida" : `Parada ${posicion} del ciclo`}
    >
      {nombre}
    </span>
  );

  const nivelPorPosicion = (posicion: number | null): NivelFila | undefined =>
    data.niveles.find((n) => n.posicion === posicion);

  return (
    <div className="space-y-6">
      {/* ---- Números del programa ---- */}
      <div className="grid gap-3 grid-cols-2 lg:grid-cols-4">
        <Dato icono={<Users className="h-3.5 w-3.5" />} titulo="Miembros activos" valor={data.resumen.clientes} leyenda={`${data.resumen.bajas} de baja`} />
        <Dato icono={<Users className="h-3.5 w-3.5" />} titulo="Altas de la semana" valor={data.resumen.altas_periodo} leyenda={`${data.resumen.altas_hoy} hoy`} />
        <Dato icono={<Ticket className="h-3.5 w-3.5" />} titulo="Visitas de la semana" valor={data.resumen.visitas_periodo} leyenda={`${data.resumen.visitas_anio} en ${data.anio}`} />
        <Dato icono={<Gift className="h-3.5 w-3.5" />} titulo="Canjes de la semana" valor={data.resumen.canjes_periodo} leyenda={`${data.resumen.recompensas_pendientes} recompensas por entregar`} />
      </div>

      {/* ---- Niveles: la tabla que se le enseña al piso ---- */}
      <Card>
        <CardHeader className="pb-3">
          <CardTitle className="text-base flex items-center gap-2">
            <Trophy className="h-4 w-4" /> Niveles y colores
          </CardTitle>
          <p className="text-xs text-muted-foreground">
            Cada {data.reglas.meta_visitas} visitas se libera una recompensa. Al
            llegar a la última, el ciclo vuelve a arrancar. La Recompensa
            inicial es una sola vez de por vida.
          </p>
        </CardHeader>
        <CardContent className="space-y-2">
          {data.niveles.map((n) => (
            <div key={n.posicion} className="flex flex-wrap items-center gap-3 border-b pb-2 last:border-0">
              <div className="w-32 shrink-0">{chip(n.posicion, n.nombre, n.color)}</div>
              <span className="text-sm flex-1 min-w-[180px]">{n.beneficio ?? "—"}</span>
              <span className="text-xs text-muted-foreground">
                {n.posicion === 0 ? "al inscribirse" : `visita ${n.posicion * data.reglas.meta_visitas} del ciclo`}
              </span>
            </div>
          ))}
          <p className="text-xs text-muted-foreground pt-1">
            Regla dura: un folio por teléfono por día ({data.reglas.tope_visitas_dia} visita
            por día). Las visitas y las recompensas cuentan por año natural: el 1 de
            enero todos arrancan de cero.
          </p>
        </CardContent>
      </Card>

      {/* ---- Rejilla por sucursal × día ---- */}
      <Card>
        <CardHeader className="pb-3">
          <CardTitle className="text-base flex items-center gap-2">
            <Store className="h-4 w-4" /> Movimiento por sucursal
          </CardTitle>
          <p className="text-xs text-muted-foreground">
            Altas / visitas / canjes por día. Una sucursal en ceros toda la
            semana es un QR que no se está pidiendo en la mesa.
          </p>
        </CardHeader>
        <CardContent className="p-0">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="bg-muted/50 text-left">
                <tr>
                  <th className="px-3 py-2 font-semibold">Sucursal</th>
                  {data.dias.map((d) => (
                    <th key={d} className="px-2 py-2 font-semibold text-center whitespace-nowrap">
                      {etiquetaDia(d)}
                    </th>
                  ))}
                  <th className="px-3 py-2 font-semibold text-right">Miembros</th>
                </tr>
              </thead>
              <tbody>
                {data.sucursales.map((s) => (
                  <tr key={s.sucursal_id} className="border-t">
                    <td className="px-3 py-2 font-medium whitespace-nowrap">{s.nombre}</td>
                    {s.dias.map((d) => {
                      const vacio = d.altas + d.visitas + d.canjes === 0;
                      return (
                        <td
                          key={d.fecha}
                          className={`px-2 py-2 text-center tabular-nums text-xs ${
                            vacio ? "text-muted-foreground/40" : ""
                          } ${d.fecha >= data.hoy ? "bg-muted/30" : ""}`}
                          title={`${d.altas} altas · ${d.visitas} visitas · ${d.canjes} canjes`}
                        >
                          {vacio ? "—" : (
                            <span>
                              <b>{d.visitas}</b>
                              <span className="text-muted-foreground">/{d.altas}/{d.canjes}</span>
                            </span>
                          )}
                        </td>
                      );
                    })}
                    <td className="px-3 py-2 text-right tabular-nums font-semibold">{s.clientes}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          <p className="px-3 py-2 text-[11px] text-muted-foreground">
            Cada celda: <b>visitas</b>/altas/canjes. El día en curso va sombreado.
          </p>
        </CardContent>
      </Card>

      {/* ---- Conciliación de canjes ---- */}
      <Card>
        <CardHeader className="pb-3">
          <CardTitle className="text-base flex items-center gap-2">
            <Ticket className="h-4 w-4" /> Conciliación de canjes
          </CardTitle>
          <p className="text-xs text-muted-foreground">
            Beneficios canjeados en sistema del {etiquetaFechaLarga(data.desde)} al{" "}
            {etiquetaFechaLarga(data.hasta)}. Empátalo contra las cortesías del
            comandero: si el comandero trae más, se están entregando beneficios de más.
          </p>
        </CardHeader>
        <CardContent>
          {data.canjes.length === 0 ? (
            <p className="text-sm text-muted-foreground">Sin canjes en la semana.</p>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead className="bg-muted/50 text-left">
                  <tr>
                    <th className="px-3 py-2 font-semibold">Sucursal</th>
                    <th className="px-3 py-2 font-semibold">Nivel</th>
                    <th className="px-3 py-2 font-semibold">Beneficio</th>
                    <th className="px-3 py-2 font-semibold text-right">Canjes</th>
                  </tr>
                </thead>
                <tbody>
                  {data.canjes.map((c, i) => {
                    const niv = nivelPorPosicion(c.posicion);
                    const rec = recompensaDeCiclo(c.posicion);
                    return (
                      <tr key={`${c.sucursal}-${c.titulo}-${i}`} className="border-t">
                        <td className="px-3 py-2">{c.sucursal}</td>
                        <td className="px-3 py-2">
                          {chip(
                            c.posicion,
                            niv?.nombre ?? rec?.identificador ?? "Recompensa inicial",
                            niv?.color ?? rec?.hex ?? "#94a3b8"
                          )}
                        </td>
                        <td className="px-3 py-2">{c.titulo}</td>
                        <td className="px-3 py-2 text-right tabular-nums font-semibold">{c.n}</td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          )}
        </CardContent>
      </Card>

      {/* ---- Anomalías ---- */}
      <Card>
        <CardHeader className="pb-3">
          <CardTitle className="text-base flex items-center gap-2">
            <AlertTriangle className="h-4 w-4" /> Anomalías de la semana
          </CardTitle>
          <p className="text-xs text-muted-foreground">
            Señales de abuso: números rotando folios, cuentas compartidas entre
            sucursales y tickets reutilizados o inventados.
          </p>
        </CardHeader>
        <CardContent className="space-y-4">
          <div>
            <p className="text-sm font-semibold mb-1">Teléfonos topando el límite diario (3+ intentos)</p>
            {data.anomalias.tope_repetido.length === 0 ? (
              <p className="text-sm text-muted-foreground">Sin casos.</p>
            ) : (
              <div className="flex flex-wrap gap-2">
                {data.anomalias.tope_repetido.map((t) => (
                  <Badge key={t.telefono} variant="destructive" className="text-sm py-1.5 px-3">
                    {t.cliente} · {t.telefono} · {t.n} intentos
                  </Badge>
                ))}
              </div>
            )}
          </div>
          <div>
            <p className="text-sm font-semibold mb-1">Mismo miembro en 2+ sucursales el mismo día</p>
            {data.anomalias.multi_sucursal.length === 0 ? (
              <p className="text-sm text-muted-foreground">Sin casos.</p>
            ) : (
              <div className="space-y-1">
                {data.anomalias.multi_sucursal.map((m, i) => (
                  <p key={`${m.cliente}-${m.fecha}-${i}`} className="text-sm">
                    <span className="font-medium">{m.cliente}</span>
                    <span className="text-muted-foreground"> · {m.fecha} · {m.sucursales}</span>
                  </p>
                ))}
              </div>
            )}
          </div>
          <div>
            <p className="text-sm font-semibold mb-1">Folios rechazados</p>
            {data.anomalias.folios.length === 0 ? (
              <p className="text-sm text-muted-foreground">Sin casos.</p>
            ) : (
              <div className="max-h-56 overflow-y-auto divide-y">
                {data.anomalias.folios.map((f, i) => (
                  <div key={`${f.telefono}-${f.folio}-${i}`} className="flex items-center justify-between py-1.5 text-sm gap-3">
                    <span>
                      folio <b>{f.folio ?? "—"}</b> · {f.telefono} ·{" "}
                      <span className="text-muted-foreground">{MOTIVOS[f.motivo] ?? f.motivo}</span>
                    </span>
                    <span className="text-muted-foreground text-xs whitespace-nowrap">
                      {f.sucursal} · {f.fecha}
                    </span>
                  </div>
                ))}
              </div>
            )}
          </div>
        </CardContent>
      </Card>

      {/* ---- Actividad reciente ---- */}
      <Card>
        <CardHeader className="pb-3">
          <CardTitle className="text-base flex items-center gap-2">
            <Clock className="h-4 w-4" /> Actividad de la semana
          </CardTitle>
          <p className="text-xs text-muted-foreground">
            Últimas visitas registradas con su folio. Sirve para ver a qué hora
            del servicio se está pidiendo el QR.
          </p>
        </CardHeader>
        <CardContent className="p-0">
          <div className="max-h-80 overflow-y-auto divide-y">
            {data.actividad.length === 0 ? (
              <p className="p-4 text-sm text-muted-foreground">Sin visitas en la semana.</p>
            ) : (
              data.actividad.map((a, i) => (
                <div key={`${a.fecha}-${a.hora}-${i}`} className="flex items-center justify-between px-4 py-2 text-sm gap-3">
                  <div className="min-w-0">
                    <span className="font-medium">{a.cliente}</span>
                    <span className="text-muted-foreground tabular-nums"> · {a.telefono}</span>
                  </div>
                  <div className="text-muted-foreground text-xs text-right whitespace-nowrap">
                    {a.sucursal}
                    {a.folio ? <> · folio <b>{a.folio}</b></> : null} · {etiquetaDia(a.fecha)} {a.hora}
                  </div>
                </div>
              ))
            )}
          </div>
        </CardContent>
      </Card>

      {/* ---- Padrón ---- */}
      <Card>
        <CardHeader className="pb-3">
          <CardTitle className="text-base flex items-center gap-2">
            <Users className="h-4 w-4" /> Padrón ({data.anio})
          </CardTitle>
          <p className="text-xs text-muted-foreground">
            Los 150 miembros más activos del año. Los teléfonos van
            enmascarados: este panel es para supervisar la operación, no para
            contactar clientes.
          </p>
        </CardHeader>
        <CardContent className="p-0">
          <div className="max-h-[28rem] overflow-y-auto">
            <table className="w-full text-sm">
              <thead className="bg-muted/50 text-left sticky top-0">
                <tr>
                  <th className="px-3 py-2 font-semibold">Miembro</th>
                  <th className="px-3 py-2 font-semibold">Teléfono</th>
                  <th className="px-3 py-2 font-semibold">Nivel</th>
                  <th className="px-3 py-2 font-semibold text-center">Sellos</th>
                  <th className="px-3 py-2 font-semibold text-right">Visitas {data.anio}</th>
                  <th className="px-3 py-2 font-semibold text-right">Por canjear</th>
                  <th className="px-3 py-2 font-semibold">Última visita</th>
                </tr>
              </thead>
              <tbody>
                {data.clientes.map((c, i) => {
                  const niv = nivelPorPosicion(c.nivel_posicion);
                  const rec = recompensaDeCiclo(c.nivel_posicion);
                  return (
                    <tr key={`${c.telefono}-${i}`} className={`border-t ${c.activo ? "" : "opacity-50"}`}>
                      <td className="px-3 py-2 font-medium">{c.nombre}</td>
                      <td className="px-3 py-2 tabular-nums text-muted-foreground">{c.telefono}</td>
                      <td className="px-3 py-2">
                        {chip(
                          c.nivel_posicion,
                          niv?.nombre ?? rec?.identificador ?? "Recompensa inicial",
                          niv?.color ?? rec?.hex ?? "#94a3b8"
                        )}
                      </td>
                      <td className="px-3 py-2 text-center tabular-nums">
                        {c.sellos}/{data.reglas.meta_visitas}
                      </td>
                      <td className="px-3 py-2 text-right tabular-nums font-semibold">{c.visitas_anio}</td>
                      <td className="px-3 py-2 text-right tabular-nums">
                        {c.disponibles > 0 ? (
                          <Badge className="bg-amber-500 hover:bg-amber-500">{c.disponibles}</Badge>
                        ) : (
                          <span className="text-muted-foreground">—</span>
                        )}
                      </td>
                      <td className="px-3 py-2 text-muted-foreground">{c.ultima_visita ?? "—"}</td>
                    </tr>
                  );
                })}
                {data.clientes.length === 0 && (
                  <tr>
                    <td colSpan={7} className="px-3 py-10 text-center text-muted-foreground">
                      Todavía no hay miembros registrados.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </CardContent>
      </Card>

      <p className="text-xs text-muted-foreground">
        {data.resumen.bienvenidas_pendientes} miembros no han canjeado su
        Recompensa inicial · {data.resumen.con_cumple} con cumpleaños
        registrado · Makatea manda los mensajes con esta misma lista.
      </p>
    </div>
  );
}

function Dato({
  icono,
  titulo,
  valor,
  leyenda,
}: {
  icono: React.ReactNode;
  titulo: string;
  valor: number;
  leyenda: string;
}) {
  return (
    <Card>
      <CardContent className="p-4">
        <div className="flex items-center gap-1.5 text-xs text-muted-foreground">
          {icono} {titulo}
        </div>
        <p className="text-2xl font-bold tabular-nums mt-1">{valor}</p>
        <p className="text-[11px] text-muted-foreground">{leyenda}</p>
      </CardContent>
    </Card>
  );
}
