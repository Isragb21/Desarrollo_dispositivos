import 'package:flutter/material.dart';

// Función pura: Formatea la temperatura
String formatTemperature(double temp, String unit) {
  return '${temp.toInt()}°$unit';
}

// Función pura: Devuelve el icono correcto según la condición
IconData getWeatherIcon(String condition) {
  switch (condition.toLowerCase()) {
    case 'sunny':
      return Icons.wb_sunny;
    case 'rainy':
      return Icons.water_drop;
    case 'cloudy':
    default:
      return Icons.cloud;
  }
}
