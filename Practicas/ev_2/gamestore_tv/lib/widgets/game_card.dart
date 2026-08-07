import 'package:flutter/material.dart';
import 'package:gamestore_tv/models/game.dart';
import 'package:gamestore_tv/theme/tv_theme.dart';
import 'package:gamestore_tv/services/api_service.dart';

/// Tarjeta enfocable del grid 2x2 estilo "thumbnail de video":
/// portada full-bleed + overlay de play + info inferior. Foco visible con
/// borde/glow dorado (SA.2.B) y datos reales (mín 3 campos, SA.2.C).
class GameCard extends StatelessWidget {
  final Game game;
  final bool focused;
  final VoidCallback onSelect;

  const GameCard({
    super.key,
    required this.game,
    required this.focused,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      selected: focused,
      label:
          '${game.title}. Género ${game.genre}. '
          'Calificación ${game.rating.toStringAsFixed(1)}. '
          'Precio \$${(game.isOnSale ? game.salePrice! : game.price).toStringAsFixed(2)}. '
          '${focused ? 'Seleccionado.' : 'Presiona Enter para seleccionar.'}',
      child: GestureDetector(
        onTap: onSelect,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          transform: focused
              ? (Matrix4.identity()..scale(1.06, 1.06, 1.0))
              : Matrix4.identity(),
          decoration: BoxDecoration(
            color: TvColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: focused ? TvColors.gold : TvColors.textSecondary,
              width: focused ? 6 : 2,
            ),
            boxShadow: focused
                ? [
                    BoxShadow(
                      color: TvColors.gold.withValues(alpha: 0.50),
                      blurRadius: 48,
                      spreadRadius: 8,
                    ),
                    BoxShadow(
                      color: TvColors.gold.withValues(alpha: 0.18),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ]
                : const [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _Cover(game: game),
                // Overlay inferior para legibilidad
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.center,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xF20B0E14)],
                    ),
                  ),
                ),
                // Botón de play (estilo preview de video)
                Center(
                    child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: focused
                          ? TvColors.gold.withValues(alpha: 0.30)
                          : Colors.black.withValues(alpha: 0.45),
                      border: Border.all(
                        color: focused ? TvColors.gold : TvColors.textSecondary,
                        width: focused ? 4 : 3,
                      ),
                      boxShadow: focused
                          ? [
                              BoxShadow(
                                color: TvColors.gold.withValues(alpha: 0.28),
                                blurRadius: 18,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: focused ? TvColors.gold : TvColors.textSecondary,
                      size: 48,
                    ),
                  ),
                ),
                // Información contextual del registro (SA.2.C)
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        game.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: focused ? TvColors.gold : TvColors.textPrimary,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            game.genre.toUpperCase(),
                            style: const TextStyle(
                              color: TvColors.textSecondary,
                              fontSize: 24,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 20),
                          const Icon(
                            Icons.star,
                            color: TvColors.gold,
                            size: 24,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            game.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: TvColors.gold,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            "\$ ${(game.isOnSale ? game.salePrice! : game.price).toStringAsFixed(2)}",
                            style: TextStyle(
                              color: game.isOnSale
                                  ? TvColors.error
                                  : TvColors.neonGreen,
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
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

class _Cover extends StatelessWidget {
  final Game game;
  const _Cover({required this.game});

  @override
  Widget build(BuildContext context) {
    return Image.network(
      ApiService.imageUrl(game.imageUrl),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Center(
        child: Icon(
          Icons.videogame_asset,
          size: 64,
          color: TvColors.neonGreen.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
