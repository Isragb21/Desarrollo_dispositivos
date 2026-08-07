import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform, debugPrint;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:http/http.dart' as http;
import 'package:gamestore_app/services/wearable_ble_constants.dart';

/// Cliente del puente BLE simulado (emuladores sin Bluetooth): la móvil y el
/// wearable se comunican vía HTTP a través del backend.
class _RelayClient {
  static String get _base {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/api/ble-relay';
    }
    return 'http://localhost:3000/api/ble-relay';
  }

  Future<bool> isWearableActive() async {
    try {
      final res = await http
          .get(Uri.parse('$_base/status'))
          .timeout(const Duration(seconds: 2));
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return json['wearableActive'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<void> sendEvent(Map<String, dynamic> event) async {
    try {
      await http
          .post(
            Uri.parse('$_base/events'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(event),
          )
          .timeout(const Duration(seconds: 3));
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> pollResponses() async {
    try {
      final res = await http
          .get(Uri.parse('$_base/responses'))
          .timeout(const Duration(seconds: 2));
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final list = json['responses'] as List? ?? [];
      return list
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (_) {
      return const [];
    }
  }
}

class WearableBleService {
  static final WearableBleService _instance = WearableBleService._internal();
  factory WearableBleService() => _instance;
  WearableBleService._internal();

  BluetoothDevice? _device;
  BluetoothCharacteristic? _cartTotalChar;
  BluetoothCharacteristic? _authAlertChar;
  BluetoothCharacteristic? _discountChar;
  BluetoothCharacteristic? _favoritesChar;
  BluetoothCharacteristic? _responseChar;
  BluetoothCharacteristic? _purchaseChar;
  BluetoothCharacteristic? _pairChar;

  bool _scanning = false;
  StreamSubscription? _scanSub;

  // Puente por red (usado en emuladores sin Bluetooth).
  _RelayClient? _relay;
  bool _relayConnected = false;
  Timer? _relayPollTimer;

  /// Estado de conexión (buscando / conectado / error / desconectado).
  final StreamController<String> _stateController =
      StreamController<String>.broadcast();
  Stream<String> get stateStream => _stateController.stream;

  /// Respuestas del wearable: `{"type":"approve"|"reject"|"pay"|"open"|"dismiss", ...}`.
  final StreamController<Map<String, dynamic>> _responses =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get responseStream => _responses.stream;

  BluetoothDevice? get device => _device;
  bool get isConnected => _device != null || _relayConnected;
  bool get isRelayConnection => _relayConnected;

  Future<void> scanAndConnect({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    if (_scanning) return;
    _scanning = true;
    _stateController.add('buscando');

    try {
      // 1) Puente por red (emuladores / Bluetooth no confiable): el wearable
      // publica su estado por HTTP, así que es el camino más rápido.
      if (await _tryRelay()) return;

      // 2) BLE real (dispositivos físicos con el wearable anunciándose).
      var adapterReady = false;
      try {
        final state = await FlutterBluePlus.adapterState
            .first
            .timeout(const Duration(seconds: 4));
        adapterReady = state == BluetoothAdapterState.on ||
            state == BluetoothAdapterState.turningOn;
      } catch (_) {
        adapterReady = false;
      }

      if (adapterReady) {
        await _scanBle(timeout: timeout);
      }

      // 3) Si BLE no encontró el wearable, último intento por el puente.
      if (_device == null && !_relayConnected) {
        debugPrint('[BLE] Sin conexión BLE, reintento por puente de red');
        await _connectViaRelay();
      }
    } finally {
      _scanning = false;
    }
  }

  /// Conecta por el puente de red si el wearable está activo.
  /// Devuelve `true` si se conectó.
  Future<bool> _tryRelay() async {
    final relay = _RelayClient();
    if (await relay.isWearableActive()) {
      debugPrint('[BLE] Wearable activo por puente de red, conectado');
      _relay = relay;
      _relayConnected = true;
      _stateController.add('conectado');
      _pollRelayResponses();
      return true;
    }
    return false;
  }

  Future<void> _scanBle({required Duration timeout}) async {
    try {
      if (FlutterBluePlus.isScanningNow) {
        await FlutterBluePlus.stopScan();
      }
      await FlutterBluePlus.startScan(timeout: timeout);
      _scanSub = FlutterBluePlus.scanResults.listen((results) {
        for (final result in results) {
          final hasService = result.advertisementData.serviceUuids
              .any((uuid) => uuid.toString().contains(
                    WearableBleConstants.serviceUUID,
                  ));
          if (hasService) {
            _scanSub?.cancel();
            FlutterBluePlus.stopScan();
            _connect(result.device);
            break;
          }
        }
      });
      await FlutterBluePlus.isScanning
          .where((scanning) => scanning == false)
          .first;
    } catch (e) {
      debugPrint('[BLE] Error de BLE: $e');
    }
  }

  Future<void> _connectViaRelay({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final relay = _RelayClient();
    _relay = relay;
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (await relay.isWearableActive()) {
        debugPrint('[BLE] Wearable activo por puente de red, conectado');
        _relayConnected = true;
        _stateController.add('conectado');
        _pollRelayResponses();
        return;
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }
    _relay = null;
    _stateController.add('error');
  }

  Future<void> _pollRelayResponses() async {
    if (!_relayConnected) return;
    final relay = _relay;
    if (relay == null) return;
    final responses = await relay.pollResponses();
    for (final response in responses) {
      _responses.add(response);
    }
    // Detección de desconexión: el wearable deja de publicar su estado cuando
    // la app se cierra o se reinicia. El backend lo marca inactivo tras 12s.
    if (_relayConnected && !await relay.isWearableActive()) {
      debugPrint('[BLE] Wearable inactivo, marcando desconectado');
      _relayConnected = false;
      _relay = null;
      _relayPollTimer?.cancel();
      _relayPollTimer = null;
      _stateController.add('desconectado');
      return;
    }
    _relayPollTimer =
        Timer(const Duration(milliseconds: 700), _pollRelayResponses);
  }

  Future<void> _connect(BluetoothDevice device) async {
    try {
      await device.connect(autoConnect: false);
      await _discover(device);
      _device = device;
      _stateController.add('conectado');
      _listenToDisconnect(device);
      _subscribeResponses();
    } catch (e) {
      _stateController.add('error');
    }
  }

  Future<void> _discover(BluetoothDevice device) async {
    final services = await device.discoverServices();
    for (final service in services) {
      if (!service.uuid
          .toString()
          .contains(WearableBleConstants.serviceUUID)) {
        continue;
      }
      for (final char in service.characteristics) {
        final id = char.uuid.toString().toLowerCase();
        if (id.contains(WearableBleConstants.cartTotalUUID)) {
          _cartTotalChar = char;
        } else if (id.contains(WearableBleConstants.authAlertUUID)) {
          _authAlertChar = char;
        } else if (id.contains(WearableBleConstants.discountAlertUUID)) {
          _discountChar = char;
        } else if (id.contains(WearableBleConstants.favoritesUUID)) {
          _favoritesChar = char;
        } else if (id.contains(WearableBleConstants.userResponseUUID)) {
          _responseChar = char;
        } else if (id.contains(WearableBleConstants.purchaseAlertUUID)) {
          _purchaseChar = char;
        } else if (id.contains(WearableBleConstants.pairUUID)) {
          _pairChar = char;
        }
      }
    }
  }

  void _listenToDisconnect(BluetoothDevice device) {
    device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        _device = null;
        _stateController.add('desconectado');
      }
    });
  }

  Future<void> _subscribeResponses() async {
    final char = _responseChar;
    if (char == null) return;
    try {
      await char.setNotifyValue(true);
      char.lastValueStream.listen((value) {
        final payload = utf8.decode(value);
        try {
          _responses.add(jsonDecode(payload) as Map<String, dynamic>);
        } catch (_) {
          _responses.add({'type': 'raw', 'message': payload});
        }
      });
    } catch (_) {}
  }

  Future<void> _write(
      BluetoothCharacteristic? char, Map<String, dynamic> data) async {
    final relay = _relay;
    if (_relayConnected && relay != null) {
      await relay.sendEvent(data);
      return;
    }
    if (char == null || _device == null) return;
    try {
      await char.write(utf8.encode(jsonEncode(data)));
    } catch (_) {}
  }

  Future<void> sendCart({
    required double total,
    required int count,
    List<String> games = const [],
  }) =>
      _write(_cartTotalChar, {
        'type': 'cart',
        'total': total,
        'count': count,
        'games': games,
      });

  Future<void> sendSessionAlert(String user) =>
      _write(_authAlertChar, {'type': 'session', 'user': user});

  Future<void> sendDiscountAlert({required String game, required int percent}) =>
      _write(_discountChar, {
        'type': 'discount',
        'game': game,
        'percent': percent,
      });

  /// Envía la wishlist de la cuenta al wearable.
  Future<void> sendFavorites({required List<String> games}) =>
      _write(_favoritesChar, {'type': 'favorites', 'games': games});

  Future<void> sendPurchaseAlert({
    required double total,
    required int games,
  }) =>
      _write(_purchaseChar, {
        'type': 'purchase',
        'total': total,
        'games': games,
      });

  /// Envía el evento de pareado al wearable: lo desbloquea e informa cuántos
  /// juegos tiene el usuario en su biblioteca.
  Future<void> sendPair({required int games}) =>
      _write(_pairChar, {'type': 'pair', 'games': games});

  Future<void> disconnect() async {
    // Avisa al wearable para que regrese a la pantalla de emparejamiento.
    await _write(_pairChar, {'type': 'unpair'});
    try {
      await _device?.disconnect();
    } catch (_) {}
    _device = null;
    _relayPollTimer?.cancel();
    _relayPollTimer = null;
    _relay = null;
    _relayConnected = false;
    _stateController.add('desconectado');
  }

  void dispose() {
    _scanSub?.cancel();
    _relayPollTimer?.cancel();
    _stateController.close();
    _responses.close();
  }
}
