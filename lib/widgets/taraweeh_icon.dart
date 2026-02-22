import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Taraweeh habit icon (salah time). Use this instead of Icons.nights_stay for Taraweeh.
class TaraweehIcon extends StatelessWidget {
  const TaraweehIcon({
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
      'assets/icons/taraweeh.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(effectiveColor, BlendMode.srcIn),
    );
  }
}
