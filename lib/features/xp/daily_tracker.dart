import '../../services/storage_service.dart';

/// Tracks daily activity completion in SharedPreferences.
/// Quiz completion delegates to the existing StorageService keys.
class DailyTracker {
  static String _today() => DateTime.now().toIso8601String().substring(0, 10);

  // ── Briefing ──────────────────────────────────────────────────────────────

  static bool isBriefingReadToday() =>
      StorageService.prefs.getBool('briefed_briefing_read_${_today()}') ??
      false;

  static Future<void> markBriefingRead() =>
      StorageService.prefs.setBool('briefed_briefing_read_${_today()}', true);

  // ── Game ─────────────────────────────────────────────────────────────────

  static bool isAnyGamePlayedToday() =>
      StorageService.prefs.getBool('briefed_game_played_${_today()}') ?? false;

  static Future<void> markGamePlayed() =>
      StorageService.prefs.setBool('briefed_game_played_${_today()}', true);

  // ── Quiz (delegates to existing StorageService keys) ─────────────────────

  static bool isDailyMixDone() {
    final last = StorageService.getLastPlayedDate();
    return last == _today();
  }

  static bool isCategoryDone(String category) =>
      StorageService.getCategoryCompletion(category) != null;

  // ── XP ───────────────────────────────────────────────────────────────────

  static int getXpEarnedToday() =>
      StorageService.prefs.getInt('briefed_xp_earned_today_${_today()}') ?? 0;

  static Future<void> addXpEarnedToday(int xp) async {
    final current = getXpEarnedToday();
    await StorageService.prefs
        .setInt('briefed_xp_earned_today_${_today()}', current + xp);
  }

  // ── Daily Path ────────────────────────────────────────────────────────────

  /// Returns the number of daily path steps completed (0–5).
  static int getCompletedStepCount() {
    final read = isBriefingReadToday();
    final quiz = isDailyMixDone();
    final game = isAnyGamePlayedToday();
    final xp = getXpEarnedToday() > 0;
    final reward = read && quiz && game && xp;
    return [read, quiz, game, xp, reward].where((b) => b).length;
  }

  /// Step completion state: index 0 = Read, 1 = Quiz, 2 = Game, 3 = XP, 4 = Reward.
  static List<bool> getStepCompletions() {
    final read = isBriefingReadToday();
    final quiz = isDailyMixDone();
    final game = isAnyGamePlayedToday();
    final xp = getXpEarnedToday() > 0;
    final reward = read && quiz && game && xp;
    return [read, quiz, game, xp, reward];
  }
}
