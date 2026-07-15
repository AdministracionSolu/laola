// QR de VALIDACIÓN DE VISITA — va impreso en el ticket de la cuenta.
// Distinto del QR de inscripción (tent card, /lealtad?suc=): este abre
//   https://<sitio>/visita?suc=CODE
// donde el MIEMBRO teclea el folio de su ticket + su teléfono y suma la visita.
//
// Uso: node marketing/lealtad/ticket-qr.mjs
// Salida: marketing/lealtad/qr/laola-visita-<CODE>.png/.svg

import QRCode from "qrcode";
import { writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const __dirname = dirname(fileURLToPath(import.meta.url));

const SITE_URL = "https://laola.mx"; // sin slash final
const SUCURSALES = [
  { codigo: "VAL", nombre: "Del Valle" },
  { codigo: "BRI", nombre: "Las Brisas" },
  { codigo: "CER", nombre: "Cervecería" },
  { codigo: "SOL", nombre: "Solares" },
];

const visitaLink = (codigo) => `${SITE_URL}/visita?suc=${codigo}`;

// Alto contraste y margen chico: el QR va pequeño en el ticket.
const qrOpts = {
  errorCorrectionLevel: "M",
  margin: 2,
  color: { dark: "#000000", light: "#ffffff" },
};

for (const s of SUCURSALES) {
  const link = visitaLink(s.codigo);
  const svg = await QRCode.toString(link, { ...qrOpts, type: "svg", width: 600 });
  writeFileSync(join(__dirname, "qr", `laola-visita-${s.codigo}.svg`), svg);
  await QRCode.toFile(join(__dirname, "qr", `laola-visita-${s.codigo}.png`), link, {
    ...qrOpts,
    width: 800,
  });
  console.log(`Ticket QR ${s.codigo} (${s.nombre}) -> qr/laola-visita-${s.codigo}.png/.svg  [${link}]`);
}
