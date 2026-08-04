// GameStore TV - Configuracion del engine Flutter (DE.1 / SA.2.A)
// Usa el CanvasKit LOCAL (build/web/canvaskit/) en lugar de gstatic.com:
//  - Cumple la CSP estricta `script-src 'self'` (sin dependencias externas).
//  - Funciona sin conexion y es cacheable por el Service Worker.
window.flutterConfiguration = {
  canvasKitBaseUrl: "canvaskit/",
};
