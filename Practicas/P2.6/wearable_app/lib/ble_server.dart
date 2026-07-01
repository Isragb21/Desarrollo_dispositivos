import 'package:flutter/services.dart';

class NativeBleServer {
  static const _channel = MethodChannel('com.uteq.wearable_app/ble');

  Future<bool> start() async {
    try {
      final result = await _channel.invokeMethod<bool>('startServer');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<void> stop() async {
    try {
      await _channel.invokeMethod('stopServer');
    } catch (_) {}
  }

  Future<void> updateSteps(int value) async {
    try {
      await _channel.invokeMethod('updateSteps', {'value': value});
    } catch (_) {}
  }

  Future<void> updateHeartRate(int value) async {
    try {
      await _channel.invokeMethod('updateHeartRate', {'value': value});
    } catch (_) {}
  }

  Future<void> updateCalories(int value) async {
    try {
      await _channel.invokeMethod('updateCalories', {'value': value});
    } catch (_) {}
  }

  Future<void> updateStatus(String value) async {
    try {
      await _channel.invokeMethod('updateStatus', {'value': value});
    } catch (_) {}
  }
}
