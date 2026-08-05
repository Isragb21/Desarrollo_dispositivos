import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:gamestore_app/services/api_service.dart';
import 'package:gamestore_app/services/wearable_ble_service.dart';
enum WearableConnectionStatus { searching, connected, error, disconnected }

class WearableProvider extends ChangeNotifier {
  final WearableBleService _ble = WearableBleService();
  WearableConnectionStatus _status = WearableConnectionStatus.disconnected;
  Map<String, dynamic>? _lastResponse;
  bool _paired = false;
  StreamSubscription? _stateSub;
  StreamSubscription? _responseSub;

  /// Respuestas de aprobación/rechazo del wearable (2FA).
  final StreamController<Map<String, dynamic>> _approvals =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get approvalStream => _approvals.stream;

  WearableConnectionStatus get status => _status;
  bool get isConnected => _status == WearableConnectionStatus.connected;
  Map<String, dynamic>? get lastResponse => _lastResponse;

  /// El teléfono ya vinculó el wearable (se envió el evento "pair").
  bool get paired => _paired;

  void init() {
    _stateSub = _ble.stateStream.listen((state) {
      _status = switch (state) {
        'buscando' => WearableConnectionStatus.searching,
        'conectado' => WearableConnectionStatus.connected,
        'desconectado' => WearableConnectionStatus.disconnected,
        _ => WearableConnectionStatus.error,
      };
      if (state != 'conectado') _paired = false;
      notifyListeners();
    });
    _responseSub = _ble.responseStream.listen((response) {
      _lastResponse = response;
      notifyListeners();
      final type = response['type'] as String? ?? '';
      if (type == 'pay') {
        _completeWearablePayment(response);
      } else if (type == 'approve' || type == 'reject') {
        _approvals.add(response);
      }
    });
  }

  Future<void> connect() async {
    // BLE solo existe en dispositivos reales/emuladores (no en la web).
    if (kIsWeb) return;
    await _ble.scanAndConnect();
  }

  /// Vincula el wearable: envía el evento "pair" que lo desbloquea.
  Future<void> sendPair({required int games}) async {
    await _ble.sendPair(games: games);
    _paired = true;
    notifyListeners();
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
    _approvals.close();
    _ble.dispose();
    super.dispose();
  }
}
