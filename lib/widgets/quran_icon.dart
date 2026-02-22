import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Quran habit icon (open book with star). Use this instead of Icons.menu_book for Quran.
class QuranIcon extends StatelessWidget {
  const QuranIcon({
    super.key,
    this.size = 24,
    this.color,
  });

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? IconTheme.of(context).color ?? const Color(0xFF000000);
    return SvgPicture.asset(
      'assets/icons/quran.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(effectiveColor, BlendMode.srcIn),
    );
  }
}
