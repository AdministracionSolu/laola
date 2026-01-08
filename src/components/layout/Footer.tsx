import { Link } from "react-router-dom";
import { Facebook, Instagram, Phone } from "lucide-react";
import logoLaOla from "@/assets/logo-la-ola.jpeg";

export function Footer() {
  return (
    <footer className="bg-primary text-primary-foreground">
      <div className="container mx-auto px-4 py-12">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
          {/* Brand */}
          <div className="md:col-span-1">
            <div className="flex items-center gap-3 mb-4">
              <img src={logoLaOla} alt="La Ola" className="h-12 w-12 rounded-full" />
              <h3 className="text-2xl font-display font-bold">La Ola</h3>
            </div>
            <p className="text-primary-foreground/80 text-sm leading-relaxed">
              Nuestra cocina nace del origen. Tradición de mariscos desde Mexcaltitán, Nayarit.
            </p>
          </div>

          {/* Quick Links */}
          <div>
            <h4 className="font-semibold mb-4">Navegación</h4>
            <ul className="space-y-2 text-sm">
              <li>
                <Link to="/" className="text-primary-foreground/80 hover:text-accent transition-colors">
                  Inicio
                </Link>
              </li>
              <li>
                <Link to="/menu" className="text-primary-foreground/80 hover:text-accent transition-colors">
                  Menú
                </Link>
              </li>
              <li>
                <Link to="/sucursales" className="text-primary-foreground/80 hover:text-accent transition-colors">
                  Sucursales
                </Link>
              </li>
              <li>
                <Link to="/contacto" className="text-primary-foreground/80 hover:text-accent transition-colors">
                  Contacto
                </Link>
              </li>
            </ul>
          </div>

          {/* Contact */}
          <div>
            <h4 className="font-semibold mb-4">Contacto</h4>
            <ul className="space-y-2 text-sm">
              <li className="flex items-center gap-2 text-primary-foreground/80">
                <Phone className="w-4 h-4 text-accent flex-shrink-0" />
                <span>Del Valle:</span>
                <a href="tel:+523111330891" className="hover:text-accent transition-colors">
                  311 133 0891
                </a>
              </li>
              <li className="flex items-center gap-2 text-primary-foreground/80">
                <Phone className="w-4 h-4 text-accent flex-shrink-0" />
                <span>Insurgentes:</span>
                <a href="tel:+523111693323" className="hover:text-accent transition-colors">
                  311 169 3323
                </a>
              </li>
              <li className="flex items-center gap-2 text-primary-foreground/80">
                <Phone className="w-4 h-4 text-accent flex-shrink-0" />
                <span>Solares:</span>
                <a href="tel:+523317893505" className="hover:text-accent transition-colors">
                  33 1789 3505
                </a>
              </li>
              <li className="flex items-center gap-2 text-primary-foreground/80">
                <Phone className="w-4 h-4 text-accent flex-shrink-0" />
                <span>Las Brisas:</span>
                <a href="tel:+523112171395" className="hover:text-accent transition-colors">
                  311 217 1395
                </a>
              </li>
            </ul>
          </div>

          {/* Social */}
          <div>
            <h4 className="font-semibold mb-4">Síguenos</h4>
            <div className="flex gap-4">
              <a
                href="https://www.facebook.com/Laolaseafood/?locale=es_LA"
                target="_blank"
                rel="noopener noreferrer"
                className="w-10 h-10 rounded-full bg-primary-foreground/10 flex items-center justify-center hover:bg-accent transition-colors"
                aria-label="Facebook"
              >
                <Facebook className="w-5 h-5" />
              </a>
              <a
                href="https://www.instagram.com/laola.seafood/"
                target="_blank"
                rel="noopener noreferrer"
                className="w-10 h-10 rounded-full bg-primary-foreground/10 flex items-center justify-center hover:bg-accent transition-colors"
                aria-label="Instagram"
              >
                <Instagram className="w-5 h-5" />
              </a>
            </div>
          </div>
        </div>

        <div className="border-t border-primary-foreground/20 mt-8 pt-8 text-center text-sm text-primary-foreground/60">
          <p>© {new Date().getFullYear()} La Ola. Todos los derechos reservados.</p>
        </div>
      </div>
    </footer>
  );
}
