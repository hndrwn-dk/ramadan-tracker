# Engagement Gamification Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or executing-plans. Steps use checkbox syntax.

**Goal:** Ship Phase 1 achievements (schema, service, celebration UI, gallery) plus quick UX l10n fixes; scaffold Phase 2 quest types.

**Architecture:** Achievement catalog in Dart; unlock state in Drift v7; `AchievementService` evaluates triggers after habit/score changes; Riverpod exposes pending celebrations queue; UI modals drain queue on Today screen.

**Tech Stack:** Flutter, Riverpod, Drift, EN/ID l10n

---

## Phase 1 — Foundation

### Task 1: Schema v7

- [ ] Add `UserAchievements` and `UserEngagement` tables to `tables.dart`
- [ ] Add `UserAchievementsDao`, `UserEngagementDao` in `daos.dart`
- [ ] Register in `app_database.dart`, bump `schemaVersion` to 7, migration `from < 7`
- [ ] Run `flutter pub run build_runner build --delete-conflicting-outputs`

### Task 2: Domain models

- [ ] `lib/domain/models/achievement_model.dart` — `AchievementDefinition`, catalog
- [ ] `lib/domain/models/companion_level.dart` — XP → level mapping

### Task 3: AchievementService (TDD)

- [ ] `test/achievement_service_test.dart` — first_log, streak_7, mercy on excused days
- [ ] `lib/domain/services/achievement_service.dart` — unlock, XP award, evaluate triggers

### Task 4: Providers

- [ ] `lib/data/providers/achievement_provider.dart` — unlocked list, pending celebrations

### Task 5: UI

- [ ] `lib/features/engagement/widgets/celebration_overlay.dart`
- [ ] `lib/features/engagement/achievements_screen.dart`
- [ ] Today hero badge strip; Settings link to achievements
- [ ] Wire celebration listener in `MainScreen` or `TodayScreen`

### Task 6: l10n UX pass

- [ ] `ScoreRing` — accept label param, use l10n from callers
- [ ] Sunnah nav label via l10n
- [ ] Weekly review bottom sheet strings to arb

### Task 7: Verify

- [ ] `flutter test`
- [ ] `flutter analyze`

---

## Phase 2 — Quests (next session)

- [ ] `DailyQuest` model + generator
- [ ] Today quests card
- [ ] Weekly review quest summary

## Phase 3 — Levels & journey map

- [ ] Companion level chip on Today
- [ ] Month tab journey overlay

## Phase 4 — Widget & share

- [ ] Achievement share card
- [ ] Widget quick-log intent

## Phase 5 — Insights trophies

- [ ] Season report trophy case
- [ ] Habit mastery tiers
