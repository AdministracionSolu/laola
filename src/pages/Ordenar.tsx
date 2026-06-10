import { useEffect, useMemo, useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";
import { ArrowLeft, ChevronRight, Clock, Loader2, MapPin, Phone, Plus, RefreshCw, Search, ShoppingBag, X } from "lucide-react";
import { toast } from "sonner";
import logoLaOla from "@/assets/logo-la-ola.jpeg";
import {
  dinero,
  estadoSucursal,
  type EstadoSucursal,
  type SucursalEnLinea,
} from "@/lib/pedidosEnLinea";
import {
  useMenuSucursal,
  useSucursalesEnLinea,
  useZonasReparto,
  type CategoriaConItems,
  type ItemConVariantes,
} from "@/hooks/useMenuEnLinea";
import { useCarrito, leerCarritoGuardado } from "@/hooks/useCarrito";
import ItemSheet from "@/components/pedidos-en-linea/ItemSheet";
import { CarritoBar, CarritoSheet } from "@/components/pedidos-en-linea/CarritoSheet";
import Checkout from "@/components/pedidos-en-linea/Checkout";

// ---------- Selector de sucursal ----------
function SelectorSucursal({
  sucursales,
  estados,
}: {
  sucursales: SucursalEnLinea[];
  estados: Map<string, EstadoSucursal>;
}) {
  const navigate = useNavigate();
  const carritoGuardado = leerCarritoGuardado();
  const sucursalDelCarrito = carritoGuardado
    ? sucursales.find((s) => s.id === carritoGuardado.sucursalId)
    : null;

  return (
    <div className="min-h-screen bg-gradient-to-b from-primary/10 via-background to-background">
      <div className="max-w-lg mx-auto p-4">
        <div className="flex flex-col items-center text-center mb-5 pt-6">
          <div className="w-20 h-20 rounded-full overflow-hidden mb-3 ring-4 ring-primary/20 shadow-lg">
            <img src={logoLaOla} alt="La Ola" className="w-full h-full object-cover" />
          </div>
          <h1 className="text-3xl font-bold font-display text-primary">Ordena en línea</h1>
          <p className="text-muted-foreground">Elige tu sucursal para ver su menú</p>
        </div>

        {/* Pedido iniciado en otra visita */}
        {carritoGuardado && sucursalDelCarrito && (
          <button
            className="w-full mb-4 rounded-2xl bg-primary text-primary-foreground p-4 flex items-center gap-3 shadow-md active:scale-[0.99] transition-transform"
            onClick={() => navigate(`/ordenar/${sucursalDelCarrito.slug ?? sucursalDelCarrito.id}`)}
          >
            <ShoppingBag className="h-6 w-6 shrink-0" />
            <span className="text-left flex-1">
              <span className="block font-bold">Traes un pedido iniciado</span>
              <span className="block text-sm opacity-90">
                {carritoGuardado.lineas.reduce((a, l) => a + l.cantidad, 0)} items en {carritoGuardado.sucursalNombre} · continuar
              </span>
            </span>
            <ChevronRight className="h-5 w-5 shrink-0" />
          </button>
        )}

        <div className="grid gap-3 pb-8">
          {sucursales.map((s) => {
            const estado = estados.get(s.id);
            const abierta = estado?.abierta ?? false;
            return (
              <button
                key={s.id}
                disabled={!abierta}
                onClick={() => navigate(`/ordenar/${s.slug ?? s.id}`)}
                className={`text-left rounded-2xl border bg-card p-4 shadow-sm transition-all ${
                  abierta
                    ? "active:scale-[0.99] hover:border-primary hover:shadow-md"
                    : "opacity-60"
                }`}
              >
                <div className="flex items-center justify-between gap-2">
                  <h2 className="text-lg font-bold">{s.nombre}</h2>
                  <Badge
                    className={abierta ? "bg-green-600 hover:bg-green-600 shrink-0" : "shrink-0"}
                    variant={abierta ? "default" : "secondary"}
                  >
                    {abierta ? "Abierto" : "Cerrado"}
                  </Badge>
                </div>
                {s.direccion && (
                  <p className="text-sm text-muted-foreground flex items-start gap-1 mt-1">
                    <MapPin className="h-3.5 w-3.5 shrink-0 mt-0.5" /> {s.direccion}
                  </p>
                )}
                <div className="flex items-center justify-between mt-1.5">
                  {s.telefono_contacto ? (
                    <span className="text-sm text-primary flex items-center gap-1">
                      <Phone className="h-3.5 w-3.5 shrink-0" /> {s.telefono_contacto}
                    </span>
                  ) : (
                    <span />
                  )}
                  {abierta ? (
                    <span className="text-sm font-semibold text-primary flex items-center">
                      Ver menú <ChevronRight className="h-4 w-4" />
                    </span>
                  ) : (
                    <span className="text-xs text-muted-foreground flex items-center gap-1">
                      <Clock className="h-3 w-3" />
                      {estado?.motivo === "pausada"
                        ? `Reabre ${estado.detalle}`
                        : estado?.detalle
                          ? `Hoy: ${estado.detalle}`
                          : "No disponible"}
                    </span>
                  )}
                </div>
              </button>
            );
          })}
        </div>
      </div>
    </div>
  );
}

// ---------- Menú de la sucursal ----------
function MenuSucursal({ sucursal }: { sucursal: SucursalEnLinea }) {
  const navigate = useNavigate();
  const { data: categorias, isLoading, isError, refetch } = useMenuSucursal(sucursal);
  const { data: zonas } = useZonasReparto(sucursal.id);
  const carrito = useCarrito(sucursal.id);

  const [busqueda, setBusqueda] = useState("");
  const [categoriaActiva, setCategoriaActiva] = useState<string | null>(null);
  const [itemAbierto, setItemAbierto] = useState<ItemConVariantes | null>(null);
  const [verCarrito, setVerCarrito] = useState(false);
  const [enCheckout, setEnCheckout] = useState(false);

  // Mapa variante → precio en ESTA sucursal (para migrar carritos de otra sucursal)
  const preciosAqui = useMemo(() => {
    const mapa = new Map<string, number>();
    for (const cat of categorias ?? []) {
      for (const item of cat.items) {
        for (const v of item.variantes) mapa.set(v.id, v.precio);
      }
    }
    return mapa;
  }, [categorias]);

  // Primera categoría seleccionada por defecto
  useEffect(() => {
    if (!categoriaActiva && categorias && categorias.length > 0) {
      setCategoriaActiva(categorias[0].id);
    }
  }, [categorias, categoriaActiva]);

  const buscando = busqueda.trim().length > 0;
  const visibles: CategoriaConItems[] = useMemo(() => {
    if (!categorias) return [];
    if (buscando) {
      const q = busqueda.trim().toLowerCase();
      return categorias
        .map((c) => ({ ...c, items: c.items.filter((i) => i.nombre.toLowerCase().includes(q)) }))
        .filter((c) => c.items.length > 0);
    }
    return categorias.filter((c) => c.id === categoriaActiva);
  }, [categorias, buscando, busqueda, categoriaActiva]);

  const migrarPedido = () => {
    if (!carrito.ajeno) return;
    const origen = carrito.ajeno.sucursalNombre;
    const eliminadas = carrito.migrar(sucursal.id, sucursal.nombre, preciosAqui);
    if (eliminadas.length > 0) {
      toast.warning(
        `Se quitaron del pedido (no disponibles en ${sucursal.nombre}): ${eliminadas.join(", ")}`,
        { duration: 8000 }
      );
    } else {
      toast.success(`Tu pedido se pasó de ${origen} a ${sucursal.nombre} con precios de aquí`);
    }
  };

  if (enCheckout) {
    return (
      <Checkout
        sucursal={sucursal}
        lineas={carrito.lineas}
        subtotal={carrito.subtotal}
        zonas={zonas ?? []}
        onVolver={() => setEnCheckout(false)}
        onPedidoCreado={carrito.vaciar}
        onItemAgotado={(nombre) => {
          carrito.marcarAgotado(nombre);
          refetch();
        }}
      />
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-b from-primary/5 to-background pb-28">
      {/* Encabezado compacto */}
      <div className="max-w-lg mx-auto px-4 pt-3">
        <div className="flex items-center gap-2">
          <Button
            variant="ghost"
            size="icon"
            className="-ml-2 shrink-0"
            onClick={() => navigate("/ordenar")}
            aria-label="Elegir otra sucursal"
          >
            <ArrowLeft className="h-5 w-5" />
          </Button>
          <div className="flex-1 min-w-0">
            <p className="text-xs text-muted-foreground leading-none">Estás ordenando en</p>
            <h1 className="text-lg font-bold truncate">{sucursal.nombre}</h1>
          </div>
          <Button
            variant="outline"
            size="sm"
            className="rounded-full gap-1 shrink-0"
            onClick={() => navigate("/ordenar")}
          >
            <RefreshCw className="h-3.5 w-3.5" /> Cambiar
          </Button>
        </div>
        <p className="text-xs text-muted-foreground mt-1 ml-9">
          Listo en ~{sucursal.tiempo_estimado_min} min · Pagas al recoger o recibir
        </p>

        {/* Búsqueda */}
        <div className="relative mt-3">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
          <Input
            value={busqueda}
            onChange={(e) => setBusqueda(e.target.value)}
            placeholder="¿Qué se te antoja hoy?"
            className="pl-9 pr-9 h-11 text-base rounded-full bg-card shadow-sm"
          />
          {buscando && (
            <button
              className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground"
              onClick={() => setBusqueda("")}
              aria-label="Limpiar búsqueda"
            >
              <X className="h-4 w-4" />
            </button>
          )}
        </div>
      </div>

      {/* Pestañas de categorías (sticky) */}
      {!buscando && (
        <div className="sticky top-0 z-30 bg-background/95 backdrop-blur mt-3 border-b">
          <div className="max-w-lg mx-auto overflow-x-auto scrollbar-none">
            <div className="flex gap-2 px-4 py-2.5 w-max">
              {(categorias ?? []).map((c) => (
                <button
                  key={c.id}
                  onClick={() => {
                    setCategoriaActiva(c.id);
                    window.scrollTo({ top: 0, behavior: "smooth" });
                  }}
                  className={`whitespace-nowrap rounded-full px-4 py-2 text-sm font-semibold transition-colors ${
                    categoriaActiva === c.id
                      ? "bg-primary text-primary-foreground shadow"
                      : "bg-card border text-foreground/80"
                  }`}
                >
                  {c.nombre}
                </button>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* Items */}
      <div className="max-w-lg mx-auto px-4">
        {isLoading && (
          <div className="flex justify-center py-16">
            <Loader2 className="h-8 w-8 animate-spin text-primary" />
          </div>
        )}
        {isError && (
          <div className="text-center py-16 space-y-3">
            <p className="text-muted-foreground">No pudimos cargar el menú.</p>
            <Button onClick={() => refetch()}>Reintentar</Button>
            {sucursal.telefono_contacto && (
              <p className="text-sm text-muted-foreground">
                O llámanos al{" "}
                <a href={`tel:${sucursal.telefono_contacto}`} className="text-primary font-semibold">
                  {sucursal.telefono_contacto}
                </a>
              </p>
            )}
          </div>
        )}
        {!isLoading && !isError && visibles.length === 0 && (
          <p className="text-center text-muted-foreground py-16">
            {buscando ? "Sin resultados para tu búsqueda." : "El menú estará disponible pronto."}
          </p>
        )}

        {visibles.map((categoria) => (
          <section key={categoria.id} className="pt-4">
            <div className="flex items-baseline justify-between mb-2">
              <h2 className="text-xl font-bold font-display text-primary">{categoria.nombre}</h2>
              <span className="text-xs text-muted-foreground">
                {categoria.items.length} {categoria.items.length === 1 ? "platillo" : "platillos"}
              </span>
            </div>
            <div className="grid gap-2.5">
              {categoria.items.map((item) => (
                <button
                  key={item.id}
                  className="text-left rounded-2xl border bg-card p-4 shadow-sm active:scale-[0.99] hover:border-primary/60 transition-all"
                  onClick={() => setItemAbierto(item)}
                >
                  <div className="flex items-center justify-between gap-3">
                    <div className="min-w-0 flex-1">
                      <p className="font-semibold leading-snug">{item.nombre}</p>
                      {item.descripcion && (
                        <p className="text-sm text-muted-foreground line-clamp-2 mt-0.5">
                          {item.descripcion}
                        </p>
                      )}
                      <p className="font-bold text-accent mt-1.5">
                        {item.precioMin === item.precioMax
                          ? dinero(item.precioMin)
                          : `${dinero(item.precioMin)} – ${dinero(item.precioMax)}`}
                        {item.variantes.length > 1 && (
                          <span className="text-xs font-normal text-muted-foreground ml-1.5">
                            {item.variantes.length} tamaños
                          </span>
                        )}
                      </p>
                    </div>
                    <span className="h-10 w-10 rounded-full bg-primary text-primary-foreground flex items-center justify-center shrink-0 shadow">
                      <Plus className="h-5 w-5" />
                    </span>
                  </div>
                </button>
              ))}
            </div>
          </section>
        ))}
      </div>

      {/* Sheets y barra de carrito */}
      <ItemSheet
        item={itemAbierto}
        abierto={itemAbierto !== null}
        onCerrar={() => setItemAbierto(null)}
        onAgregar={(item, varianteId, cantidad, opciones, notas) => {
          const variante = item.variantes.find((v) => v.id === varianteId);
          if (!variante) return;
          carrito.agregar(sucursal.nombre, {
            variante_id: variante.id,
            item_id: item.id,
            nombre_item: item.nombre,
            nombre_variante: variante.nombre,
            precio: variante.precio,
            cantidad,
            opciones_elegidas: opciones,
            notas,
          });
        }}
      />
      <CarritoSheet
        abierto={verCarrito}
        onCerrar={() => setVerCarrito(false)}
        lineas={carrito.lineas}
        subtotal={carrito.subtotal}
        onCambiarCantidad={carrito.cambiarCantidad}
        onQuitar={carrito.quitar}
        onContinuar={() => {
          setVerCarrito(false);
          setEnCheckout(true);
          window.scrollTo({ top: 0 });
        }}
      />
      <CarritoBar
        numItems={carrito.numItems}
        subtotal={carrito.subtotal}
        onVerCarrito={() => setVerCarrito(true)}
      />

      {/* Llegó con un pedido de otra sucursal: migrarlo (re-preciado) o empezar de cero */}
      <AlertDialog open={carrito.ajeno !== null && !!categorias && categorias.length > 0}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>
              Traes un pedido de {carrito.ajeno?.sucursalNombre}
            </AlertDialogTitle>
            <AlertDialogDescription>
              ¿Quieres pasarlo a {sucursal.nombre}? No tienes que capturarlo otra vez: se
              actualiza con los precios de esta sucursal y, si algo no se vende aquí, te avisamos.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel onClick={carrito.vaciar}>Empezar de cero</AlertDialogCancel>
            <AlertDialogAction onClick={migrarPedido}>
              Pasar mi pedido aquí
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}

// ---------- Página ----------
export default function Ordenar() {
  const { slugSucursal } = useParams();
  const { data, isLoading, isError, refetch } = useSucursalesEnLinea();

  const estados = useMemo(() => {
    const mapa = new Map<string, EstadoSucursal>();
    if (data) {
      for (const s of data.sucursales) mapa.set(s.id, estadoSucursal(s, data.horarios));
    }
    return mapa;
  }, [data]);

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <Loader2 className="h-8 w-8 animate-spin text-primary" />
      </div>
    );
  }
  if (isError || !data) {
    return (
      <div className="min-h-screen flex flex-col items-center justify-center gap-3 p-4 text-center">
        <p className="text-muted-foreground">No pudimos cargar las sucursales.</p>
        <Button onClick={() => refetch()}>Reintentar</Button>
        <Link to="/" className="text-sm text-primary">Volver al inicio</Link>
      </div>
    );
  }

  const sucursal = slugSucursal
    ? data.sucursales.find((s) => s.slug === slugSucursal || s.id === slugSucursal)
    : null;

  if (slugSucursal && !sucursal) {
    return (
      <div className="min-h-screen flex flex-col items-center justify-center gap-3 p-4 text-center">
        <p className="text-muted-foreground">No encontramos esa sucursal.</p>
        <Link to="/ordenar" className="text-primary font-semibold">Ver sucursales</Link>
      </div>
    );
  }

  if (sucursal) {
    const estado = estados.get(sucursal.id);
    if (!estado?.abierta) {
      return (
        <div className="min-h-screen flex flex-col items-center justify-center gap-3 p-4 text-center">
          <h1 className="text-2xl font-bold">{sucursal.nombre}</h1>
          <p className="text-muted-foreground max-w-sm">
            {estado?.motivo === "pausada"
              ? `Estamos saturados por el momento. Volvemos a recibir pedidos a las ${estado.detalle}.`
              : estado?.motivo === "desactivado"
                ? "Esta sucursal no está recibiendo pedidos en línea por ahora."
                : estado?.detalle
                  ? `Cerrado en este momento. Horario de hoy: ${estado.detalle}.`
                  : "Cerrado el día de hoy."}
          </p>
          {sucursal.telefono_contacto && (
            <a href={`tel:${sucursal.telefono_contacto}`} className="text-primary font-semibold flex items-center gap-2">
              <Phone className="h-4 w-4" /> Llámanos al {sucursal.telefono_contacto}
            </a>
          )}
          <Link to="/ordenar" className="text-sm text-primary mt-2">Ver otras sucursales</Link>
        </div>
      );
    }
    return <MenuSucursal sucursal={sucursal} />;
  }

  return <SelectorSucursal sucursales={data.sucursales} estados={estados} />;
}
