import 'package:flutter/material.dart';

/// Coolors (source): https://coolors.co/palette/264653-2a9d8f-e9c46a-f4a261-e76f51
/// Coolors (B-mature 5): https://coolors.co/264653-f7f1e3-2a9d8f-e9c46a-f4a261
///
/// 60% neutrals · 30% primary · 10% accent
///
/// | Share | Token | Hex |
/// |------:|-------|-----|
/// | 60% | neutralDeep | #264653 |
/// | 60% | neutralSoft | #F7F1E3 |
/// | 30% | primary | #2A9D8F |
/// | 30% | primaryBright | #E9C46A |
/// | 10% | accent | #F4A261 |
///
/// Light ground = neutralSoft; Dark ground = neutralDeep.
/// Coral #E76F51 is semantic error only — not a brand swatch.
abstract final class AppColors {
  // 60%
  static const Color neutralDeep = Color(0xFF264653);
  static const Color neutralSoft = Color(0xFFF7F1E3);

  // 30%
  static const Color primary = Color(0xFF2A9D8F);
  static const Color primaryBright = Color(0xFFE9C46A);

  // 10%
  static const Color accent = Color(0xFFF4A261);

  /// Semantic outlier from Coolors source; not used as brand accent.
  static const Color danger = Color(0xFFE76F51);
}
