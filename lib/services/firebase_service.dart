import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daily_fitness/firebase_options.dart';
import 'package:daily_fitness/services/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  static Future<void> initialize() async {
    if (kIsWeb) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    } else {
      await Firebase.initializeApp();
    }

    FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
    await NotificationService.initialize();
  }
}
