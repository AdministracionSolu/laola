// Exploración de dirección de arte para las tent cards de lealtad.
// Genera 3 variantes x 4 sucursales (doble cara) para comparar.
// Salida HTML: tent/<variante>/laola-tent-<CODE>.html
// PDF: se renderiza con Chrome headless (ver flujo en README).

import QRCode from "qrcode";
import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const __dirname = dirname(fileURLToPath(import.meta.url));

const SITE_URL = "https://laola.mx";
const SUCURSALES = [
  { codigo: "VAL", nombre: "Del Valle" },
  { codigo: "BRI", nombre: "Las Brisas" },
  { codigo: "CER", nombre: "Cervecería" },
  { codigo: "SOL", nombre: "Solares" },
];
const registroLink = (c) => `${SITE_URL}/lealtad?suc=${c}`;

const PAPER = "#EFE7D6"; // arena
const INK = "#0C3A52";   // océano
const INKQR = "#0A2E42";
const CORAL = "#D8623A";
const OCEAN = "#0B3346";  // fondo nocturno

// Cada variante define paleta y de dónde nacen las ondas concéntricas.
const VARIANTES = [
  { key: "01-arena-esquina", label: "Arena · esquina",
    paper: PAPER, ink: INK, rip: INK, ripOp: 0.16, origin: [2, 148], rMax: 78,
    frame: INK, coral: CORAL },
  { key: "02-nocturno", label: "Nocturno",
    paper: OCEAN, ink: PAPER, rip: PAPER, ripOp: 0.15, origin: [2, 148], rMax: 78,
    frame: PAPER, coral: "#E0672E" },
  { key: "03-ondas-centro", label: "Ondas al centro",
    paper: PAPER, ink: INK, rip: INK, ripOp: 0.13, origin: [50, 29], rMax: 27,
    frame: INK, coral: CORAL },
];

const ripples = (v) => {
  let arcs = "";
  for (let r = 5; r <= v.rMax; r += 6.5) {
    arcs += `<circle cx="${v.origin[0]}" cy="${v.origin[1]}" r="${r}" fill="none" stroke="${v.rip}" stroke-width="0.35" opacity="${v.ripOp}"/>`;
  }
  return `<svg viewBox="0 0 100 150" preserveAspectRatio="none" style="position:absolute;inset:0;width:100%;height:100%;z-index:0">${arcs}</svg>`;
};

const logoJpeg = readFileSync(join(__dirname, "..", "..", "src", "assets", "logo-la-ola.jpeg"));

// QR igual para todas las variantes: módulos navy sobre placa arena.
const qrCache = {};
for (const s of SUCURSALES) {
  qrCache[s.codigo] = (await QRCode.toString(registroLink(s.codigo), {
    errorCorrectionLevel: "M", margin: 1,
    color: { dark: INKQR, light: PAPER }, type: "svg", width: 600,
  })).replace(/<svg /, '<svg style="width:100%;height:100%;display:block" ');
}

const cara = (v, s) => `
    <section class="card">
      ${ripples(v)}
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
        <div class="qr">${qrCache[s.codigo]}</div>
      </div>
    </section>`;

const doc = (v, s) => `<!doctype html><html lang="es"><head><meta charset="utf-8">
<style>
  @import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700;900&family=Jost:wght@300;400;500&display=swap');
  @page { size: 100mm 150mm; margin: 0; }
  *{margin:0;padding:0;box-sizing:border-box}
  html,body{width:100mm}
  body{-webkit-print-color-adjust:exact;print-color-adjust:exact}
  .card{position:relative;width:100mm;height:150mm;background:${v.paper};overflow:hidden;
    page-break-after:always;font-family:'Jost',sans-serif;color:${v.ink}}
  .card:last-child{page-break-after:auto}
  .frame{position:absolute;inset:6mm;border:0.4mm solid ${v.frame};opacity:.55;z-index:1}
  .mark{position:absolute;top:20mm;left:0;right:0;text-align:center;z-index:2}
  .mark h1{font-family:'Playfair Display',serif;font-weight:900;font-size:33pt;
    letter-spacing:.14em;line-height:1;margin-left:.14em}
  .rule{display:flex;align-items:center;justify-content:center;margin:4.5mm auto 3.5mm;width:26mm}
  .rule::before,.rule::after{content:"";height:0.5mm;flex:1;background:${v.coral};opacity:.9}
  .rule i{width:1.8mm;height:1.8mm;margin:0 2mm;background:${v.coral};transform:rotate(45deg)}
  .tag{font-weight:400;font-size:8pt;letter-spacing:.12em}
  .suc{position:absolute;top:64mm;left:0;right:0;text-align:center;z-index:2;
    font-weight:400;font-size:10.5pt;letter-spacing:.42em;margin-left:.42em}
  .lede{position:absolute;top:74mm;left:0;right:0;text-align:center;z-index:2;
    font-weight:300;font-size:7.5pt;letter-spacing:.34em;opacity:.62;margin-left:.34em}
  .qrbox{position:absolute;right:12mm;bottom:23mm;z-index:2;text-align:center}
  .qlabel{display:block;font-weight:400;font-size:6.5pt;letter-spacing:.42em;margin:0 0 2.5mm .42em;opacity:.75}
  .qr{width:31mm;height:31mm;background:${PAPER};padding:2mm;border:0.3mm solid ${v.frame}}
</style></head>
<body>${cara(v, s)}${cara(v, s)}</body></html>`;

for (const v of VARIANTES) {
  const dir = join(__dirname, "tent", v.key);
  mkdirSync(dir, { recursive: true });
  for (const s of SUCURSALES) {
    writeFileSync(join(dir, `laola-tent-${s.codigo}.html`), doc(v, s));
  }
  console.log(`Variante ${v.key} (${v.label}) -> tent/${v.key}/ (4 sucursales)`);
}
