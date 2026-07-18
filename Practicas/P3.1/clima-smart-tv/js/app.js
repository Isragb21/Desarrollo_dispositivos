// js/app.js
// ── Reloj en tiempo real ───────────────────────────────────
function updateClock() {
 const now = new Date();
 document.getElementById('currentTime').textContent =
 now.toLocaleTimeString('es-MX', { hour:'2-digit', minute:'2-digit' });
}
setInterval(updateClock, 1000);
updateClock();

// ── Cambiar POSTER al navegar (Focus) ──────────────────────
function setPoster(condition) {
 const media = getMediaConfig(condition);
 const video = document.getElementById('bgVideo');
 const source = video.querySelector('source[type="video/mp4"]');

 video.pause();
 video.currentTime = 0;
 video.removeAttribute('src');
 video.load();

 if (source) {
  source.removeAttribute('src');
 }

 video.poster = media.poster;

 // Actualizamos background por si el autoplay está bloqueado
 document.body.style.backgroundImage = `url(${media.poster})`;
 document.body.style.backgroundSize = 'cover';
 document.body.style.backgroundPosition = 'center';
}

// ── Reproducir VIDEO al seleccionar (Enter/Click) ──────────
function playVideo(condition) {
 const media = getMediaConfig(condition);
 const video = document.getElementById('bgVideo');
 const source = video.querySelector('source[type="video/mp4"]');

 if (source) {
  source.src = media.video;
 }

 video.currentTime = 0;
 video.load();
 video.play().catch(() => {});
}

// ── Renderizar tarjeta ─────────────────────────────────────
function renderCard(cardId, data) {
 const card = document.getElementById(cardId);
 card.querySelector('.city-name').textContent = data.city;
 card.querySelector('.temperature').textContent = `${data.temperature}°C`;
 card.querySelector('.condition').textContent = data.description;
 card.querySelector('.details').textContent =
 `Humedad: ${data.humidity}% | Viento: ${data.windSpeed} m/s`;
}

// ── Manejar Foco (Cambiar poster) ──────────────────────────
document.addEventListener('card-focus', e => {
 const idx = parseInt(e.detail.cardId.replace('card', ''));
 if (window._weatherData?.[idx]) {
  const data = window._weatherData[idx];
  setPoster(data.condition);
 }
});

// ── Manejar Selección (Reproducir video) ───────────────────
document.addEventListener('card-select', e => {
 const idx = parseInt(e.detail.cardId.replace('card', ''));
 if (window._weatherData?.[idx]) {
  const data = window._weatherData[idx];
  playVideo(data.condition);
  document.getElementById('cityName').textContent = data.city;
 }
});

// ── Cargar datos al iniciar ────────────────────────────────
async function init() {
 try {
  const data = await fetchAllCities();
  window._weatherData = data;
  data.forEach((d, i) => renderCard(`card${i}`, d));
  
  // Poster inicial
  setPoster(data[0].condition);
  document.getElementById('cityName').textContent = data[0].city;
 } catch (err) {
  console.error('Error cargando clima:', err.message);
  document.getElementById('cityName').textContent = 'Error de conexion';
 }
}

// ── Registrar Service Worker ───────────────────────────────
if ('serviceWorker' in navigator) {
 navigator.serviceWorker.register('/sw.js')
 .then(reg => console.log('SW registrado:', reg.scope))
 .catch(err => console.error('SW error:', err));
}
init();
// Refrescar datos cada 10 minutos
setInterval(init, 10 * 60 * 1000);
