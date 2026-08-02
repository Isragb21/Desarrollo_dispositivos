import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gamestore_app/theme/app_theme.dart';
import 'package:gamestore_app/models/game.dart';
import 'package:gamestore_app/providers/game_provider.dart';
import 'package:gamestore_app/services/api_service.dart';
import 'package:gamestore_app/screens/game_detail_screen.dart';
import 'package:gamestore_app/widgets/wearable_monitor.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<GameProvider>();
      if (provider.games.isEmpty) provider.fetchGames();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => provider.fetchGames(),
          child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 16),
              const WearableMonitor(),
              const SizedBox(height: 24),
              _buildSectionTitle(context, "LANZAMIENTOS DESTACADOS"),
              const SizedBox(height: 12),
              _buildFeaturedCarousel(context, provider.featured),
              const SizedBox(height: 24),
              _buildSectionTitle(context, "EXPLORAR"),
              const SizedBox(height: 12),
              _buildQuickActions(context),
              const SizedBox(height: 24),
              _buildSectionTitle(context, "TENDENCIAS"),
              const SizedBox(height: 12),
              _buildTrendingGrid(context, provider.games),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("BIENVENIDO",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary, letterSpacing: 2)),
            Text(ApiService.currentUser?.gamertag ?? "OPERADOR",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.neonGreen, letterSpacing: 3)),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.neonGreen),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.stars_rounded, color: AppColors.gold, size: 18),
              const SizedBox(width: 6),
              Text("NIVEL ${ApiService.currentUser?.level ?? 7}",
                  style: TextStyle(color: AppColors.gold,
                      fontWeight: FontWeight.bold, letterSpacing: 1)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Row(
      children: [
        Container(width: 4, height: 20, color: AppColors.neonGreen),
        const SizedBox(width: 8),
        Text(title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(letterSpacing: 1)),
      ],
    );
  }

  Widget _buildFeaturedCarousel(BuildContext context, List<Game> games) {
    if (games.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: games.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return _buildFeaturedCard(context, games[index]);
        },
      ),
    );
  }

  Widget _buildFeaturedCard(BuildContext context, Game game) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => GameDetailScreen(game: game)),
        );
      },
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.surface, AppColors.background],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.neonGreen.withValues(alpha: 0.3)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(game.title,
                      style: const TextStyle(color: AppColors.textPrimary,
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                if (game.isOnSale)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text("OFERTA",
                        style: TextStyle(color: Colors.white, fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.star, color: AppColors.gold, size: 16),
                const SizedBox(width: 4),
                Text(game.rating.toString(),
                    style: const TextStyle(color: AppColors.gold)),
                const SizedBox(width: 12),
                Text(game.genre,
                    style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 12),
            Text(game.description,
                style: const TextStyle(color: AppColors.textSecondary),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            const Spacer(),
            Row(
              children: [
                ...game.tags.map((tag) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.neonGreenDim),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(tag,
                      style: const TextStyle(color: AppColors.neonGreenDim, fontSize: 9)),
                )),
                const Spacer(),
                Text(
                  game.isOnSale
                      ? "\$${game.salePrice!.toStringAsFixed(0)}"
                      : "\$${game.price.toStringAsFixed(0)}",
                  style: TextStyle(
                    color: game.isOnSale ? AppColors.error : AppColors.neonGreen,
                    fontSize: 18, fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        _buildActionChip(context, Icons.whatshot, "TENDENCIAS"),
        const SizedBox(width: 8),
        _buildActionChip(context, Icons.new_releases, "NOVEDADES"),
        const SizedBox(width: 8),
        _buildActionChip(context, Icons.local_offer, "OFERTAS"),
      ],
    );
  }

  Widget _buildActionChip(BuildContext context, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.neonGreen.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.neonGreen, size: 16),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildTrendingGrid(BuildContext context, List<Game> games) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: games.length,
      itemBuilder: (context, index) {
        return _buildTrendingCard(context, games[index]);
      },
    );
  }

  Widget _buildTrendingCard(BuildContext context, Game game) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => GameDetailScreen(game: game)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.2)),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  ApiService.imageUrl(game.imageUrl),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Center(
                    child: Icon(Icons.videogame_asset,
                        color: AppColors.neonGreen.withValues(alpha: 0.5), size: 48),
                  ),
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(game.title,
                style: const TextStyle(color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold, fontSize: 14),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.star, color: AppColors.gold, size: 12),
                const SizedBox(width: 4),
                Text(game.rating.toString(),
                    style: const TextStyle(color: AppColors.gold, fontSize: 11)),
                const Spacer(),
                Text("\$${game.price.toStringAsFixed(0)}",
                    style: const TextStyle(color: AppColors.neonGreen,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
