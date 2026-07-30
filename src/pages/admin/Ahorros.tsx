import { useEffect, useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { ArrowLeft, Loader2 } from "lucide-react";
import logoLaOla from "@/assets/logo-la-ola.jpeg";
import { getFechaNegocio } from "@/lib/fecha";
import { esSucursalReferencia, useAnaliticaPedidos } from "@/hooks/useAnaliticaPedidos";
import { AhorrosPanel } from "@/components/admin/pedidos/AhorrosPanel";

// Reporte de ahorros de compras (barato vs caro). Es información del dueño:
// se llega desde Herramientas → Reportes del dueño, no desde el panel de
// pedidos que usan los empleados.
export default function AdminAhorros() {
  const navigate = useNavigate();
  const [dia, setDia] = useState(getFechaNegocio());

  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => {
      if (!session) navigate("/admin/login");
    });
  }, [navigate]);

  const { sucursales, lista, insumosMaster, pedidosDetalle, loading } = useAnaliticaPedidos(dia, dia);

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

  // La prueba de proveedores es solo Tepic: Solares (GDL) compra aparte.
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
              <h1 className="text-lg font-bold">Ahorros de compras</h1>
              <p className="text-xs text-muted-foreground">Comprando al más barato vs. al más caro</p>
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
          <AhorrosPanel
            pedidosDetalle={pedidosDetalleTepic}
            insumosOrden={insumosOrden}
            nombreInsumo={nombreInsumo}
            unidadInsumo={unidadInsumo}
            hasta={dia}
          />
        )}
      </div>
    </div>
  );
}
