import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'search_screen.dart';
import '../providers/weather_provider.dart';
import '../utils/weather_utils.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WeatherProvider>(context, listen: false)
          .fetchWeather('Queretaro');
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showBLEModal(BuildContext context, WeatherProvider provider) {
    bool scanStarted = false;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final scaffoldMessenger = ScaffoldMessenger.of(context);
            if (!scanStarted) {
              scanStarted = true;
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                try {
                  await provider.bleService.startScan();
                  if (mounted) setModalState(() {});
                } catch (e) {
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          'No se pudo iniciar el escaneo Bluetooth: $e',
                        ),
                      ),
                    );
                  }
                }
              });
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      provider.bleService.stopScan();
                      await provider.bleService.startScan();
                      setModalState(() {});
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Escanear / Reiniciar'),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<ScanResult>>(
                    stream: provider.bleService.scanForDevices(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text('Error Bluetooth: ${snapshot.error}'),
                        );
                      }

                      final results = snapshot.data ?? [];
                      if (results.isEmpty) {
                        return const Center(
                          child: Text(
                            'No se encontraron dispositivos todavía. Asegura que Bluetooth esté activado y que el dispositivo sea visible.',
                            textAlign: TextAlign.center,
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: results.length,
                        itemBuilder: (context, index) {
                          final scanResult = results[index];
                          final device = scanResult.device;
                          final advName = scanResult.advertisementData.advName
                              .trim();
                          final platformName = device.platformName.trim();
                          final fallbackName =
                              device.advName.trim().isNotEmpty
                                  ? device.advName.trim()
                                  : platformName.isNotEmpty
                                      ? platformName
                                      : null;
                          final deviceName =
                              fallbackName ??
                              'Dispositivo ${device.remoteId.str}';

                          return ListTile(
                            leading: const Icon(Icons.bluetooth),
                            title: Text(deviceName),
                            subtitle: Text(
                              advName.isNotEmpty
                                  ? '${device.remoteId.str} · RSSI ${scanResult.rssi} dBm'
                                  : 'Dirección: ${device.remoteId.str} · RSSI ${scanResult.rssi} dBm',
                            ),
                            onTap: () async {
                              final navigator = Navigator.of(context);
                              final messenger =
                                  ScaffoldMessenger.of(context);

                              navigator.pop();

                              messenger.showSnackBar(
                                const SnackBar(
                                    content: Text('Conectando...')),
                              );

                              try {
                                await provider.bleService.connect(device);

                                final bleError =
                                    await provider.loadWeatherFromBLE(device);

                                if (!mounted) return;

                                if (bleError == null) {
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        '✅ ¡Conectado y datos recibidos con éxito!',
                                      ),
                                      backgroundColor: Colors.green,
                                      duration: Duration(seconds: 3),
                                    ),
                                  );
                                } else {
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text('❌ Error: $bleError'),
                                      backgroundColor: Colors.red,
                                      duration: const Duration(seconds: 4),
                                    ),
                                  );
                                }

                                provider.bleService
                                    .getConnectionState(device)
                                    .listen((state) {
                                      if (!mounted) return;
                                      if (state ==
                                          BluetoothConnectionState
                                              .disconnected) {
                                        messenger.showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              '⚠️ Sin conexión Bluetooth',
                                            ),
                                            backgroundColor: Colors.orange,
                                          ),
                                        );
                                      }
                                    });
                              } catch (e) {
                                if (!mounted) return;
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text('❌ Error al conectar: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(() {
      scanStarted = false;
      provider.bleService.stopScan();
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isLandscape = width > 600;

    return Scaffold(
      appBar: AppBar(title: const Text('Clima Actual'), centerTitle: true),
      body: Consumer<WeatherProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Buscar ciudad',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () {
                        final city = _searchController.text.trim();
                        if (city.isNotEmpty) {
                          provider.fetchWeather(city);
                        }
                      },
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  onSubmitted: (value) {
                    final city = value.trim();
                    if (city.isNotEmpty) {
                      provider.fetchWeather(city);
                    }
                  },
                ),
              ),
              Expanded(
                child: _buildBody(provider, isLandscape),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(WeatherProvider provider, bool isLandscape) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              provider.errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                provider.fetchWeather('Queretaro');
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (provider.weather == null) {
      return const Center(child: Text('Busca una ciudad para ver el clima'));
    }

    return isLandscape
        ? _buildLandscapeLayout(context, provider)
        : _buildPortraitLayout(context, provider);
  }

  Widget _buildPortraitLayout(BuildContext context, WeatherProvider provider) {
    final weather = provider.weather!;
    final displayTemp = provider.temperatureUnit == '°C'
        ? weather.temperature
        : WeatherUtils.celsiusToFahrenheit(weather.temperature).toInt();

    return ListView(
      children: [
        const SizedBox(height: 32),
        Text(
          '$displayTemp${provider.temperatureUnit}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          weather.description,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        Text(
          weather.city,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(height: 32),
        Text(
          WeatherUtils.getWeatherIcon(weather.condition),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 120),
        ),
        const SizedBox(height: 32),
        Text(
          'Humedad: ${weather.humidity}% | Viento: ${weather.windSpeed} m/s',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 40),
        Center(
          child: Column(
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final enabled =
                      await provider.bleService.ensureBluetoothEnabled();
                  if (!mounted) return;
                  if (!enabled) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Activa Bluetooth para buscar dispositivos',
                        ),
                      ),
                    );
                    return;
                  }
                  _showBLEModal(context, provider);
                },
                icon: const Icon(Icons.bluetooth_searching),
                label: const Text('Buscar dispositivos'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SearchScreen(),
                    ),
                  );
                },
                child: const Text('Buscar Ciudades'),
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
        ),
      ],
    );
  }

  Widget _buildLandscapeLayout(
      BuildContext context, WeatherProvider provider) {
    final weather = provider.weather!;
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
            const SizedBox(height: 8),
            Text(
              weather.description,
              style: const TextStyle(fontSize: 18, color: Colors.grey),
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
            Text(
              'Humedad: ${weather.humidity}% | Viento: ${weather.windSpeed} m/s',
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final enabled =
                    await provider.bleService.ensureBluetoothEnabled();
                if (!mounted) return;
                if (!enabled) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Activa Bluetooth para buscar dispositivos',
                      ),
                    ),
                  );
                  return;
                }
                _showBLEModal(context, provider);
              },
              icon: const Icon(Icons.bluetooth_searching),
              label: const Text('Buscar dispositivos'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SearchScreen(),
                  ),
                );
              },
              child: const Text('Buscar Ciudades'),
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
}
