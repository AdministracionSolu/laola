import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { useToast } from "@/hooks/use-toast";
import { InputOTP, InputOTPGroup, InputOTPSlot } from "@/components/ui/input-otp";

import logoLaOla from "@/assets/logo-la-ola.jpeg";

const ADMIN_EMAIL = "admin@laola.mx";
const ADMIN_PASSWORD = "LaOla1278!";
const CORRECT_PIN = "1278";

export default function AdminLogin() {
  const [pin, setPin] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const { toast } = useToast();
  const navigate = useNavigate();

  useEffect(() => {
    const { data: { subscription } } = supabase.auth.onAuthStateChange((event, session) => {
      if (session) {
        navigate("/admin/dashboard");
      }
    });

    supabase.auth.getSession().then(({ data: { session } }) => {
      if (session) {
        navigate("/admin/dashboard");
      }
    });

    return () => subscription.unsubscribe();
  }, [navigate]);

  const handlePinComplete = async (value: string) => {
    if (value.length !== 4) return;
    
    if (value !== CORRECT_PIN) {
      toast({
        title: "PIN incorrecto",
        description: "Verifica el código de acceso",
        variant: "destructive",
      });
      setPin("");
      return;
    }

    setIsLoading(true);

    // Intentar login
    const { error: signInError } = await supabase.auth.signInWithPassword({
      email: ADMIN_EMAIL,
      password: ADMIN_PASSWORD,
    });

    if (signInError) {
      // Si el usuario no existe, crearlo usando Edge Function
      if (signInError.message.includes("Invalid login credentials")) {
        try {
          // Llamar a la Edge Function para crear el usuario admin
          const { error: setupError } = await supabase.functions.invoke('setup-admin');
          
          if (setupError) {
            console.error("Setup error:", setupError);
            toast({
              title: "Error de configuración",
              description: "No se pudo crear la cuenta de administrador",
              variant: "destructive",
            });
            setIsLoading(false);
            setPin("");
            return;
          }

          // Intentar login de nuevo después de crear
          const { error: retryError } = await supabase.auth.signInWithPassword({
            email: ADMIN_EMAIL,
            password: ADMIN_PASSWORD,
          });

          if (retryError) {
            console.error("Retry login error:", retryError);
            toast({
              title: "Error de acceso",
              description: "Intenta ingresar el PIN nuevamente",
              variant: "destructive",
            });
            setIsLoading(false);
            setPin("");
            return;
          }
        } catch (err) {
          console.error("Unexpected error:", err);
          toast({
            title: "Error inesperado",
            description: "Intenta de nuevo en unos segundos",
            variant: "destructive",
          });
          setIsLoading(false);
          setPin("");
          return;
        }
      } else {
        toast({
          title: "Error de acceso",
          description: "No se pudo iniciar sesión",
          variant: "destructive",
        });
        setIsLoading(false);
        setPin("");
        return;
      }
    }

    navigate("/admin/dashboard");
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-primary/10 to-secondary/20 flex items-center justify-center p-4">
      <Card className="w-full max-w-sm">
        <CardHeader className="text-center">
          <div className="mx-auto mb-4 w-24 h-24 rounded-full overflow-hidden shadow-lg">
            <img src={logoLaOla} alt="La Ola" className="w-full h-full object-cover" />
          </div>
          <CardTitle className="text-2xl">Panel Administrativo</CardTitle>
          <CardDescription>
            Ingresa el PIN de acceso
          </CardDescription>
        </CardHeader>
        <CardContent className="flex flex-col items-center gap-6">
          <InputOTP
            maxLength={4}
            value={pin}
            onChange={setPin}
            onComplete={handlePinComplete}
            disabled={isLoading}
          >
            <InputOTPGroup>
              <InputOTPSlot index={0} className="w-14 h-14 text-2xl" />
              <InputOTPSlot index={1} className="w-14 h-14 text-2xl" />
              <InputOTPSlot index={2} className="w-14 h-14 text-2xl" />
              <InputOTPSlot index={3} className="w-14 h-14 text-2xl" />
            </InputOTPGroup>
          </InputOTP>

          <Button 
            onClick={() => handlePinComplete(pin)}
            className="w-full" 
            disabled={isLoading || pin.length !== 4}
          >
            {isLoading ? "Ingresando..." : "Ingresar"}
          </Button>
        </CardContent>
      </Card>
    </div>
  );
}