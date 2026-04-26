import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../models/models.dart';

class StorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get prefs {
    assert(_prefs != null, 'StorageService.init() must be called first');
    return _prefs!;
  }

  // ── THEME ────────────────────────────────────────────────────────────────
  static String getThemeMode() =>
      prefs.getString(AppConstants.keyThemeMode) ?? 'light';

  static Future<void> setThemeMode(String mode) =>
      prefs.setString(AppConstants.keyThemeMode, mode);

  // ── ONBOARDING ────────────────────────────────────────────────────────────
  static bool isOnboardingDone() =>
      prefs.getBool(AppConstants.keyOnboardingDone) ?? false;

  static Future<void> setOnboardingDone() =>
      prefs.setBool(AppConstants.keyOnboardingDone, true);

  // ── USER DATA ─────────────────────────────────────────────────────────────
  static String getUserName() =>
      prefs.getString(AppConstants.keyUserName) ?? 'Briefed User';

  static Future<void> setUserName(String name) =>
      prefs.setString(AppConstants.keyUserName, name);

  static String getUserPhotoUrl() =>
      prefs.getString(AppConstants.keyUserPhotoUrl) ?? '';

  static Future<void> setUserPhotoUrl(String url) =>
      prefs.setString(AppConstants.keyUserPhotoUrl, url);

  static Future<void> resetUserData() async {
    await prefs.remove(AppConstants.keyUserName);
    await prefs.remove(AppConstants.keyUserPhotoUrl);
    await prefs.remove(AppConstants.keySelectedCategories);
    await prefs.remove(AppConstants.keyNotificationHour);
    await prefs.remove(AppConstants.keyNotificationMinute);
    await prefs.remove(AppConstants.keyStreak);
    await prefs.remove(AppConstants.keyLastPlayedDate);
    await prefs.remove(AppConstants.keyKnowledgeScore);
    await prefs.remove(AppConstants.keyTotalQuizzes);
    await prefs.remove(AppConstants.keyUserCountry);
    await prefs.remove(AppConstants.keyQuizHistory);
    await prefs.remove('bonus_played_date');
    await clearQuestionCache();
  }

  static List<String> getSelectedCategories() {
    final stored = prefs.getStringList(AppConstants.keySelectedCategories);
    return stored ?? ['world', 'tech', 'business'];
  }

  static Future<void> setSelectedCategories(List<String> cats) =>
      prefs.setStringList(AppConstants.keySelectedCategories, cats);

  static int getNotificationHour() =>
      prefs.getInt(AppConstants.keyNotificationHour) ?? 8;

  static Future<void> setNotificationHour(int hour) =>
      prefs.setInt(AppConstants.keyNotificationHour, hour);

  static int getNotificationMinute() =>
      prefs.getInt(AppConstants.keyNotificationMinute) ?? 0;

  static Future<void> setNotificationMinute(int minute) =>
      prefs.setInt(AppConstants.keyNotificationMinute, minute);

  static String getUserCountry() =>
      prefs.getString(AppConstants.keyUserCountry) ??
      AppConstants.defaultCountry;

  static Future<void> setUserCountry(String country) =>
      prefs.setString(AppConstants.keyUserCountry, country);

  // ── STATS ─────────────────────────────────────────────────────────────────
  static int getStreak() => prefs.getInt(AppConstants.keyStreak) ?? 0;

  static Future<void> setStreak(int streak) =>
      prefs.setInt(AppConstants.keyStreak, streak);

  static String getLastPlayedDate() =>
      prefs.getString(AppConstants.keyLastPlayedDate) ?? '';

  static Future<void> setLastPlayedDate(String date) =>
      prefs.setString(AppConstants.keyLastPlayedDate, date);

  static bool hasBonusPlayedToday() {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return prefs.getString('bonus_played_date') == today;
  }

  static Future<void> setBonusPlayedToday() {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return prefs.setString('bonus_played_date', today);
  }

  static int getKnowledgeScore() =>
      prefs.getInt(AppConstants.keyKnowledgeScore) ?? 0;

  static Future<void> setKnowledgeScore(int score) =>
      prefs.setInt(AppConstants.keyKnowledgeScore, score);

  static int getTotalQuizzes() =>
      prefs.getInt(AppConstants.keyTotalQuizzes) ?? 0;

  static Future<void> setTotalQuizzes(int count) =>
      prefs.setInt(AppConstants.keyTotalQuizzes, count);

  // ── STREAK LOGIC ──────────────────────────────────────────────────────────
  static Future<int> updateStreakAfterQuiz() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastDate = getLastPlayedDate();
    final streak = getStreak();

    if (lastDate == today) return streak; // already played today

    int newStreak;
    if (lastDate.isEmpty) {
      newStreak = 1;
    } else {
      final last = DateTime.parse(lastDate);
      final diff = DateTime.now().difference(last).inDays;
      newStreak = diff == 1 ? streak + 1 : 1;
    }

    await setStreak(newStreak);
    await setLastPlayedDate(today);
    return newStreak;
  }

  // ── QUIZ HISTORY ──────────────────────────────────────────────────────────
  static List<QuizResult> getQuizHistory() {
    final stored = prefs.getString(AppConstants.keyQuizHistory);
    if (stored == null) return [];
    try {
      final list = jsonDecode(stored) as List;
      return list.map((e) => QuizResult.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> addQuizResult(QuizResult result) async {
    final history = getQuizHistory();
    history.insert(0, result);
    final trimmed = history.take(30).toList(); // keep last 30
    await prefs.setString(
      AppConstants.keyQuizHistory,
      jsonEncode(trimmed.map((e) => e.toJson()).toList()),
    );
  }

  // ── CACHED QUESTIONS ──────────────────────────────────────────────────────
  // Bump this string any time you want to invalidate all existing caches.
  static const String _cacheVersion = 'v2';
  static const String _keyCacheVersion = '_quiz_cache_version';

  static List<Question>? getCachedQuestions() {
    // Reject cache from any previous version
    final version = prefs.getString(_keyCacheVersion) ?? '';
    if (version != _cacheVersion) return null;

    final date = prefs.getString(AppConstants.keyCachedQuestionsDate) ?? '';
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (date != today) return null; // stale date

    final stored = prefs.getString(AppConstants.keyCachedQuestions);
    if (stored == null) return null;
    try {
      final list = jsonDecode(stored) as List;
      return list.map((e) => Question.fromJson(e)).toList();
    } catch (_) {
      return null;
    }
  }

  static Future<void> cacheQuestions(List<Question> questions) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await prefs.setString(_keyCacheVersion, _cacheVersion);
    await prefs.setString(AppConstants.keyCachedQuestionsDate, today);
    await prefs.setString(
      AppConstants.keyCachedQuestions,
      jsonEncode(questions.map((e) => e.toJson()).toList()),
    );
  }

  static Future<void> clearQuestionCache() async {
    await prefs.remove(AppConstants.keyCachedQuestions);
    await prefs.remove(AppConstants.keyCachedQuestionsDate);
    await prefs.remove(_keyCacheVersion);
  }

  // ── FULL USER DATA ────────────────────────────────────────────────────────
  static UserData loadUserData() {
    return UserData(
      name: getUserName(),
      photoUrl: getUserPhotoUrl(),
      streak: getStreak(),
      knowledgeScore: getKnowledgeScore(),
      totalQuizzes: getTotalQuizzes(),
      lastPlayedDate: getLastPlayedDate(),
      selectedCategories: getSelectedCategories(),
      country: getUserCountry(),
      notificationHour: getNotificationHour(),
      notificationMinute: getNotificationMinute(),
      recentResults: getQuizHistory(),
    );
  }
}
