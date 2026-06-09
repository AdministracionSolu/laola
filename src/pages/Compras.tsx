import { useEffect, useMemo, useState } from "react";
import { supabase } from "@/integrations/supabase/client";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { InputOTP, InputOTPGroup, InputOTPSlot } from "@/components/ui/input-otp";
import { Loader2, Grid3x3, ShoppingCart, Lock } from "lucide-react";
import { toast } from "sonner";
import { format, subDays } from "date-fns";
import logoLaOla from "@/assets/logo-la-ola.jpeg";
import { getFechaNegocio } from "@/lib/fecha";
import { useAnaliticaPedidos } from "@/hooks/useAnaliticaPedidos";
import { PedidoDelDiaPanel } from "@/components/admin/pedidos/PedidoDelDiaPanel";
import { DondeComprarPanel } from "@/components/admin/pedidos/DondeComprarPanel";

const rpc = (fn: string, args: Record<string, unknown>) =>
  (supabase.rpc as unknown as (f: string, a: Record<string, unknown>) => Promise<{ data: unknown; error: unknown }>)(fn, args);

const SS_PIN = "laola_compras_pin";

export default function Compras() {
  const [pin, setPin] = useState<string>(() => sessionStorage.getItem(SS_PIN) || "");
  const [ok, setOk] = useState<boolean>(() => !!sessionStorage.getItem(SS_PIN));
  const [intento, setIntento] = useState("");
  const [validando, setValidando] = useState(false);

  const validar = async (valor: string) => {
    setValidando(true);
    const { data } = await rpc("compras_validar_pin", { p_pin: valor });
    setValidando(false);
    if (data === true) {
      sessionStorage.setItem(SS_PIN, valor);
      setPin(valor);
      setOk(true);
    } else {
      toast.error("Código incorrecto");
      setIntento("");
    }
  };

  if (!ok) {
    return (
      <div className="min-h-screen flex items-center justify-center p-4 bg-gradient-to-br from-primary/5 to-secondary/10">
        <Card className="w-full max-w-sm">
          <CardContent className="p-6 text-center space-y-5">
            <div className="mx-auto w-16 h-16 rounded-full overflow-hidden">
              <img src={logoLaOla} alt="La Ola" className="w-full h-full object-cover" />
            </div>
            <div>
              <h1 className="text-xl font-bold flex items-center justify-center gap-2"><Lock className="h-5 w-5" /> Pedido del día</h1>
              <p className="text-sm text-muted-foreground">Ingresa el código de compras</p>
            </div>
            <div className="flex justify-center">
              <InputOTP
                maxLength={4}
                value={intento}
                onChange={(v) => {
                  setIntento(v);
                  if (v.length === 4) validar(v);
                }}
                autoFocus
              >
                <InputOTPGroup>
                  <InputOTPSlot index={0} className="h-14 w-14 text-2xl" />
                  <InputOTPSlot index={1} className="h-14 w-14 text-2xl" />
                  <InputOTPSlot index={2} className="h-14 w-14 text-2xl" />
                  <InputOTPSlot index={3} className="h-14 w-14 text-2xl" />
                </InputOTPGroup>
              </InputOTP>
            </div>
            {validando && <Loader2 className="h-5 w-5 animate-spin mx-auto text-primary" />}
          </CardContent>
        </Card>
      </div>
    );
  }

  return <ComprasContenido pin={pin} />;
}

function ComprasContenido({ pin }: { pin: string }) {
  const hoy = getFechaNegocio();
  const [desde, setDesde] = useState(format(subDays(new Date(), 7), "yyyy-MM-dd"));
  const [hasta, setHasta] = useState(hoy);

  const { sucursales, lista, insumosMaster, pedidosDetalle, loading, refetch } = useAnaliticaPedidos(desde, hasta);

  const nombreInsumo = useMemo(() => {
    const m = new Map<string, string>();
    insumosMaster.forEach((i) => m.set(i.id, i.nombre));
    lista.forEach((l) => m.set(l.insumo_id, l.nombre));
    return m;
  }, [insumosMaster, lista]);
  const unidadInsumo = useMemo(() => {
    const m = new Map<string, string>();
    insumosMaster.forEach((i) => m.set(i.id, i.unidad));
    lista.forEach((l) => m.set(l.insumo_id, l.unidad));
    return m;
  }, [insumosMaster, lista]);
  const insumosOrden = useMemo(() => {
    const seen = new Map<string, number>();
    lista.forEach((l) => {
      const cur = seen.get(l.insumo_id);
      if (cur === undefined || l.orden < cur) seen.set(l.insumo_id, l.orden);
    });
    return Array.from(seen.keys()).sort(
      (a, b) => (seen.get(a)! - seen.get(b)!) || (nombreInsumo.get(a) || "").localeCompare(nombreInsumo.get(b) || "")
    );
  }, [lista, nombreInsumo]);

  return (
    <div className="min-h-screen bg-gradient-to-br from-primary/5 to-secondary/10">
      <div className="bg-background border-b sticky top-0 z-10">
        <div className="container mx-auto px-3 py-2 flex items-center gap-3 max-w-5xl">
          <img src={logoLaOla} alt="La Ola" className="w-8 h-8 rounded-full object-cover" />
          <div className="flex-1">
            <h1 className="text-base font-semibold">Pedido del día</h1>
            <p className="text-xs text-muted-foreground">Captura el pedido y decide dónde comprar</p>
          </div>
        </div>
        <div className="container mx-auto px-3 pb-2 flex flex-wrap items-end gap-3 max-w-5xl">
          <div className="space-y-1">
            <Label className="text-xs">Día</Label>
            <Input type="date" value={hasta} max={hasta} onChange={(e) => { setHasta(e.target.value); setDesde(e.target.value); }} className="h-9 w-40" />
          </div>
        </div>
      </div>

      <div className="container mx-auto px-3 py-4 max-w-5xl">
        {loading ? (
          <div className="flex justify-center py-16"><Loader2 className="h-8 w-8 animate-spin text-primary" /></div>
        ) : (
          <Tabs defaultValue="pedido">
            <TabsList className="mb-4">
              <TabsTrigger value="pedido" className="gap-1 text-xs"><Grid3x3 className="h-3.5 w-3.5" />Pedido del día</TabsTrigger>
              <TabsTrigger value="comprar" className="gap-1 text-xs"><ShoppingCart className="h-3.5 w-3.5" />Dónde comprar</TabsTrigger>
            </TabsList>
            <TabsContent value="pedido">
              <PedidoDelDiaPanel
                sucursales={sucursales}
                pedidosDetalle={pedidosDetalle}
                insumosOrden={insumosOrden}
                nombreInsumo={nombreInsumo}
                hasta={hasta}
                refetch={refetch}
              />
            </TabsContent>
            <TabsContent value="comprar">
              <DondeComprarPanel
                pedidosDetalle={pedidosDetalle}
                insumosOrden={insumosOrden}
                nombreInsumo={nombreInsumo}
                unidadInsumo={unidadInsumo}
                hasta={hasta}
                pin={pin}
              />
            </TabsContent>
          </Tabs>
        )}
      </div>
    </div>
  );
}
