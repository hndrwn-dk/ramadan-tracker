import 'dart:ui';

import 'package:flutter/material.dart';

class FloatingPillNavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const FloatingPillNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

/// Shared glass surface for the floating pill and the checklist card above it.
class FloatingGlassPanel extends StatelessWidget {
  final double height;
  final double radius;
  final Widget child;

  const FloatingGlassPanel({
    super.key,
    required this.height,
    required this.radius,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillAlpha = isDark ? 0.72 : 0.80;
    final farShadow = isDark ? 0.40 : 0.16;
    final nearShadow = isDark ? 0.24 : 0.08;

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: farShadow),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: scheme.shadow.withValues(alpha: nearShadow),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surface.withValues(alpha: fillAlpha),
              border: Border.all(
                color: scheme.onSurface.withValues(alpha: 0.10),
              ),
              borderRadius: BorderRadius.circular(radius),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class FloatingPillNavBar extends StatelessWidget {
  final List<FloatingPillNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const FloatingPillNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  static const double barHeight = 64;
  static const double bottomGap = 20;
  static const double horizontalMargin = 16;
  static const double maxBarWidth = 480;
  static const double accessoryHeight = 60;
  static const double accessoryGap = 8;
  static const double contentBreathingRoom = 12;

  /// Space the floating stack occupies, including the system inset.
  static double reservedHeight(
    BuildContext context, {
    bool withAccessory = false,
  }) {
    final inset = MediaQuery.viewPaddingOf(context).bottom;
    final accessory = withAccessory ? accessoryHeight + accessoryGap : 0.0;
    return barHeight + bottomGap + inset + accessory;
  }

  /// Bottom clearance for a tab root scroll view so the last item clears the stack.
  static EdgeInsets scrollPadding(
    BuildContext context, {
    EdgeInsets padding = EdgeInsets.zero,
    bool withAccessory = false,
  }) {
    final clearance =
        reservedHeight(context, withAccessory: withAccessory) +
        contentBreathingRoom;
    return padding.copyWith(bottom: padding.bottom + clearance);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return MediaQuery.withClampedTextScaling(
      minScaleFactor: 0,
      maxScaleFactor: 1.3,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          horizontalMargin,
          0,
          horizontalMargin,
          bottomGap + bottomInset,
        ),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: maxBarWidth),
            child: FloatingGlassPanel(
              height: barHeight,
              radius: 32,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return _FloatingPillNavItems(
                      items: items,
                      selectedIndex: selectedIndex,
                      maxWidth: constraints.maxWidth,
                      onSelected: onSelected,
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingPillNavItems extends StatelessWidget {
  final List<FloatingPillNavItem> items;
  final int selectedIndex;
  final double maxWidth;
  final ValueChanged<int> onSelected;

  const _FloatingPillNavItems({
    required this.items,
    required this.selectedIndex,
    required this.maxWidth,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    const gap = 2.0;
    const itemHeight = 52.0;
    const unselectedWidth = 52.0;
    final count = items.length;
    final gaps = count > 1 ? gap * (count - 1) : 0.0;
    final selectedWidth = count == 0
        ? 0.0
        : (maxWidth - gaps - unselectedWidth * (count - 1))
            .clamp(unselectedWidth, maxWidth);

    return Row(
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: gap),
          _FloatingPillNavButton(
            item: items[i],
            index: i,
            selected: i == selectedIndex,
            width: i == selectedIndex ? selectedWidth : unselectedWidth,
            height: itemHeight,
            onSelected: () => onSelected(i),
          ),
        ],
      ],
    );
  }
}

class _FloatingPillNavButton extends StatefulWidget {
  final FloatingPillNavItem item;
  final int index;
  final bool selected;
  final double width;
  final double height;
  final VoidCallback onSelected;

  const _FloatingPillNavButton({
    required this.item,
    required this.index,
    required this.selected,
    required this.width,
    required this.height,
    required this.onSelected,
  });

  @override
  State<_FloatingPillNavButton> createState() => _FloatingPillNavButtonState();
}

class _FloatingPillNavButtonState extends State<_FloatingPillNavButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selected = widget.selected;
    final foreground =
        selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;

    Widget visual = IconTheme(
      data: IconThemeData(color: foreground, size: 22),
      child: DefaultTextStyle(
        style: TextStyle(
          color: foreground,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(selected ? widget.item.selectedIcon : widget.item.icon),
              Flexible(
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  alignment: AlignmentDirectional.centerStart,
                  child: selected
                      ? Padding(
                          padding: const EdgeInsetsDirectional.only(start: 6),
                          child: Text(
                            widget.item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!selected) {
      visual = Tooltip(message: widget.item.label, child: visual);
    }

    return Semantics(
      button: true,
      selected: selected,
      label: widget.item.label,
      child: GestureDetector(
        key: ValueKey('floating-pill-nav-${widget.index}'),
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onSelected,
        child: AnimatedScale(
          scale: _pressed ? 0.94 : 1,
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            width: widget.width,
            height: widget.height,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? scheme.primaryContainer : Colors.transparent,
              borderRadius: BorderRadius.circular(26),
            ),
            child: visual,
          ),
        ),
      ),
    );
  }
}
