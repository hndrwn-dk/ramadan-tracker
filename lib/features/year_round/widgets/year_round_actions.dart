import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/features/sunnah/sunnah_strings.dart';
import 'package:ramadan_tracker/features/year_round/year_round_navigation.dart';
import 'package:ramadan_tracker/features/year_round/widgets/pre_ramadan_banner.dart';
import 'package:ramadan_tracker/utils/ramadan_dates.dart';

/// Shared CTAs for no-season and post-Ramadan flows.
class YearRoundActions extends ConsumerWidget {
  final bool compact;

  const YearRoundActions({super.key, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = SunnahStrings.of(context);
    final scheme = Theme.of(context).colorScheme;
    final daysUntil = RamadanDates.daysUntilNext(DateTime.now());
    final ramadanNear = daysUntil != null && daysUntil <= 45;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!compact)
          Text(
            s.yearRoundIntro,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.7),
                ),
          ),
        if (!compact) const SizedBox(height: 16),
        if (ramadanNear) ...[
          _RamadanNearCard(daysUntil: daysUntil!),
          const SizedBox(height: 16),
        ],
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => YearRoundNavigation.openSunnahTab(ref),
            icon: const Icon(Icons.nightlight_round),
            label: Text(s.sunnahTitle),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => YearRoundNavigation.openCreateSeason(context),
            icon: const Icon(Icons.add),
            label: Text(s.createRamadanSeason),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}

class _RamadanNearCard extends ConsumerWidget {
  final int daysUntil;

  const _RamadanNearCard({required this.daysUntil});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = SunnahStrings.of(context);
    final scheme = Theme.of(context).colorScheme;
    final msg = daysUntil <= 0
        ? s.ramadanIsHere
        : s.ramadanCountdown(daysUntil);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.primaryContainer],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.celebration, color: scheme.onPrimary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  msg,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: scheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            s.ramadanNearSetupHint,
            style: TextStyle(color: scheme.onPrimary.withValues(alpha: 0.9)),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: () => YearRoundNavigation.openCreateSeason(context),
              style: FilledButton.styleFrom(
                foregroundColor: scheme.onPrimary,
                backgroundColor: scheme.onPrimary.withValues(alpha: 0.15),
              ),
              child: Text(s.setupRamadanSeason),
            ),
          ),
        ],
      ),
    );
  }
}

/// Header block for screens with no Ramadan season configured.
class YearRoundNoSeasonBody extends ConsumerWidget {
  const YearRoundNoSeasonBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = SunnahStrings.of(context);
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 8),
        Icon(
          Icons.nightlight_round,
          size: 56,
          color: scheme.primary.withValues(alpha: 0.6),
        ),
        const SizedBox(height: 16),
        Text(
          s.yearRoundModeTitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          s.yearRoundIntro,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.7),
              ),
        ),
        const SizedBox(height: 24),
        const YearRoundActions(compact: true),
      ],
    );
  }
}

/// Plan tab empty state when no Ramadan season exists (not the Home year-round view).
class PlanNoSeasonBody extends ConsumerWidget {
  const PlanNoSeasonBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 8),
        Center(
          child: Icon(
            Icons.auto_awesome,
            size: 56,
            color: scheme.primary.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 24),
        const RamadanCountdownCard(),
      ],
    );
  }
}
