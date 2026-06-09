import { useCallback, useEffect, useState } from "react";
import type { LineaCarrito } from "@/lib/pedidosEnLinea";

const LS_CARRITO = "laola_carrito_en_linea";

export interface CarritoGuardado {
  sucursalId: string;
  sucursalNombre: string;
  lineas: LineaCarrito[];
}

function leerCarrito(): CarritoGuardado | null {
  try {
    const crudo = localStorage.getItem(LS_CARRITO);
    if (!crudo) return null;
    const carrito = JSON.parse(crudo) as CarritoGuardado;
    if (!carrito.sucursalId || !Array.isArray(carrito.lineas)) return null;
    return carrito;
  } catch {
    return null;
  }
}

/**
 * Carrito del cliente en localStorage, ligado a UNA sucursal
 * (los precios difieren entre sucursales).
 */
export function useCarrito(sucursalId: string | null) {
  const [carrito, setCarrito] = useState<CarritoGuardado | null>(leerCarrito);

  useEffect(() => {
    if (carrito) localStorage.setItem(LS_CARRITO, JSON.stringify(carrito));
    else localStorage.removeItem(LS_CARRITO);
  }, [carrito]);

  /** Carrito de OTRA sucursal: hay que confirmar y vaciar antes de agregar aquí. */
  const deOtraSucursal =
    carrito !== null && sucursalId !== null && carrito.sucursalId !== sucursalId && carrito.lineas.length > 0;

  const lineas = carrito && carrito.sucursalId === sucursalId ? carrito.lineas : [];
  const numItems = lineas.reduce((acc, l) => acc + l.cantidad, 0);
  const subtotal = lineas.reduce((acc, l) => acc + l.precio * l.cantidad, 0);

  const agregar = useCallback(
    (sucursalNombre: string, linea: Omit<LineaCarrito, "uid">) => {
      if (!sucursalId) return;
      setCarrito((previo) => {
        const base =
          previo && previo.sucursalId === sucursalId
            ? previo
            : { sucursalId, sucursalNombre, lineas: [] as LineaCarrito[] };
        // Misma variante + mismas opciones + mismas notas → suma cantidad
        const igual = base.lineas.find(
          (l) =>
            l.variante_id === linea.variante_id &&
            JSON.stringify(l.opciones_elegidas) === JSON.stringify(linea.opciones_elegidas) &&
            (l.notas || "") === (linea.notas || "")
        );
        if (igual) {
          return {
            ...base,
            lineas: base.lineas.map((l) =>
              l.uid === igual.uid ? { ...l, cantidad: l.cantidad + linea.cantidad } : l
            ),
          };
        }
        const uid = `${linea.variante_id}-${Date.now()}-${Math.random().toString(36).slice(2, 7)}`;
        return { ...base, lineas: [...base.lineas, { ...linea, uid }] };
      });
    },
    [sucursalId]
  );

  const cambiarCantidad = useCallback((uid: string, cantidad: number) => {
    setCarrito((previo) => {
      if (!previo) return previo;
      if (cantidad <= 0) {
        const lineasNuevas = previo.lineas.filter((l) => l.uid !== uid);
        return lineasNuevas.length === 0 ? null : { ...previo, lineas: lineasNuevas };
      }
      return {
        ...previo,
        lineas: previo.lineas.map((l) => (l.uid === uid ? { ...l, cantidad: Math.min(cantidad, 99) } : l)),
      };
    });
  }, []);

  const quitar = useCallback((uid: string) => {
    setCarrito((previo) => {
      if (!previo) return previo;
      const lineasNuevas = previo.lineas.filter((l) => l.uid !== uid);
      return lineasNuevas.length === 0 ? null : { ...previo, lineas: lineasNuevas };
    });
  }, []);

  const vaciar = useCallback(() => setCarrito(null), []);

  /** Marca como agotadas las líneas de un item que la RPC rechazó. */
  const marcarAgotado = useCallback((nombreItem: string) => {
    const limpio = nombreItem.replace(/\s*\(.+\)\s*$/, ""); // sin "(variante)"
    setCarrito((previo) => {
      if (!previo) return previo;
      return {
        ...previo,
        lineas: previo.lineas.map((l) =>
          l.nombre_item === limpio || l.nombre_item === nombreItem ? { ...l, agotado: true } : l
        ),
      };
    });
  }, []);

  return {
    lineas,
    numItems,
    subtotal,
    deOtraSucursal,
    agregar,
    cambiarCantidad,
    quitar,
    vaciar,
    marcarAgotado,
  };
}
