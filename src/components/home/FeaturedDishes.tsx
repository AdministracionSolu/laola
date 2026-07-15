import { useRef } from "react";
import { Link } from "react-router-dom";
import Autoplay from "embla-carousel-autoplay";
import {
  Carousel,
  CarouselContent,
  CarouselItem,
  CarouselNext,
  CarouselPrevious,
} from "@/components/ui/carousel";
import tostadaSanBlas from "@/assets/tostada-san-blas.jpeg";
import vasoLoco from "@/assets/vaso-loco.jpeg";
import pateCamaron from "@/assets/pate-camaron.jpeg";
import calloHacha from "@/assets/callo-hacha.jpeg";

const dishes = [
  {
    name: "Tostada Especial San Blas",
    kicker: "La insignia",
    description: "Mariscos frescos del Pacífico sobre tostada crujiente.",
    image: tostadaSanBlas,
  },
  {
    name: "Vaso Loco",
    kicker: "El clásico",
    description: "El coctel que nos identifica, con receta de siempre.",
    image: vasoLoco,
  },
  {
    name: "Paté de Camarón",
    kicker: "De la casa",
    description: "Cremoso, con el punto exacto de sazón y limón.",
    image: pateCamaron,
  },
  {
    name: "Callo de Hacha",
    kicker: "Del mar",
    description: "Frescura pura, servido con limón y salsa de la casa.",
    image: calloHacha,
  },
];

export function FeaturedDishes() {
  // Auto-play en loop continuo: avanza solo, se pausa al pasar el mouse
  // y retoma tras usar las flechas.
  const autoplay = useRef(
    Autoplay({ delay: 2800, stopOnInteraction: false, stopOnMouseEnter: true })
  );

  return (
    <section className="py-16 md:py-24 bg-background">
      <div className="container mx-auto px-4">
        <div className="flex flex-col md:flex-row md:items-end md:justify-between gap-4 mb-10">
          <div className="max-w-xl">
            <p className="text-accent font-medium tracking-wide mb-2">Especialidades de la casa</p>
            <h2 className="text-3xl md:text-4xl lg:text-5xl font-display font-bold text-foreground leading-tight">
              Lo que nos hace La&nbsp;Ola
            </h2>
          </div>
          <p className="text-muted-foreground md:text-right md:max-w-xs">
            Recetas de la costa de Nayarit, preparadas al momento con producto del día.
          </p>
        </div>

        <Carousel
          plugins={[autoplay.current]}
          opts={{ align: "start", loop: true, duration: 32 }}
          className="w-full"
        >
          <CarouselContent className="-ml-4">
            {dishes.map((dish) => (
              <CarouselItem key={dish.name} className="pl-4 basis-[85%] sm:basis-1/2 lg:basis-1/3">
                <article className="group relative overflow-hidden rounded-2xl shadow-lg aspect-[4/5] bg-ocean-dark">
                  <img
                    src={dish.image}
                    alt={dish.name}
                    loading="lazy"
                    className="absolute inset-0 w-full h-full object-cover object-center transition-transform duration-[6000ms] ease-out group-hover:scale-110"
                  />
                  <div className="absolute inset-0 bg-gradient-to-t from-ocean-dark/90 via-ocean-dark/25 to-transparent" />
                  <div className="absolute inset-x-0 bottom-0 p-6 text-white">
                    <span className="inline-block text-xs uppercase tracking-widest text-accent font-semibold mb-2">
                      {dish.kicker}
                    </span>
                    <h3 className="text-2xl font-display font-bold leading-tight">{dish.name}</h3>
                    <p className="text-sm text-white/80 mt-1.5 leading-snug">{dish.description}</p>
                  </div>
                </article>
              </CarouselItem>
            ))}
          </CarouselContent>
          <CarouselPrevious className="hidden md:flex -left-4" />
          <CarouselNext className="hidden md:flex -right-4" />
        </Carousel>

        <div className="text-center mt-10">
          <Link
            to="/menu"
            className="inline-flex items-center gap-2 text-primary font-semibold text-lg hover:gap-3 transition-all"
          >
            Ver el menú completo
            <span aria-hidden>→</span>
          </Link>
        </div>
      </div>
    </section>
  );
}
