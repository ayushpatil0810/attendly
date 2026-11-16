package com.attendly.attendly

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class LargeAttendanceWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_attendance_large).apply {
                // Clicking root opens the app
                val openAppIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("attendly://dashboard"),
                )
                setOnClickPendingIntent(R.id.widget_large_root, openAppIntent)

                // Clicking Quick Log button opens Quick Log sheet
                val quickLogIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("attendly://quick-log"),
                )
                setOnClickPendingIntent(R.id.widget_large_btn_quick_log, quickLogIntent)

                // Semester Name
                val semesterName = widgetData.getString("semester_name", null)
                setTextViewText(
                    R.id.widget_large_semester_name,
                    if (!semesterName.isNullOrBlank()) semesterName else "Attendly",
                )

                // Overall Percentage
                val pctString = widgetData.getString("overall_percentage", null) ?: "—"
                setTextViewText(R.id.widget_large_percentage, pctString)

                // Threshold Status
                val statusText = widgetData.getString("status_label", null) ?: "No Records"
                val statusType = widgetData.getString("threshold_status", "none")
                setTextViewText(R.id.widget_large_status, statusText)

                when (statusType) {
                    "meeting" -> {
                        setInt(R.id.widget_large_status, "setBackgroundResource", R.drawable.widget_badge_meeting)
                        setTextColor(R.id.widget_large_status, context.getColor(R.color.widget_ink_mint))
                    }
                    "below" -> {
                        setInt(R.id.widget_large_status, "setBackgroundResource", R.drawable.widget_badge_below)
                        setTextColor(R.id.widget_large_status, context.getColor(R.color.widget_ink_coral))
                    }
                    else -> {
                        setInt(R.id.widget_large_status, "setBackgroundResource", R.drawable.widget_badge_neutral)
                        setTextColor(R.id.widget_large_status, context.getColor(R.color.widget_muted_ink))
                    }
                }

                // Personal Goal & Advice
                val goalPercent = widgetData.getInt("target_goal_percent", 85)
                setTextViewText(R.id.widget_large_goal_badge, "Goal: $goalPercent%")

                val goalAdvice = widgetData.getString("goal_advice", null)
                setTextViewText(
                    R.id.widget_large_goal_advice,
                    if (!goalAdvice.isNullOrBlank()) goalAdvice else "Personal attendance goal: $goalPercent%",
                )

                // Subject-wise Breakdown (up to 4 subjects)
                val subjectCount = widgetData.getInt("subject_count", 0)

                val rowIds = intArrayOf(
                    R.id.widget_s1_row,
                    R.id.widget_s2_row,
                    R.id.widget_s3_row,
                    R.id.widget_s4_row,
                )
                val nameIds = intArrayOf(
                    R.id.widget_s1_name,
                    R.id.widget_s2_name,
                    R.id.widget_s3_name,
                    R.id.widget_s4_name,
                )
                val statsIds = intArrayOf(
                    R.id.widget_s1_stats,
                    R.id.widget_s2_stats,
                    R.id.widget_s3_stats,
                    R.id.widget_s4_stats,
                )
                val pctIds = intArrayOf(
                    R.id.widget_s1_pct,
                    R.id.widget_s2_pct,
                    R.id.widget_s3_pct,
                    R.id.widget_s4_pct,
                )

                if (subjectCount == 0) {
                    setViewVisibility(R.id.widget_large_empty, View.VISIBLE)
                    for (i in 0..3) {
                        setViewVisibility(rowIds[i], View.GONE)
                    }
                } else {
                    setViewVisibility(R.id.widget_large_empty, View.GONE)
                    for (i in 0..3) {
                        if (i < subjectCount) {
                            val num = i + 1
                            val sName = widgetData.getString("subject_${num}_name", "Subject $num")
                            val sStats = widgetData.getString("subject_${num}_stats", "0/0")
                            val sPct = widgetData.getString("subject_${num}_pct", "—")
                            val sMeeting = widgetData.getBoolean("subject_${num}_meeting", true)

                            setTextViewText(nameIds[i], sName)
                            setTextViewText(statsIds[i], sStats)
                            setTextViewText(pctIds[i], sPct)

                            if (sMeeting) {
                                setInt(pctIds[i], "setBackgroundResource", R.drawable.widget_chip_present)
                                setTextColor(pctIds[i], context.getColor(R.color.widget_ink_mint))
                            } else {
                                setInt(pctIds[i], "setBackgroundResource", R.drawable.widget_chip_absent)
                                setTextColor(pctIds[i], context.getColor(R.color.widget_ink_coral))
                            }

                            setViewVisibility(rowIds[i], View.VISIBLE)
                        } else {
                            setViewVisibility(rowIds[i], View.GONE)
                        }
                    }
                }
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
