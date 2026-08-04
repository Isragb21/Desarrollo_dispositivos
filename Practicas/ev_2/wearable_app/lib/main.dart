import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'ble_server.dart';
import 'wearable_view_model.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WearableViewModel()),
        Provider<BleServer>(create: (_) => BleServer()),
      ],
      child: const WearableApp(),
    ),
  );
}

class WearableApp extends StatelessWidget {
  const WearableApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GameStore Wear',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0E14),
        useMaterial3: true,
      ),
      home: const WearableHome(),
    );
  }
}

class WearableHome extends StatefulWidget {
  const WearableHome({super.key});

  @override
  State<WearableHome> createState() => _WearableHomeState();
}

class _WearableHomeState extends State<WearableHome> {
  StreamSubscription? _sub;
  BleServer? _ble;

  @override
  void initState() {
    super.initState();
    final vm = context.read<WearableViewModel>();
    final ble = context.read<BleServer>();
    _ble = ble;
    vm.attachBle(ble);
    _sub = ble.events.listen(vm.handleEvent);
    ble.start();
  }
  @override
  void dispose() {
    _sub?.cancel();
    _ble?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screen = context.watch<WearableViewModel>().screen;
    return SafeArea(
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: switch (screen) {
            WearableScreen.dashboard =>
              const SensorDashboardScreen(key: ValueKey('dashboard')),
            WearableScreen.cart => const CartTotalScreen(key: ValueKey('cart')),
            WearableScreen.session =>
              const SessionAlertScreen(key: ValueKey('session')),
            WearableScreen.discount =>
              const DiscountAlertScreen(key: ValueKey('discount')),
            WearableScreen.success =>
              const PurchaseSuccessScreen(key: ValueKey('success')),
          },
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Container(
          width: 120,
          height: 48,
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: Colors.black),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SensorDashboardScreen extends StatelessWidget {
  const SensorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<WearableViewModel>();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'MONITOR',
          style: TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 12,
            letterSpacing: 3,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        _MetricTile(
          icon: Icons.directions_walk,
          label: 'PASOS',
          value: '${vm.steps}',
        ),
        const SizedBox(height: 6),
        _MetricTile(
          icon: Icons.favorite,
          label: 'RITMO',
          value: '${vm.heartRate} BPM',
        ),
        const SizedBox(height: 6),
        _MetricTile(
          icon: Icons.local_fire_department,
          label: 'CALORÍAS',
          value: '${vm.calories.toStringAsFixed(1)} kcal',
        ),
        const SizedBox(height: 10),
        _ActionButton(
          icon: vm.sensorsRunning ? Icons.stop : Icons.play_arrow,
          label: vm.sensorsRunning ? 'DETENER' : 'INICIAR',
          color: vm.sensorsRunning
              ? const Color(0xFFEF4444)
              : const Color(0xFF22C55E),
          onTap: () => vm.toggleSensors(),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 156,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF151A24),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF3B82F6)),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFF8FAFC),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CartTotalScreen extends StatelessWidget {
  const CartTotalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<WearableViewModel>();
    final ble = context.read<BleServer>();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'CARRITO',
          style: TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 13,
            letterSpacing: 3,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '\$${vm.cartTotal.toStringAsFixed(2)}',
          style: const TextStyle(
            color: Color(0xFFF8FAFC),
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          '${vm.cartCount} artículos',
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
        ),
        const SizedBox(height: 12),
        _ActionButton(
          icon: Icons.shopping_cart_outlined,
          label: 'PAGAR',
          color: const Color(0xFF22C55E),
          onTap: () => ble.sendUserResponse('pay'),
        ),
      ],
    );
  }
}

class SessionAlertScreen extends StatelessWidget {
  const SessionAlertScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<WearableViewModel>();
    final ble = context.read<BleServer>();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'INICIO DE SESIÓN DETECTADO',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFFF8FAFC),
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (vm.sessionUser.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            vm.sessionUser,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
          ),
        ],
        const SizedBox(height: 10),
        _ActionButton(
          icon: Icons.check,
          label: 'APROBAR',
          color: const Color(0xFF22C55E),
          onTap: () => ble.sendUserResponse('approve'),
        ),
        const SizedBox(height: 8),
        _ActionButton(
          icon: Icons.close,
          label: 'RECHAZAR',
          color: const Color(0xFFEF4444),
          onTap: () => ble.sendUserResponse('reject'),
        ),
      ],
    );
  }
}

class PurchaseSuccessScreen extends StatelessWidget {
  const PurchaseSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<WearableViewModel>();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            color: Color(0xFF22C55E),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, size: 34, color: Colors.black),
        ),
        const SizedBox(height: 8),
        const Text(
          'COMPRA EXITOSA',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF22C55E),
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '\$${vm.purchaseTotal.toStringAsFixed(2)}',
          style: const TextStyle(
            color: Color(0xFFF8FAFC),
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          '${vm.purchaseGames} juego(s) adquirido(s)',
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
        ),
        const SizedBox(height: 12),
        _ActionButton(
          icon: Icons.home,
          label: 'INICIO',
          color: const Color(0xFF3B82F6),
          onTap: () => vm.backToDashboard(),
        ),
      ],
    );
  }
}

class DiscountAlertScreen extends StatelessWidget {  const DiscountAlertScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<WearableViewModel>();
    final ble = context.read<BleServer>();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'WISHLIST ALERT',
          style: TextStyle(
            color: Color(0xFF3B82F6),
            fontSize: 13,
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '-${vm.discountPercent}%',
          style: const TextStyle(
            color: Color(0xFF22C55E),
            fontSize: 30,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          vm.discountGame.isEmpty ? 'JUEGO' : vm.discountGame.toUpperCase(),
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFFF8FAFC), fontSize: 12),
        ),
        const SizedBox(height: 8),
        _ActionButton(
          icon: Icons.storefront,
          label: 'VER',
          color: const Color(0xFF22C55E),
          onTap: () => ble.sendUserResponse('open'),
        ),
      ],
    );
  }
}
