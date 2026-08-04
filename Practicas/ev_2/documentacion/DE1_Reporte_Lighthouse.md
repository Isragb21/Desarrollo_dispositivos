# DE.1 — Reporte Lighthouse y Optimización de la PWA

**Proyecto:** GameStore TV (PWA)
**Estudiante:** Israel Gómez Bonilla
**Fecha:** 1 de agosto de 2026
**Criterio:** DE.1 — Lighthouse > 80 (mínimo 7/8 elementos)

---

## 1. Cómo generar el reporte (procedimiento)

1. Construir la PWA: `flutter build web` en `gamestore_tv`.
2. Servir `build/web` (ej. `npx serve build/web -l 8080`).
3. Abrir en Edge → DevTools → panel **Lighthouse**.
4. Configurar: *Device: Desktop*, *Categories: Performance, Accessibility, Best Practices,
   SEO* → **Analyze page load**.
5. Pegar aquí los resultados (scores y métricas).

## 2. Resultados

| Categoría | Score requerido | Score obtenido |
|-----------|-----------------|----------------|
| Performance | ≥ 80 | ⏳ Pendiente de medición |
| Accessibility | ≥ 90 | ⏳ Pendiente de medición |
| Best Practices | ≥ 90 | ⏳ Pendiente de medición |
| SEO | ≥ 80 | ⏳ Pendiente de medición |

### Métricas clave

| Métrica | Requerido | Obtenido |
|---------|-----------|----------|
| FCP (First Contentful Paint) | medir | ⏳ |
| LCP (Largest Contentful Paint) | medir | ⏳ |
| TBT (Total Blocking Time) | medir | ⏳ |

*(Insertar captura del reporte Lighthouse aquí.)*

![Reporte Lighthouse completo (Performance, A11y, Best Practices, SEO)](screenshots/lighthouse.png)

---

## 3. Optimizaciones ya implementadas (evidencia)

| Elemento DE.1 | Estado | Evidencia |
|---------------|--------|-----------|
| **Videos optimizados con ffmpeg** (H.264 + faststart, ≤ 5 MB) | ✅ | `gamestore_tv/web/videos/*.mp4` — H.264 High, `-movflags +faststart`, yuv420p, 1920×1080, 12 s, **0.3–0.4 MB** c/u |
| **Lazy loading de videos** | ✅ | `video_background.dart`: solo se crea/activa el `<video>` del juego seleccionado; caché de video bajo demanda en `sw.js` (`VIDEO_CACHE`, no precache) |
| **Pantalla de carga (splash)** mientras carga la API | ✅ | Estado de carga con indicador en la TV antes de mostrar datos |
| PWA checklist completo (manifest + SW + HTTPS + íconos + offline) | ⚠️ | Manifest ✅ (fullscreen, landscape, icons 192/512 any+maskable), SW ✅, offline ✅; **HTTPS pendiente** (requiere deploy con TLS) |
| ARIA en tarjetas | ✅ | `Semantics` en `game_card.dart` |
| Foco programático / contraste verificado | ✅ | Glow dorado en tarjeta activa; contraste `#94A3B8` (7.53:1) |
| Sin errores de consola / librerías vulnerables | ✅ | Sin CDNs externos; assets propios |

## 4. Acciones pendientes

- [ ] Ejecutar Lighthouse y pegar reporte (sección 2).
- [ ] Deploy de producción con HTTPS (para Best Practices ≥ 90).
- [ ] Verificar offline page en el reporte PWA.

---

*Firma: __________________________  Fecha: __________________
