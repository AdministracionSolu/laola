import { useMemo, useState } from "react";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger, DialogFooter } from "@/components/ui/dialog";
import { Plus, Trash2 } from "lucide-react";
import { toast } from "sonner";
import { PROCESOS, PanelData } from "./tipos";

const SIN_SUCURSAL = "__ninguna__";

/**
 * El mapa: quién reporta qué en cada sucursal. Se llena a mano porque no vive
 * en ninguna tabla — es el acuerdo operativo, no un dato del sistema. Debajo de
 * cada casilla se muestran los nombres que de verdad aparecen capturando.
 */
export function PanelResponsables({
  data,
  guardar,
}: {
  data: PanelData;
  guardar: (args: Record<string, unknown>) => Promise<boolean>;
}) {
  const [abierto, setAbierto] = useState(false);
  const [sucursalId, setSucursalId] = useState(SIN_SUCURSAL);
  const [proceso, setProceso] = useState(PROCESOS[0].valor);
  const [persona, setPersona] = useState("");
  const [puesto, setPuesto] = useState("");
  const [telefono, setTelefono] = useState("");
  const [guardando, setGuardando] = useState(false);

  /** Quién aparece de verdad capturando, por sucursal (sale de los registros). */
  const observados = useMemo(() => {
    const mapa = new Map<string, { pedido: Set<string>; recepcion: Set<string> }>();
    for (const o of data.operacion) {
      const acc = { pedido: new Set<string>(), recepcion: new Set<string>() };
      for (const d of o.dias) {
        if (d.pedido?.registrado_por) acc.pedido.add(d.pedido.registrado_por.trim());
        for (const r of d.recepciones) if (r.registrado_por) acc.recepcion.add(r.registrado_por.trim());
      }
      mapa.set(o.sucursal_id, acc);
    }
    return mapa;
  }, [data.operacion]);

  const crear = async () => {
    if (!persona.trim()) {
      toast.error("Falta el nombre");
      return;
    }
    setGuardando(true);
    const ok = await guardar({
      p_sucursal_id: sucursalId === SIN_SUCURSAL ? null : sucursalId,
      p_proceso: proceso,
      p_persona: persona.trim(),
      p_puesto: puesto.trim() || null,
      p_telefono: telefono.trim() || null,
    });
    setGuardando(false);
    if (ok) {
      setPersona("");
      setPuesto("");
      setTelefono("");
      setAbierto(false);
    }
  };

  return (
    <div className="space-y-4">
      <Card>
        <CardHeader>
          <div className="flex flex-wrap items-start justify-between gap-4">
            <div>
              <CardTitle>Mapa de responsables</CardTitle>
              <CardDescription>
                Quién debe reportar cada cosa, por sucursal.
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
                  <DialogTitle>Nuevo responsable</DialogTitle>
                </DialogHeader>
                <div className="space-y-3">
                  <div className="grid grid-cols-2 gap-3">
                    <div>
                      <Label>Sucursal</Label>
                      <Select value={sucursalId} onValueChange={setSucursalId}>
                        <SelectTrigger>
                          <SelectValue />
                        </SelectTrigger>
                        <SelectContent>
                          <SelectItem value={SIN_SUCURSAL}>Todas</SelectItem>
                          {data.sucursales.map((s) => (
                            <SelectItem key={s.id} value={s.id}>
                              {s.nombre}
                            </SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                    </div>
                    <div>
                      <Label>Proceso</Label>
                      <Select value={proceso} onValueChange={setProceso}>
                        <SelectTrigger>
                          <SelectValue />
                        </SelectTrigger>
                        <SelectContent>
                          {PROCESOS.map((p) => (
                            <SelectItem key={p.valor} value={p.valor}>
                              {p.etiqueta}
                            </SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                    </div>
                  </div>
                  <div>
                    <Label>Persona</Label>
                    <Input value={persona} onChange={(e) => setPersona(e.target.value)} />
                  </div>
                  <div className="grid grid-cols-2 gap-3">
                    <div>
                      <Label>Puesto</Label>
                      <Input value={puesto} onChange={(e) => setPuesto(e.target.value)} />
                    </div>
                    <div>
                      <Label>Teléfono</Label>
                      <Input value={telefono} onChange={(e) => setTelefono(e.target.value)} />
                    </div>
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
        <CardContent>
          {data.responsables.length === 0 ? (
            <p className="text-sm text-muted-foreground py-6 text-center">
              Todavía no hay nadie asignado. Agrega quién reporta cada proceso para que el panel
              sepa a quién buscar cuando algo falte.
            </p>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Proceso</TableHead>
                  <TableHead>Sucursal</TableHead>
                  <TableHead>Persona</TableHead>
                  <TableHead>Contacto</TableHead>
                  <TableHead className="w-12" />
                </TableRow>
              </TableHeader>
              <TableBody>
                {data.responsables.map((r) => (
                  <TableRow key={r.id}>
                    <TableCell>
                      {PROCESOS.find((p) => p.valor === r.proceso)?.etiqueta ?? r.proceso}
                    </TableCell>
                    <TableCell>{r.sucursal ?? "Todas"}</TableCell>
                    <TableCell>
                      <div className="font-medium">{r.persona}</div>
                      {r.puesto && <div className="text-xs text-muted-foreground">{r.puesto}</div>}
                    </TableCell>
                    <TableCell className="text-sm text-muted-foreground">{r.telefono ?? "—"}</TableCell>
                    <TableCell>
                      <Button
                        variant="ghost"
                        size="icon"
                        onClick={() => guardar({ p_id: r.id, p_borrar: true })}
                        title="Quitar"
                      >
                        <Trash2 className="h-4 w-4 text-muted-foreground" />
                      </Button>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Quién está capturando de verdad</CardTitle>
          <CardDescription>
            Nombres que quedaron grabados en las capturas del periodo. Sirve para confirmar que
            quien reporta es quien debe reportar.
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Sucursal</TableHead>
                <TableHead>Pedidos / existencias</TableHead>
                <TableHead>Recepciones</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {data.operacion.map((o) => {
                const obs = observados.get(o.sucursal_id);
                const pedido = Array.from(obs?.pedido ?? []);
                const recep = Array.from(obs?.recepcion ?? []);
                return (
                  <TableRow key={o.sucursal_id}>
                    <TableCell className="font-medium">{o.nombre}</TableCell>
                    <TableCell>
                      {pedido.length === 0 ? (
                        <span className="text-sm text-muted-foreground">Nadie</span>
                      ) : (
                        <div className="flex flex-wrap gap-1">
                          {pedido.map((n) => (
                            <Badge key={n} variant="secondary" className="font-normal">
                              {n}
                            </Badge>
                          ))}
                        </div>
                      )}
                    </TableCell>
                    <TableCell>
                      {recep.length === 0 ? (
                        <span className="text-sm text-muted-foreground">Nadie</span>
                      ) : (
                        <div className="flex flex-wrap gap-1">
                          {recep.map((n) => (
                            <Badge key={n} variant="secondary" className="font-normal">
                              {n}
                            </Badge>
                          ))}
                        </div>
                      )}
                    </TableCell>
                  </TableRow>
                );
              })}
            </TableBody>
          </Table>
        </CardContent>
      </Card>
    </div>
  );
}
