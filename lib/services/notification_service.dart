import 'dart:io';
import 'package:flutter/services.dart';

class NotificationService {
  static const MethodChannel _channel = MethodChannel('briefed/notifications');

  /// Schedule (or reschedule) the daily reminder at [hour]:[minute].
  /// Uses setAndAllowWhileIdle on Android so it fires even in Doze mode.
  static Future<bool> scheduleDailyReminder({
    required int hour,
    required int minute,
    bool requestPermission = true,
  }) async {
    if (!Platform.isAndroid) return false;
    final scheduled = await _channel.invokeMethod<bool>('scheduleDailyReminder', {
      'hour':              hour,
      'minute':            minute,
      'requestPermission': requestPermission,
    });
    return scheduled ?? false;
  }

  static Future<void> cancelDailyReminder() async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>('cancelDailyReminder');
  }

  /// Call after the user completes their daily quiz.
  /// Schedules a "quiz has reset" notification for 12:01 AM the next day.
  static Future<void> scheduleQuizReady() async {
    if (!Platform.isAndroid) return;
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1, 0, 1);
    await _channel.invokeMethod<void>('scheduleQuizReady', {
      'triggerAtMillis': nextMidnight.millisecondsSinceEpoch,
    });
  }

  static Future<void> cancelQuizReady() async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>('cancelQuizReady');
  }
}
