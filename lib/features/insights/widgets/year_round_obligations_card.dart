import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/providers/qadha_provider.dart';
import 'package:ramadan_tracker/features/qadha/qadha_screen.dart';
import 'package:ramadan_tracker/features/sunnah/sunnah_strings.dart';
import 'package:ramadan_tracker/insights/widgets/premium_card.dart';
import 'package:ramadan_tracker/utils/sedekah_utils.dart';

/// Zakat & Fidyah summary for year-round Wawasan (all-time ledger).
class YearRoundObligationsCard extends ConsumerWidget {
  const YearRoundObligationsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = SunnahStrings.of(context);
    final balanceAsync = ref.watch(qadhaBalanceProvider);
    final scheme = Theme.of(context).colorScheme;

    return balanceAsync.when(
      data: (balance) {
        final zakatMap = balance.zakatPaidByCurrency;
        final fidyahMap = balance.fidyahPaidByCurrency;
        if (zakatMap.isEmpty && fidyahMap.isEmpty && balance.fidyahDays <= 0) {
          return const SizedBox.shrink();
        }

        final currency = zakatMap.keys.firstOrNull ??
            fidyahMap.keys.firstOrNull ??
            'IDR';
        final zakatTotal = zakatMap[currency] ?? 0;
        final fidyahTotal = fidyahMap[currency] ?? 0;

        return PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.volunteer_activism,
                      size: 20, color: scheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.obligationsSubtitleYearRound,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _metric(
                      context,
                      label: s.zakatPaidStat,
                      value: zakatTotal > 0
                          ? SedekahUtils.formatCurrency(
                              zakatTotal.toDouble(), currency)
                          : '-',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _metric(
                      context,
                      label: s.fidyahPaidStat,
                      value: fidyahTotal > 0
                          ? SedekahUtils.formatCurrency(
                              fidyahTotal.toDouble(), currency)
                          : '-',
                    ),
                  ),
                ],
              ),
              if (balance.fidyahDays > 0) ...[
                const SizedBox(height: 8),
                Text(
                  '${balance.fidyahDays} ${s.daysUnit} · ${s.fidyahTitle}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.7),
                      ),
                ),
              ],
              const SizedBox(height: 8),
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}
