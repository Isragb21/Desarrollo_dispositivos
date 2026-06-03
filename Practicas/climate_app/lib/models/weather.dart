class Weather {
  final String city;
  final double temp;
  final String condition;
  final String unit;

  Weather({
    required this.city,
    required this.temp,
    required this.condition,
    required this.unit,
  }) {
    // Criterio de seguridad obligatorio
    if (city.trim().isEmpty) {
      throw ArgumentError('La ciudad no puede ser un texto vacío.');
    }
    if (temp < -60 || temp > 60) {
      throw ArgumentError('La temperatura debe estar entre -60°C y 60°C.');
    }
  }
}
