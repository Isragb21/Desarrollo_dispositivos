# SA.6 — Reporte de Configuración de Herramientas y Emuladores

**Proyecto:** GameStore (teléfono + wearable + Smart TV)
**Estudiante:** Israel Gómez Bonilla
**Fecha:** 1 de agosto de 2026
**Criterio:** SA.6 — Unidad Wearables + Unidad Pantallas Inteligentes (SA.6.A + SA.6.B)

---

## SA.6.A — Configuración de herramientas

### 1. Versiones del SDK

Salida de `flutter --version` (2026-08-01):

```
Flutter 3.44.1 • channel stable • https://github.com/flutter/flutter.git
Framework • revision 924134a44c • 2026-05-29 12:13:22 -0400
Engine • revision c416acfeb8 • 2026-05-27 20:19:31.000Z
Tools • Dart 3.12.1 • DevTools 2.57.0
```

| Herramienta | Versión |
|-------------|---------|
| Flutter SDK | 3.44.1 (stable) |
| Dart SDK | 3.12.1 |
| Flutter DevTools | 2.57.0 |

### 2. Android Studio y plugins

| Herramienta | Versión |
|-------------|---------|
| Android Studio | **Quail 2026.1.1** (Build AI-261.23567.138.2611.15503007) |
| Java (JDK embebido) | OpenJDK 21.0.10 |
| Android SDK | 36.1.0 |
| Build-tools | 36.1.0 |
| Emulador (AVD) | 36.6.11.0 |
| Plugins | Flutter + Dart (bundled) |

Salida de `flutter doctor -v`:

- `[√] Flutter (Channel stable, 3.44.1, locale es-MX)`
- `[√] Windows Version (10 Home 64-bit, 22H2, 2009)`
- `[√] Android toolchain` (SDK 36.1.0, licencias aceptadas)
- `[!] Chrome` no detectado (la PWA se prueba en **Edge**; ver troubleshooting)
- `[!] Visual Studio` no instalado (no requerido: no se compila para Windows desktop)
- `[√] Connected device` (Windows desktop + Edge web)

### 3. Herramientas de la Unidad 3 (Pantallas Inteligentes)

| Herramienta | Versión | Uso |
|-------------|---------|-----|
| VS Code | 1.131.0 | Editor principal |
| Extensiones | Dart, Flutter, Live Server, PWA Tools | Desarrollo y prueba local |
| ffmpeg (vía imageio-ffmpeg) | **7.1-essentials_build** | Optimización de videos de fondo |
| Python | 3.14.5 | Scripts de generación de recursos (íconos, videos, imágenes) |
| Chrome DevTools / Edge DevTools | Device toolbar 1920×1080 | Emulación de Smart TV |

### 4. Dependencias clave del proyecto

**`gamestore_app/pubspec.yaml`:**

```yaml
environment:
  sdk: ^3.12.1
dependencies:
  cupertino_icons: ^1.0.8
  flutter_blue_plus: ^1.34.5   # BLE teléfono ↔ wearable
  google_fonts: ^6.1.0
  provider: ^6.1.1
  http: ^1.2.1
dev_dependencies:
  flutter_test: (sdk)
  flutter_lints: ^6.0.0
  flutter_launcher_icons: ^0.14.3
```

**`gamestore_tv/pubspec.yaml`:**

```yaml
environment:
  sdk: ^3.12.1
dependencies:
  cupertino_icons: ^1.0.8
  http: ^1.2.1
  provider: ^6.1.1
  google_fonts: ^6.1.0
  web: ^1.1.1
dev_dependencies:
  flutter_test: (sdk)
  flutter_lints: ^6.0.0
```

**`backend/package.json`:**

```json
"dependencies": {
  "bcrypt": "^5.1.1",
  "bcryptjs": "^3.0.3",
  "cors": "^2.8.5",
  "express": "^4.21.0",
  "pg": "^8.13.0"
}
```

### 5. Pasos de instalación reproducibles

1. Instalar Flutter 3.44.1 estable y agregarlo al PATH.
2. Instalar Android Studio Quail 2026.1.1 con el SDK 36 y aceptar licencias
   (`flutter doctor --android-licenses`).
3. Instalar VS Code 1.131.0 con las extensiones Dart y Flutter.
4. Clonar el repositorio.
5. `flutter pub get` en `gamestore_app` y en `gamestore_tv`.
6. Backend: `cd backend && npm install` (requiere Node.js + PostgreSQL/Supabase; opcional:
   `docker-compose up`).
7. Para regenerar videos: instalar Python 3.14.5 y `pip install imageio-ffmpeg`, luego
   ejecutar el script de la carpeta `web/` de la TV.

---

## SA.6.B — Configuración de emuladores

### 1. Emulador de teléfono

| Parámetro | Valor |
|-----------|-------|
| AVD | `Pixel_7` |
| Forma / Modelo | Pixel 7 (Google) |
| Plataforma | Android (API nivel SDK 36.1.0 disponible) |
| Resolución | 1080 × 2400 px (predeterminada del AVD) |
| RAM | Según config.ini del AVD |

### 2. Emulador Wear OS

| Parámetro | Valor |
|-----------|-------|
| AVD | `Wear_OS_XL_Round` |
| Forma | Redonda (round) |
| Plataforma | Android (Wear OS) |
| Resolución | Ejemplo: 450 × 450 px (XL Round) |
| RAM | Según config.ini del AVD |

> Nota: la app wearable (`wearable_app`) es trabajo pendiente; el AVD ya está creado y
> disponible en `flutter emulators`.

### 3. Emulación de TV (Chrome DevTools / Edge DevTools)

| Parámetro | Valor |
|-----------|-------|
| Herramienta | Edge DevTools (respuesta: DevTools device toolbar) |
| Resolución | **1920 × 1080** |
| User Agent | Desktop (Chrome/Edge para Windows) |
| DPR | 1 (para respetar la escala 2x por software) |

Pasos: DevTools → Device toolbar (Ctrl+Shift+M) → elegir "Smart TV" / resolución 1920×1080,
DPR 1, y servir la PWA con el SW activo.

### 4. Capturas de pantalla de cada emulador

![Emulador Pixel 7 (teléfono)](screenshots/emulator_pixel7.png)
![Emulador Wear OS XL Round](screenshots/emulator_wear.png)
![Emulación TV 1920×1080 en DevTools](screenshots/tv_1920x1080.png)

| Emulador | Captura | Estado |
|----------|---------|--------|
| Pixel 7 | `screenshots/emulator_pixel7.png` | ⏳ Pendiente |
| Wear OS XL Round | `screenshots/emulator_wear.png` | ⏳ Pendiente |
| TV (DevTools 1920×1080) | `screenshots/tv_1920x1080.png` | ⏳ Pendiente |

### 5. Problemas de configuración encontrados (troubleshooting)

| Problema | Solución |
|----------|----------|
| Chrome no detectado por Flutter (`flutter doctor`) | Se usa **Edge** para la PWA; `flutter run -d edge` o servir `build/web` con Live Server |
| Render de `<video>` HTML en Flutter Web | Se usa `HtmlElementView` + `UiKitView` con factory registrada una sola vez (`video_background.dart`) |
| Videos pesados para DE.1 | Re-encode con ffmpeg: H.264 High + `-movflags +faststart` + `yuv420p`, 1920×1080, 12 s ≈ 0.3–0.4 MB (límite 5 MB) |
| SW no se actualizaba | `skipWaiting()` + `clients.claim()` en `activate`; cache names versionados |
| Contraste WCAG AA fallaba en `textSecondary` | Cambio de `#475569` (2.55:1) a `#94A3B8` (7.53:1 sobre `#0B0E14`) |
| 3 lints `use_null_aware_elements` en móvil | Aplicados `?"username": ...` en `api_service.dart` |
| Actualización automática del reloj en TV | `Timer.periodic` cada 1 s para header (hora/fecha) |

---

*Firma: __________________________  Fecha: __________________
