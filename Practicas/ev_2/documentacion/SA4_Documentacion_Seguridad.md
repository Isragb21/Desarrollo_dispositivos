# SA.4 — Documentación de Seguridad

**Proyecto:** GameStore (teléfono + wearable + Smart TV)
**Estudiante:** Israel Gómez Bonilla
**Fecha:** 1 de agosto de 2026
**Criterio:** SA.4 — E2.4 Documentación de seguridad (mínimo 4/5 elementos)

---

## 1. Validación de `event.origin` en BroadcastChannel

### 1.1 Estado en el código

**PENDIENTE DE IMPLEMENTACIÓN.** Actualmente el ecosistema no usa `BroadcastChannel` entre
teléfono y TV (la sincronización en tiempo real es trabajo pendiente de AU.1, vía WebSocket/SSE).
Para cumplir SA.4, el canal de mensajería debe validar `event.origin` en el receptor.

### 1.2 Implementación requerida (documentada)

El receptor (TV) debe **descartar cualquier mensaje cuyo `origin` no sea el dominio del
propio canal** antes de procesarlo:

```js
const channel = new BroadcastChannel('gamestore_sync');

channel.addEventListener('message', (event) => {
  // Validación CRÍTICA: solo se aceptan mensajes del MISMO origin
  if (event.origin !== window.location.origin) {
    console.warn('[GameStoreTV] Mensaje rechazado por origin no autorizado:', event.origin);
    return; // Se ignora el mensaje
  }

  // Validación de tipo de dato antes de procesar
  const data = event.data;
  if (!data || typeof data !== 'object' || typeof data.type !== 'string') {
    console.warn('[GameStoreTV] Mensaje con schema inválido, ignorado.');
    return;
  }

  applyRemoteAction(data); // data = { type: 'sync', gameId, action }
});
```

Reglas aplicadas:

1. **Rechazo por `origin`**: solo se procesan mensajes del mismo origin (previene XSS/CSRF
   vía canales entre pestañas).
2. **Validación de schema**: se verifica la estructura mínima (`type` string) antes de
   aplicar la acción (previene payloads maliciosos).
3. **Whitelist de acciones**: `applyRemoteAction` solo ejecuta acciones de un `Set`
   predefinido (`sync`, `selectGame`), ignorando cualquier otra.

### 1.3 Riesgo cubierto

| Ataque | Mitigación |
|--------|------------|
| XSS payload vía BroadcastChannel | Validación de `origin` + schema + whitelist de acciones |
| Spoofing de origin | Comparación exacta contra `window.location.origin` |
| Datos mal formados | Validación de tipo antes de procesar |

---

## 2. LFPDPPP — Datos personales identificados con base legal

### 2.1 Leyes aplicables

| Ley | Aplica | Justificación |
|-----|--------|---------------|
| **LFPDPPP (México)** | Sí | Se maneja correo, sesión e ID de dispositivo. Exige consentimiento y aviso de privacidad. |
| Código de Comercio | No | No hay transacciones reales (sin pasarela de pago). |
| GDPR | No obligatorio | Buenas prácticas opcionales. |
| COPPA | No | Público objetivo +15 años. |

### 2.2 Datos personales y base legal

| Dato | Tipo | Clasificación LFPDPPP | Base legal / Finalidad |
|------|------|----------------------|------------------------|
| Correo | Contacto | Personal | Autenticación y recuperación de cuenta (consentimiento) |
| Nombre | Identidad | Personal | Personalización de experiencia |
| JWT / Token de sesión | Credencial | Sensible | Seguridad de sesión (no se comparte) |
| UUID / MAC de dispositivo | Identificador | Sensible | Emparejamiento BLE no autorizado |
| Historial de carrito | Preferencias | Personal | Sincronización entre dispositivos |

Todos los datos personales se tratan conforme al consentimiento otorgado en el Aviso de
Privacidad (sección 3).

---

## 3. Aviso de Privacidad

### GAMESTORE — AVISO DE PRIVACIDAD

**Responsable:** GameStore (Israel Gómez Bonilla).

De conformidad con la Ley Federal de Protección de Datos Personales en Posesión de los
Particulares (LFPDPPP), GameStore informa:

**Datos recabados:** nombre, correo electrónico, identificador de dispositivo (UUID/MAC),
historial de carrito y preferencias.

**Finalidades:** exploración del catálogo, autenticación con doble factor (2FA) vía
wearable, sincronización de carrito entre dispositivos y personalización de la experiencia.

**Transferencias:** no se realizan transferencias a terceros.

**Seguridad:** los datos sensibles se almacenan cifrados (`flutter_secure_storage`) y las
comunicaciones se realizan por HTTPS/TLS. Los datos se conservan por un máximo de **30 días**
(ver `AU3_Ciclo_de_vida_de_datos.md`).

**Derechos ARCO:** puede ejercer sus derechos de Acceso, Rectificación, Cancelación y
Oposición ante **privacidad@gamestore.app**.

**Versión:** 1.0 — Junio 2026

---

## 4. Plan de retención de datos

| Dato | Dónde se guarda | Tiempo | Cómo se elimina |
|------|-----------------|--------|-----------------|
| Perfil | `flutter_secure_storage` / BD | Máx 30 días | Borrado automático por antigüedad |
| JWT | `flutter_secure_storage` | Sesión / máx 30 días | Al expirar o en borrado automático |
| Carrito | Supabase (cloud) + local | 30 días | Job de purga + borrado local |
| Catálogo | Supabase (cloud) | Permanente (no es dato personal) | N/A |
| Alertas BLE | Memoria volátil | Efímero | Al apagar/desconectar |

Detalle del ciclo de vida (borrado automático a los 30 días): ver
`AU3_Ciclo_de_vida_de_datos.md`.

---

## 5. Checklist de seguridad PWA

| Elemento | Estado | Evidencia |
|----------|--------|-----------|
| **CSP configurada** (default-src, connect-src, media-src) | ✅ Aplicado | `gamestore_tv/web/index.html:19-28` |
| **HTTPS en producción** | ⚠️ Pendiente | Deploy local (necesita TLS en servidor real) |
| **SRI (Subresource Integrity)** | ⚠️ Pendiente | No hay CDNs; assets propios |
| **Validación de `event.origin`** | ⚠️ Pendiente | Se implementa con AU.1 (sección 1.2) |
| **Sin API keys en repo** | ✅ Verificado | `git log --all -S 'API_KEY'` sin resultados |
| **SW con modo offline** | ✅ Aplicado | `gamestore_tv/web/sw.js` (cacheFirst + offline.html) |
| **`.gitignore` con `.env`** | ✅ App/TV | Apps lo incluyen; **pendiente en `backend/`** |

---

*Firma: __________________________  Fecha: __________________
