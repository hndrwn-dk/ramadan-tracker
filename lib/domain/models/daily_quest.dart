/// A single daily micro-goal for engagement.
class DailyQuest {
  final String id;
  final String titleKey;
  final int xpReward;

  const DailyQuest({
    required this.id,
    required this.titleKey,
    required this.xpReward,
  });
}

/// Progress for one quest on a given season day.
class DailyQuestProgress {
  final String questId;
  final bool completed;

  const DailyQuestProgress({required this.questId, required this.completed});
}
