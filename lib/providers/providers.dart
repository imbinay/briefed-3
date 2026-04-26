import 'dart:async';
import 'dart:developer' as dev;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../models/models.dart';
import '../services/storage_service.dart';
import '../services/news_service.dart';
import '../services/gemini_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// THEME PROVIDER
// ─────────────────────────────────────────────────────────────────────────────

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(_load());

  static ThemeMode _load() {
    final stored = StorageService.getThemeMode();
    switch (stored) {
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.light;
    }
  }

  void setLight() {
    state = ThemeMode.light;
    StorageService.setThemeMode('light');
  }

  void setDark() {
    state = ThemeMode.dark;
    StorageService.setThemeMode('dark');
  }

  void setSystem() {
    state = ThemeMode.system;
    StorageService.setThemeMode('system');
  }

  String get modeLabel {
    switch (state) {
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
      default:
        return 'light';
    }
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>(
  (ref) => ThemeNotifier(),
);

final authStateProvider = StreamProvider<User?>(
  (ref) => AuthService.authStateChanges,
);

final selectedTabProvider = StateProvider<int>((ref) => 0);

// ─────────────────────────────────────────────────────────────────────────────
// USER PROVIDER
// ─────────────────────────────────────────────────────────────────────────────

class UserNotifier extends StateNotifier<UserData> {
  UserNotifier() : super(StorageService.loadUserData());

  void updateName(String name) {
    StorageService.setUserName(name);
    state = state.copyWith(name: name);
  }

  void updatePhotoUrl(String photoUrl) {
    StorageService.setUserPhotoUrl(photoUrl);
    state = state.copyWith(photoUrl: photoUrl);
  }

  void syncAuthProfile(User? user) {
    if (user == null || user.isAnonymous) return;
    final name = user.displayName?.trim().isNotEmpty == true
        ? user.displayName!.trim()
        : user.email?.trim() ?? '';
    if (name.isNotEmpty) StorageService.setUserName(name);
    StorageService.setUserPhotoUrl(user.photoURL ?? '');
    state = state.copyWith(
      name: name.isNotEmpty ? name : state.name,
      photoUrl: user.photoURL ?? '',
    );
  }

  Future<void> resetForGuest() async {
    await StorageService.resetUserData();
    state = StorageService.loadUserData();
  }

  void updateCategories(List<String> cats) {
    StorageService.setSelectedCategories(cats);
    state = state.copyWith(selectedCategories: cats);
  }

  void updateNotificationHour(int hour) {
    StorageService.setNotificationHour(hour);
    StorageService.setNotificationMinute(0);
    NotificationService.scheduleDailyReminder(hour: hour, minute: 0);
    state = state.copyWith(notificationHour: hour, notificationMinute: 0);
  }

  void updateNotificationTime(int hour, int minute) {
    StorageService.setNotificationHour(hour);
    StorageService.setNotificationMinute(minute);
    NotificationService.scheduleDailyReminder(hour: hour, minute: minute);
    state = state.copyWith(notificationHour: hour, notificationMinute: minute);
  }

  Future<void> afterQuiz(QuizResult result) async {
    // Schedule "quiz ready" notification for all users (including guests)
    unawaited(NotificationService.scheduleQuizReady());
    if (AuthService.isGuest) return; // guests play but don't persist progress

    final newStreak = await StorageService.updateStreakAfterQuiz();
    final newScore = state.knowledgeScore + result.pointsEarned;
    final newTotal = state.totalQuizzes + 1;

    await StorageService.setKnowledgeScore(newScore);
    await StorageService.setTotalQuizzes(newTotal);
    await StorageService.addQuizResult(result);

    final history = StorageService.getQuizHistory();

    state = state.copyWith(
      streak: newStreak,
      longestStreak:
          newStreak > state.longestStreak ? newStreak : state.longestStreak,
      knowledgeScore: newScore,
      totalQuizzes: newTotal,
      lastPlayedDate: DateTime.now().toIso8601String().substring(0, 10),
      recentResults: history,
    );

    await AuthService.syncQuizResult(userData: state, result: result);
  }

  void reload() {
    state = StorageService.loadUserData();
  }
}

final userProvider = StateNotifierProvider<UserNotifier, UserData>(
  (ref) => UserNotifier(),
);

// ─────────────────────────────────────────────────────────────────────────────
// NEWS PROVIDER
// ─────────────────────────────────────────────────────────────────────────────

class NewsState {
  final List<NewsArticle> articles;
  final bool isLoading;
  final String? error;

  const NewsState({
    this.articles = const [],
    this.isLoading = false,
    this.error,
  });

  NewsState copyWith({
    List<NewsArticle>? articles,
    bool? isLoading,
    String? error,
  }) =>
      NewsState(
        articles: articles ?? this.articles,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class NewsNotifier extends StateNotifier<NewsState> {
  String _lastCountry = '';
  List<String> _lastCategories = [];

  static List<NewsArticle> get _mock =>
      AppConstants.mockArticles.map((e) => NewsArticle.fromJson(e)).toList();

  // Start with mock so the UI is never blank on launch
  NewsNotifier() : super(NewsState(articles: _mock));

  Future<void> load({
    required String country,
    required List<String> categories,
  }) async {
    _lastCountry = country;
    _lastCategories = categories;
    if (!mounted) return;
    state = NewsState(articles: state.articles, isLoading: true);
    unawaited(_fetchReal(country: country, categories: categories));
  }

  Future<void> _fetchReal({
    required String country,
    required List<String> categories,
  }) async {
    try {
      final articles = await NewsService.fetchHeadlines(
        country: country,
        categories: categories,
      ).timeout(const Duration(seconds: 20));
      if (!mounted) return;
      final raw = articles.isNotEmpty ? articles : _mock;
      final seenLinks = <String>{};
      final seenTitles = <String>{};
      final deduped = raw.where((a) {
        final linkKey = a.link.isNotEmpty ? a.link : '';
        final titleKey = a.title.toLowerCase().trim();
        if (titleKey.isEmpty) return false;
        if (linkKey.isNotEmpty && !seenLinks.add(linkKey)) return false;
        if (!seenTitles.add(titleKey)) return false;
        return true;
      }).toList();
      state = NewsState(articles: deduped, isLoading: false);
    } catch (e) {
      dev.log('[News] fetch failed: $e', name: 'Briefed');
      if (!mounted) return;
      state = NewsState(articles: _mock, isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() =>
      load(country: _lastCountry, categories: _lastCategories);

  List<NewsArticle> get topStories => state.articles.take(4).toList();

  List<NewsArticle> byCategory(String cat) => state.articles
      .where((a) => a.category.toLowerCase().contains(cat.toLowerCase()))
      .toList();
}

final newsProvider = StateNotifierProvider<NewsNotifier, NewsState>(
  (ref) => NewsNotifier(),
);

// ─────────────────────────────────────────────────────────────────────────────
// QUIZ PROVIDER
// ─────────────────────────────────────────────────────────────────────────────

enum QuizStatus { idle, loading, active, finished, error }

class QuizState {
  final List<Question> questions;
  final int currentIndex;
  final List<int?> answers; // null = unanswered, int = selected index
  final int timeLeft;
  final QuizStatus status;
  final String? errorMessage;
  final int startTimestamp;

  const QuizState({
    this.questions = const [],
    this.currentIndex = 0,
    this.answers = const [],
    this.timeLeft = AppConstants.timerSeconds,
    this.status = QuizStatus.idle,
    this.errorMessage,
    this.startTimestamp = 0,
  });

  Question? get currentQuestion =>
      currentIndex < questions.length ? questions[currentIndex] : null;

  int? get currentAnswer =>
      currentIndex < answers.length ? answers[currentIndex] : null;

  bool get isAnswered => currentAnswer != null;

  int get score => answers.asMap().entries.where((e) {
        if (e.key >= questions.length) return false;
        return e.value == questions[e.key].correctIndex;
      }).length;

  int get pointsEarned {
    int pts = 0;
    for (int i = 0; i < answers.length; i++) {
      if (i >= questions.length) break;
      if (answers[i] == questions[i].correctIndex) {
        pts += questions[i].isEasy
            ? AppConstants.pointsEasy
            : AppConstants.pointsHard;
      }
    }
    return pts;
  }

  QuizResult buildResult() {
    final elapsed =
        (DateTime.now().millisecondsSinceEpoch - startTimestamp) ~/ 1000;
    return QuizResult(
      date: DateTime.now().toIso8601String().substring(0, 10),
      score: score,
      totalQuestions: questions.length,
      pointsEarned: pointsEarned,
      timeTakenSeconds: elapsed,
      categories: questions.map((q) => q.category).toSet().toList(),
    );
  }

  QuizState copyWith({
    List<Question>? questions,
    int? currentIndex,
    List<int?>? answers,
    int? timeLeft,
    QuizStatus? status,
    String? errorMessage,
    int? startTimestamp,
  }) =>
      QuizState(
        questions: questions ?? this.questions,
        currentIndex: currentIndex ?? this.currentIndex,
        answers: answers ?? this.answers,
        timeLeft: timeLeft ?? this.timeLeft,
        status: status ?? this.status,
        errorMessage: errorMessage ?? this.errorMessage,
        startTimestamp: startTimestamp ?? this.startTimestamp,
      );
}

class QuizNotifier extends StateNotifier<QuizState> {
  QuizNotifier() : super(const QuizState());

  Timer? _timer;

  Future<void> startQuiz(
    List<NewsArticle> articles, {
    bool forceRefresh = false,
    bool bonusRound = false,
  }) async {
    state = state.copyWith(status: QuizStatus.loading);
    try {
      final questions = await GeminiService.generateQuestions(
        articles: articles,
        forceRefresh: forceRefresh,
        bonusRound: bonusRound,
      );
      state = QuizState(
        questions: questions,
        answers: List.filled(questions.length, null),
        status: QuizStatus.active,
        timeLeft: AppConstants.timerSeconds,
        startTimestamp: DateTime.now().millisecondsSinceEpoch,
      );
      _startTimer();
    } catch (e) {
      // Surface the REAL error — no silent fallback to mock
      state = state.copyWith(
        status: QuizStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (state.timeLeft <= 1) {
        t.cancel();
        // Auto-advance if timer hits 0 and question unanswered
        if (!state.isAnswered) {
          _recordAnswer(-1); // -1 = timed out
        }
      } else {
        state = state.copyWith(timeLeft: state.timeLeft - 1);
      }
    });
  }

  void answerQuestion(int selectedIndex) {
    if (state.isAnswered) return;
    _timer?.cancel();
    _recordAnswer(selectedIndex);
  }

  void _recordAnswer(int selectedIndex) {
    final newAnswers = List<int?>.from(state.answers);
    newAnswers[state.currentIndex] = selectedIndex;
    state = state.copyWith(answers: newAnswers);
  }

  void nextQuestion() {
    final nextIndex = state.currentIndex + 1;
    if (nextIndex >= state.questions.length) {
      state = state.copyWith(status: QuizStatus.finished);
    } else {
      state = state.copyWith(
        currentIndex: nextIndex,
        timeLeft: AppConstants.timerSeconds,
      );
      _startTimer();
    }
  }

  QuizResult buildResult() {
    return state.buildResult();
  }

  void loadMock(List<Question> questions) {
    state = QuizState(
      questions: questions,
      answers: List.filled(questions.length, null),
      status: QuizStatus.active,
      timeLeft: AppConstants.timerSeconds,
      startTimestamp: DateTime.now().millisecondsSinceEpoch,
    );
    _startTimer();
  }

  void reset() {
    _timer?.cancel();
    state = const QuizState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final quizProvider = StateNotifierProvider<QuizNotifier, QuizState>(
  (ref) => QuizNotifier(),
);

// Hot Take provider
class HotTakeState {
  final String question;
  final int yesVotes;
  final int noVotes;
  final String? userVote;

  HotTakeState({
    required this.question,
    this.yesVotes = 5812,
    this.noVotes = 4231,
    this.userVote,
  });

  int get total => yesVotes + noVotes;
  int get yesPercent => total == 0 ? 0 : (yesVotes / total * 100).round();
  int get noPercent => total == 0 ? 0 : (noVotes / total * 100).round();

  HotTakeState copyWith({String? userVote, int? yesVotes, int? noVotes}) =>
      HotTakeState(
        question: question,
        yesVotes: yesVotes ?? this.yesVotes,
        noVotes: noVotes ?? this.noVotes,
        userVote: userVote ?? this.userVote,
      );
}

class HotTakeNotifier extends StateNotifier<HotTakeState> {
  static const _questions = [
    'Will AI replace journalists within 10 years?',
    'Should social media platforms be liable for misinformation?',
    'Is remote work better for productivity than office work?',
    'Will electric vehicles fully replace petrol cars by 2035?',
    'Should governments regulate AI like pharmaceuticals?',
    'Is cryptocurrency the future of everyday money?',
    'Should space exploration be left to private companies?',
    'Will humans land on Mars within the next 20 years?',
    'Is social media doing more harm than good to society?',
    'Should university education be free worldwide?',
    'Will quantum computing make current encryption obsolete?',
    'Is nuclear energy the best answer to climate change?',
    'Should tech giants be broken up by antitrust laws?',
    'Will self-driving cars eliminate most road accidents?',
    'Is streaming killing the music industry?',
    'Should there be a global minimum tax on billionaires?',
    'Will gene editing eliminate hereditary diseases in our lifetime?',
    'Is a 4-day work week the future of employment?',
    'Should voting be mandatory in democracies?',
    'Will virtual reality eventually replace physical travel?',
  ];

  static String _dailyQuestion() {
    final dayOfYear =
        DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
    return _questions[dayOfYear % _questions.length];
  }

  HotTakeNotifier() : super(HotTakeState(question: _dailyQuestion()));

  void vote(String vote) {
    if (state.userVote != null) return;
    state = state.copyWith(
      userVote: vote,
      yesVotes: vote == 'yes' ? state.yesVotes + 1 : state.yesVotes,
      noVotes: vote == 'no' ? state.noVotes + 1 : state.noVotes,
    );
  }
}

final hotTakeProvider = StateNotifierProvider<HotTakeNotifier, HotTakeState>(
  (ref) => HotTakeNotifier(),
);

// ─────────────────────────────────────────────────────────────────────────────
// LEADERBOARD PROVIDER
// ─────────────────────────────────────────────────────────────────────────────

class LeaderboardEntry {
  final String uid;
  final String name;
  final String photoUrl;
  final int score;
  final int streak;
  final bool isYou;
  final bool isSeparator;

  const LeaderboardEntry({
    required this.uid,
    required this.name,
    this.photoUrl = '',
    required this.score,
    required this.streak,
    this.isYou = false,
    this.isSeparator = false,
  });
}

final leaderboardProvider =
    FutureProvider.autoDispose<List<LeaderboardEntry>>((ref) async {
  final authUser = ref.watch(authStateProvider).valueOrNull;
  if (authUser == null || authUser.isAnonymous) return [];

  final db = FirebaseFirestore.instance;
  final currentUid = authUser.uid;

  // Always fetch own document first — this works under standard security rules.
  LeaderboardEntry? myEntry;
  final myDoc = await db.collection('users').doc(currentUid).get();
  if (myDoc.exists) {
    final data = myDoc.data()!;
    final rawName = (data['displayName'] as String?) ?? '';
    final photoUrl = (data['photoUrl'] as String?) ?? authUser.photoURL ?? '';
    myEntry = LeaderboardEntry(
      uid: currentUid,
      name: rawName.trim().isEmpty ? 'You' : rawName,
      photoUrl: photoUrl,
      score: (data['knowledgeScore'] as int?) ?? 0,
      streak: (data['streak'] as int?) ?? 0,
      isYou: true,
    );
  }

  // Try to query the full leaderboard. May fail if Firestore rules restrict
  // collection-level reads — in that case we fall back to showing only the
  // current user's data. To enable full leaderboard, update your Firestore
  // rules to: allow read: if request.auth != null;
  try {
    final snap = await db
        .collection('users')
        .orderBy('knowledgeScore', descending: true)
        .limit(10)
        .get();

    final entries = snap.docs.map((doc) {
      final data = doc.data();
      final rawName = (data['displayName'] as String?) ?? '';
      return LeaderboardEntry(
        uid: doc.id,
        name: rawName.trim().isEmpty ? 'Anonymous' : rawName,
        photoUrl: doc.id == currentUid
            ? ((data['photoUrl'] as String?) ?? authUser.photoURL ?? '')
            : ((data['photoUrl'] as String?) ?? ''),
        score: (data['knowledgeScore'] as int?) ?? 0,
        streak: (data['streak'] as int?) ?? 0,
        isYou: doc.id == currentUid,
      );
    }).toList();

    final alreadyIn = entries.any((e) => e.uid == currentUid);
    if (!alreadyIn && myEntry != null) {
      entries.add(LeaderboardEntry(
        uid: myEntry.uid,
        name: myEntry.name,
        photoUrl: myEntry.photoUrl,
        score: myEntry.score,
        streak: myEntry.streak,
        isYou: true,
        isSeparator: true,
      ));
    }
    return entries;
  } catch (_) {
    // Permission denied or no index — show just own data
    return myEntry != null ? [myEntry] : [];
  }
});
