import { useEffect, useState } from "react";
import { useParams, Link } from "react-router-dom";
import { supabase } from "@/integrations/supabase/client";
import { Loader2, FileText, UtensilsCrossed } from "lucide-react";
import logoLaOla from "@/assets/logo-la-ola.jpeg";

// "Del Valle" se muestra como "Valle".
const nombreCorto = (n: string) => n.replace(/^Del\s+/i, "");

// Ruta estable del QR: /menu/s/<codigo> (codigo = prefijo_folio, ej. VAL).
// Busca el menú vigente de la sucursal y redirige al PDF. Si no hay menú
// cargado, muestra un aviso amable con liga al menú general.
export default function MenuSucursal() {
  const { codigo = "" } = useParams();
  const cod = codigo.trim().toUpperCase();
  const [estado, setEstado] = useState<"cargando" | "sin-menu" | "error">("cargando");
  const [sucursal, setSucursal] = useState<string | null>(null);

  useEffect(() => {
    let vivo = true;
    (async () => {
      if (!cod) { setEstado("error"); return; }
      const { data, error } = await supabase
        .from("sucursales")
        .select("nombre,menu_url,prefijo_folio")
        .eq("prefijo_folio", cod)
        .maybeSingle();
      if (!vivo) return;
      if (error) { setEstado("error"); return; }
      const url = (data as any)?.menu_url as string | null | undefined;
      setSucursal((data as any)?.nombre ?? null);
      if (url) {
        window.location.replace(url);
      } else {
        setEstado("sin-menu");
      }
    })();
    return () => { vivo = false; };
  }, [cod]);

  return (
    <div className="min-h-screen bg-gradient-to-b from-primary/10 via-background to-background flex items-center justify-center p-4">
      <div className="max-w-md w-full text-center">
        <div className="w-20 h-20 rounded-full overflow-hidden mx-auto mb-4 ring-4 ring-primary/20 shadow-lg">
          <img src={logoLaOla} alt="La Ola" className="w-full h-full object-cover" />
        </div>

        {estado === "cargando" && (
          <>
            <div className="inline-flex items-center justify-center w-14 h-14 rounded-full bg-primary/10 text-primary mb-3">
              <Loader2 className="h-7 w-7 animate-spin" />
            </div>
            <h1 className="text-2xl font-bold font-display text-primary">Abriendo el menú…</h1>
            <p className="text-muted-foreground mt-1">Un momento por favor.</p>
          </>
        )}

        {estado === "sin-menu" && (
          <>
            <div className="inline-flex items-center justify-center w-14 h-14 rounded-full bg-accent/20 text-accent-foreground mb-3">
              <UtensilsCrossed className="h-7 w-7" />
            </div>
            <h1 className="text-2xl font-bold font-display text-primary">
              Menú {sucursal ? `de ${nombreCorto(sucursal)}` : ""}
            </h1>
            <p className="text-muted-foreground mt-2">
              Aún no hay un menú cargado para esta sucursal. Mientras, revisa el menú general.
            </p>
            <Link
              to="/menu"
              className="inline-flex items-center gap-2 mt-6 rounded-xl bg-primary text-primary-foreground font-semibold px-5 py-3"
            >
              <FileText className="h-4 w-4" /> Ver menú general
            </Link>
          </>
        )}

        {estado === "error" && (
          <>
            <h1 className="text-2xl font-bold font-display text-primary">No encontramos la sucursal</h1>
            <p className="text-muted-foreground mt-2">Revisa el código del enlace.</p>
            <Link to="/menu" className="inline-block mt-6 text-primary font-semibold">Ver menú general</Link>
          </>
        )}
      </div>
    </div>
  );
}
