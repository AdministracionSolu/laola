// Kill-switch service worker.
// Reemplaza al SW viejo generado por vite-plugin-pwa que estaba
// cacheando una versión obsoleta de /pedidos en Safari iOS y
// causaba redirecciones incorrectas.
// Borra solo los cachés propios del SW de la app (Workbox)
// para no tocar cachés de Firebase Messaging u otros.

function isWorkboxCacheForThisRegistration(name) {
  const hasWorkboxBucket = /(^|-)precache-v\d+-|(^|-)runtime-|(^|-)googleAnalytics-|supabase-api/.test(name);
  return hasWorkboxBucket;
}

self.addEventListener("install", () => self.skipWaiting());

self.addEventListener("activate", (event) =>
  event.waitUntil(
    (async () => {
      try {
        const cacheNames = await caches.keys();
        const toDelete = cacheNames.filter(isWorkboxCacheForThisRegistration);
        await Promise.allSettled(toDelete.map((name) => caches.delete(name)));
        await self.clients.claim();
        const windowClients = await self.clients.matchAll({ type: "window" });
        await Promise.allSettled(
          windowClients.map((client) => client.navigate(client.url))
        );
      } finally {
        await self.registration.unregister();
      }
    })()
  )
);
