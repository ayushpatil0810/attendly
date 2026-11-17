package com.attendly.attendly

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.util.SizeF
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent

object AttendanceWidgetViews {

    fun buildAdaptiveViews(
        context: Context,
        widgetData: SharedPreferences,
        options: Bundle? = null,
    ): RemoteViews {
        val smallViews = buildSmallViews(context, widgetData)
        val mediumViews = buildMediumViews(context, widgetData)
        val largeViews = buildLargeViews(context, widgetData)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val viewsMap = mapOf(
                SizeF(100f, 100f) to smallViews,
                SizeF(180f, 100f) to mediumViews,
                SizeF(220f, 180f) to largeViews,
            )
            return RemoteViews(viewsMap)
        }

        if (options != null) {
            val minWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)
            val minHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0)
            return when {
                minWidth >= 220 && minHeight >= 180 -> largeViews
                minWidth >= 170 -> mediumViews
                else -> smallViews
            }
        }

        return smallViews
    }

    fun buildSmallViews(context: Context, widgetData: SharedPreferences): RemoteViews {
        return RemoteViews(context.packageName, R.layout.widget_attendance_small).apply {
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
    }

    fun buildMediumViews(context: Context, widgetData: SharedPreferences): RemoteViews {
        return RemoteViews(context.packageName, R.layout.widget_attendance_medium).apply {
            val openAppIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse("attendly://dashboard"),
            )
            setOnClickPendingIntent(R.id.widget_medium_root, openAppIntent)

            val quickLogIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse("attendly://quick-log"),
            )
            setOnClickPendingIntent(R.id.widget_medium_btn_quick_log, quickLogIntent)

            val semesterName = widgetData.getString("semester_name", null)
            setTextViewText(
                R.id.widget_medium_semester_name,
                if (!semesterName.isNullOrBlank()) semesterName else "Attendly",
            )

            val pctString = widgetData.getString("overall_percentage", null) ?: "—"
            val pctInt = widgetData.getInt("overall_percentage_int", 0)
            setTextViewText(R.id.widget_medium_percentage, pctString)
            setProgressBar(R.id.widget_medium_progress_ring, 100, pctInt, false)

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

            val subjectCount = widgetData.getInt("subject_count", 0)
            if (subjectCount == 0) {
                setViewVisibility(R.id.widget_medium_empty_subjects, View.VISIBLE)
                setViewVisibility(R.id.widget_m_s1_row, View.GONE)
                setViewVisibility(R.id.widget_m_s2_row, View.GONE)
                setViewVisibility(R.id.widget_m_s3_row, View.GONE)
            } else {
                setViewVisibility(R.id.widget_medium_empty_subjects, View.GONE)

                val rowIds = intArrayOf(R.id.widget_m_s1_row, R.id.widget_m_s2_row, R.id.widget_m_s3_row)
                val nameIds = intArrayOf(R.id.widget_m_s1_name, R.id.widget_m_s2_name, R.id.widget_m_s3_name)
                val barIds = intArrayOf(R.id.widget_m_s1_bar, R.id.widget_m_s2_bar, R.id.widget_m_s3_bar)
                val pctIds = intArrayOf(R.id.widget_m_s1_pct, R.id.widget_m_s2_pct, R.id.widget_m_s3_pct)

                for (i in 0 until 3) {
                    val rowId = rowIds[i]
                    val nameId = nameIds[i]
                    val barId = barIds[i]
                    val pctId = pctIds[i]

                    if (i < subjectCount) {
                        val num = i + 1
                        val name = widgetData.getString("subject_${num}_name", null) ?: "Subject $num"
                        val pct = widgetData.getString("subject_${num}_pct", null) ?: "—"
                        val subjPctInt = widgetData.getInt("subject_${num}_pct_int", 0)

                        setTextViewText(nameId, name)
                        setTextViewText(pctId, pct)
                        setProgressBar(barId, 100, subjPctInt, false)
                        setViewVisibility(rowId, View.VISIBLE)
                    } else {
                        setViewVisibility(rowId, View.GONE)
                    }
                }
            }
        }
    }

    fun buildLargeViews(context: Context, widgetData: SharedPreferences): RemoteViews {
        return RemoteViews(context.packageName, R.layout.widget_attendance_large).apply {
            val openAppIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse("attendly://dashboard"),
            )
            setOnClickPendingIntent(R.id.widget_large_root, openAppIntent)

            val quickLogIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse("attendly://quick-log"),
            )
            setOnClickPendingIntent(R.id.widget_large_btn_quick_log, quickLogIntent)

            val semesterName = widgetData.getString("semester_name", null)
            setTextViewText(
                R.id.widget_large_semester_name,
                if (!semesterName.isNullOrBlank()) semesterName else "Attendly",
            )

            val pctString = widgetData.getString("overall_percentage", null) ?: "—"
            val pctInt = widgetData.getInt("overall_percentage_int", 0)
            setTextViewText(R.id.widget_large_percentage, pctString)
            setProgressBar(R.id.widget_large_progress_ring, 100, pctInt, false)

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

            val thresholdPercent = widgetData.getInt("threshold_percent", 75)
            val thresholdBadge = widgetData.getString("threshold_badge", "Req: $thresholdPercent%")
            setTextViewText(R.id.widget_large_goal_badge, thresholdBadge)

            val advice = widgetData.getString("attendance_advice", null)
                ?: widgetData.getString("goal_advice", null)
            setTextViewText(
                R.id.widget_large_goal_advice,
                if (!advice.isNullOrBlank()) advice else "Minimum threshold: $thresholdPercent%",
            )

            val subjectCount = widgetData.getInt("subject_count", 0)
            if (subjectCount == 0) {
                setViewVisibility(R.id.widget_large_empty, View.VISIBLE)
            } else {
                setViewVisibility(R.id.widget_large_empty, View.GONE)
            }

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
            val barIds = intArrayOf(
                R.id.widget_s1_bar,
                R.id.widget_s2_bar,
                R.id.widget_s3_bar,
                R.id.widget_s4_bar,
            )
            val pctIds = intArrayOf(
                R.id.widget_s1_pct,
                R.id.widget_s2_pct,
                R.id.widget_s3_pct,
                R.id.widget_s4_pct,
            )

            for (i in 0 until 4) {
                val rowId = rowIds[i]
                val nameId = nameIds[i]
                val statsId = statsIds[i]
                val barId = barIds[i]
                val pctId = pctIds[i]

                if (i < subjectCount) {
                    val num = i + 1
                    val name = widgetData.getString("subject_${num}_name", null) ?: "Subject $num"
                    val stats = widgetData.getString("subject_${num}_stats", null) ?: "0/0"
                    val pct = widgetData.getString("subject_${num}_pct", null) ?: "—"
                    val subjPctInt = widgetData.getInt("subject_${num}_pct_int", 0)

                    setTextViewText(nameId, name)
                    setTextViewText(statsId, stats)
                    setTextViewText(pctId, pct)
                    setProgressBar(barId, 100, subjPctInt, false)

                    setViewVisibility(rowId, View.VISIBLE)
                } else {
                    setViewVisibility(rowId, View.GONE)
                }
            }
        }
    }
}
