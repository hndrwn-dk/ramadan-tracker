# Engagement & Gamification Design

**Date:** 2026-07-03  
**Status:** Approved for implementation

## Goal

Add worship-appropriate gamification (achievements, XP, companion level, daily quests, celebrations) to increase daily engagement across Ramadan, year-round sunnah, and insights — without accounts, leaderboards, or shame mechanics.

## Principles

1. **Private by default** — all progress stays on device; sharing is opt-in via image cards.
2. **Mercy rules** — excused fasting (sick, haid, nifas) never breaks streaks or blocks achievements tied to consistency.
3. **Gentle tone** — celebrate milestones; never punish missed days with negative copy.
4. **Offline-first** — no network required; engagement data in Drift alongside habit data.

## Data model (schema v7)

### `user_achievements`

| Column | Type | Notes |
|--------|------|-------|
| achievement_key | TEXT PK | Stable id e.g. `first_log`, `streak_7` |
| unlocked_at | INT | Epoch ms |
| season_id | INT nullable | Null = global / year-round |

### `user_engagement`

Single-row table (id=1):

| Column | Type | Notes |
|--------|------|-------|
| total_xp | INT | Cumulative XP |
| companion_level | INT | Derived from XP tiers |
| updated_at | INT | Epoch ms |

Achievement **definitions** live in Dart (`AchievementDefinitions`) — not DB — for easy localization and versioning.

## Launch achievements (~15)

| Key | Trigger | XP |
|-----|---------|-----|
| `first_log` | Any habit logged | 10 |
| `first_full_day` | Score >= 80% on any day | 25 |
| `streak_3` | 3-day habit streak | 30 |
| `streak_7` | 7-day streak | 50 |
| `streak_14` | 14-day streak | 75 |
| `quran_half` | Quran plan 50% season progress | 40 |
| `quran_complete` | Quran plan 100% | 100 |
| `season_complete` | Active season ended with >= 1 log | 150 |
| `first_sunnah` | First sunnah fast logged | 20 |
| `senin_kamis_4` | 4 Mon/Thu fasts in one month | 40 |
| `shawwal_complete` | Shawwal 6 fasts in one season window | 60 |
| `reflection_first` | First mood/reflection saved | 15 |
| `last_10_hero` | Log on any last-10 night | 35 |
| `weekly_perfect` | 7 consecutive days score >= 60 | 80 |
| `companion_level_5` | Reach companion level 5 | 0 (meta) |

## Companion levels

XP thresholds: L1=0, L2=100, L3=250, L4=500, L5=900, L6=1400, L7=2000, L8=2800, L9=3800, L10=5000.

Localized tier names: Mubtadi (Beginner) through Mujahid (Striving).

## UI surfaces (Phase 1)

- **Today hero** — compact badge strip (3 recent + count)
- **Celebration modal** — on unlock (icon, title, XP gained)
- **Achievements screen** — grid from Settings or Insights entry; locked/unlocked states
- **ScoreRing** — localize "Score" label

## Phase 2+ (deferred in Phase 1 code)

- Daily quests card on Today
- Monthly sunnah challenges
- Month journey map
- Widget quick-log
- Season trophy case in season report

## Notifications

Achievement unlocks show in-app modal only in Phase 1. Optional local notification in Phase 2 (rate-limited).

## l10n

All new strings in `app_en.arb` and `app_id.arb`.
