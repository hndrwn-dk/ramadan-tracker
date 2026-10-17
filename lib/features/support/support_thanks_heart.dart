import 'package:flutter/material.dart';

/// One-time thanks pop. Holds the final frame when animations are disabled.
class SupportThanksHeart extends StatefulWidget {
  const SupportThanksHeart({super.key});

  @override
  State<SupportThanksHeart> createState() => _SupportThanksHeartState();
}

class _SupportThanksHeartState extends State<SupportThanksHeart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;
  var _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.6, end: 1.08).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 65,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.08, end: 1).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 35,
      ),
    ]).animate(_controller);
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tint = colorScheme.brightness == Brightness.dark ? 0.28 : 0.16;
    return FadeTransition(
      opacity: _opacity,
      child: ScaleTransition(
        scale: _scale,
        child: SizedBox(
          width: 72,
          height: 72,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Color.alphaBlend(
                colorScheme.primary.withValues(alpha: tint),
                colorScheme.surface,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.favorite_rounded,
              size: 36,
              color: colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}
