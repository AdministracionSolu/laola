// Prepara el logo con fondo transparente para las tent cards.
// El logo original es JPEG con fondo blanco; sips lo pasa a PNG y aquí
// recortamos el blanco a transparente para que flote sobre el papel arena.
// Salida: marketing/lealtad/.logo.png  (lo consume tent-cards.mjs)

import { execFileSync } from "node:child_process";
import { readFileSync, writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";
import { PNG } from "pngjs";

const __dirname = dirname(fileURLToPath(import.meta.url));
const src = join(__dirname, "..", "..", "src", "assets", "logo-la-ola.jpeg");
const tmpPng = join(__dirname, ".logo-opaque.png");
const out = join(__dirname, ".logo.png");

// JPEG -> PNG con sips (nativo macOS)
execFileSync("/usr/bin/sips", ["-s", "format", "png", src, "--out", tmpPng], { stdio: "ignore" });

const png = PNG.sync.read(readFileSync(tmpPng));
const d = png.data;
let keyed = 0;
for (let i = 0; i < d.length; i += 4) {
  const r = d[i], g = d[i + 1], b = d[i + 2];
  // Solo el fondo casi-blanco puro: el centro crema del logo (b más bajo) se conserva.
  if (r > 238 && g > 238 && b > 238) { d[i + 3] = 0; keyed++; }
}
writeFileSync(out, PNG.sync.write(png));
console.log(`Logo transparente -> .logo.png (${png.width}x${png.height}, ${keyed} px recortados)`);
