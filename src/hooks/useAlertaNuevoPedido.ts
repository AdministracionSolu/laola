import { useCallback, useEffect, useRef } from "react";

/**
 * Alerta de pedido nuevo para el panel de sucursal:
 * tono corto (Web Audio) repetido + título de pestaña parpadeante,
 * hasta que el staff interactúe con la página.
 */
export function useAlertaNuevoPedido() {
  const audioRef = useRef<AudioContext | null>(null);
  const sonidoRef = useRef<number | null>(null);
  const tituloRef = useRef<number | null>(null);
  const tituloOriginal = useRef<string>(document.title);

  const beep = useCallback(() => {
    try {
      if (!audioRef.current) {
        type ConWebkit = typeof window & { webkitAudioContext?: typeof AudioContext };
        const Ctor = window.AudioContext ?? (window as ConWebkit).webkitAudioContext;
        if (!Ctor) return;
        audioRef.current = new Ctor();
      }
      const ctx = audioRef.current;
      if (ctx.state === "suspended") void ctx.resume();
      // Dos tonos cortos (din-don)
      [0, 0.22].forEach((offset, i) => {
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.type = "sine";
        osc.frequency.value = i === 0 ? 880 : 660;
        gain.gain.setValueAtTime(0.0001, ctx.currentTime + offset);
        gain.gain.exponentialRampToValueAtTime(0.4, ctx.currentTime + offset + 0.02);
        gain.gain.exponentialRampToValueAtTime(0.0001, ctx.currentTime + offset + 0.18);
        osc.connect(gain).connect(ctx.destination);
        osc.start(ctx.currentTime + offset);
        osc.stop(ctx.currentTime + offset + 0.2);
      });
    } catch {
      // sin audio disponible: el parpadeo del título sigue funcionando
    }
  }, []);

  const detener = useCallback(() => {
    if (sonidoRef.current !== null) {
      window.clearInterval(sonidoRef.current);
      sonidoRef.current = null;
    }
    if (tituloRef.current !== null) {
      window.clearInterval(tituloRef.current);
      tituloRef.current = null;
      document.title = tituloOriginal.current;
    }
  }, []);

  const iniciar = useCallback(() => {
    if (sonidoRef.current !== null) return; // ya está sonando
    beep();
    sonidoRef.current = window.setInterval(beep, 3000);
    let alterna = false;
    tituloRef.current = window.setInterval(() => {
      alterna = !alterna;
      document.title = alterna ? "🔔 ¡PEDIDO NUEVO!" : tituloOriginal.current;
    }, 1000);
  }, [beep]);

  // Cualquier interacción del staff apaga la alerta
  useEffect(() => {
    window.addEventListener("pointerdown", detener);
    window.addEventListener("keydown", detener);
    return () => {
      window.removeEventListener("pointerdown", detener);
      window.removeEventListener("keydown", detener);
      detener();
    };
  }, [detener]);

  return { iniciar, detener };
}
