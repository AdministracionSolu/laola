import { Layout } from "@/components/layout/Layout";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Download, ExternalLink, Scale } from "lucide-react";
const branches = [{
  id: "del-valle",
  name: "Del Valle",
  pdfUrl: "/menus/menu-del-valle.pdf"
}, {
  id: "insurgentes",
  name: "Insurgentes",
  pdfUrl: "/menus/menu-insurgentes.pdf"
}, {
  id: "solares",
  name: "Solares",
  pdfUrl: "/menus/menu-solares.pdf"
}, {
  id: "las-brisas",
  name: "Las Brisas",
  pdfUrl: "/menus/menu-las-brisas.pdf"
}];
const menuKilos = [{
  name: "Marlín en estofado",
  precio500g: 95,
  precioKg: 190
}, {
  name: "Paté de camarón",
  precio500g: 195,
  precioKg: 360
}, {
  name: "Ceviche de pescado",
  precio500g: 95,
  precioKg: 190
}, {
  name: "Ceviche de camarón",
  precio500g: 195,
  precioKg: 360
}, {
  name: "Ceviche especial La Ola",
  precio500g: 195,
  precioKg: 390
}, {
  name: "Ceviche de camarón seco",
  precio500g: 195,
  precioKg: 390
}, {
  name: "Ceviche Mexcalteca",
  precio500g: 195,
  precioKg: 360
}, {
  name: "Ceviche negro de atún",
  precio500g: 195,
  precioKg: 390
}, {
  name: "Aguachile de camarón",
  precio500g: 195,
  precioKg: 360
}, {
  name: "Aguachile Mexcalteca",
  precio500g: 195,
  precioKg: 390
}, {
  name: "Aguachile especial La Ola",
  precio500g: 195,
  precioKg: 390
}];
const menuHighlights = [{
  id: "tostadas",
  name: "Tostadas",
  items: [{
    name: "Tostada Especial San Blas",
    description: "Mariscos frescos del Pacífico",
    price: "$95"
  }, {
    name: "Tostada de Paté de Camarón",
    description: "Paté de camarón sobre tostada crujiente",
    price: "$85"
  }, {
    name: "Tostada de Ceviche",
    description: "Ceviche de pescado fresco",
    price: "$75"
  }, {
    name: "Tostada de Pulpo",
    description: "Pulpo marinado con especias",
    price: "$105"
  }]
}, {
  id: "vasos",
  name: "Vasos & Cocteles",
  items: [{
    name: "Vaso Macho",
    description: "Nuestro clásico coctel de mariscos",
    price: "$145"
  }, {
    name: "Vaso de Camarón",
    description: "Camarones frescos en salsa",
    price: "$125"
  }, {
    name: "Campechana",
    description: "Mezcla de mariscos en coctel",
    price: "$155"
  }, {
    name: "Vuelve a la Vida",
    description: "La cura perfecta",
    price: "$135"
  }]
}, {
  id: "aguachiles",
  name: "Aguachiles",
  items: [{
    name: "Aguachile Verde",
    description: "Camarones en salsa de chile verde",
    price: "$165"
  }, {
    name: "Aguachile Negro",
    description: "Con salsa de chile negro ahumado",
    price: "$175"
  }, {
    name: "Aguachile Rojo",
    description: "Picante y refrescante",
    price: "$165"
  }, {
    name: "Aguachile de Pulpo",
    description: "Pulpo fresco en aguachile",
    price: "$185"
  }]
}, {
  id: "especialidades",
  name: "Especialidades",
  items: [{
    name: "Camarones a la Diabla",
    description: "Camarones en salsa picante",
    price: "$195"
  }, {
    name: "Pescado Zarandeado",
    description: "Estilo Nayarit",
    price: "$285"
  }, {
    name: "Mojarra Frita",
    description: "Mojarra entera dorada",
    price: "$225"
  }, {
    name: "Torre de Mariscos",
    description: "Para compartir (2-3 personas)",
    price: "$395"
  }]
}];
export default function Menu() {
  return <Layout>
      {/* Hero */}
      <section className="bg-gradient-ocean py-16 md:py-24">
        <div className="container mx-auto px-4 text-center">
          <h1 className="text-4xl md:text-5xl font-display font-bold text-white mb-4">
            Nuestro Menú
          </h1>
          <p className="text-white/90 text-lg max-w-2xl mx-auto">
            Sabores auténticos de la costa del Pacífico, preparados con ingredientes frescos del día
          </p>
        </div>
      </section>

      {/* Menu por Kilos - Para Llevar */}
      <section className="py-8 bg-accent/10 border-b border-border">
        <div className="container mx-auto px-4">
          <div className="flex flex-col md:flex-row items-center justify-center gap-4">
            <div className="text-center md:text-left">
              <h2 className="text-lg font-semibold text-foreground flex items-center justify-center md:justify-start gap-2">
                <Scale className="w-5 h-5 text-accent" />
                Menú por Kilos - Para Llevar
              </h2>
              <p className="text-sm text-muted-foreground">
                Disponible en todas las sucursales
              </p>
            </div>
            <Button asChild className="bg-accent hover:bg-coral-light text-accent-foreground">
              <a href="/menus/menu-kilos.pdf" target="_blank" rel="noopener noreferrer">
                <Download className="w-4 h-4 mr-2" />
                Descargar Menú por Kilos
              </a>
            </Button>
          </div>
        </div>
      </section>

      {/* Branch Selector & Download */}
      <section className="py-8 bg-secondary border-b border-border">
        <div className="container mx-auto px-4">
          <h2 className="text-center text-lg font-semibold text-foreground mb-4">
            Descarga el menú de tu sucursal
          </h2>
          <div className="flex flex-wrap justify-center gap-3">
            {branches.map(branch => <Button key={branch.id} asChild variant="outline" className="border-primary text-primary hover:bg-primary hover:text-primary-foreground">
                <a href={branch.pdfUrl} target="_blank" rel="noopener noreferrer">
                  <Download className="w-4 h-4 mr-2" />
                  {branch.name}
                </a>
              </Button>)}
          </div>
        </div>
      </section>

      {/* Menu Highlights */}
      

      {/* Gallery CTA */}
      <section className="py-12 bg-secondary">
        <div className="container mx-auto px-4 text-center">
          <h2 className="text-2xl font-display font-bold text-foreground mb-4">
            ¿Se te antoja?
          </h2>
          <p className="text-muted-foreground mb-6">
            Visítanos en cualquiera de nuestras sucursales
          </p>
          <Button asChild className="bg-accent hover:bg-coral-light text-accent-foreground">
            <a href="/sucursales">
              Ver Sucursales
              <ExternalLink className="w-4 h-4 ml-2" />
            </a>
          </Button>
        </div>
      </section>
    </Layout>;
}