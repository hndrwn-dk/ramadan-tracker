import 'package:flutter/material.dart';
import 'package:ramadan_tracker/widgets/app_surface.dart';

/// Workout-style habit card shell for the Today checklist (collapsed / expanded).
class ChecklistHabitCard extends StatelessWidget {
  final Widget leadingIcon;
  final Widget? trailingAction;
  final String title;
  final String subtitle;
  final bool expanded;
  final bool showExpandHint;
  final bool showOptionsHint;
  final double? progress;
  final Widget? expandedChild;
  final VoidCallback onTap;
  final VoidCallback? onActionTap;
  final VoidCallback? onLongPress;

  const ChecklistHabitCard({
    super.key,
    required this.leadingIcon,
    this.trailingAction,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.expanded = false,
    this.showExpandHint = false,
    this.showOptionsHint = false,
    this.progress,
    this.expandedChild,
    this.onActionTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final borderColor =
        expanded ? scheme.primary.withValues(alpha: 0.4) : AppSurface.borderColor(context);
    final hasTrailingControls =
        showOptionsHint || showExpandHint || trailingAction != null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: AppSurface.nestedDecoration(
        context,
        color: AppSurface.fillColor(context),
        borderRadius: 16,
      ).copyWith(
        border: Border.all(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              onLongPress: onLongPress,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    leadingIcon,
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    if (subtitle.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        subtitle,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: scheme.onSurface.withValues(alpha: 0.65),
                                            ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (hasTrailingControls) ...[
                                const SizedBox(width: 8),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (showOptionsHint) ...[
                                      const ChecklistOptionsHint(),
                                      const SizedBox(width: 6),
                                    ],
                                    if (showExpandHint) ...[
                                      AnimatedRotation(
                                        turns: expanded ? 0.5 : 0,
                                        duration: const Duration(milliseconds: 200),
                                        child: Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          size: 20,
                                          color: scheme.onSurface.withValues(alpha: 0.45),
                                        ),
                                      ),
                                      if (trailingAction != null) const SizedBox(width: 6),
                                    ],
                                    if (trailingAction != null)
                                      _ActionTapTarget(
                                        onTap: onActionTap,
                                        child: trailingAction!,
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                          if (progress != null) ...[
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: progress!.clamp(0.0, 1.0),
                                minHeight: 4,
                                backgroundColor: scheme.surfaceContainerHighest,
                                color: scheme.primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          ClipRect(
            child: AnimatedAlign(
              alignment: Alignment.topCenter,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOutCubic,
              heightFactor: expanded && expandedChild != null ? 1.0 : 0.0,
              child: expandedChild == null
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Divider(
                            height: 1,
                            color: scheme.outlineVariant.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 12),
                          expandedChild!,
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Stops action taps from bubbling to the card header [InkWell].
class _ActionTapTarget extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;

  const _ActionTapTarget({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    if (onTap == null) return child;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.deferToChild,
      child: child,
    );
  }
}

/// Colored square habit icon.
class ChecklistHabitIcon extends StatelessWidget {
  final Widget child;
  final Color accent;

  const ChecklistHabitIcon({
    super.key,
    required this.child,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}

/// Trailing action: filled check for done toggles.
class ChecklistToggleAction extends StatelessWidget {
  final bool done;

  const ChecklistToggleAction({super.key, required this.done});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: done ? scheme.primary : Colors.transparent,
        shape: BoxShape.circle,
        border: done ? null : Border.all(color: AppSurface.borderColor(context), width: 2),
      ),
      alignment: Alignment.center,
      child: Icon(
        done ? Icons.check_rounded : Icons.circle,
        size: 18,
        color: done ? scheme.onPrimary : Colors.transparent,
      ),
    );
  }
}

/// Trailing action: numeric or fraction readout (Quran pages, dhikr, prayers).
class ChecklistValueAction extends StatelessWidget {
  final String label;

  const ChecklistValueAction({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 40),
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppSurface.fillColor(context),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppSurface.borderColor(context)),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Muted ··· hint for habits with extra options (fasting uzur).
class ChecklistOptionsHint extends StatelessWidget {
  const ChecklistOptionsHint({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      '···',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 14,
            color: scheme.onSurface.withValues(alpha: 0.45),
            letterSpacing: 1,
          ),
    );
  }
}

/// Trailing edit icon for input habits (sedekah).
class ChecklistEditAction extends StatelessWidget {
  final VoidCallback? onTap;

  const ChecklistEditAction({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _ActionTapTarget(
      onTap: onTap,
      child: Icon(
        Icons.edit_outlined,
        size: 20,
        color: scheme.onSurface.withValues(alpha: 0.55),
      ),
    );
  }
}

/// Trailing action: fasting status indicator.
class ChecklistStatusAction extends StatelessWidget {
  final bool resolved;

  const ChecklistStatusAction({super.key, required this.resolved});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (resolved) {
      return const ChecklistToggleAction(done: true);
    }
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppSurface.fillColor(context),
        shape: BoxShape.circle,
        border: Border.all(color: AppSurface.borderColor(context)),
      ),
      alignment: Alignment.center,
      child: Icon(Icons.more_horiz_rounded, color: scheme.onSurface.withValues(alpha: 0.55)),
    );
  }
}
