# Engagement & Gamification Design Spec

**Status:** Approved — aligned with shipped code (July 2026)  
**Principle:** Ibadah encouragement, not fitness competition. Private by default. Excused days (haid, nifas, sick) never punish streaks or achievements.

## Already shipped (do not replace)

| Area | Implementation |
|------|----------------|
| Schema v7 | `user_achievements`, `user_engagement` — `app_database.dart` |
| Achievements | 15 keys in `AchievementCatalog`, `AchievementService`, celebration modal |
| XP / levels | `CompanionLevel`, `userEngagementDao.addXp`, Today journey strip, Month journey card |
| Daily quests | `DailyQuestService` + `CompactDailyQuestsStrip` on Today hero (3/day, 15 XP) |
| Gallery | `AchievementsScreen`, achievement dots on Month calendar |
| Navigation | 5 tabs; Settings via app bar; Sunnah label localized |
| Widget | Android read-only Hijri + sunnah status |
| Weekly | `WeeklyAchievementsCard`, localized `WeeklyReviewBottomSheet` |
| Post-season | `SeasonTrophySheet` on Month tab |
| **Today checklist (Jul 2026 UX)** | `TodayChecklistBody` + `ChecklistHabitCard` — progress header, typed habits, uzur fasting, accordion numeric chips — see [UX roadmap status](2026-07-05-engagement-ux-roadmap-status.md) |
| **Today trends** | `TodayHabitTrendsCard` on home hero area |

## Mercy rules

- Streak achievements use score ≥ 60 on non-excused days (fasting excused still counts other habits).
- Streak shields: 2 per season, auto-applied on excused fasting days (see `StreakShieldService`).
- No shame notifications; celebrations are opt-in dismiss.

## Companion tiers (localized)

| Level | EN | ID |
|-------|----|----|
| 1–3 | Mubtadi | Mubtadi |
| 4–6 | Mumayyiz | Mumayyiz |
| 7–10 | Mujahid | Mujahid |

XP thresholds: 0, 100, 250, 500, 900, 1400, 2000, 2800, 3800, 5000.

## Phase 2 extensions (additive)

- Pre-Ramadan prep quests (KV, no season required)
- Sunnah monthly challenge progress (Senin-Kamis count, Shawwal)
- Weekly review quest completion summary

## Phase 3–5 extensions (additive)

- Streak shields UI on Today journey strip
- Widget quick-log sunnah fast (Android intent)
- Achievement share card (extends sunnah share pattern)
- Season report trophy grid
- Habit mastery tiers (Bronze/Silver/Gold by season consistency)
- Rotating reflection prompts on Today

## Out of scope

Accounts, cloud sync, leaderboards, iOS widget parity, paid economy.
