import { useEffect, useMemo, useRef, useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
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
import { ArrowLeft, Clock, Loader2, MapPin, Phone, Search } from "lucide-react";
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
  type ItemConVariantes,
} from "@/hooks/useMenuEnLinea";
import { useCarrito } from "@/hooks/useCarrito";
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
  return (
    <div className="max-w-lg mx-auto p-4">
      <div className="flex flex-col items-center text-center mb-6 pt-4">
        <div className="w-20 h-20 rounded-full overflow-hidden mb-3">
          <img src={logoLaOla} alt="La Ola" className="w-full h-full object-cover" />
        </div>
        <h1 className="text-3xl font-bold font-display">Ordena en línea</h1>
        <p className="text-muted-foreground">Elige tu sucursal para ver su menú</p>
      </div>
      <div className="grid gap-3">
        {sucursales.map((s) => {
          const estado = estados.get(s.id);
          const abierta = estado?.abierta ?? false;
          return (
            <Card
              key={s.id}
              className={`transition-all ${abierta ? "cursor-pointer hover:border-primary hover:shadow-md" : "opacity-70"}`}
              onClick={() => abierta && navigate(`/ordenar/${s.slug ?? s.id}`)}
            >
              <CardContent className="p-4">
                <div className="flex items-start justify-between gap-2">
                  <div>
                    <h2 className="text-xl font-bold">{s.nombre}</h2>
                    {s.direccion && (
                      <p className="text-sm text-muted-foreground flex items-center gap-1 mt-0.5">
                        <MapPin className="h-3.5 w-3.5 shrink-0" /> {s.direccion}
                      </p>
                    )}
                    {s.telefono_contacto && (
                      <a
                        href={`tel:${s.telefono_contacto}`}
                        onClick={(e) => e.stopPropagation()}
                        className="text-sm text-primary flex items-center gap-1 mt-0.5"
                      >
                        <Phone className="h-3.5 w-3.5 shrink-0" /> {s.telefono_contacto}
                      </a>
                    )}
                  </div>
                  <Badge
                    className={abierta ? "bg-green-600 hover:bg-green-600" : ""}
                    variant={abierta ? "default" : "secondary"}
                  >
                    {abierta ? "Abierto" : "Cerrado"}
                  </Badge>
                </div>
                {!abierta && (
                  <p className="text-sm text-muted-foreground flex items-center gap-1 mt-2">
                    <Clock className="h-3.5 w-3.5 shrink-0" />
                    {estado?.motivo === "pausada"
                      ? `Pausado por el momento, reabre a las ${estado.detalle}`
                      : estado?.motivo === "desactivado"
                        ? "Pedidos en línea no disponibles"
                        : estado?.detalle
                          ? `Horario de hoy: ${estado.detalle}`
                          : "Cerrado hoy"}
                  </p>
                )}
              </CardContent>
            </Card>
          );
        })}
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
  const [itemAbierto, setItemAbierto] = useState<ItemConVariantes | null>(null);
  const [verCarrito, setVerCarrito] = useState(false);
  const [enCheckout, setEnCheckout] = useState(false);
  const [categoriaActiva, setCategoriaActiva] = useState<string>("");
  const [confirmarCambio, setConfirmarCambio] = useState<ItemConVariantes | null>(null);
  const seccionesRef = useRef<Map<string, HTMLElement>>(new Map());

  const filtradas = useMemo(() => {
    if (!categorias) return [];
    const q = busqueda.trim().toLowerCase();
    if (!q) return categorias;
    return categorias
      .map((c) => ({ ...c, items: c.items.filter((i) => i.nombre.toLowerCase().includes(q)) }))
      .filter((c) => c.items.length > 0);
  }, [categorias, busqueda]);

  // Resalta la categoría visible al hacer scroll
  useEffect(() => {
    const observer = new IntersectionObserver(
      (entradas) => {
        const visible = entradas.find((e) => e.isIntersecting);
        if (visible) setCategoriaActiva(visible.target.id);
      },
      { rootMargin: "-120px 0px -70% 0px" }
    );
    seccionesRef.current.forEach((el) => observer.observe(el));
    return () => observer.disconnect();
  }, [filtradas]);

  const irACategoria = (id: string) => {
    setCategoriaActiva(id);
    seccionesRef.current.get(id)?.scrollIntoView({ behavior: "smooth", block: "start" });
  };

  const abrirItem = (item: ItemConVariantes) => {
    if (carrito.deOtraSucursal) {
      setConfirmarCambio(item);
    } else {
      setItemAbierto(item);
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
    <div className="pb-28">
      {/* Encabezado */}
      <div className="max-w-lg mx-auto px-4 pt-4">
        <Button variant="ghost" className="gap-2 -ml-2" onClick={() => navigate("/ordenar")}>
          <ArrowLeft className="h-4 w-4" /> Sucursales
        </Button>
        <h1 className="text-2xl font-bold mt-1">{sucursal.nombre}</h1>
        <p className="text-sm text-muted-foreground mb-3">
          Listo en aprox. {sucursal.tiempo_estimado_min} min · Pagas al recoger o recibir
        </p>
        <div className="relative mb-3">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
          <Input
            value={busqueda}
            onChange={(e) => setBusqueda(e.target.value)}
            placeholder="Buscar en el menú…"
            className="pl-9 h-11 text-base"
          />
        </div>
      </div>

      {/* Barra de categorías sticky */}
      <div className="sticky top-0 z-30 bg-background/95 backdrop-blur border-b">
        <div className="max-w-lg mx-auto overflow-x-auto scrollbar-none">
          <div className="flex gap-2 px-4 py-2 w-max">
            {filtradas.map((c) => (
              <Button
                key={c.id}
                size="sm"
                variant={categoriaActiva === c.id ? "default" : "outline"}
                className="rounded-full whitespace-nowrap"
                onClick={() => irACategoria(c.id)}
              >
                {c.nombre}
              </Button>
            ))}
          </div>
        </div>
      </div>

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
        {!isLoading && !isError && filtradas.length === 0 && (
          <p className="text-center text-muted-foreground py-16">
            {busqueda ? "Sin resultados para tu búsqueda." : "El menú estará disponible pronto."}
          </p>
        )}
        {filtradas.map((categoria) => (
          <section
            key={categoria.id}
            id={categoria.id}
            ref={(el) => {
              if (el) seccionesRef.current.set(categoria.id, el);
              else seccionesRef.current.delete(categoria.id);
            }}
            className="scroll-mt-16 pt-5"
          >
            <h2 className="text-lg font-bold font-display text-primary mb-2">{categoria.nombre}</h2>
            <div className="grid gap-2">
              {categoria.items.map((item) => (
                <button
                  key={item.id}
                  className="text-left rounded-lg border p-3 hover:border-primary hover:bg-primary/5 transition-colors"
                  onClick={() => abrirItem(item)}
                >
                  <div className="flex items-start justify-between gap-3">
                    <div className="min-w-0">
                      <p className="font-semibold leading-tight">{item.nombre}</p>
                      {item.descripcion && (
                        <p className="text-sm text-muted-foreground line-clamp-2 mt-0.5">
                          {item.descripcion}
                        </p>
                      )}
                    </div>
                    <p className="font-bold text-primary whitespace-nowrap">
                      {item.precioMin === item.precioMax
                        ? dinero(item.precioMin)
                        : `${dinero(item.precioMin)} – ${dinero(item.precioMax)}`}
                    </p>
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

      {/* Cambio de sucursal con carrito de otra sucursal */}
      <AlertDialog open={confirmarCambio !== null} onOpenChange={(v) => !v && setConfirmarCambio(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>¿Empezar pedido en {sucursal.nombre}?</AlertDialogTitle>
            <AlertDialogDescription>
              Tienes un carrito iniciado en otra sucursal. Los menús y precios son diferentes,
              así que ese carrito se vaciará.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Conservar carrito</AlertDialogCancel>
            <AlertDialogAction
              onClick={() => {
                const item = confirmarCambio;
                carrito.vaciar();
                setConfirmarCambio(null);
                if (item) setItemAbierto(item);
              }}
            >
              Vaciar y continuar
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
