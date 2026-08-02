import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gamestore_app/theme/app_theme.dart';
import 'package:gamestore_app/models/game.dart';
import 'package:gamestore_app/providers/game_provider.dart';
import 'package:gamestore_app/providers/cart_provider.dart';
import 'package:gamestore_app/services/api_service.dart';
import 'package:gamestore_app/screens/game_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  String _selectedCategory = "TODOS";
  List<Game> _results = [];

  final _categories = [
    "TODOS", "SHOOTER", "RPG", "CARRERAS",
    "LUCHA", "DEPORTES", "ESTRATEGIA",
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<GameProvider>();
      if (provider.games.isEmpty) provider.fetchGames();
      _search();
    });
  }

  void _search() {
    final provider = context.read<GameProvider>();
    setState(() {
      _results = provider.search(
        _searchController.text,
        category: _selectedCategory,
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "BUSCAR",
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.neonGreen,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: "Buscar juegos...",
                      prefixIcon: Icon(Icons.search),
                    ),
                    style: const TextStyle(color: AppColors.textPrimary),
                    onChanged: (_) => _search(),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 6),
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        final selected = cat == _selectedCategory;
                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedCategory = cat);
                            _search();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.neonGreen
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: selected
                                    ? AppColors.neonGreen
                                    : AppColors.textSecondary,
                              ),
                            ),
                            child: Text(
                              cat,
                              style: TextStyle(
                                color: selected
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _results.isEmpty
                  ? const Center(
                      child: Text(
                        "SIN RESULTADOS",
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        final p = context.read<GameProvider>();
                        await p.fetchGames();
                        _search();
                      },
                      child: GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.85,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final game = _results[index];
                        return _buildGameCard(context, game);
                      },
                    ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameCard(BuildContext context, Game game) {
    final cart = context.watch<CartProvider>();
    final inCart = cart.contains(game.id);

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
          border: Border.all(
            color: game.isOnSale
                ? AppColors.error.withValues(alpha: 0.5)
                : AppColors.textSecondary.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: Image.network(
                        ApiService.imageUrl(game.imageUrl),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Center(
                          child: Icon(Icons.videogame_asset,
                              color: AppColors.neonGreen.withValues(alpha: 0.3), size: 48),
                        ),
                      ),
                    ),
                    if (game.isOnSale)
                      Positioned(
                        top: 8, right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text("OFERTA",
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    if (inCart)
                      Positioned(
                        top: 8, left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.neonGreen,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text("EN CARRITO",
                              style: TextStyle(color: AppColors.textPrimary, fontSize: 8, fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(game.title,
                        style: const TextStyle(color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, color: AppColors.gold, size: 12),
                        const SizedBox(width: 4),
                        Text(game.rating.toString(),
                            style: const TextStyle(color: AppColors.gold, fontSize: 11)),
                        const SizedBox(width: 8),
                        Text(game.genre,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        if (game.isOnSale)
                          Text("\$${game.price.toStringAsFixed(0)}",
                              style: const TextStyle(color: AppColors.textSecondary,
                                  decoration: TextDecoration.lineThrough, fontSize: 11)),
                        const Spacer(),
                        Text(
                          game.isOnSale
                              ? "\$${game.salePrice!.toStringAsFixed(0)}"
                              : "\$${game.price.toStringAsFixed(0)}",
                          style: TextStyle(
                            color: game.isOnSale ? AppColors.error : AppColors.neonGreen,
                            fontWeight: FontWeight.bold, fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
