bool isSedekahGoalReadyToContinue({
  required bool goalEnabled,
  required int amount,
}) {
  if (!goalEnabled) return true;
  return amount > 0;
}
