package com.tursinalabs.ramadan.tracker

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class SunnahWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.sunnah_widget).apply {
                val hijri = widgetData.getString("hijri_date", "-") ?: "-"
                val sunnah = widgetData.getString("sunnah_today", "-") ?: "-"
                val event = widgetData.getString("next_event", "-") ?: "-"

                setTextViewText(R.id.widget_hijri_date, hijri)
                setTextViewText(R.id.widget_sunnah, sunnah)
                setTextViewText(R.id.widget_event, event)

                val launchIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java
                )
                setOnClickPendingIntent(R.id.widget_root, launchIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
