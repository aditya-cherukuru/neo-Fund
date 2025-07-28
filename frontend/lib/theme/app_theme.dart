import 'package:flutter/material.dart';

class AppTheme {
  // Color constants
  static const Color lightModePurple = Color(0xFF6B46C1);
  static const Color darkModePurple = Color(0xFF9F7AEA);
  static const Color lightModeBackground = Color(0xFFF7FAFC);
  static const Color darkModeBackground = Color(0xFF1A202C);
  static const Color lightModeSurface = Color(0xFFFFFFFF);
  static const Color darkModeSurface = Color(0xFF2D3748);
  static const Color lightModeText = Color(0xFF2D3748);
  static const Color darkModeText = Color(0xFFF7FAFC);
  static const Color lightModeTextSecondary = Color(0xFF718096);
  static const Color darkModeTextSecondary = Color(0xFFA0AEC0);

  // Light theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: lightModePurple,
        secondary: darkModePurple,
        surface: lightModeSurface,
        background: lightModeBackground,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: lightModeText,
        onBackground: lightModeText,
      ),
      scaffoldBackgroundColor: lightModeBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: lightModeSurface,
        foregroundColor: lightModeText,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: lightModeText,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardTheme(
        color: lightModeSurface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightModePurple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: lightModeText,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: lightModeText,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          color: lightModeText,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: lightModeText,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: lightModeTextSecondary,
          fontSize: 14,
        ),
      ),
    );
  }

  // Dark theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: darkModePurple,
        secondary: lightModePurple,
        surface: darkModeSurface,
        background: darkModeBackground,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: darkModeText,
        onBackground: darkModeText,
      ),
      scaffoldBackgroundColor: darkModeBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkModeSurface,
        foregroundColor: darkModeText,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: darkModeText,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardTheme(
        color: darkModeSurface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkModePurple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: darkModeText,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: darkModeText,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          color: darkModeText,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: darkModeText,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: darkModeTextSecondary,
          fontSize: 14,
        ),
      ),
    );
  }
} 