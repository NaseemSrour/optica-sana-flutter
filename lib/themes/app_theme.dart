import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData themeData = ThemeData(
    primarySwatch: Colors.blue,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF005CB2),
      secondary: Color(0xFF0088D1),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      surface: Color(0xFFE3F2FD),
      background: Colors.white,
      error: Colors.red,
      onSurface: Colors.black87,
      onBackground: Colors.black87,
      onError: Colors.white,
    ),
    textTheme: const TextTheme(
      labelLarge: TextStyle(
        color: Color(0xFF005CB2),
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
      bodyLarge: TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.normal,
        fontSize: 16,
      ),
      headlineSmall: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 24,
        color: Color(0xFF005CB2),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: Color(0xFF005CB2), width: 2.0),
      ),
      labelStyle: const TextStyle(
        color: Color(0xFF005CB2),
        fontWeight: FontWeight.bold,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF005CB2),
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
    ),
  );
}
