package com.focustrack.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class FocusScoreWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_focus_score).apply {
                setTextViewText(R.id.tv_focus_score, widgetData.getString("focusScore", "0"))
                setTextViewText(R.id.tv_focus_label, widgetData.getString("focusLabel", "--"))
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
