// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Fasting & Worship';

  @override
  String get today => 'Today';

  @override
  String get month => 'Month';

  @override
  String get plan => 'Plan';

  @override
  String get insights => 'Insights';

  @override
  String get settings => 'Settings';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get create => 'Create';

  @override
  String get export => 'Export';

  @override
  String get import => 'Import';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get appearanceTitle => 'Appearance';

  @override
  String get appearanceSubtitle => 'Theme and display settings';

  @override
  String get themeLight => 'Light';

  @override
  String get themeLightDesc => 'Always use light theme';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeDarkDesc => 'Always use dark theme';

  @override
  String get themeAuto => 'Auto';

  @override
  String get themeAutoDesc => 'Follow system theme (default)';

  @override
  String get seasonManagementTitle => 'My Ramadan';

  @override
  String get seasonManagementSubtitle =>
      'Create, view, and delete Ramadan seasons';

  @override
  String get habitsTargetsTitle => 'Habits & Targets';

  @override
  String get habitsTargetsSubtitle => 'Enable or disable habits to track';

  @override
  String get timesRemindersTitle => 'Times & Reminders';

  @override
  String get timesRemindersSubtitle =>
      'Configure prayer times and notification reminders';

  @override
  String get prayerOffsetTipTitle => 'Prayer times off by 1 hour?';

  @override
  String get prayerOffsetTipBody =>
      'If prayer times look off by about 1 hour, you can set an Offset in Settings.';

  @override
  String get prayerOffsetTipCta => 'Set Offset';

  @override
  String get backupRestoreTitle => 'Backup & Restore';

  @override
  String get backupRestoreSubtitle => 'Export or import your data';

  @override
  String get aboutTitle => 'About';

  @override
  String get aboutSubtitle => 'Share, rate, and app information';

  @override
  String get shareThisApp => 'Share this app';

  @override
  String get shareThisAppSubtitle => 'Tell friends about Ramadan Tracker';

  @override
  String get rateThisApp => 'Rate this app';

  @override
  String get rateThisAppSubtitle => 'Leave a review on Google Play';

  @override
  String shareAppMessage(String url) {
    return 'Track Ramadan habits and sunnah fasting year-round — offline and private. Try Ramadan Tracker: $url';
  }

  @override
  String get languageTitle => 'Language';

  @override
  String get languageSubtitle => 'Choose your preferred language';

  @override
  String get languageReason =>
      'Menus and content will appear in this language throughout the app.';

  @override
  String get english => 'English';

  @override
  String get indonesian => 'Indonesian';

  @override
  String get insightsTitle => 'Insights';

  @override
  String get insightsTodayTab => 'Today';

  @override
  String get insights7DaysTab => '7 Days';

  @override
  String get insightsSeasonTab => 'Ramadan';

  @override
  String get insightsTodayScore => 'Today Score';

  @override
  String get insightsStreak => 'Streak';

  @override
  String get insightsComplete => 'Complete';

  @override
  String insightsDayProgress(int day, int total) {
    return 'Day $day of $total';
  }

  @override
  String get insightsScoreDrivers => 'Score Drivers';

  @override
  String get insightsViewConsistency => 'View Ramadan Consistency';

  @override
  String get insightsHighlights => 'Highlights';

  @override
  String get insights7DayScore => '7-Day Score';

  @override
  String get insightsTotalScore => 'Total';

  @override
  String get insightsBestStreak => 'Best Streak';

  @override
  String get insightsPerfectDays => 'Perfect Days';

  @override
  String get insightsMissedTasks => 'Missed Tasks';

  @override
  String get insightsReviewMissedDays => 'Review Missed Days';

  @override
  String get insightsWeeklyRhythm => 'Weekly Rhythm';

  @override
  String get insightsSeasonScore => 'Ramadan Score';

  @override
  String get insightsPerfectDaysCount => 'Perfect Days';

  @override
  String get insightsMissedDaysCount => 'Missed Days';

  @override
  String get insightsSeasonAudit => 'Season Audit';

  @override
  String get insightsSeasonTrend => 'Completion Trend';

  @override
  String get insightsSeasonHighlights => 'Season Highlights';

  @override
  String get insightsBestDay => 'Best Day';

  @override
  String get insightsToughestDay => 'Toughest Day';

  @override
  String get insightsMostConsistent => 'Most Consistent Task';

  @override
  String get insightsBiggestComeback => 'Biggest Comeback';

  @override
  String get monthViewTitle => 'Monthly View';

  @override
  String get monthViewLegend => 'Legend';

  @override
  String get monthViewRing => 'Ring = Completion';

  @override
  String get monthViewDot => 'Dot = Tracked';

  @override
  String get monthViewStar => 'Star = Last 10';

  @override
  String get planTitle => 'Ramadan Autopilot';

  @override
  String get planTodayTarget => 'Today Target';

  @override
  String get planTodayRemaining => 'Today Remaining';

  @override
  String get planRecommended => 'Recommended Plan';

  @override
  String get planPersonalizedGuide => 'Your personalized daily guide';

  @override
  String get planTodaysPlan => 'Today\'s Plan';

  @override
  String get planStartReading => 'Start Reading';

  @override
  String get planStartCounter => 'Start Counter';

  @override
  String get planMorning => 'Morning';

  @override
  String get planDay => 'Day';

  @override
  String get planNight => 'Night';

  @override
  String get done => 'Done';

  @override
  String get miss => 'Miss';

  @override
  String get partial => 'Partial';

  @override
  String get excused => 'Excused';

  @override
  String get over => 'Over';

  @override
  String get target => 'Target';

  @override
  String get details => 'Details';

  @override
  String get reason => 'Reason';

  @override
  String get pointsEarned => 'Points Earned';

  @override
  String get trendPattern => 'Trend & Pattern';

  @override
  String bestStreak(int days) {
    return 'Best streak: $days days';
  }

  @override
  String get bestStreakLabel => 'Best Streak';

  @override
  String get missCount => 'Miss Count';

  @override
  String get lastUpdated => 'Last Updated';

  @override
  String get habitAnalytics => 'Habit analytics';

  @override
  String get ramadanProgress => 'Ramadan Progress';

  @override
  String thisRamadan(int done, int total) {
    return 'This Ramadan: $done/$total done';
  }

  @override
  String get createNewSeason => 'Create New Season';

  @override
  String get startNewRamadanTracking => 'Start a new Ramadan tracking period';

  @override
  String get resetOnboarding => 'Reset Onboarding';

  @override
  String get showSetupWizardAgain =>
      'Show setup wizard again on next app launch';

  @override
  String get deleteSeason => 'Delete Season?';

  @override
  String get deleteSeasonWarning => 'This action cannot be undone.';

  @override
  String get testNotification => 'Test Notification';

  @override
  String get goalRemindersTitle => 'Goal Reminders';

  @override
  String get goalRemindersSubtitle =>
      'Only during an active Ramadan season when the habit is enabled and a daily target is set';

  @override
  String get goalReminderQuran => 'Quran Goal Reminder';

  @override
  String get goalReminderQuranDesc =>
      'Remind me if Quran target not reached (2 PM, 6 PM, 8 PM)';

  @override
  String get goalReminderDhikr => 'Dhikr Goal Reminder';

  @override
  String get goalReminderDhikrDesc =>
      'Remind me if Dhikr target not reached (2 PM, 6 PM, 8 PM)';

  @override
  String get goalReminderSedekah => 'Sedekah Goal Reminder';

  @override
  String get goalReminderSedekahDesc =>
      'Remind me if Sedekah target not reached (4 PM)';

  @override
  String get goalReminderTaraweeh => 'Taraweeh Reminder';

  @override
  String get goalReminderTaraweehDesc =>
      'Remind me 15 minutes after Isha if Taraweeh not done';

  @override
  String get quranGoalReminderTitle => 'Quran Goal Reminder';

  @override
  String quranGoalReminderBody(int current, int target) {
    return 'Haven\'t reached today\'s Quran target ($current/$target pages). Keep going!';
  }

  @override
  String get dhikrGoalReminderTitle => 'Dhikr Goal Reminder';

  @override
  String dhikrGoalReminderBody(int current, int target) {
    return 'Dhikr target not reached ($current/$target). Keep it up!';
  }

  @override
  String get sedekahGoalReminderTitle => 'Sedekah Goal Reminder';

  @override
  String get sedekahGoalReminderBody =>
      'Today\'s Sedekah target not reached. Don\'t forget to share goodness!';

  @override
  String get taraweehReminderTitle => 'Taraweeh Reminder';

  @override
  String get taraweehReminderBody =>
      'Taraweeh time is approaching! Prepare yourself for night prayer.';

  @override
  String get sendTestNotification =>
      'Send a test notification to verify settings';

  @override
  String get testNotificationSent => 'Test notification sent';

  @override
  String get habitFasting => 'Fasting';

  @override
  String get fastingStatusFasted => 'Fasted';

  @override
  String get fastingStatusNotDone => 'Not done';

  @override
  String get fastingStatusExcusedSick => 'Excused (sick)';

  @override
  String get fastingStatusExcusedNifas => 'Excused (postpartum / nifas)';

  @override
  String get fastingStatusExcusedHaid => 'Excused (menstruation / haid)';

  @override
  String get fastingStatusExcusedOther => 'Excused (other reason)';

  @override
  String get fastingNoteHint => 'Add note (optional)';

  @override
  String get fastingSummaryTitle => 'Fasting summary';

  @override
  String get fastingSummaryDay => 'day';

  @override
  String get fastingSummaryDays => 'days';

  @override
  String get habitQuran => 'Quran';

  @override
  String get habitDhikr => 'Dhikr';

  @override
  String get habitTaraweeh => 'Taraweeh';

  @override
  String get taraweehRakaat11 => '11 rakaat';

  @override
  String get taraweehRakaat23 => '23 rakaat';

  @override
  String get taraweehRakaatPerDayLabel => 'Rakaat per day:';

  @override
  String taraweehRakaatProgress(int current, int target) {
    return '$current/$target rakaat';
  }

  @override
  String get habitSedekah => 'Sedekah';

  @override
  String get habitItikaf => 'I\'tikaf';

  @override
  String get habitPrayers => '5 Prayers';

  @override
  String get habitTahajud => 'Tahajud';

  @override
  String get habitPrayersDetailed => '5 Prayers (detailed)';

  @override
  String get trackEachPrayerIndividually => 'Track each prayer individually';

  @override
  String days(int days) {
    return '$days days';
  }

  @override
  String get errorLoadingSeasons => 'Error loading seasons';

  @override
  String get resetOnboardingConfirm =>
      'This will show the onboarding screen again when you restart the app. Continue?';

  @override
  String get reset => 'Reset';

  @override
  String get onboardingWillShowOnRestart =>
      'Onboarding will show on next app restart';

  @override
  String get sahurReminder => 'Sahur reminder';

  @override
  String minBeforeFajr(int minutes) {
    return '$minutes min before Fajr';
  }

  @override
  String get getNotifiedBeforeSuhoor => 'Get notified before suhoor time';

  @override
  String get iftarReminder => 'Iftar reminder';

  @override
  String minAfterMaghrib(int minutes) {
    return '$minutes min after Maghrib';
  }

  @override
  String get getNotifiedWhenBreakFast =>
      'Get notified when it\'s time to break fast';

  @override
  String get nightPlanReminder => 'Time for night worship';

  @override
  String get reminderToPlanNightActivities =>
      'Reminder to plan your night activities (Qiyam & Tahajud)';

  @override
  String get calculationMethod => 'Calculation Method';

  @override
  String get choosePrayerTimeMethod => 'Choose prayer time calculation method';

  @override
  String get fajrAdjustment => 'Fajr Adjustment';

  @override
  String get adjustFajrManually => 'Adjust Fajr prayer time manually';

  @override
  String get maghribAdjustment => 'Maghrib Adjustment';

  @override
  String get adjustMaghribManually => 'Adjust Maghrib prayer time manually';

  @override
  String get minutesUnit => 'minutes';

  @override
  String get nextReminders => 'Next Reminders';

  @override
  String get noTitle => 'No title';

  @override
  String get noBody => 'No body';

  @override
  String get exportBackup => 'Export Backup';

  @override
  String get saveDataAsJson => 'Save your data as JSON file';

  @override
  String get importBackup => 'Import Backup';

  @override
  String get restoreDataFromJson => 'Restore data from JSON backup';

  @override
  String get version => 'Version';

  @override
  String get supportDeveloper => 'Support this app';

  @override
  String get buyMeACoffee =>
      'Tip on Ko-fi — help keep it free, private & ad-free';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get readPrivacyPolicy => 'Read our privacy policy';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get readTermsOfService => 'Read our terms of service';

  @override
  String get noSeasonFound => 'No season found';

  @override
  String get fajrAdjustmentTitle => 'Fajr Adjustment';

  @override
  String get maghribAdjustmentTitle => 'Maghrib Adjustment';

  @override
  String importFailed(String error) {
    return 'Import failed: $error';
  }

  @override
  String exportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String get pasteBackupJson => 'Paste your backup JSON below:';

  @override
  String get pasteJsonBackupData => 'Paste JSON backup data...';

  @override
  String get backupImportedSuccessfully => 'Backup imported successfully';

  @override
  String get error => 'Error';

  @override
  String errorOpeningUrl(String error) {
    return 'Error opening URL: $error';
  }

  @override
  String get focusMode => 'Focus Mode';

  @override
  String get preRamadan => 'Pre-Ramadan';

  @override
  String get preRamadanSubtitle =>
      'Season not started yet. Browse and plan ahead.';

  @override
  String get seasonEnded => 'Season Ended';

  @override
  String get seasonEndedMessage =>
      'This Ramadan season has finished. Review your progress or create a new season.';

  @override
  String dayOfSeason(int dayIndex, int totalDays) {
    return 'Day $dayIndex of $totalDays';
  }

  @override
  String preRamadanWithDate(String date) {
    return 'Pre-Ramadan • $date';
  }

  @override
  String seasonEndedWithDate(String date) {
    return 'Season Ended • $date';
  }

  @override
  String errorMessage(String error) {
    return 'Error: $error';
  }

  @override
  String get lastDay => 'Last Day!';

  @override
  String get lastDayMessage =>
      'This is the final day of Ramadan. Finish strong and make it count!';

  @override
  String get almostThere => 'Almost There!';

  @override
  String almostThereMessage(int days) {
    return 'Only $days days left. You\'ve come so far - keep going!';
  }

  @override
  String get last10Days => 'Last 10 Days';

  @override
  String get last10DaysMessage =>
      'These are the most blessed days. Maximize your ibadah and seek Laylatul Qadr!';

  @override
  String get finalStretch => 'Final Stretch';

  @override
  String get finalStretchMessage =>
      'You\'re in the last 10 days. Every moment counts - stay focused!';

  @override
  String daysRemaining(int days) {
    return '$days days remaining';
  }

  @override
  String get createNewSeasonMessage =>
      'Create a new Ramadan season to start tracking';

  @override
  String get startSetup => 'Start Setup';

  @override
  String get newSeason => 'New Season';

  @override
  String get viewInsights => 'View Insights';

  @override
  String get enableLocationForSahurIftar => 'Enable location for Sahur/Iftar';

  @override
  String get enableLocation => 'Enable Location';

  @override
  String get times => 'Times';

  @override
  String get sahur => 'Sahur';

  @override
  String get iftar => 'Iftar';

  @override
  String get fajr => 'Fajr';

  @override
  String get maghrib => 'Maghrib';

  @override
  String iftarCountdown(int hours, int minutes) {
    return 'Iftar in ${hours}h ${minutes}m';
  }

  @override
  String iftarIn(String time) {
    return 'Iftar in $time';
  }

  @override
  String iftarPassed(String time) {
    return 'Iftar passed • $time';
  }

  @override
  String sahurIn(String time) {
    return 'Sahur in $time';
  }

  @override
  String sahurTomorrowIn(String time) {
    return 'Sahur tomorrow in $time';
  }

  @override
  String get todayFastingCountdownLabel => 'Next';

  @override
  String get todayFastingCountdownHint =>
      'Enable location for live Sahur and Iftar times';

  @override
  String sahurPassed(String time) {
    return 'Sahur passed • $time';
  }

  @override
  String get showIftarCountdown => 'Show Iftar countdown';

  @override
  String get showSahurCountdown => 'Show Sahur countdown';

  @override
  String get todayIn10Seconds => 'Today in 10 seconds';

  @override
  String get todayIn10SecondsMessage =>
      'Tap what you did. Add pages & dhikr. Done.';

  @override
  String get openOneTap => 'Open One Tap';

  @override
  String get editGoals => 'Edit Goals';

  @override
  String get oneTapToday => 'One Tap Today';

  @override
  String get reflection => 'Reflection';

  @override
  String get howWasToday => 'How was today?';

  @override
  String streakDays(int days) {
    return 'Streak: $days days';
  }

  @override
  String doneCount(int completed, int total) {
    return 'Done: $completed/$total';
  }

  @override
  String get errorLoadingEntries => 'Error loading entries';

  @override
  String get errorLoadingHabits => 'Error loading habits';

  @override
  String get moodExcellent => 'Excellent';

  @override
  String get moodGood => 'Good';

  @override
  String get moodOk => 'Ok';

  @override
  String get moodDifficult => 'Difficult';

  @override
  String get errorLoadingSeason => 'Error loading season';

  @override
  String get outsideSeason => 'Outside season';

  @override
  String get legend => 'Legend';

  @override
  String get ringEqualsCompletion => 'Ring = completion';

  @override
  String get dotEqualsTracked => 'Dot = tracked';

  @override
  String get starEqualsLast10 => 'Star = last 10';

  @override
  String get ringCompletionCompact => 'Ring=Completion';

  @override
  String get dotTrackedCompact => 'Dot=Tracked';

  @override
  String get starLast10Compact => 'Star=Last 10';

  @override
  String dayLabel(int dayIndex) {
    return 'Day $dayIndex';
  }

  @override
  String percentComplete(int percent) {
    return '$percent% Complete';
  }

  @override
  String get trackedHabits => 'Tracked Habits';

  @override
  String get close => 'Close';

  @override
  String get viewDayButton => 'View Day';

  @override
  String get errorLoadingSeasonHabits => 'Error loading season habits';

  @override
  String get notDone => 'Not done';

  @override
  String quranPagesFormat(int pages, int target) {
    return '$pages / $target pages';
  }

  @override
  String dhikrCountFormat(int count, int target) {
    return '$count / $target';
  }

  @override
  String get trackYourRamadanInSeconds => 'Track your Ramadan in seconds';

  @override
  String get noAccountNoAdsStored =>
      'No account • No ads • Stored on your device';

  @override
  String get oneTapDailyChecklist => 'One tap daily checklist';

  @override
  String get autopilotQuranPlan => 'Autopilot Qur\'an plan';

  @override
  String get sahurIftarRemindersAutomatic =>
      'Sahur & Iftar reminders (automatic)';

  @override
  String get takesAbout1Minute => 'Takes about 1 minute';

  @override
  String get ramadanSeason => 'Ramadan Season';

  @override
  String get seasonLabel => 'Season Label';

  @override
  String ramadanYearHint(int year) {
    return 'Ramadan $year';
  }

  @override
  String daysCount(int count) {
    return '$count days';
  }

  @override
  String get startDate => 'Start Date';

  @override
  String get preview => 'Preview';

  @override
  String day1StartsOn(String date) {
    return 'Day 1 starts on $date.';
  }

  @override
  String last10NightsBeginOn(int day, String date) {
    return 'Last 10 nights begin on Day $day ($date).';
  }

  @override
  String get chooseWhatToTrack => 'Choose What to Track';

  @override
  String get trackOnlyWhatHelps =>
      'Track only what helps. You can change anytime.';

  @override
  String get quran20PagesPerDay => 'Qur\'an (20 pages/day)';

  @override
  String get quran40PagesPerDay => 'Qur\'an (40 pages/day)';

  @override
  String quranCustomPagesPerDay(int pages) {
    return 'Qur\'an ($pages pages/day)';
  }

  @override
  String get advanced => 'Advanced';

  @override
  String get prayersSimple => '5 Prayers (simple)';

  @override
  String get setGoals => 'Set Goals';

  @override
  String get gentleGoalsBeatPerfectStreaks =>
      'Gentle goals beat perfect streaks.';

  @override
  String get quranGoal => 'Quran Goal';

  @override
  String get oneKhatam20Pages => '1 Khatam (20 pages/day)';

  @override
  String get twoKhatam40Pages => '2 Khatam (40 pages/day)';

  @override
  String get custom => 'Custom';

  @override
  String pagesPerDay(int pages) {
    return '$pages pages/day';
  }

  @override
  String get enterPages => 'Enter pages';

  @override
  String totalPagesCalculation(int total, int daily, int days) {
    return '$total total pages → $daily pages/day for $days days';
  }

  @override
  String get dhikrTarget => 'Dhikr Target';

  @override
  String get setDailySedekahGoal => 'Set a daily Sedekah goal';

  @override
  String get amount => 'Amount';

  @override
  String get enterAmount => 'Enter amount';

  @override
  String get currency => 'Currency';

  @override
  String get idrRp => 'IDR (Rp)';

  @override
  String get sgdSdollar => 'SGD (S\$)';

  @override
  String get usdDollar => 'USD (\$)';

  @override
  String get myrRm => 'MYR (RM)';

  @override
  String get smartReminders => 'Smart Reminders';

  @override
  String get getNotifiedForSahurIftar =>
      'Get notified for Sahur, Iftar, and your daily plan.';

  @override
  String get offset => 'Offset:';

  @override
  String minutesShort(int minutes) {
    return '$minutes min';
  }

  @override
  String get atMaghrib => 'At Maghrib';

  @override
  String get location => 'Location';

  @override
  String get useMyLocation => 'Use my location';

  @override
  String get setCityManually => 'Set city manually';

  @override
  String get cityNameOptional => 'City name (optional)';

  @override
  String get jakartaHint => 'Jakarta';

  @override
  String get latitude => 'Latitude';

  @override
  String get latitudeHint => '-6.2088';

  @override
  String get longitude => 'Longitude';

  @override
  String get longitudeHint => '106.8456';

  @override
  String get set => 'Set';

  @override
  String get locationSet => 'Location set';

  @override
  String get mwlMuslimWorldLeague => 'MWL (Muslim World League)';

  @override
  String get indonesiaKemenag => 'Indonesia (Kemenag)';

  @override
  String get singapore => 'Singapore';

  @override
  String get ummAlQura => 'Umm al-Qura';

  @override
  String get karachi => 'Karachi';

  @override
  String get egypt => 'Egypt';

  @override
  String get isnaNorthAmerica => 'ISNA (North America)';

  @override
  String get prayerTimesPreview => 'Prayer Times Preview';

  @override
  String get prayerTimesVaryDaily =>
      'Times are calculated per day and change through Ramadan.';

  @override
  String get refreshTimesTooltip =>
      'Recalculate times (e.g. after changing location)';

  @override
  String timesForDate(String date) {
    return 'Times for $date';
  }

  @override
  String get test => 'Test';

  @override
  String get sahurReminderLabel => 'Sahur reminder';

  @override
  String get iftarReminderLabel => 'Iftar reminder';

  @override
  String get finishAndStart => 'Finish & Start';

  @override
  String get locationServicesDisabled => 'Location services are disabled';

  @override
  String get locationPermissionsDenied => 'Location permissions denied';

  @override
  String get locationPermissionsPermanentlyDenied =>
      'Location permissions permanently denied';

  @override
  String get pleaseEnterValidCoordinates => 'Please enter valid coordinates';

  @override
  String get back => 'Back';

  @override
  String get continueButton => 'Continue';

  @override
  String juzProgress(String progress, int target) {
    return 'Juz: $progress/$target';
  }

  @override
  String ofPages(int pages) {
    return 'of $pages pages';
  }

  @override
  String ofDhikr(int count) {
    return 'of $count dhikr';
  }

  @override
  String todayAmountGoal(String amount, String goal) {
    return 'Today: $amount / $goal';
  }

  @override
  String get customAmount => 'Custom Amount';

  @override
  String get add => 'Add';

  @override
  String get prayerFajr => 'Fajr';

  @override
  String get prayerDhuhr => 'Dhuhr';

  @override
  String get prayerAsr => 'Asr';

  @override
  String get prayerIsha => 'Isha';

  @override
  String get ramadanAutopilot => 'Ramadan Autopilot';

  @override
  String get setupRamadanAutopilot => 'Setup Ramadan Autopilot';

  @override
  String get setupRamadanAutopilotSubtitle =>
      'Configure your goals and available time to generate a daily plan.';

  @override
  String get availableTimeMinutes => 'Available Time (minutes)';

  @override
  String minutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get totalPages => 'Total Pages';

  @override
  String get dailyTarget => 'Daily Target';

  @override
  String get savePlan => 'Save Plan';

  @override
  String get seasonCompleted => 'Season Completed';

  @override
  String get seasonCompletedMessage =>
      'Congratulations on completing Ramadan! Review your journey in the Insights tab.';

  @override
  String get newSeasonCreationComingSoon => 'New season creation coming soon';

  @override
  String get startNewSeason => 'Start New Season';

  @override
  String get recommendedPlan => 'Recommended Plan';

  @override
  String get recommendedPlanSubtitle => 'Your personalized daily guide';

  @override
  String get todayTarget => 'Today Target';

  @override
  String get todaysPlan => 'Today\'s Plan';

  @override
  String get progress => 'Progress';

  @override
  String pagesRemaining(int pages) {
    return '$pages pages remaining';
  }

  @override
  String get daysLeft => 'Days left';

  @override
  String get dhikrTargetLabel => 'Dhikr target';

  @override
  String get daily => 'daily';

  @override
  String get gentleCatchup => 'Gentle catch-up';

  @override
  String gentleCatchupMessage(int pages, int days) {
    return '+$pages pages/day for the next $days days';
  }

  @override
  String get afterFajr => 'After Fajr';

  @override
  String get midday => 'Midday';

  @override
  String get afterIsha => 'After Isha';

  @override
  String get quranGoal1Khatam => '1 Khatam';

  @override
  String get quranGoal2Khatam => '2 Khatam';

  @override
  String get quranGoalCustom => 'Custom';

  @override
  String get todayRemaining => 'Today Remaining';

  @override
  String remaining(int count) {
    return '$count remaining';
  }

  @override
  String get allDone => 'All done';

  @override
  String get noTasksScheduled => 'No tasks scheduled';

  @override
  String get startReading => 'Start reading';

  @override
  String get startCounter => 'Start counter';

  @override
  String get markDone => 'Mark done';

  @override
  String get count => 'Count';

  @override
  String get pages => 'pages';

  @override
  String get pagesPerDayLabel => 'Pages per day';

  @override
  String get daysLabel => 'Days';

  @override
  String get taskQuranReading => 'Quran Reading';

  @override
  String get taskQiyam => 'Qiyam';

  @override
  String get date => 'Date';

  @override
  String get habits => 'Habits';

  @override
  String get goals => 'Goals';

  @override
  String get seasonCreatedSuccessfully => 'Season Created Successfully';

  @override
  String get seasonCreatedMessage =>
      'Your new Ramadan season has been created and is ready to use!';

  @override
  String seasonCreatedError(String error) {
    return 'Error creating season: $error';
  }

  @override
  String get last7Days => 'Last 7 days';

  @override
  String day1ToDay(int days) {
    return 'Day 1–Day $days';
  }

  @override
  String get sevenDays => '7 Days';

  @override
  String get changeDate => 'Change date';

  @override
  String get selectDayToAnalyze => 'Select day to analyze';

  @override
  String get todayScore => 'Today Score';

  @override
  String dayOfTotal(int day, int total) {
    return 'Day $day of $total';
  }

  @override
  String get sevenDayAverageScore => '7-Day Average Score';

  @override
  String totalScore(int score, int max) {
    return 'Total: $score/$max';
  }

  @override
  String perfectDays(int done, int total) {
    return 'Perfect days $done/$total';
  }

  @override
  String currentStreak(int days) {
    return 'Current streak: $days days';
  }

  @override
  String get seasonAverageScore => 'Season Average Score';

  @override
  String daysCompleted(int done, int total) {
    return 'Days completed $done/$total';
  }

  @override
  String perfectDaysOnly(int count) {
    return 'Perfect days $count';
  }

  @override
  String longestStreak(int days) {
    return 'Longest streak: $days days';
  }

  @override
  String viewDay(String date) {
    return 'View Day ($date)';
  }

  @override
  String get reviewWhatsMissing => 'Review what\'s missing';

  @override
  String get scrollDownToSeeHeatmaps =>
      'Scroll down to see Ramadan consistency heatmaps';

  @override
  String get viewRamadanConsistency => 'View Ramadan consistency';

  @override
  String get weeklyReview => 'Weekly Review';

  @override
  String get seasonReport => 'Season Report';

  @override
  String get bestDayScore => 'Best day score';

  @override
  String get tarawihProgress => 'Tarawih progress';

  @override
  String doneNights(int done, int total) {
    return 'Done $done/$total nights';
  }

  @override
  String get itikafLast10Nights => 'Itikaf last 10 nights';

  @override
  String nights(int count) {
    return '$count/10 nights';
  }

  @override
  String get sedekahTotalGiven => 'Sedekah total given';

  @override
  String get tapToViewDetails => 'Tap to view details';

  @override
  String get highlights => 'Highlights';

  @override
  String get taskInsights => 'Task Insights';

  @override
  String get analytics => 'Analytics';

  @override
  String get disabled => 'Disabled';

  @override
  String get notEnabled => 'Not enabled';

  @override
  String doneItikaf(int done) {
    return 'Done $done/10 (last 10 nights)';
  }

  @override
  String todayPagesAvg(int pages, int target, int avg) {
    return 'Today $pages/$target • Avg $avg/$target (last 7)';
  }

  @override
  String todayCountAvg(int count, int target, int avg) {
    return 'Today $count/$target • Avg $avg/$target (last 7)';
  }

  @override
  String todayAmountTotal(String amount, String target, String total) {
    return 'Today $amount / $target • Total $total';
  }

  @override
  String todayPrayersPerfect(int completed, int perfect, int total) {
    return 'Today $completed/5 • Perfect days $perfect/$total';
  }

  @override
  String get prayersCompleted => 'Prayers completed';

  @override
  String get todayBreakdown => 'Today Breakdown';

  @override
  String get scoreBreakdown => 'Score Breakdown';

  @override
  String get goToToday => 'Go to Today';

  @override
  String auditDay(int dayIndex) {
    return 'Audit day (Day $dayIndex)';
  }

  @override
  String get pagesRead => 'Pages read';

  @override
  String get amountGiven => 'Amount given';

  @override
  String get noDonation => 'No donation';

  @override
  String given(String amount) {
    return 'Given: $amount';
  }

  @override
  String get missedDays => 'Missed Days';

  @override
  String get completed => 'Completed';

  @override
  String get notCompleted => 'Not completed';

  @override
  String toImprove(String message) {
    return 'To improve: $message';
  }

  @override
  String get fastingCompleted => 'Fasting completed';

  @override
  String get fastingNotCompleted => 'Fasting not completed';

  @override
  String completeFastingToGain(int points) {
    return 'Complete fasting to gain $points points';
  }

  @override
  String get all5PrayersCompleted => 'All 5 prayers completed';

  @override
  String onlyPrayersCompleted(int completed) {
    return 'Only $completed/5 prayers completed';
  }

  @override
  String get noPrayersLogged => 'No prayers logged';

  @override
  String completeRemainingPrayers(int remaining, int points) {
    return 'Complete remaining $remaining prayers to gain $points points';
  }

  @override
  String logAll5Prayers(int points) {
    return 'Log all 5 prayers to gain $points points';
  }

  @override
  String targetMetPages(int pages, int target) {
    return 'Target met ($pages/$target pages)';
  }

  @override
  String partialCompletionPages(int pages, int target) {
    return 'Partial completion ($pages/$target pages)';
  }

  @override
  String targetNotMetPages(int target) {
    return 'Target not met (0/$target pages)';
  }

  @override
  String readMorePages(int remaining, int points) {
    return 'Read $remaining more pages to gain $points points';
  }

  @override
  String readPagesToGain(int points) {
    return 'Read pages to gain $points points';
  }

  @override
  String targetMetCount(int count, int target) {
    return 'Target met ($count/$target)';
  }

  @override
  String partialCompletionCount(int count, int target) {
    return 'Partial completion ($count/$target)';
  }

  @override
  String targetNotMetCount(int target) {
    return 'Target not met (0/$target)';
  }

  @override
  String completeMoreToGain(int remaining, int points) {
    return 'Complete $remaining more to gain $points points';
  }

  @override
  String get dhikrCompleted => 'Dhikr completed';

  @override
  String get noDhikrLogged => 'No dhikr logged';

  @override
  String completeDhikrToGain(int points) {
    return 'Complete dhikr to gain $points points';
  }

  @override
  String get taraweehCompleted => 'Taraweeh completed';

  @override
  String get taraweehNotCompleted => 'Taraweeh not completed';

  @override
  String completeTaraweehToGain(int points) {
    return 'Complete taraweeh to gain $points points';
  }

  @override
  String get goalMet => 'Goal met';

  @override
  String get partialGiving => 'Partial giving';

  @override
  String get noGiving => 'No giving';

  @override
  String giveMoreToGain(String amount, int points) {
    return 'Give $amount more to gain $points points';
  }

  @override
  String giveToGain(int points) {
    return 'Give to gain $points points';
  }

  @override
  String get itikafCompleted => 'Itikaf completed';

  @override
  String get itikafNotCompleted => 'Itikaf not completed';

  @override
  String completeItikafToGain(int points) {
    return 'Complete itikaf to gain $points points';
  }

  @override
  String get noPagesRead => 'No pages read';

  @override
  String get sunnah => 'Sunnah';

  @override
  String get scoreLabel => 'Score';

  @override
  String get monthJourneyTitle => 'Season journey';

  @override
  String monthJourneySubtitle(String levelLabel, int unlocked, int total) {
    return '$levelLabel · $unlocked/$total achievements';
  }

  @override
  String monthJourneyDayProgress(int day, int total) {
    return 'Day $day of $total';
  }

  @override
  String monthJourneyXpToNext(int xp) {
    return '$xp XP to next level';
  }

  @override
  String get openTodayChecklist => 'Open today\'s checklist';

  @override
  String get todayChecklistTitle => 'Today\'s checklist';

  @override
  String dayChecklistTitle(int day) {
    return 'Day $day checklist';
  }

  @override
  String checklistProgressDone(int completed, int total) {
    return '$completed of $total done';
  }

  @override
  String get checklistNudgeStart => 'Let\'s begin today\'s ibadah';

  @override
  String get checklistNudgePartial => 'Keep going, you\'re doing well';

  @override
  String get checklistNudgeAlmost => 'Alhamdulillah, almost there';

  @override
  String get checklistNudgeDone => 'Alhamdulillah, all done for today';

  @override
  String get checklistNotDoneYet => 'Not done yet';

  @override
  String checklistPagesOf(int current, int target) {
    return '$current of $target pages';
  }

  @override
  String checklistCountOf(int current, int target) {
    return '$current of $target';
  }

  @override
  String checklistPrayersOf(int current, int target) {
    return '$current of $target';
  }

  @override
  String get checklistEnterAmount => 'Enter amount';

  @override
  String get checklistEnterPages => 'Enter pages read';

  @override
  String get checklistEnterDhikr => 'Enter dhikr count';

  @override
  String weeklyAchievementsTitle(int count) {
    return '$count new achievements this week';
  }

  @override
  String get seasonTrophyTitle => 'Season complete';

  @override
  String get seasonTrophyMessage =>
      'Thank you for journeying through this season. May the habits you built continue beyond Ramadan.';

  @override
  String get seasonTrophyDismiss => 'Continue';

  @override
  String get settingsSectionEngage => 'Engage';

  @override
  String get settingsSectionTrack => 'Track';

  @override
  String get settingsSectionApp => 'App';

  @override
  String get insightsStatusDone => 'Done';

  @override
  String get insightsStatusMissed => 'Missed';

  @override
  String get insightsStatusExcused => 'Excused';

  @override
  String get insightsStatusPartial => 'Partial';

  @override
  String get insightsStatusOnTrack => 'On track';

  @override
  String get insightsStatusOver => 'Over';

  @override
  String get insightsStatusMet => 'Met';

  @override
  String get insightsStatusBelow => 'Below';

  @override
  String get insightsStatusNone => 'None';

  @override
  String get insightsStatusPerfect => 'Perfect';

  @override
  String get insightsStatusNotDone => 'Not done';

  @override
  String get insightsStatusGiven => 'Given';

  @override
  String get insightsDetails => 'Details';

  @override
  String get insightsTargetLabel => 'Target';

  @override
  String get insightsTodayGiven => 'Today given';

  @override
  String get insightsSedekahTodayTitle => 'Sedekah today';

  @override
  String get achievementsTitle => 'Achievements';

  @override
  String get achievementUnlocked => 'Achievement unlocked!';

  @override
  String achievementXpGained(int xp) {
    return '+$xp XP';
  }

  @override
  String companionLevelLabel(int level) {
    return 'Companion level $level';
  }

  @override
  String totalXpLabel(int xp) {
    return '$xp XP total';
  }

  @override
  String achievementsUnlockedCount(int count) {
    return '$count unlocked';
  }

  @override
  String get viewAchievements => 'View achievements';

  @override
  String get companionTierMubtadi => 'Mubtadi — Beginner';

  @override
  String get companionTierMumayyiz => 'Mumayyiz — Steady';

  @override
  String get companionTierMujahid => 'Mujahid — Committed';

  @override
  String streakShieldsRemaining(int count) {
    return '$count mercy shields left this season';
  }

  @override
  String get coachMarkDismiss => 'Got it';

  @override
  String get coachMarkTodayQuests =>
      'Complete up to 3 small goals each day for bonus XP.';

  @override
  String get coachMarkTodayJourney =>
      'Tap your level to view achievements and companion progress.';

  @override
  String get coachMarkMonthCalendar =>
      'Tap a day to log habits or review your month at a glance.';

  @override
  String get preRamadanQuestsTitle => 'Prep quests';

  @override
  String get preRamadanQuestReviewPlan =>
      'Review or create your Ramadan season';

  @override
  String get preRamadanQuestLogSunnah => 'Log a sunnah fast today';

  @override
  String get preRamadanQuestReminders => 'Turn on Sahur or Iftar reminders';

  @override
  String get preRamadanQuestCreateSeason => 'Set up your Ramadan season';

  @override
  String weeklyQuestSummary(int completed, int total) {
    return '$completed of $total daily quests completed this week';
  }

  @override
  String get weeklyReviewAudit => 'Audit';

  @override
  String weeklyReviewDayLabel(int day) {
    return 'Day $day';
  }

  @override
  String get sunnahMonthlyChallengeTitle => 'Monthly challenge';

  @override
  String sunnahMonthlySeninKamisProgress(int done, int target) {
    return 'Mon/Thu fasts: $done / $target';
  }

  @override
  String sunnahMonthlyShawwalProgress(int done, int target) {
    return 'Shawwal days: $done / $target';
  }

  @override
  String get todayQadhaSubtitle => 'Zakat, Fidyah, and missed fast obligations';

  @override
  String get shareAction => 'Share';

  @override
  String get achievementShareTagline =>
      'Ramadan Tracker — offline worship companion';

  @override
  String get reflectionPromptGratitude => 'What are you grateful for today?';

  @override
  String get reflectionPromptChallenge =>
      'What was hardest today, and how did you respond?';

  @override
  String get reflectionPromptDua => 'Is there a dua on your heart tonight?';

  @override
  String get reflectionPromptQuran =>
      'What verse or lesson stayed with you today?';

  @override
  String get reflectionPromptCommunity =>
      'Who did you support or check on today?';

  @override
  String get reflectionPromptPatience => 'Where did you practice sabr today?';

  @override
  String get reflectionPromptTomorrow => 'What is one intention for tomorrow?';

  @override
  String get seasonReportTitle => 'Season Report';

  @override
  String get seasonReportSummary => 'Season Summary';

  @override
  String get seasonReportHabits => 'Habit Summary';

  @override
  String get seasonReportComparison => 'Season Comparison';

  @override
  String seasonReportAvgScore(String score) {
    return 'Average score: $score';
  }

  @override
  String seasonReportPerfectDays(int done, int total) {
    return 'Strong days: $done / $total';
  }

  @override
  String seasonReportLongestStreak(int days) {
    return 'Longest streak: $days days';
  }

  @override
  String get seasonReportTrophies => 'Achievement trophies';

  @override
  String get habitMasteryBronze => 'Bronze';

  @override
  String get habitMasterySilver => 'Silver';

  @override
  String get habitMasteryGold => 'Gold';

  @override
  String get widgetLogSunnah => 'Log fast';

  @override
  String get weeklyReviewTitle => 'Review Missed Days';

  @override
  String get weeklyReviewNoMissed => 'No missed days in the last 7 days!';

  @override
  String get achievementFirstLogTitle => 'First step';

  @override
  String get achievementFirstLogDesc => 'You logged your first habit.';

  @override
  String get achievementFirstFullDayTitle => 'Strong day';

  @override
  String get achievementFirstFullDayDesc =>
      'You reached 80% completion on a day.';

  @override
  String get achievementStreak3Title => '3-day rhythm';

  @override
  String get achievementStreak3Desc => 'Three consistent days in a row.';

  @override
  String get achievementStreak7Title => 'Week warrior';

  @override
  String get achievementStreak7Desc => 'Seven consistent days in a row.';

  @override
  String get achievementStreak14Title => 'Fortnight focus';

  @override
  String get achievementStreak14Desc => 'Fourteen consistent days in a row.';

  @override
  String get achievementQuranHalfTitle => 'Halfway through Quran';

  @override
  String get achievementQuranHalfDesc => 'You passed 50% of your Quran plan.';

  @override
  String get achievementQuranCompleteTitle => 'Quran complete';

  @override
  String get achievementQuranCompleteDesc =>
      'You finished your season Quran plan.';

  @override
  String get achievementSeasonCompleteTitle => 'Season complete';

  @override
  String get achievementSeasonCompleteDesc =>
      'You finished tracking a Ramadan season.';

  @override
  String get achievementFirstSunnahTitle => 'Sunnah starter';

  @override
  String get achievementFirstSunnahDesc => 'You logged your first sunnah fast.';

  @override
  String get achievementSeninKamis4Title => 'Senin-Kamis regular';

  @override
  String get achievementSeninKamis4Desc =>
      'Four Monday or Thursday fasts this month.';

  @override
  String get achievementShawwalCompleteTitle => 'Shawwal six';

  @override
  String get achievementShawwalCompleteDesc =>
      'You completed six Shawwal fasts.';

  @override
  String get achievementReflectionFirstTitle => 'Heart check-in';

  @override
  String get achievementReflectionFirstDesc =>
      'You saved your first reflection.';

  @override
  String get achievementLast10Title => 'Last ten nights';

  @override
  String get achievementLast10Desc =>
      'You showed up during the last ten nights.';

  @override
  String get achievementWeeklyPerfectTitle => 'Perfect week';

  @override
  String get achievementWeeklyPerfectDesc => 'Seven strong days in a row.';

  @override
  String get achievementLevel5Title => 'Rising companion';

  @override
  String get achievementLevel5Desc => 'You reached companion level 5.';

  @override
  String get dailyQuestsTitle => 'Today\'s quests';

  @override
  String dailyQuestsProgress(int completed, int total) {
    return '$completed of $total complete';
  }

  @override
  String get questLogFasting => 'Log today\'s fast';

  @override
  String get questLogQuran => 'Read Quran today';

  @override
  String get questLogPrayers => 'Log your prayers';

  @override
  String get questLogDhikr => 'Do dhikr today';

  @override
  String get questLogTaraweeh => 'Log Taraweeh';

  @override
  String get questScore60 => 'Reach 60% daily score';

  @override
  String get todayGreetingMorning => 'Good morning';

  @override
  String get todayGreetingAfternoon => 'Good afternoon';

  @override
  String get todayGreetingEvening => 'Good evening';

  @override
  String get todayNudgeDayOne =>
      'Day one — small steps count. Start with what you can today.';

  @override
  String get todayNudgeEarly =>
      'Build your rhythm — each day strengthens the next.';

  @override
  String get todayNudgeMid =>
      'You are in the flow. Stay consistent with what matters most.';

  @override
  String get todayNudgeLastTen =>
      'The blessed final stretch — make these nights count.';

  @override
  String get todayHomeLogPrompt =>
      'Track fasting, prayer, Quran, dhikr, and sedekah in one checklist.';

  @override
  String todayHomeCompanionLine(int level, int xp) {
    return 'Level $level · $xp XP';
  }

  @override
  String todayHomeXpToNext(int xp, int level) {
    return '$xp XP to level $level';
  }

  @override
  String get onboardingLanguageStep => 'Step 1 · Language';

  @override
  String get onboardingLanguageWelcome =>
      'Welcome — let\'s personalize your Ramadan journey';

  @override
  String get onboardingLanguageNudge =>
      'You can change this anytime in Settings.';

  @override
  String get languageOptionEnHint => 'Default · International';

  @override
  String get languageOptionIdHint => 'Local language · Indonesia';

  @override
  String get onboardingValueOffline =>
      'Works fully offline — no account needed';

  @override
  String get onboardingValuePrivate => 'Your data stays private on this device';

  @override
  String get onboardingValueRamadan =>
      'Built for fasting, prayer, Quran, and daily worship';

  @override
  String onboardingStepProgress(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get onboardingWelcomeNudge =>
      'A calm companion for your Ramadan — setup takes about one minute.';

  @override
  String get onboardingSkipForNow => 'Skip for now';

  @override
  String get onboardingLocationTitle => 'Enable location';

  @override
  String get onboardingLocationSubtitle =>
      'For automatic imsak, sahur, and iftar times';

  @override
  String get onboardingAllowLocation => 'Allow location';

  @override
  String get onboardingGoalsQuranDhikrTitle => 'Daily Goals — Quran & Dhikr';

  @override
  String get onboardingGoalsSedekahTitle => 'Sedekah Goal';

  @override
  String get onboardingReadyTitle => 'You\'re ready!';

  @override
  String get onboardingRemindersFastingSection => 'Fasting times';

  @override
  String get onboardingRemindersGoalsSection => 'Daily goals';

  @override
  String get onboardingRemindersGoalsMaster => 'Goal reminders';

  @override
  String get onboardingRemindersGoalsMasterHint =>
      'Gentle nudges if today\'s target is not done yet';

  @override
  String get onboardingRemindersCustomizeGoals => 'Customize per goal';

  @override
  String get onboardingRemindersAdjustTiming => 'Adjust timing';

  @override
  String get todayTrendsTitle => 'Trends';

  @override
  String get todayTrendsSubtitle => 'Last 7 days';

  @override
  String todayTrendQuranPerDay(int count) {
    return '$count PG/DAY';
  }

  @override
  String todayTrendCountPerDay(int count) {
    return '$count/DAY';
  }

  @override
  String todayTrendPrayersPerDay(String avg) {
    return '$avg/5 AVG';
  }

  @override
  String todayTrendSedekahPerDay(String amount) {
    return '$amount/DAY';
  }

  @override
  String todayTrendDaysDone(int done, int total) {
    return '$done/$total DAYS';
  }

  @override
  String get seasonShareTitle => 'My Ramadan season';

  @override
  String get seasonShareTagline =>
      'Ramadan Tracker — offline worship companion';

  @override
  String get seasonReportViewReport => 'View season report';

  @override
  String get seasonComparisonAvgScore => 'Avg score';

  @override
  String get seasonComparisonStrongDays => 'Strong days';
}
