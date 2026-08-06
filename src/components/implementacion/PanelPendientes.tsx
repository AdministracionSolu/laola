import { useState } from "react";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Badge } from "@/components/ui/badge";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger, DialogFooter } from "@/components/ui/dialog";
import { Plus, Trash2 } from "lucide-react";
import { toast } from "sonner";
import { ESTADOS_PENDIENTE, PanelData, Pendiente, etiquetaFechaLarga } from "./tipos";

const ESTILO_ESTADO: Record<Pendiente["estado"], string> = {
  pendiente: "bg-amber-100 text-amber-800 border-amber-200",
  en_curso: "bg-sky-100 text-sky-800 border-sky-200",
  hecho: "bg-emerald-100 text-emerald-800 border-emerald-200",
  bloqueado: "bg-red-100 text-red-800 border-red-200",
};

const SIN_SUCURSAL = "__ninguna__";

/** La libreta de Alicia: lo que falta implementar y en qué semana debe quedar. */
export function PanelPendientes({
  data,
  guardar,
}: {
  data: PanelData;
  guardar: (args: Record<string, unknown>) => Promise<boolean>;
}) {
  const [abierto, setAbierto] = useState(false);
  const [titulo, setTitulo] = useState("");
  const [sucursalId, setSucursalId] = useState(SIN_SUCURSAL);
  const [area, setArea] = useState("");
  const [semana, setSemana] = useState("");
  const [responsable, setResponsable] = useState("");
  const [notas, setNotas] = useState("");
  const [guardando, setGuardando] = useState(false);

  const limpiar = () => {
    setTitulo("");
    setSucursalId(SIN_SUCURSAL);
    setArea("");
    setSemana("");
    setResponsable("");
    setNotas("");
  };

  const crear = async () => {
    if (!titulo.trim()) {
      toast.error("Ponle un título al pendiente");
      return;
    }
    setGuardando(true);
    const ok = await guardar({
      p_titulo: titulo.trim(),
      p_sucursal_id: sucursalId === SIN_SUCURSAL ? null : sucursalId,
      p_area: area.trim() || null,
      p_estado: "pendiente",
      p_semana: semana || null,
      p_responsable: responsable.trim() || null,
      p_notas: notas.trim() || null,
    });
    setGuardando(false);
    if (ok) {
      limpiar();
      setAbierto(false);
    }
  };

  const cambiarEstado = async (p: Pendiente, estado: string) => {
    await guardar({ p_id: p.id, p_estado: estado });
  };

  const borrar = async (p: Pendiente) => {
    await guardar({ p_id: p.id, p_borrar: true });
  };

  return (
    <Card>
      <CardHeader>
        <div className="flex flex-wrap items-start justify-between gap-4">
          <div>
            <CardTitle>Pendientes de implementación</CardTitle>
            <CardDescription>
              Lo que falta dejar montado, con la semana en que debe quedar.
            </CardDescription>
          </div>
          <Dialog open={abierto} onOpenChange={setAbierto}>
            <DialogTrigger asChild>
              <Button size="sm">
                <Plus className="h-4 w-4 mr-1" /> Agregar
              </Button>
            </DialogTrigger>
            <DialogContent>
              <DialogHeader>
                <DialogTitle>Nuevo pendiente</DialogTitle>
              </DialogHeader>
              <div className="space-y-3">
                <div>
                  <Label>Título</Label>
                  <Input
                    value={titulo}
                    onChange={(e) => setTitulo(e.target.value)}
                    placeholder="Horario de cajas"
                  />
                </div>
                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <Label>Sucursal</Label>
                    <Select value={sucursalId} onValueChange={setSucursalId}>
                      <SelectTrigger>
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value={SIN_SUCURSAL}>Todas / ninguna</SelectItem>
                        {data.sucursales.map((s) => (
                          <SelectItem key={s.id} value={s.id}>
                            {s.nombre}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>
                  <div>
                    <Label>Área</Label>
                    <Input value={area} onChange={(e) => setArea(e.target.value)} placeholder="cajas" />
                  </div>
                </div>
                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <Label>Semana objetivo</Label>
                    <Input type="date" value={semana} onChange={(e) => setSemana(e.target.value)} />
                  </div>
                  <div>
                    <Label>Responsable</Label>
                    <Input
                      value={responsable}
                      onChange={(e) => setResponsable(e.target.value)}
                      placeholder="Quién lo ejecuta"
                    />
                  </div>
                </div>
                <div>
                  <Label>Notas</Label>
                  <Textarea value={notas} onChange={(e) => setNotas(e.target.value)} rows={3} />
                </div>
              </div>
              <DialogFooter>
                <Button onClick={crear} disabled={guardando}>
                  Guardar
                </Button>
              </DialogFooter>
            </DialogContent>
          </Dialog>
        </div>
      </CardHeader>
      <CardContent className="space-y-3">
        {data.pendientes.length === 0 && (
          <p className="text-sm text-muted-foreground py-6 text-center">
            No hay pendientes registrados.
          </p>
        )}
        {data.pendientes.map((p) => (
          <div
            key={p.id}
            className="flex flex-wrap items-start justify-between gap-3 rounded-lg border p-3"
          >
            <div className="min-w-[240px] flex-1">
              <div className="flex flex-wrap items-center gap-2">
                <span className="font-medium">{p.titulo}</span>
                {p.sucursal && <Badge variant="secondary">{p.sucursal}</Badge>}
                {p.area && <Badge variant="outline">{p.area}</Badge>}
              </div>
              <div className="mt-1 text-xs text-muted-foreground">
                {p.semana_objetivo
                  ? `Semana del ${etiquetaFechaLarga(p.semana_objetivo)}`
                  : "Sin semana definida"}
                {p.responsable ? ` · ${p.responsable}` : ""}
              </div>
              {p.notas && <p className="mt-2 text-sm text-muted-foreground">{p.notas}</p>}
            </div>
            <div className="flex items-center gap-2">
              <Badge variant="outline" className={ESTILO_ESTADO[p.estado]}>
                {ESTADOS_PENDIENTE.find((e) => e.valor === p.estado)?.etiqueta ?? p.estado}
              </Badge>
              <Select value={p.estado} onValueChange={(v) => cambiarEstado(p, v)}>
                <SelectTrigger className="w-[140px] h-9">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {ESTADOS_PENDIENTE.map((e) => (
                    <SelectItem key={e.valor} value={e.valor}>
                      {e.etiqueta}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
              <Button variant="ghost" size="icon" onClick={() => borrar(p)} title="Borrar">
                <Trash2 className="h-4 w-4 text-muted-foreground" />
              </Button>
            </div>
          </div>
        ))}
      </CardContent>
    </Card>
  );
}
