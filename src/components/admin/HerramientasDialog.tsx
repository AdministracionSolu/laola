import { useState } from "react";
import { useNavigate } from "react-router-dom";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Wrench, CalendarDays, Lock, ChevronRight, Package, QrCode, ShoppingCart, UtensilsCrossed } from "lucide-react";
import { useToast } from "@/hooks/use-toast";
import { ResumenAnual } from "./ResumenAnual";

// Accesos parkeados (fuera del bar principal en lo que se define su uso).
const ACCESOS = [
  { label: "Insumos & Pedidos", to: "/admin/pedidos", icon: Package },
  { label: "QR de pedidos", to: "/admin/qr-pedidos", icon: QrCode },
  { label: "Menús por sucursal", to: "/admin/menus", icon: UtensilsCrossed },
  { label: "Pedido del día", to: "/compras", icon: ShoppingCart },
];

// Contraseña de nivel administrador dueño (no visible para contadoras).
const CLAVE_HERRAMIENTAS = "Coctel Danilo";
const STORAGE_KEY = "laola_herramientas_ok";

export function HerramientasDialog() {
  const { toast } = useToast();
  const navigate = useNavigate();
  const [abierto, setAbierto] = useState(false);
  const [desbloqueado, setDesbloqueado] = useState(
    () => sessionStorage.getItem(STORAGE_KEY) === "1"
  );
  const [clave, setClave] = useState("");
  const [resumenAbierto, setResumenAbierto] = useState(false);

  const intentarDesbloquear = () => {
    if (clave.trim() === CLAVE_HERRAMIENTAS) {
      sessionStorage.setItem(STORAGE_KEY, "1");
      setDesbloqueado(true);
      setClave("");
    } else {
      toast({
        title: "Contraseña incorrecta",
        description: "Verifica la clave de herramientas.",
        variant: "destructive",
      });
      setClave("");
    }
  };

  return (
    <>
      <Button variant="outline" onClick={() => setAbierto(true)} className="gap-2">
        <Wrench className="w-4 h-4" />
        <span className="hidden sm:inline">Herramientas</span>
      </Button>

      {/* Menú de herramientas (con candado) */}
      <Dialog open={abierto} onOpenChange={setAbierto}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              <Wrench className="w-5 h-5" />
              Herramientas
            </DialogTitle>
            <DialogDescription>
              Accesos parkeados y reportes avanzados.
            </DialogDescription>
          </DialogHeader>

          {/* Accesos rápidos (sin candado) */}
          <div className="space-y-2">
            {ACCESOS.map(({ label, to, icon: Icon }) => (
              <button
                key={to}
                onClick={() => { setAbierto(false); navigate(to); }}
                className="w-full flex items-center justify-between rounded-lg border p-3 text-left hover:bg-accent transition-colors"
              >
                <span className="flex items-center gap-3">
                  <Icon className="w-4 h-4 text-muted-foreground" />
                  <span className="text-sm font-medium">{label}</span>
                </span>
                <ChevronRight className="w-4 h-4 text-muted-foreground" />
              </button>
            ))}
          </div>

          <div className="pt-2 mt-1 border-t">
            <p className="text-xs text-muted-foreground mb-2 flex items-center gap-1.5">
              <Lock className="w-3 h-3" /> Reportes del dueño
            </p>
          </div>

          {!desbloqueado ? (
            <div className="space-y-3">
              <Label htmlFor="clave-herramientas" className="flex items-center gap-2">
                <Lock className="w-4 h-4" />
                Contraseña de herramientas
              </Label>
              <div className="flex gap-2">
                <Input
                  id="clave-herramientas"
                  type="password"
                  placeholder="Ingresa la clave"
                  value={clave}
                  onChange={(e) => setClave(e.target.value)}
                  onKeyDown={(e) => {
                    if (e.key === "Enter") intentarDesbloquear();
                  }}
                  autoFocus
                />
                <Button onClick={intentarDesbloquear}>Entrar</Button>
              </div>
            </div>
          ) : (
            <div className="space-y-2">
              <button
                onClick={() => {
                  setAbierto(false);
                  setResumenAbierto(true);
                }}
                className="w-full flex items-center justify-between rounded-lg border p-4 text-left hover:bg-accent transition-colors"
              >
                <span className="flex items-center gap-3">
                  <CalendarDays className="w-5 h-5 text-primary" />
                  <span>
                    <span className="block font-medium">Resumen Anual</span>
                    <span className="block text-xs text-muted-foreground">
                      Comparativos por año, mes y patrones históricos
                    </span>
                  </span>
                </span>
                <ChevronRight className="w-4 h-4 text-muted-foreground" />
              </button>
            </div>
          )}
        </DialogContent>
      </Dialog>

      {/* Resumen Anual (pesado: solo se monta al abrir) */}
      <Dialog open={resumenAbierto} onOpenChange={setResumenAbierto}>
        <DialogContent className="max-w-[95vw] w-full h-[92vh] overflow-y-auto sm:max-w-6xl">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              <CalendarDays className="w-5 h-5" />
              Resumen Anual
            </DialogTitle>
            <DialogDescription>
              Datos históricos completos. Puede tardar unos segundos en cargar.
            </DialogDescription>
          </DialogHeader>
          {resumenAbierto && <ResumenAnual />}
        </DialogContent>
      </Dialog>
    </>
  );
}
