import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get apiKey => dotenv.env['OPENWEATHER_API_KEY']?.trim() ?? '';
  static String get baseUrl =>
      dotenv.env['OPENWEATHER_BASE_URL']?.trim() ??
      'https://api.openweathermap.org/data/2.5/weather';

  static bool isConfigured() {
    return apiKey.isNotEmpty &&
        apiKey != 'tu_api_key_aqui' &&
        baseUrl.isNotEmpty;
  }
}
