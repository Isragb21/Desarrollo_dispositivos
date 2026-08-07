import 'package:flutter/foundation.dart';
import 'package:gamestore_app/models/game.dart';
import 'package:gamestore_app/services/api_service.dart';
import 'package:gamestore_app/services/wearable_ble_service.dart';

class WishlistProvider extends ChangeNotifier {
  final Map<String, Game> _items = {};

  Map<String, Game> get items => Map.unmodifiable(_items);
  int get count => _items.length;
  bool get isEmpty => _items.isEmpty;

  Future<void> loadWishlist() async {
    final games = await ApiService.fetchWishlist();
    _items.clear();
    for (final game in games) {
      _items[game.id] = game;
    }
    _pushFavoritesToWearable();
    notifyListeners();
  }

  Future<bool> add(Game game) async {
    if (!_items.containsKey(game.id)) {
      final ok = await ApiService.addToWishlist(game.id);
      if (ok) {
        _items[game.id] = game;
        _notifyDiscount(game);
        _pushFavoritesToWearable();
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  void _pushFavoritesToWearable() {
    final titles = _items.values
        .map((g) => g.title)
        .toList()
      ..sort();
    WearableBleService().sendFavorites(games: titles);
  }

  void _notifyDiscount(Game game) {
    if (!game.isOnSale || game.salePrice == null) return;
    final percent =
        ((1 - (game.salePrice! / game.price)) * 100).round().clamp(0, 99);
    WearableBleService().sendDiscountAlert(
      game: game.title,
      percent: percent,
    );
  }

  Future<bool> remove(String gameId) async {
    if (_items.containsKey(gameId)) {
      final ok = await ApiService.removeFromWishlist(gameId);
      if (ok) {
        _items.remove(gameId);
        _pushFavoritesToWearable();
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  bool contains(String gameId) => _items.containsKey(gameId);
}
