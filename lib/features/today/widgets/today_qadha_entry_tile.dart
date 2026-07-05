import 'package:flutter/material.dart';
import 'package:ramadan_tracker/features/qadha/qadha_screen.dart';
import 'package:ramadan_tracker/features/sunnah/sunnah_strings.dart';
import 'package:ramadan_tracker/insights/widgets/premium_card.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';

/// Compact Qadha / obligations entry for Today (post-Ramadan and year-round).
class TodayQadhaEntryTile extends StatelessWidget {
  const TodayQadhaEntryTile({super.key});

  @override
  Widget build(BuildContext context) {
    final s = SunnahStrings.of(context);
    final l10n = AppLocalizations.of(context)!;

    return PremiumCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(
          Icons.volunteer_activism,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(s.obligationsTitle),
        subtitle: Text(l10n.todayQadhaSubtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const QadhaScreen()),
        ),
      ),
    );
  }
}
