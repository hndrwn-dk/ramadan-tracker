import 'package:flutter_test/flutter_test.dart';
import 'package:ramadan_tracker/features/onboarding/onboarding_advanced_habits.dart';

void main() {
  test('reports no advanced habits when only defaults are selected', () {
    expect(
      hasAdvancedHabitsSelected({
        'fasting',
        'quran_pages',
        'dhikr',
        'taraweeh',
        'sedekah',
      }),
      isFalse,
    );
  });

  test('reports advanced habits in stable order', () {
    expect(
      selectedAdvancedHabitKeys({'itikaf', 'prayers', 'sedekah'}),
      ['prayers', 'itikaf'],
    );
  });
}
