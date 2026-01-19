package com.tursinalabs.ramadan.tracker

import android.app.NotificationManager
import android.content.Context
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.ramadan_tracker/notifications"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Ensure notification manager is properly initialized
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            if (!notificationManager.areNotificationsEnabled()) {
                // Notifications are disabled
                android.util.Log.w("MainActivity", "Notifications are disabled!")
            }
        }
        
        // Setup MethodChannel for notification database clearing
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            android.util.Log.d("MainActivity", "MethodChannel called: ${call.method}")
            when (call.method) {
                "clearNotificationDatabase" -> {
                    android.util.Log.d("MainActivity", "clearNotificationDatabase method called")
                    try {
                        val success = clearNotificationDatabase()
                        android.util.Log.d("MainActivity", "clearNotificationDatabase result: $success")
                        result.success(success)
                    } catch (e: Exception) {
                        android.util.Log.e("MainActivity", "Error in clearNotificationDatabase handler: ${e.message}", e)
                        result.error("ERROR", "Failed to clear database: ${e.message}", null)
                    }
                }
                else -> {
                    android.util.Log.w("MainActivity", "Unknown method: ${call.method}")
                    result.notImplemented()
                }
            }
        }
        android.util.Log.d("MainActivity", "MethodChannel configured: $CHANNEL")
    }

    private fun clearNotificationDatabase(): Boolean {
        return try {
            android.util.Log.d("MainActivity", "=== clearNotificationDatabase START ===")
            
            // Method 1: Clear FlutterSharedPreferences notification keys
            try {
                val prefs = getSharedPreferences(
                    "FlutterSharedPreferences",
                    Context.MODE_PRIVATE
                )
                
                val editor = prefs.edit()
                
                // Remove all notification-related keys
                val allKeys = prefs.all.keys
                var removedCount = 0
                android.util.Log.d("MainActivity", "Found ${allKeys.size} total keys in FlutterSharedPreferences")
                
                allKeys.forEach { key ->
                    if (key.contains("flutter.scheduled_notifications") || 
                        key.contains("flutter.notification") ||
                        key.contains("scheduled_notifications") ||
                        key.contains("notification") ||
                        key.contains("flutter.notification")) {
                        editor.remove(key)
                        removedCount++
                        android.util.Log.d("MainActivity", "Removed key: $key")
                    }
                }
                
                // Use commit() instead of apply() to ensure immediate write
                val committed = editor.commit()
                android.util.Log.d("MainActivity", "Removed $removedCount notification-related keys. Committed: $committed")
            } catch (e: Exception) {
                android.util.Log.e("MainActivity", "Error clearing FlutterSharedPreferences: ${e.message}", e)
            }
            
            // Method 2: Clear flutter_local_notifications_plugin preferences
            try {
                val notifPrefs = getSharedPreferences(
                    "flutter_local_notifications_plugin",
                    Context.MODE_PRIVATE
                )
                val cleared = notifPrefs.edit().clear().commit()
                android.util.Log.d("MainActivity", "Cleared flutter_local_notifications_plugin preferences. Committed: $cleared")
            } catch (e: Exception) {
                android.util.Log.w("MainActivity", "Could not clear plugin preferences: ${e.message}")
            }
            
            // Method 3: Delete SharedPreferences files directly
            try {
                val sharedPrefsDir = File(applicationContext.filesDir.parent, "shared_prefs")
                if (sharedPrefsDir.exists() && sharedPrefsDir.isDirectory) {
                    val files = sharedPrefsDir.listFiles()
                    android.util.Log.d("MainActivity", "Found ${files?.size ?: 0} files in shared_prefs directory")
                    
                    files?.forEach { file ->
                        val fileName = file.name
                        if (fileName.contains("notification") || 
                            fileName.contains("flutter") ||
                            fileName == "FlutterSharedPreferences.xml") {
                            try {
                                val deleted = file.delete()
                                android.util.Log.d("MainActivity", "Deleted file: $fileName. Success: $deleted")
                            } catch (e: Exception) {
                                android.util.Log.w("MainActivity", "Could not delete $fileName: ${e.message}")
                            }
                        }
                    }
                }
            } catch (e: Exception) {
                android.util.Log.w("MainActivity", "Error deleting SharedPreferences files: ${e.message}")
            }
            
            // Method 4: Clear all FlutterSharedPreferences (more aggressive)
            try {
                val prefs = getSharedPreferences(
                    "FlutterSharedPreferences",
                    Context.MODE_PRIVATE
                )
                val allCleared = prefs.edit().clear().commit()
                android.util.Log.d("MainActivity", "Cleared ALL FlutterSharedPreferences. Committed: $allCleared")
            } catch (e: Exception) {
                android.util.Log.e("MainActivity", "Error clearing all FlutterSharedPreferences: ${e.message}", e)
            }
            
            android.util.Log.d("MainActivity", "=== clearNotificationDatabase COMPLETE ===")
            true
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "FATAL Error clearing notification database: ${e.message}", e)
            e.printStackTrace()
            false
        }
    }
}

