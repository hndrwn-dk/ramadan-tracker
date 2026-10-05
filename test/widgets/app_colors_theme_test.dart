import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ramadan_tracker/widgets/app_colors.dart';
import 'package:ramadan_tracker/widgets/theme.dart';

void main() {
  group('AppColors', () {
    test('locks Mediterranean Teal B-mature swatches', () {
      expect(AppColors.neutralDeep, const Color(0xFF264653));
      expect(AppColors.neutralSoft, const Color(0xFFF7F1E3));
      expect(AppColors.primary, const Color(0xFF2A9D8F));
      expect(AppColors.primaryBright, const Color(0xFFE9C46A));
      expect(AppColors.accent, const Color(0xFFF4A261));
    });
  });

  group('AppTheme brand schemes', () {
    test('light theme uses cream ground and teal primary', () {
      final theme = AppTheme.lightTheme;
      expect(theme.brightness, Brightness.light);
      expect(theme.colorScheme.primary, AppColors.primary);
      expect(theme.colorScheme.secondary, AppColors.primaryBright);
      expect(theme.colorScheme.tertiary, AppColors.accent);
      expect(theme.colorScheme.surface, AppColors.neutralSoft);
      expect(theme.scaffoldBackgroundColor, AppColors.neutralSoft);
      expect(theme.colorScheme.onSurface, AppColors.neutralDeep);
    });

    test('dark theme uses charcoal teal ground and teal primary', () {
      final theme = AppTheme.darkTheme;
      expect(theme.brightness, Brightness.dark);
      expect(theme.colorScheme.primary, AppColors.primary);
      expect(theme.colorScheme.secondary, AppColors.primaryBright);
      expect(theme.colorScheme.tertiary, AppColors.accent);
      expect(theme.colorScheme.surface, AppColors.neutralDeep);
      expect(theme.scaffoldBackgroundColor, AppColors.neutralDeep);
      expect(theme.colorScheme.onSurface, AppColors.neutralSoft);
    });
  });
}
