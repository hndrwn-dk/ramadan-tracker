import 'package:ramadan_tracker/l10n/app_localizations.dart';

/// Localized labels for Insights status chips (replaces hardcoded EN strings).
class InsightsLabels {
  InsightsLabels(this.l10n);

  final AppLocalizations l10n;

  String get done => l10n.insightsStatusDone;
  String get missed => l10n.insightsStatusMissed;
  String get excused => l10n.insightsStatusExcused;
  String get partial => l10n.insightsStatusPartial;
  String get onTrack => l10n.insightsStatusOnTrack;
  String get over => l10n.insightsStatusOver;
  String get met => l10n.insightsStatusMet;
  String get below => l10n.insightsStatusBelow;
  String get none => l10n.insightsStatusNone;
  String get perfect => l10n.insightsStatusPerfect;
  String get notDone => l10n.insightsStatusNotDone;
  String get given => l10n.insightsStatusGiven;
  String get details => l10n.insightsDetails;
  String get target => l10n.insightsTargetLabel;
  String get todayGiven => l10n.insightsTodayGiven;
  String sedekahTodayTitle() => l10n.insightsSedekahTodayTitle;
}
