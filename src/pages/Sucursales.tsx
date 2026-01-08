import { Layout } from "@/components/layout/Layout";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { MapPin, Phone, Clock, ExternalLink, Facebook } from "lucide-react";

const locations = [
  {
    id: 1,
    name: "La Ola Del Valle",
    address: "Calle San Borja #1076, Col Del Valle Centro",
    city: "Ciudad de México",
    phone: "55 5524 6403",
    hours: {
      weekdays: "12:00 PM - 7:00 PM",
      saturday: "12:00 PM - 7:00 PM",
      sunday: "12:00 PM - 6:00 PM",
    },
    facebook: "https://facebook.com/laoladelvalle",
    mapUrl: "https://maps.google.com/?q=Calle+San+Borja+1076+Del+Valle+CDMX",
    features: ["Privado disponible", "Música en vivo fines de semana"],
  },
  {
    id: 2,
    name: "La Ola Insurgentes",
    address: "Av. Insurgentes Sur 1809, Guadalupe Inn",
    city: "Ciudad de México",
    phone: "55 5662 4567",
    hours: {
      weekdays: "12:00 PM - 7:00 PM",
      saturday: "12:00 PM - 7:00 PM",
      sunday: "12:00 PM - 6:00 PM",
    },
    facebook: "https://facebook.com/laolainsurgentes",
    mapUrl: "https://maps.google.com/?q=Insurgentes+Sur+1809+Guadalupe+Inn+CDMX",
    features: ["Estacionamiento", "Cervecería"],
  },
  {
    id: 3,
    name: "La Ola Solares",
    address: "Av. Himno Nacional 69",
    city: "Cuernavaca, Morelos",
    phone: "777 318 3456",
    hours: {
      weekdays: "11:00 AM - 8:00 PM",
      saturday: "11:00 AM - 8:00 PM",
      sunday: "11:00 AM - 7:00 PM",
    },
    facebook: "https://facebook.com/laolasolares",
    mapUrl: "https://maps.google.com/?q=Himno+Nacional+69+Cuernavaca",
    features: ["Terraza", "Música en vivo sábados"],
  },
  {
    id: 4,
    name: "La Ola Las Brisas",
    address: "Av. Del Lago 57, Col Las Brisas",
    city: "Cuernavaca, Morelos",
    phone: "777 362 7890",
    hours: {
      weekdays: "11:00 AM - 8:00 PM",
      saturday: "11:00 AM - 9:00 PM",
      sunday: "11:00 AM - 7:00 PM",
    },
    facebook: "https://facebook.com/laolabrisas",
    mapUrl: "https://maps.google.com/?q=Del+Lago+57+Las+Brisas+Cuernavaca",
    features: ["Vista al lago", "Área para niños"],
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
            4 ubicaciones en la Ciudad de México y Cuernavaca para disfrutar de nuestros mariscos
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
                  {/* Map placeholder */}
                  <div className="h-48 bg-secondary relative overflow-hidden">
                    <div className="absolute inset-0 flex items-center justify-center bg-primary/5">
                      <MapPin className="w-12 h-12 text-primary/30" />
                    </div>
                    <a
                      href={location.mapUrl}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="absolute inset-0 flex items-center justify-center bg-primary/0 hover:bg-primary/10 transition-colors"
                    >
                      <span className="sr-only">Ver en Google Maps</span>
                    </a>
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
                        <div className="text-sm text-muted-foreground">
                          <p>Lun-Vie: {location.hours.weekdays}</p>
                          <p>Sáb: {location.hours.saturday}</p>
                          <p>Dom: {location.hours.sunday}</p>
                        </div>
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
