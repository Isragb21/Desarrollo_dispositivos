import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/services.dart';

/// Cliente del puente BLE simulado (emuladores sin Bluetooth): se comunica con
/// la móvil vía HTTP a través del backend.
class _RelayClient {
  static String get _base {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000/api/ble-relay';
    }
    return 'http://localhost:3000/api/ble-relay';
  }

  final HttpClient _client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 2);

  Future<void> heartbeat() => _post('/heartbeat', <String, dynamic>{});

  Future<List<Map<String, dynamic>>> pollEvents() async {
    try {
      final req = await _client.getUrl(Uri.parse('$_base/events'));
      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      final json = jsonDecode(body) as Map<String, dynamic>;
      final list = json['events'] as List? ?? [];
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> postResponse(Map<String, dynamic> data) =>
      _post('/responses', data);

  Future<void> _post(String path, Map<String, dynamic> body) async {
    try {
      final req = await _client.postUrl(Uri.parse('$_base$path'));
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode(body));
      final res = await req.close();
      await res.drain<void>();
    } catch (_) {}
  }

  void close() => _client.close(force: true);
}

class BleServer {
  static const _methodChannel = MethodChannel('com.uteq.gamestore/ble');
  static const _eventChannel = EventChannel('com.uteq.gamestore/ble_events');

  final StreamController<Map<String, dynamic>> _events =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get events => _events.stream;
  bool _listening = false;

  // Puente por red (usado cuando no hay Bluetooth, ej. emulador).
  bool _relayActive = false;
  _RelayClient? _relay;
  Timer? _relayHeartbeatTimer;
  Timer? _relayPollTimer;

  /// Pide los permisos de Bluetooth en runtime (Android 12+: CONNECT/SCAN/
  /// ADVERTISE; previo: ACCESS_FINE_LOCATION). Se invoca al iniciar la app.
  Future<void> requestPermissions() async {
    try {
      await _methodChannel.invokeMethod('requestPermissions');
    } catch (e) {
      developer.log('requestPermissions error: $e', name: '[WEARABLE]');
    }
  }

  Future<void> start() async {
    try {
      final started =
          await _methodChannel.invokeMethod<bool>('startServer') ?? false;
      if (started) {
        developer.log('BLE server started', name: '[WEARABLE]');
      } else {
        // Sin Bluetooth (emulador): puente por red.
        developer.log('BLE no disponible, usando puente por red',
            name: '[WEARABLE]');
        _startRelay();
        // Reintenta el BLE real por si se concedieron permisos después.
        await Future.delayed(const Duration(seconds: 4));
        if (!_relayActive) return;
        if (await _methodChannel.invokeMethod<bool>('startServer') ?? false) {
          _stopRelay();
          developer.log('BLE server started (reintento)', name: '[WEARABLE]');
        }
      }
    } catch (e) {
      developer.log('BLE start error: $e, usando puente por red',
          name: '[WEARABLE]');
      _startRelay();
    }
    _listen();
  }

  void _startRelay() {
    if (_relayActive) return;
    _relayActive = true;
    final relay = _RelayClient();
    _relay = relay;
    relay.heartbeat();
    _relayHeartbeatTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => relay.heartbeat(),
    );
    _pollRelayEvents();
  }

  Future<void> _pollRelayEvents() async {
    if (!_relayActive) return;
    final relay = _relay;
    if (relay == null) return;
    final events = await relay.pollEvents();
    for (final event in events) {
      _events.add(event);
    }
    _relayPollTimer =
        Timer(const Duration(milliseconds: 600), _pollRelayEvents);
  }

  void _stopRelay() {
    _relayActive = false;
    _relayHeartbeatTimer?.cancel();
    _relayHeartbeatTimer = null;
    _relayPollTimer?.cancel();
    _relayPollTimer = null;
    _relay?.close();
    _relay = null;
  }

  Future<void> stop() async {
    try {
      await _methodChannel.invokeMethod('stopServer');
    } catch (_) {}
    _stopRelay();
  }

  void _listen() {
    if (_listening) return;
    _listening = true;
    _eventChannel.receiveBroadcastStream().listen((raw) {
      try {
        final map = Map<String, dynamic>.from(raw as Map);
        _events.add(map);
      } catch (e) {
        developer.log('Event parse error: $e', name: '[WEARABLE]');
      }
    });
  }

  /// Envía la respuesta del usuario (aprobado/rechazado/pagar) al teléfono
  /// vía NOTIFY (BLE real) o por el puente por red.
  Future<void> sendUserResponse(String type, {String? payload}) async {
    final data = {
      'type': type,
      'payload': ?payload,
    };
    if (_relayActive) {
      await _relay?.postResponse(data);
      return;
    }
    try {
      await _methodChannel
          .invokeMethod('notifyResponse', jsonEncode(data));
    } catch (e) {
      developer.log('Notify error: $e', name: '[WEARABLE]');
    }
  }

  Future<void> dispose() async {
    _stopRelay();
    await _events.close();
    _listening = false;
  }
}
