import 'package:daily_fitness/app.dart';
import 'package:daily_fitness/services/firebase_service.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.initialize();
  runApp(const DailyFitnessApp());
}
