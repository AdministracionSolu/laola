import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

// DESACTIVADA POR SEGURIDAD (barrido 2026-08).
//
// Esta función provisionaba una cuenta admin con correo y contraseña
// hardcodeados y estaba expuesta públicamente (verify_jwt = false), por lo que
// cualquiera podía crear —o confirmar la existencia de— un admin con contraseña
// conocida. El admin ya existe; ya no se provisiona desde aquí.
//
// La gestión de la cuenta admin y su contraseña se hace desde el dashboard de
// Supabase (Auth) o con la service_role key del lado servidor, nunca desde una
// función pública ni con secretos en el código.

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve((req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }
  return new Response(
    JSON.stringify({ success: false, error: "Función desactivada." }),
    { status: 410, headers: { ...corsHeaders, "Content-Type": "application/json" } },
  );
});
