import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    await _messaging.requestPermission();
    FirebaseMessaging.onMessage.listen((message) {
      // Handle foreground messages.
      debugPrint('Received notification: ${message.notification?.title}');
    });
  }

  static Future<String?> getToken() async {
    return _messaging.getToken();
  }
}
