import { useState } from "react";
import { Link, useLocation } from "react-router-dom";
import { Menu, X, Phone } from "lucide-react";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";
import logoLaOla from "@/assets/logo-la-ola.jpeg";

const navLinks = [
  { href: "/", label: "Inicio" },
  { href: "/menu", label: "Menú" },
  { href: "/ordenar", label: "Ordenar en línea" },
  { href: "/sucursales", label: "Sucursales" },
  { href: "/contacto", label: "Contacto" },
];

export function Navbar() {
  const [isOpen, setIsOpen] = useState(false);
  const location = useLocation();

  return (
    <nav className="sticky top-0 z-50 bg-background/95 backdrop-blur-md border-b border-border">
      <div className="container mx-auto px-4">
        <div className="flex items-center justify-between h-16 md:h-20">
          {/* Logo */}
          <Link to="/" className="flex items-center gap-2">
            <img src={logoLaOla} alt="La Ola" className="h-10 md:h-12 w-auto rounded-full" />
            <span className="text-2xl md:text-3xl font-display font-bold text-primary">
              La Ola
            </span>
          </Link>

          {/* Desktop Navigation */}
          <div className="hidden md:flex items-center gap-8">
            {navLinks.map((link) => (
              <Link
                key={link.href}
                to={link.href}
                className={cn(
                  "text-sm font-medium transition-colors hover:text-primary relative py-1",
                  location.pathname === link.href
                    ? "text-primary after:absolute after:bottom-0 after:left-0 after:w-full after:h-0.5 after:bg-accent"
                    : "text-muted-foreground"
                )}
              >
                {link.label}
              </Link>
            ))}
          </div>

          {/* CTA Button */}
          <div className="hidden md:block">
            <Button asChild className="bg-accent hover:bg-coral-light text-accent-foreground">
              <a href="tel:+525555555555">
                <Phone className="w-4 h-4 mr-2" />
                Llámanos
              </a>
            </Button>
          </div>

          {/* Mobile Menu Button */}
          <button
            className="md:hidden p-2 text-foreground"
            onClick={() => setIsOpen(!isOpen)}
            aria-label="Toggle menu"
          >
            {isOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
          </button>
        </div>
      </div>

      {/* Mobile Menu */}
      {isOpen && (
        <div className="md:hidden bg-background border-t border-border animate-fade-in">
          <div className="container mx-auto px-4 py-4 space-y-3">
            {navLinks.map((link) => (
              <Link
                key={link.href}
                to={link.href}
                onClick={() => setIsOpen(false)}
                className={cn(
                  "block py-2 px-4 rounded-lg text-base font-medium transition-colors",
                  location.pathname === link.href
                    ? "bg-secondary text-primary"
                    : "text-muted-foreground hover:bg-muted"
                )}
              >
                {link.label}
              </Link>
            ))}
            <Button asChild className="w-full bg-accent hover:bg-coral-light text-accent-foreground mt-4">
              <a href="tel:+525555555555">
                <Phone className="w-4 h-4 mr-2" />
                Llámanos
              </a>
            </Button>
          </div>
        </div>
      )}
    </nav>
  );
}
