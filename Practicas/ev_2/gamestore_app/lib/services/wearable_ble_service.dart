import 'dart:async';
import 'dart:convert';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:gamestore_app/services/wearable_ble_constants.dart';

/// Lectura de sensores del wearable (una por tipo de dato).
class SensorReading {
  const SensorReading({this.steps, this.heartRate, this.calories});

  final int? steps;
  final int? heartRate;
  final double? calories;

  SensorReading copyWith({int? steps, int? heartRate, double? calories}) {
    return SensorReading(
      steps: steps ?? this.steps,
      heartRate: heartRate ?? this.heartRate,
      calories: calories ?? this.calories,
    );
  }

  bool get isComplete =>
      steps != null && heartRate != null && calories != null;
}

class WearableBleService {
  static final WearableBleService _instance = WearableBleService._internal();
  factory WearableBleService() => _instance;
  WearableBleService._internal();

  BluetoothDevice? _device;
  BluetoothCharacteristic? _cartTotalChar;
  BluetoothCharacteristic? _authAlertChar;
  BluetoothCharacteristic? _discountChar;
  BluetoothCharacteristic? _stepsChar;
  BluetoothCharacteristic? _heartRateChar;
  BluetoothCharacteristic? _caloriesChar;
  BluetoothCharacteristic? _responseChar;

  bool _scanning = false;
  StreamSubscription? _scanSub;
  SensorReading _currentReading = const SensorReading();

  /// Estado de conexión (buscando / conectado / error / desconectado).
  final StreamController<String> _stateController =
      StreamController<String>.broadcast();
  Stream<String> get stateStream => _stateController.stream;

  /// Respuestas del wearable: `{"type":"approve"|"reject"|"pay"|"open"|"dismiss", ...}`.
  final StreamController<Map<String, dynamic>> _responses =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get responseStream => _responses.stream;

  /// Lecturas de sensores en tiempo real (3 tipos: pasos, ritmo, calorías).
  final StreamController<SensorReading> _sensorController =
      StreamController<SensorReading>.broadcast();
  Stream<SensorReading> get sensorStream => _sensorController.stream;
  SensorReading get currentReading => _currentReading;

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
      _subscribeSensors();
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
        } else if (id.contains(WearableBleConstants.stepsUUID)) {
          _stepsChar = char;
        } else if (id.contains(WearableBleConstants.heartRateUUID)) {
          _heartRateChar = char;
        } else if (id.contains(WearableBleConstants.caloriesUUID)) {
          _caloriesChar = char;
        } else if (id.contains(WearableBleConstants.userResponseUUID)) {
          _responseChar = char;
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

  /// Suscribe NOTIFY de las 3 características de sensores (pasos, ritmo,
  /// calorías) y emite una lectura combinada por cada notificación.
  Future<void> _subscribeSensors() async {
    Future<void> watch(BluetoothCharacteristic? char,
        void Function(String value) onValue) async {
      if (char == null) return;
      try {
        await char.setNotifyValue(true);
        char.lastValueStream.listen((value) {
          onValue(utf8.decode(value));
        });
      } catch (_) {}
    }

    await watch(_stepsChar, (v) => _applyReading(
        _currentReading.copyWith(steps: int.tryParse(v))));
    await watch(_heartRateChar, (v) => _applyReading(
        _currentReading.copyWith(heartRate: int.tryParse(v))));
    await watch(_caloriesChar, (v) => _applyReading(
        _currentReading.copyWith(calories: double.tryParse(v))));
  }

  void _applyReading(SensorReading reading) {
    _currentReading = reading;
    _sensorController.add(reading);
  }

  Future<void> sendCart({required double total, required int count}) =>
      _write(_cartTotalChar, {'total': total, 'count': count});

  Future<void> sendSessionAlert(String user) =>
      _write(_authAlertChar, {'user': user});

  Future<void> sendDiscountAlert({required String game, required int percent}) =>
      _write(_discountChar, {'game': game, 'percent': percent});

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
    _sensorController.close();
  }
}
