// TENT CARDS — La Ola. Tarjeta rígida 80x120 mm (portador ranura 6 cm), DOS CARAS distintas:
//   Cara A (página 1): MEMBRESÍA  -> QR a /lealtad  (con nudge de conversión)
//   Cara B (página 2): FACTURACIÓN -> QR a /factura  (limpia, minimal)
// para base de madera con ranura (la franja inferior queda oculta).
//
// Dirección de arte: la PALETA sale del logo (azul #209ED7 y naranja #E98F23,
// muestreados del propio logo) sobre marfil claro, para que todo viva en armonía
// con el logo, que es la base. Logo real conservado y completo (fondo neutro
// recortado, sin comerse el logo). Tipografía Didone (Playfair) + Jost tracked.
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
  { codigo: "VAL", nombre: "Valle" },
  { codigo: "BRI", nombre: "Las Brisas" },
  { codigo: "CER", nombre: "Cervecería" },
  { codigo: "SOL", nombre: "Solares" },
];

// Paleta derivada del logo
const PAPER = "#FAF6EE";  // marfil claro (fondo)
const BLUE = "#1B87BC";   // azul océano del logo (títulos)
const INK = "#155E82";    // azul profundo del logo (texto/labels/marco)
const ORANGE = "#E98F23"; // naranja del logo (acento)
const QRDARK = "#123E57"; // azul muy profundo, para contraste de escaneo

const logoPng = join(__dirname, ".logo.png");
const logoTransparente = existsSync(logoPng);
const logo = logoTransparente
  ? "data:image/png;base64," + readFileSync(logoPng).toString("base64")
  : "data:image/jpeg;base64," + readFileSync(join(__dirname, "..", "..", "src", "assets", "logo-la-ola.jpeg")).toString("base64");
const logoBlend = logoTransparente ? "normal" : "multiply";

const qr = async (url) =>
  (await QRCode.toString(url, {
    errorCorrectionLevel: "M", margin: 1,
    color: { dark: QRDARK, light: PAPER }, type: "svg", width: 600,
  })).replace(/<svg /, '<svg style="width:100%;height:100%;display:block" ');

const cara = (f) => `
    <section class="card">
      <div class="frame"></div>
      <img class="logo" src="${logo}" alt="La Ola">
      <div class="rule"><i></i></div>
      <h1>${f.titulo}</h1>
      <p class="sub">${f.sub}</p>
      <div class="suc">${f.suc}</div>
      ${f.extra || ""}
      <div class="qrbox">
        ${f.qlabel ? `<span class="qlabel">${f.qlabel}</span>` : ""}
        <div class="qr">${f.svg}</div>
      </div>
    </section>`;

// Tarjeta física 80x120 mm (portador ranura 6 cm). Se compone DIRECTO a 80x120
// (sin transform: scale, que Chrome no imprime bien: perdía los QR y recortaba
// el logo). Todas las medidas van ya a escala de la tarjeta real.
const style = `
  @import url('https://fonts.googleapis.com/css2?family=Playfair+Display:ital,wght@0,700;0,900;1,700&family=Jost:wght@300;400;500&display=swap');
  @page { size: 80mm 120mm; margin: 0; }
  *{margin:0;padding:0;box-sizing:border-box}
  html,body{width:80mm}
  body{-webkit-print-color-adjust:exact;print-color-adjust:exact}
  .card{position:relative;width:80mm;height:120mm;background:${PAPER};overflow:hidden;
    page-break-after:always;font-family:'Jost',sans-serif;color:${INK}}
  .card:last-child{page-break-after:auto}
  .frame{position:absolute;inset:4.8mm;border:0.35mm solid ${INK};opacity:.4;z-index:1}
  .logo{position:absolute;top:9.6mm;left:50%;transform:translateX(-50%);z-index:2;
    height:21.6mm;width:auto;mix-blend-mode:${logoBlend}}
  .rule{position:absolute;top:35.2mm;left:50%;transform:translateX(-50%);z-index:2;
    display:flex;align-items:center;justify-content:center;width:19.2mm}
  .rule::before,.rule::after{content:"";height:0.4mm;flex:1;background:${ORANGE}}
  .rule i{width:1.45mm;height:1.45mm;margin:0 1.6mm;background:${ORANGE};transform:rotate(45deg)}
  h1{position:absolute;top:40mm;left:6.4mm;right:6.4mm;text-align:center;z-index:2;
    font-family:'Playfair Display',serif;font-weight:900;font-size:16.8pt;
    letter-spacing:.08em;color:${BLUE}}
  .sub{position:absolute;top:51.2mm;left:7.2mm;right:7.2mm;text-align:center;z-index:2;
    font-weight:400;font-size:6pt;letter-spacing:.22em;color:${INK};opacity:.7}
  .suc{position:absolute;top:59.2mm;left:6.4mm;right:6.4mm;text-align:center;z-index:2;
    font-weight:400;font-size:7.6pt;letter-spacing:.28em;color:${INK}}

  .qrbox{position:absolute;right:9.6mm;bottom:18.4mm;z-index:2;text-align:center}
  .qlabel{display:block;font-weight:400;font-size:5.2pt;letter-spacing:.3em;margin:0 0 2mm .3em;color:${INK};opacity:.75}
  .qr{width:24.8mm;height:24.8mm;background:${PAPER};padding:1.6mm;border:0.3mm solid ${INK}66}

  /* QR secundario de MENÚ: presente, sin robar protagonismo */
  .menuqr{position:absolute;left:9.6mm;bottom:19.2mm;z-index:2;text-align:center}
  .menuqr .qlabel{display:block;font-weight:400;font-size:5.2pt;letter-spacing:.3em;margin:0 0 2mm .3em;color:${INK};opacity:.75}
  .qr2{width:21.6mm;height:21.6mm;background:${PAPER};padding:1.45mm;border:0.3mm solid ${INK}66}
  .diaonly{position:absolute;left:6.4mm;right:6.4mm;bottom:10.4mm;z-index:2;text-align:center;
    font-weight:400;font-size:4.8pt;letter-spacing:.26em;color:${INK};opacity:.55}

  /* Gancho centrado (cara membresía, sobre los dos QR) */
  .hook{position:absolute;left:6.4mm;right:6.4mm;top:67.2mm;z-index:2;text-align:center;
    font-family:'Playfair Display',serif;font-style:italic;font-weight:700;
    font-size:10pt;line-height:1.15;color:${INK}}`;

for (const s of SUCURSALES) {
  const caraA = {
    titulo: "MEMBRESÍA",
    sub: "BENEFICIOS EN CADA VISITA",
    suc: s.nombre.toUpperCase(),
    qlabel: "REGÍSTRATE",
    svg: await qr(`${SITE_URL}/lealtad?suc=${s.codigo}`),
    extra: `<div class="hook">Tu regalo de bienvenida te espera.</div>
    <div class="menuqr">
      <span class="qlabel">MENÚ</span>
      <div class="qr2">${await qr(`${SITE_URL}/menu/s/${s.codigo}`)}</div>
    </div>`,
  };
  const caraB = {
    titulo: "FACTURA Y MENÚ",
    sub: "ESCANEA LO QUE NECESITES",
    suc: s.nombre.toUpperCase(),
    qlabel: "FACTURA",
    svg: await qr(`${SITE_URL}/factura?suc=${s.codigo}`),
    extra: `<div class="menuqr">
      <span class="qlabel">MENÚ</span>
      <div class="qr2">${await qr(`${SITE_URL}/menu/s/${s.codigo}`)}</div>
    </div>
    <div class="diaonly">FACTURA EL MISMO DÍA DE TU CONSUMO</div>`,
  };

  const html = `<!doctype html><html lang="es"><head><meta charset="utf-8"><style>${style}</style></head>
<body>${cara(caraA)}${cara(caraB)}</body></html>`;

  writeFileSync(join(OUT, `laola-tent-${s.codigo}.html`), html);
  console.log(`Tent card ${s.codigo} (${s.nombre}) -> paleta del logo · A: Membresía · B: Facturación`);
}
