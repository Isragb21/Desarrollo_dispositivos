import 'dart:async';

import 'tv_sync_base.dart';
import 'tv_sync_stub.dart'
    if (dart.library.js_interop) 'tv_sync_web.dart' as impl;

/// Canal de sincronización teléfono ↔ TV.
///
/// En web usa BroadcastChannel con validación de `event.origin`; fuera del
/// navegador se convierte en no-op.
class TvSync {
  final TvSyncBase _impl = impl.createTvSync();

  Stream<Map<String, dynamic>> get messages => _impl.messages;
  bool get isSupported => _impl.isSupported;

  void open() => _impl.open();
  void close() => _impl.close();

  void broadcast(String type, [Map<String, dynamic>? payload]) =>
      _impl.broadcast(type, payload);
}
