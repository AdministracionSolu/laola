import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { useToast } from "@/hooks/use-toast";
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart, Pie, Cell, Legend } from "recharts";
import { LogOut, RefreshCw, Store, Calendar, TrendingUp, CreditCard, Banknote, DollarSign } from "lucide-react";
import { format } from "date-fns";
import { es } from "date-fns/locale";

import logoLaOla from "@/assets/logo-la-ola.jpeg";

interface Sucursal {
  id: string;
  nombre: string;
}

interface Corte {
  id: string;
  sucursal_id: string;
  tipo_corte: "momento" | "cierre";
  corte_x: number;
  tarjetas: number;
  efectivo: number;
  total: number;
  created_at: string;
  sucursales: {
    nombre: string;
  };
}

const COLORS = ["#0088FE", "#00C49F", "#FFBB28", "#FF8042"];

export default function AdminDashboard() {
  const [sucursales, setSucursales] = useState<Sucursal[]>([]);
  const [cortes, setCortes] = useState<Corte[]>([]);
  const [filtroSucursal, setFiltroSucursal] = useState<string>("todas");
  const [filtroFecha, setFiltroFecha] = useState<string>(format(new Date(), "yyyy-MM-dd"));
  const [filtroTipo, setFiltroTipo] = useState<string>("todos");
  const [isLoading, setIsLoading] = useState(true);
  const { toast } = useToast();
  const navigate = useNavigate();

  useEffect(() => {
    checkAuth();
  }, []);

  useEffect(() => {
    if (sucursales.length > 0) {
      fetchCortes();
    }
  }, [filtroSucursal, filtroFecha, filtroTipo, sucursales]);

  const checkAuth = async () => {
    const { data: { session } } = await supabase.auth.getSession();
    if (!session) {
      navigate("/admin/login");
      return;
    }
    fetchSucursales();
  };

  const fetchSucursales = async () => {
    const { data, error } = await supabase
      .from("sucursales")
      .select("id, nombre")
      .order("nombre");

    if (error) {
      toast({
        title: "Error",
        description: "No se pudieron cargar las sucursales",
        variant: "destructive",
      });
      return;
    }

    setSucursales(data || []);
    setIsLoading(false);
  };

  const fetchCortes = async () => {
    let query = supabase
      .from("cortes_caja")
      .select("*, sucursales(nombre)")
      .order("created_at", { ascending: false });

    // Filtro por sucursal
    if (filtroSucursal !== "todas") {
      query = query.eq("sucursal_id", filtroSucursal);
    }

    // Filtro por fecha
    if (filtroFecha) {
      const startOfDay = `${filtroFecha}T00:00:00`;
      const endOfDay = `${filtroFecha}T23:59:59`;
      query = query.gte("created_at", startOfDay).lte("created_at", endOfDay);
    }

    // Filtro por tipo
    if (filtroTipo !== "todos") {
      query = query.eq("tipo_corte", filtroTipo as "momento" | "cierre");
    }

    const { data, error } = await query;

    if (error) {
      toast({
        title: "Error",
        description: "No se pudieron cargar los cortes",
        variant: "destructive",
      });
      return;
    }

    setCortes(data as Corte[] || []);
  };

  const handleLogout = async () => {
    await supabase.auth.signOut();
    navigate("/admin/login");
  };

  const handleRefresh = () => {
    fetchCortes();
    toast({
      title: "Actualizado",
      description: "Los datos se han actualizado",
    });
  };

  // Calcular totales
  const totales = cortes.reduce(
    (acc, corte) => ({
      corte_x: acc.corte_x + Number(corte.corte_x),
      tarjetas: acc.tarjetas + Number(corte.tarjetas),
      efectivo: acc.efectivo + Number(corte.efectivo),
      total: acc.total + Number(corte.total),
    }),
    { corte_x: 0, tarjetas: 0, efectivo: 0, total: 0 }
  );

  // Datos para gráfica de barras por sucursal
  const dataPorSucursal = sucursales.map((sucursal) => {
    const cortesDeEsta = cortes.filter((c) => c.sucursal_id === sucursal.id);
    const totalSucursal = cortesDeEsta.reduce((acc, c) => acc + Number(c.total), 0);
    return {
      nombre: sucursal.nombre,
      total: totalSucursal,
    };
  });

  // Datos para gráfica de pie (tarjetas vs efectivo)
  const dataPie = [
    { name: "Tarjetas", value: totales.tarjetas },
    { name: "Efectivo", value: totales.efectivo },
  ];

  const formatMoney = (value: number) => {
    return new Intl.NumberFormat("es-MX", {
      style: "currency",
      currency: "MXN",
    }).format(value);
  };

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
        {/* Filtros */}
        <Card className="mb-8">
          <CardHeader>
            <CardTitle className="text-lg">Filtros</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
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
                <Label className="flex items-center gap-2">
                  <Calendar className="w-4 h-4" />
                  Fecha
                </Label>
                <Input
                  type="date"
                  value={filtroFecha}
                  onChange={(e) => setFiltroFecha(e.target.value)}
                />
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

        {/* Tarjetas de resumen */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-8">
          <Card>
            <CardContent className="pt-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-muted-foreground">Corte X</p>
                  <p className="text-2xl font-bold">{formatMoney(totales.corte_x)}</p>
                </div>
                <DollarSign className="w-10 h-10 text-muted-foreground/30" />
              </div>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="pt-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-muted-foreground">Tarjetas</p>
                  <p className="text-2xl font-bold">{formatMoney(totales.tarjetas)}</p>
                </div>
                <CreditCard className="w-10 h-10 text-blue-500/30" />
              </div>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="pt-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-muted-foreground">Efectivo</p>
                  <p className="text-2xl font-bold">{formatMoney(totales.efectivo)}</p>
                </div>
                <Banknote className="w-10 h-10 text-green-500/30" />
              </div>
            </CardContent>
          </Card>
          <Card className="bg-primary text-primary-foreground">
            <CardContent className="pt-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm opacity-80">Total General</p>
                  <p className="text-2xl font-bold">{formatMoney(totales.total)}</p>
                </div>
                <TrendingUp className="w-10 h-10 opacity-30" />
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Gráficas */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-8">
          <Card>
            <CardHeader>
              <CardTitle>Ventas por Sucursal</CardTitle>
              <CardDescription>Total del día por cada sucursal</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="h-[300px]">
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={dataPorSucursal}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="nombre" />
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

        {/* Tabla de cortes */}
        <Card>
          <CardHeader>
            <CardTitle>Historial de Cortes</CardTitle>
            <CardDescription>
              {cortes.length} cortes encontrados
            </CardDescription>
          </CardHeader>
          <CardContent>
            {cortes.length === 0 ? (
              <div className="text-center py-12 text-muted-foreground">
                <Store className="w-12 h-12 mx-auto mb-4 opacity-30" />
                <p>No hay cortes para esta fecha</p>
              </div>
            ) : (
              <div className="overflow-x-auto">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Hora</TableHead>
                      <TableHead>Sucursal</TableHead>
                      <TableHead>Tipo</TableHead>
                      <TableHead className="text-right">Corte X</TableHead>
                      <TableHead className="text-right">Tarjetas</TableHead>
                      <TableHead className="text-right">Efectivo</TableHead>
                      <TableHead className="text-right">Total</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {cortes.map((corte) => (
                      <TableRow key={corte.id}>
                        <TableCell>
                          {format(new Date(corte.created_at), "HH:mm", { locale: es })}
                        </TableCell>
                        <TableCell className="font-medium">
                          {corte.sucursales?.nombre}
                        </TableCell>
                        <TableCell>
                          <Badge variant={corte.tipo_corte === "cierre" ? "default" : "secondary"}>
                            {corte.tipo_corte === "cierre" ? "Cierre" : "Momento"}
                          </Badge>
                        </TableCell>
                        <TableCell className="text-right">
                          {formatMoney(Number(corte.corte_x))}
                        </TableCell>
                        <TableCell className="text-right">
                          {formatMoney(Number(corte.tarjetas))}
                        </TableCell>
                        <TableCell className="text-right">
                          {formatMoney(Number(corte.efectivo))}
                        </TableCell>
                        <TableCell className="text-right font-semibold">
                          {formatMoney(Number(corte.total))}
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </div>
            )}
          </CardContent>
        </Card>
      </main>
    </div>
  );
}
