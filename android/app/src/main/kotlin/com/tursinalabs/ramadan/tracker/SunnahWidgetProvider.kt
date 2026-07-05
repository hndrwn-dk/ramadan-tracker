package com.tursinalabs.ramadan.tracker

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.os.Build
import android.util.Log
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class SunnahWidgetProvider : HomeWidgetProvider() {

    companion object {
        private const val TAG = "SunnahWidget"
        private const val REQ_OPEN_APP = 41
        private const val REQ_ACTION = 42
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            try {
                val views = buildViews(context, widgetData)
                appWidgetManager.updateAppWidget(widgetId, views)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to update widget $widgetId", e)
            }
        }
    }

    private fun buildViews(context: Context, widgetData: SharedPreferences): RemoteViews {
        val hijri = widgetData.getString("hijri_date", null) ?: "-"
        val sunnah = widgetData.getString("sunnah_today", null) ?: "-"
        val event = widgetData.getString("next_event", null)?.takeIf { it.isNotBlank() } ?: "-"
        val logLabel = widgetData.getString("widget_log_label", null) ?: "Log fast"
        val actionUri = widgetData.getString(
            "widget_action_uri",
            "ramadantracker://log_sunnah",
        ) ?: "ramadantracker://log_sunnah"

        return RemoteViews(context.packageName, R.layout.sunnah_widget).apply {
            setTextViewText(R.id.widget_hijri_date, hijri)
            setTextViewText(R.id.widget_sunnah, sunnah)
            setTextViewText(R.id.widget_event, event)
            setTextViewText(R.id.widget_log_btn, logLabel)

            setOnClickPendingIntent(
                R.id.widget_root,
                launchPendingIntent(context, null, REQ_OPEN_APP),
            )
            setOnClickPendingIntent(
                R.id.widget_log_btn,
                launchPendingIntent(context, Uri.parse(actionUri), REQ_ACTION),
            )
        }
    }

    private fun launchPendingIntent(
        context: Context,
        uri: Uri?,
        requestCode: Int,
    ): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            data = uri
            action = HomeWidgetLaunchIntent.HOME_WIDGET_LAUNCH_ACTION
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        var flags = PendingIntent.FLAG_UPDATE_CURRENT
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            flags = flags or PendingIntent.FLAG_IMMUTABLE
        }
        return PendingIntent.getActivity(context, requestCode, intent, flags)
    }
}
