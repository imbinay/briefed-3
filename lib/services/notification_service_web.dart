class NotificationService {
  static Future<bool> scheduleDailyReminder({
    required int hour,
    required int minute,
    bool requestPermission = true,
  }) async => false;

  static Future<void> cancelDailyReminder() async {}

  static Future<void> scheduleQuizReady() async {}

  static Future<void> cancelQuizReady() async {}
}
