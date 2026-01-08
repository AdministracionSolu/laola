import { Calendar, Music, Users } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Link } from "react-router-dom";

export function EventsSection() {
  return (
    <section className="py-16 md:py-24 bg-secondary">
      <div className="container mx-auto px-4">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
          {/* Content */}
          <div>
            <span className="text-accent font-medium text-sm uppercase tracking-wider">
              Eventos & Música en Vivo
            </span>
            <h2 className="text-3xl md:text-4xl font-display font-bold text-foreground mt-2 mb-6">
              Más que un restaurante, una experiencia
            </h2>
            <p className="text-muted-foreground mb-8 leading-relaxed">
              En La Ola no solo disfrutas de los mejores mariscos, también vives momentos inolvidables. 
              Contamos con música en vivo los fines de semana y un espacio privado perfecto para tus celebraciones.
            </p>

            <div className="space-y-4 mb-8">
              <div className="flex items-start gap-4">
                <div className="w-12 h-12 rounded-full bg-primary/10 flex items-center justify-center flex-shrink-0">
                  <Music className="w-6 h-6 text-primary" />
                </div>
                <div>
                  <h3 className="font-semibold text-foreground">Música en Vivo</h3>
                  <p className="text-sm text-muted-foreground">
                    Viernes y sábados a partir de las 3:00 PM
                  </p>
                </div>
              </div>

              <div className="flex items-start gap-4">
                <div className="w-12 h-12 rounded-full bg-accent/10 flex items-center justify-center flex-shrink-0">
                  <Users className="w-6 h-6 text-accent" />
                </div>
                <div>
                  <h3 className="font-semibold text-foreground">Privado / Cervecería</h3>
                  <p className="text-sm text-muted-foreground">
                    Espacio exclusivo para eventos y celebraciones
                  </p>
                </div>
              </div>

              <div className="flex items-start gap-4">
                <div className="w-12 h-12 rounded-full bg-primary/10 flex items-center justify-center flex-shrink-0">
                  <Calendar className="w-6 h-6 text-primary" />
                </div>
                <div>
                  <h3 className="font-semibold text-foreground">Eventos Especiales</h3>
                  <p className="text-sm text-muted-foreground">
                    Cumpleaños, reuniones de empresa y más
                  </p>
                </div>
              </div>
            </div>

            <Button asChild className="bg-accent hover:bg-coral-light text-accent-foreground">
              <Link to="/contacto">
                Contáctanos para tu evento
              </Link>
            </Button>
          </div>

          {/* Image */}
          <div className="relative">
            <div className="aspect-[4/3] rounded-2xl overflow-hidden shadow-2xl">
              <img
                src="https://images.unsplash.com/photo-1514933651103-005eec06c04b?w=800&h=600&fit=crop"
                alt="Ambiente del restaurante con música en vivo"
                className="w-full h-full object-cover"
              />
            </div>
            {/* Decorative element */}
            <div className="absolute -bottom-6 -left-6 w-24 h-24 bg-accent rounded-2xl -z-10" />
            <div className="absolute -top-6 -right-6 w-32 h-32 bg-primary/20 rounded-full -z-10" />
          </div>
        </div>
      </div>
    </section>
  );
}
