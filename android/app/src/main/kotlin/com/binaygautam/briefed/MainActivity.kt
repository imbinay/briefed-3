package com.binaygautam.briefed

import android.Manifest
import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Calendar

class MainActivity : FlutterActivity() {

    private val notificationChannelName = "briefed/notifications"
    private var pendingSchedule: Pair<Int, Int>? = null
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            notificationChannelName
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "scheduleDailyReminder" -> {
                    val hour              = call.argument<Int>("hour")              ?: 8
                    val minute            = call.argument<Int>("minute")            ?: 0
                    val requestPermission = call.argument<Boolean>("requestPermission") ?: true
                    scheduleDailyReminder(hour, minute, requestPermission, result)
                }
                "cancelDailyReminder" -> {
                    cancelAlarm(ReminderReceiver.DAILY_REQUEST_CODE)
                    result.success(null)
                }
                "scheduleQuizReady" -> {
                    val triggerAt = call.argument<Long>("triggerAtMillis")
                        ?: run { result.success(null); return@setMethodCallHandler }
                    scheduleOneShot(
                        requestCode  = ReminderReceiver.QUIZ_REQUEST_CODE,
                        triggerAtMs  = triggerAt,
                        extraType    = "quiz_ready",
                    )
                    result.success(null)
                }
                "cancelQuizReady" -> {
                    cancelAlarm(ReminderReceiver.QUIZ_REQUEST_CODE)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    // ── Daily reminder ────────────────────────────────────────────────────────

    private fun scheduleDailyReminder(
        hour: Int, minute: Int,
        requestPermission: Boolean,
        result: MethodChannel.Result,
    ) {
        createNotificationChannel()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS)
                != PackageManager.PERMISSION_GRANTED
        ) {
            if (!requestPermission) { result.success(false); return }
            pendingSchedule = Pair(hour, minute)
            pendingResult   = result
            requestPermissions(
                arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                PERMISSION_REQUEST_CODE
            )
            return
        }
        scheduleDailyAlarm(hour, minute)
        result.success(true)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != PERMISSION_REQUEST_CODE) return

        val granted  = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
        val schedule = pendingSchedule
        val result   = pendingResult
        pendingSchedule = null
        pendingResult   = null

        if (granted && schedule != null) {
            scheduleDailyAlarm(schedule.first, schedule.second)
            result?.success(true)
        } else {
            result?.success(false)
        }
    }

    // ── Alarm helpers ─────────────────────────────────────────────────────────

    /** Schedules (or replaces) the repeating daily alarm using setAndAllowWhileIdle.
     *  The receiver self-reschedules for the next day after each fire. */
    internal fun scheduleDailyAlarm(hour: Int, minute: Int) {
        val calendar = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, hour)
            set(Calendar.MINUTE, minute)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
            if (timeInMillis <= System.currentTimeMillis()) add(Calendar.DAY_OF_YEAR, 1)
        }
        val intent = Intent(this, ReminderReceiver::class.java).apply {
            putExtra("type",   "daily")
            putExtra("hour",   hour)
            putExtra("minute", minute)
        }
        val pi = PendingIntent.getBroadcast(
            this, ReminderReceiver.DAILY_REQUEST_CODE, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val am = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, calendar.timeInMillis, pi)
    }

    /** Schedules a one-shot alarm at an absolute epoch-millisecond time. */
    private fun scheduleOneShot(requestCode: Int, triggerAtMs: Long, extraType: String) {
        val intent = Intent(this, ReminderReceiver::class.java).apply {
            putExtra("type", extraType)
        }
        val pi = PendingIntent.getBroadcast(
            this, requestCode, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val am = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMs, pi)
    }

    private fun cancelAlarm(requestCode: Int) {
        val am     = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(this, ReminderReceiver::class.java)
        val pi     = PendingIntent.getBroadcast(
            this, requestCode, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        am.cancel(pi)
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val channel = NotificationChannel(
            ReminderReceiver.CHANNEL_ID,
            "Briefed Notifications",
            NotificationManager.IMPORTANCE_DEFAULT
        ).apply { description = "Daily quiz reminders and quiz-ready alerts" }
        manager.createNotificationChannel(channel)
    }

    companion object {
        private const val PERMISSION_REQUEST_CODE = 4202
    }
}
