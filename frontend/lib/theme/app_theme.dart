import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Light Theme Colors (Updated - Darker and More Vibrant)
  static const Color mainBackground = Color(0xFFF5F7FA); // Light Blue-Gray Background
  static const Color cardBackground = Color(0xFFFFFFFF); // Pure White Cards
  static const Color borderShadow = Color(0xFFD1D5DB); // Darker Gray Border
  static const Color primaryText = Color(0xFF1F2937); // Dark Gray Text
  static const Color secondaryText = Color(0xFF4B5563); // Medium Gray Text
  static const Color valueText = Color(0xFF059669); // Darker Success Green
  static const Color cryptoButton = Color(0xFF6B2B6B); // Vibrant Purple
  static const Color stocksButton = Color(0xFF06B6D4); // Vibrant Cyan
  static const Color quickAddButton = Color(0xFF10B981); // Vibrant Green
  static const Color quickAddText = Color(0xFFFFFFFF); // White Text
  static const Color roundUpToggle = Color(0xFF3B82F6); // Vibrant Blue
  static const Color pieCrypto = Color(0xFF6B2B6B); // Dark Purple
  static const Color pieStocks = Color(0xFF059669); // Dark Green (Replaced Seagreen)
  static const Color lineSolo = Color(0xFFDC2626); // Vibrant Red
  static const Color lineSquad = Color(0xFF0891B2); // Vibrant Teal
  static const Color xpAlice = Color(0xFFF59E0B); // Vibrant Orange
  static const Color xpBob = Color(0xFF3B82F6); // Vibrant Blue
  static const Color xpCarol = Color(0xFFEF4444); // Vibrant Red
  static const Color lightModePurple = Color(0xFF6B2B6B); // Deep Purple for Light Mode

  // Dark Theme Colors
  static const Color darkPrimaryColor = Color(0xFF6B2B6B); // Deep purple
  static const Color darkSecondaryColor = Color(0xFF06D6A0); // Teal/green accent
  static const Color darkAccentColor = Color(0xFF00B4D8); // Vibrant blue/teal
  static const Color darkBackgroundColor = Color(0xFF231124); // Very dark purple
  static const Color darkSurfaceColor = Color(0xFF2D1836); // Card background
  static const Color darkTextPrimaryColor = Color(0xFFF8F8FF); // Near white
  static const Color darkTextSecondaryColor = Color(0xFFB3B3B3);
  static const Color darkErrorColor = Color(0xFFEF5350);
  static const Color darkSuccessColor = Color(0xFF06D6A0);
  static const Color darkWarningColor = Color(0xFFFFB74D);

  // Gradients
  static const LinearGradient gradientBlue = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientGreen = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientPurple = LinearGradient(
            colors: [Color(0xFF6B2B6B), Color(0xFF6B2B6B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientOrange = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Dark Gradients
  static const LinearGradient darkGradientBlue = LinearGradient(
    colors: [Color(0xFF64B5F6), Color(0xFF42A5F5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradientGreen = LinearGradient(
    colors: [Color(0xFF66BB6A), Color(0xFF81C784)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradientPurple = LinearGradient(
    colors: [Color(0xFFBA68C8), Color(0xFFF06292)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradientOrange = LinearGradient(
    colors: [Color(0xFFFFB74D), Color(0xFFFF8A65)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Text Styles
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: primaryText,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: primaryText,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: primaryText,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    color: primaryText,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    color: primaryText,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    color: secondaryText,
  );

  // Dark Text Styles
  static const TextStyle darkHeadlineLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    color: darkTextPrimaryColor,
    fontFamily: 'Poppins',
    letterSpacing: 0.5,
  );
  static const TextStyle darkHeadlineMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: darkTextPrimaryColor,
    fontFamily: 'Poppins',
    letterSpacing: 0.2,
  );
  static const TextStyle darkTitleLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: darkTextPrimaryColor,
    fontFamily: 'Poppins',
  );
  static const TextStyle darkBodyLarge = TextStyle(
    fontSize: 16,
    color: darkTextPrimaryColor,
    fontFamily: 'Poppins',
  );
  static const TextStyle darkBodyMedium = TextStyle(
    fontSize: 14,
    color: darkTextPrimaryColor,
    fontFamily: 'Poppins',
  );
  static const TextStyle darkBodySmall = TextStyle(
    fontSize: 12,
    color: darkTextSecondaryColor,
    fontFamily: 'Poppins',
  );

  // Theme Data
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: cryptoButton,
      scaffoldBackgroundColor: mainBackground,
      fontFamily: GoogleFonts.poppins().fontFamily,
      appBarTheme: const AppBarTheme(
        backgroundColor: cardBackground,
        elevation: 2,
        shadowColor: borderShadow,
        iconTheme: IconThemeData(color: primaryText),
        titleTextStyle: TextStyle(
          color: primaryText,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        color: cardBackground,
        shadowColor: borderShadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: quickAddButton,
          foregroundColor: quickAddText,
          elevation: 4,
          shadowColor: borderShadow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: cryptoButton,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderShadow),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderShadow),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: cryptoButton, width: 2),
        ),
        labelStyle: const TextStyle(color: secondaryText),
        hintStyle: const TextStyle(color: secondaryText),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: primaryText),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryText),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: primaryText),
        bodyLarge: TextStyle(fontSize: 16, color: primaryText),
        bodyMedium: TextStyle(fontSize: 14, color: primaryText),
        bodySmall: TextStyle(fontSize: 12, color: secondaryText),
      ),
      colorScheme: const ColorScheme.light(
        primary: cryptoButton,
        secondary: stocksButton,
        surface: cardBackground,
        background: mainBackground,
        error: lineSolo,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: primaryText,
        onBackground: primaryText,
        onError: Colors.white,
      ),
      iconTheme: const IconThemeData(
        color: primaryText,
        size: 24,
      ),
      dividerTheme: const DividerThemeData(
        color: borderShadow,
        thickness: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: mainBackground,
        selectedColor: cryptoButton,
        labelStyle: const TextStyle(color: primaryText),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: darkPrimaryColor,
      scaffoldBackgroundColor: darkBackgroundColor,
      fontFamily: GoogleFonts.poppins().fontFamily,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurfaceColor,
        elevation: 0,
        iconTheme: IconThemeData(color: darkAccentColor),
        titleTextStyle: TextStyle(
          color: darkTextPrimaryColor,
          fontSize: 22,
          fontWeight: FontWeight.w900,
          fontFamily: 'Poppins',
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 8,
        color: darkSurfaceColor,
        shadowColor: Color(0xFF000000).withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkAccentColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 28,
            vertical: 16,
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: darkHeadlineLarge,
        headlineMedium: darkHeadlineMedium,
        titleLarge: darkTitleLarge,
        bodyLarge: darkBodyLarge,
        bodyMedium: darkBodyMedium,
        bodySmall: darkBodySmall,
      ),
      colorScheme: const ColorScheme.dark(
        primary: darkPrimaryColor,
        secondary: darkSecondaryColor,
        surface: darkSurfaceColor,
        error: darkErrorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: darkTextPrimaryColor,
        onError: Colors.white,
      ),
    );
  }
} 