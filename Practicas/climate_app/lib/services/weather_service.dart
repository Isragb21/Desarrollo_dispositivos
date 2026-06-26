import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/weather_model.dart';

class WeatherService {
  Future<Weather> getWeather(String city) async {
    final sanitized = city
        .replaceAll(RegExp(r'[^a-zA-Z0-9áéíóúÁÉÍÓÚñÑ\s]'), '')
        .trim();
    if (sanitized.isEmpty) {
      throw Exception('City name is invalid');
    }

    if (!AppConfig.isConfigured()) {
      throw Exception('API key not configured.');
    }

    final baseUri = Uri.parse(AppConfig.baseUrl);
    final uri = Uri(
      scheme: baseUri.scheme,
      host: baseUri.host,
      path: baseUri.path,
      queryParameters: {
        'q': sanitized,
        'appid': AppConfig.apiKey,
        'units': 'metric',
        'lang': 'es',
      },
    );

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return Weather.fromJson(data);
      }

      String apiMessage = '';
      try {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        apiMessage = errorData['message'] != null
            ? ': ${errorData['message']}'
            : '';
      } catch (_) {
        apiMessage = '';
      }

      if (response.statusCode == 401) {
        throw Exception(
          'Invalid API key$apiMessage. Verifica OPENWEATHER_API_KEY en .env y usa una clave de OpenWeatherMap.',
        );
      } else if (response.statusCode == 404) {
        throw Exception('City not found$apiMessage');
      } else if (response.statusCode == 429) {
        throw Exception('API rate limit exceeded. Try again later$apiMessage');
      } else {
        throw Exception(
          'Weather service error: ${response.statusCode}$apiMessage',
        );
      }
    } on SocketException {
      throw Exception('No internet connection. Check your network.');
    } on TimeoutException {
      throw Exception('Request timed out. The server may be slow.');
    }
  }
}
