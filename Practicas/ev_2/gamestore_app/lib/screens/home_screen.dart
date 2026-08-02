import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gamestore_app/theme/app_theme.dart';
import 'package:gamestore_app/services/api_service.dart';
import 'package:gamestore_app/services/tv_sync.dart';
import 'package:gamestore_app/screens/dashboard_screen.dart';
import 'package:gamestore_app/screens/search_screen.dart';
import 'package:gamestore_app/screens/cart_screen.dart';
import 'package:gamestore_app/screens/profile_screen.dart';
import 'package:gamestore_app/providers/cart_provider.dart';
import 'package:gamestore_app/providers/wearable_provider.dart';
import 'package:gamestore_app/widgets/wearable_status_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  StreamSubscription<Map<String, dynamic>>? _tvSyncSub;

  final _screens = const [
    DashboardScreen(),
    SearchScreen(),
    CartScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = ApiService.userId;
      if (userId != null) {
        context.read<CartProvider>().loadCart();
      }
      _syncWearable();
      _syncTv();
    });
  }

  void _syncWearable() {
    final wearable = context.read<WearableProvider>();
    wearable.connect();

    // Reenvía el total del carrito al wearable cuando cambie.
    context.read<CartProvider>().addListener(_pushCartToWearable);
  }

  void _syncTv() {
    final tvSync = context.read<TvSync>();
    tvSync.open();

    // La TV (BroadcastChannel) informa qué juego seleccionó el usuario.
    _tvSyncSub = tvSync.messages.listen((message) {
      if (message['type'] != 'tv_selection') return;
      final game = message['game'] ?? '';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surface,
          content: Row(
            children: [
              const Icon(Icons.live_tv, color: AppColors.neonGreen, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'TV seleccionó: $game',
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    });

    // Reenvía el total del carrito a la TV cuando cambie.
    context.read<CartProvider>().addListener(_pushCartToTv);
  }

  void _pushCartToWearable() {
    final cart = context.read<CartProvider>();
    context.read<WearableProvider>().sendCart(
          total: cart.total,
          count: cart.count,
        );
  }

  void _pushCartToTv() {
    final cart = context.read<CartProvider>();
    context.read<TvSync>().broadcast('cart', {
      'total': cart.total,
      'count': cart.count,
    });
  }

  @override
  void dispose() {
    _tvSyncSub?.cancel();
    context.read<CartProvider>().removeListener(_pushCartToWearable);
    context.read<CartProvider>().removeListener(_pushCartToTv);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const WearableStatusBar(),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.neonGreen, width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: [
            _buildNavItem(Icons.home_rounded, "INICIO", 0),
            _buildNavItem(Icons.search_rounded, "BUSCAR", 1),
            _buildNavItem(Icons.shopping_cart_outlined, "CARRITO", 2),
            _buildNavItem(Icons.person_outline, "PERFIL", 3),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    return BottomNavigationBarItem(
      icon: Icon(icon, color: AppColors.textSecondary),
      activeIcon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.neonGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.neonGreen),
      ),
      label: label,
      backgroundColor: isSelected
          ? AppColors.neonGreen.withValues(alpha: 0.1)
          : null,
    );
  }
}
