import { Link } from "react-router-dom";
import { MapPin, ChevronRight } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";

const locations = [
  {
    id: 1,
    name: "Del Valle",
    address: "Av del Valle 161, Cd del Valle, 63157",
    city: "Tepic, Nayarit",
  },
  {
    id: 2,
    name: "Insurgentes",
    address: "De Los Insurgentes Pte. 233, Versalles, 63000",
    city: "Tepic, Nayarit",
  },
  {
    id: 3,
    name: "Solares",
    address: "P.° Solares 1639-int: #11 & #12, Solares Residencial, 45019",
    city: "Zapopan, Jalisco",
  },
  {
    id: 4,
    name: "Las Brisas",
    address: "De Los Insurgentes Pte. 959, Las Brisas Rodeo de la Punta, 63110",
    city: "Tepic, Nayarit",
  },
];

export function LocationsPreview() {
  return (
    <section className="py-16 md:py-24 bg-background">
      <div className="container mx-auto px-4">
        <div className="text-center mb-12">
          <span className="text-accent font-medium text-sm uppercase tracking-wider">
            Encuéntranos
          </span>
          <h2 className="text-3xl md:text-4xl font-display font-bold text-foreground mt-2">
            Nuestras Sucursales
          </h2>
          <p className="text-muted-foreground mt-4 max-w-2xl mx-auto">
            4 ubicaciones en Tepic, Nayarit y Zapopan, Jalisco para llevarte el sabor de Mexcaltitán
          </p>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          {locations.map((location, index) => (
            <Card 
              key={location.id} 
              className="group hover:shadow-lg transition-all duration-300 border-border hover:border-primary/30 animate-fade-in"
              style={{ animationDelay: `${index * 0.1}s` }}
            >
              <CardContent className="p-6">
                <div className="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center mb-4 group-hover:bg-primary/20 transition-colors">
                  <MapPin className="w-5 h-5 text-primary" />
                </div>
                <h3 className="font-semibold text-lg text-foreground mb-1">
                  {location.name}
                </h3>
                <p className="text-sm text-muted-foreground mb-2">
                  {location.city}
                </p>
                <p className="text-sm text-muted-foreground leading-relaxed">
                  {location.address}
                </p>
              </CardContent>
            </Card>
          ))}
        </div>

        <div className="text-center">
          <Button asChild variant="outline" className="border-primary text-primary hover:bg-primary hover:text-primary-foreground">
            <Link to="/sucursales">
              Ver todas las sucursales
              <ChevronRight className="w-4 h-4 ml-1" />
            </Link>
          </Button>
        </div>
      </div>
    </section>
  );
}
