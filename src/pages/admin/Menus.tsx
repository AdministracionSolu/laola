import { useEffect, useRef, useState } from "react";
import { useNavigate } from "react-router-dom";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { toast } from "sonner";
import { ArrowLeft, RefreshCw, UploadCloud, ExternalLink, Loader2, Link2, Trash2, QrCode } from "lucide-react";
import logoLaOla from "@/assets/logo-la-ola.jpeg";

type Sucursal = { id: string; nombre: string; prefijo_folio: string | null; menu_url: string | null };

const db = supabase as any;
// "Del Valle" se muestra como "Valle" (igual que en los QR de pedidos).
const nombreCorto = (n: string) => n.replace(/^Del\s+/i, "");

export default function AdminMenus() {
  const navigate = useNavigate();
  const [cargando, setCargando] = useState(true);
  const [rows, setRows] = useState<Sucursal[]>([]);
  const [ocupada, setOcupada] = useState<string | null>(null); // id de la sucursal en proceso
  const inputs = useRef<Record<string, HTMLInputElement | null>>({});
  const origin = typeof window !== "undefined" ? window.location.origin : "";

  useEffect(() => {
    (async () => {
      const { data: { session } } = await supabase.auth.getSession();
      if (!session) { navigate("/admin/login"); return; }
      await cargar();
    })();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const cargar = async () => {
    setCargando(true);
    const { data, error } = await db
      .from("sucursales")
      .select("id,nombre,prefijo_folio,menu_url")
      .order("nombre");
    if (error) toast.error("No pudimos cargar las sucursales.");
    setRows((data ?? []) as Sucursal[]);
    setCargando(false);
  };

  const guardarUrl = async (s: Sucursal, url: string) => {
    setOcupada(s.id);
    const { error } = await db.rpc("sucursal_set_menu", { p_sucursal_id: s.id, p_menu_url: url || null });
    setOcupada(null);
    if (error) return toast.error("No se pudo guardar el menú.");
    setRows((p) => p.map((x) => (x.id === s.id ? { ...x, menu_url: url || null } : x)));
    toast.success(url ? "Menú actualizado." : "Menú quitado.");
  };

  const subirPDF = async (s: Sucursal, file: File) => {
    if (file.type !== "application/pdf") { toast.error("El menú debe ser un PDF."); return; }
    if (file.size > 20 * 1024 * 1024) { toast.error("El PDF pesa más de 20 MB."); return; }
    setOcupada(s.id);
    const code = (s.prefijo_folio || s.id).toLowerCase();
    const path = `${code}/${crypto.randomUUID()}.pdf`;
    const up = await supabase.storage.from("menus").upload(path, file, {
      contentType: "application/pdf",
      upsert: false,
    });
    if (up.error) {
      setOcupada(null);
      toast.error("No pudimos subir el PDF. Intenta de nuevo.");
      return;
    }
    const { data: pub } = supabase.storage.from("menus").getPublicUrl(path);
    await guardarUrl(s, pub.publicUrl); // guardarUrl limpia 'ocupada'
  };

  if (cargando) {
    return <div className="min-h-screen flex items-center justify-center"><div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary" /></div>;
  }

  return (
    <div className="min-h-screen bg-background">
      <header className="bg-card border-b sticky top-0 z-50">
        <div className="container mx-auto px-4 py-4 flex items-center justify-between gap-2">
          <div className="flex items-center gap-3 min-w-0">
            <Button variant="ghost" size="icon" onClick={() => navigate("/admin/dashboard")}><ArrowLeft className="w-5 h-5" /></Button>
            <img src={logoLaOla} alt="La Ola" className="w-10 h-10 rounded-full object-cover shrink-0" />
            <h1 className="text-xl font-bold truncate">Menús por sucursal</h1>
          </div>
          <div className="flex items-center gap-2">
            <Button variant="outline" onClick={() => navigate("/admin/qr-pedidos")} className="gap-2">
              <QrCode className="w-4 h-4" /><span className="hidden sm:inline">QR</span>
            </Button>
            <Button variant="outline" size="icon" onClick={cargar}><RefreshCw className="w-4 h-4" /></Button>
          </div>
        </div>
      </header>

      <main className="container mx-auto px-4 py-6 space-y-4 max-w-3xl">
        <p className="text-sm text-muted-foreground">
          Sube el PDF del menú de cada sucursal o pega una liga. El QR impreso apunta a una dirección fija
          (<span className="font-mono">/menu/s/&lt;código&gt;</span>), así que <b>no hay que reimprimirlo</b> cuando cambie el menú: solo actualiza aquí.
        </p>

        {rows.map((s) => {
          const code = s.prefijo_folio?.toUpperCase() || "—";
          const qrUrl = s.prefijo_folio ? `${origin}/menu/s/${s.prefijo_folio.toUpperCase()}` : null;
          const busy = ocupada === s.id;
          return (
            <Card key={s.id}>
              <CardContent className="p-4 space-y-3">
                <div className="flex items-center justify-between gap-2">
                  <div className="flex items-center gap-2 min-w-0">
                    <span className="font-semibold truncate">{nombreCorto(s.nombre)}</span>
                    <Badge variant="secondary" className="shrink-0 font-mono">{code}</Badge>
                  </div>
                  {s.menu_url ? (
                    <a href={s.menu_url} target="_blank" rel="noopener noreferrer"
                       className="inline-flex items-center gap-1 text-sm text-primary font-medium shrink-0">
                      <ExternalLink className="w-3.5 h-3.5" /> Ver menú actual
                    </a>
                  ) : (
                    <span className="text-xs text-muted-foreground shrink-0">Sin menú cargado</span>
                  )}
                </div>

                {qrUrl && (
                  <p className="text-[11px] text-muted-foreground font-mono break-all">{qrUrl}</p>
                )}

                <div className="flex flex-col sm:flex-row gap-2">
                  <input
                    ref={(el) => (inputs.current[s.id] = el)}
                    type="file" accept="application/pdf" className="sr-only"
                    onChange={(e) => { const f = e.target.files?.[0]; e.target.value = ""; if (f) subirPDF(s, f); }}
                  />
                  <Button
                    variant="default" className="gap-2 flex-1" disabled={busy}
                    onClick={() => inputs.current[s.id]?.click()}
                  >
                    {busy ? <Loader2 className="w-4 h-4 animate-spin" /> : <UploadCloud className="w-4 h-4" />}
                    Subir / reemplazar PDF
                  </Button>
                  <PegarUrl disabled={busy} onGuardar={(u) => guardarUrl(s, u)} />
                  {s.menu_url && (
                    <Button variant="outline" size="icon" disabled={busy}
                      onClick={() => guardarUrl(s, "")} title="Quitar menú">
                      <Trash2 className="w-4 h-4" />
                    </Button>
                  )}
                </div>
              </CardContent>
            </Card>
          );
        })}
      </main>
    </div>
  );
}

// Pega una liga externa (Drive, Canva, etc.) como menú.
function PegarUrl({ onGuardar, disabled }: { onGuardar: (u: string) => void; disabled?: boolean }) {
  const [abierto, setAbierto] = useState(false);
  const [url, setUrl] = useState("");
  if (!abierto) {
    return (
      <Button variant="outline" className="gap-2" disabled={disabled} onClick={() => setAbierto(true)}>
        <Link2 className="w-4 h-4" /> Pegar liga
      </Button>
    );
  }
  return (
    <div className="flex gap-2 flex-1">
      <Input
        autoFocus value={url} onChange={(e) => setUrl(e.target.value)}
        placeholder="https://…" className="h-10"
        onKeyDown={(e) => { if (e.key === "Enter" && url.trim()) { onGuardar(url.trim()); setAbierto(false); setUrl(""); } }}
      />
      <Button disabled={disabled || !url.trim()} onClick={() => { onGuardar(url.trim()); setAbierto(false); setUrl(""); }}>
        Guardar
      </Button>
    </div>
  );
}
