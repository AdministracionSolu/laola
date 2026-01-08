import { Layout } from "@/components/layout/Layout";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { MapPin, Phone, Clock, ExternalLink, Facebook, Download } from "lucide-react";

const locations = [
  {
    id: 1,
    name: "La Ola Del Valle",
    address: "Av del Valle 161, Cd del Valle, 63157",
    city: "Tepic, Nayarit",
    phone: "+52 311 133 0891",
    hours: "10:00 A.M - 23:59 P.M",
    facebook: "https://www.facebook.com/Laolaseafood/?locale=es_LA",
    mapUrl: "https://maps.google.com/?q=Av+del+Valle+161+Tepic+Nayarit",
    embedMap: "https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d3724.5!2d-104.8937!3d21.5051!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x0%3A0x0!2zMjHCsDMwJzE4LjQiTiAxMDTCsDUzJzM3LjMiVw!5e0!3m2!1ses!2smx!4v1700000000000",
    features: ["Privado disponible", "Música en vivo fines de semana"],
    menuPdf: "/menus/menu-del-valle.pdf",
  },
  {
    id: 2,
    name: "La Ola Insurgentes",
    address: "De Los Insurgentes Pte. 233, Versalles, 63000",
    city: "Tepic, Nayarit",
    phone: "+52 311 169 3323",
    hours: "Dom-Mié: 11:00 A.M - 23:59 P.M / Jue-Sáb: 11:00 A.M - 2:00 A.M",
    facebook: "https://www.facebook.com/Laolaseafood/?locale=es_LA",
    mapUrl: "https://maps.google.com/?q=De+Los+Insurgentes+Pte+233+Versalles+Tepic+Nayarit",
    embedMap: "https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d3724.5!2d-104.9001!3d21.5055!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x0%3A0x0!2zMjHCsDMwJzE5LjgiTiAxMDTCsDU0JzAwLjQiVw!5e0!3m2!1ses!2smx!4v1700000000000",
    features: ["Estacionamiento", "Cervecería"],
    menuPdf: "/menus/menu-insurgentes.pdf",
  },
  {
    id: 3,
    name: "La Ola Solares",
    address: "P.° Solares 1639-int: #11 & #12, Solares Residencial, 45019",
    city: "Zapopan, Jalisco",
    phone: "+52 33 1789 3505",
    hours: "11:00 A.M - 20:00 P.M",
    facebook: "https://www.facebook.com/Laolaseafood/?locale=es_LA",
    mapUrl: "https://maps.google.com/?q=Paseo+Solares+1639+Zapopan+Jalisco",
    embedMap: "https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d3724.5!2d-103.4428!3d20.7139!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x0%3A0x0!2zMjDCsDQyJzUwLjAiTiAxMDPCsDI2JzM0LjEiVw!5e0!3m2!1ses!2smx!4v1700000000000",
    features: ["Terraza", "Música en vivo sábados"],
    menuPdf: "/menus/menu-solares.pdf",
  },
  {
    id: 4,
    name: "La Ola Las Brisas",
    address: "De Los Insurgentes Pte. 959, Las Brisas Rodeo de la Punta, 63110",
    city: "Tepic, Nayarit",
    phone: "+52 311 217 1395",
    hours: "10:00 A.M - 18:00 P.M",
    facebook: "https://www.facebook.com/Laolaseafood/?locale=es_LA",
    mapUrl: "https://maps.google.com/?q=De+Los+Insurgentes+Pte+959+Tepic+Nayarit",
    embedMap: "https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d3724.5!2d-104.9156!3d21.4989!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x0%3A0x0!2zMjHCsDI5JzU2LjAiTiAxMDTCsDU0JzU2LjIiVw!5e0!3m2!1ses!2smx!4v1700000000000",
    features: ["Vista al lago", "Área para niños"],
    menuPdf: "/menus/menu-las-brisas.pdf",
  },
];

export default function Sucursales() {
  return (
    <Layout>
      {/* Hero */}
      <section className="bg-gradient-ocean py-16 md:py-24">
        <div className="container mx-auto px-4 text-center">
          <h1 className="text-4xl md:text-5xl font-display font-bold text-white mb-4">
            Nuestras Sucursales
          </h1>
          <p className="text-white/90 text-lg max-w-2xl mx-auto">
            4 ubicaciones en Tepic, Nayarit y Zapopan, Jalisco para disfrutar de nuestros mariscos
          </p>
        </div>
      </section>

      {/* Locations Grid */}
      <section className="py-12 md:py-16 bg-background">
        <div className="container mx-auto px-4">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
            {locations.map((location, index) => (
              <Card 
                key={location.id} 
                className="overflow-hidden hover:shadow-xl transition-all duration-300 animate-fade-in"
                style={{ animationDelay: `${index * 0.1}s` }}
              >
                <CardContent className="p-0">
                  {/* Embedded Google Map */}
                  <div className="h-48 relative overflow-hidden">
                    <iframe
                      src={location.embedMap}
                      width="100%"
                      height="100%"
                      style={{ border: 0 }}
                      allowFullScreen
                      loading="lazy"
                      referrerPolicy="no-referrer-when-downgrade"
                      title={`Mapa de ${location.name}`}
                      className="absolute inset-0"
                    />
                  </div>

                  {/* Content */}
                  <div className="p-6">
                    <h2 className="text-xl font-display font-bold text-foreground mb-2">
                      {location.name}
                    </h2>
                    <p className="text-accent font-medium text-sm mb-4">
                      {location.city}
                    </p>

                    <div className="space-y-3 mb-6">
                      <div className="flex items-start gap-3">
                        <MapPin className="w-5 h-5 text-primary mt-0.5 flex-shrink-0" />
                        <p className="text-muted-foreground text-sm">
                          {location.address}
                        </p>
                      </div>

                      <div className="flex items-center gap-3">
                        <Phone className="w-5 h-5 text-primary flex-shrink-0" />
                        <a
                          href={`tel:${location.phone.replace(/\s/g, "")}`}
                          className="text-foreground hover:text-primary transition-colors font-medium"
                        >
                          {location.phone}
                        </a>
                      </div>

                      <div className="flex items-start gap-3">
                        <Clock className="w-5 h-5 text-primary mt-0.5 flex-shrink-0" />
                        <p className="text-sm text-muted-foreground">
                          {location.hours}
                        </p>
                      </div>
                    </div>

                    {/* Features */}
                    <div className="flex flex-wrap gap-2 mb-6">
                      {location.features.map((feature, i) => (
                        <span
                          key={i}
                          className="px-3 py-1 bg-secondary text-secondary-foreground rounded-full text-xs font-medium"
                        >
                          {feature}
                        </span>
                      ))}
                    </div>

                    {/* Actions */}
                    <div className="flex flex-wrap gap-3">
                      <Button asChild size="sm" className="bg-accent hover:bg-coral-light text-accent-foreground">
                        <a href={location.mapUrl} target="_blank" rel="noopener noreferrer">
                          <MapPin className="w-4 h-4 mr-1" />
                          Cómo llegar
                        </a>
                      </Button>
                      <Button asChild size="sm" variant="outline" className="border-primary text-primary hover:bg-primary hover:text-primary-foreground">
                        <a href={location.menuPdf} target="_blank" rel="noopener noreferrer">
                          <Download className="w-4 h-4 mr-1" />
                          Menú
                        </a>
                      </Button>
                      <Button asChild size="sm" variant="ghost" className="text-muted-foreground hover:text-primary">
                        <a href={location.facebook} target="_blank" rel="noopener noreferrer">
                          <Facebook className="w-4 h-4 mr-1" />
                          Facebook
                        </a>
                      </Button>
                    </div>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        </div>
      </section>

      {/* Private Events CTA */}
      <section className="py-12 md:py-16 bg-secondary">
        <div className="container mx-auto px-4 text-center">
          <h2 className="text-2xl md:text-3xl font-display font-bold text-foreground mb-4">
            ¿Buscas un espacio para tu evento?
          </h2>
          <p className="text-muted-foreground mb-6 max-w-xl mx-auto">
            Contamos con áreas privadas y cervecería en algunas sucursales. 
            Contáctanos para más información.
          </p>
          <Button asChild className="bg-primary hover:bg-ocean-light text-primary-foreground">
            <a href="/contacto">
              Solicitar Información
              <ExternalLink className="w-4 h-4 ml-2" />
            </a>
          </Button>
        </div>
      </section>
    </Layout>
  );
}
