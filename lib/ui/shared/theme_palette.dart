import 'package:flutter/material.dart';

class ThemePalette {
  static const Color primary = Color(0xFF0F2850);
  static const Color accent = Color(0xFF4AB3F4);
  static const Color background = Color(0xFFF4F8FF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color success = Color(0xFF37B24D);
  static const Color warning = Color(0xFFF08C00);
  static const Color error = Color(0xFFEF4444);

  static final ThemeData theme = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: accent,
      background: background,
      surface: surface,
    ),
    scaffoldBackgroundColor: background,
    textTheme: Typography.blackMountainView,
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Color(0xFFF2F6FF),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide.none,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    cardTheme: const CardThemeData(
      color: surface,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
    ),
  );
}
