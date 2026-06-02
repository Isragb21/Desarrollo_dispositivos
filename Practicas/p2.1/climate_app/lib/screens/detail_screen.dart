import 'package:flutter/material.dart';
import '../widgets/weather_icon.dart'; //icono reutilizado

class DetailScreen extends StatelessWidget {
  final String city;

  const DetailScreen({super.key, required this.city});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$city 5 Días'), 
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildForecastCard('Lun', '24°C', 'sunny'),
                  _buildForecastCard('Mar', '26°C', 'sunny'),
                  _buildForecastCard('Mié', '20°C', 'cloudy'),
                  _buildForecastCard('Jue', '25°C', 'cloudy'),
                  _buildForecastCard('Vie', '28°C', 'sunny'),
                ],
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              
              onPressed: () => Navigator.pop(context), 
              child: const Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }

  // Elemento "Card" reutilizable
  Widget _buildForecastCard(String day, String temp, String condition) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(day, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            WeatherIcon(condition: condition, size: 40),
            const SizedBox(height: 12),
            Text(temp, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}