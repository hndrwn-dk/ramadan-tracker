# Integration tests

## Post-Ramadan regression (emulator / device)

Seeds a completed 30-day Ramadan + 6 Syawal fasts, then asserts year-round UI:

- **Today:** season ended card
- **Month:** sunnah calendar (not Ramadan 30-day legend)
- **Sunnah:** not Ramadan focus mode
- **Wawasan:** sunnah insights + “Lihat ringkasan Ramadan”

```bash
flutter test integration_test/regression_emulator_test.dart \
  -d <device_id> \
  --dart-define=REGRESSION_SEED=true
```

Cold start can take up to ~2 minutes while the harness dismisses onboarding and waits for the nav bar.

## Unit tests (no device)

```bash
flutter test test/regression_seeder_test.dart
flutter test test/notification_season_resolver_test.dart
```

See also `test/QA_NOTIFICATION_CHECKLIST.md` for manual notification verification.
