import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// 🔹 Imports locais
import 'geofencing.dart';
import 'services/notification_service.dart';
import 'services/permission_service.dart';
import 'login_page.dart'; // 👈 Novo login
// import 'home_page.dart';  // agora só é usado dentro do login

// Plugin de notificações locais (global)
final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();

// Canal Android (MESMO ID do Manifest)
const AndroidNotificationChannel _channel = AndroidNotificationChannel(
  'high_importance_channel',
  'Notificações Importantes',
  description: 'Canal para notificações de alta prioridade.',
  importance: Importance.max,
);

// Handler para mensagens recebidas com a app em background/terminada
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  _showLocalFromRemote(message);
}

// Mostra uma notificação local a partir de uma RemoteMessage
Future<void> _showLocalFromRemote(RemoteMessage message) async {
  final notification = message.notification;
  if (notification == null) return;

  final androidDetails = AndroidNotificationDetails(
    _channel.id,
    _channel.name,
    channelDescription: _channel.description,
    importance: Importance.max,
    priority: Priority.high,
  );

  await _local.show(
    notification.hashCode,
    notification.title,
    notification.body,
    NotificationDetails(android: androidDetails),
  );
}

Future<void> _initLocalNotifications() async {
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidInit);

  await _local.initialize(initSettings);

  // Cria o canal no Android (8+)
  final androidImpl =
      _local.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  await androidImpl?.createNotificationChannel(_channel);

  // No Android 13+ é preciso pedir permissão para notificações
  await androidImpl?.requestNotificationsPermission();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Regista o handler de background ANTES do runApp
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Inicializa notificações locais e canal
  await _initLocalNotifications();

  // Inicializa serviço de notificações custom (para POIs)
  await NotificationService.init();

  // 🔔 Pede permissão de notificações
  await PermissionService.requestNotificationPermissions();

  // 🔹 Pede permissão de localização ANTES de arrancar geofencing
  final hasLocation = await PermissionService.requestLocationPermissions();
  if (hasLocation) {
    await GeofencingService.startAllPOIs();
  } else {
    print("⚠️ Localização não concedida — Geofencing não iniciado.");
  }

  runApp(const AzoresTourApp());
}

class AzoresTourApp extends StatelessWidget {
  const AzoresTourApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Azores Tour',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const LoginPage(), // 👈 agora começa no login
    );
  }
}
