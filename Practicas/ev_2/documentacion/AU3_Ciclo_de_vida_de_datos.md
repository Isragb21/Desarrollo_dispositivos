# AU.3 — Ciclo de Vida de Datos (30 días)

**Proyecto:** GameStore (teléfono + wearable + Smart TV)
**Estudiante:** Israel Gómez Bonilla
**Fecha:** 1 de agosto de 2026
**Criterio:** AU.3 — Retención y borrado automático de datos (mínimo 5/6 elementos)

---

## 1. Política de retención (qué se guarda y por cuánto)

| Dato | Almacén | Retención | 
|------|---------|-----------|
| Perfil (nombre, correo) | `flutter_secure_storage` / BD | **30 días** |
| Token JWT de sesión | `flutter_secure_storage` | **30 días** (máx) |
| Historial de carrito / deseos | Supabase + local | **30 días** |
| Datos del wearable (métricas) | Local (efímero) | **30 días** / volátil |

Regla general: **todo dato personal se conserva máximo 30 días desde su creación/última
actualización y se elimina automáticamente.**

## 2. Timestamps de creación (requisito)

Cada registro guardado localmente debe incluir su timestamp de creación para poder aplicar
la política de retención:

```dart
final entry = {
  'createdAt': DateTime.now().millisecondsSinceEpoch, // ISO/timestamp del registro
  'data': cartData,
  // ...
};
```

*(Requisito pendiente de implementación: los datos actuales no persisten con timestamp en
`gamestore_tv`.)*

## 3. Función de borrado automático (30 días)

Se ejecuta **al iniciar la app** (no requiere acción del usuario):

```dart
const retentionMillis = Duration(days: 30).inMilliseconds;

void purgeExpiredData(Map<String, dynamic> store, String key) {
  final now = DateTime.now().millisecondsSinceEpoch;
  final items = store[key] as List? ?? [];
  store[key] = items.where((item) {
    final createdAt = item['createdAt'] as int? ?? now;
    return (now - createdAt) < retentionMillis;
  }).toList();
}

void purgeOnStartup() {
  // Llamado desde main() antes de montar la UI
  purgeExpiredData(localStore, 'cart');
  purgeExpiredData(localStore, 'wishlist');
  purgeExpiredData(secureStore, 'profile');
}
```

Nota: el código anterior es la **implementación requerida** para AU.3; aún no está
incorporado al repositorio.

## 4. El aviso de privacidad menciona los 30 días

✅ **Sí** — ver `SA4_Documentacion_Seguridad.md` §3 (Aviso de Privacidad) y §4
(Plan de retención): *"los datos se conservan por un máximo de 30 días"*.

## 5. Evidencia en DevTools (screenshot)

![DevTools → Application → Local Storage mostrando el timestamp `createdAt`](screenshots/localstorage_timestamp.png)

| Evidencia | Estado |
|-----------|--------|
| DevTools → Application → Local Storage mostrando `createdAt` | ⏳ Pendiente de captura |

---

*Firma: __________________________  Fecha: __________________
