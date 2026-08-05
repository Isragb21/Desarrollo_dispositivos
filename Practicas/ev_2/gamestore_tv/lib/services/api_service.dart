import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:gamestore_tv/models/game.dart';

/// Misma API/BD que la app móvil (gamestore_app). Solo lectura (TV).
class ApiService {
  static const String baseUrl = "http://localhost:3000/api";

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
}
