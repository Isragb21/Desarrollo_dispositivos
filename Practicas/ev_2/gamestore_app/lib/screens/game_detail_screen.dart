import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gamestore_app/theme/app_theme.dart';
import 'package:gamestore_app/models/game.dart';
import 'package:gamestore_app/providers/cart_provider.dart';
import 'package:gamestore_app/providers/wishlist_provider.dart';
import 'package:gamestore_app/services/api_service.dart';

class GameDetailScreen extends StatelessWidget {
  final Game game;

  const GameDetailScreen({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final wishlist = context.watch<WishlistProvider>();
    final inCart = cart.contains(game.id);
    final inWishlist = wishlist.contains(game.id);

    return Scaffold(
      appBar: AppBar(title: Text(game.title)),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroBanner(context),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitleSection(context),
                    const SizedBox(height: 16),
                    _buildInfoRow(context),
                    const SizedBox(height: 16),
                    _buildTagsRow(),
                    const SizedBox(height: 20),
                    _buildDescription(context),
                    const SizedBox(height: 24),
                    _buildActionButtons(context, cart, wishlist, inCart, inWishlist),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context) {
    return Container(
      height: 220,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.surface, AppColors.background],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          ApiService.imageUrl(game.imageUrl),
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Center(
            child: Icon(Icons.videogame_asset, size: 80,
                color: AppColors.neonGreen.withValues(alpha: 0.4)),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleSection(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(game.title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(letterSpacing: 1)),
              const SizedBox(height: 4),
              Text(game.genre.toUpperCase(),
                  style: const TextStyle(color: AppColors.textSecondary,
                      letterSpacing: 2, fontSize: 12)),
            ],
          ),
        ),
        Row(
          children: [
            const Icon(Icons.star, color: AppColors.gold, size: 20),
            const SizedBox(width: 4),
            Text(game.rating.toString(),
                style: const TextStyle(color: AppColors.gold,
                    fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context) {
    return Row(
      children: [
        _buildInfoChip("${game.rating} ESTRELLAS", AppColors.gold),
        const SizedBox(width: 8),
        _buildInfoChip(game.genre.toUpperCase(), AppColors.neonGreen),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (game.isOnSale)
              Text("\$${game.price.toStringAsFixed(2)}",
                  style: const TextStyle(color: AppColors.textSecondary,
                      decoration: TextDecoration.lineThrough, fontSize: 16)),
            Text(
              game.isOnSale
                  ? "\$${game.salePrice!.toStringAsFixed(2)}"
                  : "\$${game.price.toStringAsFixed(2)}",
              style: TextStyle(
                color: game.isOnSale ? AppColors.error : AppColors.neonGreen,
                fontSize: 28, fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildTagsRow() {
    return Wrap(
      spacing: 8, runSpacing: 4,
      children: game.tags.map((tag) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.neonGreen.withValues(alpha: 0.1),
          border: Border.all(color: AppColors.neonGreenDim),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(tag,
            style: const TextStyle(color: AppColors.neonGreen,
                fontSize: 11, fontWeight: FontWeight.bold)),
      )).toList(),
    );
  }

  Widget _buildDescription(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("DESCRIPCIÓN",
            style: TextStyle(color: AppColors.textSecondary,
                letterSpacing: 2, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(game.description,
            style: const TextStyle(color: AppColors.textPrimary, height: 1.5)),
        const SizedBox(height: 12),
        const Text("Sumérgete en una experiencia única donde cada partida te acerca "
            "a la gloria. Gráficos mejorados, jugabilidad fluida y un mundo "
            "que reacciona a cada una de tus decisiones.",
            style: TextStyle(color: AppColors.textSecondary, height: 1.5)),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, CartProvider cart, WishlistProvider wishlist, bool inCart, bool inWishlist) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: inCart
                ? null
                : () async {
                    await cart.add(game);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Agregado al carrito"),
                        backgroundColor: AppColors.neonGreen,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
            icon: Icon(inCart ? Icons.check_circle : Icons.add_shopping_cart),
            label: Text(inCart ? "EN CARRITO" : "AÑADIR AL CARRITO"),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              if (inWishlist) {
                await wishlist.remove(game.id);
              } else {
                await wishlist.add(game);
              }
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(inWishlist ? "Eliminado de lista de deseados" : "Agregado a lista de deseados"),
                  backgroundColor: AppColors.neonGreen,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: Icon(inWishlist ? Icons.favorite : Icons.favorite_border),
            label: Text(inWishlist ? "EN LISTA DE DESEADOS" : "AGREGAR A LISTA DE DESEADOS"),
            style: OutlinedButton.styleFrom(
              foregroundColor: inWishlist ? AppColors.error : AppColors.neonGreen,
              side: BorderSide(color: inWishlist ? AppColors.error : AppColors.neonGreen),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
