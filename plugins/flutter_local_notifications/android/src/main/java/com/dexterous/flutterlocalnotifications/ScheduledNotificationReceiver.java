package com.dexterous.flutterlocalnotifications;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.util.Log;

import androidx.annotation.Keep;
import androidx.core.app.NotificationCompat;
import androidx.core.app.NotificationManagerCompat;

import org.json.JSONObject;

/**
 * Patched ScheduledNotificationReceiver that uses Android JSONObject instead of Gson.
 * Fixes silent deserialization failures in release builds caused by R8 stripping
 * Gson TypeToken generic signatures.
 */
@Keep
public class ScheduledNotificationReceiver extends BroadcastReceiver {

    private static final String TAG = "ScheduledNotifReceiver";

    @Override
    @SuppressWarnings("deprecation")
    public void onReceive(final Context context, Intent intent) {
        Log.i(TAG, "onReceive called");
        Log.d(TAG, "Intent action: " + (intent != null ? intent.getAction() : "null"));

        try {
            String notificationDetailsJson =
                intent.getStringExtra(FlutterLocalNotificationsPlugin.NOTIFICATION_DETAILS);

            if (notificationDetailsJson == null || notificationDetailsJson.isEmpty()) {
                Log.w(TAG, "JSON is null/empty, trying legacy path");
                handleLegacyNotification(context, intent);
                return;
            }

            Log.d(TAG, "JSON available, length=" + notificationDetailsJson.length());

            boolean success = tryOriginalPath(context, notificationDetailsJson);
            if (success) {
                Log.i(TAG, "Notification shown via Gson path");
                return;
            }

            Log.w(TAG, "Gson path failed, using JSONObject fallback");
            showNotificationFromJson(context, notificationDetailsJson);

        } catch (Exception e) {
            Log.e(TAG, "Error in receiver: " + e.getMessage(), e);
            try {
                showFallbackNotification(context);
            } catch (Exception fallbackError) {
                Log.e(TAG, "Fallback also failed: " + fallbackError.getMessage(), fallbackError);
            }
        }
    }

    /**
     * Try the original plugin path using Gson deserialization.
     * Returns true if successful, false if it fails (e.g. R8 stripped TypeToken).
     */
    private boolean tryOriginalPath(Context context, String notificationDetailsJson) {
        try {
            com.google.gson.Gson gson = FlutterLocalNotificationsPlugin.buildGson();
            java.lang.reflect.Type type =
                new com.google.gson.reflect.TypeToken<
                    com.dexterous.flutterlocalnotifications.models.NotificationDetails>() {}.getType();
            com.dexterous.flutterlocalnotifications.models.NotificationDetails notificationDetails =
                gson.fromJson(notificationDetailsJson, type);

            if (notificationDetails == null) {
                Log.w(TAG, "Gson deserialization returned null");
                return false;
            }

            Log.d(TAG, "Gson OK, id=" + notificationDetails.id);
            FlutterLocalNotificationsPlugin.showNotification(context, notificationDetails);
            FlutterLocalNotificationsPlugin.scheduleNextNotification(context, notificationDetails);
            return true;
        } catch (Exception e) {
            Log.w(TAG, "Gson path failed: " + e.getMessage());
            return false;
        }
    }

    /**
     * Parse notification JSON using Android built-in JSONObject and show notification directly.
     */
    private void showNotificationFromJson(Context context, String jsonStr) throws Exception {
        JSONObject json = new JSONObject(jsonStr);

        int id = json.optInt("id", 0);
        String title = json.optString("title", "Ramadan Tracker");
        String body = json.optString("body", "");
        String channelId = json.optString("channelId", "ramadan_reminders");
        String channelName = json.optString("channelName", "Ramadan Reminders");
        String channelDescription = json.optString("channelDescription", "");
        boolean playSound = json.optBoolean("playSound", true);
        boolean enableVibration = json.optBoolean("enableVibration", true);

        Log.e(TAG, "JSONObject parsed - id: " + id + ", title: " + title + ", channel: " + channelId);

        ensureNotificationChannel(context, channelId, channelName, channelDescription, enableVibration);

        int smallIconId = getSmallIconResourceId(context);

        NotificationCompat.Builder builder = new NotificationCompat.Builder(context, channelId)
            .setSmallIcon(smallIconId)
            .setContentTitle(title)
            .setContentText(body)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setWhen(System.currentTimeMillis())
            .setShowWhen(true);

        if (playSound) {
            builder.setDefaults(NotificationCompat.DEFAULT_SOUND);
        }
        if (enableVibration) {
            builder.setDefaults(builder.build().defaults | NotificationCompat.DEFAULT_VIBRATE);
        }

        if (body != null && body.length() > 40) {
            builder.setStyle(new NotificationCompat.BigTextStyle().bigText(body));
        }

        NotificationManagerCompat notificationManagerCompat = NotificationManagerCompat.from(context);
        notificationManagerCompat.notify(id, builder.build());

        Log.e(TAG, "NOTIFICATION DISPLAYED via JSONObject fallback - id: " + id);

        // Remove from scheduled cache
        FlutterLocalNotificationsPlugin.removeNotificationFromCache(context, id);
    }

    private void handleLegacyNotification(Context context, Intent intent) {
        try {
            int notificationId = intent.getIntExtra("notification_id", 0);
            Notification notification;

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                notification = intent.getParcelableExtra("notification", Notification.class);
            } else {
                notification = intent.getParcelableExtra("notification");
            }

            if (notification == null) {
                Log.e(TAG, "Legacy path: notification parcelable is null. ID: " + notificationId);
                FlutterLocalNotificationsPlugin.removeNotificationFromCache(context, notificationId);
                return;
            }

            notification.when = System.currentTimeMillis();
            NotificationManagerCompat notificationManager = NotificationManagerCompat.from(context);
            notificationManager.notify(notificationId, notification);
            Log.e(TAG, "Legacy notification displayed. ID: " + notificationId);

            boolean repeat = intent.getBooleanExtra("repeat", false);
            if (!repeat) {
                FlutterLocalNotificationsPlugin.removeNotificationFromCache(context, notificationId);
            }
        } catch (Exception e) {
            Log.e(TAG, "Error in legacy path: " + e.getMessage(), e);
        }
    }

    private void showFallbackNotification(Context context) {
        String channelId = "ramadan_reminders";
        ensureNotificationChannel(context, channelId, "Ramadan Reminders", "", true);

        NotificationCompat.Builder builder = new NotificationCompat.Builder(context, channelId)
            .setSmallIcon(getSmallIconResourceId(context))
            .setContentTitle("Ramadan Reminder")
            .setContentText("You have a reminder. Open the app for details.")
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH);

        NotificationManagerCompat.from(context).notify(88888, builder.build());
        Log.e(TAG, "Fallback notification shown");
    }

    private void ensureNotificationChannel(
            Context context, String channelId, String channelName,
            String channelDescription, boolean enableVibration) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationManager nm =
                (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
            if (nm != null) {
                NotificationChannel existing = nm.getNotificationChannel(channelId);
                if (existing == null) {
                    Log.e(TAG, "Creating channel: " + channelId);
                    NotificationChannel channel = new NotificationChannel(
                        channelId, channelName, NotificationManager.IMPORTANCE_HIGH);
                    if (channelDescription != null && !channelDescription.isEmpty()) {
                        channel.setDescription(channelDescription);
                    }
                    channel.enableVibration(enableVibration);
                    nm.createNotificationChannel(channel);
                }
            }
        }
    }

    private int getSmallIconResourceId(Context context) {
        try {
            int iconId = context.getResources().getIdentifier(
                "ic_launcher", "mipmap", context.getPackageName());
            if (iconId != 0) return iconId;
        } catch (Exception e) {
            // ignore
        }
        return android.R.drawable.ic_dialog_info;
    }
}
