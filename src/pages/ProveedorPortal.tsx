import { useEffect, useState, useCallback } from "react";
import { useParams } from "react-router-dom";
import { supabase } from "@/integrations/supabase/client";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { Loader2, Save, Tag, CheckCircle2 } from "lucide-react";
import { toast } from "sonner";
import { format } from "date-fns";
import { es } from "date-fns/locale";
import logoLaOla from "@/assets/logo-la-ola.jpeg";

interface Producto {
  id: string;
  nombre: string;
  unidad: string;
  por_gramaje: boolean;
  precio_vigente: number | null;
  precio_fecha: string | null;
  gramajes: { gramaje: string | null; precio: number }[] | null;
}
interface Catalogo {
  proveedor: { nombre: string; categoria: string | null };
  productos: Producto[];
}

interface GramajeRow { gramaje: string; precio: string; }
const GRAMAJE_ROWS = 4;
const filasVacias = (): GramajeRow[] =>
  Array.from({ length: GRAMAJE_ROWS }, () => ({ gramaje: "", precio: "" }));

const rpc = (fn: string, args: Record<string, unknown>) =>
  (supabase.rpc as unknown as (f: string, a: Record<string, unknown>) => Promise<{ data: unknown; error: unknown }>)(fn, args);

export default function ProveedorPortal() {
  const { token = "" } = useParams();
  const [loading, setLoading] = useState(true);
  const [catalogo, setCatalogo] = useState<Catalogo | null>(null);
  const [valido, setValido] = useState(true);
  // Precios normales (arrancan en blanco).
  const [precios, setPrecios] = useState<Record<string, string>>({});
  // Filas de gramaje por producto por-gramaje (4 filas, en blanco).
  const [gramajes, setGramajes] = useState<Record<string, GramajeRow[]>>({});
  const [guardando, setGuardando] = useState(false);
  // Pantalla de éxito con lo que quedó guardado, y lista de lo que falló.
  const [exito, setExito] = useState<{ nombre: string; detalle: string }[] | null>(null);
  const [fallidos, setFallidos] = useState<string[]>([]);

  const cargar = useCallback(async () => {
    setLoading(true);
    const { data, error } = await rpc("prov_catalogo", { p_token: token });
    if (error || !data) {
      setValido(false);
      setCatalogo(null);
    } else {
      setValido(true);
      const c = data as Catalogo;
      setCatalogo(c);
      // Inicializa 4 filas vacías para cada producto por gramaje.
      const g: Record<string, GramajeRow[]> = {};
      c.productos.forEach((p) => { if (p.por_gramaje) g[p.id] = filasVacias(); });
      setGramajes(g);
    }
    setLoading(false);
  }, [token]);

  useEffect(() => { cargar(); }, [cargar]);

  const setGramajeCell = (prodId: string, i: number, campo: keyof GramajeRow, valor: string) => {
    setGramajes((prev) => {
      const filas = (prev[prodId] ?? filasVacias()).map((f, idx) => (idx === i ? { ...f, [campo]: valor } : f));
      return { ...prev, [prodId]: filas };
    });
  };

  // ¿Un producto por-gramaje tiene al menos una fila con precio válido?
  const gramajeCapturado = (prodId: string) =>
    (gramajes[prodId] ?? []).some((f) => {
      const v = parseFloat(f.precio);
      return !isNaN(v) && v > 0;
    });

  // Corre un RPC y reintenta UNA vez si falla (señal débil de celular).
  const conReintento = async (run: () => Promise<{ data: unknown; error: unknown }>) => {
    const r1 = await run();
    if (!r1.error && r1.data !== false) return true;
    const r2 = await run();
    return !r2.error && r2.data !== false;
  };

  const guardarTodo = async () => {
    if (!catalogo) return;
    const nombreDe = (id: string) => catalogo.productos.find((p) => p.id === id)?.nombre ?? "";
    const unidadDe = (id: string) => catalogo.productos.find((p) => p.id === id)?.unidad ?? "";
    const normales = catalogo.productos.filter((p) => !p.por_gramaje);
    const porGramaje = catalogo.productos.filter((p) => p.por_gramaje);

    const itemsNormales = normales
      .map((p) => ({ id: p.id, valor: parseFloat(precios[p.id] ?? "") }))
      .filter((x) => !isNaN(x.valor) && x.valor > 0);
    const itemsGramaje = porGramaje
      .map((p) => ({
        id: p.id,
        filas: (gramajes[p.id] ?? [])
          .map((f) => ({ gramaje: f.gramaje.trim(), precio: f.precio.trim() }))
          .filter((f) => { const v = parseFloat(f.precio); return !isNaN(v) && v > 0; }),
      }))
      .filter((x) => x.filas.length > 0);

    if (itemsNormales.length === 0 && itemsGramaje.length === 0) {
      toast.error("Pon al menos un precio");
      return;
    }

    // Una tarea por producto, con cómo limpiar su campo si se guardó bien.
    type Tarea = {
      id: string;
      nombre: string;
      detalle: string;
      run: () => Promise<{ data: unknown; error: unknown }>;
      limpiar: () => void;
    };
    const tareas: Tarea[] = [
      ...itemsNormales.map((it) => ({
        id: it.id,
        nombre: nombreDe(it.id),
        detalle: `$${it.valor}/${unidadDe(it.id)}`,
        run: () => rpc("prov_set_precio", { p_token: token, p_producto_id: it.id, p_precio: it.valor }),
        limpiar: () => setPrecios((prev) => { const n = { ...prev }; delete n[it.id]; return n; }),
      })),
      ...itemsGramaje.map((it) => ({
        id: it.id,
        nombre: nombreDe(it.id),
        detalle: it.filas.map((f) => `${f.gramaje || "s/g"} $${f.precio}`).join(" · "),
        run: () => rpc("prov_set_camaron", { p_token: token, p_producto_id: it.id, p_items: it.filas }),
        limpiar: () => setGramajes((prev) => ({ ...prev, [it.id]: filasVacias() })),
      })),
    ];

    setGuardando(true);
    setFallidos([]);
    // En lotes chicos (no 10+ llamadas de golpe en señal de celular).
    const resultados: { tarea: Tarea; ok: boolean }[] = [];
    for (let i = 0; i < tareas.length; i += 3) {
      const lote = tareas.slice(i, i + 3);
      const oks = await Promise.all(lote.map((t) => conReintento(t.run)));
      lote.forEach((t, j) => resultados.push({ tarea: t, ok: oks[j] }));
    }
    setGuardando(false);

    const bien = resultados.filter((r) => r.ok);
    const mal = resultados.filter((r) => !r.ok);
    bien.forEach((r) => r.tarea.limpiar());

    if (mal.length === 0) {
      setExito(bien.map((r) => ({ nombre: r.tarea.nombre, detalle: r.tarea.detalle })));
    } else {
      // Los que fallaron conservan su campo lleno; aviso fijo (no solo toast).
      setFallidos(mal.map((r) => r.tarea.nombre));
      toast.error(
        `Se guardaron ${bien.length} de ${tareas.length}. Falta: ${mal
          .map((r) => r.tarea.nombre)
          .join(", ")}. Dale Guardar otra vez.`
      );
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <Loader2 className="h-8 w-8 animate-spin text-primary" />
      </div>
    );
  }

  if (!valido || !catalogo) {
    return (
      <div className="min-h-screen flex items-center justify-center p-4 bg-gradient-to-br from-primary/5 to-secondary/10">
        <Card className="max-w-sm w-full">
          <CardContent className="p-8 text-center space-y-2">
            <Tag className="h-10 w-10 mx-auto text-muted-foreground/40" />
            <p className="font-semibold">Liga no válida</p>
            <p className="text-sm text-muted-foreground">
              Esta liga de proveedor no existe o fue desactivada. Pide una nueva al
              restaurante.
            </p>
          </CardContent>
        </Card>
      </div>
    );
  }

  const capturados =
    catalogo.productos.filter((p) => !p.por_gramaje && !isNaN(parseFloat(precios[p.id] ?? "")) && parseFloat(precios[p.id] ?? "") > 0).length +
    catalogo.productos.filter((p) => p.por_gramaje && gramajeCapturado(p.id)).length;

  const hoy = format(new Date(), "EEEE d 'de' MMMM", { locale: es });
  const hoyCap = hoy.charAt(0).toUpperCase() + hoy.slice(1);

  // ---- Pantalla de éxito: lo que quedó guardado, confirmado ----
  if (exito) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-primary/5 to-secondary/10 flex items-center justify-center p-4">
        <div className="max-w-sm w-full space-y-4">
          <div className="text-center space-y-2">
            <div className="inline-flex items-center justify-center w-24 h-24 rounded-full bg-emerald-100 text-emerald-600">
              <CheckCircle2 className="h-14 w-14" />
            </div>
            <h1 className="text-2xl font-bold">¡Precios guardados!</h1>
            <p className="text-sm text-muted-foreground">
              Gracias, {catalogo.proveedor.nombre} · {hoyCap}
            </p>
          </div>
          <Card>
            <CardContent className="p-4">
              <p className="text-sm font-semibold mb-2">
                Quedaron registrados {exito.length} producto{exito.length === 1 ? "" : "s"}:
              </p>
              <div className="divide-y">
                {exito.map((r) => (
                  <div key={r.nombre} className="flex items-center justify-between gap-2 py-2">
                    <span className="text-sm">{r.nombre}</span>
                    <span className="font-semibold text-sm text-right">{r.detalle}</span>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
          <Button
            variant="outline"
            className="w-full h-12 text-base"
            onClick={() => { setExito(null); cargar(); }}
          >
            Capturar otro precio
          </Button>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-primary/5 to-secondary/10 pb-28">
      {/* Encabezado personalizado */}
      <div className="bg-background border-b sticky top-0 z-10">
        <div className="container mx-auto px-3 py-3 flex items-center gap-3 max-w-2xl">
          <img src={logoLaOla} alt="La Ola" className="w-10 h-10 rounded-full object-cover shrink-0" />
          <div className="flex-1 min-w-0">
            <h1 className="text-base font-semibold leading-tight truncate">
              Hola, {catalogo.proveedor.nombre}
            </h1>
            <p className="text-xs text-muted-foreground">
              Precios para La Ola · {hoyCap}
            </p>
          </div>
          <Badge variant="secondary" className="shrink-0">
            {capturados}/{catalogo.productos.length}
          </Badge>
        </div>
      </div>

      <div className="container mx-auto px-3 py-3 max-w-2xl space-y-3">
        <p className="text-sm text-muted-foreground px-1">
          Escribe el precio de <b>hoy</b> de cada producto y dale Guardar. Toma menos de 1 minuto.
        </p>

        {fallidos.length > 0 && (
          <Card className="border-destructive/50 bg-destructive/5">
            <CardContent className="p-4 text-sm">
              <p className="font-semibold text-destructive">
                Estos precios NO se guardaron: {fallidos.join(", ")}.
              </p>
              <p className="text-muted-foreground mt-1">
                Siguen capturados abajo. Revisa tu señal y vuelve a dar Guardar.
              </p>
            </CardContent>
          </Card>
        )}

        {catalogo.productos.length === 0 ? (
          <Card>
            <CardContent className="p-6 text-center text-sm text-muted-foreground">
              Aún no tienes productos asignados. El restaurante los configura.
            </CardContent>
          </Card>
        ) : (
          <>
            {/* Productos normales (un precio) */}
            {catalogo.productos.some((p) => !p.por_gramaje) && (
              <Card>
                <CardContent className="p-0 divide-y">
                  {catalogo.productos.filter((p) => !p.por_gramaje).map((p) => {
                    const lleno = !isNaN(parseFloat(precios[p.id] ?? ""));
                    return (
                      <div key={p.id} className="flex items-center gap-3 px-3 py-3">
                        <div className="flex-1 min-w-0">
                          <div className="flex items-center gap-1.5">
                            {lleno ? (
                              <CheckCircle2 className="h-4 w-4 text-emerald-500 shrink-0" />
                            ) : (
                              <span className="h-4 w-4 shrink-0" />
                            )}
                            <span className="font-medium truncate">{p.nombre}</span>
                          </div>
                        </div>
                        <span className="text-muted-foreground text-sm">$</span>
                        <Input
                          type="number"
                          inputMode="decimal"
                          min="0"
                          placeholder="0"
                          value={precios[p.id] ?? ""}
                          onChange={(e) => setPrecios((prev) => ({ ...prev, [p.id]: e.target.value }))}
                          className="h-12 w-24 text-center text-base font-semibold"
                        />
                        <span className="text-xs text-muted-foreground w-10 shrink-0">/{p.unidad}</span>
                      </div>
                    );
                  })}
                </CardContent>
              </Card>
            )}

            {/* Productos por gramaje (ej. Camarón fresco): hasta 4 tallas */}
            {catalogo.productos.filter((p) => p.por_gramaje).map((p) => (
              <Card key={p.id}>
                <CardContent className="p-3 space-y-2">
                  <div className="flex items-center gap-1.5">
                    {gramajeCapturado(p.id) ? (
                      <CheckCircle2 className="h-4 w-4 text-emerald-500 shrink-0" />
                    ) : (
                      <span className="h-4 w-4 shrink-0" />
                    )}
                    <span className="font-medium">{p.nombre}</span>
                  </div>
                  <p className="text-xs text-muted-foreground">
                    Pon los gramajes que tengas hoy (hasta 4): de cuántos gramos y su precio.
                  </p>
                  <div className="space-y-2">
                    {(gramajes[p.id] ?? filasVacias()).map((fila, i) => (
                      <div key={i} className="flex items-center gap-2">
                        <Input
                          type="text"
                          placeholder="gramaje (ej. 19g)"
                          value={fila.gramaje}
                          onChange={(e) => setGramajeCell(p.id, i, "gramaje", e.target.value)}
                          className="h-11 flex-1 text-base"
                        />
                        <span className="text-muted-foreground text-sm">$</span>
                        <Input
                          type="number"
                          inputMode="decimal"
                          min="0"
                          placeholder="0"
                          value={fila.precio}
                          onChange={(e) => setGramajeCell(p.id, i, "precio", e.target.value)}
                          className="h-11 w-24 text-center text-base font-semibold"
                        />
                        <span className="text-xs text-muted-foreground w-8 shrink-0">/{p.unidad}</span>
                      </div>
                    ))}
                  </div>
                </CardContent>
              </Card>
            ))}
          </>
        )}
      </div>

      {/* Un solo botón: guarda TODO */}
      <div className="fixed bottom-0 inset-x-0 bg-background border-t z-20">
        <div className="container mx-auto px-3 py-3 max-w-2xl">
          <Button
            className="w-full h-14 text-lg gap-2"
            onClick={guardarTodo}
            disabled={guardando || capturados === 0}
          >
            {guardando ? <Loader2 className="h-5 w-5 animate-spin" /> : <Save className="h-5 w-5" />}
            Guardar precios de hoy ({capturados})
          </Button>
        </div>
      </div>
    </div>
  );
}
