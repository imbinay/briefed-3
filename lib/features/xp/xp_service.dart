import '../../services/storage_service.dart';

/// Manages XP, levels, and streak multipliers.
/// Uses SharedPreferences via StorageService.prefs.
class XpService {
  static const _keyTotalXp = 'briefed_total_xp';
  static const _keyMigrated = 'briefed_xp_migrated';

  static const List<(int, String)> _levels = [
    (0, 'Newcomer'),
    (500, 'Curious'),
    (1500, 'Informed'),
    (3000, 'Analyst'),
    (6000, 'Sharp Mind'),
    (10000, 'News Hawk'),
    (15000, 'Fact Checker'),
    (22000, 'World Watcher'),
    (30000, 'Deep Thinker'),
    (50000, 'Master Briefed'),
  ];

  /// Migrate from legacy knowledgeScore on first launch (1 point = 3 XP).
  static Future<void> migrateIfNeeded() async {
    final prefs = StorageService.prefs;
    if (prefs.getBool(_keyMigrated) == true) return;
    final knowledgeScore = StorageService.getKnowledgeScore();
    if (knowledgeScore > 0) {
      final migratedXp = knowledgeScore * 3;
      final existing = prefs.getInt(_keyTotalXp) ?? 0;
      if (migratedXp > existing) {
        await prefs.setInt(_keyTotalXp, migratedXp);
      }
    }
    await prefs.setBool(_keyMigrated, true);
  }

  static int getTotalXp() => StorageService.prefs.getInt(_keyTotalXp) ?? 0;

  static Future<void> addXp(int amount) async {
    if (amount <= 0) return;
    final current = getTotalXp();
    await StorageService.prefs.setInt(_keyTotalXp, current + amount);
  }

  static int getLevel() {
    final xp = getTotalXp();
    int level = 1;
    for (int i = 1; i < _levels.length; i++) {
      if (xp >= _levels[i].$1) {
        level = i + 1;
      } else {
        break;
      }
    }
    return level;
  }

  static String getLevelTitle() {
    final level = getLevel();
    return _levels[level - 1].$2;
  }

  static int getXpForNextLevel() {
    final level = getLevel();
    if (level >= _levels.length) return _levels.last.$1;
    return _levels[level].$1;
  }

  /// Returns 0.0–1.0 progress within the current level.
  static double getLevelProgress() {
    final xp = getTotalXp();
    final level = getLevel();
    if (level >= _levels.length) return 1.0;
    final levelStart = _levels[level - 1].$1;
    final levelEnd = _levels[level].$1;
    if (levelEnd <= levelStart) return 1.0;
    return ((xp - levelStart) / (levelEnd - levelStart)).clamp(0.0, 1.0);
  }

  /// Returns multiplier as integer percent: 100, 125, 150, or 200.
  static int getStreakMultiplier(int streak) {
    if (streak >= 14) return 200;
    if (streak >= 7) return 150;
    if (streak >= 3) return 125;
    return 100;
  }

  /// Calculate XP for a completed quiz.
  static int calculateQuizXp({
    required int correct,
    required int total,
    required bool isDailyMix,
    required int streak,
  }) {
    final xpPerCorrect = isDailyMix ? 20 : 15;
    final perfectBonus = correct == total ? (isDailyMix ? 50 : 30) : 0;
    final baseXp = correct * xpPerCorrect + perfectBonus;
    final multiplier = getStreakMultiplier(streak);
    return (baseXp * multiplier) ~/ 100;
  }
}
