import { useEffect, useState } from "react";
import { supabase } from "@/integrations/supabase/client";

// ============================================================
// Sucursales — fuente de verdad
//
// Los DATOS operativos (nombre, menú vigente) viven en la BD `sucursales`
// y se editan desde Admin. El menú SIEMPRE se abre por la ruta estable
// /menu/s/<CÓDIGO>, que lee menu_url de la BD y redirige. Así el sitio
// nunca apunta a un PDF viejo: si el menú cambia en Admin, cambia en todos
// lados sin tocar código.
//
// La info de CONTACTO (teléfono, horario, mapa, redes) aún no vive en la BD,
// así que se mantiene aquí indexada por el prefijo de folio (VAL/BRI/CER/SOL).
// ============================================================

export type SucursalContacto = {
  telefono: string;
  ciudad: string;
  horario: string;
  facebook: string;
  // Consulta para Google Maps (link "cómo llegar" + iframe embed).
  mapaQuery: string;
  amenidades: string[];
};

// Indexado por prefijo_folio (código de la sucursal en la BD).
export const CONTACTO_SUCURSAL: Record<string, SucursalContacto> = {
  VAL: {
    telefono: "+52 311 133 0891",
    ciudad: "Tepic, Nayarit",
    horario: "Todos los días · 10:00 a 23:59",
    facebook: "https://www.facebook.com/Laolaseafood/?locale=es_LA",
    mapaQuery: "Av del Valle 161, Cd del Valle, 63157, Tepic, Nayarit",
    amenidades: ["Privado disponible", "Música en vivo fines de semana"],
  },
  CER: {
    telefono: "+52 311 169 3323",
    ciudad: "Tepic, Nayarit",
    horario: "Dom a Mié · 11:00 a 23:59 — Jue a Sáb · 11:00 a 02:00",
    facebook: "https://www.facebook.com/Laolaseafood/?locale=es_LA",
    mapaQuery: "De Los Insurgentes Pte. 233, Versalles, 63000, Tepic, Nayarit",
    amenidades: ["Estacionamiento", "Cervecería"],
  },
  SOL: {
    telefono: "+52 33 1789 3505",
    ciudad: "Zapopan, Jalisco",
    horario: "Todos los días · 11:00 a 20:00",
    facebook: "https://www.facebook.com/Laolaseafood/?locale=es_LA",
    mapaQuery: "Paseo Solares 1639, Solares Residencial, 45019, Zapopan, Jalisco",
    amenidades: ["Terraza", "Música en vivo sábados"],
  },
  BRI: {
    telefono: "+52 311 217 1395",
    ciudad: "Tepic, Nayarit",
    horario: "Todos los días · 10:00 a 18:00",
    facebook: "https://www.facebook.com/Laolaseafood/?locale=es_LA",
    mapaQuery: "De Los Insurgentes Pte. 959, Las Brisas, 63110, Tepic, Nayarit",
    amenidades: ["Vista al lago", "Área para niños"],
  },
};

export type Sucursal = {
  id: string;
  nombre: string;        // nombre real desde la BD (ej. "Cervecería")
  codigo: string;        // prefijo_folio (VAL/BRI/CER/SOL)
  direccion: string | null;
  menuUrl: string | null;
  contacto: SucursalContacto | null;
  // Ruta estable del menú (lee menu_url de la BD y redirige). Úsala SIEMPRE
  // en lugar de un PDF fijo.
  menuLink: string;
  mapaEmbed: string | null;
  mapaLink: string | null;
};

// "Del Valle" se muestra como "Valle".
export const nombreCorto = (n: string) => n.replace(/^Del\s+/i, "");

const mapEmbed = (q: string) => `https://www.google.com/maps?q=${encodeURIComponent(q)}&output=embed`;
const mapLink = (q: string) => `https://maps.google.com/?q=${encodeURIComponent(q)}`;

// Orden de presentación deseado (por código).
const ORDEN = ["VAL", "CER", "BRI", "SOL"];

export function toSucursal(row: any): Sucursal {
  const codigo = (row.prefijo_folio ?? "").toUpperCase();
  const contacto = CONTACTO_SUCURSAL[codigo] ?? null;
  return {
    id: row.id,
    nombre: row.nombre,
    codigo,
    direccion: row.direccion ?? null,
    menuUrl: row.menu_url ?? null,
    contacto,
    menuLink: `/menu/s/${codigo}`,
    mapaEmbed: contacto ? mapEmbed(contacto.mapaQuery) : null,
    mapaLink: contacto ? mapLink(contacto.mapaQuery) : null,
  };
}

/** Trae las sucursales desde la BD, ordenadas y con su info de contacto. */
export function useSucursales() {
  const [sucursales, setSucursales] = useState<Sucursal[]>([]);
  const [cargando, setCargando] = useState(true);

  useEffect(() => {
    let vivo = true;
    (supabase as any)
      .from("sucursales")
      .select("id,nombre,prefijo_folio,direccion,menu_url")
      .then(({ data }: { data: any[] | null }) => {
        if (!vivo) return;
        const lista = (data ?? []).map(toSucursal).sort(
          (a: Sucursal, b: Sucursal) => {
            const ia = ORDEN.indexOf(a.codigo); const ib = ORDEN.indexOf(b.codigo);
            return (ia === -1 ? 99 : ia) - (ib === -1 ? 99 : ib);
          }
        );
        setSucursales(lista);
        setCargando(false);
      });
    return () => { vivo = false; };
  }, []);

  return { sucursales, cargando };
}
