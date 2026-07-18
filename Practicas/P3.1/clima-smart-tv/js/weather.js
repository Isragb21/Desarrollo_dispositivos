// js/weather.js
// NOTA DE SEGURIDAD: En produccion, la API key debe ir en un
// backend proxy (Node/Express) que reciba peticiones del cliente
// y haga la llamada a OpenWeatherMap sin exponer la key.
// Para esta practica academica la declaramos como constante
// y documentamos que el archivo NO se sube a GitHub.
// En produccion: reemplazar por llamada a /api/weather?city=X
const BASE_URL = 'https://api.openweathermap.org/data/2.5/weather';
const CITIES = ['Queretaro', 'Ciudad de Mexico', 'Guadalajara', 'Monterrey'];
// Mapeo condicion -> archivo de video y poster
const VIDEO_MAP = {
 clear: { video: 'assets/videos/clear.mp4', poster: 'assets/posters/clear.jpg' },
 cloudy: { video: 'assets/videos/cloudy.mp4', poster: 'assets/posters/cloudy.jpg' },
 rain: { video: 'assets/videos/rain.mp4', poster: 'assets/posters/rain.jpg' },
 thunder: { video: 'assets/videos/thunder.mp4', poster: 'assets/posters/thunder.jpg' },
};

function normalizeCondition(condition = '') {
 const value = String(condition || '').trim().toLowerCase();
 if (['clouds', 'cloudy', 'overcast'].includes(value)) return 'cloudy';
 if (['rain', 'drizzle', 'showers', 'shower'].includes(value)) return 'rain';
 if (['thunderstorm', 'storm', 'thunder'].includes(value)) return 'thunder';
 if (['snow', 'snowy', 'sleet'].includes(value)) return 'cloudy';
 return 'clear';
}

function getMediaConfig(condition) {
 return VIDEO_MAP[normalizeCondition(condition)] || VIDEO_MAP.clear;
}

// Datos Mock hermosos para desarrollo si la API Key es la por defecto
 const MOCK_WEATHER = {
 'Queretaro': { city: 'Santiago de Querétaro', temperature: 26, condition: 'Clear', description: 'cielo despejado', humidity: 45, windSpeed: 12 },
 'Ciudad de Mexico': { city: 'Ciudad de México', temperature: 22, condition: 'Clouds', description: 'nubes dispersas', humidity: 60, windSpeed: 8 },
 'Guadalajara': { city: 'Guadalajara', temperature: 18, condition: 'Rain', description: 'lluvia ligera', humidity: 75, windSpeed: 14 },
 'Monterrey': { city: 'Monterrey', temperature: 32, condition: 'Thunderstorm', description: 'tormenta con lluvia moderada', humidity: 70, windSpeed: 20 },
 };

async function fetchWeather(city) {
 // Sanitizar entrada
 const clean = city.trim().replace(/[^\w\s]/g, '');
 if (!clean) throw new Error('Ciudad invalida');
 
 try {
  const url = `${BASE_URL}?q=${encodeURIComponent(clean)}&appid=${API_KEY}&units=metric&lang=es`;
  const res = await fetch(url, { signal: AbortSignal.timeout(8000) });
  if (!res.ok) throw new Error(`Error API: ${res.status}`);
  
  const json = await res.json();
  return {
  city: json.name,
  temperature: Math.round(json.main.temp),
  condition: json.weather[0].main,
  description: json.weather[0].description,
  humidity: json.main.humidity,
  windSpeed: json.wind?.speed?.toFixed(1) ?? '0',
  };
 } catch (e) {
  console.warn(`Error API para ${city}, usando mock:`, e);
  return MOCK_WEATHER[city] || { city: city, temperature:'--', condition:'Clear', description:'Sin datos', humidity:'--', windSpeed:'--' };
 }
}
async function fetchAllCities() {
 const results = await Promise.allSettled(
 CITIES.map(city => fetchWeather(city))
 );
 return results.map((r, i) =>
 r.status === 'fulfilled'
 ? r.value
 : { city: CITIES[i], temperature:'--', condition:'Error',
 description:'Sin datos', humidity:'--', windSpeed:'--' }
 );
}
