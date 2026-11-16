package com.attendly.attendly

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class SmallAttendanceWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_attendance_small).apply {
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("attendly://dashboard"),
                )
                setOnClickPendingIntent(R.id.widget_small_root, pendingIntent)

                val semesterName = widgetData.getString("semester_name", null)
                val title = if (!semesterName.isNullOrBlank()) semesterName.uppercase() else "ATTENDANCE"
                setTextViewText(R.id.widget_small_title, title)

                val pctString = widgetData.getString("overall_percentage", null) ?: "—"
                val pctInt = widgetData.getInt("overall_percentage_int", 0)
                setTextViewText(R.id.widget_small_percentage, pctString)
                setProgressBar(R.id.widget_small_progress_ring, 100, pctInt, false)

                val statusText = widgetData.getString("status_label", null) ?: "No Records"
                val statusType = widgetData.getString("threshold_status", "none")
                setTextViewText(R.id.widget_small_status, statusText)

                when (statusType) {
                    "meeting" -> {
                        setInt(R.id.widget_small_status, "setBackgroundResource", R.drawable.widget_badge_meeting)
                        setTextColor(R.id.widget_small_status, context.getColor(R.color.widget_ink_mint))
                    }
                    "below" -> {
                        setInt(R.id.widget_small_status, "setBackgroundResource", R.drawable.widget_badge_below)
                        setTextColor(R.id.widget_small_status, context.getColor(R.color.widget_ink_coral))
                    }
                    else -> {
                        setInt(R.id.widget_small_status, "setBackgroundResource", R.drawable.widget_badge_neutral)
                        setTextColor(R.id.widget_small_status, context.getColor(R.color.widget_muted_ink))
                    }
                }
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
