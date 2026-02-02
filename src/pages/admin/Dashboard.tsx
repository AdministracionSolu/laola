import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Label } from "@/components/ui/label";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { useToast } from "@/hooks/use-toast";
import { LogOut, RefreshCw, Store, Camera, BarChart3, History, LayoutDashboard } from "lucide-react";
import { useEffect } from "react";

import logoLaOla from "@/assets/logo-la-ola.jpeg";

import { usePeriodo } from "@/hooks/usePeriodo";
import { useCortes } from "@/hooks/useCortes";
import { PeriodSelector } from "@/components/admin/PeriodSelector";
import { SucursalStatus } from "@/components/admin/SucursalStatus";
import { HistoricoTable } from "@/components/admin/HistoricoTable";
import { EstadoActualView } from "@/components/admin/EstadoActualView";
import { AnalisisVentas } from "@/components/admin/AnalisisVentas";
import { DesgloseTerminales } from "@/components/admin/DesgloseTerminales";

export default function AdminDashboard() {
  const [filtroSucursal, setFiltroSucursal] = useState<string>("todas");
  const [filtroTipo, setFiltroTipo] = useState<string>("todos");
  const [vistaActiva, setVistaActiva] = useState<string>("estado");
  const { toast } = useToast();
  const navigate = useNavigate();

  const {
    tipoPeriodo,
    setTipoPeriodo,
    rangoPersonalizado,
    setRangoPersonalizado,
    rangoActual,
    rangoAnterior,
    etiquetaPeriodo,
    formatoFechaRango,
  } = usePeriodo();

  const {
    sucursales,
    cortes,
    cortesCierre,
    ultimosCortesHoy,
    isLoading,
    totales,
    totalesAnterior,
    datosTendencia,
    dataPorSucursal,
    estadoSucursales,
    refetch,
    deleteCorte,
    cambiarTipoCorte,
  } = useCortes({
    rango: rangoActual,
    rangoAnterior,
    filtroSucursal,
    filtroTipo,
  });

  useEffect(() => {
    checkAuth();
  }, []);

  const checkAuth = async () => {
    const { data: { session } } = await supabase.auth.getSession();
    if (!session) {
      navigate("/admin/login");
    }
  };

  const handleLogout = async () => {
    await supabase.auth.signOut();
    navigate("/admin/login");
  };

  const handleRefresh = () => {
    refetch();
    toast({
      title: "Actualizado",
      description: "Los datos se han actualizado",
    });
  };

  const formatMoney = (value: number) => {
    return new Intl.NumberFormat("es-MX", {
      style: "currency",
      currency: "MXN",
    }).format(value);
  };

  const esDiaUnico = tipoPeriodo === "hoy" || tipoPeriodo === "ayer";

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background">
      {/* Header */}
      <header className="bg-card border-b sticky top-0 z-50">
        <div className="container mx-auto px-4 py-4 flex items-center justify-between">
          <div className="flex items-center gap-4">
            <img src={logoLaOla} alt="La Ola" className="w-10 h-10 rounded-full object-cover" />
            <div>
              <h1 className="text-xl font-bold">Dashboard de Cortes</h1>
              <p className="text-sm text-muted-foreground">Panel Administrativo</p>
            </div>
          </div>
          <div className="flex items-center gap-2">
            <Button variant="default" onClick={() => navigate("/admin/panel-control")} className="gap-2">
              <LayoutDashboard className="w-4 h-4" />
              <span className="hidden sm:inline">Panel Control</span>
            </Button>
            <Button variant="outline" size="icon" onClick={handleRefresh}>
              <RefreshCw className="w-4 h-4" />
            </Button>
            <Button variant="outline" onClick={handleLogout}>
              <LogOut className="w-4 h-4 mr-2" />
              Salir
            </Button>
          </div>
        </div>
      </header>

      <main className="container mx-auto px-4 py-8">
        {/* Tabs principales: Estado Actual vs Análisis */}
        <Tabs value={vistaActiva} onValueChange={setVistaActiva} className="space-y-6">
          <TabsList className="grid w-full grid-cols-2 lg:w-auto lg:inline-grid">
            <TabsTrigger value="estado" className="gap-2">
              <Camera className="w-4 h-4" />
              Estado Actual
            </TabsTrigger>
            <TabsTrigger value="analisis" className="gap-2">
              <BarChart3 className="w-4 h-4" />
              Análisis de Ventas
            </TabsTrigger>
          </TabsList>

          {/* Vista: Estado Actual */}
          <TabsContent value="estado" className="space-y-6">
            <Card className="mb-6">
              <CardHeader className="pb-3">
                <CardTitle className="text-lg">Período</CardTitle>
              </CardHeader>
              <CardContent>
                <PeriodSelector
                  tipoPeriodo={tipoPeriodo}
                  onTipoPeriodoChange={setTipoPeriodo}
                  onRangoPersonalizadoChange={setRangoPersonalizado}
                  etiquetaPeriodo={etiquetaPeriodo}
                  formatoFechaRango={formatoFechaRango}
                />
              </CardContent>
            </Card>

            {/* Filtro de sucursal para Estado Actual */}
            <Card className="mb-6">
              <CardContent className="pt-6">
                <div className="space-y-2">
                  <Label className="flex items-center gap-2">
                    <Store className="w-4 h-4" />
                    Filtrar por Sucursal
                  </Label>
                  <Select value={filtroSucursal} onValueChange={setFiltroSucursal}>
                    <SelectTrigger className="max-w-xs">
                      <SelectValue placeholder="Todas las sucursales" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="todas">Todas las sucursales</SelectItem>
                      {sucursales.map((s) => (
                        <SelectItem key={s.id} value={s.id}>
                          {s.nombre}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
              </CardContent>
            </Card>

            <EstadoActualView
              sucursales={filtroSucursal === "todas" ? sucursales : sucursales.filter(s => s.id === filtroSucursal)}
              ultimosCortes={ultimosCortesHoy}
              formatMoney={formatMoney}
            />
          </TabsContent>

          {/* Vista: Análisis de Ventas */}
          <TabsContent value="analisis" className="space-y-6">
            {/* Selector de período */}
            <Card className="mb-6">
              <CardHeader className="pb-3">
                <CardTitle className="text-lg">Período</CardTitle>
              </CardHeader>
              <CardContent>
                <PeriodSelector
                  tipoPeriodo={tipoPeriodo}
                  onTipoPeriodoChange={setTipoPeriodo}
                  onRangoPersonalizadoChange={setRangoPersonalizado}
                  etiquetaPeriodo={etiquetaPeriodo}
                  formatoFechaRango={formatoFechaRango}
                />
              </CardContent>
            </Card>

            {/* Filtros adicionales */}
            <Card className="mb-6">
              <CardContent className="pt-6">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label className="flex items-center gap-2">
                      <Store className="w-4 h-4" />
                      Sucursal
                    </Label>
                    <Select value={filtroSucursal} onValueChange={setFiltroSucursal}>
                      <SelectTrigger>
                        <SelectValue placeholder="Todas las sucursales" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="todas">Todas las sucursales</SelectItem>
                        {sucursales.map((s) => (
                          <SelectItem key={s.id} value={s.id}>
                            {s.nombre}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>
                  <div className="space-y-2">
                    <Label>Tipo de Corte (histórico)</Label>
                    <Select value={filtroTipo} onValueChange={setFiltroTipo}>
                      <SelectTrigger>
                        <SelectValue placeholder="Todos los tipos" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="todos">Todos</SelectItem>
                        <SelectItem value="momento">Del Momento</SelectItem>
                        <SelectItem value="cierre">De Cierre</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                </div>
              </CardContent>
            </Card>

            {/* Estado de sucursales (solo para día único) */}
            {esDiaUnico && (
              <div className="mb-6">
                <SucursalStatus estados={estadoSucursales} mostrarSoloDia={esDiaUnico} />
              </div>
            )}

            {/* Subtabs: Resumen e Histórico */}
            <Tabs defaultValue="resumen" className="space-y-6">
              <TabsList>
                <TabsTrigger value="resumen" className="gap-2">
                  <BarChart3 className="w-4 h-4" />
                  Resumen
                </TabsTrigger>
                <TabsTrigger value="historico" className="gap-2">
                  <History className="w-4 h-4" />
                  Histórico
                </TabsTrigger>
              </TabsList>

              <TabsContent value="resumen" className="space-y-6">
                <div className="p-3 rounded-lg bg-muted/50 border border-dashed">
                  <p className="text-sm text-muted-foreground">
                    📊 Los totales y gráficas muestran únicamente cortes de <strong>cierre</strong> (ventas finales del día).
                  </p>
                </div>
                <AnalisisVentas
                  totales={totales}
                  totalesAnterior={totalesAnterior}
                  datosTendencia={datosTendencia}
                  dataPorSucursal={dataPorSucursal}
                  tipoPeriodo={tipoPeriodo}
                  formatMoney={formatMoney}
                  cortesCierre={cortesCierre}
                />
                {/* Desglose de tarjetas por terminal */}
                <DesgloseTerminales
                  cortesCierre={cortesCierre}
                  sucursales={sucursales}
                  formatMoney={formatMoney}
                />
              </TabsContent>

              <TabsContent value="historico">
                <HistoricoTable
                  cortes={cortes}
                  formatMoney={formatMoney}
                  mostrarFecha={!esDiaUnico}
                  onDelete={deleteCorte}
                  onCambiarTipo={cambiarTipoCorte}
                />
              </TabsContent>
            </Tabs>
          </TabsContent>
        </Tabs>
      </main>
    </div>
  );
}
