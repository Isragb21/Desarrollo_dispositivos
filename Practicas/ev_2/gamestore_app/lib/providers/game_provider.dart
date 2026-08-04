import 'package:flutter/foundation.dart';
import 'package:gamestore_app/models/game.dart';
import 'package:gamestore_app/services/api_service.dart';

class GameProvider extends ChangeNotifier {
  List<Game> _games = [];
  List<Game> _featured = [];
  bool _loading = false;
  String? _error;

  List<Game> get games => _games;
  List<Game> get featured => _featured;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetchGames() async {
    _loading = true;
    _error = null;
    notifyListeners();

    final results = await ApiService.fetchGames();
    _games = results;
    _featured = results.take(3).toList();
    _loading = false;
    notifyListeners();
  }

  List<Game> search(String query, {String? category}) {
    if (query.isEmpty && (category == null || category == "TODOS")) {
      return _games;
    }
    var results = _games;
    if (category != null && category != "TODOS") {
      results = results.where((g) =>
          g.genre.toUpperCase() == category).toList();
    }
    if (query.isNotEmpty) {
      results = results.where((g) =>
          g.title.toLowerCase().contains(query.toLowerCase())).toList();
    }
    return results;
  }

  Game? getById(String id) {
    try {
      return _games.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }
}
