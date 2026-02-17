import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id')
  ];

  /// The application title
  ///
  /// In en, this message translates to:
  /// **'Ramadan Tracker'**
  String get appTitle;

  /// Navigation menu label for Today tab
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// Navigation menu label for Month tab
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get month;

  /// Navigation menu label for Plan tab
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get plan;

  /// Navigation menu label for Insights tab
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get insights;

  /// Navigation menu label for Settings tab
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Save button label
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Cancel button label
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Delete button label
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Create button label
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// Export button label
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// Import button label
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get import;

  /// Settings screen title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Appearance section title
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceTitle;

  /// Appearance section subtitle
  ///
  /// In en, this message translates to:
  /// **'Theme and display settings'**
  String get appearanceSubtitle;

  /// Light theme option
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// Light theme description
  ///
  /// In en, this message translates to:
  /// **'Always use light theme'**
  String get themeLightDesc;

  /// Dark theme option
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// Dark theme description
  ///
  /// In en, this message translates to:
  /// **'Always use dark theme'**
  String get themeDarkDesc;

  /// Auto theme option
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get themeAuto;

  /// Auto theme description
  ///
  /// In en, this message translates to:
  /// **'Follow system theme (default)'**
  String get themeAutoDesc;

  /// Season Management section title
  ///
  /// In en, this message translates to:
  /// **'Season Management'**
  String get seasonManagementTitle;

  /// Season Management section subtitle
  ///
  /// In en, this message translates to:
  /// **'Create, view, and delete Ramadan seasons'**
  String get seasonManagementSubtitle;

  /// Habits & Targets section title
  ///
  /// In en, this message translates to:
  /// **'Habits & Targets'**
  String get habitsTargetsTitle;

  /// Habits & Targets section subtitle
  ///
  /// In en, this message translates to:
  /// **'Enable or disable habits to track'**
  String get habitsTargetsSubtitle;

  /// Times & Reminders section title
  ///
  /// In en, this message translates to:
  /// **'Times & Reminders'**
  String get timesRemindersTitle;

  /// Times & Reminders section subtitle
  ///
  /// In en, this message translates to:
  /// **'Configure prayer times and notification reminders'**
  String get timesRemindersSubtitle;

  /// Backup & Restore section title
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore'**
  String get backupRestoreTitle;

  /// Backup & Restore section subtitle
  ///
  /// In en, this message translates to:
  /// **'Export or import your data'**
  String get backupRestoreSubtitle;

  /// About section title
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutTitle;

  /// About section subtitle
  ///
  /// In en, this message translates to:
  /// **'App information and settings'**
  String get aboutSubtitle;

  /// Language section title
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// Language section subtitle
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred language'**
  String get languageSubtitle;

  /// English language option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// Indonesian language option
  ///
  /// In en, this message translates to:
  /// **'Indonesian'**
  String get indonesian;

  /// Insights screen title
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get insightsTitle;

  /// Insights Today tab label
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get insightsTodayTab;

  /// Insights 7 Days tab label
  ///
  /// In en, this message translates to:
  /// **'7 Days'**
  String get insights7DaysTab;

  /// Insights Season tab label
  ///
  /// In en, this message translates to:
  /// **'Ramadan'**
  String get insightsSeasonTab;

  /// Today score label
  ///
  /// In en, this message translates to:
  /// **'Today Score'**
  String get insightsTodayScore;

  /// Streak label
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get insightsStreak;

  /// Complete status label
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get insightsComplete;

  /// Day progress text with placeholders
  ///
  /// In en, this message translates to:
  /// **'Day {day} of {total}'**
  String insightsDayProgress(int day, int total);

  /// Score drivers section title
  ///
  /// In en, this message translates to:
  /// **'Score Drivers'**
  String get insightsScoreDrivers;

  /// View consistency button label
  ///
  /// In en, this message translates to:
  /// **'View Ramadan Consistency'**
  String get insightsViewConsistency;

  /// Highlights section title
  ///
  /// In en, this message translates to:
  /// **'Highlights'**
  String get insightsHighlights;

  /// 7-day score label
  ///
  /// In en, this message translates to:
  /// **'7-Day Score'**
  String get insights7DayScore;

  /// Total score label
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get insightsTotalScore;

  /// Best streak label
  ///
  /// In en, this message translates to:
  /// **'Best Streak'**
  String get insightsBestStreak;

  /// Perfect days label
  ///
  /// In en, this message translates to:
  /// **'Perfect Days'**
  String get insightsPerfectDays;

  /// Missed tasks label
  ///
  /// In en, this message translates to:
  /// **'Missed Tasks'**
  String get insightsMissedTasks;

  /// Review missed days button label
  ///
  /// In en, this message translates to:
  /// **'Review Missed Days'**
  String get insightsReviewMissedDays;

  /// Weekly rhythm section title
  ///
  /// In en, this message translates to:
  /// **'Weekly Rhythm'**
  String get insightsWeeklyRhythm;

  /// Season score label
  ///
  /// In en, this message translates to:
  /// **'Ramadan Score'**
  String get insightsSeasonScore;

  /// Perfect days count label
  ///
  /// In en, this message translates to:
  /// **'Perfect Days'**
  String get insightsPerfectDaysCount;

  /// Missed days count label
  ///
  /// In en, this message translates to:
  /// **'Missed Days'**
  String get insightsMissedDaysCount;

  /// Season audit button label
  ///
  /// In en, this message translates to:
  /// **'Season Audit'**
  String get insightsSeasonAudit;

  /// Completion trend section title
  ///
  /// In en, this message translates to:
  /// **'Completion Trend'**
  String get insightsSeasonTrend;

  /// Season highlights section title
  ///
  /// In en, this message translates to:
  /// **'Season Highlights'**
  String get insightsSeasonHighlights;

  /// Best day label
  ///
  /// In en, this message translates to:
  /// **'Best Day'**
  String get insightsBestDay;

  /// Toughest day label
  ///
  /// In en, this message translates to:
  /// **'Toughest Day'**
  String get insightsToughestDay;

  /// Most consistent task label
  ///
  /// In en, this message translates to:
  /// **'Most Consistent Task'**
  String get insightsMostConsistent;

  /// Biggest comeback label
  ///
  /// In en, this message translates to:
  /// **'Biggest Comeback'**
  String get insightsBiggestComeback;

  /// Month view screen title
  ///
  /// In en, this message translates to:
  /// **'Month View'**
  String get monthViewTitle;

  /// Month view legend title
  ///
  /// In en, this message translates to:
  /// **'Legend'**
  String get monthViewLegend;

  /// Month view ring legend
  ///
  /// In en, this message translates to:
  /// **'Ring = Completion'**
  String get monthViewRing;

  /// Month view dot legend
  ///
  /// In en, this message translates to:
  /// **'Dot = Tracked'**
  String get monthViewDot;

  /// Month view star legend
  ///
  /// In en, this message translates to:
  /// **'Star = Last 10'**
  String get monthViewStar;

  /// Plan screen title
  ///
  /// In en, this message translates to:
  /// **'Ramadan Autopilot'**
  String get planTitle;

  /// Today target label
  ///
  /// In en, this message translates to:
  /// **'Today Target'**
  String get planTodayTarget;

  /// Today remaining label
  ///
  /// In en, this message translates to:
  /// **'Today Remaining'**
  String get planTodayRemaining;

  /// Recommended plan label
  ///
  /// In en, this message translates to:
  /// **'Recommended Plan'**
  String get planRecommended;

  /// Personalized guide subtitle
  ///
  /// In en, this message translates to:
  /// **'Your personalized daily guide'**
  String get planPersonalizedGuide;

  /// Today's plan title
  ///
  /// In en, this message translates to:
  /// **'Today\'s Plan'**
  String get planTodaysPlan;

  /// Start reading button label
  ///
  /// In en, this message translates to:
  /// **'Start Reading'**
  String get planStartReading;

  /// Start counter button label
  ///
  /// In en, this message translates to:
  /// **'Start Counter'**
  String get planStartCounter;

  /// Morning time block label
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get planMorning;

  /// Day time block label
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get planDay;

  /// Night time block label
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get planNight;

  /// Done status
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// Miss status
  ///
  /// In en, this message translates to:
  /// **'Miss'**
  String get miss;

  /// Partial status
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get partial;

  /// Over status label
  ///
  /// In en, this message translates to:
  /// **'Over'**
  String get over;

  /// Target label
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get target;

  /// Details label
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// Reason label
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reason;

  /// Points earned label
  ///
  /// In en, this message translates to:
  /// **'Points Earned'**
  String get pointsEarned;

  /// Trend and pattern section title
  ///
  /// In en, this message translates to:
  /// **'Trend & Pattern'**
  String get trendPattern;

  /// Best streak label
  ///
  /// In en, this message translates to:
  /// **'Best streak: {days} days'**
  String bestStreak(int days);

  /// Best streak label (without days)
  ///
  /// In en, this message translates to:
  /// **'Best Streak'**
  String get bestStreakLabel;

  /// Miss count label
  ///
  /// In en, this message translates to:
  /// **'Miss Count'**
  String get missCount;

  /// Last updated label
  ///
  /// In en, this message translates to:
  /// **'Last Updated'**
  String get lastUpdated;

  /// Habit analytics section title
  ///
  /// In en, this message translates to:
  /// **'Habit analytics'**
  String get habitAnalytics;

  /// Ramadan progress label
  ///
  /// In en, this message translates to:
  /// **'Ramadan Progress'**
  String get ramadanProgress;

  /// This Ramadan label
  ///
  /// In en, this message translates to:
  /// **'This Ramadan: {done}/{total} done'**
  String thisRamadan(int done, int total);

  /// Create new season button label
  ///
  /// In en, this message translates to:
  /// **'Create New Season'**
  String get createNewSeason;

  /// Create new season subtitle
  ///
  /// In en, this message translates to:
  /// **'Start a new Ramadan tracking period'**
  String get startNewRamadanTracking;

  /// Reset onboarding button label
  ///
  /// In en, this message translates to:
  /// **'Reset Onboarding'**
  String get resetOnboarding;

  /// Reset onboarding subtitle
  ///
  /// In en, this message translates to:
  /// **'Show setup wizard again on next app launch'**
  String get showSetupWizardAgain;

  /// Delete season dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Season?'**
  String get deleteSeason;

  /// Delete season warning message
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get deleteSeasonWarning;

  /// Test notification button label
  ///
  /// In en, this message translates to:
  /// **'Test Notification'**
  String get testNotification;

  /// No description provided for @goalRemindersTitle.
  ///
  /// In en, this message translates to:
  /// **'Goal Reminders'**
  String get goalRemindersTitle;

  /// No description provided for @goalRemindersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get notified when you haven\'t reached your daily goals'**
  String get goalRemindersSubtitle;

  /// No description provided for @goalReminderQuran.
  ///
  /// In en, this message translates to:
  /// **'Quran Goal Reminder'**
  String get goalReminderQuran;

  /// No description provided for @goalReminderQuranDesc.
  ///
  /// In en, this message translates to:
  /// **'Remind me if Quran target not reached (2 PM, 6 PM, 8 PM)'**
  String get goalReminderQuranDesc;

  /// No description provided for @goalReminderDhikr.
  ///
  /// In en, this message translates to:
  /// **'Dhikr Goal Reminder'**
  String get goalReminderDhikr;

  /// No description provided for @goalReminderDhikrDesc.
  ///
  /// In en, this message translates to:
  /// **'Remind me if Dhikr target not reached (2 PM, 6 PM, 8 PM)'**
  String get goalReminderDhikrDesc;

  /// No description provided for @goalReminderSedekah.
  ///
  /// In en, this message translates to:
  /// **'Sedekah Goal Reminder'**
  String get goalReminderSedekah;

  /// No description provided for @goalReminderSedekahDesc.
  ///
  /// In en, this message translates to:
  /// **'Remind me if Sedekah target not reached (4 PM)'**
  String get goalReminderSedekahDesc;

  /// No description provided for @goalReminderTaraweeh.
  ///
  /// In en, this message translates to:
  /// **'Taraweeh Reminder'**
  String get goalReminderTaraweeh;

  /// No description provided for @goalReminderTaraweehDesc.
  ///
  /// In en, this message translates to:
  /// **'Remind me 15 minutes after Isha if Taraweeh not done'**
  String get goalReminderTaraweehDesc;

  /// No description provided for @quranGoalReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Quran Goal Reminder'**
  String get quranGoalReminderTitle;

  /// Quran goal reminder notification body
  ///
  /// In en, this message translates to:
  /// **'Haven\'t reached today\'s Quran target ({current}/{target} pages). Keep going!'**
  String quranGoalReminderBody(int current, int target);

  /// No description provided for @dhikrGoalReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Dhikr Goal Reminder'**
  String get dhikrGoalReminderTitle;

  /// Dhikr goal reminder notification body
  ///
  /// In en, this message translates to:
  /// **'Dhikr target not reached ({current}/{target}). Keep it up!'**
  String dhikrGoalReminderBody(int current, int target);

  /// No description provided for @sedekahGoalReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Sedekah Goal Reminder'**
  String get sedekahGoalReminderTitle;

  /// No description provided for @sedekahGoalReminderBody.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Sedekah target not reached. Don\'t forget to share goodness!'**
  String get sedekahGoalReminderBody;

  /// No description provided for @taraweehReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Taraweeh Reminder'**
  String get taraweehReminderTitle;

  /// No description provided for @taraweehReminderBody.
  ///
  /// In en, this message translates to:
  /// **'Taraweeh time is approaching! Prepare yourself for night prayer.'**
  String get taraweehReminderBody;

  /// Test notification subtitle
  ///
  /// In en, this message translates to:
  /// **'Send a test notification to verify settings'**
  String get sendTestNotification;

  /// Test notification sent message
  ///
  /// In en, this message translates to:
  /// **'Test notification sent'**
  String get testNotificationSent;

  /// Fasting habit name
  ///
  /// In en, this message translates to:
  /// **'Fasting'**
  String get habitFasting;

  /// Quran habit name
  ///
  /// In en, this message translates to:
  /// **'Quran'**
  String get habitQuran;

  /// Dhikr habit name
  ///
  /// In en, this message translates to:
  /// **'Dhikr'**
  String get habitDhikr;

  /// Taraweeh habit name
  ///
  /// In en, this message translates to:
  /// **'Taraweeh'**
  String get habitTaraweeh;

  /// Sedekah habit name
  ///
  /// In en, this message translates to:
  /// **'Sedekah'**
  String get habitSedekah;

  /// I'tikaf habit name
  ///
  /// In en, this message translates to:
  /// **'I\'tikaf'**
  String get habitItikaf;

  /// 5 Prayers habit name
  ///
  /// In en, this message translates to:
  /// **'5 Prayers'**
  String get habitPrayers;

  /// 5 Prayers detailed mode label
  ///
  /// In en, this message translates to:
  /// **'5 Prayers (detailed)'**
  String get habitPrayersDetailed;

  /// 5 Prayers detailed mode subtitle
  ///
  /// In en, this message translates to:
  /// **'Track each prayer individually'**
  String get trackEachPrayerIndividually;

  /// Days text
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String days(int days);

  /// Error message when loading seasons
  ///
  /// In en, this message translates to:
  /// **'Error loading seasons'**
  String get errorLoadingSeasons;

  /// Reset onboarding confirmation message
  ///
  /// In en, this message translates to:
  /// **'This will show the onboarding screen again when you restart the app. Continue?'**
  String get resetOnboardingConfirm;

  /// Reset button label
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// Onboarding reset success message
  ///
  /// In en, this message translates to:
  /// **'Onboarding will show on next app restart'**
  String get onboardingWillShowOnRestart;

  /// Sahur reminder label
  ///
  /// In en, this message translates to:
  /// **'Sahur reminder'**
  String get sahurReminder;

  /// Sahur reminder offset text
  ///
  /// In en, this message translates to:
  /// **'{minutes} min before Fajr'**
  String minBeforeFajr(int minutes);

  /// Sahur reminder description
  ///
  /// In en, this message translates to:
  /// **'Get notified before suhoor time'**
  String get getNotifiedBeforeSuhoor;

  /// Iftar reminder label
  ///
  /// In en, this message translates to:
  /// **'Iftar reminder'**
  String get iftarReminder;

  /// Iftar reminder offset text
  ///
  /// In en, this message translates to:
  /// **'{minutes} min after Maghrib'**
  String minAfterMaghrib(int minutes);

  /// Iftar reminder description
  ///
  /// In en, this message translates to:
  /// **'Get notified when it\'s time to break fast'**
  String get getNotifiedWhenBreakFast;

  /// Night plan reminder label
  ///
  /// In en, this message translates to:
  /// **'Night plan reminder'**
  String get nightPlanReminder;

  /// Night plan reminder description
  ///
  /// In en, this message translates to:
  /// **'Reminder to plan your night activities'**
  String get reminderToPlanNightActivities;

  /// Calculation method label
  ///
  /// In en, this message translates to:
  /// **'Calculation Method'**
  String get calculationMethod;

  /// Calculation method description
  ///
  /// In en, this message translates to:
  /// **'Choose prayer time calculation method'**
  String get choosePrayerTimeMethod;

  /// Fajr adjustment label
  ///
  /// In en, this message translates to:
  /// **'Fajr Adjustment'**
  String get fajrAdjustment;

  /// Fajr adjustment description
  ///
  /// In en, this message translates to:
  /// **'Adjust Fajr prayer time manually'**
  String get adjustFajrManually;

  /// Maghrib adjustment label
  ///
  /// In en, this message translates to:
  /// **'Maghrib Adjustment'**
  String get maghribAdjustment;

  /// Maghrib adjustment description
  ///
  /// In en, this message translates to:
  /// **'Adjust Maghrib prayer time manually'**
  String get adjustMaghribManually;

  /// Minutes unit label (non-parameterized)
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get minutesUnit;

  /// Next reminders section title
  ///
  /// In en, this message translates to:
  /// **'Next Reminders'**
  String get nextReminders;

  /// No title placeholder
  ///
  /// In en, this message translates to:
  /// **'No title'**
  String get noTitle;

  /// No body placeholder
  ///
  /// In en, this message translates to:
  /// **'No body'**
  String get noBody;

  /// Export backup button label
  ///
  /// In en, this message translates to:
  /// **'Export Backup'**
  String get exportBackup;

  /// Export backup description
  ///
  /// In en, this message translates to:
  /// **'Save your data as JSON file'**
  String get saveDataAsJson;

  /// Import backup button label
  ///
  /// In en, this message translates to:
  /// **'Import Backup'**
  String get importBackup;

  /// Import backup description
  ///
  /// In en, this message translates to:
  /// **'Restore data from JSON backup'**
  String get restoreDataFromJson;

  /// Version label
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// Support developer label
  ///
  /// In en, this message translates to:
  /// **'Support Developer'**
  String get supportDeveloper;

  /// Buy me a coffee label
  ///
  /// In en, this message translates to:
  /// **'Buy me a coffee'**
  String get buyMeACoffee;

  /// Privacy policy label
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// Privacy policy description
  ///
  /// In en, this message translates to:
  /// **'Read our privacy policy'**
  String get readPrivacyPolicy;

  /// Terms of service label
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// Terms of service description
  ///
  /// In en, this message translates to:
  /// **'Read our terms of service'**
  String get readTermsOfService;

  /// No season found error message
  ///
  /// In en, this message translates to:
  /// **'No season found'**
  String get noSeasonFound;

  /// Fajr adjustment dialog title
  ///
  /// In en, this message translates to:
  /// **'Fajr Adjustment'**
  String get fajrAdjustmentTitle;

  /// Maghrib adjustment dialog title
  ///
  /// In en, this message translates to:
  /// **'Maghrib Adjustment'**
  String get maghribAdjustmentTitle;

  /// Import failed error message
  ///
  /// In en, this message translates to:
  /// **'Import failed: {error}'**
  String importFailed(String error);

  /// Export failed error message
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String exportFailed(String error);

  /// Import backup dialog instruction
  ///
  /// In en, this message translates to:
  /// **'Paste your backup JSON below:'**
  String get pasteBackupJson;

  /// Import backup text field hint
  ///
  /// In en, this message translates to:
  /// **'Paste JSON backup data...'**
  String get pasteJsonBackupData;

  /// Backup import success message
  ///
  /// In en, this message translates to:
  /// **'Backup imported successfully'**
  String get backupImportedSuccessfully;

  /// Generic error label
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// Error opening URL message
  ///
  /// In en, this message translates to:
  /// **'Error opening URL: {error}'**
  String errorOpeningUrl(String error);

  /// Focus mode tooltip
  ///
  /// In en, this message translates to:
  /// **'Focus Mode'**
  String get focusMode;

  /// Pre-Ramadan state label
  ///
  /// In en, this message translates to:
  /// **'Pre-Ramadan'**
  String get preRamadan;

  /// Pre-Ramadan subtitle message
  ///
  /// In en, this message translates to:
  /// **'Season not started yet. Browse and plan ahead.'**
  String get preRamadanSubtitle;

  /// Season ended label
  ///
  /// In en, this message translates to:
  /// **'Season Ended'**
  String get seasonEnded;

  /// Season ended message
  ///
  /// In en, this message translates to:
  /// **'This Ramadan season has finished. Review your progress or create a new season.'**
  String get seasonEndedMessage;

  /// Day of season subtitle
  ///
  /// In en, this message translates to:
  /// **'Day {dayIndex} of {totalDays}'**
  String dayOfSeason(int dayIndex, int totalDays);

  /// Pre-Ramadan with date
  ///
  /// In en, this message translates to:
  /// **'Pre-Ramadan • {date}'**
  String preRamadanWithDate(String date);

  /// Season ended with date
  ///
  /// In en, this message translates to:
  /// **'Season Ended • {date}'**
  String seasonEndedWithDate(String date);

  /// Error message with error text
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorMessage(String error);

  /// Last day title
  ///
  /// In en, this message translates to:
  /// **'Last Day!'**
  String get lastDay;

  /// Last day message
  ///
  /// In en, this message translates to:
  /// **'This is the final day of Ramadan. Finish strong and make it count!'**
  String get lastDayMessage;

  /// Almost there title
  ///
  /// In en, this message translates to:
  /// **'Almost There!'**
  String get almostThere;

  /// Almost there message
  ///
  /// In en, this message translates to:
  /// **'Only {days} days left. You\'ve come so far - keep going!'**
  String almostThereMessage(int days);

  /// Last 10 days title
  ///
  /// In en, this message translates to:
  /// **'Last 10 Days'**
  String get last10Days;

  /// Last 10 days message
  ///
  /// In en, this message translates to:
  /// **'These are the most blessed days. Maximize your ibadah and seek Laylatul Qadr!'**
  String get last10DaysMessage;

  /// Final stretch title
  ///
  /// In en, this message translates to:
  /// **'Final Stretch'**
  String get finalStretch;

  /// Final stretch message
  ///
  /// In en, this message translates to:
  /// **'You\'re in the last 10 days. Every moment counts - stay focused!'**
  String get finalStretchMessage;

  /// Days remaining label
  ///
  /// In en, this message translates to:
  /// **'{days} days remaining'**
  String daysRemaining(int days);

  /// Create new season message
  ///
  /// In en, this message translates to:
  /// **'Create a new Ramadan season to start tracking'**
  String get createNewSeasonMessage;

  /// Start setup button label
  ///
  /// In en, this message translates to:
  /// **'Start Setup'**
  String get startSetup;

  /// New season button label
  ///
  /// In en, this message translates to:
  /// **'New Season'**
  String get newSeason;

  /// View insights button label
  ///
  /// In en, this message translates to:
  /// **'View Insights'**
  String get viewInsights;

  /// Enable location message
  ///
  /// In en, this message translates to:
  /// **'Enable location for Sahur/Iftar'**
  String get enableLocationForSahurIftar;

  /// Enable location button label
  ///
  /// In en, this message translates to:
  /// **'Enable Location'**
  String get enableLocation;

  /// Times card title
  ///
  /// In en, this message translates to:
  /// **'Times'**
  String get times;

  /// Sahur label
  ///
  /// In en, this message translates to:
  /// **'Sahur'**
  String get sahur;

  /// Iftar label
  ///
  /// In en, this message translates to:
  /// **'Iftar'**
  String get iftar;

  /// Fajr prayer label
  ///
  /// In en, this message translates to:
  /// **'Fajr'**
  String get fajr;

  /// Maghrib prayer label
  ///
  /// In en, this message translates to:
  /// **'Maghrib'**
  String get maghrib;

  /// Today in 10 seconds card title
  ///
  /// In en, this message translates to:
  /// **'Today in 10 seconds'**
  String get todayIn10Seconds;

  /// Today in 10 seconds message
  ///
  /// In en, this message translates to:
  /// **'Tap what you did. Add pages & dhikr. Done.'**
  String get todayIn10SecondsMessage;

  /// Open one tap button label
  ///
  /// In en, this message translates to:
  /// **'Open One Tap'**
  String get openOneTap;

  /// Edit goals button label
  ///
  /// In en, this message translates to:
  /// **'Edit Goals'**
  String get editGoals;

  /// One tap today card title
  ///
  /// In en, this message translates to:
  /// **'One Tap Today'**
  String get oneTapToday;

  /// Reflection card title
  ///
  /// In en, this message translates to:
  /// **'Reflection'**
  String get reflection;

  /// Reflection text field hint
  ///
  /// In en, this message translates to:
  /// **'How was today?'**
  String get howWasToday;

  /// Streak days label
  ///
  /// In en, this message translates to:
  /// **'Streak: {days} days'**
  String streakDays(int days);

  /// Done count label
  ///
  /// In en, this message translates to:
  /// **'Done: {completed}/{total}'**
  String doneCount(int completed, int total);

  /// Error loading entries message
  ///
  /// In en, this message translates to:
  /// **'Error loading entries'**
  String get errorLoadingEntries;

  /// Error loading habits message
  ///
  /// In en, this message translates to:
  /// **'Error loading habits'**
  String get errorLoadingHabits;

  /// Excellent mood label
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get moodExcellent;

  /// Good mood label
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get moodGood;

  /// Ok mood label
  ///
  /// In en, this message translates to:
  /// **'Ok'**
  String get moodOk;

  /// Difficult mood label
  ///
  /// In en, this message translates to:
  /// **'Difficult'**
  String get moodDifficult;

  /// Error loading season message
  ///
  /// In en, this message translates to:
  /// **'Error loading season'**
  String get errorLoadingSeason;

  /// Outside season message
  ///
  /// In en, this message translates to:
  /// **'Outside season'**
  String get outsideSeason;

  /// Legend label
  ///
  /// In en, this message translates to:
  /// **'Legend'**
  String get legend;

  /// Ring equals completion legend
  ///
  /// In en, this message translates to:
  /// **'Ring = completion'**
  String get ringEqualsCompletion;

  /// Dot equals tracked legend
  ///
  /// In en, this message translates to:
  /// **'Dot = tracked'**
  String get dotEqualsTracked;

  /// Star equals last 10 legend
  ///
  /// In en, this message translates to:
  /// **'Star = last 10'**
  String get starEqualsLast10;

  /// Ring completion compact legend
  ///
  /// In en, this message translates to:
  /// **'Ring=Completion'**
  String get ringCompletionCompact;

  /// Dot tracked compact legend
  ///
  /// In en, this message translates to:
  /// **'Dot=Tracked'**
  String get dotTrackedCompact;

  /// Star last 10 compact legend
  ///
  /// In en, this message translates to:
  /// **'Star=Last 10'**
  String get starLast10Compact;

  /// Day label
  ///
  /// In en, this message translates to:
  /// **'Day {dayIndex}'**
  String dayLabel(int dayIndex);

  /// Percent complete label
  ///
  /// In en, this message translates to:
  /// **'{percent}% Complete'**
  String percentComplete(int percent);

  /// Tracked habits label
  ///
  /// In en, this message translates to:
  /// **'Tracked Habits'**
  String get trackedHabits;

  /// Close button label
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// View day button label (non-parameterized)
  ///
  /// In en, this message translates to:
  /// **'View Day'**
  String get viewDayButton;

  /// Error loading season habits message
  ///
  /// In en, this message translates to:
  /// **'Error loading season habits'**
  String get errorLoadingSeasonHabits;

  /// Not done status
  ///
  /// In en, this message translates to:
  /// **'Not done'**
  String get notDone;

  /// Quran pages format
  ///
  /// In en, this message translates to:
  /// **'{pages} / {target} pages'**
  String quranPagesFormat(int pages, int target);

  /// Dhikr count format
  ///
  /// In en, this message translates to:
  /// **'{count} / {target}'**
  String dhikrCountFormat(int count, int target);

  /// Onboarding welcome subtitle
  ///
  /// In en, this message translates to:
  /// **'Track your Ramadan in seconds'**
  String get trackYourRamadanInSeconds;

  /// Onboarding welcome privacy message
  ///
  /// In en, this message translates to:
  /// **'No account • No ads • Stored on your device'**
  String get noAccountNoAdsStored;

  /// Onboarding feature description
  ///
  /// In en, this message translates to:
  /// **'One tap daily checklist'**
  String get oneTapDailyChecklist;

  /// Onboarding feature description
  ///
  /// In en, this message translates to:
  /// **'Autopilot Qur\'an plan'**
  String get autopilotQuranPlan;

  /// Onboarding feature description
  ///
  /// In en, this message translates to:
  /// **'Sahur & Iftar reminders (automatic)'**
  String get sahurIftarRemindersAutomatic;

  /// Onboarding setup time estimate
  ///
  /// In en, this message translates to:
  /// **'Takes about 1 minute'**
  String get takesAbout1Minute;

  /// Ramadan Season label
  ///
  /// In en, this message translates to:
  /// **'Ramadan Season'**
  String get ramadanSeason;

  /// Season label field
  ///
  /// In en, this message translates to:
  /// **'Season Label'**
  String get seasonLabel;

  /// Season label hint
  ///
  /// In en, this message translates to:
  /// **'Ramadan {year}'**
  String ramadanYearHint(int year);

  /// Days count label
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String daysCount(int count);

  /// Start date label
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// Preview label
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// Day 1 preview message
  ///
  /// In en, this message translates to:
  /// **'Day 1 starts on {date}.'**
  String day1StartsOn(String date);

  /// Last 10 nights preview message
  ///
  /// In en, this message translates to:
  /// **'Last 10 nights begin on Day {day} ({date}).'**
  String last10NightsBeginOn(int day, String date);

  /// Onboarding step 3 title
  ///
  /// In en, this message translates to:
  /// **'Choose What to Track'**
  String get chooseWhatToTrack;

  /// Onboarding step 3 subtitle
  ///
  /// In en, this message translates to:
  /// **'Track only what helps. You can change anytime.'**
  String get trackOnlyWhatHelps;

  /// Quran 20 pages per day label
  ///
  /// In en, this message translates to:
  /// **'Qur\'an (20 pages/day)'**
  String get quran20PagesPerDay;

  /// Quran 40 pages per day label
  ///
  /// In en, this message translates to:
  /// **'Qur\'an (40 pages/day)'**
  String get quran40PagesPerDay;

  /// Quran custom pages per day label
  ///
  /// In en, this message translates to:
  /// **'Qur\'an ({pages} pages/day)'**
  String quranCustomPagesPerDay(int pages);

  /// Advanced section label
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get advanced;

  /// 5 Prayers simple label
  ///
  /// In en, this message translates to:
  /// **'5 Prayers (simple)'**
  String get prayersSimple;

  /// Onboarding step 4 title
  ///
  /// In en, this message translates to:
  /// **'Set Goals'**
  String get setGoals;

  /// Onboarding step 4 subtitle
  ///
  /// In en, this message translates to:
  /// **'Gentle goals beat perfect streaks.'**
  String get gentleGoalsBeatPerfectStreaks;

  /// Quran goal section title
  ///
  /// In en, this message translates to:
  /// **'Quran Goal'**
  String get quranGoal;

  /// 1 Khatam option
  ///
  /// In en, this message translates to:
  /// **'1 Khatam (20 pages/day)'**
  String get oneKhatam20Pages;

  /// 2 Khatam option
  ///
  /// In en, this message translates to:
  /// **'2 Khatam (40 pages/day)'**
  String get twoKhatam40Pages;

  /// Custom button/label
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// Pages per day text
  ///
  /// In en, this message translates to:
  /// **'{pages} pages/day'**
  String pagesPerDay(int pages);

  /// Enter pages hint
  ///
  /// In en, this message translates to:
  /// **'Enter pages'**
  String get enterPages;

  /// Total pages calculation
  ///
  /// In en, this message translates to:
  /// **'{total} total pages → {daily} pages/day for {days} days'**
  String totalPagesCalculation(int total, int daily, int days);

  /// Dhikr target section title
  ///
  /// In en, this message translates to:
  /// **'Dhikr Target'**
  String get dhikrTarget;

  /// Set daily Sedekah goal label
  ///
  /// In en, this message translates to:
  /// **'Set a daily Sedekah goal'**
  String get setDailySedekahGoal;

  /// Amount label
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// Enter amount hint
  ///
  /// In en, this message translates to:
  /// **'Enter amount'**
  String get enterAmount;

  /// Currency label
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// IDR currency label
  ///
  /// In en, this message translates to:
  /// **'IDR (Rp)'**
  String get idrRp;

  /// SGD currency label
  ///
  /// In en, this message translates to:
  /// **'SGD (S\$)'**
  String get sgdSdollar;

  /// USD currency label
  ///
  /// In en, this message translates to:
  /// **'USD (\$)'**
  String get usdDollar;

  /// MYR currency label
  ///
  /// In en, this message translates to:
  /// **'MYR (RM)'**
  String get myrRm;

  /// Onboarding step 5 title
  ///
  /// In en, this message translates to:
  /// **'Smart Reminders'**
  String get smartReminders;

  /// Onboarding step 5 subtitle
  ///
  /// In en, this message translates to:
  /// **'Get notified for Sahur, Iftar, and your daily plan.'**
  String get getNotifiedForSahurIftar;

  /// Offset label
  ///
  /// In en, this message translates to:
  /// **'Offset:'**
  String get offset;

  /// Minutes short format
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String minutesShort(int minutes);

  /// At Maghrib label
  ///
  /// In en, this message translates to:
  /// **'At Maghrib'**
  String get atMaghrib;

  /// Location label
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// Use my location button
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get useMyLocation;

  /// Set city manually button
  ///
  /// In en, this message translates to:
  /// **'Set city manually'**
  String get setCityManually;

  /// City name label
  ///
  /// In en, this message translates to:
  /// **'City name (optional)'**
  String get cityNameOptional;

  /// Jakarta hint
  ///
  /// In en, this message translates to:
  /// **'Jakarta'**
  String get jakartaHint;

  /// Latitude label
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get latitude;

  /// Latitude hint
  ///
  /// In en, this message translates to:
  /// **'-6.2088'**
  String get latitudeHint;

  /// Longitude label
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get longitude;

  /// Longitude hint
  ///
  /// In en, this message translates to:
  /// **'106.8456'**
  String get longitudeHint;

  /// Set button
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get set;

  /// Location set label
  ///
  /// In en, this message translates to:
  /// **'Location set'**
  String get locationSet;

  /// MWL calculation method
  ///
  /// In en, this message translates to:
  /// **'MWL (Muslim World League)'**
  String get mwlMuslimWorldLeague;

  /// Indonesia calculation method
  ///
  /// In en, this message translates to:
  /// **'Indonesia (Kemenag)'**
  String get indonesiaKemenag;

  /// Singapore calculation method
  ///
  /// In en, this message translates to:
  /// **'Singapore'**
  String get singapore;

  /// Umm al-Qura calculation method
  ///
  /// In en, this message translates to:
  /// **'Umm al-Qura'**
  String get ummAlQura;

  /// Karachi calculation method
  ///
  /// In en, this message translates to:
  /// **'Karachi'**
  String get karachi;

  /// Egypt calculation method
  ///
  /// In en, this message translates to:
  /// **'Egypt'**
  String get egypt;

  /// ISNA calculation method
  ///
  /// In en, this message translates to:
  /// **'ISNA (North America)'**
  String get isnaNorthAmerica;

  /// Prayer times preview label
  ///
  /// In en, this message translates to:
  /// **'Prayer Times Preview'**
  String get prayerTimesPreview;

  /// Test button
  ///
  /// In en, this message translates to:
  /// **'Test'**
  String get test;

  /// Sahur reminder time label
  ///
  /// In en, this message translates to:
  /// **'Sahur reminder'**
  String get sahurReminderLabel;

  /// Iftar reminder time label
  ///
  /// In en, this message translates to:
  /// **'Iftar reminder'**
  String get iftarReminderLabel;

  /// Finish and start button
  ///
  /// In en, this message translates to:
  /// **'Finish & Start'**
  String get finishAndStart;

  /// Location services disabled message
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled'**
  String get locationServicesDisabled;

  /// Location permissions denied message
  ///
  /// In en, this message translates to:
  /// **'Location permissions denied'**
  String get locationPermissionsDenied;

  /// Location permissions permanently denied message
  ///
  /// In en, this message translates to:
  /// **'Location permissions permanently denied'**
  String get locationPermissionsPermanentlyDenied;

  /// Invalid coordinates message
  ///
  /// In en, this message translates to:
  /// **'Please enter valid coordinates'**
  String get pleaseEnterValidCoordinates;

  /// Back button label
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Continue button label
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// Juz progress label
  ///
  /// In en, this message translates to:
  /// **'Juz: {progress}/{target}'**
  String juzProgress(String progress, int target);

  /// Pages count label
  ///
  /// In en, this message translates to:
  /// **'of {pages} pages'**
  String ofPages(int pages);

  /// Dhikr count target label
  ///
  /// In en, this message translates to:
  /// **'of {count} dhikr'**
  String ofDhikr(int count);

  /// Today amount and goal label
  ///
  /// In en, this message translates to:
  /// **'Today: {amount} / {goal}'**
  String todayAmountGoal(String amount, String goal);

  /// Custom amount dialog title
  ///
  /// In en, this message translates to:
  /// **'Custom Amount'**
  String get customAmount;

  /// Add button label
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// Fajr prayer name
  ///
  /// In en, this message translates to:
  /// **'Fajr'**
  String get prayerFajr;

  /// Dhuhr prayer name
  ///
  /// In en, this message translates to:
  /// **'Dhuhr'**
  String get prayerDhuhr;

  /// Asr prayer name
  ///
  /// In en, this message translates to:
  /// **'Asr'**
  String get prayerAsr;

  /// Isha prayer name
  ///
  /// In en, this message translates to:
  /// **'Isha'**
  String get prayerIsha;

  /// Plan screen title
  ///
  /// In en, this message translates to:
  /// **'Ramadan Autopilot'**
  String get ramadanAutopilot;

  /// Setup wizard title
  ///
  /// In en, this message translates to:
  /// **'Setup Ramadan Autopilot'**
  String get setupRamadanAutopilot;

  /// Setup wizard subtitle
  ///
  /// In en, this message translates to:
  /// **'Configure your goals and available time to generate a daily plan.'**
  String get setupRamadanAutopilotSubtitle;

  /// Available time section title
  ///
  /// In en, this message translates to:
  /// **'Available Time (minutes)'**
  String get availableTimeMinutes;

  /// Minutes display
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String minutes(int minutes);

  /// Total pages label
  ///
  /// In en, this message translates to:
  /// **'Total Pages'**
  String get totalPages;

  /// Daily target label
  ///
  /// In en, this message translates to:
  /// **'Daily Target'**
  String get dailyTarget;

  /// Save plan button label
  ///
  /// In en, this message translates to:
  /// **'Save Plan'**
  String get savePlan;

  /// Season completed message title
  ///
  /// In en, this message translates to:
  /// **'Season Completed'**
  String get seasonCompleted;

  /// Season completed message
  ///
  /// In en, this message translates to:
  /// **'Congratulations on completing Ramadan! Review your journey in the Insights tab.'**
  String get seasonCompletedMessage;

  /// New season creation message
  ///
  /// In en, this message translates to:
  /// **'New season creation coming soon'**
  String get newSeasonCreationComingSoon;

  /// Start new season button label
  ///
  /// In en, this message translates to:
  /// **'Start New Season'**
  String get startNewSeason;

  /// Recommended plan card title
  ///
  /// In en, this message translates to:
  /// **'Recommended Plan'**
  String get recommendedPlan;

  /// Recommended plan card subtitle
  ///
  /// In en, this message translates to:
  /// **'Your personalized daily guide'**
  String get recommendedPlanSubtitle;

  /// Today target section title
  ///
  /// In en, this message translates to:
  /// **'Today Target'**
  String get todayTarget;

  /// Today's plan card title
  ///
  /// In en, this message translates to:
  /// **'Today\'s Plan'**
  String get todaysPlan;

  /// Progress section title
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// Pages remaining text
  ///
  /// In en, this message translates to:
  /// **'{pages} pages remaining'**
  String pagesRemaining(int pages);

  /// Days left label
  ///
  /// In en, this message translates to:
  /// **'Days left'**
  String get daysLeft;

  /// Dhikr target label
  ///
  /// In en, this message translates to:
  /// **'Dhikr target'**
  String get dhikrTargetLabel;

  /// Daily unit label
  ///
  /// In en, this message translates to:
  /// **'daily'**
  String get daily;

  /// Gentle catch-up title
  ///
  /// In en, this message translates to:
  /// **'Gentle catch-up'**
  String get gentleCatchup;

  /// Gentle catch-up message
  ///
  /// In en, this message translates to:
  /// **'+{pages} pages/day for the next {days} days'**
  String gentleCatchupMessage(int pages, int days);

  /// After Fajr time window
  ///
  /// In en, this message translates to:
  /// **'After Fajr'**
  String get afterFajr;

  /// Midday time window
  ///
  /// In en, this message translates to:
  /// **'Midday'**
  String get midday;

  /// After Isha time window
  ///
  /// In en, this message translates to:
  /// **'After Isha'**
  String get afterIsha;

  /// 1 Khatam goal label
  ///
  /// In en, this message translates to:
  /// **'1 Khatam'**
  String get quranGoal1Khatam;

  /// 2 Khatam goal label
  ///
  /// In en, this message translates to:
  /// **'2 Khatam'**
  String get quranGoal2Khatam;

  /// Custom Quran goal label
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get quranGoalCustom;

  /// Today remaining card title
  ///
  /// In en, this message translates to:
  /// **'Today Remaining'**
  String get todayRemaining;

  /// Remaining count text
  ///
  /// In en, this message translates to:
  /// **'{count} remaining'**
  String remaining(int count);

  /// All done status
  ///
  /// In en, this message translates to:
  /// **'All done'**
  String get allDone;

  /// No tasks scheduled message
  ///
  /// In en, this message translates to:
  /// **'No tasks scheduled'**
  String get noTasksScheduled;

  /// Start reading button label
  ///
  /// In en, this message translates to:
  /// **'Start reading'**
  String get startReading;

  /// Start counter button label
  ///
  /// In en, this message translates to:
  /// **'Start counter'**
  String get startCounter;

  /// Mark done button label
  ///
  /// In en, this message translates to:
  /// **'Mark done'**
  String get markDone;

  /// Count label
  ///
  /// In en, this message translates to:
  /// **'Count'**
  String get count;

  /// Pages unit label
  ///
  /// In en, this message translates to:
  /// **'pages'**
  String get pages;

  /// Pages per day label
  ///
  /// In en, this message translates to:
  /// **'Pages per day'**
  String get pagesPerDayLabel;

  /// Days label
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get daysLabel;

  /// Quran reading task name
  ///
  /// In en, this message translates to:
  /// **'Quran Reading'**
  String get taskQuranReading;

  /// Qiyam task name
  ///
  /// In en, this message translates to:
  /// **'Qiyam'**
  String get taskQiyam;

  /// Date label
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// Habits label
  ///
  /// In en, this message translates to:
  /// **'Habits'**
  String get habits;

  /// Goals label
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get goals;

  /// Season created success dialog title
  ///
  /// In en, this message translates to:
  /// **'Season Created Successfully'**
  String get seasonCreatedSuccessfully;

  /// Season created success message
  ///
  /// In en, this message translates to:
  /// **'Your new Ramadan season has been created and is ready to use!'**
  String get seasonCreatedMessage;

  /// Season created error message
  ///
  /// In en, this message translates to:
  /// **'Error creating season: {error}'**
  String seasonCreatedError(String error);

  /// Last 7 days label
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get last7Days;

  /// Day range label
  ///
  /// In en, this message translates to:
  /// **'Day 1–Day {days}'**
  String day1ToDay(int days);

  /// 7 Days tab label
  ///
  /// In en, this message translates to:
  /// **'7 Days'**
  String get sevenDays;

  /// Change date tooltip
  ///
  /// In en, this message translates to:
  /// **'Change date'**
  String get changeDate;

  /// Date picker help text
  ///
  /// In en, this message translates to:
  /// **'Select day to analyze'**
  String get selectDayToAnalyze;

  /// Today Score title
  ///
  /// In en, this message translates to:
  /// **'Today Score'**
  String get todayScore;

  /// Day of total label
  ///
  /// In en, this message translates to:
  /// **'Day {day} of {total}'**
  String dayOfTotal(int day, int total);

  /// 7-Day Average Score title
  ///
  /// In en, this message translates to:
  /// **'7-Day Average Score'**
  String get sevenDayAverageScore;

  /// Total score label
  ///
  /// In en, this message translates to:
  /// **'Total: {score}/{max}'**
  String totalScore(int score, int max);

  /// Perfect days label
  ///
  /// In en, this message translates to:
  /// **'Perfect days {done}/{total}'**
  String perfectDays(int done, int total);

  /// Current streak label
  ///
  /// In en, this message translates to:
  /// **'Current streak: {days} days'**
  String currentStreak(int days);

  /// Season Average Score title
  ///
  /// In en, this message translates to:
  /// **'Season Average Score'**
  String get seasonAverageScore;

  /// Days completed label
  ///
  /// In en, this message translates to:
  /// **'Days completed {done}/{total}'**
  String daysCompleted(int done, int total);

  /// Perfect days only label
  ///
  /// In en, this message translates to:
  /// **'Perfect days {count}'**
  String perfectDaysOnly(int count);

  /// Longest streak label
  ///
  /// In en, this message translates to:
  /// **'Longest streak: {days} days'**
  String longestStreak(int days);

  /// View Day button label
  ///
  /// In en, this message translates to:
  /// **'View Day ({date})'**
  String viewDay(String date);

  /// Review what's missing button label
  ///
  /// In en, this message translates to:
  /// **'Review what\'s missing'**
  String get reviewWhatsMissing;

  /// Scroll down message
  ///
  /// In en, this message translates to:
  /// **'Scroll down to see Ramadan consistency heatmaps'**
  String get scrollDownToSeeHeatmaps;

  /// View Ramadan consistency button label
  ///
  /// In en, this message translates to:
  /// **'View Ramadan consistency'**
  String get viewRamadanConsistency;

  /// Weekly Review button label
  ///
  /// In en, this message translates to:
  /// **'Weekly Review'**
  String get weeklyReview;

  /// Season Report button label
  ///
  /// In en, this message translates to:
  /// **'Season Report'**
  String get seasonReport;

  /// Best day score highlight title
  ///
  /// In en, this message translates to:
  /// **'Best day score'**
  String get bestDayScore;

  /// Tarawih progress highlight title
  ///
  /// In en, this message translates to:
  /// **'Tarawih progress'**
  String get tarawihProgress;

  /// Done nights label
  ///
  /// In en, this message translates to:
  /// **'Done {done}/{total} nights'**
  String doneNights(int done, int total);

  /// Itikaf last 10 nights highlight title
  ///
  /// In en, this message translates to:
  /// **'Itikaf last 10 nights'**
  String get itikafLast10Nights;

  /// Nights label
  ///
  /// In en, this message translates to:
  /// **'{count}/10 nights'**
  String nights(int count);

  /// Sedekah total given highlight title
  ///
  /// In en, this message translates to:
  /// **'Sedekah total given'**
  String get sedekahTotalGiven;

  /// Tap to view details label
  ///
  /// In en, this message translates to:
  /// **'Tap to view details'**
  String get tapToViewDetails;

  /// Highlights section title
  ///
  /// In en, this message translates to:
  /// **'Highlights'**
  String get highlights;

  /// Task Insights section title
  ///
  /// In en, this message translates to:
  /// **'Task Insights'**
  String get taskInsights;

  /// Analytics button label
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analytics;

  /// Disabled status
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabled;

  /// Not enabled status
  ///
  /// In en, this message translates to:
  /// **'Not enabled'**
  String get notEnabled;

  /// Done Itikaf label
  ///
  /// In en, this message translates to:
  /// **'Done {done}/10 (last 10 nights)'**
  String doneItikaf(int done);

  /// Today pages average label
  ///
  /// In en, this message translates to:
  /// **'Today {pages}/{target} • Avg {avg}/{target} (last 7)'**
  String todayPagesAvg(int pages, int target, int avg);

  /// Today count average label
  ///
  /// In en, this message translates to:
  /// **'Today {count}/{target} • Avg {avg}/{target} (last 7)'**
  String todayCountAvg(int count, int target, int avg);

  /// Today amount total label
  ///
  /// In en, this message translates to:
  /// **'Today {amount} / {target} • Total {total}'**
  String todayAmountTotal(String amount, String target, String total);

  /// Today prayers perfect days label
  ///
  /// In en, this message translates to:
  /// **'Today {completed}/5 • Perfect days {perfect}/{total}'**
  String todayPrayersPerfect(int completed, int perfect, int total);

  /// Prayers completed label
  ///
  /// In en, this message translates to:
  /// **'Prayers completed'**
  String get prayersCompleted;

  /// Today breakdown card title
  ///
  /// In en, this message translates to:
  /// **'Today Breakdown'**
  String get todayBreakdown;

  /// Score breakdown card title
  ///
  /// In en, this message translates to:
  /// **'Score Breakdown'**
  String get scoreBreakdown;

  /// Go to today button label
  ///
  /// In en, this message translates to:
  /// **'Go to Today'**
  String get goToToday;

  /// Audit day button label
  ///
  /// In en, this message translates to:
  /// **'Audit day (Day {dayIndex})'**
  String auditDay(int dayIndex);

  /// Pages read label
  ///
  /// In en, this message translates to:
  /// **'Pages read'**
  String get pagesRead;

  /// Amount given label
  ///
  /// In en, this message translates to:
  /// **'Amount given'**
  String get amountGiven;

  /// No donation label
  ///
  /// In en, this message translates to:
  /// **'No donation'**
  String get noDonation;

  /// Given label
  ///
  /// In en, this message translates to:
  /// **'Given: {amount}'**
  String given(String amount);

  /// Missed days card title
  ///
  /// In en, this message translates to:
  /// **'Missed Days'**
  String get missedDays;

  /// Completed status
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// Not completed status
  ///
  /// In en, this message translates to:
  /// **'Not completed'**
  String get notCompleted;

  /// To improve label
  ///
  /// In en, this message translates to:
  /// **'To improve: {message}'**
  String toImprove(String message);

  /// Fasting completed reason
  ///
  /// In en, this message translates to:
  /// **'Fasting completed'**
  String get fastingCompleted;

  /// Fasting not completed reason
  ///
  /// In en, this message translates to:
  /// **'Fasting not completed'**
  String get fastingNotCompleted;

  /// Complete fasting to improve message
  ///
  /// In en, this message translates to:
  /// **'Complete fasting to gain {points} points'**
  String completeFastingToGain(int points);

  /// All 5 prayers completed reason
  ///
  /// In en, this message translates to:
  /// **'All 5 prayers completed'**
  String get all5PrayersCompleted;

  /// Only some prayers completed reason
  ///
  /// In en, this message translates to:
  /// **'Only {completed}/5 prayers completed'**
  String onlyPrayersCompleted(int completed);

  /// No prayers logged reason
  ///
  /// In en, this message translates to:
  /// **'No prayers logged'**
  String get noPrayersLogged;

  /// Complete remaining prayers to improve message
  ///
  /// In en, this message translates to:
  /// **'Complete remaining {remaining} prayers to gain {points} points'**
  String completeRemainingPrayers(int remaining, int points);

  /// Log all 5 prayers to improve message
  ///
  /// In en, this message translates to:
  /// **'Log all 5 prayers to gain {points} points'**
  String logAll5Prayers(int points);

  /// Target met with pages reason
  ///
  /// In en, this message translates to:
  /// **'Target met ({pages}/{target} pages)'**
  String targetMetPages(int pages, int target);

  /// Partial completion with pages reason
  ///
  /// In en, this message translates to:
  /// **'Partial completion ({pages}/{target} pages)'**
  String partialCompletionPages(int pages, int target);

  /// Target not met with pages reason
  ///
  /// In en, this message translates to:
  /// **'Target not met (0/{target} pages)'**
  String targetNotMetPages(int target);

  /// Read more pages to improve message
  ///
  /// In en, this message translates to:
  /// **'Read {remaining} more pages to gain {points} points'**
  String readMorePages(int remaining, int points);

  /// Read pages to gain points message
  ///
  /// In en, this message translates to:
  /// **'Read pages to gain {points} points'**
  String readPagesToGain(int points);

  /// Target met with count reason
  ///
  /// In en, this message translates to:
  /// **'Target met ({count}/{target})'**
  String targetMetCount(int count, int target);

  /// Partial completion with count reason
  ///
  /// In en, this message translates to:
  /// **'Partial completion ({count}/{target})'**
  String partialCompletionCount(int count, int target);

  /// Target not met with count reason
  ///
  /// In en, this message translates to:
  /// **'Target not met (0/{target})'**
  String targetNotMetCount(int target);

  /// Complete more to improve message
  ///
  /// In en, this message translates to:
  /// **'Complete {remaining} more to gain {points} points'**
  String completeMoreToGain(int remaining, int points);

  /// Dhikr completed reason
  ///
  /// In en, this message translates to:
  /// **'Dhikr completed'**
  String get dhikrCompleted;

  /// No dhikr logged reason
  ///
  /// In en, this message translates to:
  /// **'No dhikr logged'**
  String get noDhikrLogged;

  /// Complete dhikr to gain points message
  ///
  /// In en, this message translates to:
  /// **'Complete dhikr to gain {points} points'**
  String completeDhikrToGain(int points);

  /// Taraweeh completed reason
  ///
  /// In en, this message translates to:
  /// **'Taraweeh completed'**
  String get taraweehCompleted;

  /// Taraweeh not completed reason
  ///
  /// In en, this message translates to:
  /// **'Taraweeh not completed'**
  String get taraweehNotCompleted;

  /// Complete taraweeh to gain points message
  ///
  /// In en, this message translates to:
  /// **'Complete taraweeh to gain {points} points'**
  String completeTaraweehToGain(int points);

  /// Goal met reason
  ///
  /// In en, this message translates to:
  /// **'Goal met'**
  String get goalMet;

  /// Partial giving reason
  ///
  /// In en, this message translates to:
  /// **'Partial giving'**
  String get partialGiving;

  /// No giving reason
  ///
  /// In en, this message translates to:
  /// **'No giving'**
  String get noGiving;

  /// Give more to improve message
  ///
  /// In en, this message translates to:
  /// **'Give {amount} more to gain {points} points'**
  String giveMoreToGain(String amount, int points);

  /// Give to gain points message
  ///
  /// In en, this message translates to:
  /// **'Give to gain {points} points'**
  String giveToGain(int points);

  /// Itikaf completed reason
  ///
  /// In en, this message translates to:
  /// **'Itikaf completed'**
  String get itikafCompleted;

  /// Itikaf not completed reason
  ///
  /// In en, this message translates to:
  /// **'Itikaf not completed'**
  String get itikafNotCompleted;

  /// Complete itikaf to gain points message
  ///
  /// In en, this message translates to:
  /// **'Complete itikaf to gain {points} points'**
  String completeItikafToGain(int points);

  /// No pages read reason
  ///
  /// In en, this message translates to:
  /// **'No pages read'**
  String get noPagesRead;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
