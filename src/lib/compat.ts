/**
 * `crypto.randomUUID` para los teléfonos que no lo traen.
 *
 * Existe desde Safari 15.4, y **sólo en contextos seguros**. En un iPhone más
 * viejo —o si alguien abre la página por http— es `undefined`, y la pantalla
 * que lo llama se cae con un error que el usuario lee como "algo salió mal".
 *
 * No es hipotético: en SignSolú una liga de firma reventaba en iOS 16 por una
 * API igual de moderna, y se descubrió tres semanas después revisando
 * telemetría. Del otro lado hay gente con el teléfono que tiene, no con el que
 * nos gustaría.
 *
 * El reemplazo no es criptográfico y no tiene por qué serlo: estos ids sólo
 * nombran archivos y distinguen filas dentro de una pantalla.
 */
type CryptoConRandomUUID = Crypto & { randomUUID?: () => string };

const c = (globalThis.crypto ?? {}) as CryptoConRandomUUID;

if (typeof c.randomUUID !== 'function') {
  const aleatorio = (bytes: number) => {
    const salida = new Uint8Array(bytes);
    if (typeof c.getRandomValues === 'function') {
      c.getRandomValues(salida);
    } else {
      for (let i = 0; i < bytes; i++) salida[i] = Math.floor(Math.random() * 256);
    }
    return salida;
  };

  const uuid = () => {
    const b = aleatorio(16);
    b[6] = (b[6] & 0x0f) | 0x40; // versión 4
    b[8] = (b[8] & 0x3f) | 0x80; // variante
    const hex = Array.from(b, (n) => n.toString(16).padStart(2, '0')).join('');
    return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20)}`;
  };

  if (globalThis.crypto) {
    (globalThis.crypto as CryptoConRandomUUID).randomUUID = uuid;
  } else {
    (globalThis as unknown as { crypto: CryptoConRandomUUID }).crypto = { randomUUID: uuid } as CryptoConRandomUUID;
  }
}

export {};
