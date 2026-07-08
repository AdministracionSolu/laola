# La Ola · Colocación del programa de lealtad en piso

Guía para poner los QR y flyers en las 4 sucursales. El objetivo es máxima captación con mínima fricción: que el cliente escanee sentado, mientras espera o al pagar.

Cómo funciona: el QR abre el formulario `/lealtad?suc=CODE`. El cliente pone nombre + teléfono + acepta, y queda registrado (pantalla de "¡Gracias!"). Makatea jala esa lista para comunicarle después. No hay número de WhatsApp de por medio en la captación.

## Códigos por sucursal

Cada sucursal tiene su propio QR con el código de atribución (reusa el prefijo de folio que ya vive en la BD). Sirve solo para saber dónde se captó al cliente; NO fragmenta el perfil (un teléfono = un perfil, unificado entre las 4).

| Sucursal    | Código | QR                     | Flyer          |
|-------------|--------|------------------------|----------------|
| Del Valle   | `VAL`  | `qr/laola-VAL.png/.svg`| flyers.html p.1|
| Las Brisas  | `BRI`  | `qr/laola-BRI.png/.svg`| flyers.html p.2|
| Cervecería  | `CER`  | `qr/laola-CER.png/.svg`| flyers.html p.3|
| Solares     | `SOL`  | `qr/laola-SOL.png/.svg`| flyers.html p.4|

> Importante: cada sucursal SOLO usa su propio QR. Si en Las Brisas cuelgan el QR de Del Valle, la atribución sale mal.

## Dónde colocar (por sucursal, mismo patrón en las 4)

1. **Carpa de mesa (la pieza principal).** Una en cada mesa. Es lo que el cliente ve sentado esperando. Impresa a doble cara o en soporte de acrílico tipo "tent". Tamaño A5.
2. **En la cuenta / al pagar.** Un sticker o mini-flyer del mismo QR junto a la terminal o dentro del portacuentas. El mejor momento para registrarse es justo después de comer contento.
3. **Entrada / recepción.** Un póster tamaño carta o A4 a la vista mientras esperan mesa.
4. **Opcional: menú.** El QR chico impreso en una esquina del menú físico.

## Reglas de impresión y montaje

- **Tamaño mínimo del QR impreso: 3 x 3 cm.** Debajo de eso falla el escaneo desde la distancia de una mesa. En la carpa de mesa va a ~5 cm, correcto.
- **Contraste:** el QR es azul océano sobre blanco. No lo imprimas sobre fondo de color ni encima de fotos.
- **Zona quieta:** deja el marco blanco alrededor del QR (ya viene en el diseño). No lo recortes al ras.
- **Prueba antes de mandar a imprimir en lote:** escanea el PDF final desde el celular. Debe abrir el formulario `/lealtad` con la sucursal correcta en el badge (ej. "Del Valle" para el QR `VAL`).
- **Laminar o acrílico** las carpas de mesa: sobreviven salpicaduras y limón.

## Antes de imprimir (obligatorio)

Los QR actuales son **DEMO**: apuntan a un dominio placeholder. Antes de mandar a imprimir:

1. Pon el dominio real del sitio de La Ola en `marketing/lealtad/generar.mjs` (`SITE_URL`).
2. Corre `node marketing/lealtad/generar.mjs`.
3. Verifica que el aviso naranja "QR DEMO" ya NO aparezca en `flyers.html`.
4. Escanea cada QR y confirma que abre el formulario con la sucursal correcta.

## Checklist de lanzamiento en piso

- [ ] Migración `20260707120000_lealtad.sql` aplicada en Lovable (crea la tabla y la RPC).
- [ ] Dominio real configurado en `SITE_URL` y QR regenerados (sin marca DEMO).
- [ ] Cada QR escaneado y probado en un celular (abre el formulario con la sucursal correcta).
- [ ] Registro de prueba real que llega al dashboard `/admin/lealtad` con su sucursal.
- [ ] Carpas de mesa impresas A5, laminadas o en acrílico, una por mesa.
- [ ] Stickers/mini-flyers en el área de cobro de cada sucursal.
- [ ] Póster en la entrada de cada sucursal.
- [ ] **Cada sucursal recibió SOLO su propio QR** (VAL a Del Valle, BRI a Las Brisas, etc.).
- [ ] Aviso de privacidad publicado en la URL que aparece en el flyer (`/privacidad`).
- [ ] La lista de La Ola conectada a Makatea para las comunicaciones.
- [ ] Meseros/cajeros saben qué es el regalo de bienvenida y cómo se muestra.
- [ ] Prueba de punta a punta: alguien se registra desde una mesa real y aparece en el dashboard.
