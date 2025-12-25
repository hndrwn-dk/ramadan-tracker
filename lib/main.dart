import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/app/app.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/data/providers/database_provider.dart';
import 'package:ramadan_tracker/domain/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    final database = AppDatabase();
    await database.initialize();
    
    try {
      await NotificationService.initialize();
    } catch (e) {
      // Notification initialization failed, but continue app
      debugPrint('NotificationService initialization failed: $e');
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

