class Weather {
  final String city;
  final int temperature;
  final String condition;
  final String description;
  final int humidity;
  final double windSpeed;

  Weather({
    required this.city,
    required this.temperature,
    required this.condition,
    required this.description,
    required this.humidity,
    required this.windSpeed,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('main') || !json.containsKey('weather')) {
      throw const FormatException('Missing main or weather field in weather data');
    }

    final mainData = json['main'] as Map<String, dynamic>;
    final weatherList = json['weather'] as List<dynamic>;

    final temp = mainData['temp'];
    if (temp is! num) {
      throw const FormatException('Temperature must be a number');
    }

    final weatherItem = weatherList.isNotEmpty
        ? weatherList[0] as Map<String, dynamic>
        : <String, dynamic>{};

    return Weather(
      city: json['name'] as String? ?? 'Unknown',
      temperature: temp.toInt(),
      condition: weatherItem['main'] as String? ?? 'unknown',
      description: weatherItem['description'] as String? ?? '',
      humidity: mainData['humidity'] as int? ?? 0,
      windSpeed: (json['wind'] as Map<String, dynamic>?)?['speed']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'city': city,
    'temperature': temperature,
    'condition': condition,
    'description': description,
    'humidity': humidity,
    'windSpeed': windSpeed,
  };

  @override
  String toString() {
    return 'Weather(city: $city, temp: $temperature°C, condition: $condition, '
        'description: $description, humidity: $humidity%, windSpeed: $windSpeed m/s)';
  }
}
