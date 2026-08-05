import 'dart:async';
import 'dart:convert';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:gamestore_app/services/wearable_ble_constants.dart';

class WearableBleService {
  static final WearableBleService _instance = WearableBleService._internal();
  factory WearableBleService() => _instance;
  WearableBleService._internal();

  BluetoothDevice? _device;
  BluetoothCharacteristic? _cartTotalChar;
  BluetoothCharacteristic? _authAlertChar;
  BluetoothCharacteristic? _discountChar;
  BluetoothCharacteristic? _responseChar;
  BluetoothCharacteristic? _purchaseChar;
  BluetoothCharacteristic? _pairChar;

  bool _scanning = false;
  StreamSubscription? _scanSub;

  /// Estado de conexión (buscando / conectado / error / desconectado).
  final StreamController<String> _stateController =
      StreamController<String>.broadcast();
  Stream<String> get stateStream => _stateController.stream;

  /// Respuestas del wearable: `{"type":"approve"|"reject"|"pay"|"open"|"dismiss", ...}`.
  final StreamController<Map<String, dynamic>> _responses =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get responseStream => _responses.stream;

  BluetoothDevice? get device => _device;
  bool get isConnected => _device != null;

  Future<void> scanAndConnect({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    if (_scanning) return;
    _scanning = true;
    _stateController.add('buscando');

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
      _stateController.add('error');
    } finally {
      _scanning = false;
    }
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

  Future<void> _write(BluetoothCharacteristic? char, Map<String, dynamic> data) async {
    if (char == null || _device == null) return;
    try {
      await char.write(utf8.encode(jsonEncode(data)));
    } catch (_) {}
  }

  Future<void> sendCart({required double total, required int count}) =>
      _write(_cartTotalChar, {'total': total, 'count': count});

  Future<void> sendSessionAlert(String user) =>
      _write(_authAlertChar, {'user': user});

  Future<void> sendDiscountAlert({required String game, required int percent}) =>
      _write(_discountChar, {'game': game, 'percent': percent});

  Future<void> sendPurchaseAlert({
    required double total,
    required int games,
  }) =>
      _write(_purchaseChar, {'total': total, 'games': games});

  /// Envía el evento de pareado al wearable: lo desbloquea e informa cuántos
  /// juegos tiene el usuario en su biblioteca.
  Future<void> sendPair({required int games}) =>
      _write(_pairChar, {'games': games});

  Future<void> disconnect() async {
    try {
      await _device?.disconnect();
    } catch (_) {}
    _device = null;
  }

  void dispose() {
    _scanSub?.cancel();
    _stateController.close();
    _responses.close();
  }
}
