import 'dart:async';

import 'tv_sync_base.dart';

/// Implementación no-web: BroadcastChannel no existe fuera del navegador,
/// así que la sincronización es un no-op (Android/iOS/desktop).
TvSyncBase createTvSync() => TvSyncStub();

class TvSyncStub implements TvSyncBase {
  final StreamController<Map<String, dynamic>> _controller =
      StreamController<Map<String, dynamic>>.broadcast();

  @override
  bool get isSupported => false;

  @override
  Stream<Map<String, dynamic>> get messages => _controller.stream;

  @override
  void open() {}

  @override
  void close() {}

  @override
  void broadcast(String type, [Map<String, dynamic>? payload]) {}
}
