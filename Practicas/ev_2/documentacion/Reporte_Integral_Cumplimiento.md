# Reporte Integral de Cumplimiento — Evaluación 2

**Proyecto:** GameStore (teléfono + wearable + Smart TV)
**Estudiante:** Israel Gómez Bonilla
**Fecha:** 1 de agosto de 2026
**Referencia:** Lista de cotejo y criterios de evaluación (Ev 2)

---

## Nivel SA — Satisfactorio (80 pts)

### SA.1.A — App wearable (Wear OS emulado)

| Elemento | Estado |
|----------|--------|
| Proyecto Wear OS separado compila | ⏳ Pendiente |
| Ícono propio del wearable | ⏳ Pendiente |
| Simulador de sensores genera datos cada segundo | ⏳ Pendiente |
| ≥ 3 tipos de datos | ⏳ Pendiente |
| Pantalla muestra datos en tiempo real | ⏳ Pendiente |
| Botón Iniciar/Detener | ⏳ Pendiente |
| GATT con NOTIFY por tipo de dato | ⏳ Pendiente |
| UUIDs compartidos como constantes | ⏳ Pendiente |
| **Subtotal** | **0 / 8** |

### SA.1.B — App teléfono recibe datos BLE

| Elemento | Estado |
|----------|--------|
| `BleClient` escanea por serviceUUID | ✅ (implementado, depende de wearable) |
| Suscripción a NOTIFY (`setNotifyValue`) | ✅ (implementado) |
| Parseo de bytes (int/float/string) | ✅ (implementado) |
| Provider acumula y notifica a UI | ⏳ Parcial |
| Widget con ≥ 3 métricas en tiempo real | ⏳ Pendiente (sin wearable) |
| Alerta de umbral crítico | ⏳ Pendiente |
| Estado de conexión BLE en UI | ⏳ Parcial |
| Desconexión sin crash + mensaje | ⏳ Pendiente de verificación |
| **Subtotal** | **2 / 8** |

### SA.2.A — Estructura y configuración PWA

| Elemento | Estado | Evidencia |
|----------|--------|-----------|
| manifest.json válido (fullscreen, landscape) | ✅ | `web/manifest.json` |
| Íconos 192/512 PNG any+maskable | ✅ | `web/icons/` |
| SW registrado y activo | ✅ | `web/index.html:36-45`, `web/sw.js` |
| Cache First estáticos / Network First API | ✅ | `sw.js` (`cacheFirst`, `networkFirst`) |
| Modo offline | ✅ | `offline.html` + precache |
| CSP (default/connect/media-src) | ✅ | `web/index.html:19-28` |
| .gitignore .env, sin API key en commits | ⚠️ | Apps ✅; **`backend/` sin `.gitignore`**; git log limpio |
| **Subtotal** | **6.5 / 7** | |

### SA.2.B — Layout 1920×1080 y diseño 10-foot

| Elemento | Estado |
|----------|--------|
| Safe zone 5% (54px v / 96px h) | ✅ |
| Sin scroll, todo visible en 1080px | ✅ |
| Grid ≥ 4 elementos (2×2) | ✅ (6+ juegos) |
| Dato principal ≥ 5rem (80px) | ✅ |
| Etiqueta ≥ 2rem (32px), detalle ≥ 1.5rem (24px) | ✅ |
| Contraste WCAG AA (≥ 4.5:1) | ✅ (`#94A3B8` = 7.53:1) |
| Foco visible D-pad (glow dorado) | ✅ |
| **Subtotal** | **7 / 7** |

### SA.2.C — Navegación D-pad y datos reales

| Elemento | Estado |
|----------|--------|
| Flechas mueven el foco en el grid | ✅ |
| Enter/OK selecciona y cambia multimedia de fondo | ✅ |
| Límites del grid sin romper foco | ✅ |
| ≥ 4 registros con datos reales de la API | ✅ |
| Tarjetas con ≥ 3 campos relevantes | ✅ (título, género, rating, precio) |
| Multimedia cambia según contexto | ✅ (`video_background.dart`) |
| Fallback si el recurso no carga | ✅ (portada) |
| Info contextual en header (hora/fecha) | ✅ |
| **Subtotal** | **8 / 8** |

### SA.3 — Integración del ecosistema (3 dispositivos)

| Elemento | Estado |
|----------|--------|
| Teléfono muestra datos reales desde API (P2.5) | ✅ |
| Wearable envía datos por BLE NOTIFY (P2.6) | ⏳ Pendiente (wearable) |
| PWA TV muestra datos sincronizados (P3.3) | ⏳ Sin sincronización en tiempo real |
| 3 dispositivos simultáneos en demo | ⏳ Pendiente |
| README con instrucciones de los 3 proyectos | ⚠️ Parcial (falta README raíz) |
| Release v1.0 en GitHub | ⏳ Pendiente |
| Repositorio limpio (sin .env/.jks/API keys) | ⚠️ **`ev_2` sin commitear**; `.gitignore` backend |
| **Subtotal** | **1.5 / 7** |

### SA.4 — Documentación de seguridad

| Elemento | Estado | Evidencia |
|----------|--------|-----------|
| Validación `event.origin` documentada y aplicada | ⚠️ Documentada (`SA4` §1.2), código pendiente | |
| LFPDPPP: datos personales + base legal | ✅ | `SA4` §2 |
| Aviso de privacidad (responsable, datos, finalidad, ARCO) | ✅ | `SA4` §3 |
| Plan de retención de datos | ✅ | `SA4` §4 + `AU3` |
| Checklist seguridad PWA (CSP, HTTPS, SRI, origin) | ⚠️ CSP ✅; HTTPS/SRI pendientes | |
| **Subtotal** | **3.5 / 5** | |

### SA.5 — Plan y reporte de pruebas

| Elemento | Estado |
|----------|--------|
| Plan con ≥ 10 casos (P2.5, P2.6, P3.1–P3.4) | ✅ (14 casos) |
| Prueba API (P2.5) | ⏳ Por ejecutar |
| Prueba BLE NOTIFY (P2.6) | ⏳ Por ejecutar |
| Prueba D-pad | ⏳ Por ejecutar |
| Prueba modo offline | ⏳ Por ejecutar |
| Prueba sincronización < 2 s | ⏳ Por ejecutar |
| Evidencia ≥ 5 screenshots | ⏳ Pendiente |
| Documento firmado con fecha | ⏳ Pendiente de firma |
| **Subtotal** | **1 / 8** |

### SA.6.A — Configuración de herramientas

| Elemento | Estado |
|----------|--------|
| Flutter/Dart versionados | ✅ (3.44.1 / 3.12.1) |
| Android Studio + plugins | ✅ (Quail 2026.1.1) |
| Unidad 3: VS Code, extensiones, ffmpeg | ✅ (1.131.0, ffmpeg 7.1) |
| Dependencias con versión | ✅ (pubspecs + package.json) |
| Pasos reproducibles | ✅ |
| **Subtotal** | **5 / 5** |

### SA.6.B — Configuración de emuladores

| Elemento | Estado |
|----------|--------|
| Emulador teléfono (modelo, API, RAM) | ✅ (Pixel 7) |
| Emulador Wear OS (forma, API, RAM) | ✅ (Wear OS XL Round) |
| Emulación TV (1920×1080, user agent) | ✅ (DevTools) |
| Capturas de cada emulador | ⏳ Pendiente |
| Troubleshooting real | ✅ |
| **Subtotal** | **4 / 5** |

---

## Nivel DE — Destacado (90 pts)

### DE.1 — Lighthouse y optimización

| Elemento | Estado |
|----------|--------|
| Reporte Lighthouse (4 categorías) | ⏳ Pendiente |
| Performance ≥ 80 (FCP/LCP/TBT) | ⏳ Pendiente |
| Accessibility ≥ 90 (ARIA, foco, contraste) | ✅ (implementado) |
| Best Practices ≥ 90 (HTTPS, consola) | ⚠️ HTTPS pendiente |
| PWA checklist completo | ⚠️ HTTPS pendiente |
| Videos ffmpeg H.264 faststart ≤ 5 MB | ✅ (0.3–0.4 MB) |
| Lazy loading de videos | ✅ |
| Splash screen mientras carga API | ✅ |
| **Subtotal** | **4 / 8** |

### DE.2 — Video demo del ecosistema

| Elemento | Estado |
|----------|--------|
| Video 5 min con los 3 dispositivos | ⏳ Pendiente |
| Voz explicando | ⏳ Pendiente |
| Muestra inicio TV, búsqueda teléfono, actualización TV | ⏳ Pendiente |
| Muestra pasos/ritmo cardiaco del wearable | ⏳ Pendiente |
| Publicado como Release asset / enlace | ⏳ Pendiente |
| Calidad suficiente | ⏳ Pendiente |
| **Subtotal** | **0 / 6** |

### DE.3 — Pruebas ampliadas

| Elemento | Estado |
|----------|--------|
| Lighthouse como evidencia | ⏳ Pendiente |
| Sincronización cronometrada | ⏳ Pendiente |
| Fallback si API no responde | ⏳ Pendiente |
| Fallback si video no carga | ✅ (implementado, falta captura) |
| **Subtotal** | **1 / 4** |

---

## Nivel AU — Autónomo (100 pts)

| Criterio | Estado |
|----------|--------|
| **AU.1** — WebSocket/SSE bidireccional | ⏳ Pendiente (documentado el plan en `SA4` §1) |
| **AU.2** — Tester externo + reporte firmado | ⏳ Pendiente |
| **AU.3** — Ciclo de vida de datos 30 días | ⚠️ Política documentada (`AU3`), código pendiente |
| **AU.4** — Demo avanzada | ⏳ Pendiente |

---

## Requisitos críticos (NA automático si se incumple)

| Requisito | Estado |
|-----------|--------|
| API key en commits (`git log --all -S 'API_KEY'`) | ✅ Sin resultados |
| `.jks`/`.keystore` en el repo | ✅ Sin archivos |
| `.env` versionado | ✅ Sin archivos |
| 3 dispositivos funcionando en demo | ⏳ Pendiente |
| PWA carga en emulador 1920×1080 | ✅ Verificado |

---

## Resumen

| Nivel | Puntos posibles | Avance actual |
|-------|-----------------|---------------|
| SA.1.A (wearable) | 8 | 0 |
| SA.1.B (BLE teléfono) | 8 | 2 |
| SA.2.A (estructura PWA) | 7 | 6.5 |
| SA.2.B (layout 10-foot) | 7 | 7 |
| SA.2.C (D-pad + datos) | 8 | 8 |
| SA.3 (ecosistema) | 7 | 1.5 |
| SA.4 (seguridad) | 5 | 3.5 |
| SA.5 (pruebas) | 8 | 1 |
| SA.6.A (herramientas) | 5 | 5 |
| SA.6.B (emuladores) | 5 | 4 |

**Conclusión:** la **PWA TV está lista (SA.2 A/B/C completos)** y los reportes de SA.4/SA.6
están documentados. Faltan para asegurar el nivel: **wearable (SA.1)**, **sincronización en
tiempo real (SA.3/AU.1)**, **commit + Release v1.0 + README raíz (SA.3)**, **ejecución y
evidencia de pruebas (SA.5/DE.3)**, **Lighthouse (DE.1)** y **`.gitignore` del backend**.

*Firma: __________________________  Fecha: __________________
