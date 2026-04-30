import 'dart:async';
import 'dart:developer' as dev;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart' if (dart.library.js_interop) '../core/iap_stub.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../core/constants.dart';
import '../models/models.dart';
import '../services/storage_service.dart';
import '../services/news_service.dart';
import '../services/gemini_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/ad_service.dart';

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

  Future<void> syncAuthProfile(User? user) async {
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
    try {
      final remote = await AuthService.currentUserData();
      if (remote == null) return;
      final remoteIsPro = remote['isPro'] == true;
      await StorageService.setIsPro(remoteIsPro);
      state = state.copyWith(isPro: remoteIsPro);
      AdService.configure(adsEnabled: !remoteIsPro);
    } catch (e) {
      dev.log('[User] profile sync failed: $e', name: 'Briefed');
    }
  }

  Future<void> resetForGuest() async {
    await StorageService.resetUserData();
    state = StorageService.loadUserData();
    AdService.configure(adsEnabled: true);
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

  Future<void> setPro(bool value) async {
    await StorageService.setIsPro(value);
    await AuthService.setProStatus(value);
    state = state.copyWith(isPro: value);
    AdService.configure(adsEnabled: !value);
  }

  Future<void> activateProFromPurchase(PurchaseDetails purchase) async {
    if (kIsWeb) return; // Prevent execution on web
    final token = purchase.verificationData.serverVerificationData;
    await StorageService.setIsPro(true);
    await AuthService.setProStatus(
      true,
      productId: purchase.productID,
      purchaseToken: token.isEmpty ? null : token,
      source: purchase.verificationData.source,
    );
    state = state.copyWith(isPro: true);
    AdService.configure(adsEnabled: false);
  }

  Future<void> afterQuiz(QuizResult result) async {
    if (!state.isPro && !kIsWeb) unawaited(NotificationService.scheduleQuizReady());

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

    if (!AuthService.isGuest) {
      await AuthService.syncQuizResult(userData: state, result: result);
    }
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
  final bool isOffline;
  final String? error;

  const NewsState({
    this.articles = const [],
    this.isLoading = false,
    this.isOffline = false,
    this.error,
  });

  NewsState copyWith({
    List<NewsArticle>? articles,
    bool? isLoading,
    bool? isOffline,
    String? error,
  }) =>
      NewsState(
        articles: articles ?? this.articles,
        isLoading: isLoading ?? this.isLoading,
        isOffline: isOffline ?? this.isOffline,
        error: error,
      );
}

class NewsNotifier extends StateNotifier<NewsState> {
  String _lastCountry = '';
  List<String> _lastCategories = [];

  static List<NewsArticle> get _mock =>
      AppConstants.mockArticles.map((e) => NewsArticle.fromJson(e)).toList();

  NewsNotifier() : super(NewsState(articles: _mock, isLoading: true));

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
      if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup')) {
        dev.log('[News] No internet connection', name: 'Briefed');
        if (!mounted) return;
        state = NewsState(articles: _mock, isLoading: false, isOffline: true);
        return;
      }
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
    final attempts = questions.asMap().entries.map((entry) {
      final index = entry.key;
      final question = entry.value;
      final selected = index < answers.length ? answers[index] : null;
      return QuestionAttempt(
        category: question.category,
        difficulty: question.difficulty,
        correct: selected == question.correctIndex,
        selectedIndex: selected ?? -1,
        correctIndex: question.correctIndex,
      );
    }).toList();
    return QuizResult(
      date: DateTime.now().toIso8601String().substring(0, 10),
      score: score,
      totalQuestions: questions.length,
      pointsEarned: pointsEarned,
      timeTakenSeconds: elapsed,
      categories: questions.map((q) => q.category).toSet().toList(),
      attempts: attempts,
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
    int? replaySeed,
  }) async {
    state = state.copyWith(status: QuizStatus.loading);
    try {
      final questions = await GeminiService.generateQuestions(
        articles: articles,
        forceRefresh: forceRefresh,
        bonusRound: bonusRound,
        replaySeed: replaySeed,
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
  final int questionIndex;
  final int yesVotes;
  final int noVotes;
  final String? userVote;
  final bool isLoading;

  const HotTakeState({
    required this.question,
    required this.questionIndex,
    this.yesVotes = 0,
    this.noVotes = 0,
    this.userVote,
    this.isLoading = true,
  });

  int get total => yesVotes + noVotes;
  int get yesPercent => total == 0 ? 50 : (yesVotes / total * 100).round();
  int get noPercent => total == 0 ? 50 : 100 - yesPercent;

  HotTakeState copyWith({
    String? userVote,
    int? yesVotes,
    int? noVotes,
    bool? isLoading,
    bool clearVote = false,
  }) =>
      HotTakeState(
        question: question,
        questionIndex: questionIndex,
        yesVotes: yesVotes ?? this.yesVotes,
        noVotes: noVotes ?? this.noVotes,
        userVote: clearVote ? null : (userVote ?? this.userVote),
        isLoading: isLoading ?? this.isLoading,
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
    'Should AI-generated art be eligible for copyright protection?',
    'Will cash become completely obsolete within 20 years?',
    'Should junk food advertising be banned during children\'s TV?',
    'Is space tourism a waste of resources when Earth has bigger problems?',
    'Should all countries adopt a universal basic income?',
    'Will humans ever achieve true artificial general intelligence?',
    'Should smartphones be banned in all schools worldwide?',
    'Is climate change the single biggest threat facing humanity today?',
    'Should wealthy countries open their borders to climate refugees?',
    'Will China surpass the US as the world\'s dominant superpower?',
    'Should athletes be allowed to use performance-enhancing drugs if they\'re safe?',
    'Is the 24-hour news cycle making society more anxious?',
    'Should tech companies pay users for their personal data?',
    'Will renewable energy fully replace fossil fuels by 2050?',
    'Should organ donation be opt-out rather than opt-in?',
    'Is cancel culture ultimately good or bad for society?',
    'Should the voting age be lowered to 16 globally?',
    'Will lab-grown meat completely replace farmed animals within 30 years?',
    'Should deepfake videos be treated as a criminal offence?',
    'Is social media the main driver of political polarisation?',
    'Should governments control the development of powerful AI systems?',
    'Will online learning replace traditional universities within a generation?',
    'Should extreme wealth — over \$1 billion — simply be illegal?',
    'Is colonising other planets a moral imperative for humanity\'s survival?',
    'Should airlines pay a higher tax to offset their carbon emissions?',
    'Will human lifespans routinely exceed 150 years by 2100?',
    'Should all drugs be decriminalised and treated as a health issue?',
    'Is privacy more important than national security in the digital age?',
    'Should robots and AI systems be taxed to fund retraining for displaced workers?',
    'Will a human-level AI companion become the norm within 15 years?',
    'Should fast fashion be heavily taxed to discourage overconsumption?',
    'Is the global education system failing today\'s students?',
    'Should social media companies be required to verify users\' real identities?',
    'Will gene-edited \'designer babies\' become commonplace within 30 years?',
    'Should the Olympic Games be permanently hosted in one location?',
    'Is the internet doing more to unite or divide the world?',
  ];

  static int _dailyIndex() {
    final dayOfYear =
        DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
    return dayOfYear % _questions.length;
  }

  HotTakeNotifier()
      : super(HotTakeState(
          question: _questions[_dailyIndex()],
          questionIndex: _dailyIndex(),
        )) {
    _load();
  }

  Future<void> _load() async {
    final docId = 'q_${state.questionIndex}';
    try {
      final snap = await FirebaseFirestore.instance
          .collection('hot_takes')
          .doc(docId)
          .get();
      int yes = 0, no = 0;
      if (snap.exists) {
        yes = (snap.data()!['yes'] as int?) ?? 0;
        no = (snap.data()!['no'] as int?) ?? 0;
      }

      String? existingVote;
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.isAnonymous) {
        final userSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userSnap.exists) {
          final votes =
              userSnap.data()!['hotTakeVotes'] as Map<String, dynamic>?;
          existingVote = votes?[docId] as String?;
        }
      }

      if (mounted) {
        state = state.copyWith(
          yesVotes: yes,
          noVotes: no,
          userVote: existingVote,
          isLoading: false,
        );
      }
    } catch (e) {
      dev.log('[HotTake] load failed: $e', name: 'Briefed');
      if (mounted) state = state.copyWith(isLoading: false);
    }
  }

  Future<void> vote(String vote) async {
    if (state.userVote != null || state.isLoading) return;
    final docId = 'q_${state.questionIndex}';

    // Optimistic update
    state = state.copyWith(
      userVote: vote,
      yesVotes: vote == 'yes' ? state.yesVotes + 1 : state.yesVotes,
      noVotes: vote == 'no' ? state.noVotes + 1 : state.noVotes,
    );

    try {
      await FirebaseFirestore.instance
          .collection('hot_takes')
          .doc(docId)
          .set({
        'question': state.question,
        vote: FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.isAnonymous) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'hotTakeVotes': {docId: vote},
        }, SetOptions(merge: true));
      }
    } catch (e) {
      dev.log('[HotTake] vote failed: $e', name: 'Briefed');
      if (mounted) {
        state = state.copyWith(
          clearVote: true,
          yesVotes: vote == 'yes' ? state.yesVotes - 1 : state.yesVotes,
          noVotes: vote == 'no' ? state.noVotes - 1 : state.noVotes,
        );
      }
    }
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

  try {
    final snap = await db
        .collection('leaderboard')
        .orderBy('knowledgeScore', descending: true)
        .limit(30)
        .get();

    final entries = snap.docs
        .map((doc) {
          final data = doc.data();
          final rawName = (data['displayName'] as String?) ?? '';
          return LeaderboardEntry(
            uid: doc.id,
            name: rawName.trim(),
            photoUrl: doc.id == currentUid
                ? ((data['photoUrl'] as String?) ?? authUser.photoURL ?? '')
                : ((data['photoUrl'] as String?) ?? ''),
            score: (data['knowledgeScore'] as int?) ?? 0,
            streak: (data['streak'] as int?) ?? 0,
            isYou: doc.id == currentUid,
          );
        })
        // ONLY show users with names, and remove those with the default placeholder
        .where((e) =>
            e.name.isNotEmpty && e.name != AppConstants.defaultAnonymousName)
        .take(10)
        .toList();

    // If I'm not in the top 10, add a separator and me at the bottom
    final amInTop10 = entries.any((e) => e.uid == currentUid);
    if (!amInTop10 && myEntry != null) {
      entries.add(const LeaderboardEntry(
        uid: 'sep',
        name: '',
        score: 0,
        streak: 0,
        isSeparator: true,
      ));
      entries.add(myEntry);
    }
    return entries;
  } catch (e) {
    dev.log('[Leaderboard] Error: $e', name: 'Briefed');
    return myEntry != null ? [myEntry] : [];
  }
});

final dailyRankProvider = FutureProvider.autoDispose<String>((ref) async {
  final authUser = ref.watch(authStateProvider).valueOrNull;
  if (authUser == null || authUser.isAnonymous) return 'Sign in';

  final today = DateTime.now().toIso8601String().substring(0, 10);
  final snap = await FirebaseFirestore.instance
      .collection('quizzes')
      .doc(today)
      .collection('scores')
      .orderBy('pointsEarned', descending: true)
      .limit(500)
      .get();

  if (snap.docs.isEmpty) return 'Today';
  final index = snap.docs.indexWhere((doc) => doc.id == authUser.uid);
  if (index == -1) return 'Today';

  return '#${index + 1} of ${snap.docs.length}';
});
