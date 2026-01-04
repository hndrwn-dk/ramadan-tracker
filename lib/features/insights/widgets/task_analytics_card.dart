import 'package:flutter/material.dart';
import 'package:ramadan_tracker/domain/models/season_model.dart';
import 'package:ramadan_tracker/insights/widgets/premium_card.dart';
import 'package:ramadan_tracker/features/insights/widgets/mini_heatmap_strip.dart';

/// Analytics card for a single task/habit in Insights > Today
class TaskAnalyticsCard extends StatelessWidget {
  final String habitKey;
  final String habitName;
  final IconData icon;
  final String status; // 'Done', 'Partial', 'Miss'
  final String keyMetricText;
  final List<DayStatus> heatmapDays;
  final int currentDayIndex;
  final SeasonModel season;
  final VoidCallback onAnalyticsTap;
  final VoidCallback? onAuditMissedTap;
  final Function(int dayIndex)? onHeatmapDayTap;
  final Color? statusColor;

  const TaskAnalyticsCard({
    super.key,
    required this.habitKey,
    required this.habitName,
    required this.icon,
    required this.status,
    required this.keyMetricText,
    required this.heatmapDays,
    required this.currentDayIndex,
    required this.season,
    required this.onAnalyticsTap,
    this.onAuditMissedTap,
    this.onHeatmapDayTap,
    this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final statusBgColor = statusColor ?? _getStatusColor(context, status);
    
    return PremiumCard(
      onTap: onAnalyticsTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Icon + Name + Status
          Row(
            children: [
              Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  habitName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBgColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: statusBgColor.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  status,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: statusBgColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Key metric
          Text(
            keyMetricText,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                ),
          ),
          const SizedBox(height: 16),
          // Mini heatmap
          MiniHeatmapStrip(
            days: heatmapDays,
            selectedDayIndex: currentDayIndex,
            onDayTap: onHeatmapDayTap ?? (dayIndex) {},
            season: season,
          ),
          const SizedBox(height: 16),
          // CTAs
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onAnalyticsTap,
                  icon: const Icon(Icons.analytics_outlined, size: 16),
                  label: const Text('Analytics'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
              if (onAuditMissedTap != null) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: onAuditMissedTap,
                  child: const Text('Audit missed'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(BuildContext context, String status) {
    switch (status) {
      case 'Done':
        return Colors.green;
      case 'Partial':
        return Colors.orange;
      case 'Miss':
        return Colors.red;
      default:
        return Theme.of(context).colorScheme.outline;
    }
  }
}

