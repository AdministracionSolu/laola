import { Layout } from "@/components/layout/Layout";
import { Card, CardContent } from "@/components/ui/card";
import { Phone } from "lucide-react";

const sucursales = [
  {
    nombre: "La Ola Del Valle",
    ubicacion: "Tepic, Nayarit",
    telefono: "311 133 0891",
    href: "tel:+523111330891",
  },
  {
    nombre: "La Ola Insurgentes",
    ubicacion: "Tepic, Nayarit",
    telefono: "311 169 3323",
    href: "tel:+523111693323",
  },
  {
    nombre: "La Ola Solares",
    ubicacion: "Zapopan, Jalisco",
    telefono: "33 1789 3505",
    href: "tel:+523317893505",
  },
  {
    nombre: "La Ola Las Brisas",
    ubicacion: "Tepic, Nayarit",
    telefono: "311 217 1395",
    href: "tel:+523112171395",
  },
];

export default function Contacto() {
  return (
    <Layout>
      {/* Hero */}
      <section className="bg-gradient-ocean py-16 md:py-24">
        <div className="container mx-auto px-4 text-center">
          <h1 className="text-4xl md:text-5xl font-display font-bold text-white mb-4">
            Contáctanos
          </h1>
          <p className="text-white/90 text-lg max-w-2xl mx-auto">
            Llámanos directamente a cualquiera de nuestras sucursales
          </p>
        </div>
      </section>

      {/* Sucursales */}
      <section className="py-12 md:py-16 bg-background">
        <div className="container mx-auto px-4">
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6 max-w-5xl mx-auto">
            {sucursales.map((sucursal, index) => (
              <Card key={index} className="hover:shadow-lg transition-shadow">
                <CardContent className="p-6 text-center">
                  <h3 className="font-display font-bold text-foreground text-lg mb-1">
                    {sucursal.nombre}
                  </h3>
                  <p className="text-muted-foreground text-sm mb-4">
                    {sucursal.ubicacion}
                  </p>
                  <a
                    href={sucursal.href}
                    className="inline-flex items-center gap-2 text-primary hover:text-primary/80 font-semibold transition-colors"
                  >
                    <Phone className="w-4 h-4" />
                    {sucursal.telefono}
                  </a>
                </CardContent>
              </Card>
            ))}
          </div>
        </div>
      </section>
    </Layout>
  );
}
