import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web;
import 'package:gamestore_tv/models/game.dart';
import 'package:gamestore_tv/models/tv_user.dart';

/// Misma API/BD que la app móvil (gamestore_app). Solo lectura (TV).
class ApiService {
  static const String baseUrl = "http://localhost:3000/api";

  /// Usuario con sesión iniciada en la TV (tras confirmación 2FA).
  static TvUser? currentUser;

  /// Clave de localStorage donde se guarda la sesión para que sobreviva al
  /// refrescar la pestaña (se cierra solo con el botón "Cerrar sesión").
  static const String _sessionKey = 'gamestore_tv_session';

  /// Persiste la sesión actual en localStorage.
  static void saveSession() {
    final user = currentUser;
    if (user == null) return;
    try {
      web.window.localStorage.setItem(_sessionKey, jsonEncode(user.toJson()));
    } catch (_) {
      // localStorage puede fallar (p.ej. navegador con almacenamiento
      // bloqueado); en ese caso la sesión solo vive mientras dure la pestaña.
    }
  }

  /// Restaura la sesión guardada al arrancar la app. Devuelve el usuario o
  /// null si no hay sesión previa.
  static TvUser? loadSession() {
    try {
      final raw = web.window.localStorage.getItem(_sessionKey);
      if (raw == null || raw.isEmpty) {
        currentUser = null;
      } else {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          currentUser = TvUser.fromJson(decoded);
        }
      }
    } catch (_) {
      currentUser = null;
    }
    return currentUser;
  }

  /// Cierra sesión y borra la sesión persistida.
  static void clearSession() {
    currentUser = null;
    try {
      web.window.localStorage.removeItem(_sessionKey);
    } catch (_) {}
  }

  static String imageUrl(String path) {
    if (path.startsWith('http')) return path;
    return "http://localhost:3000$path";
  }

  /// URL del fondo HD 1920x1080 del juego (generado en el backend).
  /// `/images/god_of_war_ragnarok.jpg` -> `/images/backdrops/god_of_war_ragnarok.jpg`.
  static String backdropUrl(String imagePath) {
    if (imagePath.isEmpty) return imageUrl(imagePath);
    final fileName = imagePath.split('/').last;
    return imageUrl('/images/backdrops/$fileName');
  }

  /// URL del video de fondo derivada de la portada del juego, p.ej.
  /// `/images/cyberpunk_2077.jpg` -> `videos/cyberpunk_2077.mp4`.
  /// El MP4 vive en `web/videos/` (mismo origen que la PWA) para ser
  /// cacheable por el Service Worker y reproducible offline.
  static String videoUrl(String imagePath) {
    if (imagePath.isEmpty) return 'videos/default.mp4';
    final fileName = imagePath.split('/').last;
    final base = fileName.replaceAll(RegExp(r'\.[^.]+$'), '');
    return 'videos/$base.mp4';
  }

  /// Juegos que tienen tráiler en `web/videos/<slug>.mp4`.
  /// Los demás usan solo el fondo HD (imagen) para no depender del video.
  static const Set<String> _gamesWithVideo = {
    'cyberpunk_2077',
    'elden_ring',
    'god_of_war_ragnarok',
    'stray',
  };

  static bool hasVideo(String imagePath) {
    if (imagePath.isEmpty) return false;
    final fileName = imagePath.split('/').last;
    final base = fileName.replaceAll(RegExp(r'\.[^.]+$'), '');
    return _gamesWithVideo.contains(base);
  }

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
      final uri = Uri.parse(
        "$baseUrl/juegos",
      ).replace(queryParameters: params.isNotEmpty ? params : null);
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map((j) => _parseGame(j)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Login desde TV: valida credenciales y crea una solicitud 2FA pendiente.
  /// Devuelve `{'pending': bool, 'user': {...}}` o `null` si las credenciales
  /// fallaron o hubo error de red.
  static Future<Map<String, dynamic>?> loginTv(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/auth/login-tv"),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Polling del estado 2FA: 'pending' | 'confirmed' | 'rejected' | 'none'.
  static Future<String> check2fa(String email) async {
    try {
      final uri = Uri.parse("$baseUrl/auth/check-2fa/${Uri.encodeComponent(email)}");
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['status'] as String?) ?? 'none';
      }
      return 'none';
    } catch (_) {
      return 'none';
    }
  }

  /// Perfil completo del usuario (incluye nivel, XP y juegos poseídos).
  static Future<TvUser?> fetchUser(String id) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/usuario/$id"));
      if (response.statusCode == 200) {
        return TvUser.fromJson(json.decode(response.body));
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Juegos poseídos por el usuario (biblioteca) con datos completos,
  /// ordenados por calificación. Vacío si no hay sesión o falla la red.
  static Future<List<Game>> fetchOwnedGames(String userId) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/biblioteca/$userId"));
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map((j) => _parseGame(j)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Edita datos básicos del perfil (gamertag, username, email).
  static Future<TvUser?> updateProfile({
    required String id,
    String? username,
    String? gamertag,
    String? email,
  }) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/usuario/$id"),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          if (username != null) 'username': username,
          if (gamertag != null) 'gamertag': gamertag,
          if (email != null) 'email': email,
        }),
      );
      if (response.statusCode == 200) {
        return TvUser.fromJson(json.decode(response.body));
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
