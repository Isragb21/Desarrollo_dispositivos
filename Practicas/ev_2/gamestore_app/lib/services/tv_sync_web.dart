import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'tv_sync_base.dart';

/// Implementación web: BroadcastChannel entre pestañas del mismo origin.
/// Todo mensaje entrante valida `event.origin` contra el origin actual antes
/// de aplicarse (SA.4 / AU.1): si el emisor vive en otro origin se descarta.
TvSyncBase createTvSync() => TvSyncWeb();

class TvSyncWeb implements TvSyncBase {
  static const String _channelName = 'gamestore_sync';

  web.BroadcastChannel? _channel;
  final StreamController<Map<String, dynamic>> _controller =
      StreamController<Map<String, dynamic>>.broadcast();

  @override
  bool get isSupported => true;

  @override
  Stream<Map<String, dynamic>> get messages => _controller.stream;

  @override
  void open() {
    if (_channel != null) return;
    _channel = web.BroadcastChannel(_channelName);
    _channel!.onmessage = ((web.MessageEvent event) {
      final data = event.data;
      if (data == null || !data.isA<JSString>()) return;

      // Validación de event.origin: solo se aceptan mensajes del mismo origin.
      final allowedOrigin = web.window.location.origin;
      if (event.origin != allowedOrigin) return;

      Map<String, dynamic>? parsed;
      try {
        final decoded = jsonDecode((data as JSString).toDart);
        if (decoded is Map<String, dynamic>) {
          parsed = decoded;
        }
      } catch (_) {
        return;
      }
      if (parsed != null) _controller.add(parsed);
    }).toJS;
  }

  @override
  void close() {
    _channel?.close();
    _channel = null;
  }

  @override
  void broadcast(String type, [Map<String, dynamic>? payload]) {
    final channel = _channel;
    if (channel == null) return;
    final message = <String, dynamic>{
      'type': type,
      'origin': 'gamestore_app',
      'ts': DateTime.now().millisecondsSinceEpoch,
      ...?payload,
    };
    channel.postMessage(jsonEncode(message).toJS);
  }
}
