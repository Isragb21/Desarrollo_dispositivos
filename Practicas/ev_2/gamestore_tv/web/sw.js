/* GameStore TV - Service Worker
 * Estrategias (SA.2.A):
 *  - CACHE FIRST  : estáticos de la app (app shell)
 *  - NETWORK FIRST: datos de la API (con fallback a cache)
 *  - OFFLINE      : navegaciones sirven index.html cacheado
 */

const APP_SHELL_CACHE = 'gamestore-tv-shell-v2';
const API_CACHE = 'gamestore-tv-api-v2';
const VIDEO_CACHE = 'gamestore-tv-videos-v2';
const OFFLINE_URL = 'offline.html';

const API_ORIGINS = [
  'http://localhost:3000',
  'http://10.0.2.2:3000',
  'http://127.0.0.1:3000',
];

const PRECACHE_URLS = [
  './',
  './index.html',
  './manifest.json',
  './icons/Icon-192.png',
  './icons/Icon-512.png',
  './icons/Icon-maskable-192.png',
  './icons/Icon-maskable-512.png',
  './offline.html',
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(APP_SHELL_CACHE)
      .then((cache) => cache.addAll(PRECACHE_URLS))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(
        keys
          .filter((k) => k !== APP_SHELL_CACHE && k !== API_CACHE && k !== VIDEO_CACHE)
          .map((k) => caches.delete(k))
      ))
      .then(() => self.clients.claim())
  );
});

function isApiRequest(url) {
  return API_ORIGINS.some((origin) => url.startsWith(origin)) || url.includes('/api/');
}

function isNavigation(url) {
  const parsed = new URL(url);
  return parsed.pathname === '/' || parsed.pathname.endsWith('/index.html') || parsed.pathname.endsWith('/');
}

// CACHE FIRST para estáticos
async function cacheFirst(request) {
  const cached = await caches.match(request);
  if (cached) return cached;
  const response = await fetch(request);
  if (response && response.ok) {
    const cache = await caches.open(APP_SHELL_CACHE);
    cache.put(request, response.clone());
  }
  return response;
}

// CACHE FIRST para videos: se cachean bajo demanda (lazy load), NO en el
// precache del app shell (DE.1: solo carga el video de la condición activa).
async function videoCacheFirst(request) {
  const cache = await caches.open(VIDEO_CACHE);
  const cached = await cache.match(request);
  if (cached) return cached;
  const response = await fetch(request);
  if (response && response.ok) {
    cache.put(request, response.clone());
  }
  return response;
}

// NETWORK FIRST para API, con fallback a cache
async function networkFirst(request) {
  const cache = await caches.open(API_CACHE);
  try {
    const response = await fetch(request);
    if (response && response.ok) {
      cache.put(request, response.clone());
      return response;
    }
    throw new Error('API no disponible');
  } catch (err) {
    const cached = await cache.match(request);
    if (cached) return cached;
    const lastResponse = await caches.match(request, { ignoreSearch: true });
    if (lastResponse) return lastResponse;
    return new Response(JSON.stringify({ error: 'Sin conexión' }), {
      status: 503,
      headers: { 'Content-Type': 'application/json' },
    });
  }
}

self.addEventListener('fetch', (event) => {
  const url = event.request.url;

  if (event.request.method !== 'GET') return;

  // Navegaciones offline -> index.html cacheado
  if (event.request.mode === 'navigate') {
    event.respondWith(
      caches.match(OFFLINE_URL).then((offline) => {
        return cacheFirst(event.request).catch(() => {
          return offline || caches.match('./index.html');
        });
      })
    );
    return;
  }

  if (isApiRequest(url)) {
    event.respondWith(networkFirst(event.request));
    return;
  }

  // Videos de fondo: caché dedicada bajo demanda
  if (url.includes('/videos/') && (url.endsWith('.mp4') || url.endsWith('.webm'))) {
    event.respondWith(videoCacheFirst(event.request));
    return;
  }

  event.respondWith(cacheFirst(event.request));
});
