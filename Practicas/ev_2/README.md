# GameStore — Ecosistema Teléfono + Wearable + Smart TV

Evaluación 2 de Desarrollo para Dispositivos Inteligentes (UTeQ, Mayo–Agosto 2026).
Ecosistema de 3 dispositivos que operan SIMULTÁNEAMENTE durante la demo:

| Dispositivo | Proyecto | Tecnología | Emulador / Runtime |
|---|---|---|---|
| Teléfono | `gamestore_app/` | Flutter (Android + Web) | Android Studio · Pixel 7 (API 36) |
| Wearable | `wearable_app/` | Flutter UI + GATT nativo (Kotlin) | Android Studio · Wear OS XL Round |
| Smart TV | `gamestore_tv/` | Flutter Web (PWA) | Chrome/Edge DevTools 1920×1080 |
| API | `backend/` | Node.js + Express + PostgreSQL | Docker Compose (`docker-compose.yml`) |

## Requisitos

- Flutter 3.44+ / Dart 3.12+ (`flutter --version`)
- Android Studio (Quail 2026.1.1) con emuladores Pixel 7 y Wear OS XL Round
- Node.js 20+ y Docker Desktop (para la API)
- Chrome o Edge DevTools para la PWA

## 1. Levantar la API

```bash
docker compose up --build
```

- API en `http://localhost:3000` (rutas bajo `/api`)
- PostgreSQL en `localhost:5434`
- Verificar: `curl http://localhost:3000/api/juegos`

## 2. Teléfono (Android)

```bash
cd gamestore_app
flutter pub get
flutter run          # en el emulador Pixel 7
```

Para la versión web (sincronización teléfono ↔ TV por BroadcastChannel):

```bash
flutter build web
```

## 3. Wearable (Wear OS)

```bash
cd wearable_app
flutter pub get
flutter run          # en el emulador Wear OS XL Round
```

El wearable inicia un servidor GATT BLE (`wearable_app`) que se empareja con el
teléfono y recibe notificaciones del ecosistema GameStore: ofertas con descuento
real, carrito, aprobación de sesión (2FA) y lista de deseos. Cada alerta se
muestra en la pantalla del reloj y el botón VER abre el juego en el teléfono.

## 4. Smart TV (PWA 1920×1080)

```bash
cd gamestore_tv
flutter build web
```

Sírvase junto con la PWA del teléfono en el MISMO origin para que funcione
la sincronización por BroadcastChannel (misma pestaña/origen, ej. `localhost`):

```bash
python -m http.server 8080
```

- TV: `http://localhost:8080/tv/`
- Teléfono (web): `http://localhost:8080/phone/`

En Chrome/Edge DevTools: modo dispositivo **1920×1080**, con la app TV enfocada
para la navegación D-pad (←↑→↓ + Enter).

## Sincronización entre dispositivos

- **Wearable → Teléfono:** BLE GATT `NOTIFY` (pasos, ritmo, calorías) con
  `serviceUUID` y características compartidas en constantes.
- **Teléfono → Wearable:** notificaciones de carrito, 2FA y wishlist vía BLE `WRITE`.
- **Teléfono ↔ TV:** `BroadcastChannel` (`gamestore_sync`) con validación de
  `event.origin` (SA.4): el carrito del teléfono se refleja en la TV en tiempo real.

## Documentación

Reportes de evaluación (Word) y checklist en [`documentacion/`](documentacion/).

## Seguridad

- Sin API keys, `.env`, `.jks` ni `.keystore` versionados (ver `.gitignore`).
- CSP en la PWA, validación de origin en BroadcastChannel.
