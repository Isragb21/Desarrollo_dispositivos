import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gamestore_app/theme/app_theme.dart';
import 'package:gamestore_app/providers/cart_provider.dart';
import 'package:gamestore_app/models/game.dart';
import 'package:gamestore_app/services/api_service.dart';
import 'package:gamestore_app/screens/game_detail_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<CartProvider>(
          builder: (context, cart, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "CARRITO",
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.neonGreen,
                          letterSpacing: 3,
                        ),
                      ),
                      if (!cart.isEmpty)
                        TextButton.icon(
                          onPressed: () async { await cart.clear(); },
                          icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                          label: const Text(
                            "VACÍAR",
                            style: TextStyle(color: AppColors.error, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
                if (cart.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_cart_outlined,
                              size: 64, color: AppColors.textSecondary),
                          SizedBox(height: 16),
                          Text(
                            "CARRITO VACÍO",
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 18,
                              letterSpacing: 2,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Agrega juegos desde el catálogo",
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => cart.loadCart(),
                      child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: cart.items.length,
                      itemBuilder: (context, index) {
                        final entry = cart.items.entries.elementAt(index);
                        return _buildCartItem(context, entry.value, cart);
                      },
                    ),
                    ),
                  ),
                if (!cart.isEmpty)
                  _buildCheckoutSection(context, cart),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCartItem(BuildContext context, Game game, CartProvider cart) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => GameDetailScreen(game: game)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.neonGreen.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  ApiService.imageUrl(game.imageUrl),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Icon(Icons.videogame_asset,
                      color: AppColors.neonGreen.withValues(alpha: 0.4), size: 28),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(game.title,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  Text(game.genre,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "\$${(game.isOnSale ? game.salePrice! : game.price).toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: AppColors.neonGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline,
                      color: AppColors.error, size: 20),
                  onPressed: () async { await cart.remove(game.id); },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutSection(BuildContext context, CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.neonGreen, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("TOTAL", style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
                Text(
                  "\$${cart.total.toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: AppColors.neonGreen,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _simularPago(context, cart),
            icon: const Icon(Icons.shopping_cart_checkout),
            label: const Text("PAGAR"),
          ),
        ],
      ),
    );
  }

  Future<void> _simularPago(BuildContext context, CartProvider cart) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text("CONFIRMAR PAGO",
            style: TextStyle(color: AppColors.neonGreen)),
        content: Text(
          "Total a pagar: \$${cart.total.toStringAsFixed(2)} MXN\n\n"
          "¿Deseas simular el pago?",
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("CANCELAR",
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("PAGAR"),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.neonGreen),
      ),
    );

    final result = await ApiService.simulatePayment();

    if (!context.mounted) return;
    Navigator.pop(context);

    if (result != null) {
      await cart.loadCart();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Pago exitoso: ${result['juegos_adquiridos']} juego(s) adquirido(s)"),
          backgroundColor: AppColors.neonGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ApiService.lastError ?? "Error al procesar pago"),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
