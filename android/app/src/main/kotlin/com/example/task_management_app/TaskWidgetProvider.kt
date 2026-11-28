package com.example.task_management_app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class TaskWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.task_widget)

            // Bấm vào widget -> mở app
            val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            val loggedIn = widgetData.getString("w_logged_in", "0") == "1"

            if (!loggedIn) {
                views.setTextViewText(R.id.tv_title, "Task Manager")
                views.setTextViewText(R.id.tv_stats, "Mở app để đăng nhập")
                views.setTextViewText(R.id.tv_summary, "")
                views.setViewVisibility(R.id.tv_task1, View.GONE)
                views.setViewVisibility(R.id.tv_task2, View.GONE)
                views.setViewVisibility(R.id.tv_task3, View.GONE)
            } else {
                val name = widgetData.getString("w_name", "") ?: ""
                val streak = widgetData.getString("w_streak", "0")
                val hp = widgetData.getString("w_hp", "0")
                val gold = widgetData.getString("w_gold", "0")
                val pending = widgetData.getString("w_pending", "0") ?: "0"
                val total = widgetData.getString("w_total", "0") ?: "0"

                views.setTextViewText(
                    R.id.tv_title,
                    if (name.isEmpty()) "Task Manager" else "Chào $name"
                )
                views.setTextViewText(
                    R.id.tv_stats,
                    "🔥 $streak   ❤️ $hp/3   🪙 $gold"
                )
                views.setTextViewText(
                    R.id.tv_summary,
                    if (total == "0") "Hôm nay không có nhắc nhở"
                    else if (pending == "0") "Đã hoàn thành hết $total việc 🎉"
                    else "Còn $pending/$total việc hôm nay"
                )

                val ids = intArrayOf(R.id.tv_task1, R.id.tv_task2, R.id.tv_task3)
                val keys = arrayOf("w_task1", "w_task2", "w_task3")
                for (i in ids.indices) {
                    val text = widgetData.getString(keys[i], "") ?: ""
                    if (text.isEmpty()) {
                        views.setViewVisibility(ids[i], View.GONE)
                    } else {
                        views.setViewVisibility(ids[i], View.VISIBLE)
                        views.setTextViewText(ids[i], "• $text")
                    }
                }
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}