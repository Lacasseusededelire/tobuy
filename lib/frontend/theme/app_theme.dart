import 'package:flutter/material.dart';

class AppTheme {
  static const Color sageGreen = Color(0xFFA8BDB0);
  static const Color lightBeige = Color(0xFFF5F0E1);
  static const Color softBrown = Color(0xFFC1A783);
  static const Color offWhite = Color(0xFFFAFAF5);

  static ThemeData lightTheme = ThemeData(
    primaryColor: sageGreen,
    scaffoldBackgroundColor: lightBeige,
    cardColor: offWhite,
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: softBrown, fontSize: 16),
      bodyMedium: TextStyle(color: softBrown, fontSize: 14),
      headlineSmall: TextStyle(color: softBrown, fontWeight: FontWeight.bold, fontSize: 20),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: sageGreen,
        foregroundColor: offWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: sageGreen,
      foregroundColor: offWhite,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: sageGreen,
      foregroundColor: offWhite,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: offWhite,
      hintStyle: const TextStyle(color: softBrown),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    primaryColor: sageGreen,
    scaffoldBackgroundColor: const Color(0xFF2A2F2B),
    cardColor: const Color(0xFF3C403A), // Gris foncé pour les cartes en mode sombre
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: offWhite, fontSize: 16),
      bodyMedium: TextStyle(color: offWhite, fontSize: 14),
      headlineSmall: TextStyle(color: offWhite, fontWeight: FontWeight.bold, fontSize: 20),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: sageGreen,
        foregroundColor: offWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: sageGreen,
      foregroundColor: offWhite,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1A1E1B),
      foregroundColor: offWhite,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: const Color(0xFF3C403A),
      hintStyle: const TextStyle(color: offWhite), // Placeholder clair en mode sombre
    ),
  );
}