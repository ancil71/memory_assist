import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Guardian Theme - Modern, Clean
  static final ThemeData guardianTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.light,
    ),
    textTheme: GoogleFonts.interTextTheme(),
  );

  // Patient Theme - High Contrast, Large Text, Accessible
  static final ThemeData patientTheme = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.highContrastLight(
      primary: Color(0xFF0055FF), // High contrast blue
      onPrimary: Colors.white,
      secondary: Color(0xFFFFCC00), // High contrast yellow
      onSecondary: Colors.black,
      error: Color(0xFFD32F2F), // High contrast red
      onError: Colors.white,
      background: Colors.white,
      onBackground: Colors.black,
      surface: Colors.white,
      onSurface: Colors.black,
    ),
    scaffoldBackgroundColor: Colors.white,
    textTheme: GoogleFonts.poppinsTextTheme().copyWith(
      displayLarge: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black),
      displayMedium: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
      bodyLarge: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: Colors.black),
      bodyMedium: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.black),
      titleMedium: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.black),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
        textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
  );
}
