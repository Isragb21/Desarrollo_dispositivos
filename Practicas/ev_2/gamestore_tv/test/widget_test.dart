import 'package:flutter_test/flutter_test.dart';
import 'package:gamestore_tv/services/api_service.dart';

void main() {
  group('ApiService', () {
    test('imageUrl convierte rutas relativas a URL completa', () {
      expect(ApiService.imageUrl('/images/cyberpunk_2077.jpg'),
          'http://localhost:3000/images/cyberpunk_2077.jpg');
    });

    test('imageUrl no altera URLs absolutas', () {
      expect(
          ApiService.imageUrl('https://cdn.example.com/cover.jpg'),
          'https://cdn.example.com/cover.jpg');
    });

    test('videoUrl deriva el tráiler del slug de la portada', () {
      expect(ApiService.videoUrl('/images/cyberpunk_2077.jpg'),
          'videos/cyberpunk_2077.mp4');
    });

    test('videoUrl usa default cuando no hay portada', () {
      expect(ApiService.videoUrl(''), 'videos/default.mp4');
    });
  });
}
