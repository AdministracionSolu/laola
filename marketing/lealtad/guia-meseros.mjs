// GUÍA PARA MESEROS — La Ola. Una carta (letter) explicando los tent cards de mesa:
// qué es cada cara, qué decirle al cliente y respuestas rápidas.
// Misma dirección de arte que los tent cards (paleta del logo, Playfair + Jost).
//
// Salida: tent/laola-guia-meseros.html  (PDF con Chrome headless, ver README).

import { readFileSync, writeFileSync, mkdirSync, existsSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const __dirname = dirname(fileURLToPath(import.meta.url));
const OUT = join(__dirname, "tent");
mkdirSync(OUT, { recursive: true });

const PAPER = "#FAF6EE";
const BLUE = "#1B87BC";
const INK = "#155E82";
const ORANGE = "#E98F23";

const logoPng = join(__dirname, ".logo.png");
const logoTransparente = existsSync(logoPng);
const logo = logoTransparente
  ? "data:image/png;base64," + readFileSync(logoPng).toString("base64")
  : "data:image/jpeg;base64," + readFileSync(join(__dirname, "..", "..", "src", "assets", "logo-la-ola.jpeg")).toString("base64");
const logoBlend = logoTransparente ? "normal" : "multiply";

// Mini diagrama de una cara del tent (esquema, no reproducción)
const mini = (titulo, filas) => `
  <div class="mini">
    <div class="mini-frame"></div>
    <div class="mini-title">${titulo}</div>
    ${filas}
  </div>`;

const html = `<!doctype html><html lang="es"><head><meta charset="utf-8"><style>
  @import url('https://fonts.googleapis.com/css2?family=Playfair+Display:ital,wght@0,700;0,900;1,700&family=Jost:wght@300;400;500;600&display=swap');
  @page { size: letter; margin: 0; }
  *{margin:0;padding:0;box-sizing:border-box}
  body{-webkit-print-color-adjust:exact;print-color-adjust:exact;
    font-family:'Jost',sans-serif;color:${INK};background:${PAPER}}
  .page{position:relative;width:216mm;height:279mm;padding:14mm 16mm;overflow:hidden}
  .frame{position:absolute;inset:7mm;border:0.35mm solid ${INK};opacity:.35}

  header{display:flex;align-items:center;gap:8mm;margin-bottom:5mm}
  .logo{height:20mm;width:auto;mix-blend-mode:${logoBlend}}
  .head-txt h1{font-family:'Playfair Display',serif;font-weight:900;font-size:19pt;
    letter-spacing:.04em;color:${BLUE};margin-bottom:1.5mm}
  .head-txt p{font-size:9pt;letter-spacing:.18em;opacity:.7;text-transform:uppercase}

  .rule{display:flex;align-items:center;margin:3mm 0 5mm}
  .rule::before,.rule::after{content:"";height:0.4mm;flex:1;background:${ORANGE}}
  .rule i{width:2mm;height:2mm;margin:0 2.2mm;background:${ORANGE};transform:rotate(45deg)}

  .intro{font-size:11pt;line-height:1.5;margin-bottom:6mm}

  .caras{display:flex;gap:8mm;margin-bottom:6mm}
  .cara{flex:1;display:flex;gap:5mm;align-items:flex-start}
  .mini{position:relative;flex:0 0 32mm;height:48mm;background:#fff;border:0.3mm solid ${INK}55}
  .mini-frame{position:absolute;inset:2mm;border:0.25mm solid ${INK};opacity:.35}
  .mini-title{position:absolute;top:6mm;left:0;right:0;text-align:center;
    font-family:'Playfair Display',serif;font-weight:900;font-size:7pt;color:${BLUE};letter-spacing:.06em}
  .mini .qr-g{position:absolute;right:4mm;bottom:8mm;width:12mm;height:12mm;border:0.3mm solid ${INK};
    display:flex;align-items:center;justify-content:center;font-size:4.6pt;letter-spacing:.1em;text-align:center;opacity:.8}
  .mini .qr-c{position:absolute;left:4mm;bottom:9.5mm;width:9mm;height:9mm;border:0.3mm solid ${INK};
    display:flex;align-items:center;justify-content:center;font-size:4.6pt;letter-spacing:.1em;opacity:.8}
  .mini .hookline{position:absolute;top:16mm;left:3mm;right:3mm;text-align:center;
    font-family:'Playfair Display',serif;font-style:italic;font-size:5.4pt;line-height:1.2}

  .cara-txt h2{font-family:'Playfair Display',serif;font-weight:700;font-size:13pt;color:${BLUE};margin-bottom:2mm}
  .cara-txt li{font-size:10pt;line-height:1.45;margin:0 0 2mm 4.5mm}
  .cara-txt b{font-weight:600}

  h3{font-family:'Playfair Display',serif;font-weight:700;font-size:13pt;color:${BLUE};margin:5mm 0 2.5mm}
  .frases li{font-size:10.5pt;line-height:1.5;margin:0 0 2mm 4.5mm}
  .frases em{font-style:italic}

  .faq{display:grid;grid-template-columns:1fr 1fr;gap:2.5mm 8mm}
  .faq div{font-size:10pt;line-height:1.45}
  .faq b{font-weight:600;display:block}

  .reglas li{font-size:10.5pt;line-height:1.5;margin:0 0 2mm 4.5mm}
  .reglas b{font-weight:600}
</style></head><body>
<div class="page">
  <div class="frame"></div>
  <header>
    <img class="logo" src="${logo}" alt="La Ola">
    <div class="head-txt">
      <h1>Tarjetas de mesa</h1>
      <p>Guía para meseros</p>
    </div>
  </header>
  <div class="rule"><i></i></div>

  <p class="intro">Cada mesa tiene una tarjeta en una base de madera. Tiene dos caras y el cliente
  escanea los QR con la cámara de su celular. El cliente lo hace todo solo y tú no capturas nada.</p>

  <div class="caras">
    <div class="cara">
      ${mini("MEMBRESÍA", `
        <div class="hookline">Tu regalo de<br>bienvenida te espera.</div>
        <div class="qr-g">QR<br>REGÍSTRATE</div>
        <div class="qr-c">QR<br>MENÚ</div>`)}
      <div class="cara-txt">
        <h2>Cara A · Membresía</h2>
        <ul>
          <li><b>QR grande:</b> el cliente se registra en el programa de lealtad. Es gratis y recibe un regalo de bienvenida.</li>
          <li><b>QR chico:</b> abre el menú de la sucursal.</li>
        </ul>
      </div>
    </div>
    <div class="cara">
      ${mini("FACTURA Y MENÚ", `
        <div class="qr-g">QR<br>FACTURA</div>
        <div class="qr-c">QR<br>MENÚ</div>`)}
      <div class="cara-txt">
        <h2>Cara B · Factura</h2>
        <ul>
          <li><b>QR grande:</b> el cliente captura sus datos fiscales y los datos de su ticket. Contabilidad emite la factura después.</li>
          <li><b>QR chico:</b> el mismo menú.</li>
          <li>La factura se pide <b>el mismo día del consumo</b>.</li>
        </ul>
      </div>
    </div>
  </div>

  <h3>Qué decir</h3>
  <ul class="frases">
    <li>Al entregar la mesa: <em>"En la tarjeta está el QR del menú."</em></li>
    <li>Al cobrar: <em>"¿Ya tiene su membresía? El registro está en la tarjeta y trae un regalo de bienvenida."</em></li>
    <li>Si piden factura: <em>"Escanee el QR de factura y llene sus datos con su ticket a la mano. Se pide hoy mismo."</em></li>
  </ul>

  <h3>Respuestas rápidas</h3>
  <div class="faq">
    <div><b>¿La membresía cuesta?</b>No. Es gratis y trae regalo de bienvenida.</div>
    <div><b>¿La factura sale al momento?</b>No. El cliente deja sus datos y contabilidad la emite.</div>
    <div><b>¿Puedo facturar otro día?</b>No. Se pide el mismo día del consumo.</div>
    <div><b>¿Necesito el ticket para facturar?</b>Sí. El formulario pide los datos del ticket.</div>
  </div>

  <h3>Cuidados de la tarjeta</h3>
  <ul class="reglas">
    <li>La tarjeta vive en su base, con la cara de <b>Membresía</b> hacia el cliente.</li>
    <li>Cada tarjeta es de su sucursal. <b>No se mueven entre sucursales:</b> los QR llevan el código de la sucursal.</li>
    <li>Si el cliente no puede escanear, ayúdale con su celular. No captures sus datos por él.</li>
    <li>Si una tarjeta se maltrata o se pierde, avisa a tu gerente.</li>
  </ul>
</div>
</body></html>`;

writeFileSync(join(OUT, "laola-guia-meseros.html"), html);
console.log("Guía para meseros -> tent/laola-guia-meseros.html");
