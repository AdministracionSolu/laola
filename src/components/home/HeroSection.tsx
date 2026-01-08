import { Link } from "react-router-dom";
import { Button } from "@/components/ui/button";
import { ChevronRight } from "lucide-react";
import islaMexcaltitan from "@/assets/isla-mexcaltitan.jpg";

export function HeroSection() {
  return (
    <section className="relative min-h-[80vh] flex items-center overflow-hidden">
      {/* Background image with gradient overlay */}
      <div className="absolute inset-0">
        <img 
          src={islaMexcaltitan} 
          alt="Isla de Mexcaltitán" 
          className="w-full h-full object-cover"
        />
        <div className="absolute inset-0 bg-gradient-to-br from-primary/85 via-ocean-dark/80 to-primary/85" />
      </div>

      {/* Wave decoration at bottom */}
      <div className="absolute bottom-0 left-0 right-0">
        <svg
          viewBox="0 0 1440 120"
          fill="none"
          xmlns="http://www.w3.org/2000/svg"
          className="w-full h-auto"
          preserveAspectRatio="none"
        >
          <path
            d="M0 120L48 110C96 100 192 80 288 70C384 60 480 60 576 65C672 70 768 80 864 85C960 90 1056 90 1152 85C1248 80 1344 70 1392 65L1440 60V120H1392C1344 120 1248 120 1152 120C1056 120 960 120 864 120C768 120 672 120 576 120C480 120 384 120 288 120C192 120 96 120 48 120H0Z"
            className="fill-background"
          />
        </svg>
      </div>

      {/* Content */}
      <div className="container mx-auto px-4 relative z-10">
        <div className="max-w-3xl">
          <span className="inline-block px-4 py-1.5 bg-accent/20 text-accent rounded-full text-sm font-medium mb-6 animate-fade-in">
            Desde Mexcaltitán, Nayarit
          </span>
          <h1 className="text-4xl md:text-6xl lg:text-7xl font-display font-bold text-white mb-6 leading-tight animate-fade-in" style={{ animationDelay: "0.1s" }}>
            Nuestra cocina nace del origen
          </h1>
          <p className="text-lg md:text-xl text-white/90 mb-8 max-w-xl animate-fade-in" style={{ animationDelay: "0.2s" }}>
            Mariscos frescos con la tradición de la isla de Mexcaltitán. 
            Sabores auténticos que cuentan la historia de nuestras raíces.
          </p>
          <div className="flex flex-col sm:flex-row gap-4 animate-fade-in" style={{ animationDelay: "0.3s" }}>
            <Button 
              asChild 
              size="lg" 
              className="bg-accent hover:bg-coral-light text-accent-foreground text-base"
            >
              <Link to="/menu">
                Ver Menú
                <ChevronRight className="w-5 h-5 ml-1" />
              </Link>
            </Button>
            <Button 
              asChild 
              size="lg" 
              className="bg-white text-primary hover:bg-white/90 text-base"
            >
              <Link to="/sucursales">
                Nuestras Sucursales
              </Link>
            </Button>
          </div>
        </div>
      </div>
    </section>
  );
}
