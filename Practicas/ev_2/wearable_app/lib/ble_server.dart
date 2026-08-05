import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/services.dart';

class BleServer {
  static const _methodChannel = MethodChannel('com.uteq.gamestore/ble');
  static const _eventChannel = EventChannel('com.uteq.gamestore/ble_events');

  final StreamController<Map<String, dynamic>> _events =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get events => _events.stream;
  bool _listening = false;

  Future<void> start() async {
    try {
      final started =
          await _methodChannel.invokeMethod<bool>('startServer') ?? false;
      if (!started) {
        // Faltan permisos: se vuelven a intentar tras la concesión.
        developer.log(
            'BLE server no iniciado, reintentando en 4s...', name: '[WEARABLE]');
        await Future.delayed(const Duration(seconds: 4));
        if (await _methodChannel.invokeMethod<bool>('startServer') ?? false) {
          developer.log('BLE server started', name: '[WEARABLE]');
        }
      } else {
        developer.log('BLE server started', name: '[WEARABLE]');
      }
    } catch (e) {
      developer.log('BLE start error: $e', name: '[WEARABLE]');
    }
    _listen();
  }

  Future<void> stop() async {
    try {
      await _methodChannel.invokeMethod('stopServer');
    } catch (_) {}
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
  /// vía NOTIFY.
  Future<void> sendUserResponse(String type, {String? payload}) async {
    try {
      final data = {
        'type': type,
        'payload': ?payload,
      };
      await _methodChannel
          .invokeMethod('notifyResponse', jsonEncode(data));
    } catch (e) {
      developer.log('Notify error: $e', name: '[WEARABLE]');
    }
  }

  Future<void> dispose() async {
    await _events.close();
    _listening = false;
  }
}
