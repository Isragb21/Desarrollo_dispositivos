import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/weather.dart';

// Creamos la clase que administrará el estado del clima
class WeatherNotifier extends StateNotifier<Weather> {
  // Estado inicial por defecto
  WeatherNotifier()
    : super(
        Weather(
          city: 'Santiago de Querétaro',
          temp: 24.0,
          condition: 'cloudy',
          unit: 'C',
        ),
      );

  // Función para actualizar los datos desde la UI
  void updateWeather(String newCity, double newTemp, String newCondition) {
    // Al asignar un nuevo 'state', Riverpod avisa a la pantalla que debe actualizarse.
    // Además, las validaciones de seguridad que pusiste en tu modelo se ejecutan solas aquí.
    state = Weather(
      city: newCity,
      temp: newTemp,
      condition: newCondition,
      unit: state.unit,
    );
  }
}

// Creamos el Provider global para poder leerlo desde cualquier pantalla
final weatherProvider = StateNotifierProvider<WeatherNotifier, Weather>((ref) {
  return WeatherNotifier();
});
