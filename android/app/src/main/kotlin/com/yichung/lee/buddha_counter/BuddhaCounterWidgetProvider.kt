package com.yichung.lee.buddha_counter

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

open class BuddhaCounterWidgetProvider : AppWidgetProvider() {

    companion object {
        const val ACTION_REFRESH = "com.yichung.lee.buddha_counter.ACTION_WIDGET_REFRESH"
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_REFRESH) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val thisWidget = ComponentName(context, BuddhaCounterWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(thisWidget)
            onUpdate(context, appWidgetManager, appWidgetIds)
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val widgetData = HomeWidgetPlugin.getData(context)
            val views = RemoteViews(context.packageName, R.layout.buddha_widget).apply {
                val todayCount = widgetData.getInt("today_count", 0)
                val weeklyCount = widgetData.getInt("weekly_count", 0)
                val monthlyCount = widgetData.getInt("monthly_count", 0)
                val streakDays = widgetData.getInt("streak_days", 0)
                // 文字優先採用 App 依使用者語言推送的內容；尚未同步時回退至系統語言的 strings.xml
                val streakText = widgetData.getString("streak_text", null)
                    ?: if (streakDays > 0) context.getString(R.string.widget_streak_placeholder)
                    else context.getString(R.string.widget_streak_none)
                val targetText = widgetData.getString("target_text", null)
                    ?: context.getString(R.string.widget_target_placeholder)
                val titleText = widgetData.getString("widget_title", null)
                    ?: context.getString(R.string.widget_title)
                val weeklyText = widgetData.getString("weekly_text", null)
                    ?: context.getString(R.string.widget_weekly_format, String.format("%,d", weeklyCount))
                val monthlyText = widgetData.getString("monthly_text", null)
                    ?: context.getString(R.string.widget_monthly_format, String.format("%,d", monthlyCount))
                val refreshLabel = widgetData.getString("refresh_label", null)
                    ?: context.getString(R.string.widget_refresh)

                setTextViewText(R.id.widget_today_count, String.format("%,d", todayCount))
                setTextViewText(R.id.widget_title, titleText)
                setTextViewText(R.id.widget_streak_text, streakText)
                setTextViewText(R.id.widget_target_text, targetText)
                setTextViewText(R.id.widget_weekly_count, weeklyText)
                setTextViewText(R.id.widget_monthly_count, monthlyText)
                setContentDescription(R.id.widget_refresh_button, refreshLabel)

                // 點擊卡片開啟 App
                val openIntent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val openPendingIntent = PendingIntent.getActivity(
                    context,
                    0,
                    openIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_container, openPendingIntent)

                // 點擊重整按鈕：原地廣播更新 Widget
                val refreshIntent = Intent(context, BuddhaCounterWidgetProvider::class.java).apply {
                    action = ACTION_REFRESH
                }
                val refreshPendingIntent = PendingIntent.getBroadcast(
                    context,
                    1,
                    refreshIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_refresh_button, refreshPendingIntent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

