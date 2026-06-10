import { useEffect, useMemo, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { ArrowLeft, Bike, Loader2, Phone, Store } from "lucide-react";
import { toast } from "sonner";
import {
  db,
  dinero,
  guardarDatosCliente,
  itemAgotadoDeError,
  leerDatosCliente,
  mensajeErrorPedido,
  normalizarTelefono,
  type LineaCarrito,
  type SucursalEnLinea,
  type ZonaReparto,
} from "@/lib/pedidosEnLinea";

interface Props {
  sucursal: SucursalEnLinea;
  lineas: LineaCarrito[];
  subtotal: number;
  zonas: ZonaReparto[];
  onVolver: () => void;
  onPedidoCreado: () => void; // vaciar carrito
  onItemAgotado: (nombreItem: string) => void;
}

export default function Checkout({
  sucursal,
  lineas,
  subtotal,
  zonas,
  onVolver,
  onPedidoCreado,
  onItemAgotado,
}: Props) {
  const navigate = useNavigate();
  // Registro ligero: los datos del cliente se recuerdan en este dispositivo
  const recordado = useMemo(() => leerDatosCliente(), []);
  const [tipo, setTipo] = useState<"recoger" | "reparto">("recoger");
  const [nombre, setNombre] = useState(recordado?.nombre ?? "");
  const [telefono, setTelefono] = useState(recordado?.telefono ?? "");
  const [zonaId, setZonaId] = useState("");
  const [direccion, setDireccion] = useState(recordado?.direccion ?? "");
  const [referencias, setReferencias] = useState(recordado?.referencias ?? "");
  const [enviando, setEnviando] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Una sola zona de reparto: se elige sola, sin preguntar
  useEffect(() => {
    if (zonas.length === 1) setZonaId(zonas[0].id);
  }, [zonas]);

  const zona = zonas.find((z) => z.id === zonaId) ?? null;
  const costoEnvio = tipo === "reparto" && zona ? Number(zona.costo_envio) : 0;
  const total = subtotal + costoEnvio;

  const telefonoNormalizado = normalizarTelefono(telefono);
  const faltaMinimo =
    tipo === "reparto" && zona && subtotal < Number(zona.pedido_minimo)
      ? Number(zona.pedido_minimo) - subtotal
      : 0;

  const valido = useMemo(() => {
    if (lineas.length === 0) return false;
    if (nombre.trim().length < 2) return false;
    if (telefonoNormalizado.length !== 10) return false;
    if (tipo === "reparto") {
      if (!zona) return false;
      if (direccion.trim().length < 5) return false;
      if (faltaMinimo > 0) return false;
    }
    return true;
  }, [lineas.length, nombre, telefonoNormalizado, tipo, zona, direccion, faltaMinimo]);

  const enviar = async () => {
    if (!valido || enviando) return; // doble-tap: se deshabilita al primer tap
    setEnviando(true);
    setError(null);
    try {
      const { data, error: rpcError } = await db.rpc("crear_pedido_en_linea", {
        p_sucursal_id: sucursal.id,
        p_tipo: tipo,
        p_nombre_cliente: nombre.trim(),
        p_telefono: telefonoNormalizado,
        p_items: lineas.map((l) => ({
          variante_id: l.variante_id,
          cantidad: l.cantidad,
          opciones: l.opciones_elegidas,
          notas: l.notas,
        })),
        p_zona_id: tipo === "reparto" ? zonaId : null,
        p_direccion: tipo === "reparto" ? direccion.trim() : null,
        p_referencias: tipo === "reparto" ? referencias.trim() || null : null,
        p_notas_generales: null,
      });
      if (rpcError) {
        const agotado = itemAgotadoDeError(rpcError.message);
        if (agotado) onItemAgotado(agotado);
        setError(mensajeErrorPedido(rpcError.message, sucursal.telefono_contacto));
        setEnviando(false);
        return;
      }
      const resultado = data as { token: string; folio: string; tiempo_estimado_min: number };
      // Recuerda los datos para la próxima vez (sin cuentas ni contraseñas)
      guardarDatosCliente({
        nombre: nombre.trim(),
        telefono: telefonoNormalizado,
        direccion: tipo === "reparto" ? direccion.trim() : (recordado?.direccion ?? ""),
        referencias: tipo === "reparto" ? referencias.trim() : (recordado?.referencias ?? ""),
      });
      onPedidoCreado();
      toast.success(`¡Pedido ${resultado.folio} enviado!`);
      navigate(`/pedido/${resultado.token}`, { replace: true });
    } catch {
      setError(mensajeErrorPedido("", sucursal.telefono_contacto));
      setEnviando(false);
    }
  };

  return (
    <div className="max-w-lg mx-auto p-4 pb-32">
      <Button variant="ghost" className="gap-2 -ml-2 mb-2" onClick={onVolver}>
        <ArrowLeft className="h-4 w-4" /> Volver al menú
      </Button>
      <h1 className="text-2xl font-bold mb-1">Completa tu pedido</h1>
      <p className="text-muted-foreground mb-4">
        Estás ordenando en <span className="font-semibold text-foreground">{sucursal.nombre}</span>
        {" · "}
        <Link to="/ordenar" className="text-primary font-semibold underline-offset-2 underline">
          cambiar sucursal
        </Link>
        <span className="block text-xs mt-0.5">
          Si cambias, tu pedido se pasa solito a la otra sucursal.
        </span>
      </p>

      {/* Recoger / Reparto */}
      <div className="grid grid-cols-2 gap-3 mb-5">
        <Button
          variant={tipo === "recoger" ? "default" : "outline"}
          className="h-16 flex-col gap-1"
          onClick={() => setTipo("recoger")}
        >
          <Store className="h-5 w-5" />
          <span className="font-bold">Recoger</span>
        </Button>
        <Button
          variant={tipo === "reparto" ? "default" : "outline"}
          className="h-16 flex-col gap-1"
          onClick={() => setTipo("reparto")}
          disabled={zonas.length === 0}
        >
          <Bike className="h-5 w-5" />
          <span className="font-bold">A domicilio</span>
        </Button>
      </div>
      {zonas.length === 0 && (
        <p className="text-sm text-muted-foreground -mt-3 mb-4">
          Esta sucursal por ahora solo tiene pedidos para recoger.
        </p>
      )}

      <div className="space-y-4">
        <div>
          <Label htmlFor="nombre" className="text-base">Tu nombre</Label>
          <Input
            id="nombre"
            value={nombre}
            onChange={(e) => setNombre(e.target.value)}
            placeholder="¿Quién recoge / recibe?"
            className="h-12 text-base mt-1"
            maxLength={80}
          />
        </div>
        <div>
          <Label htmlFor="telefono" className="text-base">Teléfono (10 dígitos)</Label>
          <Input
            id="telefono"
            type="tel"
            inputMode="numeric"
            value={telefono}
            onChange={(e) => setTelefono(e.target.value)}
            placeholder="311 123 4567"
            className="h-12 text-base mt-1"
            maxLength={16}
          />
          {telefono.length > 0 && telefonoNormalizado.length !== 10 && (
            <p className="text-sm text-destructive mt-1">Debe tener 10 dígitos.</p>
          )}
        </div>

        {tipo === "reparto" && (
          <>
            {zonas.length === 1 ? (
              <p className="text-sm rounded-lg bg-muted px-3 py-2.5">
                Envío a domicilio: <span className="font-semibold">{dinero(Number(zonas[0].costo_envio))}</span>
                {Number(zonas[0].pedido_minimo) > 0 && ` · pedido mínimo ${dinero(Number(zonas[0].pedido_minimo))}`}
              </p>
            ) : (
              <div>
                <Label className="text-base">Zona de reparto</Label>
                <Select value={zonaId} onValueChange={setZonaId}>
                  <SelectTrigger className="h-12 text-base mt-1">
                    <SelectValue placeholder="Elige tu zona" />
                  </SelectTrigger>
                  <SelectContent>
                    {zonas.map((z) => (
                      <SelectItem key={z.id} value={z.id} className="text-base">
                        {z.nombre} · envío {dinero(Number(z.costo_envio))}
                        {Number(z.pedido_minimo) > 0 ? ` · mínimo ${dinero(Number(z.pedido_minimo))}` : ""}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
            )}
            {faltaMinimo > 0 && (
              <p className="text-sm text-destructive">
                El pedido mínimo para esta zona es {dinero(Number(zona?.pedido_minimo ?? 0))}. Te faltan {dinero(faltaMinimo)}.
              </p>
            )}
            <div>
              <Label htmlFor="direccion" className="text-base">Dirección</Label>
              <Input
                id="direccion"
                value={direccion}
                onChange={(e) => setDireccion(e.target.value)}
                placeholder="Calle, número, colonia"
                className="h-12 text-base mt-1"
                maxLength={200}
              />
            </div>
            <div>
              <Label htmlFor="referencias" className="text-base">Referencias (opcional)</Label>
              <Textarea
                id="referencias"
                value={referencias}
                onChange={(e) => setReferencias(e.target.value)}
                placeholder="Casa azul, portón negro…"
                className="text-base mt-1"
                maxLength={200}
              />
            </div>
          </>
        )}
      </div>

      {/* Resumen */}
      <div className="rounded-lg border p-4 mt-6 space-y-2">
        {lineas.map((l) => (
          <div key={l.uid} className="flex justify-between text-sm">
            <span className="text-muted-foreground">
              {l.cantidad}× {l.nombre_item}
              {l.nombre_variante !== "Única" ? ` (${l.nombre_variante})` : ""}
            </span>
            <span>{dinero(l.precio * l.cantidad)}</span>
          </div>
        ))}
        <div className="border-t pt-2 flex justify-between">
          <span>Subtotal</span>
          <span>{dinero(subtotal)}</span>
        </div>
        {tipo === "reparto" && (
          <div className="flex justify-between">
            <span>Envío</span>
            <span>{zona ? dinero(costoEnvio) : "—"}</span>
          </div>
        )}
        <div className="flex justify-between text-lg font-bold">
          <span>Total</span>
          <span>{dinero(total)}</span>
        </div>
        <p className="text-sm text-muted-foreground pt-1">
          {tipo === "recoger"
            ? "Pagas al recoger (efectivo o tarjeta)."
            : "Pagas al recibir (efectivo o tarjeta)."}
        </p>
      </div>

      {error && (
        <div className="rounded-lg border border-destructive bg-destructive/5 p-4 mt-4">
          <p className="text-destructive font-medium">{error}</p>
          {sucursal.telefono_contacto && (
            <a
              href={`tel:${sucursal.telefono_contacto}`}
              className="inline-flex items-center gap-2 mt-2 font-semibold text-primary"
            >
              <Phone className="h-4 w-4" /> Llámanos al {sucursal.telefono_contacto}
            </a>
          )}
        </div>
      )}

      <Button
        className="w-full h-14 text-lg font-bold mt-5"
        disabled={!valido || enviando}
        onClick={enviar}
      >
        {enviando ? (
          <>
            <Loader2 className="h-5 w-5 animate-spin mr-2" /> Enviando…
          </>
        ) : (
          `Enviar pedido · ${dinero(total)}`
        )}
      </Button>
    </div>
  );
}
