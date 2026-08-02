import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleService {
  static final BleService _instance = BleService._internal();
  factory BleService() => _instance;
  BleService._internal();

  BluetoothDevice? _connectedTv;
  bool _isScanning = false;
  StreamSubscription? _scanSubscription;

  static const String _tvServiceUuid = "0000game-0000-1000-8000-00805f9b34fb";
  static const String _tvCommandCharUuid = "0000cmd1-0000-1000-8000-00805f9b34fb";
  static const String _tvStatusCharUuid = "0000stat-0000-1000-8000-00805f9b34fb";

  BluetoothDevice? get connectedTv => _connectedTv;
  bool get isConnected => _connectedTv != null;

  final StreamController<Map<String, dynamic>> _statusController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get tvStatusStream => _statusController.stream;

  Future<List<ScanResult>> scanForTv({Duration timeout = const Duration(seconds: 10)}) async {
    if (_isScanning) return [];
    _isScanning = true;

    List<ScanResult> results = [];
    try {
      await FlutterBluePlus.startScan(timeout: timeout);
      _scanSubscription = FlutterBluePlus.scanResults.listen((r) {
        results = r;
      });
      await FlutterBluePlus.isScanning
          .where((scanning) => scanning == false)
          .first;
    } catch (e) {
      // ignore scan errors
    } finally {
      _isScanning = false;
    }
    return results;
  }

  Future<bool> connectToTv(BluetoothDevice device) async {
    try {
      await device.connect(autoConnect: false);
      _connectedTv = device;
      _listenToStatus(device);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _listenToStatus(BluetoothDevice device) async {
    try {
      List<BluetoothService> services = await device.discoverServices();
      for (var service in services) {
        if (service.uuid.toString().contains(_tvServiceUuid)) {
          for (var char in service.characteristics) {
            if (char.uuid.toString().contains(_tvStatusCharUuid)) {
              await char.setNotifyValue(true);
              char.lastValueStream.listen((value) {
                _statusController.add({'raw': value});
              });
            }
          }
        }
      }
    } catch (e) {
      // ignore subscription errors
    }
  }

  Future<bool> sendCommand(String command) async {
    if (_connectedTv == null) return false;
    try {
      List<BluetoothService> services = await _connectedTv!.discoverServices();
      for (var service in services) {
        if (service.uuid.toString().contains(_tvServiceUuid)) {
          for (var char in service.characteristics) {
            if (char.uuid.toString().contains(_tvCommandCharUuid)) {
              await char.write(command.codeUnits);
              return true;
            }
          }
        }
      }
    } catch (e) {
      return false;
    }
    return false;
  }

  Future<void> disconnect() async {
    await _connectedTv?.disconnect();
    _connectedTv = null;
  }

  void stopScan() {
    _scanSubscription?.cancel();
    FlutterBluePlus.stopScan();
    _isScanning = false;
  }

  void dispose() {
    _scanSubscription?.cancel();
    _statusController.close();
    FlutterBluePlus.stopScan();
  }
}
