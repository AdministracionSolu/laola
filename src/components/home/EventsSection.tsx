import { Button } from "@/components/ui/button";
import { Link } from "react-router-dom";
import zonaPrivada from "@/assets/zona-privada.jpeg";

const experiencias = [
  { titulo: "Música en vivo", detalle: "Viernes y sábados desde las 3:00 PM" },
  { titulo: "Privado y cervecería", detalle: "Un espacio aparte para tu celebración" },
  { titulo: "Eventos especiales", detalle: "Cumpleaños, empresa y fechas importantes" },
];

export function EventsSection() {
  return (
    <section className="py-16 md:py-24 bg-secondary">
      <div className="container mx-auto px-4">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
          {/* Content */}
          <div>
            <p className="text-accent font-medium tracking-wide mb-2">Eventos y música en vivo</p>
            <h2 className="text-3xl md:text-4xl lg:text-5xl font-display font-bold text-foreground leading-tight mb-6">
              Más que un restaurante, una experiencia
            </h2>
            <p className="text-muted-foreground mb-8 leading-relaxed">
              En La Ola comes de los mejores mariscos y te quedas por el ambiente: música
              en vivo los fines de semana y un espacio privado para lo que quieras celebrar.
            </p>

            <div className="divide-y divide-border border-y border-border mb-8">
              {experiencias.map((e) => (
                <div key={e.titulo} className="py-4 flex items-baseline justify-between gap-4">
                  <h3 className="font-display font-bold text-lg text-foreground">{e.titulo}</h3>
                  <p className="text-sm text-muted-foreground text-right">{e.detalle}</p>
                </div>
              ))}
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
                src={zonaPrivada}
                alt="Zona privada y cervecería de La Ola con botellas premium"
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
