import { Layout } from "@/components/layout/Layout";
import { Button } from "@/components/ui/button";
import { Link } from "react-router-dom";
import { useSucursales, nombreCorto } from "@/lib/sucursales";
import { FeaturedDishes } from "@/components/home/FeaturedDishes";
import restauranteComedor from "@/assets/restaurante-comedor.jpeg";

export default function Menu() {
  const { sucursales, cargando } = useSucursales();

  return (
    <Layout>
      {/* Hero */}
      <section className="bg-gradient-ocean py-16 md:py-24">
        <div className="container mx-auto px-4 text-center">
          <h1 className="text-4xl md:text-6xl font-display font-bold text-white mb-4">
            Nuestro menú
          </h1>
          <p className="text-white/90 text-lg max-w-2xl mx-auto">
            Sabores de la costa del Pacífico, con producto fresco del día.
          </p>
        </div>
      </section>

      {/* Menú por sucursal — SIEMPRE el vigente que se carga en Admin */}
      <section className="py-16 md:py-20 bg-background">
        <div className="container mx-auto px-4">
          <div className="max-w-xl mb-10">
            <p className="text-accent font-medium tracking-wide mb-2">Elige tu sucursal</p>
            <h2 className="text-3xl md:text-4xl font-display font-bold text-foreground leading-tight">
              Consulta el menú vigente
            </h2>
            <p className="text-muted-foreground mt-3">
              Cada sucursal tiene su carta actualizada. Ábrela desde aquí o escanea el
              código QR de tu mesa.
            </p>
          </div>

          {cargando ? (
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
              {Array.from({ length: 4 }).map((_, i) => (
                <div key={i} className="aspect-[3/4] rounded-2xl bg-muted animate-pulse" />
              ))}
            </div>
          ) : (
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
              {sucursales.map((s) => (
                <a
                  key={s.id}
                  href={s.menuLink}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="group relative overflow-hidden rounded-2xl aspect-[3/4] shadow-lg ring-1 ring-border"
                >
                  <img
                    src={restauranteComedor}
                    alt=""
                    aria-hidden
                    className="absolute inset-0 w-full h-full object-cover transition-transform duration-700 group-hover:scale-105"
                  />
                  <div className="absolute inset-0 bg-gradient-to-t from-ocean-dark/95 via-primary/50 to-primary/20" />
                  <div className="absolute inset-x-0 bottom-0 p-6 text-white">
                    <span className="text-xs uppercase tracking-widest text-accent font-semibold">
                      {s.contacto?.ciudad ?? "La Ola"}
                    </span>
                    <h3 className="text-2xl font-display font-bold mt-1">{nombreCorto(s.nombre)}</h3>
                    <span className="inline-flex items-center gap-1.5 mt-3 text-sm font-semibold text-white/90 group-hover:gap-2.5 transition-all">
                      Ver menú <span aria-hidden>→</span>
                    </span>
                  </div>
                </a>
              ))}
            </div>
          )}
        </div>
      </section>

      {/* Platillos estrella (carrusel) */}
      <FeaturedDishes />

      {/* CTA */}
      <section className="relative py-20 overflow-hidden">
        <img src={restauranteComedor} alt="" aria-hidden className="absolute inset-0 w-full h-full object-cover" />
        <div className="absolute inset-0 bg-ocean-dark/80" />
        <div className="relative container mx-auto px-4 text-center text-white">
          <h2 className="text-3xl md:text-4xl font-display font-bold mb-4">¿Se te antojó?</h2>
          <p className="text-white/85 mb-8 max-w-lg mx-auto">
            Te esperamos en cualquiera de nuestras cuatro sucursales.
          </p>
          <Button asChild size="lg" className="bg-accent hover:bg-coral-light text-accent-foreground">
            <Link to="/sucursales">Ver sucursales</Link>
          </Button>
        </div>
      </section>
    </Layout>
  );
}
