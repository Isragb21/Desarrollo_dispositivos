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
  StreamSubscription<Map<String, dynamic>>? _approvalSub;
  Timer? _twoFaTimer;
  String? _pendingEmail;
  bool _dialogShowing = false;

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
      _startTwoFaHub();
    });
  }

  /// Hub de verificación 2FA: si la TV pide iniciar sesión (pending), la
  /// confirmación va al wearable cuando hay conexión BLE activa; si no, se
  /// muestra directamente en el móvil.
  void _startTwoFaHub() {
    final wearable = context.read<WearableProvider>();
    _approvalSub = wearable.approvalStream.listen((response) {
      final email = _pendingEmail;
      if (email == null) return;
      final type = response['type'] as String? ?? '';
      if (type == 'approve' || type == 'reject') {
        ApiService.confirm2fa(email, type == 'approve' ? 'confirmed' : 'rejected');
        _pendingEmail = null;
      }
    });
    _twoFaTimer = Timer.periodic(const Duration(seconds: 3), (_) => _pollTwoFa());
  }

  Future<void> _pollTwoFa() async {
    final email = ApiService.currentUser?.email;
    if (email == null) return;
    final status = await ApiService.check2fa(email);
    if (!mounted) return;
    if (status == 'pending' && _pendingEmail == null) {
      _pendingEmail = email;
      final wearable = context.read<WearableProvider>();
      if (wearable.isConnected) {
        wearable.sendSessionAlert(email);
        _showSnack(
          'Inicio de sesión en TV: confirma en tu wearable',
          Icons.watch_rounded,
        );
      } else {
        _showTwoFaDialog(email);
      }
    } else if (status == 'confirmed' || status == 'rejected') {
      if (_pendingEmail != null) {
        _pendingEmail = null;
        _showSnack(
          status == 'confirmed'
              ? 'Inicio de sesión aprobado'
              : 'Inicio de sesión rechazado',
          status == 'confirmed' ? Icons.check_circle : Icons.cancel,
        );
      }
    }
  }

  Future<void> _showTwoFaDialog(String email) async {
    if (_dialogShowing) return;
    _dialogShowing = true;
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          "Inicio de sesión detectado",
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: Text(
          "¿Confirmas el inicio de sesión de $email en GameStore TV?",
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("RECHAZAR", style: TextStyle(color: AppColors.error)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text("APROBAR"),
          ),
        ],
      ),
    );
    _dialogShowing = false;
    if (approved == null) return;
    await ApiService.confirm2fa(email, approved ? 'confirmed' : 'rejected');
    _pendingEmail = null;
  }

  void _showSnack(String message, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surface,
        content: Row(
          children: [
            Icon(icon, color: AppColors.neonGreen, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
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
    _twoFaTimer?.cancel();
    _approvalSub?.cancel();
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
