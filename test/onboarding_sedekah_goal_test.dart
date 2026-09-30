import 'package:flutter_test/flutter_test.dart';
import 'package:ramadan_tracker/features/onboarding/onboarding_sedekah_goal.dart';

void main() {
  test('allows continue when sedekah goal is off', () {
    expect(
      isSedekahGoalReadyToContinue(goalEnabled: false, amount: 0),
      isTrue,
    );
  });

  test('blocks continue when sedekah goal is on and amount is empty', () {
    expect(
      isSedekahGoalReadyToContinue(goalEnabled: true, amount: 0),
      isFalse,
    );
  });

  test('allows continue when sedekah goal is on and amount is positive', () {
    expect(
      isSedekahGoalReadyToContinue(goalEnabled: true, amount: 10000),
      isTrue,
    );
  });
}
