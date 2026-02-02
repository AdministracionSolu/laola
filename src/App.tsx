import { Toaster } from "@/components/ui/toaster";
import { Toaster as Sonner } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Routes, Route } from "react-router-dom";
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
          <Route path="/centro-de-operaciones" element={<CentroOperaciones />} />
          <Route path="/centro-de-operaciones/cortes" element={<Corte />} />
          <Route path="/centro-de-operaciones/reservaciones" element={<Reservaciones />} />
          <Route path="/centro-de-operaciones/pedidos" element={<Pedidos />} />
          <Route path="/centro-de-operaciones/recepciones" element={<Recepciones />} />
          <Route path="/centro-de-operaciones/contadoras" element={<Contadoras />} />
          {/* Legacy route redirect */}
          <Route path="/corte" element={<CentroOperaciones />} />
          <Route path="/admin/login" element={<AdminLogin />} />
          <Route path="/admin/dashboard" element={<AdminDashboard />} />
          <Route path="/admin/panel-control" element={<AdminPanelControl />} />
          {/* ADD ALL CUSTOM ROUTES ABOVE THE CATCH-ALL "*" ROUTE */}
          <Route path="*" element={<NotFound />} />
        </Routes>
      </BrowserRouter>
    </TooltipProvider>
  </QueryClientProvider>
);

export default App;
