import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { useToast } from "@/hooks/use-toast";

import logoLaOla from "@/assets/logo-la-ola.jpeg";

export default function AdminLogin() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const { toast } = useToast();
  const navigate = useNavigate();

  // Admin → dashboard completo. Cuenta sin rol admin (contadoras) → solo facturación.
  const irADondeCorresponde = async (userId: string) => {
    const { data: esAdmin } = await supabase.rpc("has_role", {
      _user_id: userId,
      _role: "admin",
    });
    navigate(esAdmin ? "/admin/dashboard" : "/admin/facturacion");
  };

  useEffect(() => {
    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      if (session) irADondeCorresponde(session.user.id);
    });

    supabase.auth.getSession().then(({ data: { session } }) => {
      if (session) irADondeCorresponde(session.user.id);
    });

    return () => subscription.unsubscribe();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [navigate]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email || !password) return;
    setIsLoading(true);

    const { data, error } = await supabase.auth.signInWithPassword({
      email: email.trim(),
      password,
    });

    if (error) {
      toast({
        title: "No se pudo iniciar sesión",
        description: "Correo o contraseña incorrectos.",
        variant: "destructive",
      });
      setIsLoading(false);
      setPassword("");
      return;
    }

    if (data.session) await irADondeCorresponde(data.session.user.id);
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-primary/10 to-secondary/20 flex items-center justify-center p-4">
      <Card className="w-full max-w-sm">
        <CardHeader className="text-center">
          <div className="mx-auto mb-4 w-24 h-24 rounded-full overflow-hidden shadow-lg">
            <img src={logoLaOla} alt="La Ola" className="w-full h-full object-cover" />
          </div>
          <CardTitle className="text-2xl">Panel Administrativo</CardTitle>
          <CardDescription>Inicia sesión con tu cuenta</CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit} className="flex flex-col gap-4">
            <div className="flex flex-col gap-2">
              <Label htmlFor="email">Correo</Label>
              <Input
                id="email"
                type="email"
                autoComplete="username"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                disabled={isLoading}
                required
              />
            </div>
            <div className="flex flex-col gap-2">
              <Label htmlFor="password">Contraseña</Label>
              <Input
                id="password"
                type="password"
                autoComplete="current-password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                disabled={isLoading}
                required
              />
            </div>
            <Button type="submit" className="w-full" disabled={isLoading || !email || !password}>
              {isLoading ? "Ingresando..." : "Ingresar"}
            </Button>
          </form>
        </CardContent>
      </Card>
    </div>
  );
}
