import 'package:flutter/foundation.dart';
import 'package:gamestore_app/models/game.dart';
import 'package:gamestore_app/services/api_service.dart';

class CartProvider extends ChangeNotifier {
  final Map<String, Game> _items = {};

  Map<String, Game> get items => Map.unmodifiable(_items);
  int get count => _items.length;
  double get total => _items.values.fold(0, (sum, g) => sum + (g.isOnSale ? g.salePrice! : g.price));
  bool get isEmpty => _items.isEmpty;

  Future<void> loadCart() async {
    final cartGames = await ApiService.fetchCart();
    _items.clear();
    for (final game in cartGames) {
      _items[game.id] = game;
    }
    notifyListeners();
  }

  Future<void> add(Game game) async {
    if (!_items.containsKey(game.id)) {
      final ok = await ApiService.addToCart(game.id);
      if (ok) {
        _items[game.id] = game;
        notifyListeners();
      }
    }
  }

  Future<void> remove(String gameId) async {
    if (_items.containsKey(gameId)) {
      final ok = await ApiService.removeFromCart(gameId);
      if (ok) {
        _items.remove(gameId);
        notifyListeners();
      }
    }
  }

  Future<void> clear() async {
    final ok = await ApiService.clearCart();
    if (ok) {
      _items.clear();
      notifyListeners();
    }
  }

  bool contains(String gameId) => _items.containsKey(gameId);
}
