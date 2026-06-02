import 'package:flutter/material.dart';
import 'search_screen.dart';
import '../widgets/weather_icon.dart'; // Importamos tu componente reutilizable

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Aquí implementamos el requerimiento responsivo que pedía la rúbrica
    final width = MediaQuery.of(context).size.width;
    final isLandscape = width > 600; // Si es mayor a 600, está en horizontal

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clima Actual'),
        centerTitle: true,
      ),
      body: Center(
        // Cambia entre Row y Column dependiendo de cómo esté el celular
        child: isLandscape 
            ? _buildLandscapeLayout(context) 
            : _buildPortraitLayout(context),
      ),
    );
  }

  // Diseño Vertical (Celular normal / Portrait)
  Widget _buildPortraitLayout(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('24°C', style: TextStyle(fontSize: 72, fontWeight: FontWeight.bold, color: Colors.blue)),
        const SizedBox(height: 16),
        const Text('Santiago de Querétaro', style: TextStyle(fontSize: 24)),
        const SizedBox(height: 32),
        const WeatherIcon(condition: 'cloudy', size: 120), // Usando tu widget
        const SizedBox(height: 32),
        const Text('Humedad: 65% | Viento: 12 km/h'),
        const SizedBox(height: 40),
        _buildSearchButton(context),
      ],
    );
  }

  // Diseño Horizontal (Celular acostado / Landscape)
  Widget _buildLandscapeLayout(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('24°C', style: TextStyle(fontSize: 72, fontWeight: FontWeight.bold, color: Colors.blue)),
            SizedBox(height: 16),
            Text('Santiago de Querétaro', style: TextStyle(fontSize: 24)),
          ],
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const WeatherIcon(condition: 'cloudy', size: 120),
            const SizedBox(height: 16),
            const Text('Humedad: 65% | Viento: 12 km/h'),
            const SizedBox(height: 20),
            _buildSearchButton(context),
          ],
        ),
      ],
    );
  }

  // El botón con la navegación (Navigator.push) que pide la tarea
  Widget _buildSearchButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SearchScreen()),
        );
      },
      child: const Text('Buscar Ciudades'),
    );
  }
}