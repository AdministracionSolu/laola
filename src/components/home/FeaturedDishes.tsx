import { Card, CardContent } from "@/components/ui/card";
import { Star } from "lucide-react";
import tostadaSanBlas from "@/assets/tostada-san-blas.jpeg";
import vasoLoco from "@/assets/vaso-loco.jpeg";
import pateCamaron from "@/assets/pate-camaron.jpeg";
import calloHacha from "@/assets/callo-hacha.jpeg";

const dishes = [
  {
    id: 1,
    name: "Tostada Especial San Blas",
    description: "Nuestra tostada insignia con mariscos frescos del Pacífico",
    image: tostadaSanBlas,
    featured: true,
  },
  {
    id: 2,
    name: "Vaso Loco",
    description: "El clásico que nos identifica, preparado con receta tradicional",
    image: vasoLoco,
    featured: true,
  },
  {
    id: 3,
    name: "Tostada de Paté de Camarón",
    description: "Delicioso paté de camarón sobre tostada crujiente",
    image: pateCamaron,
    featured: false,
  },
  {
    id: 4,
    name: "Callo de Hacha",
    description: "Frescura del mar servida con limón y salsa especial",
    image: calloHacha,
    featured: false,
  },
];

export function FeaturedDishes() {
  return (
    <section className="py-16 md:py-24 bg-background">
      <div className="container mx-auto px-4">
        <div className="text-center mb-12">
          <span className="text-accent font-medium text-sm uppercase tracking-wider">
            Lo Mejor de Nuestra Casa
          </span>
          <h2 className="text-3xl md:text-4xl font-display font-bold text-foreground mt-2">
            Platillos Estrella
          </h2>
          <p className="text-muted-foreground mt-4 max-w-2xl mx-auto">
            Descubre los sabores que han hecho famosa a La Ola por más de una década
          </p>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
          {dishes.map((dish, index) => (
            <Card
              key={dish.id}
              className="group overflow-hidden border-0 shadow-lg hover:shadow-xl transition-all duration-300 animate-fade-in"
              style={{ animationDelay: `${index * 0.1}s` }}
            >
              <div className="relative aspect-[4/3] overflow-hidden">
                <img
                  src={dish.image}
                  alt={dish.name}
                  className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
                />
                {dish.featured && (
                  <div className="absolute top-3 right-3 bg-accent text-accent-foreground px-2 py-1 rounded-full text-xs font-medium flex items-center gap-1">
                    <Star className="w-3 h-3 fill-current" />
                    Favorito
                  </div>
                )}
              </div>
              <CardContent className="p-4">
                <h3 className="font-semibold text-foreground text-lg mb-1 group-hover:text-primary transition-colors">
                  {dish.name}
                </h3>
                <p className="text-muted-foreground text-sm">
                  {dish.description}
                </p>
              </CardContent>
            </Card>
          ))}
        </div>
      </div>
    </section>
  );
}
