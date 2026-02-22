import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Itikaf habit icon (person in prayer). Use this instead of Icons.mosque for Itikaf.
class ItikafIcon extends StatelessWidget {
  const ItikafIcon({
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
      'assets/icons/itikaf.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(effectiveColor, BlendMode.srcIn),
    );
  }
}
