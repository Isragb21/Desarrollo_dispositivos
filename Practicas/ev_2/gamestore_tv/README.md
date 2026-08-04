# GameStore TV

PWA para Smart TV del ecosistema GameStore (Evaluación 2 — Unidades 2 y 3).

## Requisitos
- Flutter SDK 3.44+ (web habilitado)
- Backend de GameStore corriendo en `http://localhost:3000` (`docker compose up` en `../`)

## Ejecutar
```bash
# 1) Levantar backend + BD (misma BD que la app móvil)
cd ..
docker compose up -d

# 2) Correr la PWA TV en Chrome (modo dev)
#    Mismo requisito que el build: --no-web-resources-cdn (CanvasKit local, CSP)
cd gamestore_tv
flutter run -d chrome --no-web-resources-cdn

# 3) Build de producción
#    --no-web-resources-cdn: usa el CanvasKit LOCAL (build/web/canvaskit/)
#    en vez de gstatic.com. Es OBLIGATORIO por la CSP estricta `script-src 'self'`
#    (sin dependencias externas) y para que funcione offline con el SW.
flutter build web --no-web-resources-cdn

# 4) Servir el build en 1920x1080 (Chrome DevTools -> emular Smart TV)
cd build/web
python -m http.server 8080
```
Abrir `http://localhost:8080` en Chrome y emular resolución **1920x1080** en DevTools.

> **Nota (pantalla en blanco):** si se hace `flutter build web` sin `--no-web-resources-cdn`,
> el bootstrap intenta descargar `canvaskit.js` desde `https://www.gstatic.com/...` y la CSP lo
> bloquea, dejando la app en blanco. El flag fuerza `useLocalCanvasKit: true` en
> `flutter_bootstrap.js` y todo se carga localmente.

## Características implementadas
- **PWA** (`web/`): `manifest.json` (`fullscreen`, `landscape`), íconos maskable 192/512, service worker `sw.js` (Cache First estáticos / Network First API / caché dedicada para videos), página offline, CSP en `index.html`.
- **Layout 10-foot**: 1920x1080 sin scroll, safe zone 5% (96px h / 54px v), grid 2x2, tipografía grande (dato principal 88px, etiquetas 32px, detalle 24px), sidebar con navegación (Inicio / Buscar / Biblioteca / Perfil / Configuración).
- **Navegación D-pad**: flechas del teclado + Enter/OK, foco dorado con glow, lógica de límites.
- **Datos reales**: consume la misma API/BD que la app móvil (`GET /api/juegos`), solo lectura.
- **Multimedia (video-first)**: el fondo reproduce un video por juego (`web/videos/<slug>.mp4`) con autoplay/muted/loop, lazy load (solo carga el video del juego activo), y fallback automático a la portada si el video falta o falla (SA.2.C). Tráilers generados con ffmpeg: H.264 + faststart, <= 5MB (DE.1).

## Videos de fondo
Cada portada `NOMBRE.jpg` de la API busca su tráiler en `web/videos/NOMBRE.mp4`
(se deriva de `ApiService.videoUrl`). Para agregar/regenerar:

```bash
# Generar con ffmpeg (H.264 + faststart + yuv420p, <= 5MB)
ffmpeg -f lavfi -i "gradients=s=1920x1080:r=15:c0=0x0b0e14:c1=0x22c55e:c2=0x1b263b:nb_colors=3:type=linear:speed=0.04:duration=12" \
  -c:v libx264 -preset veryfast -crf 27 -pix_fmt yuv420p -movflags +faststart -an web/videos/cyberpunk_2077.mp4
```

Si `web/videos/NOMBRE.mp4` no existe, la app usa la portada como fallback sin errores.

## Estructura
```
gamestore_tv/
├── lib/
│   ├── main.dart                  # Entry point
│   ├── models/game.dart           # Modelo de juego
│   ├── services/api_service.dart  # Conexión a la API (misma BD) + videoUrl
│   ├── theme/tv_theme.dart        # Paleta y tipografía TV
│   ├── screens/tv_home_screen.dart# Layout principal + sidebar + D-pad
│   └── widgets/
│       ├── game_card.dart         # Thumbnail de video enfocable con glow dorado
│       └── video_background.dart  # <video> HTML con lazy load y fallback
└── web/
    ├── manifest.json              # fullscreen + landscape
    ├── index.html                 # CSP + registro SW
    ├── sw.js                      # Cache First / Network First / videos
    ├── sw_register.js             # Registro del SW en script externo (CSP)
    ├── flutter_config.js          # Configuración del engine (CanvasKit local)
    ├── offline.html               # Página offline
    ├── icons/                     # Íconos 192/512 maskable
    └── videos/                    # Tráilers H.264 faststart <= 5MB
```
