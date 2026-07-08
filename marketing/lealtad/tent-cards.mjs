// TENT CARDS — Programa de membresía de La Ola.
// Dirección de arte: mínima y editorial. La "ola" se expresa como ondas
// concéntricas (geometría de agua), no como ícono. Paleta reducida: tinta
// océano sobre papel arena, un solo acento coral. Tipografía curada:
// Didone en versalitas (wordmark) + geométrica tracked (labels).
//
// Formato: tarjeta rígida 100 x 150 mm, DOBLE CARA (dos páginas idénticas).
// La franja inferior entra en la ranura de la base de madera.
// Salida: tent/laola-tent-<CODE>.html  (PDF con Chrome headless, ver README).

import QRCode from "qrcode";
import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const __dirname = dirname(fileURLToPath(import.meta.url));
const OUT = join(__dirname, "tent");
mkdirSync(OUT, { recursive: true });

const SITE_URL = "https://laola.mx";
const SUCURSALES = [
  { codigo: "VAL", nombre: "Del Valle" },
  { codigo: "BRI", nombre: "Las Brisas" },
  { codigo: "CER", nombre: "Cervecería" },
  { codigo: "SOL", nombre: "Solares" },
];
const registroLink = (c) => `${SITE_URL}/lealtad?suc=${c}`;

// Paleta
const PAPER = "#EFE7D6"; // papel arena
const INK = "#0C3A52";   // tinta océano
const INKQR = "#0A2E42"; // navy para el QR (contraste de escaneo)
const CORAL = "#D8623A"; // acento (usado una sola vez)

// Ondas concéntricas ancladas a una esquina; el marco recorta el cuarto visible.
const ripples = (cx, cy) => {
  let arcs = "";
  for (let r = 8; r <= 78; r += 6.5) {
    arcs += `<circle cx="${cx}" cy="${cy}" r="${r}" fill="none" stroke="${INK}" stroke-width="0.35" opacity="0.16"/>`;
  }
  return `<svg viewBox="0 0 100 150" preserveAspectRatio="none" style="position:absolute;inset:0;width:100%;height:100%;z-index:0">${arcs}</svg>`;
};

for (const s of SUCURSALES) {
  const svg = (await QRCode.toString(registroLink(s.codigo), {
    errorCorrectionLevel: "M",
    margin: 1, // zona de silencio mínima para escaneo fiable
    color: { dark: INKQR, light: PAPER },
    type: "svg",
    width: 600,
  })).replace(/<svg /, '<svg style="width:100%;height:100%;display:block" ');

  const cara = `
    <section class="card">
      ${ripples(2, 148)}
      <div class="frame"></div>

      <header class="mark">
        <h1>LA OLA</h1>
        <div class="rule"><i></i></div>
        <p class="tag">S E A F O O D</p>
      </header>

      <div class="suc">${s.nombre.toUpperCase()}</div>

      <p class="lede">PROGRAMA&nbsp;&nbsp;DE&nbsp;&nbsp;MEMBRESÍA</p>

      <div class="qrbox">
        <span class="qlabel">ESCANEA</span>
        <div class="qr">${svg}</div>
      </div>
    </section>`;

  const html = `<!doctype html><html lang="es"><head><meta charset="utf-8">
<style>
  @import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700;900&family=Jost:wght@300;400;500&display=swap');
  @page { size: 100mm 150mm; margin: 0; }
  *{margin:0;padding:0;box-sizing:border-box}
  html,body{width:100mm}
  body{-webkit-print-color-adjust:exact;print-color-adjust:exact}
  .card{position:relative;width:100mm;height:150mm;background:${PAPER};overflow:hidden;
    page-break-after:always;font-family:'Jost',sans-serif;color:${INK}}
  .card:last-child{page-break-after:auto}

  .frame{position:absolute;inset:6mm;border:0.4mm solid ${INK};opacity:.55;z-index:1}

  .mark{position:absolute;top:20mm;left:0;right:0;text-align:center;z-index:2}
  .mark h1{font-family:'Playfair Display',serif;font-weight:900;font-size:33pt;
    letter-spacing:.14em;line-height:1;margin-left:.14em}
  .rule{display:flex;align-items:center;justify-content:center;gap:0;margin:4.5mm auto 3.5mm;width:26mm}
  .rule::before,.rule::after{content:"";height:0.5mm;flex:1;background:${CORAL};opacity:.85}
  .rule i{width:1.8mm;height:1.8mm;margin:0 2mm;background:${CORAL};transform:rotate(45deg)}
  .tag{font-weight:400;font-size:8pt;letter-spacing:.12em}

  .suc{position:absolute;top:64mm;left:0;right:0;text-align:center;z-index:2;
    font-weight:400;font-size:10.5pt;letter-spacing:.42em;margin-left:.42em}
  .lede{position:absolute;top:74mm;left:0;right:0;text-align:center;z-index:2;
    font-weight:300;font-size:7.5pt;letter-spacing:.34em;opacity:.62;margin-left:.34em}

  .qrbox{position:absolute;right:12mm;bottom:23mm;z-index:2;text-align:center}
  .qlabel{display:block;font-weight:400;font-size:6.5pt;letter-spacing:.42em;
    margin:0 0 2.5mm .42em;opacity:.75}
  .qr{width:31mm;height:31mm;background:${PAPER};padding:2mm;
    border:0.3mm solid rgba(12,58,82,.4)}
</style></head>
<body>${cara}${cara}</body></html>`;

  writeFileSync(join(OUT, `laola-tent-${s.codigo}.html`), html);
  console.log(`Tent card ${s.codigo} (${s.nombre}) -> tent/laola-tent-${s.codigo}.html`);
}
