import 'package:flutter/material.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';
import 'package:ramadan_tracker/widgets/app_back_button.dart';
import 'package:ramadan_tracker/widgets/app_surface.dart';

/// Compact brand mark (e.g. language step).
class OnboardingBrandMark extends StatelessWidget {
  final double size;

  const OnboardingBrandMark({super.key, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size + 12,
      height: size + 12,
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(size * 0.32),
        border: Border.all(color: AppSurface.borderColor(context)),
      ),
      child: Icon(
        Icons.nights_stay_rounded,
        size: size,
        color: scheme.primary,
      ),
    );
  }
}

/// Brand mark used across language pick + onboarding steps.
class OnboardingBrandHero extends StatelessWidget {
  final String title;
  final String? subtitle;
  final double iconSize;

  const OnboardingBrandHero({
    super.key,
    required this.title,
    this.subtitle,
    this.iconSize = 36,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: scheme.secondaryContainer.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppSurface.borderColor(context)),
          ),
          child: Icon(
            Icons.nights_stay_rounded,
            size: iconSize,
            color: scheme.primary,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.6),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class OnboardingStepBadge extends StatelessWidget {
  final String label;

  const OnboardingStepBadge({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: scheme.onPrimaryContainer,
            ),
      ),
    );
  }
}

class OnboardingStepDots extends StatelessWidget {
  final int current;
  final int total;

  const OnboardingStepDots({
    super.key,
    required this.current,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (index) {
        final active = index == current;
        final done = index < current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: EdgeInsets.only(right: index < total - 1 ? 6 : 0),
          width: active ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: active || done
                ? scheme.primary
                : scheme.surfaceContainerHighest,
          ),
        );
      }),
    );
  }
}

class OnboardingValueRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const OnboardingValueRow({
    super.key,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: scheme.primaryContainer.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: scheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      ],
    );
  }
}

class OnboardingFeatureSurface extends StatelessWidget {
  final IconData icon;
  final String text;

  const OnboardingFeatureSurface({
    super.key,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppSurface(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: scheme.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tappable EN / ID row for onboarding step 1 (language).
class OnboardingLanguageOptionCard extends StatelessWidget {
  final String code;
  final String label;
  final String hint;
  final bool selected;
  final VoidCallback onTap;

  const OnboardingLanguageOptionCard({
    super.key,
    required this.code,
    required this.label,
    required this.hint,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: selected
          ? scheme.primaryContainer.withValues(alpha: 0.35)
          : scheme.surface,
      borderRadius: BorderRadius.circular(AppSurface.radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSurface.radius),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSurface.radius),
            border: Border.all(
              color: selected
                  ? scheme.primary
                  : AppSurface.borderColor(context),
              width: selected ? 2 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: scheme.secondaryContainer.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    code,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.onSecondaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hint,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.58),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected ? Icons.check_circle : Icons.arrow_forward_rounded,
                  color: scheme.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Top bar for the 9-step onboarding flow.
class OnboardingFlowHeader extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final VoidCallback? onBack;
  final VoidCallback? onSkip;
  final String? skipLabel;

  const OnboardingFlowHeader({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.onBack,
    this.onSkip,
    this.skipLabel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final showSkip = onSkip != null && skipLabel != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Column(
        children: [
          Row(
            children: [
              if (onBack != null)
                AppBackButton(onPressed: onBack)
              else
                const SizedBox(width: 48),
              Expanded(
                child: Text(
                  l10n.onboardingStepProgress(currentStep + 1, totalSteps),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              if (showSkip)
                TextButton(onPressed: onSkip, child: Text(skipLabel!))
              else
                const SizedBox(width: 88),
            ],
          ),
          const SizedBox(height: 8),
          OnboardingStepDots(current: currentStep, total: totalSteps),
        ],
      ),
    );
  }
}
