// GameStore TV - Registro del Service Worker personalizado
// (Cache First / Network First). Archivo externo para cumplir la CSP
// `script-src 'self'` (los scripts inline quedan bloqueados).
if ('serviceWorker' in navigator) {
  window.addEventListener('load', function () {
    navigator.serviceWorker.register('sw.js').then(function (reg) {
      console.log('[GameStoreTV] SW registrado:', reg.scope);
    }).catch(function (err) {
      console.error('[GameStoreTV] Error registrando SW:', err);
    });
  });
}
