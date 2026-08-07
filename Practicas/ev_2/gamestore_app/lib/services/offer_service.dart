import 'dart:async';
import 'dart:convert';
import 'dart:ui' show DartPluginRegistrant;

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

/// Servicio en segundo plano (foreground service) que vigila las ofertas del
/// catálogo aunque la app esté cerrada o en segundo plano. Cuando llega una
/// oferta nueva y NO hay wearable conectado, publica una notificación en el
/// celular. Si hay wearable activo, la notificación ya la muestra el reloj.
class OfferService {
  /// Registra el manejador del servicio. NO lo arranca: hay que llamar a
  /// [start] una vez que el usuario concedió permiso de notificaciones.
  static Future<void> initialize() async {
    final service = FlutterBackgroundService();
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: offerServiceOnStart,
        autoStart: false,
        isForegroundMode: true,
        initialNotificationTitle: 'GameStore',
        initialNotificationContent: 'Notificaciones de ofertas activas',
        foregroundServiceNotificationId: 888,
        foregroundServiceTypes: [AndroidForegroundType.dataSync],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: (service) {},
        onBackground: (service) => true,
      ),
    );
  }

  /// Arranca el servicio en segundo plano.
  static Future<void> start() async {
    try {
      await FlutterBackgroundService().startService();
    } catch (_) {
      // Si el arranque falla (p. ej. sin permiso de notificaciones), la app
      // no debe crashear; las ofertas se seguirán viendo con la app abierta.
    }
  }

  static Future<void> stop() async {
    FlutterBackgroundService().invoke('stopService');
  }
}

String get _relayBase {
  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:3000/api/ble-relay';
  }
  return 'http://localhost:3000/api/ble-relay';
}

@pragma('vm:entry-point')
Future<void> offerServiceOnStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((_) {
      service.setAsForegroundService();
    });
    service.on('setAsBackground').listen((_) {
      service.setAsBackgroundService();
    });
    service.on('stopService').listen((_) {
      service.stopSelf();
    });
  }

  final notifications = FlutterLocalNotificationsPlugin();
  await notifications.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );

  int? lastOfferAt;
  Timer? timer;

  Future<void> poll() async {
    var wearableActive = true;
    try {
      final status = await http
          .get(Uri.parse('$_relayBase/status'))
          .timeout(const Duration(seconds: 3));
      final statusJson = jsonDecode(status.body) as Map<String, dynamic>;
      wearableActive = statusJson['wearableActive'] == true;
    } catch (_) {}

    try {
      final res = await http
          .get(Uri.parse('$_relayBase/discount'))
          .timeout(const Duration(seconds: 3));
      if (res.statusCode == 200 && res.body != 'null') {
        final offer = Map<String, dynamic>.from(jsonDecode(res.body));
        final at = (offer['updatedAt'] as num?)?.toInt() ?? 0;
        if (at != 0 && at != lastOfferAt) {
          lastOfferAt = at;
          final game = offer['game']?.toString() ?? '';
          final percent = (offer['percent'] as num?)?.toInt() ?? 0;
          if (game.isNotEmpty && !wearableActive) {
            await notifications.show(
              id: at ~/ 1000,
              title: '$game en oferta -$percent%',
              body: 'El juego "$game" está en oferta con un -$percent%.',
              notificationDetails: const NotificationDetails(
                android: AndroidNotificationDetails(
                  'ofertas',
                  'Ofertas',
                  channelDescription: 'Juegos en oferta del catálogo',
                  importance: Importance.max,
                  priority: Priority.high,
                ),
              ),
            );
          }
        }
      }
    } catch (_) {}

    timer?.cancel();
    timer = Timer(const Duration(seconds: 10), poll);
  }

  timer?.cancel();
  timer = Timer(const Duration(seconds: 3), poll);
}
