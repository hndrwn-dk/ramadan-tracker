import 'package:flutter/material.dart';
import 'package:ramadan_tracker/widgets/app_colors.dart';

class AppTheme {
  static ColorScheme get _lightScheme {
    return ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.primaryBright,
      onSecondary: AppColors.neutralDeep,
      tertiary: AppColors.accent,
      onTertiary: AppColors.neutralDeep,
      surface: AppColors.neutralSoft,
      onSurface: AppColors.neutralDeep,
      error: AppColors.danger,
      onError: Colors.white,
      outline: AppColors.neutralDeep.withValues(alpha: 0.28),
    );
  }

  static ColorScheme get _darkScheme {
    return ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.primaryBright,
      onSecondary: AppColors.neutralDeep,
      tertiary: AppColors.accent,
      onTertiary: AppColors.neutralDeep,
      surface: AppColors.neutralDeep,
      onSurface: AppColors.neutralSoft,
      error: AppColors.danger,
      onError: Colors.white,
      outline: AppColors.neutralSoft.withValues(alpha: 0.28),
    );
  }

  static ThemeData get lightTheme {
    final colorScheme = _lightScheme;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.neutralSoft,
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.neutralSoft,
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
        bodyMedium: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 14),
        bodySmall: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12),
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
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = _darkScheme;
    final cardColor = Color.alphaBlend(
      colorScheme.primary.withValues(alpha: 0.12),
      colorScheme.surface,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.neutralDeep,
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: colorScheme.onSurface.withValues(alpha: 0.22),
            width: 1,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.neutralDeep,
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
        bodyMedium: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 14),
        bodySmall: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12),
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
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
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
