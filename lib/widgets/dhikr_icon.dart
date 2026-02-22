import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Dhikr habit icon (tasbih). Use this instead of Icons.favorite for Dhikr.
class DhikrIcon extends StatelessWidget {
  const DhikrIcon({
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
      'assets/icons/dhikr.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(effectiveColor, BlendMode.srcIn),
    );
  }
}
