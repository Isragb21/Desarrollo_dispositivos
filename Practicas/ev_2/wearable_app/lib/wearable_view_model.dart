import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'ble_server.dart';

enum WearableScreen { dashboard, cart, session, discount }

class WearableViewModel extends ChangeNotifier {
  WearableScreen _screen = WearableScreen.dashboard;

  // Carrito
  double _cartTotal = 0.0;
  int _cartCount = 0;

  // Sesión (2FA)
  String _sessionUser = '';

  // Wishlist / descuento
  String _discountGame = '';
  int _discountPercent = 0;

  // Simulador de sensores
  BleServer? _ble;
  Timer? _sensorTimer;
  final _random = Random();
  bool _sensorsRunning = false;
  int _steps = 0;
  int _heartRate = 75;
  double _calories = 0.0;

  WearableScreen get screen => _screen;
  double get cartTotal => _cartTotal;
  int get cartCount => _cartCount;
  String get sessionUser => _sessionUser;
  String get discountGame => _discountGame;
  int get discountPercent => _discountPercent;

  bool get sensorsRunning => _sensorsRunning;
  int get steps => _steps;
  int get heartRate => _heartRate;
  double get calories => _calories;

  void attachBle(BleServer ble) {
    _ble = ble;
  }

  /// Eventos recibidos del teléfono vía BLE.
  void handleEvent(Map<String, dynamic> event) {
    final type = event['type'] as String? ?? '';

    switch (type) {
      case 'cart':
        _cartTotal = (event['total'] as num?)?.toDouble() ?? 0.0;
        _cartCount = (event['count'] as num?)?.toInt() ?? 0;
        _screen = WearableScreen.cart;
        break;
      case 'session':
        _sessionUser = event['user'] as String? ?? '';
        _screen = WearableScreen.session;
        break;
      case 'discount':
        _discountGame = event['game'] as String? ?? '';
        _discountPercent = (event['percent'] as num?)?.toInt() ?? 0;
        _screen = WearableScreen.discount;
        break;
      default:
        return;
    }
    notifyListeners();
  }

  /// Respuestas del usuario hacia el teléfono.
  String responseForCart() => '{"type":"pay","total":$_cartTotal}';
  String responseForSession(bool approved) =>
      '{"type":"${approved ? "approve" : "reject"}","user":"$_sessionUser"}';
  String responseForDiscount(bool open) =>
      '{"type":"${open ? "open" : "dismiss"}","game":"$_discountGame"}';

  /// Arranca o detiene el simulador local de sensores. Cada segundo genera
  /// pasos, ritmo cardíaco y calorías y los notifica por BLE (NOTIFY).
  void toggleSensors() {
    if (_sensorsRunning) {
      _sensorTimer?.cancel();
      _sensorTimer = null;
      _sensorsRunning = false;
      notifyListeners();
      return;
    }

    _sensorsRunning = true;
    notifyListeners();
    _tick();
    _sensorTimer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    _steps += 1 + _random.nextInt(4);
    _heartRate = (_heartRate + _random.nextInt(7) - 3).clamp(55, 140);
    _calories += 0.08 + _random.nextDouble() * 0.30;
    _ble?.notifySensorData(_steps, _heartRate, _calories);
    notifyListeners();
  }

  void resetToCart() {
    _screen = WearableScreen.cart;
    notifyListeners();
  }

  @override
  void dispose() {
    _sensorTimer?.cancel();
    super.dispose();
  }
}
