// Genera las TENT CARDS del programa de lealtad de La Ola: una tarjeta rígida
// vertical por sucursal, con el QR en la esquina inferior derecha. Pensada para
// insertarse en una base de madera con ranura: la franja inferior (~16 mm) queda
// oculta dentro de la base, por eso ahí no va contenido importante.
//
// Tamaño: 100 x 150 mm (con @page para que el PDF salga exacto).
// Salida: marketing/lealtad/tent/laola-tent-<CODE>.html
// El PDF se genera aparte con Chrome headless (ver render-pdf en el flujo).

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

const logoJpeg = readFileSync(join(__dirname, "..", "..", "src", "assets", "logo-la-ola.jpeg"));
const logo = "data:image/jpeg;base64," + logoJpeg.toString("base64");

const qrOpts = {
  errorCorrectionLevel: "M",
  margin: 1,
  color: { dark: "#0d5a86", light: "#ffffff" },
  type: "svg",
  width: 600,
};

for (const s of SUCURSALES) {
  const svg = (await QRCode.toString(registroLink(s.codigo), qrOpts))
    .replace(/<svg /, '<svg style="width:100%;height:100%;display:block" ');

  const html = `<!doctype html>
<html lang="es"><head><meta charset="utf-8">
<style>
  @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=Playfair+Display:wght@700;800;900&display=swap');
  @page { size: 100mm 150mm; margin: 0; }
  :root{ --ocean:#0d5a86; --ocean2:#2a93c7; --coral:#f97316; --coral2:#fb9a4b; --sand:#f5efe2; --ink:#0e2a3a; }
  *{margin:0;padding:0;box-sizing:border-box}
  html,body{width:100mm;height:150mm}
  body{font-family:Inter,system-ui,sans-serif;color:var(--ink);position:relative;overflow:hidden;background:#fff;
    -webkit-print-color-adjust:exact;print-color-adjust:exact}

  /* Ola superior */
  .header{position:absolute;top:0;left:0;right:0;height:45mm;
    background:linear-gradient(135deg,var(--ocean),var(--ocean2));
    border-radius:0 0 55% 55% / 0 0 100% 100%}
  .logo{position:absolute;top:8.5mm;left:50%;transform:translateX(-50%);z-index:3;
    height:23mm;background:#fff;padding:2mm 4mm;border-radius:12px;box-shadow:0 3px 10px rgba(0,0,0,.15)}
  .badge{position:absolute;top:39mm;left:50%;transform:translateX(-50%);z-index:3;
    background:var(--coral);color:#fff;font-weight:700;font-size:11.5pt;letter-spacing:.02em;
    padding:4px 18px;border-radius:999px;box-shadow:0 3px 8px rgba(249,115,22,.35);white-space:nowrap}

  /* Hero */
  .hero{position:absolute;top:52mm;left:8mm;right:8mm;text-align:center;z-index:2}
  .hero h1{font-family:'Playfair Display',serif;font-weight:900;font-size:23pt;line-height:1.02;color:var(--ocean)}
  .hero p{font-size:10.5pt;color:#33556a;margin-top:2mm}
  .hero p b{color:var(--coral)}

  /* Bloque de abajo: texto a la izquierda, QR en la esquina derecha */
  .cta{position:absolute;left:8mm;bottom:30mm;width:44mm;z-index:2}
  .cta .n{display:inline-flex;align-items:center;gap:2mm;font-size:9pt;color:#33556a;margin-bottom:2mm}
  .cta .n span{width:5.4mm;height:5.4mm;flex:none;background:var(--ocean);color:#fff;border-radius:50%;
    font-weight:700;font-size:7.5pt;display:flex;align-items:center;justify-content:center}

  .qrwrap{position:absolute;right:7mm;bottom:26mm;width:37mm;text-align:center;z-index:2}
  .qrtag{display:inline-block;background:var(--coral);color:#fff;font-weight:700;font-size:8.5pt;
    padding:2px 12px;border-radius:999px;margin-bottom:2mm}
  .qr{width:37mm;height:37mm;padding:2.4mm;background:#fff;border:2px solid var(--sand);
    border-radius:12px;box-shadow:0 4px 12px rgba(13,42,58,.12)}

  /* Franja inferior: entra en la ranura de la base (contenido no crítico) */
  .slot{position:absolute;left:0;right:0;bottom:0;height:16mm;
    background:linear-gradient(135deg,var(--coral),var(--coral2));
    border-radius:55% 55% 0 0 / 100% 100% 0 0;
    display:flex;align-items:flex-end;justify-content:center;padding-bottom:3mm}
  .slot span{color:#fff;font-weight:600;font-size:8pt;opacity:.9;letter-spacing:.03em}
</style></head>
<body>
  <div class="header"></div>
  <img class="logo" src="${logo}" alt="La Ola">
  <div class="badge">${s.nombre}</div>

  <div class="hero">
    <h1>Únete a La&nbsp;Ola</h1>
    <p>Escanea y recibe tu <b>regalo de bienvenida</b> 🦐</p>
  </div>

  <div class="cta">
    <div class="n"><span>1</span> Apunta tu cámara</div>
    <div class="n"><span>2</span> Deja tus datos (30&nbsp;seg)</div>
    <div class="n"><span>3</span> Listo, eres parte de La&nbsp;Ola 🌊</div>
  </div>

  <div class="qrwrap">
    <div class="qrtag">Escanéame</div>
    <div class="qr">${svg}</div>
  </div>

  <div class="slot"><span>laola.mx</span></div>
</body></html>`;

  writeFileSync(join(OUT, `laola-tent-${s.codigo}.html`), html);
  console.log(`Tent card ${s.codigo} (${s.nombre}) -> tent/laola-tent-${s.codigo}.html`);
}
