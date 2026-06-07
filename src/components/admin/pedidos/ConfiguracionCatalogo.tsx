import { useEffect, useState, useCallback } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Checkbox } from "@/components/ui/checkbox";
import { Badge } from "@/components/ui/badge";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Plus, Loader2 } from "lucide-react";
import { supabase } from "@/integrations/supabase/client";
import { esProteina, infoProteina } from "@/lib/proteinas";
import { toast } from "sonner";

interface Categoria {
  id: string;
  nombre: string;
  orden: number;
}
interface Insumo {
  id: string;
  nombre: string;
  categoria_id: string;
  unidad: string | null;
  activo: boolean;
}
interface Sucursal {
  id: string;
  nombre: string;
}
interface Asignacion {
  id: string;
  insumo_id: string;
  sucursal_id: string;
  activo: boolean;
  nivel_par: number | null;
  costo: number | null;
  unidad: string | null;
  orden: number;
}

export function ConfiguracionCatalogo() {
  const [categorias, setCategorias] = useState<Categoria[]>([]);
  const [insumos, setInsumos] = useState<Insumo[]>([]);
  const [sucursales, setSucursales] = useState<Sucursal[]>([]);
  const [asignaciones, setAsignaciones] = useState<Asignacion[]>([]);
  const [sucursalSel, setSucursalSel] = useState<string>("");
  const [loading, setLoading] = useState(true);

  // Alta de insumo
  const [nuevoNombre, setNuevoNombre] = useState("");
  const [nuevaCategoria, setNuevaCategoria] = useState("");
  const [nuevaUnidad, setNuevaUnidad] = useState("kg");
  const [creando, setCreando] = useState(false);

  const fetchAll = useCallback(async () => {
    setLoading(true);
    const [catRes, insRes, sucRes, asgRes] = await Promise.all([
      supabase.from("categorias_insumos").select("*").order("orden"),
      supabase.from("insumos").select("*").order("nombre"),
      supabase.from("sucursales").select("id, nombre").order("nombre"),
      supabase.from("insumo_sucursal").select("*"),
    ]);
    if (catRes.data) setCategorias(catRes.data);
    if (insRes.data) setInsumos(insRes.data);
    if (sucRes.data) {
      setSucursales(sucRes.data);
      setSucursalSel((prev) => prev || sucRes.data[0]?.id || "");
    }
    if (asgRes.data) setAsignaciones(asgRes.data as Asignacion[]);
    setLoading(false);
  }, []);

  useEffect(() => {
    fetchAll();
  }, [fetchAll]);

  const asignacionDe = (insumoId: string) =>
    asignaciones.find(
      (a) => a.insumo_id === insumoId && a.sucursal_id === sucursalSel
    );

  const toggleAsignacion = async (insumo: Insumo, incluir: boolean) => {
    const existente = asignacionDe(insumo.id);
    if (existente) {
      const { error } = await supabase
        .from("insumo_sucursal")
        .update({ activo: incluir })
        .eq("id", existente.id);
      if (error) return toast.error("No se pudo actualizar");
      setAsignaciones((prev) =>
        prev.map((a) => (a.id === existente.id ? { ...a, activo: incluir } : a))
      );
    } else if (incluir) {
      const orden =
        Math.max(
          0,
          ...asignaciones
            .filter((a) => a.sucursal_id === sucursalSel)
            .map((a) => a.orden)
        ) + 1;
      const { data, error } = await supabase
        .from("insumo_sucursal")
        .insert({ insumo_id: insumo.id, sucursal_id: sucursalSel, activo: true, orden })
        .select()
        .single();
      if (error || !data) return toast.error("No se pudo asignar");
      setAsignaciones((prev) => [...prev, data as Asignacion]);
    }
  };

  const guardarCampo = async (
    asignacionId: string,
    campo: "nivel_par" | "costo" | "orden" | "unidad",
    valor: number | string | null
  ) => {
    const { error } = await supabase
      .from("insumo_sucursal")
      .update({ [campo]: valor })
      .eq("id", asignacionId);
    if (error) {
      toast.error("No se pudo guardar el cambio");
      return;
    }
    setAsignaciones((prev) =>
      prev.map((a) => (a.id === asignacionId ? { ...a, [campo]: valor } : a))
    );
  };

  const toggleActivoInsumo = async (insumo: Insumo) => {
    const { error } = await supabase
      .from("insumos")
      .update({ activo: !insumo.activo })
      .eq("id", insumo.id);
    if (error) return toast.error("No se pudo actualizar el insumo");
    setInsumos((prev) =>
      prev.map((i) => (i.id === insumo.id ? { ...i, activo: !i.activo } : i))
    );
  };

  const crearInsumo = async () => {
    if (!nuevoNombre.trim() || !nuevaCategoria) {
      toast.error("Nombre y categoría son obligatorios");
      return;
    }
    setCreando(true);
    const { data, error } = await supabase
      .from("insumos")
      .insert({
        nombre: nuevoNombre.trim(),
        categoria_id: nuevaCategoria,
        unidad: nuevaUnidad,
        activo: true,
      })
      .select()
      .single();
    setCreando(false);
    if (error || !data) {
      toast.error("No se pudo crear (¿nombre repetido?)");
      return;
    }
    setInsumos((prev) =>
      [...prev, data as Insumo].sort((a, b) => a.nombre.localeCompare(b.nombre))
    );
    setNuevoNombre("");
    toast.success("Insumo creado");
  };

  if (loading) {
    return (
      <div className="flex justify-center py-16">
        <Loader2 className="h-8 w-8 animate-spin text-primary" />
      </div>
    );
  }

  // Solo proteínas de la lista oficial (oculta el resto del catálogo).
  const insumosProteina = insumos.filter((i) => esProteina(i.nombre));
  const insumosActivos = insumosProteina.filter((i) => i.activo);
  const nombreInsumo = (i: Insumo) => infoProteina(i.nombre)?.display ?? i.nombre;

  return (
    <div className="space-y-4">
      {/* Alta de insumo */}
      <Card>
        <CardHeader className="pb-2">
          <CardTitle className="text-sm">Agregar insumo al catálogo</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid sm:grid-cols-4 gap-2 items-end">
            <div className="space-y-1 sm:col-span-2">
              <Label className="text-xs">Nombre</Label>
              <Input
                value={nuevoNombre}
                onChange={(e) => setNuevoNombre(e.target.value)}
                placeholder="Ej. Camarón U-15"
              />
            </div>
            <div className="space-y-1">
              <Label className="text-xs">Categoría</Label>
              <Select value={nuevaCategoria} onValueChange={setNuevaCategoria}>
                <SelectTrigger>
                  <SelectValue placeholder="Categoría" />
                </SelectTrigger>
                <SelectContent>
                  {categorias.map((c) => (
                    <SelectItem key={c.id} value={c.id}>
                      {c.nombre}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-1">
              <Label className="text-xs">Unidad</Label>
              <Select value={nuevaUnidad} onValueChange={setNuevaUnidad}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {["kg", "pz", "bolsa", "caja"].map((u) => (
                    <SelectItem key={u} value={u}>
                      {u}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </div>
          <Button className="mt-3 gap-2" onClick={crearInsumo} disabled={creando}>
            {creando ? <Loader2 className="h-4 w-4 animate-spin" /> : <Plus className="h-4 w-4" />}
            Agregar
          </Button>
        </CardContent>
      </Card>

      {/* Asignación por sucursal */}
      <Card>
        <CardHeader className="pb-2">
          <CardTitle className="text-sm flex items-center justify-between gap-2">
            <span>Lista por sucursal</span>
            <Select value={sucursalSel} onValueChange={setSucursalSel}>
              <SelectTrigger className="w-40">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                {sucursales.map((s) => (
                  <SelectItem key={s.id} value={s.id}>
                    {s.nombre}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </CardTitle>
        </CardHeader>
        <CardContent className="p-0">
          <div className="divide-y">
            {/* Encabezado */}
            <div className="hidden sm:grid grid-cols-12 gap-2 px-4 py-2 text-xs font-medium text-muted-foreground">
              <div className="col-span-1">Pide</div>
              <div className="col-span-4">Insumo</div>
              <div className="col-span-2 text-center">Nivel par</div>
              <div className="col-span-2 text-center">Costo $</div>
              <div className="col-span-2 text-center">Unidad</div>
              <div className="col-span-1 text-center">Orden</div>
            </div>
            {insumosActivos.map((insumo) => {
              const asg = asignacionDe(insumo.id);
              const incluido = !!asg && asg.activo;
              return (
                <div
                  key={insumo.id}
                  className="grid grid-cols-12 gap-2 px-4 py-2 items-center"
                >
                  <div className="col-span-2 sm:col-span-1">
                    <Checkbox
                      checked={incluido}
                      onCheckedChange={(v) => toggleAsignacion(insumo, !!v)}
                    />
                  </div>
                  <div className="col-span-10 sm:col-span-4 text-sm">
                    {nombreInsumo(insumo)}
                    {!incluido && (
                      <span className="ml-2 text-xs text-muted-foreground">
                        (no pide)
                      </span>
                    )}
                  </div>
                  {incluido && asg ? (
                    <>
                      <div className="col-span-4 sm:col-span-2">
                        <Input
                          type="number"
                          inputMode="decimal"
                          defaultValue={asg.nivel_par ?? ""}
                          placeholder="par"
                          className="h-9 text-center"
                          onBlur={(e) =>
                            guardarCampo(
                              asg.id,
                              "nivel_par",
                              e.target.value === "" ? null : parseFloat(e.target.value)
                            )
                          }
                        />
                      </div>
                      <div className="col-span-4 sm:col-span-2">
                        <Input
                          type="number"
                          inputMode="decimal"
                          defaultValue={asg.costo ?? ""}
                          placeholder="costo"
                          className="h-9 text-center"
                          onBlur={(e) =>
                            guardarCampo(
                              asg.id,
                              "costo",
                              e.target.value === "" ? null : parseFloat(e.target.value)
                            )
                          }
                        />
                      </div>
                      <div className="col-span-2 sm:col-span-2">
                        <Input
                          defaultValue={asg.unidad ?? ""}
                          placeholder={insumo.unidad || "u"}
                          className="h-9 text-center"
                          onBlur={(e) =>
                            guardarCampo(
                              asg.id,
                              "unidad",
                              e.target.value.trim() === "" ? null : e.target.value.trim()
                            )
                          }
                        />
                      </div>
                      <div className="col-span-2 sm:col-span-1">
                        <Input
                          type="number"
                          defaultValue={asg.orden}
                          className="h-9 text-center"
                          onBlur={(e) =>
                            guardarCampo(asg.id, "orden", parseInt(e.target.value) || 0)
                          }
                        />
                      </div>
                    </>
                  ) : (
                    <div className="col-span-12 sm:col-span-7" />
                  )}
                </div>
              );
            })}
          </div>
        </CardContent>
      </Card>

      {/* ABM rápido: activar/desactivar insumos */}
      <Card>
        <CardHeader className="pb-2">
          <CardTitle className="text-sm">Insumos del catálogo</CardTitle>
        </CardHeader>
        <CardContent className="p-0">
          <div className="divide-y max-h-72 overflow-y-auto">
            {insumosProteina.map((insumo) => (
              <div
                key={insumo.id}
                className="flex items-center justify-between px-4 py-2"
              >
                <div className="text-sm">
                  {nombreInsumo(insumo)}{" "}
                  <Badge variant="outline" className="ml-1 text-xs">
                    {insumo.unidad}
                  </Badge>
                </div>
                <Button
                  variant={insumo.activo ? "ghost" : "outline"}
                  size="sm"
                  className="text-xs"
                  onClick={() => toggleActivoInsumo(insumo)}
                >
                  {insumo.activo ? "Activo" : "Inactivo"}
                </Button>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
