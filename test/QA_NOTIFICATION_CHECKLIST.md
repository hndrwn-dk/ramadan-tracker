# Notification QA checklist (manual)

Run after changes to `NotificationService` or `GoalReminderService`.
Open the app once after each scenario so `rescheduleAllReminders` runs.

## Prerequisites

- Android device or emulator with notification permission granted

## Scenarios

### 1. No season (skip onboarding)

1. Fresh install or clear app data
2. Choose language, then **Skip for now**
3. Wait on main screen ~10s

**Expected:** No Quran / Sedekah / Dhikr / Taraweeh **goal** notifications.
Sunnah-fast evening reminders may still appear (year-round).

### 2. Post-Ramadan (season ended)

1. Use regression seed or an account whose Ramadan season ended
2. Open app

**Expected:** No goal reminders for today.
Stale goal notifications cleared after reschedule.

### 3. Active season, no targets

1. Active Ramadan season with Quran habit disabled or no quran plan
2. Sedekah goal disabled
3. Open app on an active season day

**Expected:** No goal reminders without a baseline target.

### 4. Active season with targets

1. Active season with Quran plan (e.g. 20 pages/day) and sedekah goal enabled
2. Leave habits incomplete before reminder times (14:00 / 16:00 / 18:00 / 20:00 local)

**Expected:** Goal reminders only on active season days for incomplete habits.

## Automated coverage

- `test/notification_season_resolver_test.dart`
- `test/goal_reminder_service_test.dart`
- `test/regression_seeder_test.dart`
- `integration_test/regression_emulator_test.dart` with `REGRESSION_SEED=true`
