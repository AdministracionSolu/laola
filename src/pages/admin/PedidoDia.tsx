import { useEffect, useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { ArrowLeft, Grid3x3, Loader2, PiggyBank, ShoppingCart } from "lucide-react";
import logoLaOla from "@/assets/logo-la-ola.jpeg";
import { getFechaNegocio } from "@/lib/fecha";
import { useAnaliticaPedidos } from "@/hooks/useAnaliticaPedidos";
import { PedidoDelDiaPanel } from "@/components/admin/pedidos/PedidoDelDiaPanel";
import { DondeComprarPanel } from "@/components/admin/pedidos/DondeComprarPanel";
import { AhorrosPanel } from "@/components/admin/pedidos/AhorrosPanel";

// Vista de operación diaria de pedidos para el admin: el consolidado del día
// (existencia · pidió · a pedir por sucursal), dónde comprar y el ahorro.
// La analítica histórica completa vive aparte en /admin/pedidos.
export default function AdminPedidoDia() {
  const navigate = useNavigate();
  const [dia, setDia] = useState(getFechaNegocio());

  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => {
      if (!session) navigate("/admin/login");
    });
  }, [navigate]);

  const { sucursales, lista, insumosMaster, pedidosDetalle, loading, refetch } = useAnaliticaPedidos(dia, dia);

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
    <div className="min-h-screen bg-muted/30">
      <div className="bg-card border-b sticky top-0 z-10">
        <div className="max-w-6xl mx-auto px-4 py-3 flex items-center justify-between gap-2 flex-wrap">
          <div className="flex items-center gap-3">
            <Button variant="ghost" size="sm" onClick={() => navigate("/admin/dashboard")}>
              <ArrowLeft className="w-4 h-4 mr-1" /> Panel
            </Button>
            <img src={logoLaOla} alt="La Ola" className="w-9 h-9 rounded-full object-cover" />
            <div>
              <h1 className="text-lg font-bold">Pedidos</h1>
              <p className="text-xs text-muted-foreground">Pedido del día, dónde comprar y ahorro</p>
            </div>
          </div>
          <div className="space-y-1">
            <Label className="text-xs">Día</Label>
            <Input type="date" value={dia} onChange={(e) => setDia(e.target.value)} className="h-9 w-40" />
          </div>
        </div>
      </div>

      <div className="max-w-6xl mx-auto px-4 py-4">
        {loading ? (
          <div className="flex justify-center py-16"><Loader2 className="h-8 w-8 animate-spin text-primary" /></div>
        ) : (
          <Tabs defaultValue="pedido">
            <TabsList className="mb-4">
              <TabsTrigger value="pedido" className="gap-1 text-xs"><Grid3x3 className="h-3.5 w-3.5" />Pedido del día</TabsTrigger>
              <TabsTrigger value="comprar" className="gap-1 text-xs"><ShoppingCart className="h-3.5 w-3.5" />Dónde comprar</TabsTrigger>
              <TabsTrigger value="ahorros" className="gap-1 text-xs"><PiggyBank className="h-3.5 w-3.5" />Ahorros</TabsTrigger>
            </TabsList>
            <TabsContent value="pedido">
              <PedidoDelDiaPanel
                sucursales={sucursales}
                pedidosDetalle={pedidosDetalle}
                insumosOrden={insumosOrden}
                nombreInsumo={nombreInsumo}
                hasta={dia}
                refetch={refetch}
              />
            </TabsContent>
            <TabsContent value="comprar">
              <DondeComprarPanel
                pedidosDetalle={pedidosDetalle}
                insumosOrden={insumosOrden}
                nombreInsumo={nombreInsumo}
                unidadInsumo={unidadInsumo}
                hasta={dia}
              />
            </TabsContent>
            <TabsContent value="ahorros">
              <AhorrosPanel
                pedidosDetalle={pedidosDetalle}
                insumosOrden={insumosOrden}
                nombreInsumo={nombreInsumo}
                unidadInsumo={unidadInsumo}
                hasta={dia}
              />
            </TabsContent>
          </Tabs>
        )}
      </div>
    </div>
  );
}
