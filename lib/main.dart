import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/app/app.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/data/providers/database_provider.dart';
import 'package:ramadan_tracker/domain/services/notification_service.dart';
import 'package:ramadan_tracker/testing/regression_seeder.dart';
import 'package:ramadan_tracker/utils/log_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize log service
  LogService.init();
  LogService.log('=== App Started ===');
  
  const regressionSeed = bool.fromEnvironment('REGRESSION_SEED');
  
  try {
    AppDatabase database = AppDatabase();
    await database.initialize();

    if (regressionSeed) {
      LogService.log('=== REGRESSION_SEED: wiping and seeding scenario ===');
      await database.wipeDatabase();
      database = AppDatabase();
      await database.initialize();
      final result = await RegressionSeeder.seed(database);
      LogService.log(
        'Regression seed: season ${result.seasonId}, '
        '${result.fastedDays} fasted, ${result.haidDays} haid, '
        '${result.sickDays} sick, ${result.syawalDays} syawal',
      );
    }
    
    if (!regressionSeed) {
      try {
        debugPrint('=== STARTING NotificationService.initialize() ===');
        await NotificationService.initialize();
        debugPrint('=== NotificationService.initialize() COMPLETED ===');
      } catch (e, stackTrace) {
        debugPrint('=== NotificationService initialization FAILED ===');
        debugPrint('Error: $e');
        debugPrint('Stack trace: $stackTrace');
      }
    } else {
      debugPrint('=== REGRESSION_SEED: skipping NotificationService.initialize() ===');
    }
    
    runApp(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
        ],
        child: const RamadanCompanionApp(),
      ),
    );
  } catch (e, stackTrace) {
    // Show error screen if initialization fails
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Initialization Error: $e'),
                const SizedBox(height: 8),
                Text('$stackTrace', style: const TextStyle(fontSize: 10)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

