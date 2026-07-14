package com.ahoura.yadyar

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * ارائه‌دهنده‌ی ویجت صفحه‌ی خانه‌ی یادیار.
 * تعداد کارت‌های سررسید امروز را نمایش می‌دهد و با کلیک اپ را باز می‌کند.
 */
class YadyarWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        // خواندن تعداد کارت‌های سررسید از داده‌ی به‌اشتراک‌گذاشته‌شده‌ی فلوتر.
        val dueCount = widgetData.getInt("dueCount", 0)

        val views = RemoteViews(context.packageName, R.layout.yadyar_widget).apply {
            // نمایش عدد با ارقام فارسی.
            setTextViewText(R.id.widget_due_count, toPersianDigits(dueCount))
        }

        // کلیک روی ویجت → باز کردن MainActivity.
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

        // اعمال روی همه‌ی نمونه‌های ویجت.
        appWidgetManager.updateAppWidget(appWidgetIds, views)
    }

    /** تبدیل ارقام لاتین به فارسی برای نمایش در ویجت. */
    private fun toPersianDigits(value: Int): String {
        val faDigits = charArrayOf('۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹')
        return value.toString().map { ch ->
            if (ch in '0'..'9') faDigits[ch - '0'] else ch
        }.joinToString("")
    }
}
