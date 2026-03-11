package com.focustrack.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class ScreenTimeWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_screen_time).apply {
                setTextViewText(R.id.tv_today_time, widgetData.getString("todayTime", "0m"))
                setTextViewText(R.id.tv_top_app, widgetData.getString("topApp", "▸ No data"))
                setTextViewText(R.id.tv_session_count, widgetData.getString("sessionCount", "0") + " sessions")
                setTextViewText(R.id.tv_app_count, widgetData.getString("appCount", "0") + " apps")
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
