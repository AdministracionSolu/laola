import { Layout } from "@/components/layout/Layout";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { MapPin, Phone, Clock, ExternalLink, Facebook, UtensilsCrossed } from "lucide-react";
import { useSucursales } from "@/lib/sucursales";

export default function Sucursales() {
  const { sucursales } = useSucursales();

  return (
    <Layout>
      {/* Hero */}
      <section className="bg-gradient-ocean py-16 md:py-24">
        <div className="container mx-auto px-4 text-center">
          <h1 className="text-4xl md:text-6xl font-display font-bold text-white mb-4">
            Nuestras sucursales
          </h1>
          <p className="text-white/90 text-lg max-w-2xl mx-auto">
            Cuatro ubicaciones entre Tepic, Nayarit y Zapopan, Jalisco.
          </p>
        </div>
      </section>

      {/* Locations Grid */}
      <section className="py-12 md:py-16 bg-background">
        <div className="container mx-auto px-4">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
            {sucursales.map((s) => (
              <Card key={s.id} className="overflow-hidden hover:shadow-xl transition-all duration-300">
                <CardContent className="p-0">
                  {/* Mapa embebido */}
                  {s.mapaEmbed && (
                    <div className="h-52 relative overflow-hidden">
                      <iframe
                        src={s.mapaEmbed}
                        width="100%"
                        height="100%"
                        style={{ border: 0 }}
                        allowFullScreen
                        loading="lazy"
                        referrerPolicy="no-referrer-when-downgrade"
                        title={`Mapa de La Ola ${s.nombre}`}
                        className="absolute inset-0"
                      />
                    </div>
                  )}

                  <div className="p-6">
                    <h2 className="text-2xl font-display font-bold text-foreground">
                      La Ola {s.nombre}
                    </h2>
                    <p className="text-accent font-medium text-sm mb-4">
                      {s.contacto?.ciudad}
                    </p>

                    <div className="space-y-3 mb-6">
                      <div className="flex items-start gap-3">
                        <MapPin className="w-5 h-5 text-primary mt-0.5 flex-shrink-0" />
                        <p className="text-muted-foreground text-sm">{s.direccion}</p>
                      </div>

                      {s.contacto?.telefono && (
                        <div className="flex items-center gap-3">
                          <Phone className="w-5 h-5 text-primary flex-shrink-0" />
                          <a
                            href={`tel:${s.contacto.telefono.replace(/\s/g, "")}`}
                            className="text-foreground hover:text-primary transition-colors font-medium"
                          >
                            {s.contacto.telefono}
                          </a>
                        </div>
                      )}

                      {s.contacto?.horario && (
                        <div className="flex items-start gap-3">
                          <Clock className="w-5 h-5 text-primary mt-0.5 flex-shrink-0" />
                          <p className="text-sm text-muted-foreground">{s.contacto.horario}</p>
                        </div>
                      )}
                    </div>

                    {/* Amenidades */}
                    {s.contacto?.amenidades?.length ? (
                      <div className="flex flex-wrap gap-2 mb-6">
                        {s.contacto.amenidades.map((a) => (
                          <span
                            key={a}
                            className="px-3 py-1 bg-secondary text-secondary-foreground rounded-md text-xs font-medium"
                          >
                            {a}
                          </span>
                        ))}
                      </div>
                    ) : null}

                    {/* Acciones */}
                    <div className="flex flex-wrap gap-3">
                      {s.mapaLink && (
                        <Button asChild size="sm" className="bg-accent hover:bg-coral-light text-accent-foreground">
                          <a href={s.mapaLink} target="_blank" rel="noopener noreferrer">
                            <MapPin className="w-4 h-4 mr-1" />
                            Cómo llegar
                          </a>
                        </Button>
                      )}
                      <Button asChild size="sm" variant="outline" className="border-primary text-primary hover:bg-primary hover:text-primary-foreground">
                        <a href={s.menuLink} target="_blank" rel="noopener noreferrer">
                          <UtensilsCrossed className="w-4 h-4 mr-1" />
                          Menú
                        </a>
                      </Button>
                      {s.contacto?.facebook && (
                        <Button asChild size="sm" variant="ghost" className="text-muted-foreground hover:text-primary">
                          <a href={s.contacto.facebook} target="_blank" rel="noopener noreferrer">
                            <Facebook className="w-4 h-4 mr-1" />
                            Facebook
                          </a>
                        </Button>
                      )}
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
            Tenemos áreas privadas y cervecería en algunas sucursales. Cuéntanos qué necesitas.
          </p>
          <Button asChild className="bg-primary hover:bg-ocean-light text-primary-foreground">
            <a href="/contacto">
              Solicitar información
              <ExternalLink className="w-4 h-4 ml-2" />
            </a>
          </Button>
        </div>
      </section>
    </Layout>
  );
}
