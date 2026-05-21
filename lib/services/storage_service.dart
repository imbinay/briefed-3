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
    await prefs.remove(AppConstants.keyIsPro);
    await prefs.remove('bonus_played_date');
    await clearQuestionCache();
    await clearArticleCache();
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

  static int getDailyGoal() => prefs.getInt('dailyGoal') ?? 5;

  static Future<void> setDailyGoal(int questions) =>
      prefs.setInt('dailyGoal', questions);

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

  static Future<void> setLastPlayedDate(String date) async {
    await prefs.setString(AppConstants.keyLastPlayedDate, date);
    await prefs.setInt('lastPlayedTimestampMs', DateTime.now().millisecondsSinceEpoch);
  }

  static DateTime? getLastPlayedTimestamp() {
    final ms = prefs.getInt('lastPlayedTimestampMs');
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  static bool hasBonusPlayedToday() {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return prefs.getString('bonus_played_date') == today;
  }

  static Future<void> setBonusPlayedToday() {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return prefs.setString('bonus_played_date', today);
  }

  // ── PER-GAME DAILY PLAY COUNT (for interstitial gating) ──────────────────
  // Key: game_plays_{gameId}_{yyyy-MM-dd}  Value: int count

  static int getGamePlaysToday(String gameId) {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return prefs.getInt('game_plays_${gameId}_$today') ?? 0;
  }

  static Future<void> incrementGamePlaysToday(String gameId) {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final key = 'game_plays_${gameId}_$today';
    return prefs.setInt(key, (prefs.getInt(key) ?? 0) + 1);
  }

  // ── PER-CATEGORY COMPLETION ───────────────────────────────────────────────
  // Key: briefed_completed_{category}_{yyyy-MM-dd}
  // Value: "{correct}/{total},{points}"

  static String? getCategoryCompletion(String category) {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return prefs.getString('briefed_completed_${category}_$today');
  }

  static Future<void> setCategoryCompletion(
      String category, int correct, int total, int points) {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return prefs.setString(
        'briefed_completed_${category}_$today', '$correct/$total,$points');
  }

  static int getKnowledgeScore() =>
      prefs.getInt(AppConstants.keyKnowledgeScore) ?? 0;

  static Future<void> setKnowledgeScore(int score) =>
      prefs.setInt(AppConstants.keyKnowledgeScore, score);

  static int getTotalQuizzes() =>
      prefs.getInt(AppConstants.keyTotalQuizzes) ?? 0;

  static Future<void> setTotalQuizzes(int count) =>
      prefs.setInt(AppConstants.keyTotalQuizzes, count);

  // ── SUBSCRIPTION ─────────────────────────────────────────────────────────
  static bool getIsPro() => prefs.getBool(AppConstants.keyIsPro) ?? false;

  static Future<void> setIsPro(bool value) =>
      prefs.setBool(AppConstants.keyIsPro, value);

  // ── STREAK LOGIC ──────────────────────────────────────────────────────────
  static Future<int> updateStreakAfterQuiz() async {
    final now = DateTime.now();
    final today = '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    final lastDate = getLastPlayedDate();
    final streak = getStreak();

    if (lastDate == today) return streak; // already played today

    int newStreak;
    if (lastDate.isEmpty) {
      newStreak = 1;
    } else {
      // DateTime.parse('YYYY-MM-DD') returns UTC midnight in Dart. Build local
      // DateTime objects from the date components so inDays reflects calendar
      // days in the user's timezone rather than raw 24-hour durations.
      final todayDate = DateTime(now.year, now.month, now.day);
      final parts = lastDate.split('-');
      final lastLocal = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      final diff = todayDate.difference(lastLocal).inDays;
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

  // ── CACHED NEWS ARTICLES ─────────────────────────────────────────────────
  // Keyed by country + sorted categories. TTL = 2 hours.

  static List<NewsArticle>? getCachedArticles({
    required String country,
    required List<String> categories,
  }) {
    final stored = prefs.getString(AppConstants.keyCachedNews);
    if (stored == null) return null;
    try {
      final blob = jsonDecode(stored) as Map<String, dynamic>;
      if (blob['country'] != country) return null;
      final catKey = (List<String>.from(blob['categories'] as List? ?? []))
        ..sort();
      final requested = [...categories]..sort();
      if (catKey.join(',') != requested.join(',')) return null;
      final ts = blob['ts'] as int? ?? 0;
      final age = DateTime.now().millisecondsSinceEpoch - ts;
      if (age > AppConstants.newsCacheTtlMinutes * 60 * 1000) return null;
      final list = blob['articles'] as List? ?? [];
      return list
          .map((e) => NewsArticle.fromJson(e as Map<String, dynamic>))
          .where((a) => a.title.isNotEmpty)
          .toList();
    } catch (_) {
      return null;
    }
  }

  static Future<void> cacheArticles({
    required List<NewsArticle> articles,
    required String country,
    required List<String> categories,
  }) async {
    final blob = jsonEncode({
      'country': country,
      'categories': [...categories]..sort(),
      'ts': DateTime.now().millisecondsSinceEpoch,
      'articles': articles.map((a) => a.toJson()).toList(),
    });
    await prefs.setString(AppConstants.keyCachedNews, blob);
  }

  static Future<void> clearArticleCache() =>
      prefs.remove(AppConstants.keyCachedNews);

  // ── CACHED QUESTIONS ──────────────────────────────────────────────────────
  // Bump this string any time you want to invalidate all existing caches.
  static const String _cacheVersion = 'v4';
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
      isPro: getIsPro(),
    );
  }
}
