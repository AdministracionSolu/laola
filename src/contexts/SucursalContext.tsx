import { createContext, useContext, useState, useCallback, ReactNode } from "react";

const LS_ID = "laola_sucursal_id";
const LS_NOMBRE = "laola_sucursal_nombre";
const LS_REGISTRADO_POR = "laola_registrado_por";
const LS_BLOQUEADA = "laola_sucursal_bloqueada";

interface SucursalContextValue {
  sucursalId: string | null;
  sucursalNombre: string | null;
  /** Fijada por liga/QR de sucursal: no se puede cambiar. */
  bloqueada: boolean;
  /** Nombre del encargado recordado en este dispositivo. */
  registradoPor: string;
  setSucursal: (id: string, nombre: string, bloqueada?: boolean) => void;
  setRegistradoPor: (nombre: string) => void;
  clearSucursal: () => void;
}

const SucursalContext = createContext<SucursalContextValue | null>(null);

export function SucursalProvider({ children }: { children: ReactNode }) {
  const [sucursalId, setSucursalId] = useState<string | null>(
    () => localStorage.getItem(LS_ID)
  );
  const [sucursalNombre, setSucursalNombre] = useState<string | null>(
    () => localStorage.getItem(LS_NOMBRE)
  );
  const [bloqueada, setBloqueada] = useState<boolean>(
    () => localStorage.getItem(LS_BLOQUEADA) === "1"
  );
  const [registradoPor, setRegistradoPorState] = useState<string>(
    () => localStorage.getItem(LS_REGISTRADO_POR) || ""
  );

  const setSucursal = useCallback((id: string, nombre: string, bloquear = false) => {
    localStorage.setItem(LS_ID, id);
    localStorage.setItem(LS_NOMBRE, nombre);
    if (bloquear) localStorage.setItem(LS_BLOQUEADA, "1");
    else localStorage.removeItem(LS_BLOQUEADA);
    setSucursalId(id);
    setSucursalNombre(nombre);
    setBloqueada(bloquear);
  }, []);

  const setRegistradoPor = useCallback((nombre: string) => {
    localStorage.setItem(LS_REGISTRADO_POR, nombre);
    setRegistradoPorState(nombre);
  }, []);

  const clearSucursal = useCallback(() => {
    localStorage.removeItem(LS_ID);
    localStorage.removeItem(LS_NOMBRE);
    localStorage.removeItem(LS_BLOQUEADA);
    setSucursalId(null);
    setSucursalNombre(null);
    setBloqueada(false);
  }, []);

  return (
    <SucursalContext.Provider
      value={{
        sucursalId,
        sucursalNombre,
        bloqueada,
        registradoPor,
        setSucursal,
        setRegistradoPor,
        clearSucursal,
      }}
    >
      {children}
    </SucursalContext.Provider>
  );
}

export function useSucursal() {
  const ctx = useContext(SucursalContext);
  if (!ctx) {
    throw new Error("useSucursal debe usarse dentro de <SucursalProvider>");
  }
  return ctx;
}
