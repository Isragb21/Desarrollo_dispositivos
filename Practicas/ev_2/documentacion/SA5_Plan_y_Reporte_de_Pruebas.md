# SA.5 — Plan y Reporte de Pruebas

**Proyecto:** GameStore (teléfono + wearable + Smart TV)
**Estudiante:** Israel Gómez Bonilla
**Fecha:** 1 de agosto de 2026
**Criterio:** SA.5 — E2.2 Plan y reporte de pruebas (mínimo 7/8 elementos, 10+ casos)

---

## 1. Alcance

Las pruebas cubren las prácticas del ecosistema:

- **P2.5** — App teléfono consume la API real y maneja errores de red.
- **P2.6** — Wearable envía datos al teléfono por BLE con NOTIFY.
- **P3.1–P3.4** — PWA Smart TV: estructura, layout 10-foot, navegación D-pad, multimedia.

## 2. Casos de prueba

| # | Caso | Práctica | Precondición | Pasos | Resultado esperado | Estado |
|---|------|----------|--------------|-------|--------------------|--------|
| TC-01 | Carga del catálogo desde API | P2.5 | Backend en línea | Abrir app teléfono → Inicio | Grid de juegos con datos reales (título, precio, rating) | ⏳ Por ejecutar |
| TC-02 | Manejo de error de red | P2.5 | Backend apagado | Abrir app teléfono sin red | Mensaje de error/fallback, la app no crashea | ⏳ Por ejecutar |
| TC-03 | Búsqueda de juego | P2.5 | Catálogo cargado | Buscar "cyberpunk" | Resultado filtrado correcto | ⏳ Por ejecutar |
| TC-04 | Agregar juego al carrito | P2.5 | Sesión iniciada | Añadir al carrito → revisar carrito | Ítem aparece en carrito sincronizado | ⏳ Por ejecutar |
| TC-05 | Datos BLE NOTIFY del wearable | P2.6 | Wearable emparejado, NOTIFY activo | Iniciar generación de datos | Teléfono muestra ≥3 métricas actualizándose en tiempo real | ⏳ Por ejecutar |
| TC-06 | Umbral crítico BLE | P2.6 | Wearable conectado | Exceder umbral de ritmo cardiaco | Alerta visible en la UI | ⏳ Por ejecutar |
| TC-07 | Desconexión BLE sin crash | P2.6 | Wearable conectado | Apagar Bluetooth del wearable | La app muestra "desconectado", no crashea | ⏳ Por ejecutar |
| TC-08 | Navegación D-pad (todas las direcciones) | P3.1–P3.4 | TV cargada en 1920×1080 | Pulsar ArrowUp/Down/Left/Right en el grid | El foco se mueve entre tarjetas con glow dorado | ⏳ Por ejecutar |
| TC-09 | Límites del grid | P3.1–P3.4 | TV cargada | Mover foco hasta los bordes | El foco no se rompe (lógica de límites) | ⏳ Por ejecutar |
| TC-10 | Enter/OK selecciona y cambia multimedia | P3.1–P3.4 | TV cargada | Presionar Enter sobre una tarjeta | El video/imagen de fondo cambia al juego seleccionado | ⏳ Por ejecutar |
| TC-11 | Modo offline | P3.1–P3.4 | SW registrado | Desactivar red → recargar | La app carga estructura desde caché (offline.html) | ⏳ Por ejecutar |
| TC-12 | Fallback de video | P3.1–P3.4 | TV cargada | Bloquear carga del MP4 | Se muestra la portada (fallback visual) | ⏳ Por ejecutar |
| TC-13 | Sincronización teléfono → TV | AU.1 | Ambos conectados | Acción en teléfono | La TV actualiza en < 2 s (objetivo AU: < 1 s) | ⏳ Por ejecutar |
| TC-14 | Recarga de datos de la API | P3.1–P3.4 | Backend con cambios | Recargar TV | La TV muestra datos actualizados (networkFirst) | ⏳ Por ejecutar |

> Se ejecutó previamente: `flutter test` en `gamestore_tv` = **4/4 pruebas unitarias pasando**
> (incluye pruebas de `ApiService.videoUrl`), `flutter analyze` limpio en ambas apps.

## 3. Evidencia (screenshots)

(Mínimo 5 capturas de los 3 dispositivos funcionando.)

![TV en 1920×1080 con grid y video de fondo](screenshots/tv_home.png)
![Foco dorado en tarjeta activa (D-pad)](screenshots/tv_focus.png)
![Teléfono con catálogo real desde API](screenshots/phone_catalog.png)
![Teléfono con 3 métricas BLE en tiempo real](screenshots/phone_ble.png)
![Wearable generando datos](screenshots/wearable.png)
![Modo offline con red desactivada](screenshots/offline.png)

| Evidencia | Descripción | Estado |
|-----------|-------------|--------|
| `screenshots/tv_home.png` | TV en 1920×1080 con grid y video de fondo | ⏳ Pendiente |
| `screenshots/tv_focus.png` | Foco dorado en tarjeta activa (D-pad) | ⏳ Pendiente |
| `screenshots/phone_catalog.png` | Teléfono con catálogo real desde API | ⏳ Pendiente |
| `screenshots/phone_ble.png` | Teléfono con 3 métricas BLE en tiempo real | ⏳ Pendiente |
| `screenshots/wearable.png` | Wearable generando datos | ⏳ Pendiente |
| `screenshots/offline.png` | Modo offline con red desactivada | ⏳ Pendiente |

## 4. Firma del documento

El alumno declara que las pruebas fueron ejecutadas y verificadas conforme a este plan.

**Nombre:** Israel Gómez Bonilla
**Firma:** __________________________
**Fecha:** __________________

---

## Anexo A — Pruebas ampliadas (DE.3)

| Prueba | Detalle |
|--------|---------|
| Reporte Lighthouse como evidencia | Ver `DE1_Reporte_Lighthouse.md` |
| Sincronización cronometrada | Medir ms entre acción en teléfono y actualización en TV |
| Fallback si la API no responde | Capturar qué ve el usuario (mensaje 503 / caché) |
| Fallback si el video no carga | Capturar portada de respaldo |

*Firma: __________________________  Fecha: __________________
