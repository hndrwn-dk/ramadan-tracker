import 'package:flutter_riverpod/flutter_riverpod.dart';

final tabIndexProvider = StateProvider<int>((ref) => 0);

// Provider to trigger scroll to a specific habit in Today screen
final scrollToHabitKeyProvider = StateProvider<String?>((ref) => null);

