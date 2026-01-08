import { useState } from "react";
import { Layout } from "@/components/layout/Layout";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Label } from "@/components/ui/label";
import { Phone, Mail, MessageCircle, MapPin, Send, CheckCircle } from "lucide-react";
import { useToast } from "@/hooks/use-toast";

const contactInfo = [
  {
    icon: Phone,
    title: "Teléfono",
    value: "55 5524 6403",
    href: "tel:+525555246403",
    description: "Sucursal Del Valle",
  },
  {
    icon: MessageCircle,
    title: "WhatsApp",
    value: "55 1234 5678",
    href: "https://wa.me/5215512345678?text=Hola,%20me%20gustaría%20más%20información%20sobre%20La%20Ola",
    description: "Respuesta rápida",
  },
  {
    icon: Mail,
    title: "Email",
    value: "info@laola.mx",
    href: "mailto:info@laola.mx",
    description: "Consultas generales",
  },
];

export default function Contacto() {
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isSubmitted, setIsSubmitted] = useState(false);
  const { toast } = useToast();

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setIsSubmitting(true);
    
    // Simulate form submission
    await new Promise(resolve => setTimeout(resolve, 1000));
    
    setIsSubmitting(false);
    setIsSubmitted(true);
    toast({
      title: "¡Mensaje enviado!",
      description: "Nos pondremos en contacto contigo pronto.",
    });
  };

  return (
    <Layout>
      {/* Hero */}
      <section className="bg-gradient-ocean py-16 md:py-24">
        <div className="container mx-auto px-4 text-center">
          <h1 className="text-4xl md:text-5xl font-display font-bold text-white mb-4">
            Contáctanos
          </h1>
          <p className="text-white/90 text-lg max-w-2xl mx-auto">
            ¿Tienes alguna pregunta o quieres reservar un espacio para tu evento? 
            Estamos para ayudarte.
          </p>
        </div>
      </section>

      {/* Contact Content */}
      <section className="py-12 md:py-16 bg-background">
        <div className="container mx-auto px-4">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-12">
            {/* Contact Info */}
            <div>
              <h2 className="text-2xl font-display font-bold text-foreground mb-6">
                Información de Contacto
              </h2>
              
              <div className="space-y-4 mb-8">
                {contactInfo.map((item, index) => (
                  <Card key={index} className="hover:shadow-md transition-shadow">
                    <CardContent className="p-4">
                      <a
                        href={item.href}
                        target={item.href.startsWith("http") ? "_blank" : undefined}
                        rel={item.href.startsWith("http") ? "noopener noreferrer" : undefined}
                        className="flex items-center gap-4 group"
                      >
                        <div className="w-12 h-12 rounded-full bg-primary/10 flex items-center justify-center group-hover:bg-primary/20 transition-colors">
                          <item.icon className="w-6 h-6 text-primary" />
                        </div>
                        <div>
                          <p className="text-sm text-muted-foreground">{item.title}</p>
                          <p className="font-semibold text-foreground group-hover:text-primary transition-colors">
                            {item.value}
                          </p>
                          <p className="text-xs text-muted-foreground">{item.description}</p>
                        </div>
                      </a>
                    </CardContent>
                  </Card>
                ))}
              </div>

              {/* WhatsApp CTA */}
              <Card className="bg-green-50 border-green-200">
                <CardContent className="p-6 text-center">
                  <MessageCircle className="w-12 h-12 text-green-600 mx-auto mb-4" />
                  <h3 className="font-semibold text-foreground mb-2">
                    ¿Prefieres WhatsApp?
                  </h3>
                  <p className="text-muted-foreground text-sm mb-4">
                    Escríbenos directamente y te responderemos lo antes posible
                  </p>
                  <Button 
                    asChild 
                    className="bg-green-600 hover:bg-green-700 text-white"
                  >
                    <a 
                      href="https://wa.me/5215512345678?text=Hola,%20me%20gustaría%20más%20información%20sobre%20La%20Ola"
                      target="_blank"
                      rel="noopener noreferrer"
                    >
                      <MessageCircle className="w-4 h-4 mr-2" />
                      Abrir WhatsApp
                    </a>
                  </Button>
                </CardContent>
              </Card>
            </div>

            {/* Contact Form */}
            <div>
              <h2 className="text-2xl font-display font-bold text-foreground mb-6">
                Envíanos un Mensaje
              </h2>
              
              <Card>
                <CardContent className="p-6">
                  {isSubmitted ? (
                    <div className="text-center py-8">
                      <div className="w-16 h-16 rounded-full bg-green-100 flex items-center justify-center mx-auto mb-4">
                        <CheckCircle className="w-8 h-8 text-green-600" />
                      </div>
                      <h3 className="text-xl font-semibold text-foreground mb-2">
                        ¡Gracias por escribirnos!
                      </h3>
                      <p className="text-muted-foreground">
                        Hemos recibido tu mensaje y te responderemos pronto.
                      </p>
                      <Button 
                        variant="outline" 
                        className="mt-6"
                        onClick={() => setIsSubmitted(false)}
                      >
                        Enviar otro mensaje
                      </Button>
                    </div>
                  ) : (
                    <form onSubmit={handleSubmit} className="space-y-6">
                      <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                        <div className="space-y-2">
                          <Label htmlFor="name">Nombre *</Label>
                          <Input 
                            id="name" 
                            placeholder="Tu nombre" 
                            required 
                          />
                        </div>
                        <div className="space-y-2">
                          <Label htmlFor="phone">Teléfono</Label>
                          <Input 
                            id="phone" 
                            type="tel" 
                            placeholder="55 1234 5678" 
                          />
                        </div>
                      </div>

                      <div className="space-y-2">
                        <Label htmlFor="email">Email *</Label>
                        <Input 
                          id="email" 
                          type="email" 
                          placeholder="tu@email.com" 
                          required 
                        />
                      </div>

                      <div className="space-y-2">
                        <Label htmlFor="subject">Asunto *</Label>
                        <Input 
                          id="subject" 
                          placeholder="¿En qué podemos ayudarte?" 
                          required 
                        />
                      </div>

                      <div className="space-y-2">
                        <Label htmlFor="message">Mensaje *</Label>
                        <Textarea 
                          id="message" 
                          placeholder="Cuéntanos más detalles..." 
                          rows={5}
                          required 
                        />
                      </div>

                      <Button 
                        type="submit" 
                        className="w-full bg-accent hover:bg-coral-light text-accent-foreground"
                        disabled={isSubmitting}
                      >
                        {isSubmitting ? (
                          "Enviando..."
                        ) : (
                          <>
                            <Send className="w-4 h-4 mr-2" />
                            Enviar Mensaje
                          </>
                        )}
                      </Button>
                    </form>
                  )}
                </CardContent>
              </Card>
            </div>
          </div>
        </div>
      </section>

      {/* Locations Quick Access */}
      <section className="py-12 bg-secondary">
        <div className="container mx-auto px-4 text-center">
          <MapPin className="w-10 h-10 text-primary mx-auto mb-4" />
          <h2 className="text-2xl font-display font-bold text-foreground mb-4">
            Visítanos en persona
          </h2>
          <p className="text-muted-foreground mb-6">
            4 sucursales en CDMX y Cuernavaca
          </p>
          <Button asChild variant="outline" className="border-primary text-primary hover:bg-primary hover:text-primary-foreground">
            <a href="/sucursales">
              Ver todas las sucursales
            </a>
          </Button>
        </div>
      </section>
    </Layout>
  );
}
