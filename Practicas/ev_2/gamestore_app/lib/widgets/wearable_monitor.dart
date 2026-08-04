import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gamestore_app/providers/wearable_provider.dart';
import 'package:gamestore_app/theme/app_theme.dart';

/// Tarjeta de monitoreo del wearable: muestra en tiempo real las 3 métricas
/// (pasos, ritmo cardíaco, calorías) y dispara una alerta visual cuando el
/// ritmo cardíaco supera el umbral de seguridad.
class WearableMonitor extends StatelessWidget {
  const WearableMonitor({super.key});

  @override
  Widget build(BuildContext context) {
    final wearable = context.watch<WearableProvider>();
    if (!wearable.isConnected) return const SizedBox.shrink();

    final reading = wearable.reading;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neonGreen.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.watch_rounded,
                  size: 16, color: AppColors.neonGreen),
              const SizedBox(width: 6),
              Text("MONITOREO DEL WEARABLE",
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(letterSpacing: 1.5, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _Metric(
                icon: Icons.directions_walk,
                label: 'PASOS',
                value: reading.steps?.toString() ?? '--',
              ),
              const SizedBox(width: 12),
              _Metric(
                icon: Icons.favorite,
                label: 'RITMO',
                value: reading.heartRate == null
                    ? '--'
                    : '${reading.heartRate} BPM',
              ),
              const SizedBox(width: 12),
              _Metric(
                icon: Icons.local_fire_department,
                label: 'CALORÍAS',
                value: reading.calories == null
                    ? '--'
                    : '${reading.calories!.toStringAsFixed(1)} kcal',
              ),
            ],
          ),
          if (wearable.isHeartRateHigh) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 16, color: AppColors.error),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'ALERTA: RITMO CARDÍACO POR ENCIMA DEL UMBRAL',
                      style: TextStyle(
                          color: AppColors.error,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: AppColors.gold),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 9, letterSpacing: 1),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
