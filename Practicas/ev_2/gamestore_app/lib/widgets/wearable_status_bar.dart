import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gamestore_app/providers/wearable_provider.dart';
import 'package:gamestore_app/theme/app_theme.dart';

class WearableStatusBar extends StatelessWidget {
  const WearableStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    final wearable = context.watch<WearableProvider>();

    final (label, color, icon) = switch (wearable.status) {
      WearableConnectionStatus.searching =>
        ('BUSCANDO WEARABLE...', AppColors.gold, Icons.bluetooth_searching),
      WearableConnectionStatus.connected =>
        ('WEARABLE CONECTADO', AppColors.neonGreen, Icons.watch),
      WearableConnectionStatus.error =>
        ('ERROR BLE', AppColors.error, Icons.error_outline),
      WearableConnectionStatus.disconnected =>
        ('WEARABLE DESCONECTADO', AppColors.textSecondary, Icons.watch_off),
    };

    return Material(
      color: AppColors.surface,
      child: InkWell(
        onTap: wearable.status == WearableConnectionStatus.connected
            ? null
            : () => context.read<WearableProvider>().connect(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              if (wearable.status == WearableConnectionStatus.disconnected)
                Text(
                  'TOCA PARA CONECTAR',
                  style: TextStyle(color: AppColors.gold, fontSize: 10),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
