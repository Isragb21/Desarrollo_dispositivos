import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/weather_model.dart';
import '../services/ble_service.dart';
import '../services/weather_service.dart';

class WeatherProvider extends ChangeNotifier {
  Weather? _weather;
  bool _isLoading = false;
  String? _errorMessage;
  int _tempUnit = 0;

  final BLEService bleService = BLEService();
  final WeatherService weatherService = WeatherService();

  Weather? get weather => _weather;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get temperatureUnit => _tempUnit == 0 ? '°C' : '°F';

  Future<void> fetchWeather(String city) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _weather = await weatherService.getWeather(city);
    } on Exception catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } catch (e) {
      _errorMessage = 'Unexpected error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadWeather(String city) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 1));
      _weather = Weather(
        city: city,
        temperature: 24,
        condition: 'cloudy',
        description: 'nublado',
        humidity: 65,
        windSpeed: 12.0,
      );
    } catch (e) {
      _errorMessage = 'Error loading weather: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> loadWeatherFromBLE(BluetoothDevice device) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      const targetUuid = "19b10001-e8f2-537e-4f6c-d104768a1214";
      final data = await bleService.readWeatherCharacteristic(
        device,
        targetUuid,
      );

      if (data != null) {
        _weather = Weather(
          city: data['city'] ?? 'Reloj BLE',
          temperature: data['temperature'] ?? 0,
          condition: data['condition'] ?? 'sunny',
          description: data['description'] ?? '',
          humidity: data['humidity'] ?? 50,
          windSpeed: (data['windSpeed'] as num?)?.toDouble() ?? 0.0,
        );
        return null;
      }

      return 'Datos inválidos o no se encontró la característica';
    } catch (e) {
      return 'Error leyendo BLE: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void toggleTemperatureUnit() {
    _tempUnit = _tempUnit == 0 ? 1 : 0;
    notifyListeners();
  }

  void updateTemperature(int newTemp) {
    if (_weather != null) {
      _weather = Weather(
        city: _weather!.city,
        temperature: newTemp,
        condition: _weather!.condition,
        description: _weather!.description,
        humidity: _weather!.humidity,
        windSpeed: _weather!.windSpeed,
      );
      notifyListeners();
    }
  }
}
