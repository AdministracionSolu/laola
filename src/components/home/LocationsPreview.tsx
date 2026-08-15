import { Link } from "react-router-dom";
import { Button } from "@/components/ui/button";
import { useSucursales, nombreCorto } from "@/lib/sucursales";

export function LocationsPreview() {
  const { sucursales } = useSucursales();

  return (
    <section className="py-16 md:py-24 bg-secondary">
      <div className="container mx-auto px-4">
        <div className="max-w-xl mb-10">
          <p className="text-accent font-medium tracking-wide mb-2">Dónde encontrarnos</p>
          <h2 className="text-3xl md:text-4xl lg:text-5xl font-display font-bold text-foreground leading-tight">
            Nuestras sucursales
          </h2>
          <p className="text-muted-foreground mt-4">
            Cuatro casas entre Tepic y Zapopan, con el mismo sabor de siempre.
          </p>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-px bg-border rounded-2xl overflow-hidden border border-border">
          {sucursales.map((s) => (
            <div key={s.id} className="bg-background p-6 flex flex-col min-h-[180px] hover:bg-primary/[0.03] transition-colors">
              <span className="text-sm text-accent font-semibold">
                {s.contacto?.ciudad ?? ""}
              </span>
              <h3 className="text-2xl font-display font-bold text-foreground mt-1">
                {nombreCorto(s.nombre)}
              </h3>
              <p className="text-sm text-muted-foreground mt-2 leading-relaxed flex-1">
                {s.direccion}
              </p>
              {s.mapaLink && (
                <a
                  href={s.mapaLink}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-sm font-semibold text-primary mt-4 hover:underline"
                >
                  Cómo llegar →
                </a>
              )}
            </div>
          ))}
        </div>

        <div className="mt-8">
          <Button asChild variant="outline" className="border-primary text-primary hover:bg-primary hover:text-primary-foreground">
            <Link to="/sucursales">Ver detalles y horarios</Link>
          </Button>
        </div>
      </div>
    </section>
  );
}
