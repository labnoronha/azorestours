import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      const InitializationSettings(android: androidInit),
      onDidReceiveNotificationResponse: (resp) {
        final payload = resp.payload;
        if (payload != null) {
          _NotificationTapDispatcher.dispatch(payload);
        }
      },
    );
  }

  static Future<void> showPOI(String title, String body,
      {required String poiId}) async {
    const details = AndroidNotificationDetails(
      'azorestour_channel',
      'AzoresTour',
      channelDescription: 'Alertas de geofencing e dicas',
      importance: Importance.max,
      priority: Priority.high,
    );

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(android: details),
      payload: jsonEncode({'poiId': poiId}),
    );
  }
}

/// Dispatcher simples para tratar dos toques na notificação
typedef NotificationTapHandler = void Function(Map<String, dynamic> data);

class _NotificationTapDispatcher {
  static final _handlers = <NotificationTapHandler>[];

  static void addHandler(NotificationTapHandler h) => _handlers.add(h);

  static void dispatch(String payload) {
    try {
      final data = Map<String, dynamic>.from(jsonDecode(payload));
      for (final h in _handlers) {
        h(data);
      }
    } catch (_) {}
  }
}
