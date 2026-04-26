package com.binaygautam.briefed

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.app.AlarmManager
import android.os.Build
import java.util.Calendar

class ReminderReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent?) {
        ensureChannel(context)

        val type = intent?.getStringExtra("type") ?: "daily"

        val launchIntent = context.packageManager
            .getLaunchIntentForPackage(context.packageName)
            ?: Intent(context, MainActivity::class.java)
        val contentPi = PendingIntent.getActivity(
            context, 4203, launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        when (type) {
            "daily" -> {
                post(
                    context, contentPi,
                    id    = DAILY_NOTIF_ID,
                    title = "Stay Briefed. Stay Sharp.",
                    text  = "Today's quiz is ready — 5 questions, 2 minutes. Play now!",
                )
                // Self-reschedule for tomorrow so the daily alarm keeps repeating
                val hour   = intent?.getIntExtra("hour", 8)   ?: 8
                val minute = intent?.getIntExtra("minute", 0) ?: 0
                rescheduleTomorrow(context, hour, minute)
            }
            "quiz_ready" -> {
                post(
                    context, contentPi,
                    id    = QUIZ_NOTIF_ID,
                    title = "Your daily quiz has reset! ⚡",
                    text  = "A fresh set of questions is waiting. Play today's Briefed quiz.",
                )
            }
        }
    }

    private fun post(
        context: Context,
        contentIntent: PendingIntent,
        id: Int,
        title: String,
        text: String,
    ) {
        val notification = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(context, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context)
        }
            .setSmallIcon(android.R.drawable.ic_popup_reminder)
            .setContentTitle(title)
            .setContentText(text)
            .setContentIntent(contentIntent)
            .setAutoCancel(true)
            .build()

        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE)
            as NotificationManager
        manager.notify(id, notification)
    }

    /** Re-schedules the daily alarm for the same time tomorrow. */
    private fun rescheduleTomorrow(context: Context, hour: Int, minute: Int) {
        val calendar = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, hour)
            set(Calendar.MINUTE, minute)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
            add(Calendar.DAY_OF_YEAR, 1) // always the next day
        }
        val intent = Intent(context, ReminderReceiver::class.java).apply {
            putExtra("type",   "daily")
            putExtra("hour",   hour)
            putExtra("minute", minute)
        }
        val pi = PendingIntent.getBroadcast(
            context, DAILY_REQUEST_CODE, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, calendar.timeInMillis, pi)
    }

    private fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE)
            as NotificationManager
        if (manager.getNotificationChannel(CHANNEL_ID) != null) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Briefed Notifications",
            NotificationManager.IMPORTANCE_DEFAULT
        ).apply { description = "Daily quiz reminders and quiz-ready alerts" }
        manager.createNotificationChannel(channel)
    }

    companion object {
        const val CHANNEL_ID          = "briefed_notifications"
        const val DAILY_REQUEST_CODE  = 4201
        const val QUIZ_REQUEST_CODE   = 4205
        private const val DAILY_NOTIF_ID = 4204
        private const val QUIZ_NOTIF_ID  = 4206
    }
}
