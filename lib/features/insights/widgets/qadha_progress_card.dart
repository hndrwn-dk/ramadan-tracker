import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/providers/qadha_provider.dart';
import 'package:ramadan_tracker/features/qadha/qadha_screen.dart';
import 'package:ramadan_tracker/features/sunnah/sunnah_strings.dart';
import 'package:ramadan_tracker/insights/widgets/premium_card.dart';

/// Year-round qadha owed vs made-up progress.
class QadhaProgressCard extends ConsumerWidget {
  const QadhaProgressCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = SunnahStrings.of(context);
    final balanceAsync = ref.watch(qadhaBalanceProvider);
    final scheme = Theme.of(context).colorScheme;

    return balanceAsync.when(
      data: (balance) {
        if (balance.qadhaOwed <= 0 && balance.qadhaPaid <= 0) {
          return const SizedBox.shrink();
        }

        final owed = balance.qadhaOwed;
        final paid = balance.qadhaPaid.clamp(0, owed > 0 ? owed : balance.qadhaPaid);
        final remaining = balance.qadhaRemaining;
        final progress = owed > 0 ? (paid / owed).clamp(0.0, 1.0) : 1.0;

        return PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.event_repeat, size: 20, color: scheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.qadhaSection,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  backgroundColor: scheme.surfaceContainerHighest,
                  color: remaining == 0 ? Colors.green : scheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _metric(
                      context,
                      label: s.qadhaOwed,
                      value: '$owed ${s.daysUnit}',
                    ),
                  ),
                  Expanded(
                    child: _metric(
                      context,
                      label: s.qadhaPaid,
                      value: '$paid ${s.daysUnit}',
                    ),
                  ),
                  Expanded(
                    child: _metric(
                      context,
                      label: s.qadhaRemaining,
                      value: '$remaining ${s.daysUnit}',
                      highlight: remaining > 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const QadhaScreen()),
                    );
                  },
                  child: Text(s.viewObligationsDetails),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _metric(
    BuildContext context, {
    required String label,
    required String value,
    bool highlight = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: highlight ? scheme.primary : null,
              ),
        ),
      ],
    );
  }
}
