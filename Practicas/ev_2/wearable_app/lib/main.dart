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
      builder: (context, child) {
        return DefaultTextStyle(
          style: const TextStyle(
            color: Color(0xFFF8FAFC),
            decoration: TextDecoration.none,
            decorationColor: Colors.transparent,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0E14),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF22C55E),
          surface: Color(0xFF1A1F2B),
          error: Color(0xFFEF4444),
        ),
        textTheme: ThemeData(brightness: Brightness.dark).textTheme.apply(
          bodyColor: const Color(0xFFF8FAFC),
          displayColor: const Color(0xFFF8FAFC),
          decoration: TextDecoration.none,
          decorationColor: Colors.transparent,
        ),
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
    // Pide permisos de Bluetooth al iniciar (el wearable queda bloqueado hasta
    // que el teléfono lo vincule por BLE).
    ble.requestPermissions();
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
    final vm = context.watch<WearableViewModel>();
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 64, 16, 56),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: !vm.paired
                ? const PairLockScreen(key: ValueKey('lock'))
                : switch (vm.screen) {
                    WearableScreen.dashboard => const HomeDashboardScreen(
                      key: ValueKey('dashboard'),
                    ),
                    WearableScreen.cart => const CartTotalScreen(
                      key: ValueKey('cart'),
                    ),
                    WearableScreen.session => const SessionAlertScreen(
                      key: ValueKey('session'),
                    ),
                    WearableScreen.discount => const DiscountAlertScreen(
                      key: ValueKey('discount'),
                    ),
                    WearableScreen.favorites => const FavoritesScreen(
                      key: ValueKey('favorites'),
                    ),
                    WearableScreen.success => const PurchaseSuccessScreen(
                      key: ValueKey('success'),
                    ),
                  },
          ),
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

/// Pantalla inicial: solo muestra el botón de emparejar. La app se desbloquea
/// cuando el teléfono envía "pair" vía BLE (o el puente por red).
class PairLockScreen extends StatelessWidget {
  const PairLockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<WearableViewModel>();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (vm.pairing) ...[
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Color(0xFF22C55E),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Esperando al teléfono...',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
          ),
        ] else
          _ActionButton(
            icon: Icons.sports_esports,
            label: 'EMPAREJAR',
            color: const Color(0xFF22C55E),
            onTap: () => vm.beginPairing(),
          ),
      ],
    );
  }
}

/// Inicio del wearable ya vinculado: carrito, juegos obtenidos y aviso de
/// ofertas / verificación 2FA (sin monitoreo de signos vitales).
class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<WearableViewModel>();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.sports_esports,
                color: Color(0xFF22C55E),
                size: 20,
              ),
              const SizedBox(width: 6),
              const Text(
                'GAMESTORE',
                style: TextStyle(
                  color: Color(0xFFF8FAFC),
                  fontSize: 16,
                  letterSpacing: 3,
                  fontWeight: FontWeight.w800,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
        const Text(
          'WEAR',
          style: TextStyle(
            color: Color(0xFF22C55E),
            fontSize: 12,
            letterSpacing: 3,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.none,
          ),
        ),
        const SizedBox(height: 14),
        _DashboardTile(
          icon: Icons.shopping_cart_outlined,
          label: 'CARRITO',
          value: '\$${vm.cartTotal.toStringAsFixed(2)}',
          hint: '${vm.cartCount} artículo(s)',
          onTap: () => vm.showCart(),
        ),
        const SizedBox(height: 6),
        _DashboardTile(
          icon: Icons.videogame_asset_outlined,
          label: 'JUEGOS OBTENIDOS',
          value: '${vm.ownedGames}',
          hint: 'en tu biblioteca',
        ),
        const SizedBox(height: 6),
        _DashboardTile(
          icon: Icons.favorite_outline,
          label: 'FAVORITOS',
          value: '${vm.favorites.length}',
          hint: vm.favorites.isEmpty
              ? 'juegos en tu wishlist'
              : vm.favorites.first,
          onTap: () => vm.showFavorites(),
        ),
      ],
    );
  }
}

class _DashboardTile extends StatelessWidget {
  const _DashboardTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.hint,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final String hint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tile = Container(
      width: 160,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF151A24),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF22C55E).withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF22C55E)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFF8FAFC),
              fontSize: 20,
              fontWeight: FontWeight.w800,
              decoration: TextDecoration.none,
            ),
          ),
          Text(
            hint,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 10,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return tile;
    return GestureDetector(onTap: onTap, child: tile);
  }
}

class CartTotalScreen extends StatelessWidget {
  const CartTotalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<WearableViewModel>();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'CARRITO',
          style: TextStyle(
            color: Color(0xFF22C55E),
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
            decoration: TextDecoration.none,
          ),
        ),
        Text(
          '${vm.cartCount} artículo(s)',
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
        ),
        if (vm.cartGames.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            width: 180,
            height: 130,
            decoration: BoxDecoration(
              color: const Color(0xFF151A24),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFF22C55E).withValues(alpha: 0.3),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: ListView.separated(
              itemCount: vm.cartGames.length,
              separatorBuilder: (_, _) => const SizedBox(height: 6),
              itemBuilder: (context, index) => Row(
                children: [
                  const Icon(
                    Icons.videogame_asset,
                    size: 12,
                    color: Color(0xFF22C55E),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      vm.cartGames[index],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFF8FAFC),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          const SizedBox(height: 8),
          const Text(
            'Carrito vacío',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
          ),
        ],
        const SizedBox(height: 12),
        _ActionButton(
          icon: Icons.arrow_back,
          label: 'VOLVER',
          color: const Color(0xFF94A3B8),
          onTap: () => vm.backToDashboard(),
        ),
      ],
    );
  }
}

/// Favoritos de la cuenta: lista de juegos de la wishlist del usuario.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<WearableViewModel>();
    final favorites = vm.favorites;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'FAVORITOS',
          style: TextStyle(
            color: Color(0xFF22C55E),
            fontSize: 13,
            letterSpacing: 3,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${favorites.length} juego(s) en tu wishlist',
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
        ),
        const SizedBox(height: 10),
        if (favorites.isEmpty)
          const Text(
            'No tienes favoritos todavía',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
          )
        else
          Container(
            width: 170,
            height: 150,
            decoration: BoxDecoration(
              color: const Color(0xFF151A24),
              borderRadius: BorderRadius.circular(18),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: ListView.separated(
              itemCount: favorites.length,
              separatorBuilder: (_, _) => const SizedBox(height: 6),
              itemBuilder: (context, index) => Row(
                children: [
                  const Icon(
                    Icons.favorite,
                    size: 12,
                    color: Color(0xFFEF4444),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      favorites[index],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFF8FAFC),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 10),
        _ActionButton(
          icon: Icons.arrow_back,
          label: 'VOLVER',
          color: const Color(0xFF94A3B8),
          onTap: () => vm.backToDashboard(),
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
          onTap: () {
            ble.sendUserResponse('approve');
            vm.backToDashboard();
          },
        ),
        const SizedBox(height: 8),
        _ActionButton(
          icon: Icons.close,
          label: 'RECHAZAR',
          color: const Color(0xFFEF4444),
          onTap: () {
            ble.sendUserResponse('reject');
            vm.backToDashboard();
          },
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
            decoration: TextDecoration.none,
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
          color: const Color(0xFF22C55E),
          onTap: () => vm.backToDashboard(),
        ),
      ],
    );
  }
}

class DiscountAlertScreen extends StatelessWidget {
  const DiscountAlertScreen({super.key});

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
            color: Color(0xFF22C55E),
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
          onTap: () {
            ble.sendUserResponse('open', payload: vm.discountGame);
            vm.backToDashboard();
          },
        ),
        const SizedBox(height: 8),
        _ActionButton(
          icon: Icons.close,
          label: 'DESCARTAR',
          color: const Color(0xFFEF4444),
          onTap: () {
            ble.sendUserResponse('dismiss', payload: vm.discountGame);
            vm.backToDashboard();
          },
        ),
      ],
    );
  }
}
