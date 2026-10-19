// Service Worker de avisos de Mi Cancha (solo web). Vive en /push/ para no
// chocar con flutter_service_worker.js. Los push llegan aunque la app esté
// cerrada: el navegador despierta este archivo.

self.addEventListener('push', (event) => {
  const data = event.data ? event.data.json() : {};
  const title = data.title || 'Mi Cancha';
  const url = data.url || '/negocio/reservas';

  event.waitUntil(
    (async () => {
      await self.registration.showNotification(title, {
        body: data.body,
        tag: data.tag,
        icon: '/icons/Icon-192.png',
        // Imagen grande del aviso del admin; se ignora donde no se soporta.
        image: data.image,
        data: { url, ...(data.data || {}) },
      });

      // Si la app está abierta, avisarle para que recargue la agenda.
      const clients = await self.clients.matchAll({
        type: 'window',
        includeUncontrolled: true,
      });
      const type = (data.data && data.data.type) || 'NEW_RESERVATION';
      clients.forEach((client) => client.postMessage({ type }));
    })(),
  );
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const url = (event.notification.data && event.notification.data.url) || '/negocio/reservas';

  event.waitUntil(
    (async () => {
      const clients = await self.clients.matchAll({
        type: 'window',
        includeUncontrolled: true,
      });
      for (const client of clients) {
        if ('focus' in client && 'navigate' in client) {
          await client.focus();
          return client.navigate(url);
        }
      }
      return self.clients.openWindow(url);
    })(),
  );
});
