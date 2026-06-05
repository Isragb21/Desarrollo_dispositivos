import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'search_screen.dart';
import '../providers/weather_provider.dart';
import '../utils/weather_utils.dart';

// Se cambia a StatefulWidget para poder inicializar la carga de datos al abrir la pantalla
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Carga los datos iniciales al cargar el widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WeatherProvider>(
        context,
        listen: false,
      ).loadWeather('Santiago de Querétaro');
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isLandscape = width > 600;

    return Scaffold(
      appBar: AppBar(title: const Text('Clima Actual'), centerTitle: true),
      // Consumer escucha los cambios del WeatherProvider
      body: Consumer<WeatherProvider>(
        builder: (context, provider, _) {
          // Manejo de estados de carga y error requeridos
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.errorMessage != null) {
            return Center(child: Text('Error: ${provider.errorMessage}'));
          }
          if (provider.weather == null) {
            return const Center(child: Text('Sin datos'));
          }

          return Center(
            child: isLandscape
                ? _buildLandscapeLayout(context, provider)
                : _buildPortraitLayout(context, provider),
          );
        },
      ),
    );
  }

  // Diseño Vertical
  Widget _buildPortraitLayout(BuildContext context, WeatherProvider provider) {
    final weather = provider.weather!;

    // Lógica de conversión de temperatura según la unidad seleccionada
    final displayTemp = provider.temperatureUnit == '°C'
        ? weather.temperature
        : WeatherUtils.celsiusToFahrenheit(weather.temperature).toInt();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$displayTemp${provider.temperatureUnit}',
          style: const TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 16),
        Text(weather.city, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 32),
        // Se utiliza el icono convertido a texto según las utilidades
        Text(
          WeatherUtils.getWeatherIcon(weather.condition),
          style: const TextStyle(fontSize: 120),
        ),
        const SizedBox(height: 32),
        Text('Humedad: ${weather.humidity}% | Viento: 12 km/h'),
        const SizedBox(height: 40),
        _buildSearchButton(context),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            // Reemplaza la funcionalidad de prueba de Riverpod por la de Provider
            provider.loadWeather('Monterrey');
          },
          child: const Text('Actualizar'),
        ),
        const SizedBox(height: 10),
        // Botón agregado para cumplir con el cambio de unidad
        ElevatedButton(
          onPressed: () {
            provider.toggleTemperatureUnit();
          },
          child: const Text('Cambiar unidad (°C / °F)'),
        ),
      ],
    );
  }

  // Diseño Horizontal
  Widget _buildLandscapeLayout(BuildContext context, WeatherProvider provider) {
    final weather = provider.weather!;

    // Lógica de conversión de temperatura
    final displayTemp = provider.temperatureUnit == '°C'
        ? weather.temperature
        : WeatherUtils.celsiusToFahrenheit(weather.temperature).toInt();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$displayTemp${provider.temperatureUnit}',
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
            Text(
              WeatherUtils.getWeatherIcon(weather.condition),
              style: const TextStyle(fontSize: 120),
            ),
            const SizedBox(height: 16),
            Text('Humedad: ${weather.humidity}% | Viento: 12 km/h'),
            const SizedBox(height: 20),
            _buildSearchButton(context),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                provider.loadWeather('Monterrey');
              },
              child: const Text('Probar Cambio de Estado'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                provider.toggleTemperatureUnit();
              },
              child: const Text('Cambiar unidad (°C / °F)'),
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
