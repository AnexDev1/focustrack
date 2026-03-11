package com.focustrack.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class TopAppsWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_top_apps).apply {
                setTextViewText(R.id.tv_top1_name, widgetData.getString("top1Name", "--"))
                setTextViewText(R.id.tv_top1_time, widgetData.getString("top1Time", "--"))
                setTextViewText(R.id.tv_top2_name, widgetData.getString("top2Name", "--"))
                setTextViewText(R.id.tv_top2_time, widgetData.getString("top2Time", "--"))
                setTextViewText(R.id.tv_top3_name, widgetData.getString("top3Name", "--"))
                setTextViewText(R.id.tv_top3_time, widgetData.getString("top3Time", "--"))
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
