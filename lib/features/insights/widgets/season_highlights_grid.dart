import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ramadan_tracker/insights/widgets/premium_card.dart';
import 'package:ramadan_tracker/features/insights/services/season_insights_service.dart';

/// Season Highlights Grid
class SeasonHighlightsGrid extends StatelessWidget {
  final SeasonHighlights highlights;
  final Function(String habitKey)? onTaskTap;

  const SeasonHighlightsGrid({
    super.key,
    required this.highlights,
    this.onTaskTap,
  });

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[];

    if (highlights.bestDay != null) {
      cards.add(_buildHighlightCard(
        context,
        title: 'Best day',
        icon: Icons.emoji_events,
        iconColor: Colors.amber,
        value: '${highlights.bestDay!.score}%',
        subtitle: DateFormat('MMM d').format(highlights.bestDay!.date),
      ));
    }

    if (highlights.toughestDay != null) {
      cards.add(_buildHighlightCard(
        context,
        title: 'Toughest day',
        icon: Icons.trending_down,
        iconColor: Colors.red,
        value: '${highlights.toughestDay!.score}%',
        subtitle: DateFormat('MMM d').format(highlights.toughestDay!.date),
      ));
    }

    if (highlights.mostConsistentTask != null) {
      cards.add(_buildHighlightCard(
        context,
        title: 'Most consistent',
        icon: Icons.trending_up,
        iconColor: Colors.green,
        value: _getHabitDisplayName(highlights.mostConsistentTask!),
        subtitle: 'Task',
        onTap: onTaskTap != null
            ? () => onTaskTap!(highlights.mostConsistentTask!)
            : null,
      ));
    }

    if (highlights.biggestComeback != null) {
      cards.add(_buildHighlightCard(
        context,
        title: 'Biggest comeback',
        icon: Icons.arrow_upward,
        iconColor: Colors.blue,
        value: '+${highlights.biggestComeback!.score - highlights.biggestComeback!.previousScore}',
        subtitle: DateFormat('MMM d').format(highlights.biggestComeback!.date),
      ));
    }

    if (cards.isEmpty) {
      return const SizedBox.shrink();
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) => cards[index],
    );
  }

  Widget _buildHighlightCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required String value,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    final card = PremiumCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
              ),
            ],
          ),
        ],
      ),
    );

    return card;
  }

  String _getHabitDisplayName(String habitKey) {
    switch (habitKey) {
      case 'fasting':
        return 'Fasting';
      case 'prayers':
        return '5 Prayers';
      case 'quran_pages':
        return 'Quran';
      case 'dhikr':
        return 'Dhikr';
      case 'taraweeh':
        return 'Taraweeh';
      case 'sedekah':
        return 'Sedekah';
      case 'itikaf':
        return "I'tikaf";
      default:
        return habitKey;
    }
  }
}

