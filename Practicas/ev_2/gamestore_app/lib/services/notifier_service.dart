import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Notificaciones locales del celular. Se usan cuando NO hay wearable
/// conectado: la oferta se muestra directamente en el teléfono.
class NotifierService {
  NotifierService._();

  static final NotifierService instance = NotifierService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;

  /// Inicializa las notificaciones y pide permiso (Android 13+). Devuelve
  /// `true` si las notificaciones están permitidas (indispensable para poder
  /// arrancar el servicio en segundo plano sin crashear).
  Future<bool> init() async {
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );
      final allowed = await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      _ready = true;
      return allowed ?? true;
    } catch (_) {
      _ready = false;
      return false;
    }
  }

  /// Muestra una notificación de oferta en el celular.
  Future<void> showOffer({
    required String game,
    required int percent,
    required String body,
  }) async {
    if (!_ready) return;
    try {
      const details = AndroidNotificationDetails(
        'ofertas',
        'Ofertas',
        channelDescription: 'Juegos en oferta del catálogo',
        importance: Importance.max,
        priority: Priority.high,
      );
      await _plugin.show(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: '$game en oferta -$percent%',
        body: body,
        notificationDetails: const NotificationDetails(android: details),
      );
    } catch (_) {}
  }
}
