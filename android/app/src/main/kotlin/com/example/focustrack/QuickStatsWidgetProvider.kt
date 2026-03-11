package com.focustrack.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class QuickStatsWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_quick_stats).apply {
                setTextViewText(R.id.tv_qs_time, widgetData.getString("qsTime", "0m"))
                setTextViewText(R.id.tv_qs_apps, widgetData.getString("qsApps", "0"))
                setTextViewText(R.id.tv_qs_sessions, widgetData.getString("qsSessions", "0"))
                setTextViewText(R.id.tv_qs_focus, widgetData.getString("qsFocus", "0"))
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
