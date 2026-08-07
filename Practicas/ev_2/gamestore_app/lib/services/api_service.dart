import 'dart:convert';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:http/http.dart' as http;
import 'package:gamestore_app/models/game.dart';
import 'package:gamestore_app/models/user.dart';

class ApiService {
  static String _baseUrlOverride = "";
  static String get _baseUrl {
    if (_baseUrlOverride.isNotEmpty) return _baseUrlOverride;
    if (defaultTargetPlatform == TargetPlatform.android) {
      return "http://10.0.2.2:3000/api";
    }
    return "http://localhost:3000/api";
  }
  static set baseUrlOverride(String v) => _baseUrlOverride = v;

  /// Converts a relative image path to a full URL using the API base.
  static String imageUrl(String path) {
    if (path.startsWith('http')) return path;
    final base = _baseUrl.replaceAll('/api', '');
    return '$base$path';
  }
  static String? currentUserId;
  static UserModel? currentUser;
  static String? lastError;

  static String? get userId => currentUserId;

  static double _parseDouble(dynamic v) {
    if (v == null) return 0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  static Game _parseGame(Map j) {
    return Game(
      id: j['id'].toString(),
      title: j['titulo']?.toString() ?? '',
      genre: j['genero']?.toString() ?? '',
      description: j['descripcion']?.toString() ?? '',
      price: _parseDouble(j['precio']),
      rating: _parseDouble(j['rating']),
      imageUrl: j['portada']?.toString() ?? '',
      tags: (j['etiquetas'] as List?)?.map((e) => e.toString()).toList() ?? [],
      isOnSale: j['descuento'] != null,
      salePrice: _parseDouble(j['descuento']),
    );
  }

  static Future<List<Game>> fetchGames({String? search, String? genero}) async {
    try {
      final params = <String, String>{};
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (genero != null && genero.isNotEmpty) params['genero'] = genero;
      final uri = Uri.parse("$_baseUrl/juegos").replace(queryParameters: params.isNotEmpty ? params : null);
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map((j) => _parseGame(j)).toList();
      }
      try { lastError = json.decode(response.body)['error']; } catch (_) {}
      return [];
    } catch (e) {
      lastError = "Error al cargar juegos: $e";
      return [];
    }
  }

  static Future<Game?> fetchGameById(String id) async {
    try {
      final response = await http.get(Uri.parse("$_baseUrl/juegos/$id"));
      if (response.statusCode == 200) {
        return _parseGame(json.decode(response.body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<List<Game>> fetchCart() async {
    if (currentUserId == null) return [];
    try {
      final response = await http.get(Uri.parse("$_baseUrl/carrito/$currentUserId"));
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map((j) => _parseGame(j)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> addToCart(String gameId) async {
    if (currentUserId == null) return false;
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/carrito"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"user_id": currentUserId, "juego_id": gameId}),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> removeFromCart(String gameId) async {
    if (currentUserId == null) return false;
    try {
      final response = await http.delete(
        Uri.parse("$_baseUrl/carrito"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"user_id": currentUserId, "juego_id": gameId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> clearCart() async {
    if (currentUserId == null) return false;
    try {
      final response = await http.delete(Uri.parse("$_baseUrl/carrito/clear/$currentUserId"));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// La oferta activa del momento (publicada por el backend cada 30s).
  static Future<Map<String, dynamic>?> fetchActiveOffer() async {
    try {
      final response = await http
          .get(Uri.parse("$_baseUrl/ble-relay/discount"))
          .timeout(const Duration(seconds: 3));
      if (response.statusCode == 200 && response.body != "null") {
        return Map<String, dynamic>.from(json.decode(response.body));
      }
    } catch (e) {
      // Sin conexión al backend: se ignora.
    }
    return null;
  }

  static Future<UserModel?> login(String email, String password) async {
    lastError = null;
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/auth/login"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"email": email, "password": password}),
      );
      if (response.statusCode == 200) {
        final u = json.decode(response.body);
        final user = UserModel(
          id: u['id'].toString(),
          username: u['username'] ?? '',
          gamertag: u['gamertag'] ?? '',
          email: u['email'] ?? '',
          level: int.tryParse(u['nivel']?.toString() ?? '') ?? 1,
          xp: int.tryParse(u['xp']?.toString() ?? '') ?? 0,
          nextLevelXp: int.tryParse(u['xp_siguiente']?.toString() ?? '') ?? 1000,
          gamesOwned: int.tryParse(u['juegos_poseidos']?.toString() ?? '') ?? 0,
        );
        currentUserId = user.id;
        currentUser = user;
        return user;
      }
      if (response.statusCode == 401) {
        lastError = "Credenciales inválidas";
      } else {
        try { lastError = json.decode(response.body)['error']; } catch (_) { lastError = "Error del servidor (${response.statusCode})"; }
      }
      return null;
    } catch (e) {
      lastError = "No se pudo conectar ($_baseUrl) — $e";
      return null;
    }
  }

  static Future<UserModel?> register(String username, String gamertag, String email, String password) async {
    lastError = null;
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/auth/register"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "username": username,
          "gamertag": gamertag,
          "email": email,
          "password": password,
        }),
      );
      if (response.statusCode == 201) {
        final u = json.decode(response.body);
        final user = UserModel(
          id: u['id'].toString(),
          username: u['username'] ?? '',
          gamertag: u['gamertag'] ?? '',
          email: u['email'] ?? '',
          level: int.tryParse(u['nivel']?.toString() ?? '') ?? 1,
          xp: int.tryParse(u['xp']?.toString() ?? '') ?? 0,
          nextLevelXp: int.tryParse(u['xp_siguiente']?.toString() ?? '') ?? 1000,
          gamesOwned: int.tryParse(u['juegos_poseidos']?.toString() ?? '') ?? 0,
        );
        currentUserId = user.id;
        currentUser = user;
        return user;
      }
      try { lastError = json.decode(response.body)['error']; } catch (_) { lastError = "Error del servidor (${response.statusCode})"; }
      return null;
    } catch (e) {
      lastError = "No se pudo conectar ($_baseUrl) — $e";
      return null;
    }
  }

  static Future<UserModel?> fetchUser() async {
    if (currentUserId == null) return null;
    try {
      final response = await http.get(Uri.parse("$_baseUrl/usuario/$currentUserId"));
      if (response.statusCode == 200) {
        final u = json.decode(response.body);
        final user = UserModel(
          id: u['id'].toString(),
          username: u['username'] ?? '',
          gamertag: u['gamertag'] ?? '',
          email: u['email'] ?? '',
          level: int.tryParse(u['nivel']?.toString() ?? '') ?? 1,
          xp: int.tryParse(u['xp']?.toString() ?? '') ?? 0,
          nextLevelXp: int.tryParse(u['xp_siguiente']?.toString() ?? '') ?? 1000,
          gamesOwned: int.tryParse(u['juegos_poseidos']?.toString() ?? '') ?? 0,
          recentGames: u['juegos_recientes'] != null
              ? List<Map<String, dynamic>>.from(u['juegos_recientes']).map((g) => g['titulo']?.toString() ?? '').toList()
              : [],
        );
        currentUser = user;
        return user;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static void logout() {
    currentUserId = null;
    currentUser = null;
    lastError = null;
  }

  static Future<UserModel?> updateProfile({String? username, String? gamertag, String? email}) async {
    if (currentUserId == null) return null;
    lastError = null;
    try {
      final response = await http.put(
        Uri.parse("$_baseUrl/usuario/$currentUserId"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "username": ?username,
          "gamertag": ?gamertag,
          "email": ?email,
        }),
      );
      if (response.statusCode == 200) {
        final u = json.decode(response.body);
        final user = UserModel(
          id: u['id'].toString(),
          username: u['username'] ?? '',
          gamertag: u['gamertag'] ?? '',
          email: u['email'] ?? '',
          level: int.tryParse(u['nivel']?.toString() ?? '') ?? 1,
          xp: int.tryParse(u['xp']?.toString() ?? '') ?? 0,
          nextLevelXp: int.tryParse(u['xp_siguiente']?.toString() ?? '') ?? 1000,
          gamesOwned: int.tryParse(u['juegos_poseidos']?.toString() ?? '') ?? 0,
        );
        currentUser = user;
        return user;
      }
      if (response.statusCode == 409) {
        try { lastError = json.decode(response.body)['error']; } catch (_) {}
      } else {
        try { lastError = json.decode(response.body)['error']; } catch (_) { lastError = "Error del servidor (${response.statusCode})"; }
      }
      return null;
    } catch (e) {
      lastError = "No se pudo conectar — $e";
      return null;
    }
  }

  static Future<List<Game>> fetchWishlist() async {
    if (currentUserId == null) return [];
    try {
      final response = await http.get(Uri.parse("$_baseUrl/deseados/$currentUserId"));
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map((j) => _parseGame(j)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> addToWishlist(String gameId) async {
    if (currentUserId == null) return false;
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/deseados"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"user_id": currentUserId, "juego_id": gameId}),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> removeFromWishlist(String gameId) async {
    if (currentUserId == null) return false;
    try {
      final response = await http.delete(
        Uri.parse("$_baseUrl/deseados"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"user_id": currentUserId, "juego_id": gameId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> simulatePayment() async {
    if (currentUserId == null) return null;
    lastError = null;
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/pago"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"user_id": currentUserId}),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await fetchUser();
        return data;
      }
      try { lastError = json.decode(response.body)['error']; } catch (_) {}
      return null;
    } catch (e) {
      lastError = "No se pudo conectar — $e";
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchNotifications() async {
    if (currentUserId == null) return [];
    try {
      final response = await http.get(Uri.parse("$_baseUrl/notificaciones/$currentUserId"));
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> markNotificationRead(String notificationId) async {
    try {
      final response = await http.put(Uri.parse("$_baseUrl/notificaciones/$notificationId/leer"));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Estado de la solicitud de inicio de sesión en TV (2FA):
  /// 'pending' | 'confirmed' | 'rejected' | 'none'.
  static Future<String> check2fa(String email) async {
    try {
      final response = await http.get(Uri.parse("$_baseUrl/auth/check-2fa/$email"));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['status'] as String?) ?? 'none';
      }
      return 'none';
    } catch (e) {
      return 'none';
    }
  }

  /// Confirma o rechaza la solicitud de inicio de sesión en TV.
  static Future<bool> confirm2fa(String email, String status) async {
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/auth/confirm-2fa"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"email": email, "status": status}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
