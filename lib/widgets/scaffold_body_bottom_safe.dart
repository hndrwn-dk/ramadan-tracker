import 'package:flutter/material.dart';

/// Bottom system-bar inset only for pushed [Scaffold] bodies that already have
/// an [AppBar] (top inset handled). Avoids double-padding under the shell
/// [SafeArea] when those screens are not used as tab roots.
class ScaffoldBodyBottomSafe extends StatelessWidget {
  const ScaffoldBodyBottomSafe({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      left: false,
      right: false,
      child: child,
    );
  }
}
