import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/activity_data.dart';
import '../providers/activity_provider.dart';
import '../services/ble_client.dart';
import '../widgets/metric_card.dart';

class MonitorScreen extends StatelessWidget {
  const MonitorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ActivityProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Monitor de Actividad'),
            centerTitle: true,
            actions: [
              if (provider.connectionState == BLEConnectionState.connected)
                IconButton(
                  icon: const Icon(Icons.bluetooth_connected),
                  onPressed: () => provider.disconnect(),
                  tooltip: 'Desconectar',
                ),
            ],
          ),
          body: _buildBody(context, provider),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, ActivityProvider provider) {
    switch (provider.connectionState) {
      case BLEConnectionState.scanning:
      case BLEConnectionState.connecting:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Buscando wearable...'),
            ],
          ),
        );

      case BLEConnectionState.error:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                provider.errorMessage ?? 'Error de conexión',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => provider.startScan(),
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        );

      case BLEConnectionState.disconnected:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.bluetooth_searching, size: 64, color: Colors.blue),
              const SizedBox(height: 16),
              const Text('Conéctate a tu wearable', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => provider.startScan(),
                icon: const Icon(Icons.search),
                label: const Text('Buscar wearable'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
            ],
          ),
        );

      case BLEConnectionState.connected:
        return _buildDashboard(context, provider.activityData);
    }

  }

  Widget _buildDashboard(BuildContext context, ActivityData data) {
    final isHighHR = data.heartRate > 120;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (isHighHR)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.red.shade900,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.white),
                  SizedBox(width: 8),
                  Text('¡Frecuencia cardíaca alta!',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.blue.shade900,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info, color: Colors.white),
                const SizedBox(width: 8),
                Text('Estado: ${data.status.toUpperCase()}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                MetricCard(
                  icon: Icons.directions_walk,
                  label: 'Pasos',
                  value: '${data.steps}',
                  unit: 'pasos',
                  color: Colors.green,
                ),
                MetricCard(
                  icon: Icons.favorite,
                  label: 'Ritmo Cardíaco',
                  value: '${data.heartRate}',
                  unit: 'BPM',
                  color: data.heartRateColor,
                ),
                MetricCard(
                  icon: Icons.local_fire_department,
                  label: 'Calorías',
                  value: '${data.calories}',
                  unit: 'kcal',
                  color: Colors.orange,
                ),
                MetricCard(
                  icon: Icons.monitor_heart,
                  label: 'Zona',
                  value: data.heartRateZone,
                  unit: '',
                  color: data.heartRateColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
