// Generador de material del programa de lealtad de La Ola.
// Produce los 4 QR (uno por sucursal) y el HTML imprimible con los flyers de mesa.
//
// Cada QR apunta al formulario de registro con la sucursal en el parámetro:
//   https://<sitio>/lealtad?suc=VAL
// El cliente escanea, llena nombre + teléfono + consentimiento, y listo. Makatea
// jala esa lista para las comunicaciones. No se necesita número de WhatsApp aquí.
//
// Uso:
//   1. Pon el dominio real del sitio de La Ola en SITE_URL.
//   2. node marketing/lealtad/generar.mjs
//   3. Salida en marketing/lealtad/qr/ y marketing/lealtad/flyers.html
//
// Al cambiar el dominio solo se corre de nuevo: nada más se toca aquí.

import QRCode from "qrcode";
import { readFileSync, writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const __dirname = dirname(fileURLToPath(import.meta.url));

// ─────────────────────────────────────────────────────────────
// CONFIG — lo único que se edita
// ─────────────────────────────────────────────────────────────

// Dominio del sitio de La Ola (sin slash final). El QR abre <SITE_URL>/lealtad?suc=CODE.
// PLACEHOLDER: cámbialo por el dominio real antes de imprimir.
const SITE_URL = "https://ejemplo-laola.mx";

// El código de cada sucursal reutiliza el prefijo de folio que ya vive en la BD
// (VAL, BRI, CER, SOL). El bot de Makatea lo parsea del texto entre corchetes
// para atribuir dónde se captó al cliente sin fragmentar el perfil.
const SUCURSALES = [
  { codigo: "VAL", nombre: "Del Valle" },
  { codigo: "BRI", nombre: "Las Brisas" },
  { codigo: "CER", nombre: "Cervecería" },
  { codigo: "SOL", nombre: "Solares" },
];

// URL de registro por sucursal. El código (VAL/BRI/CER/SOL) viaja en ?suc= para
// la atribución; la página lo lee y lo guarda como sucursal_captacion.
const registroLink = (codigo) => `${SITE_URL}/lealtad?suc=${codigo}`;

const PLACEHOLDER = SITE_URL.includes("ejemplo-laola");

// ─────────────────────────────────────────────────────────────
// Generación de QR
// ─────────────────────────────────────────────────────────────

const qrOpts = {
  errorCorrectionLevel: "M",
  margin: 1,
  color: { dark: "#0d5a86", light: "#ffffff" }, // azul océano La Ola
};

const svgPorSucursal = {};

for (const s of SUCURSALES) {
  const link = registroLink(s.codigo);
  const svg = await QRCode.toString(link, { ...qrOpts, type: "svg", width: 900 });
  svgPorSucursal[s.codigo] = svg;
  writeFileSync(join(__dirname, "qr", `laola-${s.codigo}.svg`), svg);
  await QRCode.toFile(join(__dirname, "qr", `laola-${s.codigo}.png`), link, {
    ...qrOpts,
    width: 1200,
  });
  console.log(`QR ${s.codigo} (${s.nombre}) -> qr/laola-${s.codigo}.png/.svg`);
}

// ─────────────────────────────────────────────────────────────
// Flyers imprimibles (carpa de mesa, una por sucursal)
// ─────────────────────────────────────────────────────────────

const logoJpeg = readFileSync(join(__dirname, "..", "..", "src", "assets", "logo-la-ola.jpeg"));
const logo = "data:image/jpeg;base64," + logoJpeg.toString("base64");

// Inserta el SVG del QR quitando el ancho fijo para que escale al contenedor.
const qrInline = (codigo) =>
  svgPorSucursal[codigo].replace(/<svg /, '<svg style="width:100%;height:100%" ');

const tarjeta = (s) => `
  <section class="card">
    <div class="wave-top"></div>
    <img class="logo" src="${logo}" alt="La Ola Seafood" />
    <div class="badge">${s.nombre}</div>
    <h1>Únete a La&nbsp;Ola</h1>
    <p class="lead">Escanéame y recibe tu <strong>regalo de bienvenida</strong> 🦐</p>
    <div class="qr">${qrInline(s.codigo)}</div>
    <ol class="pasos">
      <li>Apunta tu cámara al código</li>
      <li>Llena tus datos (30 segundos)</li>
      <li>Listo, ya eres parte de La Ola 🌊</li>
    </ol>
    ${PLACEHOLDER ? '<div class="aviso-demo">QR DEMO · falta el dominio real del sitio</div>' : ""}
    <p class="legal">Al registrarte aceptas recibir promociones de La Ola. Puedes darte de baja cuando quieras. Aviso de privacidad: laola.mx/privacidad</p>
    <div class="wave-bot"></div>
  </section>`;

const html = `<!doctype html>
<html lang="es">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>La Ola · Flyers de lealtad</title>
<style>
  @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=Playfair+Display:wght@700;800;900&display=swap');
  :root{
    --ocean:#0d5a86; --ocean-light:#2a93c7; --coral:#f97316; --coral-light:#fb9a4b;
    --sand:#f5efe2; --ink:#0e2a3a;
  }
  *{box-sizing:border-box;margin:0;padding:0}
  body{background:#e9eef2;font-family:Inter,system-ui,sans-serif;color:var(--ink)}
  .toolbar{max-width:900px;margin:24px auto;padding:0 16px;display:flex;gap:12px;align-items:center;justify-content:space-between}
  .toolbar h2{font-family:'Playfair Display',serif;font-size:20px;color:var(--ocean)}
  .toolbar button{background:var(--ocean);color:#fff;border:0;border-radius:999px;padding:10px 20px;font-weight:600;cursor:pointer}
  .sheet{display:flex;flex-direction:column;align-items:center;gap:28px;padding:16px 0 60px}

  .card{
    position:relative;width:148mm;height:210mm; /* A5 vertical, carpa de mesa */
    background:#fff;border-radius:18px;overflow:hidden;
    box-shadow:0 10px 30px rgba(13,42,58,.18);
    display:flex;flex-direction:column;align-items:center;text-align:center;
    padding:0 14mm;
  }
  .wave-top,.wave-bot{position:absolute;left:0;right:0;height:34mm;
    background:linear-gradient(120deg,var(--ocean),var(--ocean-light))}
  .wave-top{top:0;border-radius:0 0 60% 60%/0 0 100% 100%}
  .wave-bot{bottom:0;height:16mm;background:linear-gradient(120deg,var(--coral),var(--coral-light));border-radius:60% 60% 0 0/100% 100% 0 0}
  .logo{position:relative;z-index:2;height:30mm;width:auto;margin-top:10mm;
    background:#fff;padding:2mm 4mm;border-radius:14px;box-shadow:0 4px 14px rgba(0,0,0,.12)}
  .badge{z-index:2;margin-top:5mm;background:var(--coral);color:#fff;
    font-weight:700;font-size:13pt;letter-spacing:.02em;padding:5px 20px;border-radius:999px}
  h1{z-index:2;font-family:'Playfair Display',serif;font-weight:900;
    font-size:31pt;line-height:1.02;color:var(--ocean);margin-top:5mm}
  .lead{z-index:2;font-size:12.5pt;color:#33556a;margin-top:3mm;max-width:112mm}
  .lead strong{color:var(--coral)}
  .qr{z-index:2;width:54mm;height:54mm;margin-top:5mm;padding:3.5mm;background:#fff;
    border:2px solid var(--sand);border-radius:14px}
  .pasos{z-index:2;list-style:none;counter-reset:p;margin-top:5mm;display:grid;gap:2.2mm;text-align:left}
  .pasos li{counter-increment:p;font-size:9.5pt;color:#33556a;padding-left:9mm;position:relative;line-height:1.15}
  .pasos li::before{content:counter(p);position:absolute;left:0;top:-1px;width:6.2mm;height:6.2mm;
    background:var(--ocean);color:#fff;border-radius:50%;font-weight:700;font-size:8pt;
    display:flex;align-items:center;justify-content:center}
  .aviso-demo{z-index:2;margin-top:3.5mm;font-size:8.5pt;font-weight:700;color:#b45309;
    background:#fef3c7;border:1px dashed #d97706;border-radius:8px;padding:4px 12px}
  .legal{z-index:2;font-size:7pt;color:#8aa0ad;margin-top:4mm;margin-bottom:19mm;max-width:118mm;line-height:1.35}

  @media print{
    body{background:#fff}
    .toolbar{display:none}
    .sheet{gap:0;padding:0}
    .card{box-shadow:none;border-radius:0;page-break-after:always;width:148mm;height:210mm}
  }
</style>
</head>
<body>
  <div class="toolbar">
    <h2>La Ola · Flyers de lealtad (4 sucursales)</h2>
    <button onclick="window.print()">Imprimir / Guardar PDF</button>
  </div>
  <div class="sheet">
    ${SUCURSALES.map(tarjeta).join("\n")}
  </div>
</body>
</html>`;

writeFileSync(join(__dirname, "flyers.html"), html);
console.log("\nFlyers -> marketing/lealtad/flyers.html");
console.log(PLACEHOLDER ? "\n⚠  SITE_URL = PLACEHOLDER. Cambia el dominio y vuelve a correr antes de imprimir." : "\n✔  Dominio real configurado.");
