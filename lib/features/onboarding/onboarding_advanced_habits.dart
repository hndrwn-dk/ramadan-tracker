const List<String> kAdvancedHabitKeys = ['prayers', 'tahajud', 'itikaf'];

bool hasAdvancedHabitsSelected(Set<String> selectedHabits) {
  return selectedAdvancedHabitKeys(selectedHabits).isNotEmpty;
}

List<String> selectedAdvancedHabitKeys(Set<String> selectedHabits) {
  return kAdvancedHabitKeys
      .where((key) => selectedHabits.contains(key))
      .toList();
}
