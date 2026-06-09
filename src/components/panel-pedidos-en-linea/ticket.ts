import { dinero, ETIQUETA_ESTADO, type PedidoEnLinea } from "@/lib/pedidosEnLinea";

function escaparHtml(texto: string): string {
  return texto
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;");
}

/** Abre una vista de ticket simple y lanza window.print(). */
export function imprimirTicket(pedido: PedidoEnLinea, sucursalNombre: string): void {
  const items = (pedido.pedidos_en_linea_items ?? [])
    .map((item) => {
      const opciones = item.opciones_elegidas
        ? `<div class="sub">${escaparHtml(Object.values(item.opciones_elegidas).join(" · "))}</div>`
        : "";
      const notas = item.notas ? `<div class="sub">Nota: ${escaparHtml(item.notas)}</div>` : "";
      return `<tr>
        <td class="cant">${item.cantidad}×</td>
        <td>${escaparHtml(item.nombre_item)}${item.nombre_variante !== "Única" ? ` (${escaparHtml(item.nombre_variante)})` : ""}${opciones}${notas}</td>
        <td class="precio">${dinero(item.precio_unitario * item.cantidad)}</td>
      </tr>`;
    })
    .join("");

  const entrega =
    pedido.tipo === "reparto"
      ? `<p><strong>REPARTO</strong>${pedido.zonas_reparto?.nombre ? ` · ${escaparHtml(pedido.zonas_reparto.nombre)}` : ""}</p>
         <p>${escaparHtml(pedido.direccion ?? "")}</p>
         ${pedido.referencias ? `<p>Ref: ${escaparHtml(pedido.referencias)}</p>` : ""}`
      : `<p><strong>RECOGER EN SUCURSAL</strong></p>`;

  const html = `<!doctype html>
<html lang="es">
<head>
<meta charset="utf-8" />
<title>Pedido ${escaparHtml(pedido.folio)}</title>
<style>
  body { font-family: ui-monospace, Menlo, monospace; font-size: 13px; margin: 0; padding: 12px; width: 280px; }
  h1 { font-size: 22px; text-align: center; margin: 0 0 2px; }
  h2 { font-size: 14px; text-align: center; margin: 0 0 8px; font-weight: normal; }
  hr { border: none; border-top: 1px dashed #000; margin: 8px 0; }
  table { width: 100%; border-collapse: collapse; }
  td { vertical-align: top; padding: 2px 0; }
  .cant { width: 28px; }
  .precio { text-align: right; white-space: nowrap; }
  .sub { font-size: 11px; color: #333; }
  .total { font-size: 16px; font-weight: bold; }
  p { margin: 2px 0; }
  .centrado { text-align: center; }
</style>
</head>
<body>
  <h1>${escaparHtml(pedido.folio)}</h1>
  <h2>La Ola · ${escaparHtml(sucursalNombre)}</h2>
  <p class="centrado">${new Date(pedido.created_at).toLocaleString("es-MX")}</p>
  <hr />
  <p><strong>${escaparHtml(pedido.nombre_cliente)}</strong> · ${escaparHtml(pedido.telefono)}</p>
  ${entrega}
  ${pedido.notas_generales ? `<p>Notas: ${escaparHtml(pedido.notas_generales)}</p>` : ""}
  <hr />
  <table>${items}</table>
  <hr />
  <table>
    <tr><td>Subtotal</td><td class="precio">${dinero(pedido.subtotal)}</td></tr>
    ${Number(pedido.costo_envio) > 0 ? `<tr><td>Envío</td><td class="precio">${dinero(pedido.costo_envio)}</td></tr>` : ""}
    <tr class="total"><td>TOTAL</td><td class="precio total">${dinero(pedido.total)}</td></tr>
  </table>
  <hr />
  <p class="centrado">Pago contra entrega (efectivo o tarjeta)</p>
  <p class="centrado">Estado: ${ETIQUETA_ESTADO[pedido.estado]}</p>
</body>
</html>`;

  const ventana = window.open("", "_blank", "width=320,height=600");
  if (!ventana) return;
  ventana.document.write(html);
  ventana.document.close();
  ventana.focus();
  // pequeño retraso para que cargue el contenido antes de imprimir
  window.setTimeout(() => {
    ventana.print();
  }, 250);
}
