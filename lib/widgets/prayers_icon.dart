import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 5 Prayers habit icon (ruku). Use this instead of Icons.mosque for 5 Prayers.
class PrayersIcon extends StatelessWidget {
  const PrayersIcon({
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
      'assets/icons/prayers.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(effectiveColor, BlendMode.srcIn),
    );
  }
}
