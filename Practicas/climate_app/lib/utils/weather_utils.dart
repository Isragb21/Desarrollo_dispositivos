class WeatherUtils {
  // Convierte Celsius a Fahrenheit
  static double celsiusToFahrenheit(int celsius) {
    return (celsius * 9 / 5) + 32;
  }

  // Convierte Fahrenheit a Celsius
  static int fahrenheitToCelsius(double fahrenheit) {
    return ((fahrenheit - 32) * 5 / 9).toInt();
  }

  // Obtiene ícono según condición
  static String getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'sunny':
        return '☀️';
      case 'cloudy':
        return '☁️';
      case 'rainy':
        return '🌧️';
      case 'snowy':
        return '❄️';
      default:
        return '❓';
    }
  }

  // Valida temperatura (está en rango válido)
  static bool isValidTemperature(int temp) {
    return temp >= -50 && temp <= 60;
  }
}
