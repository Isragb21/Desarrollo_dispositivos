import 'dart:developer' as developer;
import 'package:flutter/services.dart';

class NativeBleServer {
  static const _channel = MethodChannel('com.uteq.wearable_app/ble');

  Future<bool> start() async {
    try {
      final result = await _channel.invokeMethod<bool>('startServer');
      final success = result ?? false;
      developer.log('BLE server start: $success', name: '[WEARABLE]');
      return success;
    } catch (e) {
      developer.log('BLE server start error: $e', name: '[WEARABLE]');
      return false;
    }
  }

  Future<void> stop() async {
    try {
      await _channel.invokeMethod('stopServer');
      developer.log('BLE server stopped', name: '[WEARABLE]');
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
