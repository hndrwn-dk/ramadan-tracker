import 'package:flutter/material.dart';
import 'package:ramadan_tracker/insights/widgets/premium_card.dart';
import 'package:ramadan_tracker/features/insights/services/season_insights_service.dart';
import 'package:ramadan_tracker/domain/models/season_model.dart';

/// Season Task Analytics Row
class SeasonTaskAnalyticsRow extends StatelessWidget {
  final String habitKey;
  final String habitName;
  final IconData icon;
  final Widget? iconWidget;
  final TaskSeasonAnalytics analytics;
  final SeasonModel season;
  final VoidCallback onAnalyticsTap;

  const SeasonTaskAnalyticsRow({
    super.key,
    required this.habitKey,
    required this.habitName,
    required this.icon,
    this.iconWidget,
    required this.analytics,
    required this.season,
    required this.onAnalyticsTap,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              iconWidget != null
                  ? SizedBox(width: 20, height: 20, child: iconWidget)
                  : Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  habitName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _buildMetricsText(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                ),
          ),
          const SizedBox(height: 12),
          // Mini visual: sparkline for numeric, mini strip for boolean
          if (habitKey == 'fasting' || habitKey == 'taraweeh' || habitKey == 'tahajud' || habitKey == 'itikaf')
            _buildMiniStrip(context)
          else if (habitKey == 'quran_pages' || habitKey == 'dhikr' || habitKey == 'sedekah')
            _buildMiniSparkline(context),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onAnalyticsTap,
              icon: const Icon(Icons.analytics_outlined, size: 16),
              label: const Text('Analytics'),
            ),
          ),
        ],
      ),
    );
  }

  String _buildMetricsText() {
    if (habitKey == 'fasting' || habitKey == 'tahajud' || habitKey == 'itikaf') {
      final totalDays = habitKey == 'itikaf' ? 10 : season.days;
      return 'Done ${analytics.doneCount ?? 0}/$totalDays • Missed ${analytics.missCount ?? 0} • Best streak: ${analytics.bestStreak ?? 0} days';
    }
    if (habitKey == 'taraweeh') {
      final totalDays = season.days;
      final rakaat = analytics.totalRakaat != null && analytics.targetRakaat != null
          ? '${analytics.totalRakaat}/${analytics.targetRakaat} rakaat'
          : null;
      final days = 'Done ${analytics.doneCount ?? 0}/$totalDays • Missed ${analytics.missCount ?? 0} • Best streak: ${analytics.bestStreak ?? 0} days';
      return rakaat != null ? '$rakaat • $days' : days;
    }
    if (habitKey == 'prayers') {
      return 'Perfect days ${analytics.perfectDays ?? 0}/${season.days} • Avg ${(analytics.avgPerDay ?? 0).toStringAsFixed(1)}/5 prayers per day';
    }
    if (habitKey == 'quran_pages' || habitKey == 'dhikr') {
      final unit = habitKey == 'quran_pages' ? 'pages' : 'count';
      final best = analytics.bestDay != null ? '${analytics.bestDay!.value.toInt()}' : '0';
      return 'Total: ${(analytics.total ?? 0).toStringAsFixed(0)} • Avg: ${(analytics.avg ?? 0).toStringAsFixed(1)}/$unit per day • Met target: ${analytics.metTargetDays ?? 0}/${season.days} • Best day: $best';
    }
    if (habitKey == 'sedekah') {
      final best = analytics.bestDay != null ? '${analytics.bestDay!.value.toInt()}' : '0';
      return 'Total: ${(analytics.total ?? 0).toStringAsFixed(0)} • Avg: ${(analytics.avg ?? 0).toStringAsFixed(0)} per day • Met goal: ${analytics.metTargetDays ?? 0}/${season.days} • Best day: $best';
    }
    return '';
  }

  Widget _buildMiniStrip(BuildContext context) {
    // Simplified: just show a small indicator
    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildMiniSparkline(BuildContext context) {
    // Simplified sparkline placeholder
    return Container(
      height: 20,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          'Trend',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 9,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
        ),
      ),
    );
  }
}

