import 'package:flutter/material.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/domain/models/season_model.dart';
import 'package:ramadan_tracker/features/qadha/widgets/obligations_history_charts.dart';
import 'package:ramadan_tracker/features/sunnah/sunnah_strings.dart';
import 'package:ramadan_tracker/insights/widgets/premium_card.dart';
import 'package:ramadan_tracker/utils/obligations_utils.dart';
import 'package:ramadan_tracker/utils/sedekah_utils.dart';

class ObligationsHistorySection extends StatelessWidget {
  final List<QadhaLedgerData> entries;
  final Map<String, int> zakatByCurrency;
  final Map<String, int> fidyahByCurrency;
  final String? currency;
  final SeasonModel? season;
  final void Function(QadhaLedgerData entry) onDelete;

  const ObligationsHistorySection({
    super.key,
    required this.entries,
    required this.zakatByCurrency,
    required this.fidyahByCurrency,
    this.currency,
    this.season,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final s = SunnahStrings.of(context);
    final scheme = Theme.of(context).colorScheme;
    final monetary = entries
        .where((e) => e.kind == 'zakat' || e.kind == 'fidyah')
        .toList();
    final qadhaEntries =
        entries.where((e) => e.kind == 'qadha').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s.history, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        if (currency != null) ...[
          ObligationsHistoryCharts(
            entries: entries,
            currency: currency!,
            season: season,
          ),
          const SizedBox(height: 16),
        ] else if (zakatByCurrency.isNotEmpty || fidyahByCurrency.isNotEmpty)
          PremiumCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.paymentSummary,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
                if (zakatByCurrency.isNotEmpty) ...[
                  _summaryRow(
                    context,
                    icon: Icons.volunteer_activism,
                    color: scheme.primary,
                    title: s.zakatTitle,
                    amounts: zakatByCurrency,
                  ),
                  if (fidyahByCurrency.isNotEmpty) const SizedBox(height: 12),
                ],
                if (fidyahByCurrency.isNotEmpty)
                  _summaryRow(
                    context,
                    icon: Icons.payments_outlined,
                    color: scheme.secondary,
                    title: s.fidyahTitle,
                    amounts: fidyahByCurrency,
                  ),
              ],
            ),
          ),
        if (currency == null &&
            (zakatByCurrency.isNotEmpty || fidyahByCurrency.isNotEmpty))
          const SizedBox(height: 16),
        if (entries.isEmpty)
          PremiumCard(
            child: Row(
              children: [
                Icon(Icons.history, color: scheme.outline),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    s.noHistory,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.7),
                        ),
                  ),
                ),
              ],
            ),
          )
        else ...[
          if (monetary.isNotEmpty) ...[
            Text(
              s.paymentHistory,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.7),
                  ),
            ),
            const SizedBox(height: 8),
            ...monetary.map((e) => _paymentCard(context, s, e)),
            const SizedBox(height: 16),
          ],
          if (qadhaEntries.isNotEmpty) ...[
            Text(
              s.qadhaSection,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.7),
                  ),
            ),
            const SizedBox(height: 8),
            ...qadhaEntries.map((e) => _qadhaCard(context, s, e)),
          ],
        ],
      ],
    );
  }

  Widget _summaryRow(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required Map<String, int> amounts,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      )),
              const SizedBox(height: 4),
              ...amounts.entries.map(
                (e) => Text(
                  SedekahUtils.formatCurrency(e.value.toDouble(), e.key),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _paymentCard(
      BuildContext context, SunnahStrings s, QadhaLedgerData e) {
    final isZakat = e.kind == 'zakat';
    final currency =
        ObligationsUtils.parseCurrencyFromNote(e.note);
    final scheme = Theme.of(context).colorScheme;
    final title = isZakat
        ? '${s.zakatTitle} · ${e.days} ${s.peopleUnit}'
        : '${s.fidyahTitle} · ${e.days} ${s.daysUnit}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: ValueKey('obligation_${e.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          color: scheme.error,
          child: Icon(Icons.delete, color: scheme.onError),
        ),
        onDismissed: (_) => onDelete(e),
        child: PremiumCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: (isZakat ? scheme.primary : scheme.secondary)
                    .withValues(alpha: 0.15),
                child: Icon(
                  isZakat ? Icons.volunteer_activism : Icons.payments_outlined,
                  size: 18,
                  color: isZakat ? scheme.primary : scheme.secondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    Text(
                      ObligationsUtils.formatEntryDate(e.createdAt, s.id),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.6),
                          ),
                    ),
                  ],
                ),
              ),
              Text(
                SedekahUtils.formatCurrency(e.amount.toDouble(), currency),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: scheme.primary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _qadhaCard(BuildContext context, SunnahStrings s, QadhaLedgerData e) {
    final isPaid = e.direction == 'paid';
    final scheme = Theme.of(context).colorScheme;
    final label = isPaid ? s.qadhaPaid : s.qadhaOwed;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: ValueKey('qadha_${e.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          color: scheme.error,
          child: Icon(Icons.delete, color: scheme.onError),
        ),
        onDismissed: (_) => onDelete(e),
        child: PremiumCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: (isPaid ? Colors.green : Colors.orange)
                    .withValues(alpha: 0.15),
                child: Icon(
                  isPaid ? Icons.check_circle_outline : Icons.schedule,
                  size: 18,
                  color: isPaid ? Colors.green : Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    Text(
                      ObligationsUtils.formatEntryDate(e.createdAt, s.id),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.6),
                          ),
                    ),
                  ],
                ),
              ),
              Text(
                '${e.days} ${s.daysUnit}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
