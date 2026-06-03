import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'search_screen.dart';
import '../providers/weater_provider.dart';
import '../utils/weather_utils.dart';

// Se cambia StatelessWidget por ConsumerWidget para leer el estado
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Se lee el estado actual del provider
    final weather = ref.watch(weatherProvider);

    final width = MediaQuery.of(context).size.width;
    final isLandscape = width > 600;

    return Scaffold(
      appBar: AppBar(title: const Text('Clima Actual'), centerTitle: true),
      body: Center(
        child: isLandscape
            ? _buildLandscapeLayout(context, weather, ref)
            : _buildPortraitLayout(context, weather, ref),
      ),
    );
  }

  // Diseño Vertical
  Widget _buildPortraitLayout(BuildContext context, weather, WidgetRef ref) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Se usan las funciones puras y los datos del estado
        Text(
          formatTemperature(weather.temp, weather.unit),
          style: const TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 16),
        Text(weather.city, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 32),
        Icon(getWeatherIcon(weather.condition), size: 120, color: Colors.blue),
        const SizedBox(height: 32),
        const Text('Humedad: 65% | Viento: 12 km/h'),
        const SizedBox(height: 40),
        _buildSearchButton(context),
        const SizedBox(height: 20),
        // Botón de prueba para actualizar el estado
        ElevatedButton(
          onPressed: () {
            ref
                .read(weatherProvider.notifier)
                .updateWeather('Monterrey', 35.0, 'sunny');
          },
          child: const Text('Actualizar'),
        ),
      ],
    );
  }

  // Diseño Horizontal
  Widget _buildLandscapeLayout(BuildContext context, weather, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              formatTemperature(weather.temp, weather.unit),
              style: const TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            Text(weather.city, style: const TextStyle(fontSize: 24)),
          ],
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              getWeatherIcon(weather.condition),
              size: 120,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            const Text('Humedad: 65% | Viento: 12 km/h'),
            const SizedBox(height: 20),
            _buildSearchButton(context),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                ref
                    .read(weatherProvider.notifier)
                    .updateWeather('Monterrey', 35.0, 'sunny');
              },
              child: const Text('Probar Cambio de Estado'),
            ),
          ],
        ),
      ],
    );
  }

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
