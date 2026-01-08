import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

const ADMIN_EMAIL = "admin@laola.mx";
const ADMIN_PASSWORD = "LaOla1278!";

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

    const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    });

    // Check if admin user already exists
    const { data: existingUsers } = await supabaseAdmin.auth.admin.listUsers();
    const adminExists = existingUsers?.users?.some(u => u.email === ADMIN_EMAIL);

    if (adminExists) {
      console.log("Admin user already exists");
      return new Response(
        JSON.stringify({ success: true, message: "Admin already exists" }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Create admin user
    const { data: newUser, error: createError } = await supabaseAdmin.auth.admin.createUser({
      email: ADMIN_EMAIL,
      password: ADMIN_PASSWORD,
      email_confirm: true,
    });

    if (createError) {
      console.error("Error creating admin:", createError);
      throw createError;
    }

    console.log("Admin user created:", newUser.user?.id);

    // Assign admin role
    if (newUser.user) {
      const { error: roleError } = await supabaseAdmin
        .from('user_roles')
        .insert({ user_id: newUser.user.id, role: 'admin' });

      if (roleError) {
        console.error("Error assigning role:", roleError);
      } else {
        console.log("Admin role assigned");
      }
    }

    return new Response(
      JSON.stringify({ success: true, message: "Admin created successfully" }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (error: unknown) {
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';
    console.error("Setup admin error:", errorMessage);
    return new Response(
      JSON.stringify({ success: false, error: errorMessage }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
