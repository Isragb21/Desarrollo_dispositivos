import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/activity_data.dart';
import '../services/ble_client.dart';

class ActivityProvider extends ChangeNotifier {
  final BLEClient _bleClient = BLEClient();
  StreamSubscription<ActivityData>? _dataSubscription;
  StreamSubscription<BLEConnectionState>? _connectionSubscription;

  ActivityData _activityData = const ActivityData();
  BLEConnectionState _connectionState = BLEConnectionState.disconnected;
  String? _errorMessage;

  ActivityData get activityData => _activityData;
  BLEConnectionState get connectionState => _connectionState;
  String? get errorMessage => _errorMessage;
  BLEClient get bleClient => _bleClient;

  ActivityProvider() {
    _connectionSubscription = _bleClient.connectionStream.listen((state) {
      _connectionState = state;
      if (state == BLEConnectionState.error) {
        _errorMessage = 'Error al conectar con el wearable';
      }
      notifyListeners();
    });

    _dataSubscription = _bleClient.dataStream.listen((data) {
      _activityData = _activityData.copyWith(
        steps: data.steps > 0 ? data.steps : _activityData.steps,
        heartRate: data.heartRate > 0 ? data.heartRate : _activityData.heartRate,
        calories: data.calories > 0 ? data.calories : _activityData.calories,
        status: data.status.isNotEmpty ? data.status : _activityData.status,
      );
      notifyListeners();
    });
  }

  void startScan() {
    _errorMessage = null;
    _bleClient.scanAndConnect();
    notifyListeners();
  }

  void stopScan() {
    FlutterBluePlus.stopScan();
  }

  void disconnect() {
    _bleClient.disconnect();
    _connectionState = BLEConnectionState.disconnected;
    _activityData = const ActivityData();
    notifyListeners();
  }

  @override
  void dispose() {
    _dataSubscription?.cancel();
    _connectionSubscription?.cancel();
    _bleClient.dispose();
    super.dispose();
  }
}
