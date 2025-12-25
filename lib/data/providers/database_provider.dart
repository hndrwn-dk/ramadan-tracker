import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('Database provider must be overridden');
});

