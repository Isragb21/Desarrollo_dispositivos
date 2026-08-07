import 'dart:async';

import 'package:flutter/foundation.dart';

import 'ble_server.dart';

enum WearableScreen { dashboard, cart, session, discount, favorites, success }

class WearableViewModel extends ChangeNotifier {
  WearableScreen _screen = WearableScreen.dashboard;

  // Pareado: la app permanece bloqueada hasta que el teléfono envía "pair".
  bool _paired = false;
  bool _pairing = false;
  int _ownedGames = 0;

  // Ventana corta tras emparejar: el carrito/favoritos llegan junto con "pair"
  // y actualizan datos, pero sin cambiar de pantalla (se muestra el dashboard).
  bool _justPaired = false;
  Timer? _justPairedTimer;

  // Carrito
  double _cartTotal = 0.0;
  int _cartCount = 0;
  List<String> _cartGames = [];

  // Sesión (2FA)
  String _sessionUser = '';

  // Wishlist / descuento
  String _discountGame = '';
  int _discountPercent = 0;

  // Favoritos (wishlist de la cuenta)
  List<String> _favorites = [];

  // Compra exitosa
  double _purchaseTotal = 0.0;
  int _purchaseGames = 0;

  BleServer? _ble;

  WearableScreen get screen => _screen;
  bool get paired => _paired;
  bool get pairing => _pairing;
  int get ownedGames => _ownedGames;
  double get cartTotal => _cartTotal;
  int get cartCount => _cartCount;
  List<String> get cartGames => List.unmodifiable(_cartGames);
  String get sessionUser => _sessionUser;
  String get discountGame => _discountGame;
  int get discountPercent => _discountPercent;
  List<String> get favorites => List.unmodifiable(_favorites);
  double get purchaseTotal => _purchaseTotal;
  int get purchaseGames => _purchaseGames;

  void attachBle(BleServer ble) {
    _ble = ble;
  }

  /// El usuario pulsó "ESTABLECER CONEXIÓN": asegura que el servidor BLE esté
  /// anunciando y espera el evento "pair" del teléfono.
  Future<void> beginPairing() async {
    _pairing = true;
    notifyListeners();
    await _ble?.start();
  }

  /// Eventos recibidos del teléfono vía BLE.
  void handleEvent(Map<String, dynamic> event) {
    final type = event['type'] as String? ?? '';

    switch (type) {
      case 'pair':
        _ownedGames = (event['games'] as num?)?.toInt() ?? 0;
        _paired = true;
        _pairing = false;
        _justPaired = true;
        _justPairedTimer?.cancel();
        _justPairedTimer = Timer(const Duration(seconds: 2), () {
          _justPaired = false;
        });
        _screen = WearableScreen.dashboard;
        break;
      case 'cart':
        _cartTotal = (event['total'] as num?)?.toDouble() ?? 0.0;
        _cartCount = (event['count'] as num?)?.toInt() ?? 0;
        final games = event['games'];
        _cartGames = switch (games) {
          final List list => list.map((g) => g.toString()).toList(),
          _ => <String>[],
        };
        if (!_justPaired) {
          _screen = WearableScreen.cart;
        }
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
      case 'favorites':
        final games = event['games'];
        _favorites = switch (games) {
          final List list => list.map((g) => g.toString()).toList(),
          _ => <String>[],
        };
        if (!_justPaired) {
          _screen = WearableScreen.favorites;
        }
        break;
      case 'purchase':
        _purchaseTotal = (event['total'] as num?)?.toDouble() ?? 0.0;
        _purchaseGames = (event['games'] as num?)?.toInt() ?? 0;
        _screen = WearableScreen.success;
        break;
      case 'unpair':
        // El teléfono se desconectó: volver a la pantalla de emparejamiento.
        _paired = false;
        _pairing = false;
        _cartTotal = 0.0;
        _cartCount = 0;
        _cartGames = [];
        _favorites = [];
        _sessionUser = '';
        _discountGame = '';
        _discountPercent = 0;
        _purchaseTotal = 0.0;
        _purchaseGames = 0;
        _screen = WearableScreen.dashboard;
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

  void resetToCart() {
    _screen = WearableScreen.cart;
    notifyListeners();
  }

  /// Navegación local (sin evento del teléfono): ver el carrito de la cuenta.
  void showCart() {
    _screen = WearableScreen.cart;
    notifyListeners();
  }

  /// Navegación local: ver los favoritos de la cuenta.
  void showFavorites() {
    _screen = WearableScreen.favorites;
    notifyListeners();
  }

  void backToDashboard() {
    _screen = WearableScreen.dashboard;
    notifyListeners();
  }

  @override
  void dispose() {
    _justPairedTimer?.cancel();
    super.dispose();
  }
}
