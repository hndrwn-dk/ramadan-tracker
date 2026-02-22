import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Tahajud habit icon (sujood). Use this instead of Icons.self_improvement for Tahajud.
class TahajudIcon extends StatelessWidget {
  const TahajudIcon({
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
      'assets/icons/tahajud.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(effectiveColor, BlendMode.srcIn),
    );
  }
}
