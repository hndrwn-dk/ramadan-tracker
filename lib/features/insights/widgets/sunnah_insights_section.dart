import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/providers/database_provider.dart';
import 'package:ramadan_tracker/data/providers/season_state_provider.dart';
import 'package:ramadan_tracker/data/providers/tab_provider.dart';
import 'package:ramadan_tracker/domain/models/season_model.dart';
import 'package:ramadan_tracker/features/insights/screens/sunnah_insights_screen.dart';
import 'package:ramadan_tracker/features/insights/services/sunnah_insights_service.dart';
import 'package:ramadan_tracker/features/insights/widgets/sunnah_insights_card.dart';
import 'package:ramadan_tracker/features/sunnah/sunnah_strings.dart';
import 'package:ramadan_tracker/insights/widgets/premium_card.dart';

/// Sunnah analytics block in Wawasan (hidden during active Ramadan).
class SunnahInsightsSection extends ConsumerWidget {
  final bool forceVisible;

  const SunnahInsightsSection({super.key, this.forceVisible = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seasonState = ref.watch(seasonStateProvider);
    if (!forceVisible && seasonState == SeasonState.active) {
      return const SizedBox.shrink();
    }

    final s = SunnahStrings.of(context);
    return FutureBuilder<SunnahInsightsData>(
      future: SunnahInsightsService.load(ref.read(databaseProvider)),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final data = snapshot.data;
        if (data == null) return const SizedBox.shrink();

        if (!forceVisible && !data.hasAnyData && seasonState == SeasonState.preRamadan) {
          return const SizedBox.shrink();
        }

        if (!data.hasAnyData) {
          return PremiumCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.insightsSunnahTitleFor(DateTime.now().year),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Text(s.sunnahInsightsEmpty),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    ref.read(tabIndexProvider.notifier).state = 3;
                  },
                  icon: const Icon(Icons.nightlight_round, size: 16),
                  label: Text(s.markFast),
                ),
              ],
            ),
          );
        }

        return SunnahInsightsCard(
          data: data,
          onViewDetails: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SunnahInsightsScreen(),
              ),
            );
          },
        );
      },
    );
  }
}
