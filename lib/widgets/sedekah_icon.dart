import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Sedekah (alms) habit icon. Use this instead of Icons.volunteer_activism for Sedekah.
class SedekahIcon extends StatelessWidget {
  const SedekahIcon({
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
      'assets/icons/sedekah.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(effectiveColor, BlendMode.srcIn),
    );
  }
}
