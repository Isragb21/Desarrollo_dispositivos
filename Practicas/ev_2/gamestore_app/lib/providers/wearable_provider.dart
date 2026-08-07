import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:gamestore_app/models/game.dart';
import 'package:gamestore_app/providers/game_provider.dart';
import 'package:gamestore_app/screens/game_detail_screen.dart';
import 'package:gamestore_app/services/api_service.dart';
import 'package:gamestore_app/services/app_navigator.dart';
import 'package:gamestore_app/services/wearable_ble_service.dart';
enum WearableConnectionStatus { searching, connected, error, disconnected }

class WearableProvider extends ChangeNotifier {
  final WearableBleService _ble = WearableBleService();
  WearableConnectionStatus _status = WearableConnectionStatus.disconnected;
  Map<String, dynamic>? _lastResponse;
  bool _paired = false;
  StreamSubscription? _stateSub;
  StreamSubscription? _responseSub;

  /// Ofertas del catálogo: cada 30s el backend pone un juego en oferta.
  /// Si hay wearable conectado la notificación llega al reloj (evento
  /// `discount` del puente); si no, se muestra directamente en el celular.
  int? _lastOfferAt;
  String _lastOfferTitle = '';
  Timer? _offerTimer;

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
      } else if (type == 'open') {
        _openGameOnPhone(response);
      }
    });
    _pollActiveOffer();
  }

  /// Consulta la oferta del momento. Si es nueva:
  /// - wearable conectado  -> la notificación ya llegó al reloj por el puente.
  /// - wearable por BLE     -> se reenvía la alerta al reloj.
  /// - sin wearable         -> notificación local en el celular.
  Future<void> _pollActiveOffer() async {
    final offer = await ApiService.fetchActiveOffer();
    if (offer != null) {
      final at = (offer['updatedAt'] as num?)?.toInt() ?? 0;
      if (at != 0 && at != _lastOfferAt) {
        _lastOfferAt = at;
        final game = offer['game'] as String? ?? '';
        final percent = (offer['percent'] as num?)?.toInt() ?? 0;
        if (game.isNotEmpty) {
          _lastOfferTitle = game;
          // Refresca el catálogo para que el descuento se vea de verdad.
          _refreshCatalog();
          // Si la conexión es por BLE real (no puente), la notificación de la
          // oferta no llega por el backend y se reenvía al reloj. La notifi-
          // cación del celular la publica OfferService (segundo plano).
          if (_status == WearableConnectionStatus.connected &&
              !_ble.isRelayConnection) {
            await _ble.sendDiscountAlert(game: game, percent: percent);
          }
        }
      }
    }
    _offerTimer?.cancel();
    _offerTimer = Timer(const Duration(seconds: 10), _pollActiveOffer);
  }

  /// El wearable pulsó VER en la notificación de oferta: abre en el celular
  /// la pantalla del juego en descuento.
  Future<void> _openGameOnPhone(Map<String, dynamic> response) async {
    final navigator = appNavigatorKey.currentState;
    final ctx = appNavigatorKey.currentContext;
    if (navigator == null || ctx == null) return;
    final games = Provider.of<GameProvider>(ctx, listen: false);
    final title = (response['payload'] as String?) ?? _lastOfferTitle;
    Game? game = games.findGame(title);
    if (game == null) {
      await games.fetchGames();
      game = games.findGame(title);
    }
    final found = game;
    if (found != null) {
      navigator.push(
        MaterialPageRoute(builder: (_) => GameDetailScreen(game: found)),
      );
    }
  }

  /// Refresca el catálogo para que el descuento aplicado en el backend
  /// aparezca realmente en la tienda del celular.
  void _refreshCatalog() {
    final ctx = appNavigatorKey.currentContext;
    if (ctx == null) return;
    Provider.of<GameProvider>(ctx, listen: false).fetchGames();
  }

  Future<void> connect() async {
    // BLE solo existe en dispositivos reales/emuladores (no en la web).
    if (kIsWeb) return;
    await _ble.scanAndConnect();
  }

  Future<void> disconnect() async {
    _paired = false;
    await _ble.disconnect();
  }

  /// Vincula el wearable: envía el evento "pair" que lo desbloquea.
  Future<void> sendPair({required int games}) async {
    await _ble.sendPair(games: games);
    _paired = true;
    notifyListeners();
  }

  Future<void> sendCart({
    required double total,
    required int count,
    List<String> games = const [],
  }) =>
      _ble.sendCart(total: total, count: count, games: games);

  Future<void> sendSessionAlert(String user) =>
      _ble.sendSessionAlert(user);

  Future<void> sendDiscountAlert({
    required String game,
    required int percent,
  }) =>
      _ble.sendDiscountAlert(game: game, percent: percent);

  Future<void> sendFavorites({required List<String> games}) =>
      _ble.sendFavorites(games: games);

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
    _offerTimer?.cancel();
    _approvals.close();
    _ble.dispose();
    super.dispose();
  }
}
