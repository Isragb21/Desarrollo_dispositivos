import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../ble_constants.dart';
import '../models/activity_data.dart';

enum BLEConnectionState { disconnected, scanning, connecting, connected, error }

class BLEClient {
  BluetoothDevice? _device;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  final StreamController<ActivityData> _dataController =
      StreamController<ActivityData>.broadcast();
  final StreamController<BLEConnectionState> _connectionController =
      StreamController<BLEConnectionState>.broadcast();

  Stream<ActivityData> get dataStream => _dataController.stream;
  Stream<BLEConnectionState> get connectionStream => _connectionController.stream;

  Future<void> scanAndConnect() async {
    _connectionController.add(BLEConnectionState.scanning);

    _scanSubscription?.cancel();

    try {
      final state = await FlutterBluePlus.adapterState.first;
      if (state == BluetoothAdapterState.unauthorized) {
        _connectionController.add(BLEConnectionState.error);
        return;
      }
      await FlutterBluePlus.turnOn();

      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 30),
      );

      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (final result in results) {
          final name = result.advertisementData.advName.toLowerCase();
          final serviceUuids = result.advertisementData.serviceUuids
              .map((u) => u.toString().toLowerCase());
          if (serviceUuids.contains(BLEConstants.serviceUUID.toLowerCase()) ||
              name.contains('wearable')) {
            FlutterBluePlus.stopScan();
            _connectToDevice(result.device);
            return;
          }
        }
      });
    } catch (e) {
      _connectionController.add(BLEConnectionState.error);
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    _device = device;
    _connectionController.add(BLEConnectionState.connecting);

    try {
      await device.connect();
      _connectionController.add(BLEConnectionState.connected);

      _connectionSubscription = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _connectionController.add(BLEConnectionState.disconnected);
          _cleanup();
        }
      });

      await _subscribeToServices(device);
    } catch (e) {
      _connectionController.add(BLEConnectionState.error);
    }
  }

  Future<void> _subscribeToServices(BluetoothDevice device) async {
    final services = await device.discoverServices();

    for (final service in services) {
      if (service.uuid.toString().toUpperCase() ==
          BLEConstants.serviceUUID.toUpperCase()) {
        for (final characteristic in service.characteristics) {
          await characteristic.setNotifyValue(true);

          characteristic.onValueReceived.listen((value) {
            final uuid = characteristic.uuid.toString().toUpperCase();
            if (uuid == BLEConstants.stepsUUID.toUpperCase()) {
              _dataController.add(ActivityData(steps: _bytesToInt32(value)));
            } else if (uuid == BLEConstants.heartRateUUID.toUpperCase()) {
              final hr = value.isNotEmpty ? value[0] : 0;
              _dataController.add(ActivityData(heartRate: hr));
            } else if (uuid == BLEConstants.caloriesUUID.toUpperCase()) {
              _dataController.add(ActivityData(calories: _bytesToInt16(value)));
            } else if (uuid == BLEConstants.statusUUID.toUpperCase()) {
              _dataController.add(ActivityData(status: utf8.decode(value)));
            }
          });
        }
      }
    }
  }

  void disconnect() {
    _device?.disconnect();
    _cleanup();
  }

  void _cleanup() {
    _scanSubscription?.cancel();
    _scanSubscription = null;
    _connectionSubscription?.cancel();
    _connectionSubscription = null;
    _device = null;
  }

  void dispose() {
    disconnect();
    _dataController.close();
    _connectionController.close();
  }

  int _bytesToInt32(List<int> bytes) {
    if (bytes.length < 4) return 0;
    return bytes[0] |
        (bytes[1] << 8) |
        (bytes[2] << 16) |
        (bytes[3] << 24);
  }

  int _bytesToInt16(List<int> bytes) {
    if (bytes.length < 2) return 0;
    return bytes[0] | (bytes[1] << 8);
  }
}
