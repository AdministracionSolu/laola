import { Toaster } from "@/components/ui/toaster";
import { Toaster as Sonner } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import Index from "./pages/Index";
import Menu from "./pages/Menu";
import Sucursales from "./pages/Sucursales";
import Contacto from "./pages/Contacto";
import CentroOperaciones from "./pages/CentroOperaciones";
import Corte from "./pages/Corte";
import Reservaciones from "./pages/Reservaciones";
import Pedidos from "./pages/Pedidos";
import Recepciones from "./pages/Recepciones";
import Contadoras from "./pages/Contadoras";
import AdminLogin from "./pages/admin/Login";
import AdminDashboard from "./pages/admin/Dashboard";
import AdminPanelControl from "./pages/admin/PanelControl";
import AdminPedidos from "./pages/admin/Pedidos";
import AdminProveedores from "./pages/admin/Proveedores";
import QrPedidos from "./pages/admin/QrPedidos";
import PedidosHome from "./pages/PedidosHome";
import EntrarSucursal from "./pages/EntrarSucursal";
import Compras from "./pages/Compras";
import ProveedorPortal from "./pages/ProveedorPortal";
import DepurarProveedores from "./pages/DepurarProveedores";
import OperacionesLayout from "./components/operaciones/OperacionesLayout";
import Ordenar from "./pages/Ordenar";
import SeguimientoPedido from "./pages/SeguimientoPedido";
import PanelPedidosEnLinea from "./pages/PanelPedidosEnLinea";
import NotFound from "./pages/NotFound";

const queryClient = new QueryClient();

const App = () => (
  <QueryClientProvider client={queryClient}>
    <TooltipProvider>
      <Toaster />
      <Sonner />
      <BrowserRouter>
        <Routes>
          <Route path="/" element={<Index />} />
          <Route path="/menu" element={<Menu />} />
          <Route path="/sucursales" element={<Sucursales />} />
          <Route path="/contacto" element={<Contacto />} />
          {/* Pedidos en línea (cliente final, público) */}
          <Route path="/ordenar" element={<Ordenar />} />
          <Route path="/ordenar/:slugSucursal" element={<Ordenar />} />
          <Route path="/pedido/:token" element={<SeguimientoPedido />} />
          {/* Centro de Operaciones: igual que antes (sin gate) */}
          <Route path="/centro-de-operaciones" element={<CentroOperaciones />} />
          <Route path="/centro-de-operaciones/cortes" element={<Corte />} />
          <Route path="/centro-de-operaciones/reservaciones" element={<Reservaciones />} />
          <Route path="/centro-de-operaciones/contadoras" element={<Contadoras />} />
          {/* Liga/QR por sucursal: fija la sucursal (bloqueada) y entra al destino */}
          <Route path="/compras" element={<Compras />} />
          <Route path="/pedidos/s/:sucursalId" element={<EntrarSucursal destino="/pedidos/hacer" />} />
          <Route path="/recepcion/s/:sucursalId" element={<EntrarSucursal destino="/pedidos/recepcion" />} />
          {/* Pedidos: slug propio con gate de sucursal */}
          <Route element={<OperacionesLayout />}>
            <Route path="/pedidos" element={<PedidosHome />} />
            <Route path="/pedidos/hacer" element={<Pedidos />} />
            <Route path="/pedidos/recepcion" element={<Recepciones />} />
            {/* Panel de pedidos en línea (staff de sucursal) */}
            <Route path="/pedidos-en-linea" element={<PanelPedidosEnLinea />} />
          </Route>
          {/* Redirects de rutas anteriores */}
          <Route path="/centro-de-operaciones/pedidos" element={<Navigate to="/pedidos/hacer" replace />} />
          <Route path="/centro-de-operaciones/recepciones" element={<Navigate to="/pedidos/recepcion" replace />} />
          {/* Legacy route redirect */}
          <Route path="/corte" element={<CentroOperaciones />} />
          <Route path="/admin/login" element={<AdminLogin />} />
          <Route path="/admin/dashboard" element={<AdminDashboard />} />
          <Route path="/admin/panel-control" element={<AdminPanelControl />} />
          <Route path="/admin/pedidos" element={<AdminPedidos />} />
          <Route path="/admin/proveedores" element={<AdminProveedores />} />
          <Route path="/admin/qr-pedidos" element={<QrPedidos />} />
          {/* Portal público del proveedor (sin login, por token) */}
          <Route path="/proveedor/:token" element={<ProveedorPortal />} />
          {/* Depuración de listas de proveedores (uso único, por token) */}
          <Route path="/depurar/:token" element={<DepurarProveedores />} />
          {/* ADD ALL CUSTOM ROUTES ABOVE THE CATCH-ALL "*" ROUTE */}
          <Route path="*" element={<NotFound />} />
        </Routes>
      </BrowserRouter>
    </TooltipProvider>
  </QueryClientProvider>
);

export default App;
