import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../widgets/ad_widgets.dart';
import '../features/news/models/news_category.dart';
import '../features/news/providers/news_pipeline_provider.dart';
import '../features/xp/daily_tracker.dart';
import '../features/xp/xp_provider.dart';
import '../features/xp/xp_service.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import 'briefing_read_screen.dart';

// ─── Colour constants ────────────────────────────────────────────────────────

const _orange = Color(0xFFFF5A1F);
const _deepOrange = Color(0xFFD84315);

const Map<String, Color> _categoryColours = {
  'world': Color(0xFF2196F3),
  'politics': Color(0xFF9C27B0),
  'sports': Color(0xFF4CAF50),
  'technology': Color(0xFF00BCD4),
  'business': Color(0xFFFF9800),
  'health': Color(0xFF26A69A),
  'entertainment': Color(0xFFE91E63),
};

// ─── Helpers ──────────────────────────────────────────────────────────────────

Map<String, int>? _parseCompletion(String? raw) {
  if (raw == null) return null;
  try {
    final parts = raw.split(',');
    final scoreParts = parts[0].split('/');
    return {
      'correct': int.parse(scoreParts[0]),
      'total': int.parse(scoreParts[1]),
      'points': int.parse(parts[1]),
    };
  } catch (_) {
    return null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TODAY SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen>
    with TickerProviderStateMixin {
  // World is covered by the main daily mix quiz — only these get separate cards.
  static const _categoryQuizzes = [
    NewsCategory.politics,
    NewsCategory.sports,
    NewsCategory.technology,
    NewsCategory.business,
    NewsCategory.health,
    NewsCategory.entertainment,
  ];

  // ── Controllers ──────────────────────────────────────────────────────────
  late AnimationController _entryCtrl;   // 1 400ms master
  late AnimationController _pulseCtrl;   // repeat — flame pulse
  late AnimationController _arrowCtrl;   // repeat — game arrow
  late AnimationController _quizBtnCtrl; // repeat — Play Quiz pulse

  // ── Entry animations ─────────────────────────────────────────────────────
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;
  late Animation<double> _briefingFade;
  late Animation<double> _briefingScale;
  late Animation<double> _progressFade;
  late Animation<double> _gamesFade;
  late Animation<Offset> _gamesSlide;
  late Animation<double> _pulseScale;

  // ── State ────────────────────────────────────────────────────────────────
  final Map<String, Map<String, int>?> _catCompletions = {};
  bool _briefingRead = false;
  int _selectedStatIndex = 0;
  Timer? _clockTimer;
  String _nextBriefLabel = '';

  @override
  void initState() {
    super.initState();
    _loadState();
    _initAnimations();
    _entryCtrl.forward();
    XpService.migrateIfNeeded();
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _updateCountdown();
      if (mounted) _syncQuizBtn(ref.read(userProvider));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncQuizBtn(ref.read(userProvider));
    });
  }

  void _syncQuizBtn(UserData user) {
    final isPro = user.isPro &&
        AuthService.currentUser != null &&
        !AuthService.isGuest;
    final lastPlayed = StorageService.getLastPlayedTimestamp();
    final playedMoreThan2hAgo = lastPlayed != null &&
        DateTime.now().difference(lastPlayed).inHours >= 2;
    final shouldAnimate = !user.hasPlayedToday || (isPro && playedMoreThan2hAgo);
    if (shouldAnimate && !_quizBtnCtrl.isAnimating) {
      _quizBtnCtrl.repeat();
    } else if (!shouldAnimate && _quizBtnCtrl.isAnimating) {
      _quizBtnCtrl.stop();
      _quizBtnCtrl.value = 0;
    }
  }

  void _loadState() {
    _briefingRead = DailyTracker.isBriefingReadToday();
    for (final cat in _categoryQuizzes) {
      _catCompletions[cat.name] =
          _parseCompletion(StorageService.getCategoryCompletion(cat.name));
    }
    _updateCountdown();
  }

  void _updateCountdown() {
    final last = StorageService.getLastPlayedTimestamp();
    if (last == null) {
      if (mounted) setState(() => _nextBriefLabel = '');
      return;
    }
    final user = ref.read(userProvider);
    final isPro = user.isPro &&
        AuthService.currentUser != null &&
        !AuthService.isGuest;
    final DateTime next;
    if (isPro) {
      // Pro users get fresh questions every 4h
      next = last.add(const Duration(hours: 4));
    } else {
      // Free users reset at midnight
      final now = DateTime.now();
      next = DateTime(now.year, now.month, now.day + 1);
    }
    final diff = next.difference(DateTime.now());
    if (!mounted) return;
    if (diff.isNegative) {
      setState(() => _nextBriefLabel = '');
    } else {
      final h = diff.inHours;
      final m = diff.inMinutes % 60;
      setState(() => _nextBriefLabel = h > 0 ? '${h}h ${m}m' : '${m}m');
    }
  }

  void _initAnimations() {
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);

    _arrowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat();

    // Header: 0–500ms → 0.0–0.357
    _headerFade = CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.0, 0.357, curve: Curves.easeOut));
    _headerSlide =
        Tween<Offset>(begin: const Offset(0, -0.03), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _entryCtrl,
                curve: const Interval(0.0, 0.357, curve: Curves.easeOut)));

    // Briefing card: 200–900ms → 0.143–0.643
    _briefingFade = CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.143, 0.643, curve: Curves.easeOut));
    _briefingScale = Tween<double>(begin: 0.95, end: 1.0).animate(
        CurvedAnimation(
            parent: _entryCtrl,
            curve: const Interval(0.143, 0.643, curve: Curves.easeOut)));

    // Progress ring + quiz: 300–1000ms → 0.214–0.714
    _progressFade = CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.214, 0.714, curve: Curves.easeOut));

    // Games: 500–1100ms → 0.357–0.786
    _gamesFade = CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.357, 0.786, curve: Curves.easeOut));
    _gamesSlide = Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _entryCtrl,
            curve: const Interval(0.357, 0.786, curve: Curves.easeOut)));

    _pulseScale = Tween<double>(begin: 1.0, end: 1.2)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _quizBtnCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _entryCtrl.dispose();
    _pulseCtrl.dispose();
    _arrowCtrl.dispose();
    _quizBtnCtrl.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(_loadState);
    ref.read(userProvider.notifier).reload();
    ref.read(xpProvider.notifier).reload();
    unawaited(ref.read(newsProvider.notifier).refresh());
    unawaited(ref.read(newsPipelineProvider.notifier).refresh());
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final xp = ref.watch(xpProvider);
    final news = ref.watch(newsProvider);

    ref.listen<UserData>(userProvider, (_, newUser) {
      setState(_loadState);
      _syncQuizBtn(newUser);
    });

    final latestResult =
        user.recentResults.isEmpty ? null : user.recentResults.first;
    final heroArticle = news.articles.isNotEmpty ? news.articles.first : null;
    final completedToday = [
      _briefingRead,
      user.hasPlayedToday,
      ..._catCompletions.values.map((v) => v != null),
    ].where((done) => done).length;

    return Scaffold(
      backgroundColor:
          context.isDark ? const Color(0xFF101010) : const Color(0xFFFFF7EF),
      body: RefreshIndicator(
        color: _orange,
        onRefresh: _refresh,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // A — Header
                FadeTransition(
                  opacity: _headerFade,
                  child: SlideTransition(
                      position: _headerSlide,
                      child: _buildHeader(context, user, xp)),
                ),
                const SizedBox(height: 20),

                // B — Today's Briefing Hero
                FadeTransition(
                  opacity: _briefingFade,
                  child: ScaleTransition(
                      scale: _briefingScale,
                      child: _buildBriefingCard(
                        context,
                        user,
                        xp,
                        heroArticle,
                        completedToday,
                      )),
                ),
                const SizedBox(height: 18),

                // C — Quiz Result / Mission
                FadeTransition(
                  opacity: _progressFade,
                  child: _buildQuickStatsRow(
                      context, user, latestResult, completedToday, xp),
                ),
                const SizedBox(height: 22),

                // D — Category Quizzes
                _buildCategorySection(context),
                const SizedBox(height: 24),

                // E — Games
                FadeTransition(
                  opacity: _gamesFade,
                  child: SlideTransition(
                      position: _gamesSlide,
                      child: _buildGamesSection(context, user)),
                ),
                if (heroArticle != null) ...[
                  const SizedBox(height: 24),
                  _buildHeadlineCard(context, heroArticle),
                ],
                const SizedBox(height: 24),
                const Center(child: BriefedBannerAd()),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // A — HEADER
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, UserData user, XpState xp) {
    final h = DateTime.now().hour;
    final greeting =
        h >= 5 && h < 12 ? 'Morning' : h >= 12 && h < 18 ? 'Afternoon' : 'Evening';

    final firebaseUser = AuthService.currentUser;
    final firstName = firebaseUser?.displayName?.split(' ').first ??
        (user.name.trim().isEmpty ? 'there' : user.name.split(' ').first);
    final photoUrl = firebaseUser?.photoURL ?? '';
    final initial = firstName.isEmpty ? 'B' : firstName[0].toUpperCase();
    final level = (user.knowledgeScore / 200).floor() + 1;
    final isDark = context.isDark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Row: greeting + name (left) | avatar with level (right) ──────
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$greeting,',
                    style: TextStyle(
                      fontFamily: AppFonts.display,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: context.textColor,
                      height: 1.1,
                    ),
                  ),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontFamily: AppFonts.display,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                        height: 1.05,
                      ),
                      children: [
                        TextSpan(
                          text: firstName,
                          style: const TextStyle(color: _orange),
                        ),
                        TextSpan(
                          text: '.',
                          style: TextStyle(color: context.textColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _buildAvatarWithLevel(context, photoUrl, initial, level, isDark),
          ],
        ),
        const SizedBox(height: 10),
        // ── Row: streak pill | next-drops pill ───────────────────────────
        Row(
          children: [
            // Streak pill
            Container(
              padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
              decoration: BoxDecoration(
                color: _orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                AnimatedBuilder(
                  animation: _pulseScale,
                  builder: (_, __) => Transform.scale(
                    scale: _pulseScale.value,
                    child: const Icon(
                      Icons.local_fire_department_rounded,
                      color: _orange,
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  'Day ${user.streak} streak',
                  style: const TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _deepOrange,
                  ),
                ),
              ]),
            ),
            // Next drops in pill — only while the 12h window is active
            if (_nextBriefLabel.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF27170E) : Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF3A2516)
                        : const Color(0xFFE8D4C0),
                  ),
                  boxShadow: isDark
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(
                    Icons.timer_outlined,
                    size: 13,
                    color: Color(0xFF9C8377),
                  ),
                  const SizedBox(width: 5),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? const Color(0xFF9C8377)
                            : const Color(0xFF7A5C48),
                      ),
                      children: [
                        const TextSpan(text: 'Next drops in '),
                        TextSpan(
                          text: _nextBriefLabel,
                          style: const TextStyle(
                            color: _orange,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildAvatarWithLevel(BuildContext context, String photoUrl,
      String initial, int level, bool isDark) {
    final avatar = photoUrl.isNotEmpty
        ? Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0xFFB83400),
                  blurRadius: 0,
                  offset: Offset(0, 4),
                ),
                BoxShadow(
                  color: Color(0x33FF5A1F),
                  blurRadius: 10,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.network(
                photoUrl,
                width: 46,
                height: 46,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _initialsCircle(initial, isDark),
              ),
            ),
          )
        : _initialsCircle(initial, isDark);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          right: -4,
          bottom: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFFFB800),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? const Color(0xFF101010) : const Color(0xFFFFF7EF),
                width: 1.5,
              ),
            ),
            child: Text(
              'L$level',
              style: const TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _initialsCircle(String initial, bool isDark) {
    return Container(
      width: 46,
      height: 46,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [_orange, _deepOrange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          // 3D chunky bottom shadow — same language as the Duolingo-style buttons
          BoxShadow(
            color: Color(0xFFB83400),
            blurRadius: 0,
            offset: Offset(0, 4),
          ),
          // soft ambient glow
          BoxShadow(
            color: Color(0x33FF5A1F),
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            fontFamily: AppFonts.display,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // C — BRIEFING CARD
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildBriefingCard(
    BuildContext context,
    UserData user,
    XpState xp,
    NewsArticle? article,
    int completedToday,
  ) {
    final isDark = context.isDark;
    final read = _briefingRead;
    final isPro = user.isPro &&
        AuthService.currentUser != null &&
        !AuthService.isGuest;
    final lastPlayed = StorageService.getLastPlayedTimestamp();
    final playedMoreThan2hAgo = lastPlayed != null &&
        DateTime.now().difference(lastPlayed).inHours >= 2;

    return GestureDetector(
      onTap: read ? null : () => _onStartBriefing(context, xp),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_orange, _deepOrange],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            const BoxShadow(
              color: Color(0xFF7A2A00),
              blurRadius: 0,
              offset: Offset(0, 6),
            ),
            BoxShadow(
              color: _orange.withValues(alpha: isDark ? 0.22 : 0.42),
              blurRadius: 42,
              offset: const Offset(0, 22),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              right: -44,
              top: -52,
              child: Container(
                width: 210,
                height: 210,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.14),
                ),
              ),
            ),
            Positioned(
              right: 12,
              top: 14,
              child: Icon(Icons.newspaper_rounded,
                  size: 66, color: Colors.white.withValues(alpha: 0.18)),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const _HeroChip(
                    icon: Icons.bolt_rounded,
                    label: 'DAILY BRIEF',
                  ),
                  const SizedBox(width: 6),
                  const _HeroChip(
                    icon: Icons.quiz_rounded,
                    label: '5 questions',
                  ),
                  const Spacer(),
                  if (read)
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.20),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded,
                          color: Colors.white, size: 18),
                    ),
                ]),
                const SizedBox(height: 18),
                const Text("Today's\nheadlines",
                    style: TextStyle(
                        fontFamily: AppFonts.display,
                        fontSize: 31,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.04,
                        letterSpacing: -0.8)),
                const SizedBox(height: 8),
                Text(
                  article?.title ??
                      'Five fresh questions across politics, tech and sport.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 13,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.86)),
                ),
                const SizedBox(height: 18),
                Row(
                  children: List.generate(_categoryQuizzes.length + 2, (i) {
                    final total = _categoryQuizzes.length + 2;
                    final done = i < completedToday;
                    return Expanded(
                      child: Container(
                        height: 6,
                        margin: EdgeInsets.only(right: i == total - 1 ? 0 : 6),
                        decoration: BoxDecoration(
                          color: done
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                Row(children: [
                  Text('$completedToday/${_categoryQuizzes.length + 2} completed',
                      style: TextStyle(
                          fontFamily: AppFonts.body,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.white.withValues(alpha: 0.88))),
                  const Spacer(),
                  const Text('+250 XP',
                      style: TextStyle(
                          fontFamily: AppFonts.display,
                          height: 1.02,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white)),
                ]),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.17),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () => _onStartBriefing(context, xp),
                          icon: const Icon(Icons.article_rounded, size: 17),
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(read ? 'Read Again' : 'Read First',
                                style: const TextStyle(
                                    fontFamily: AppFonts.body,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AnimatedBuilder(
                        animation: _quizBtnCtrl,
                        builder: (_, child) {
                          final t = _quizBtnCtrl.value;
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white
                                      .withValues(alpha: 0.55 * (1 - t)),
                                  blurRadius: 18 * t,
                                  spreadRadius: 10 * t,
                                ),
                              ],
                            ),
                            child: child,
                          );
                        },
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              disabledBackgroundColor:
                                  Colors.white.withValues(alpha: 0.62),
                              foregroundColor: _deepOrange,
                              disabledForegroundColor:
                                  _deepOrange.withValues(alpha: 0.55),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            onPressed: (user.hasPlayedToday && !isPro)
                                ? null
                                : () => _onPlayMainQuiz(context, xp),
                            icon: const Icon(Icons.play_arrow_rounded, size: 18),
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                  (user.hasPlayedToday && !isPro)
                                      ? 'Quiz Complete'
                                      : (user.hasPlayedToday && isPro)
                                          ? (playedMoreThan2hAgo
                                              ? 'Play Quiz'
                                              : 'Replay Quiz')
                                          : 'Play Quiz',
                                  style: const TextStyle(
                                      fontFamily: AppFonts.body,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatsRow(BuildContext context, UserData user,
      QuizResult? latestResult, int completedToday, XpState xp) {
    final played = user.hasPlayedToday && latestResult != null;
    final score = latestResult?.score ?? 0;
    final total = latestResult?.totalQuestions ?? 5;
    final xpEarned = latestResult?.pointsEarned ?? 75;

    void tap(int i) {
      setState(() => _selectedStatIndex = i);
      _showStatInsights(context, i, user, latestResult, completedToday, xp);
    }

    return Row(children: [
      Expanded(
        child: GestureDetector(
          onTap: () => tap(0),
          child: _HomeStatTile(
            label: 'Today',
            value: played ? '$score/$total' : '$completedToday/${_categoryQuizzes.length + 2}',
            sub: played ? 'correct' : 'completed',
            selected: _selectedStatIndex == 0,
          ),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: GestureDetector(
          onTap: () => tap(1),
          child: _HomeStatTile(
            label: 'Streak',
            value: '${user.streak}d',
            sub: 'keep going',
            icon: Icons.local_fire_department_rounded,
            selected: _selectedStatIndex == 1,
          ),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: GestureDetector(
          onTap: () => tap(2),
          child: _HomeStatTile(
            label: 'This quiz',
            value: played ? '+$xpEarned' : '+250',
            sub: 'XP',
            icon: Icons.star_rounded,
            selected: _selectedStatIndex == 2,
          ),
        ),
      ),
    ]);
  }

  void _showStatInsights(BuildContext context, int index, UserData user,
      QuizResult? latestResult, int completedToday, XpState xp) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          decoration: BoxDecoration(
            color: context.isDark ? const Color(0xFF181818) : Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 32,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: index == 0
              ? _buildTodayInsights(context, user, latestResult, completedToday)
              : index == 1
                  ? _buildStreakInsights(context, user)
                  : _buildXpInsights(context, user, latestResult, xp),
        ),
      ),
    );
  }

  Widget _buildTodayInsights(BuildContext context, UserData user,
      QuizResult? latestResult, int completedToday) {
    final played = user.hasPlayedToday && latestResult != null;
    final tasks = [
      ('Read Briefing', _briefingRead, Icons.article_rounded),
      ('Main Quiz', user.hasPlayedToday, Icons.quiz_rounded),
      ('Politics Quiz', _catCompletions['politics'] != null,
          Icons.account_balance_rounded),
      ('Sports Quiz', _catCompletions['sports'] != null,
          Icons.sports_basketball_rounded),
      ('Technology Quiz', _catCompletions['technology'] != null,
          Icons.memory_rounded),
      ('Business Quiz', _catCompletions['business'] != null,
          Icons.trending_up_rounded),
      ('Health & Lifestyle Quiz', _catCompletions['health'] != null,
          Icons.health_and_safety_rounded),
      ('Entertainment Quiz', _catCompletions['entertainment'] != null,
          Icons.theaters_rounded),
    ];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: _orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.today_rounded, color: _orange, size: 24),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Today's Progress",
                  style: TextStyle(
                      fontFamily: AppFonts.display,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: context.textColor,
                      height: 1.02,
                      letterSpacing: -0.4)),
              Text('$completedToday of ${_categoryQuizzes.length + 2} tasks done',
                  style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 13,
                      color: context.hintColor)),
            ]),
          ]),
          const SizedBox(height: 20),
          ...tasks.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: t.$2
                          ? _orange.withValues(alpha: 0.12)
                          : context.isDark
                              ? const Color(0xFF242424)
                              : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(t.$2 ? Icons.check_rounded : t.$3,
                        color: t.$2 ? _orange : context.hintColor, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text(t.$1,
                          style: TextStyle(
                              fontFamily: AppFonts.body,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: t.$2
                                  ? context.textColor
                                  : context.subColor))),
                  if (t.$2)
                    const Text('✓',
                        style: TextStyle(
                            fontFamily: AppFonts.body,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: _orange)),
                ]),
              )),
          if (played) ...[
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _orange.withValues(alpha: 0.18)),
              ),
              child: Row(children: [
                const Icon(Icons.bolt_rounded, color: _orange, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                      '${latestResult.score}/${latestResult.totalQuestions} correct · +${latestResult.pointsEarned} XP',
                      style: const TextStyle(
                          fontFamily: AppFonts.body,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _orange)),
                ),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStreakInsights(BuildContext context, UserData user) {
    final streak = user.streak;
    final longest = user.longestStreak;

    final motivation = streak == 0
        ? 'Start today and build your streak!'
        : streak < 3
            ? 'Great start — keep going tomorrow.'
            : streak < 7
                ? "On a roll! 7-day badge within reach."
                : streak < 14
                    ? '7-day streak! The 14-day badge is next.'
                    : streak < 30
                        ? 'Incredible consistency! Keep pushing.'
                        : 'Legendary — you\'re in the top tier.';

    final milestones = [3, 7, 14, 30, 60, 100];
    final next =
        milestones.firstWhere((m) => m > streak, orElse: () => streak + 10);
    final progress = (streak / next).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: _orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.local_fire_department_rounded,
                  color: _orange, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Your Streak',
                    style: TextStyle(
                        fontFamily: AppFonts.display,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: context.textColor,
                        height: 1.02,
                        letterSpacing: -0.4)),
                Text(motivation,
                    style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 12,
                        color: context.hintColor)),
              ]),
            ),
          ]),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
                child: _insightStat(context, '$streak', 'Current',
                    streak > 0 ? _orange : context.hintColor)),
            Container(width: 1, height: 52, color: context.borderColor),
            Expanded(
                child: _insightStat(
                    context, '$longest', 'Longest', context.textColor)),
          ]),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Next milestone',
                style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: context.subColor)),
            Text('$next days',
                style: const TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _orange)),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => LinearProgressIndicator(
                value: v,
                minHeight: 10,
                backgroundColor: context.isDark
                    ? const Color(0xFF242424)
                    : const Color(0xFFF0F0F0),
                valueColor: const AlwaysStoppedAnimation(_orange),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('$streak days',
                style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 10,
                    color: context.hintColor)),
            Text('$next days',
                style: const TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _orange)),
          ]),
        ],
      ),
    );
  }

  Widget _buildXpInsights(BuildContext context, UserData user,
      QuizResult? latestResult, XpState xp) {
    final played = user.hasPlayedToday && latestResult != null;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: _orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.star_rounded, color: _orange, size: 24),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('XP & Level',
                  style: TextStyle(
                      fontFamily: AppFonts.display,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: context.textColor,
                      height: 1.02,
                      letterSpacing: -0.4)),
              Text('Level ${xp.level}: ${xp.levelTitle}',
                  style: const TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _orange)),
            ]),
          ]),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${xp.totalXp} XP',
                style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: context.subColor)),
            Text('${xp.xpForNextLevel} XP to next level',
                style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 12,
                    color: context.hintColor)),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: xp.levelProgress),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => LinearProgressIndicator(
                value: v,
                minHeight: 12,
                backgroundColor: context.isDark
                    ? const Color(0xFF242424)
                    : const Color(0xFFF0F0F0),
                valueColor: const AlwaysStoppedAnimation(_orange),
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (played) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _orange.withValues(alpha: 0.18)),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const Text('Last Quiz Breakdown',
                    style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: _orange,
                        letterSpacing: 0.5)),
                const SizedBox(height: 10),
                _xpRow(context, '${latestResult.score} correct answers',
                    '+${latestResult.score * 20} XP'),
                if (latestResult.score == latestResult.totalQuestions)
                  _xpRow(context, 'Perfect score bonus', '+50 XP'),
                _xpRow(context, 'Total earned',
                    '+${latestResult.pointsEarned} XP',
                    bold: true),
              ]),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.isDark
                    ? const Color(0xFF242424)
                    : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text("Play today's quiz to earn XP and level up!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.subColor)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _insightStat(
      BuildContext context, String value, String label, Color color) {
    return Column(children: [
      Text(value,
          style: TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 38,
              fontWeight: FontWeight.w900,
              color: color,
              height: 1.0,
              letterSpacing: -1)),
      const SizedBox(height: 4),
      Text(label,
          style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 12,
              color: context.hintColor,
              fontWeight: FontWeight.w600),
          textAlign: TextAlign.center),
    ]);
  }

  Widget _xpRow(BuildContext context, String label, String value,
      {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Expanded(
            child: Text(label,
                style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 12,
                    color: context.subColor,
                    fontWeight:
                        bold ? FontWeight.w800 : FontWeight.w500))),
        Text(value,
            style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: bold ? _orange : context.textColor)),
      ]),
    );
  }

  Future<void> _onStartBriefing(BuildContext context, XpState xp) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const BriefingReadScreen()),
    );
    if (!mounted) return;
    if (!_briefingRead) {
      await DailyTracker.markBriefingRead();
      await XpService.addXp(50);
      ref.read(xpProvider.notifier).reload();
      setState(_loadState);
    }
  }

  void _startMainQuiz() {
    Navigator.of(context)
        .pushNamed('/quiz/intro', arguments: {'isDailyMix': true});
  }

  Future<void> _onPlayMainQuiz(BuildContext context, XpState xp) async {
    // Always allow the quiz — show a gentle suggestion to read first if they
    // haven't yet, but don't block. User can dismiss or read first.
    if (_briefingRead) {
      _startMainQuiz();
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: context.isDark ? const Color(0xFF181818) : Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.20),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.article_rounded, color: _orange),
              ),
              const SizedBox(height: 12),
              Text('Read before the quiz?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: AppFonts.display,
                      height: 1.02,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: context.textColor)),
              const SizedBox(height: 6),
              Text(
                'The main quiz is based on today’s briefing. Reading first gives you the best shot.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 13,
                    height: 1.35,
                    color: context.subColor),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    Navigator.of(sheetContext).pop();
                    await _onStartBriefing(context, xp);
                  },
                  icon: const Icon(Icons.article_rounded, size: 18),
                  label: const Text('Read Briefing First',
                      style: TextStyle(
                          fontFamily: AppFonts.body,
                          fontSize: 14,
                          fontWeight: FontWeight.w900)),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: _orange,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    _startMainQuiz();
                  },
                  child: const Text('Start Quiz Anyway',
                      style: TextStyle(
                          fontFamily: AppFonts.body,
                          fontSize: 13,
                          fontWeight: FontWeight.w900)),
                ),
              ),
            ]),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // E — CATEGORY QUIZZES
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildCategorySection(BuildContext context) {
    const cats = _categoryQuizzes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text('Category Quizzes',
              style: TextStyle(
                  fontFamily: AppFonts.display,
                  height: 1.02,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: context.textColor,
                  letterSpacing: -0.4)),
          const Spacer(),
          const Text('View all',
              style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _orange)),
        ]),
        const SizedBox(height: 12),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: cats.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (ctx, i) {
              final cat = cats[i];
              final completion = _catCompletions[cat.name];
              final color = _categoryColours[cat.name] ?? _orange;

              final start = (0.25 + i * 0.06).clamp(0.0, 0.9);
              final end = (start + 0.40).clamp(0.0, 1.0);
              final anim = CurvedAnimation(
                parent: _entryCtrl,
                curve: Interval(start, end, curve: Curves.easeOut),
              );

              return AnimatedBuilder(
                animation: anim,
                builder: (_, child) => Opacity(
                  opacity: anim.value,
                  child: Transform.translate(
                    offset: Offset(60 * (1 - anim.value), 0),
                    child: child,
                  ),
                ),
                child: _CategoryQuizCard(
                  category: cat,
                  color: color,
                  completion: completion,
                  onTap: completion != null
                      ? null
                      : () => Navigator.of(ctx).pushNamed(
                            '/quiz/intro',
                            arguments: {'category': cat},
                          ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // F — GAMES
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildGamesSection(BuildContext context, UserData user) {
    final isDark = context.isDark;
    final unlocked = user.hasPlayedToday;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text('Play Next',
              style: TextStyle(
                  fontFamily: AppFonts.display,
                  height: 1.02,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: context.textColor,
                  letterSpacing: -0.4)),
          const Spacer(),
          GestureDetector(
            onTap: () => ref.read(selectedTabProvider.notifier).state = 1,
            child: const Text('Explore all games →',
                style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _orange)),
          ),
        ]),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (ctx, constraints) {
            return Column(
              children: [
                _GameCard(
                  width: constraints.maxWidth,
                  title: 'Real or Fake?',
                  subtitle: 'Spot the fake headline',
                  bgGradient: isDark
                      ? [const Color(0xFF5A210E), const Color(0xFF1A0D08)]
                      : [const Color(0xFFFFB17D), const Color(0xFFFF5A1F)],
                  unlocked: unlocked,
                  arrowCtrl: _arrowCtrl,
                  onTap: () {
                    if (!unlocked) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Complete today\'s quiz first',
                              style: TextStyle(
                                  fontFamily: AppFonts.body, fontSize: 13)),
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 2),
                        ),
                      );
                      return;
                    }
                    ref.read(selectedTabProvider.notifier).state = 1;
                  },
                ),
                const SizedBox(height: 12),
                _GameCard(
                  width: constraints.maxWidth,
                  title: 'Oldest to Latest',
                  subtitle: 'Sort events in order',
                  bgGradient: isDark
                      ? [const Color(0xFF64250E), const Color(0xFF20100A)]
                      : [const Color(0xFFFFC49D), const Color(0xFFE85D04)],
                  unlocked: unlocked,
                  arrowCtrl: _arrowCtrl,
                  onTap: () {
                    if (!unlocked) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Complete today\'s quiz first',
                              style: TextStyle(
                                  fontFamily: AppFonts.body, fontSize: 13)),
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 2),
                        ),
                      );
                      return;
                    }
                    ref.read(selectedTabProvider.notifier).state = 1;
                  },
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildHeadlineCard(BuildContext context, NewsArticle article) {
    final catKey = article.category.toLowerCase();
    final tint = _categoryColours[catKey] ?? _orange;
    final hasImage = article.imageUrl != null && article.imageUrl!.isNotEmpty;
    final surface = context.isDark ? const Color(0xFF27170E) : Colors.white;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('Headline of the day',
            style: TextStyle(
                fontFamily: AppFonts.display,
                height: 1.02,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: context.textColor,
                letterSpacing: -0.4)),
        const Spacer(),
        const Text('Quiz it',
            style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: _orange)),
      ]),
      const SizedBox(height: 12),
      Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withValues(alpha: context.isDark ? 0.18 : 0.05),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            height: 130,
            width: double.infinity,
            child: Stack(fit: StackFit.expand, children: [
              if (hasImage)
                Image.network(
                  article.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _HeadlineFallback(tint: tint),
                )
              else
                _HeadlineFallback(tint: tint),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.42),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Positioned(
                left: 14,
                bottom: 14,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.90),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(_categoryLabel(article.category),
                      style: TextStyle(
                          fontFamily: AppFonts.body,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: tint)),
                ),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(article.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: context.textColor,
                      height: 1.25,
                      letterSpacing: -0.2)),
              const SizedBox(height: 8),
              Row(children: [
                Text(article.sourceName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: context.hintColor)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color:
                        _orange.withValues(alpha: context.isDark ? 0.16 : 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.bolt_rounded, size: 12, color: _orange),
                    SizedBox(width: 4),
                    Text('Quiz me later',
                        style: TextStyle(
                            fontFamily: AppFonts.body,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: _orange)),
                  ]),
                ),
              ]),
            ]),
          ),
        ]),
      ),
    ]);
  }

  String _categoryLabel(String raw) {
    if (raw.isEmpty) return 'News';
    if (raw.toLowerCase() == 'tech') return 'Technology';
    return '${raw[0].toUpperCase()}${raw.substring(1)}';
  }
}

class _HeadlineFallback extends StatelessWidget {
  final Color tint;

  const _HeadlineFallback({required this.tint});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFFFB940), tint],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.only(right: 24),
          child: Icon(Icons.article_rounded,
              size: 78, color: Colors.white.withValues(alpha: 0.24)),
        ),
      ),
    );
  }
}

class _HomeStatTile extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final bool selected;
  final IconData? icon;

  const _HomeStatTile({
    required this.label,
    required this.value,
    required this.sub,
    this.selected = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? _orange
        : context.isDark
            ? const Color(0xFF27170E)
            : Colors.white;
    final fg = selected ? Colors.white : context.textColor;
    final muted =
        selected ? Colors.white.withValues(alpha: 0.78) : context.hintColor;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          if (selected)
            const BoxShadow(
              color: _deepOrange,
              blurRadius: 0,
              offset: Offset(0, 4),
            )
          else
            BoxShadow(
              color:
                  Colors.black.withValues(alpha: context.isDark ? 0.16 : 0.04),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: selected ? Colors.white : _orange),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Text(label.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: muted,
                    letterSpacing: 0.7)),
          ),
        ]),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value,
              style: TextStyle(
                  fontFamily: AppFonts.display,
                  height: 1.02,
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                  color: fg,
                  letterSpacing: -0.5)),
        ),
        const SizedBox(height: 2),
        Text(sub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: muted)),
      ]),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: Colors.white),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Colors.white)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRIVATE: Category Quiz Card
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryQuizCard extends StatefulWidget {
  final NewsCategory category;
  final Color color;
  final Map<String, int>? completion;
  final VoidCallback? onTap;

  const _CategoryQuizCard({
    required this.category,
    required this.color,
    required this.completion,
    required this.onTap,
  });

  @override
  State<_CategoryQuizCard> createState() => _CategoryQuizCardState();
}

class _CategoryQuizCardState extends State<_CategoryQuizCard>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 850))
      ..repeat(reverse: true);
    _pulseScale = Tween<double>(begin: 1.0, end: 1.22)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.color;
    final done = widget.completion != null;
    final surface = context.isDark ? const Color(0xFF181818) : Colors.white;

    return GestureDetector(
      onTapDown:
          widget.onTap != null ? (_) => setState(() => _pressed = true) : null,
      onTapUp: widget.onTap != null
          ? (_) {
              setState(() => _pressed = false);
              widget.onTap!();
            }
          : null,
      onTapCancel:
          widget.onTap != null ? () => setState(() => _pressed = false) : null,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: _orange.withValues(alpha: context.isDark ? 0.04 : 0.11),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: done ? _buildDone(context, c) : _buildPlay(context, c),
        ),
      ),
    );
  }

  Widget _buildPlay(BuildContext context, Color c) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_categoryIcon(widget.category), color: c, size: 21),
          ),
          const Spacer(),
          AnimatedBuilder(
            animation: _pulseScale,
            builder: (_, __) => Transform.scale(
              scale: _pulseScale.value,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: c,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: c.withValues(alpha: 0.40),
                      blurRadius: 0,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.play_arrow_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 18),
        Text(widget.category.label,
            style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: context.textColor)),
        const SizedBox(height: 4),
        Text('5 questions',
            style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 11,
                color: context.subColor)),
      ]),
    );
  }

  Widget _buildDone(BuildContext context, Color c) {
    final comp = widget.completion!;
    final correct = comp['correct'] ?? 0;
    final total = comp['total'] ?? 5;
    final estimatedXp = correct * 15 + (correct == total ? 30 : 0);

    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    final diff = midnight.difference(now);
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    final resetLabel = h > 0 ? 'Resets in ${h}h ${m}m' : 'Resets in ${m}m';

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: c.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(Icons.check_rounded, color: c, size: 20)),
          const Spacer(),
          Text('$correct/$total',
              style: const TextStyle(
                  fontFamily: AppFonts.display,
                  height: 1.02,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: _orange)),
        ]),
        const Spacer(),
        Text(widget.category.label,
            style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: context.textColor)),
        const SizedBox(height: 2),
        Text('+$estimatedXp XP earned',
            style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 11,
                color: context.subColor)),
        const SizedBox(height: 2),
        Text(resetLabel,
            style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: c.withValues(alpha: 0.70))),
      ]),
    );
  }

  IconData _categoryIcon(NewsCategory category) {
    switch (category) {
      case NewsCategory.politics:
        return Icons.account_balance_rounded;
      case NewsCategory.sports:
        return Icons.sports_basketball_rounded;
      case NewsCategory.technology:
        return Icons.memory_rounded;
      case NewsCategory.business:
        return Icons.trending_up_rounded;
      case NewsCategory.world:
        return Icons.public_rounded;
      case NewsCategory.health:
        return Icons.health_and_safety_rounded;
      case NewsCategory.entertainment:
        return Icons.theaters_rounded;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRIVATE: Game Card
// ─────────────────────────────────────────────────────────────────────────────

class _GameCard extends StatelessWidget {
  final double width;
  final String title;
  final String subtitle;
  final List<Color> bgGradient;
  final bool unlocked;
  final AnimationController arrowCtrl;
  final VoidCallback onTap;

  const _GameCard({
    required this.width,
    required this.title,
    required this.subtitle,
    required this.bgGradient,
    required this.unlocked,
    required this.arrowCtrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tint = bgGradient.first;
    final surface = context.isDark ? const Color(0xFF27170E) : Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: 80,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withValues(alpha: context.isDark ? 0.16 : 0.04),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(_gameIcon(title), size: 26, color: tint),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontFamily: AppFonts.body,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: context.textColor,
                            letterSpacing: -0.2)),
                    const SizedBox(height: 2),
                    Text(
                        unlocked ? subtitle : 'Complete today\'s quiz to unlock',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontFamily: AppFonts.body,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: context.hintColor)),
                  ]),
            ),
            const SizedBox(width: 10),
            AnimatedBuilder(
              animation: arrowCtrl,
              builder: (_, __) {
                final dx = unlocked
                    ? 4.0 * math.sin(arrowCtrl.value * math.pi)
                    : 0.0;
                return Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: unlocked ? tint : tint.withValues(alpha: 0.30),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: unlocked
                        ? [
                            BoxShadow(
                              color: tint.withValues(alpha: 0.35),
                              blurRadius: 0,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : [],
                  ),
                  child: Center(
                    child: Transform.translate(
                      offset: Offset(dx, 0),
                      child: Icon(
                        unlocked
                            ? Icons.play_arrow_rounded
                            : Icons.lock_rounded,
                        color: Colors.white,
                        size: unlocked ? 20 : 16,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  IconData _gameIcon(String title) {
    if (title.contains('Real')) return Icons.fact_check_rounded;
    if (title.contains('Oldest')) return Icons.timeline_rounded;
    return Icons.sports_esports_rounded;
  }
}
