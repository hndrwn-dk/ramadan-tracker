import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryDarkGreen = Color(0xFF1B5E20);
  static const Color backgroundDarkGreen = Color(0xFF0D2818);
  static const Color cardBackground = Color(0xFF1B3A1F);
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color textPrimary = Color(0xFFE8F5E9);
  static const Color textSecondary = Color(0xFFA5D6A7);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryDarkGreen,
      scaffoldBackgroundColor: backgroundDarkGreen,
      colorScheme: const ColorScheme.dark(
        primary: accentGreen,
        secondary: accentGreen,
        surface: cardBackground,
        background: backgroundDarkGreen,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onBackground: textPrimary,
      ),
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundDarkGreen,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: textPrimary, fontSize: 32, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: textPrimary, fontSize: 28, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(color: textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: textPrimary, fontSize: 20, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: textPrimary, fontSize: 16),
        bodyMedium: TextStyle(color: textSecondary, fontSize: 14),
        bodySmall: TextStyle(color: textSecondary, fontSize: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentGreen, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryDarkGreen,
      scaffoldBackgroundColor: const Color(0xFFF1F8F4),
      colorScheme: const ColorScheme.light(
        primary: primaryDarkGreen,
        secondary: accentGreen,
        surface: Colors.white,
        background: Color(0xFFF1F8F4),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFF1B5E20),
        onBackground: Color(0xFF1B5E20),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFFF1F8F4),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          color: Color(0xFF1B5E20),
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1B5E20)),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: Color(0xFF1B5E20), fontSize: 32, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: Color(0xFF1B5E20), fontSize: 28, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(color: Color(0xFF1B5E20), fontSize: 24, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: Color(0xFF1B5E20), fontSize: 20, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: Color(0xFF1B5E20), fontSize: 18, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: Color(0xFF1B5E20), fontSize: 16, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: Color(0xFF1B5E20), fontSize: 16),
        bodyMedium: TextStyle(color: Color(0xFF4A5568), fontSize: 14),
        bodySmall: TextStyle(color: Color(0xFF718096), fontSize: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryDarkGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryDarkGreen, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  static ThemeData lightThemeWithDynamic(ColorScheme? dynamicColorScheme) {
    // Use the provided colorScheme directly, or fallback to neutral if null
    final colorScheme = dynamicColorScheme ??
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4), // Neutral purple to avoid green flash
          brightness: Brightness.light,
        );
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(color: colorScheme.onSurface, fontSize: 32, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: colorScheme.onSurface, fontSize: 28, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(color: colorScheme.onSurface, fontSize: 24, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: colorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: colorScheme.onSurface, fontSize: 16),
        bodyMedium: TextStyle(color: colorScheme.onSurface.withOpacity(0.7), fontSize: 14),
        bodySmall: TextStyle(color: colorScheme.onSurface.withOpacity(0.6), fontSize: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  static ThemeData darkThemeWithDynamic(ColorScheme? dynamicColorScheme) {
    // Use the provided colorScheme directly, or fallback to neutral if null
    final colorScheme = dynamicColorScheme ??
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4), // Neutral purple to avoid green flash
          brightness: Brightness.dark,
        );
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(color: colorScheme.onSurface, fontSize: 32, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: colorScheme.onSurface, fontSize: 28, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(color: colorScheme.onSurface, fontSize: 24, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: colorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: colorScheme.onSurface, fontSize: 16),
        bodyMedium: TextStyle(color: colorScheme.onSurface.withOpacity(0.7), fontSize: 14),
        bodySmall: TextStyle(color: colorScheme.onSurface.withOpacity(0.6), fontSize: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}

