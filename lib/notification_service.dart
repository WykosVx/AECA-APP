import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Notificación recibida en segundo plano: ${message.messageId}");
  if (message.notification != null) {
    debugPrint("Título: ${message.notification!.title}");
    debugPrint("Cuerpo: ${message.notification!.body}");
  }
}

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> inicializar() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint("Permisos de notificaciones concedidos.");
    } else {
      debugPrint("Permisos de notificaciones denegados o no configurados.");
    }

    String? token = await _messaging.getToken();
    debugPrint("FCM TOKEN: $token");

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("Notificación en primer plano recibida!");
      if (message.notification != null) {
        debugPrint("Título: ${message.notification!.title}");
        debugPrint("Cuerpo: ${message.notification!.body}");
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("El usuario abrió la app desde la notificación!");
    });
  }
}