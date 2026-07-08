# Material del programa de lealtad — La Ola

Material físico para captar clientes al programa de lealtad. El cliente escanea un
QR en la mesa → se abre el formulario `/lealtad?suc=CODE` → pone nombre + teléfono +
consentimiento → queda registrado. Cada sucursal tiene su propio QR con código de
atribución para saber dónde se captó (sin fragmentar el perfil). Las comunicaciones
(bienvenida, cumpleaños, promos) las opera Makatea, que jala esta lista.

## Contenido

- `generar.mjs` — genera los 4 QR y el HTML imprimible. Único archivo que se edita.
- `qr/laola-VAL.svg|.png` … — QR por sucursal (VAL, BRI, CER, SOL). Úsalos sueltos en menús, redes, etc.
- `flyers.html` — carpas de mesa A5 imprimibles, una por sucursal. Abre y "Imprimir / Guardar PDF".

Guía de dónde va cada pieza en piso: [`docs/lealtad-colocacion.md`](../../docs/lealtad-colocacion.md).

## Cómo regenerar (cuando haya dominio real)

Los QR actuales son DEMO (dominio placeholder). Para dejarlos listos:

1. Edita `generar.mjs` y pon el dominio real del sitio en `SITE_URL`
   (sin slash final, ej. `https://laola.mx`).
2. Corre:
   ```sh
   node marketing/lealtad/generar.mjs
   ```
3. Se regeneran `qr/` y `flyers.html`. Cuando el dominio es real, desaparece la
   marca naranja "QR DEMO" del flyer.

## Detalles técnicos

- El QR codifica `https://<sitio>/lealtad?suc=CODE`. La página lee `?suc=` y guarda
  la sucursal de captación vía la RPC `lealtad_registrar`.
- Los códigos (VAL, BRI, CER, SOL) reusan el `prefijo_folio` que ya existe en la
  tabla `sucursales`, para no inventar identificadores nuevos.
- El logo se lee directo de `src/assets/logo-la-ola.jpeg`; los colores salen de
  la marca (azul océano `#0d5a86`, coral `#f97316`).
- Depende del paquete `qrcode` (ya en el `package.json` del repo).
