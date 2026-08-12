import { useEffect, useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { ArrowLeft, Grid3x3, Loader2, ShoppingCart, Store } from "lucide-react";
import logoLaOla from "@/assets/logo-la-ola.jpeg";
import { getFechaCalendario } from "@/lib/fecha";
import { esSucursalReferencia, useAnaliticaPedidos } from "@/hooks/useAnaliticaPedidos";
import { PedidoDelDiaPanel } from "@/components/admin/pedidos/PedidoDelDiaPanel";
import { DondeComprarPanel } from "@/components/admin/pedidos/DondeComprarPanel";
import { ProveedoresPanel } from "@/components/admin/pedidos/ProveedoresPanel";

// Vista de operación diaria de pedidos para el admin: el consolidado del día
// (existencia · pidió · a pedir por sucursal), dónde comprar y proveedores.
// El panel de Ahorros es del dueño y vive en Herramientas (/admin/ahorros);
// la analítica histórica completa vive aparte en /admin/pedidos.
export default function AdminPedidoDia() {
  const navigate = useNavigate();
  // El panel es de REVISIÓN: abre en el día de hoy. Antes usaba la fecha de
  // negocio, que a partir de la 1pm salta al día siguiente y hacía ver el
  // tablero vacío cuando en realidad ya habían capturado.
  const [dia, setDia] = useState(getFechaCalendario());

  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => {
      if (!session) navigate("/admin/login");
    });
  }, [navigate]);

  const { sucursales, lista, insumosMaster, pedidos, pedidosDetalle, loading, refetch } = useAnaliticaPedidos(dia, dia);

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

  // La prueba de proveedores es solo Tepic: Solares (GDL) compra aparte y no
  // entra a "Dónde comprar".
  const pedidosDetalleTepic = useMemo(() => {
    const idsRef = new Set(sucursales.filter((s) => esSucursalReferencia(s.codigo)).map((s) => s.id));
    return pedidosDetalle.filter((d) => !idsRef.has(d.sucursal_id));
  }, [pedidosDetalle, sucursales]);

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
              <TabsTrigger value="proveedores" className="gap-1 text-xs"><Store className="h-3.5 w-3.5" />Proveedores</TabsTrigger>
            </TabsList>
            <TabsContent value="pedido">
              <PedidoDelDiaPanel
                sucursales={sucursales}
                pedidos={pedidos}
                pedidosDetalle={pedidosDetalle}
                insumosOrden={insumosOrden}
                nombreInsumo={nombreInsumo}
                hasta={dia}
                refetch={refetch}
              />
            </TabsContent>
            <TabsContent value="comprar">
              <DondeComprarPanel
                pedidosDetalle={pedidosDetalleTepic}
                insumosOrden={insumosOrden}
                nombreInsumo={nombreInsumo}
                unidadInsumo={unidadInsumo}
                hasta={dia}
              />
            </TabsContent>
            <TabsContent value="proveedores">
              <ProveedoresPanel />
            </TabsContent>
          </Tabs>
        )}
      </div>
    </div>
  );
}
