package com.attendly.attendly

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class MediumAttendanceWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_attendance_medium).apply {
                // Clicking root opens the app
                val openAppIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("attendly://dashboard"),
                )
                setOnClickPendingIntent(R.id.widget_medium_root, openAppIntent)

                // Clicking Quick Log button directly opens Quick Log sheet
                val quickLogIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("attendly://quick-log"),
                )
                setOnClickPendingIntent(R.id.widget_medium_btn_quick_log, quickLogIntent)

                // Semester Name
                val semesterName = widgetData.getString("semester_name", null)
                setTextViewText(
                    R.id.widget_medium_semester_name,
                    if (!semesterName.isNullOrBlank()) semesterName else "Attendly",
                )

                // Overall Percentage
                val pctString = widgetData.getString("overall_percentage", null) ?: "—"
                setTextViewText(R.id.widget_medium_percentage, pctString)

                // Threshold Status
                val statusText = widgetData.getString("status_label", null) ?: "No Records"
                val statusType = widgetData.getString("threshold_status", "none")
                setTextViewText(R.id.widget_medium_status, statusText)

                when (statusType) {
                    "meeting" -> {
                        setInt(R.id.widget_medium_status, "setBackgroundResource", R.drawable.widget_badge_meeting)
                        setTextColor(R.id.widget_medium_status, context.getColor(R.color.widget_ink_mint))
                    }
                    "below" -> {
                        setInt(R.id.widget_medium_status, "setBackgroundResource", R.drawable.widget_badge_below)
                        setTextColor(R.id.widget_medium_status, context.getColor(R.color.widget_ink_coral))
                    }
                    else -> {
                        setInt(R.id.widget_medium_status, "setBackgroundResource", R.drawable.widget_badge_neutral)
                        setTextColor(R.id.widget_medium_status, context.getColor(R.color.widget_muted_ink))
                    }
                }

                // Present & Absent counts
                val presentCount = widgetData.getInt("total_present", 0)
                val absentCount = widgetData.getInt("total_absent", 0)
                val conductedCount = widgetData.getInt("total_conducted", 0)

                setTextViewText(R.id.widget_medium_present, "Present: $presentCount")
                setTextViewText(R.id.widget_medium_absent, "Absent: $absentCount")
                setTextViewText(
                    R.id.widget_medium_conducted,
                    if (conductedCount == 1) "1 session recorded" else "$conductedCount sessions recorded",
                )
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
