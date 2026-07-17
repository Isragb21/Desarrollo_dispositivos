import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math';
import 'package:flutter/material.dart';
import 'ble_server.dart';

class SensorData {
  final int steps;
  final int heartRate;
  final int calories;
  final String status;

  SensorData({
    required this.steps,
    required this.heartRate,
    required this.calories,
    required this.status,
  });
}

class SensorSimulator {
  final Random _random = Random();
  Timer? _timer;
  Timer? _statusTimer;
  int _steps = 0;
  int _heartRate = 70;
  int _calories = 0;
  String _status = 'reposo';

  final StreamController<SensorData> _controller =
      StreamController<SensorData>.broadcast();

  Stream<SensorData> get dataStream => _controller.stream;

  void start() {
    _controller.add(SensorData(
      steps: _steps,
      heartRate: _heartRate,
      calories: _calories,
      status: _status,
    ));
    _statusTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      final statuses = ['reposo', 'caminando', 'corriendo'];
      _status = statuses[_random.nextInt(statuses.length)];
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      int baseHR;
      switch (_status) {
        case 'caminando':
          baseHR = 90;
          break;
        case 'corriendo':
          baseHR = 140;
          break;
        default:
          baseHR = 70;
      }

      _heartRate = (baseHR + _random.nextInt(7) - 3).clamp(40, 220);

      if (_status == 'corriendo') {
        _steps += _random.nextInt(5) + 2;
        _calories += _random.nextInt(3) + 1;
      } else if (_status == 'caminando') {
        _steps += _random.nextInt(3) + 1;
        _calories += _random.nextInt(2);
      } else {
        _steps += _random.nextInt(2);
      }

      _controller.add(SensorData(
        steps: _steps,
        heartRate: _heartRate,
        calories: _calories,
        status: _status,
      ));
    });
  }

  void stop() {
    _timer?.cancel();
    _statusTimer?.cancel();
    _timer = null;
    _statusTimer = null;
  }

  void dispose() {
    stop();
    _controller.close();
  }
}

void main() {
  runApp(const WearableApp());
}

class WearableApp extends StatelessWidget {
  const WearableApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Monitor Wearable',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        useMaterial3: true,
      ),
      home: const WearableScreen(),
    );
  }
}

class WearableScreen extends StatefulWidget {
  const WearableScreen({super.key});

  @override
  State<WearableScreen> createState() => _WearableScreenState();
}

class _WearableScreenState extends State<WearableScreen> {
  final SensorSimulator _simulator = SensorSimulator();
  final NativeBleServer _bleServer = NativeBleServer();
  SensorData? _currentData;
  bool _isTransmitting = false;
  StreamSubscription<SensorData>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = _simulator.dataStream.listen((data) {
      _currentData = data;
      if (_isTransmitting) {
        _bleServer.updateSteps(data.steps);
        _bleServer.updateHeartRate(data.heartRate);
        _bleServer.updateCalories(data.calories);
        _bleServer.updateStatus(data.status);
      }
      if (mounted) setState(() {});
    });
    _simulator.start();
    _initBle();
  }

  Future<void> _initBle() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      var started = await _bleServer.start();
      if (!started) {
        developer.log('BLE start failed, retrying in 3s...', name: '[WEARABLE]');
        await Future.delayed(const Duration(seconds: 3));
        started = await _bleServer.start();
      }
      if (mounted) setState(() => _isTransmitting = started);
    } catch (e) {
      developer.log('BLE init error: $e', name: '[WEARABLE]');
      if (mounted) setState(() => _isTransmitting = false);
    }
  }

  @override
  void dispose() {
    _simulator.stop();
    _bleServer.stop();
    _subscription?.cancel();
    _simulator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentData == null) {
      return const Scaffold(
        body: Center(
          child: Text('Esperando datos...',
              style: TextStyle(color: Colors.grey, fontSize: 18)),
        ),
      );
    }

    final data = _currentData!;
    final isHighHR = data.heartRate > 120;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            children: [
              Text(
                '${data.heartRate}',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: isHighHR ? Colors.red : Colors.white,
                  height: 1.0,
                ),
              ),
              Text(
                'BPM',
                style: TextStyle(
                    fontSize: 14,
                    color: isHighHR ? Colors.red.shade300 : Colors.grey),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMetric(
                      Icons.directions_walk, '${data.steps}', 'Pasos'),
                  _buildMetric(Icons.local_fire_department,
                      '${data.calories}', 'Cal'),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                data.status.toUpperCase(),
                style: const TextStyle(
                    fontSize: 16, color: Colors.cyanAccent, letterSpacing: 2),
              ),
               const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isTransmitting ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                    size: 14,
                    color: _isTransmitting ? Colors.blue : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isTransmitting ? 'BLE activo' : 'BLE no disponible',
                    style: TextStyle(fontSize: 11, color: _isTransmitting ? Colors.blue : Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetric(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 22),
        Text(value,
            style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}
