# ProGuard rules for Ramadan Tracker
# Fixes "Missing type parameter" error in release builds caused by R8/ProGuard stripping generic signatures
# Required for flutter_local_notifications Gson TypeToken deserialization
#
# VERIFICATION INSTRUCTIONS:
# 1. Build release APK: flutter clean && flutter build apk --release
# 2. Install on device: adb install build/app/outputs/flutter-apk/app-release.apk
# 3. Test scheduled notifications:
#    - Open app, complete onboarding
#    - Use Settings > Debug > "Schedule Test in 60s" 
#    - Verify notification appears after 60 seconds
#    - Use Settings > Debug > "Run Notification Diagnostic"
#    - Check logs for "Scheduling health check: OK" (should NOT see "Missing type parameter")
# 4. If "Missing type parameter" still appears:
#    - Verify proguard-rules.pro is in android/app/
#    - Verify build.gradle references proguard-rules.pro in release block
#    - Check that minifyEnabled true and shrinkResources true are set
#    - Rebuild with: flutter clean && flutter build apk --release

# CRITICAL: Keep generic type signatures needed by Gson TypeToken
# Without Signature attribute, TypeToken cannot deserialize generic types
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes InnerClasses,EnclosingMethod
-keepattributes Exceptions

# Gson keep rules (required for JSON deserialization of scheduled notifications)
# Keep ALL Gson classes and their members
-keep class com.google.gson.** { *; }
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class com.google.gson.reflect.TypeToken$* { *; }
# Keep ALL classes that extend TypeToken (including anonymous inner classes)
-keep class * extends com.google.gson.reflect.TypeToken
-keepclassmembers class * extends com.google.gson.reflect.TypeToken {
    <init>(...);
}
# Keep all TypeToken constructors and methods
-keepclassmembers class com.google.gson.reflect.TypeToken {
    <init>();
    <init>(java.lang.reflect.Type);
    protected <init>(java.lang.reflect.Type, java.lang.reflect.Type);
    public java.lang.reflect.Type getType();
    public java.lang.Class getRawType();
}
-dontwarn com.google.gson.**

# flutter_local_notifications keep rules (prevents R8 from stripping notification models)
# Keep ALL classes and members from flutter_local_notifications package
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.dexterous.flutterlocalnotifications.models.** { *; }
-keepclassmembers class com.dexterous.flutterlocalnotifications.** { *; }
# Keep ALL methods in FlutterLocalNotificationsPlugin (especially loadScheduledNotifications)
-keepclassmembers class com.dexterous.flutterlocalnotifications.FlutterLocalNotificationsPlugin {
    *;
}
# Keep all constructors and methods that might use TypeToken
-keepclassmembers class com.dexterous.flutterlocalnotifications.** {
    <init>(...);
    *;
}
-dontwarn com.dexterous.flutterlocalnotifications.**

# Keep all scheduled notification models and their generic types
-keep class com.dexterous.flutterlocalnotifications.models.ScheduledNotification { *; }
-keep class com.dexterous.flutterlocalnotifications.models.NotificationDetails { *; }
-keep class com.dexterous.flutterlocalnotifications.models.AndroidNotificationDetails { *; }
-keep class com.dexterous.flutterlocalnotifications.models.DarwinNotificationDetails { *; }

# CRITICAL: Keep all anonymous inner classes that might be TypeToken instances
# These are often obfuscated to names like u1.a, u2.b, etc.
# We need to keep them with their generic signatures intact
-keepclassmembers class * {
    <init>(...);
}
# Keep all inner classes (including anonymous) that extend TypeToken
-keep class *$* extends com.google.gson.reflect.TypeToken { *; }
# Keep all classes that might be used by Gson for deserialization
-keepnames class * extends com.google.gson.reflect.TypeToken
# Don't obfuscate TypeToken and its subclasses
-keepnames class com.google.gson.reflect.TypeToken
-keepnames class * extends com.google.gson.reflect.TypeToken

# CRITICAL: Prevent R8 from optimizing Gson and flutter_local_notifications
# R8 full mode can strip generic type signatures even with -keepattributes Signature
# This causes ScheduledNotificationReceiver to fail silently when deserializing notification data
-dontoptimize

# Keep all classes with generic signatures used by Gson reflection
-keep,allowobfuscation class * extends com.google.gson.reflect.TypeToken
-keep class * extends com.google.gson.reflect.TypeToken {
    <fields>;
    <init>(...);
}

# Prevent R8 from removing ParameterizedType implementations
-keep class * implements java.lang.reflect.ParameterizedType {
    *;
}

# Keep Gson internal classes needed for TypeToken resolution
-keep class com.google.gson.internal.** { *; }
-keep class com.google.gson.stream.** { *; }

# Additional Flutter/Dart keep rules
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.**
