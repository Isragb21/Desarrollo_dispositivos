import 'dart:async';

/// Interfaz del canal de sincronización teléfono ↔ TV.
/// La implementación real usa BroadcastChannel + validación de event.origin
/// (web); en plataformas no-web (Android/iOS) es un no-op.
abstract class TvSyncBase {
  Stream<Map<String, dynamic>> get messages;
  bool get isSupported;
  void open();
  void close();
  void broadcast(String type, [Map<String, dynamic>? payload]);
}
