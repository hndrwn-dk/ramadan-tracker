import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ramadan_tracker/widgets/app_colors.dart';
import 'package:ramadan_tracker/widgets/app_surface.dart';
import 'package:ramadan_tracker/widgets/theme.dart';

void main() {
  group('AppColors', () {
    test('locks Mediterranean Teal B-mature swatches', () {
      expect(AppColors.neutralDeep, const Color(0xFF264653));
      expect(AppColors.neutralSoft, const Color(0xFFF2F5F4));
      expect(AppColors.lightWash, const Color(0xFFDAECE9));
      expect(AppColors.lightMist, const Color(0xFFDDE6E4));
      expect(AppColors.primary, const Color(0xFF2A9D8F));
      expect(AppColors.primaryBright, const Color(0xFFE9C46A));
      expect(AppColors.accent, const Color(0xFFF4A261));
    });
  });

  group('AppTheme brand schemes', () {
    test('light theme uses cool paper and soft teal containers', () {
      final theme = AppTheme.lightTheme;
      final scheme = theme.colorScheme;
      expect(theme.brightness, Brightness.light);
      expect(scheme.primary, AppColors.primary);
      expect(scheme.secondary, AppColors.primaryBright);
      expect(scheme.tertiary, AppColors.accent);
      expect(scheme.surface, AppColors.neutralSoft);
      expect(theme.scaffoldBackgroundColor, AppColors.neutralSoft);
      expect(scheme.onSurface, AppColors.neutralDeep);
      expect(scheme.primaryContainer, AppColors.primary);
      expect(scheme.onPrimaryContainer, Colors.white);
      expect(scheme.secondaryContainer, AppColors.lightWash);
      expect(scheme.onSecondaryContainer, AppColors.neutralDeep);
      expect(scheme.tertiaryContainer, AppColors.lightMist);
      expect(scheme.onTertiaryContainer, AppColors.neutralDeep);
      expect(scheme.surfaceContainerLowest, Colors.white);
      expect(scheme.surfaceContainerHighest, AppColors.lightMist);
    });

    testWidgets('light cards are white on the cool page', (tester) async {
      late Color fill;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Builder(
            builder: (context) {
              fill = AppSurface.fillColor(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(fill, Colors.white);
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
