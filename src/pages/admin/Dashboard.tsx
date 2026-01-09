import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Label } from "@/components/ui/label";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { useToast } from "@/hooks/use-toast";
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart, Pie, Cell, Legend } from "recharts";
import { LogOut, RefreshCw, Store, TrendingUp, CreditCard, Banknote, DollarSign, LayoutDashboard, History } from "lucide-react";
import { useEffect } from "react";

import logoLaOla from "@/assets/logo-la-ola.jpeg";

import { usePeriodo } from "@/hooks/usePeriodo";
import { useCortes } from "@/hooks/useCortes";
import { PeriodSelector } from "@/components/admin/PeriodSelector";
import { TrendChart } from "@/components/admin/TrendChart";
import { ComparativoCard } from "@/components/admin/ComparativoCard";
import { SucursalStatus } from "@/components/admin/SucursalStatus";
import { HistoricoTable } from "@/components/admin/HistoricoTable";

const COLORS = ["#0088FE", "#00C49F", "#FFBB28", "#FF8042"];

export default function AdminDashboard() {
  const [filtroSucursal, setFiltroSucursal] = useState<string>("todas");
  const [filtroTipo, setFiltroTipo] = useState<string>("todos");
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
    isLoading,
    totales,
    totalesAnterior,
    datosTendencia,
    dataPorSucursal,
    estadoSucursales,
    refetch,
    deleteCorte,
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

  // Datos para gráfica de pie (tarjetas vs efectivo)
  const dataPie = [
    { name: "Tarjetas", value: totales.tarjetas },
    { name: "Efectivo", value: totales.efectivo },
  ];

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
                <Label>Tipo de Corte</Label>
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

        <Tabs defaultValue="resumen" className="space-y-6">
          <TabsList>
            <TabsTrigger value="resumen" className="gap-2">
              <LayoutDashboard className="w-4 h-4" />
              Resumen
            </TabsTrigger>
            <TabsTrigger value="historico" className="gap-2">
              <History className="w-4 h-4" />
              Histórico
            </TabsTrigger>
          </TabsList>

          <TabsContent value="resumen" className="space-y-6">
            {/* Tarjetas de resumen con comparativos */}
            <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
              <ComparativoCard
                titulo="Corte X"
                valor={totales.corte_x}
                valorAnterior={totalesAnterior.corte_x}
                formatMoney={formatMoney}
                icon={DollarSign}
              />
              <ComparativoCard
                titulo="Tarjetas"
                valor={totales.tarjetas}
                valorAnterior={totalesAnterior.tarjetas}
                formatMoney={formatMoney}
                icon={CreditCard}
                iconColor="text-blue-500/30"
              />
              <ComparativoCard
                titulo="Efectivo"
                valor={totales.efectivo}
                valorAnterior={totalesAnterior.efectivo}
                formatMoney={formatMoney}
                icon={Banknote}
                iconColor="text-green-500/30"
              />
              <ComparativoCard
                titulo="Total General"
                valor={totales.total}
                valorAnterior={totalesAnterior.total}
                formatMoney={formatMoney}
                icon={TrendingUp}
                destacado
              />
            </div>

            {/* Gráfica de tendencia (solo para rangos mayores a un día) */}
            <TrendChart
              datos={datosTendencia}
              tipoPeriodo={tipoPeriodo}
              formatMoney={formatMoney}
            />

            {/* Gráficas */}
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              <Card>
                <CardHeader>
                  <CardTitle>Ventas por Sucursal</CardTitle>
                  <CardDescription>Total del período por cada sucursal</CardDescription>
                </CardHeader>
                <CardContent>
                  <div className="h-[300px]">
                    <ResponsiveContainer width="100%" height="100%">
                      <BarChart data={dataPorSucursal}>
                        <CartesianGrid strokeDasharray="3 3" className="stroke-muted" />
                        <XAxis dataKey="nombre" tick={{ fontSize: 12 }} />
                        <YAxis tickFormatter={(value) => `$${(value / 1000).toFixed(0)}k`} />
                        <Tooltip formatter={(value: number) => formatMoney(value)} />
                        <Bar dataKey="total" fill="hsl(var(--primary))" radius={[4, 4, 0, 0]} />
                      </BarChart>
                    </ResponsiveContainer>
                  </div>
                </CardContent>
              </Card>

              <Card>
                <CardHeader>
                  <CardTitle>Distribución de Pagos</CardTitle>
                  <CardDescription>Tarjetas vs Efectivo</CardDescription>
                </CardHeader>
                <CardContent>
                  <div className="h-[300px]">
                    <ResponsiveContainer width="100%" height="100%">
                      <PieChart>
                        <Pie
                          data={dataPie}
                          cx="50%"
                          cy="50%"
                          labelLine={false}
                          label={({ name, percent }) => `${name}: ${(percent * 100).toFixed(0)}%`}
                          outerRadius={100}
                          fill="#8884d8"
                          dataKey="value"
                        >
                          {dataPie.map((_, index) => (
                            <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                          ))}
                        </Pie>
                        <Tooltip formatter={(value: number) => formatMoney(value)} />
                        <Legend />
                      </PieChart>
                    </ResponsiveContainer>
                  </div>
                </CardContent>
              </Card>
            </div>
          </TabsContent>

          <TabsContent value="historico">
            <HistoricoTable
              cortes={cortes}
              formatMoney={formatMoney}
              mostrarFecha={!esDiaUnico}
              onDelete={deleteCorte}
            />
          </TabsContent>
        </Tabs>
      </main>
    </div>
  );
}
