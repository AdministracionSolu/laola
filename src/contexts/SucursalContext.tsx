import { createContext, useContext, useState, useCallback, ReactNode } from "react";

const LS_ID = "laola_sucursal_id";
const LS_NOMBRE = "laola_sucursal_nombre";
const LS_REGISTRADO_POR = "laola_registrado_por";

interface SucursalContextValue {
  sucursalId: string | null;
  sucursalNombre: string | null;
  /** Nombre del encargado recordado en este dispositivo. */
  registradoPor: string;
  setSucursal: (id: string, nombre: string) => void;
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
  const [registradoPor, setRegistradoPorState] = useState<string>(
    () => localStorage.getItem(LS_REGISTRADO_POR) || ""
  );

  const setSucursal = useCallback((id: string, nombre: string) => {
    localStorage.setItem(LS_ID, id);
    localStorage.setItem(LS_NOMBRE, nombre);
    setSucursalId(id);
    setSucursalNombre(nombre);
  }, []);

  const setRegistradoPor = useCallback((nombre: string) => {
    localStorage.setItem(LS_REGISTRADO_POR, nombre);
    setRegistradoPorState(nombre);
  }, []);

  const clearSucursal = useCallback(() => {
    localStorage.removeItem(LS_ID);
    localStorage.removeItem(LS_NOMBRE);
    setSucursalId(null);
    setSucursalNombre(null);
  }, []);

  return (
    <SucursalContext.Provider
      value={{
        sucursalId,
        sucursalNombre,
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
