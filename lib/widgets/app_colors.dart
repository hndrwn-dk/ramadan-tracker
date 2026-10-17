import 'package:flutter/material.dart';

/// Coolors (source): https://coolors.co/palette/264653-2a9d8f-e9c46a-f4a261-e76f51
/// Coolors (B-mature 5): https://coolors.co/264653-f2f5f4-2a9d8f-e9c46a-f4a261
///
/// 60% neutrals · 30% primary · 10% accent
///
/// | Share | Token | Hex |
/// |------:|-------|-----|
/// | 60% | neutralDeep | #264653 |
/// | 60% | neutralSoft | #F2F5F4 |
/// | 30% | primary | #2A9D8F |
/// | 30% | primaryBright | #E9C46A |
/// | 10% | accent | #F4A261 |
///
/// Light ground = neutralSoft (cool paper). Dark ground = neutralDeep.
/// Dark on-surface text uses the same cool paper.
/// lightWash and lightMist are teal tints of that paper, not extra brand hues.
/// Gold and orange stay on secondary and tertiary for marks, not page fills.
/// Coral #E76F51 is semantic error only — not a brand swatch.
abstract final class AppColors {
  // 60%
  static const Color neutralDeep = Color(0xFF264653);
  static const Color neutralSoft = Color(0xFFF2F5F4);

  /// Selected tab pill and chips. Primary at low strength on the light paper.
  static const Color lightWash = Color(0xFFDAECE9);

  /// Inset tracks and the deeper end of soft gradients.
  static const Color lightMist = Color(0xFFDDE6E4);

  /// Sticky bars, a step above the page.
  static const Color lightLow = Color(0xFFF7F9F8);

  /// Raised neutral between the page and inset tracks.
  static const Color lightHigh = Color(0xFFE7EEEC);

  // 30%
  static const Color primary = Color(0xFF2A9D8F);
  static const Color primaryBright = Color(0xFFE9C46A);

  // 10%
  static const Color accent = Color(0xFFF4A261);

  /// Semantic outlier from Coolors source; not used as brand accent.
  static const Color danger = Color(0xFFE76F51);
}
