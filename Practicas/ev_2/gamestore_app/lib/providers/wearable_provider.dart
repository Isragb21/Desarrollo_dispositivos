import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:gamestore_app/services/api_service.dart';
import 'package:gamestore_app/services/wearable_ble_service.dart';
enum WearableConnectionStatus { searching, connected, error, disconnected }

/// Umbral de ritmo cardíaco que dispara la alerta de seguridad (SA.1.B).
const int kHeartRateThreshold = 110;

class WearableProvider extends ChangeNotifier {
  final WearableBleService _ble = WearableBleService();
  WearableConnectionStatus _status = WearableConnectionStatus.disconnected;
  Map<String, dynamic>? _lastResponse;
  SensorReading _reading = const SensorReading();
  StreamSubscription? _stateSub;
  StreamSubscription? _responseSub;
  StreamSubscription? _sensorSub;

  WearableConnectionStatus get status => _status;
  bool get isConnected => _status == WearableConnectionStatus.connected;
  Map<String, dynamic>? get lastResponse => _lastResponse;
  SensorReading get reading => _reading;

  /// Alerta de umbral: ritmo cardíaco por encima de [kHeartRateThreshold].
  bool get isHeartRateHigh {
    final hr = _reading.heartRate;
    return hr != null && hr > kHeartRateThreshold;
  }

  void init() {
    _stateSub = _ble.stateStream.listen((state) {
      _status = switch (state) {
        'buscando' => WearableConnectionStatus.searching,
        'conectado' => WearableConnectionStatus.connected,
        'desconectado' => WearableConnectionStatus.disconnected,
        _ => WearableConnectionStatus.error,
      };
      notifyListeners();
    });
    _responseSub = _ble.responseStream.listen((response) {
      _lastResponse = response;
      notifyListeners();
      if (response['type'] == 'pay') {
        _completeWearablePayment(response);
      }
    });
    _sensorSub = _ble.sensorStream.listen((reading) {
      _reading = reading;
      notifyListeners();
    });
  }

  Future<void> connect() async {
    // BLE solo existe en dispositivos reales/emuladores (no en la web).
    if (kIsWeb) return;
    await _ble.scanAndConnect();
  }

  Future<void> sendCart({required double total, required int count}) =>
      _ble.sendCart(total: total, count: count);

  Future<void> sendSessionAlert(String user) =>
      _ble.sendSessionAlert(user);

  Future<void> sendDiscountAlert({
    required String game,
    required int percent,
  }) =>
      _ble.sendDiscountAlert(game: game, percent: percent);

  Future<void> sendPurchaseAlert({
    required double total,
    required int games,
  }) =>
      _ble.sendPurchaseAlert(total: total, games: games);

  /// El wearable pulsó "PAGAR": se completa el pago y se confirma al
  /// wearable con una notificación de compra exitosa.
  Future<void> _completeWearablePayment(Map<String, dynamic> response) async {
    final total = (response['total'] as num?)?.toDouble() ?? 0.0;
    final result = await ApiService.simulatePayment();
    if (result != null) {
      await sendPurchaseAlert(
        total: total,
        games: (result['juegos_adquiridos'] as num?)?.toInt() ?? 0,
      );
    }
  }

  void clearResponse() {
    _lastResponse = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _responseSub?.cancel();
    _sensorSub?.cancel();
    _ble.dispose();
    super.dispose();
  }
}
