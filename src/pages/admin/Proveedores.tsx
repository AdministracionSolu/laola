import { useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { ArrowLeft } from "lucide-react";
import logoLaOla from "@/assets/logo-la-ola.jpeg";
import { ProveedoresPanel } from "@/components/admin/pedidos/ProveedoresPanel";

// El módulo completo vive en ProveedoresPanel y también está embebido como
// pestaña en /admin/pedido-dia; esta ruta se conserva como acceso directo.
export default function AdminProveedores() {
  const navigate = useNavigate();

  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => {
      if (!session) navigate("/admin/login");
    });
  }, [navigate]);

  return (
    <div className="min-h-screen bg-gradient-to-br from-primary/5 to-secondary/10">
      <div className="bg-background border-b sticky top-0 z-10">
        <div className="container mx-auto px-3 py-2 flex items-center gap-3">
          <Button variant="ghost" size="icon" onClick={() => navigate("/admin/dashboard")}><ArrowLeft className="h-5 w-5" /></Button>
          <img src={logoLaOla} alt="La Ola" className="w-8 h-8 rounded-full object-cover" />
          <div className="flex-1">
            <h1 className="text-base font-semibold">Proveedores & Precios</h1>
            <p className="text-xs text-muted-foreground">Compra estratégica — compara y ahorra</p>
          </div>
        </div>
      </div>

      <div className="container mx-auto px-3 py-4 max-w-4xl">
        <ProveedoresPanel />
      </div>
    </div>
  );
}
