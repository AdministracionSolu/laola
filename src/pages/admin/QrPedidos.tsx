import { useEffect, useState, useMemo } from "react";
import { useNavigate } from "react-router-dom";
import { QRCodeSVG } from "qrcode.react";
import jsPDF from "jspdf";
import QRCode from "qrcode";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { ArrowLeft, Printer, Loader2, Download } from "lucide-react";
import logoLaOla from "@/assets/logo-la-ola.jpeg";

interface Sucursal {
  id: string;
  nombre: string;
}
interface Tarjeta {
  key: string;
  sucursal: string;
  accion: string;
  sub: string;
  url: string;
}

export default function QrPedidos() {
  const navigate = useNavigate();
  const [sucursales, setSucursales] = useState<Sucursal[]>([]);
  const [loading, setLoading] = useState(true);
  const [tipo, setTipo] = useState<"ambos" | "pedido" | "recepcion">("ambos");
  const [generando, setGenerando] = useState(false);
  const origin = typeof window !== "undefined" ? window.location.origin : "";

  const tarjetas: Tarjeta[] = useMemo(
    () =>
      sucursales.flatMap((s) => {
        const out: Tarjeta[] = [];
        if (tipo === "ambos" || tipo === "pedido")
          out.push({ key: `${s.id}-p`, sucursal: s.nombre, accion: "Hacer pedido", sub: "Escanea para hacer el pedido", url: `${origin}/pedidos/s/${s.id}` });
        if (tipo === "ambos" || tipo === "recepcion")
          out.push({ key: `${s.id}-r`, sucursal: s.nombre, accion: "Registrar lo que llegó", sub: "Escanea cuando llegue la mercancía", url: `${origin}/recepcion/s/${s.id}` });
        return out;
      }),
    [sucursales, tipo, origin]
  );

  const descargarPDF = async () => {
    if (tarjetas.length === 0) return;
    setGenerando(true);
    try {
      const doc = new jsPDF({ unit: "mm", format: "a4" });
      const cx = 105;
      for (let i = 0; i < tarjetas.length; i++) {
        const t = tarjetas[i];
        if (i > 0) doc.addPage();
        const dataUrl = await QRCode.toDataURL(t.url, { width: 900, margin: 2 });
        doc.setFontSize(14);
        doc.setTextColor(120);
        doc.text(`La Ola — ${t.accion}`, cx, 45, { align: "center" });
        doc.setFontSize(36);
        doc.setTextColor(0);
        doc.text(t.sucursal, cx, 60, { align: "center" });
        const qr = 110;
        doc.addImage(dataUrl, "PNG", cx - qr / 2, 80, qr, qr);
        doc.setFontSize(16);
        doc.text(t.sub, cx, 205, { align: "center" });
      }
      doc.save(`QR_laola_${tipo}.pdf`);
    } finally {
      setGenerando(false);
    }
  };

  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => {
      if (!session) {
        navigate("/admin/login");
        return;
      }
      supabase
        .from("sucursales")
        .select("id, nombre")
        .order("nombre")
        .then(({ data }) => {
          setSucursales((data ?? []) as Sucursal[]);
          setLoading(false);
        });
    });
  }, [navigate]);

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <Loader2 className="h-8 w-8 animate-spin text-primary" />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-primary/5 to-secondary/10">
      {/* Barra (se oculta al imprimir) */}
      <div className="bg-background border-b sticky top-0 z-10 print:hidden">
        <div className="container mx-auto px-3 py-2 flex items-center gap-3">
          <Button variant="ghost" size="icon" onClick={() => navigate("/admin/dashboard")}>
            <ArrowLeft className="h-5 w-5" />
          </Button>
          <div className="flex-1">
            <h1 className="text-base font-semibold">QR por sucursal</h1>
            <p className="text-xs text-muted-foreground">Imprime, plastifica y pégalos en cada cocina</p>
          </div>
          <Button variant="outline" className="gap-2" onClick={descargarPDF} disabled={generando || tarjetas.length === 0}>
            {generando ? <Loader2 className="h-4 w-4 animate-spin" /> : <Download className="h-4 w-4" />} Guardar PDF
          </Button>
          <Button className="gap-2" onClick={() => window.print()}>
            <Printer className="h-4 w-4" /> Imprimir
          </Button>
        </div>
      </div>

      <div className="container mx-auto px-3 py-4 max-w-4xl">
        <div className="flex items-center gap-2 mb-4 print:hidden">
          <span className="text-sm text-muted-foreground">Imprimir:</span>
          {([
            ["ambos", "Ambos"],
            ["pedido", "Solo Pedido"],
            ["recepcion", "Solo Recepción"],
          ] as const).map(([k, label]) => (
            <Button key={k} size="sm" variant={tipo === k ? "default" : "outline"} onClick={() => setTipo(k)}>
              {label}
            </Button>
          ))}
        </div>
        <p className="text-sm text-muted-foreground mb-4 print:hidden">
          Cada QR fija la sucursal (no se puede cambiar) y abre directo su acción. Al imprimir,
          sale uno por hoja.
        </p>
        <div className="grid sm:grid-cols-2 gap-4 print:block">
          {tarjetas.map((t) => (
            <Card
              key={t.key}
              className="print:break-after-page print:shadow-none print:border-2 print:min-h-screen print:flex print:items-center"
            >
              <CardContent className="p-6 flex flex-col items-center text-center gap-3 w-full">
                <img src={logoLaOla} alt="La Ola" className="w-14 h-14 rounded-full object-cover" />
                <div>
                  <p className="text-sm text-muted-foreground">La Ola — {t.accion}</p>
                  <h2 className="text-3xl font-bold">{t.sucursal}</h2>
                </div>
                <div className="bg-white p-3 rounded-lg border">
                  <QRCodeSVG value={t.url} size={220} level="M" marginSize={2} />
                </div>
                <p className="text-base font-medium">{t.sub}</p>
                {/* URL solo en pantalla (admin), nunca en impresión/PDF */}
                <p className="text-xs text-muted-foreground break-all print:hidden">{t.url}</p>
              </CardContent>
            </Card>
          ))}
        </div>
      </div>
    </div>
  );
}
