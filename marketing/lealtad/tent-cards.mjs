// TENT CARDS — La Ola. Tarjeta rígida 100x150 mm, DOS CARAS distintas:
//   Cara A (página 1): MEMBRESÍA  -> QR a /lealtad
//   Cara B (página 2): FACTURACIÓN -> QR a /factura
// para base de madera con ranura (la franja inferior queda oculta).
//
// Dirección de arte: mínima y editorial. El logo real se conserva (fusionado
// con multiply, sin vectorizar). La "ola" se expresa como ondas concéntricas
// (geometría propia, no íconos de librería). Paleta reducida: tinta océano
// sobre papel arena, un acento coral. Tipografía Didone + geométrica tracked.
//
// Salida: tent/laola-tent-<CODE>.html  (PDF con Chrome headless, ver README).

import QRCode from "qrcode";
import { readFileSync, writeFileSync, mkdirSync, existsSync } from "node:fs";
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

const PAPER = "#EFE7D6"; // arena
const INK = "#0C3A52";   // océano
const INKQR = "#0A2E42";
const CORAL = "#D8623A";

// Prefiere el logo con fondo transparente (node prep-logo.mjs). Si no existe,
// cae al JPEG original y compensa el fondo con mix-blend-mode:multiply.
const logoPng = join(__dirname, ".logo.png");
const logoTransparente = existsSync(logoPng);
const logo = logoTransparente
  ? "data:image/png;base64," + readFileSync(logoPng).toString("base64")
  : "data:image/jpeg;base64," + readFileSync(join(__dirname, "..", "..", "src", "assets", "logo-la-ola.jpeg")).toString("base64");
const logoBlend = logoTransparente ? "normal" : "multiply";

const qr = async (url) =>
  (await QRCode.toString(url, {
    errorCorrectionLevel: "M", margin: 1,
    color: { dark: INKQR, light: PAPER }, type: "svg", width: 600,
  })).replace(/<svg /, '<svg style="width:100%;height:100%;display:block" ');

// Ondas concéntricas ancladas a una esquina; el marco recorta el cuarto visible.
const ripples = (cx, cy) => {
  let arcs = "";
  for (let r = 8; r <= 80; r += 6.5)
    arcs += `<circle cx="${cx}" cy="${cy}" r="${r}" fill="none" stroke="${INK}" stroke-width="0.35" opacity="0.15"/>`;
  return `<svg viewBox="0 0 100 150" preserveAspectRatio="none" style="position:absolute;inset:0;width:100%;height:100%;z-index:0">${arcs}</svg>`;
};

const cara = (f) => `
    <section class="card">
      ${ripples(f.ox, f.oy)}
      <div class="frame"></div>
      <img class="logo" src="${logo}" alt="La Ola">
      <div class="rule"><i></i></div>
      <h1>${f.titulo}</h1>
      <p class="sub">${f.sub}</p>
      <div class="suc">${f.suc}</div>
      <div class="qrbox">
        <span class="qlabel">${f.qlabel}</span>
        <div class="qr">${f.svg}</div>
      </div>
    </section>`;

const style = `
  @import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700;900&family=Jost:wght@300;400;500&display=swap');
  @page { size: 100mm 150mm; margin: 0; }
  *{margin:0;padding:0;box-sizing:border-box}
  html,body{width:100mm}
  body{-webkit-print-color-adjust:exact;print-color-adjust:exact}
  .card{position:relative;width:100mm;height:150mm;background:${PAPER};overflow:hidden;
    page-break-after:always;font-family:'Jost',sans-serif;color:${INK}}
  .card:last-child{page-break-after:auto}
  .frame{position:absolute;inset:6mm;border:0.4mm solid ${INK};opacity:.55;z-index:1}
  .logo{position:absolute;top:13mm;left:50%;transform:translateX(-50%);z-index:2;
    height:20mm;width:auto;mix-blend-mode:${logoBlend}}
  .rule{position:absolute;top:37mm;left:50%;transform:translateX(-50%);z-index:2;
    display:flex;align-items:center;justify-content:center;width:26mm}
  .rule::before,.rule::after{content:"";height:0.5mm;flex:1;background:${CORAL};opacity:.9}
  .rule i{width:1.8mm;height:1.8mm;margin:0 2mm;background:${CORAL};transform:rotate(45deg)}
  h1{position:absolute;top:43mm;left:0;right:0;text-align:center;z-index:2;
    font-family:'Playfair Display',serif;font-weight:900;font-size:21pt;
    letter-spacing:.1em;margin-left:.1em;color:${INK}}
  .sub{position:absolute;top:57mm;left:0;right:0;text-align:center;z-index:2;
    font-weight:300;font-size:7.5pt;letter-spacing:.34em;opacity:.6;margin-left:.34em}
  .suc{position:absolute;top:69mm;left:0;right:0;text-align:center;z-index:2;
    font-weight:400;font-size:9.5pt;letter-spacing:.4em;margin-left:.4em}
  .qrbox{position:absolute;right:12mm;bottom:23mm;z-index:2;text-align:center}
  .qlabel{display:block;font-weight:400;font-size:6.5pt;letter-spacing:.34em;margin:0 0 2.5mm .34em;opacity:.75}
  .qr{width:31mm;height:31mm;background:${PAPER};padding:2mm;border:0.3mm solid rgba(12,58,82,.4)}`;

for (const s of SUCURSALES) {
  const caraA = {
    titulo: "MEMBRESÍA", sub: "Ú N E T E &nbsp; A &nbsp; N U E S T R A &nbsp; M E S A",
    suc: s.nombre.toUpperCase(), qlabel: "ESCANEA · ÚNETE",
    ox: 2, oy: 148, svg: await qr(`${SITE_URL}/lealtad?suc=${s.codigo}`),
  };
  const caraB = {
    titulo: "FACTURACIÓN", sub: "S O L I C I T A &nbsp; T U &nbsp; F A C T U R A",
    suc: s.nombre.toUpperCase(), qlabel: "ESCANEA · FACTURA",
    ox: 98, oy: 148, svg: await qr(`${SITE_URL}/factura?suc=${s.codigo}`),
  };

  const html = `<!doctype html><html lang="es"><head><meta charset="utf-8"><style>${style}</style></head>
<body>${cara(caraA)}${cara(caraB)}</body></html>`;

  writeFileSync(join(OUT, `laola-tent-${s.codigo}.html`), html);
  console.log(`Tent card ${s.codigo} (${s.nombre}) -> A: Membresía · B: Facturación`);
}
