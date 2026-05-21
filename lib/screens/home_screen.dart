import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../widgets/ad_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../features/news/models/news_category.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/ad_service.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

// ─── File-level helpers ───────────────────────────────────────────────────────

String _fmt(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}K' : '$n';

Color _catColor(NewsCategory cat) {
  switch (cat) {
    case NewsCategory.world:
      return const Color(0xFF2196F3);
    case NewsCategory.politics:
      return const Color(0xFF9C27B0);
    case NewsCategory.sports:
      return const Color(0xFF4CAF50);
    case NewsCategory.technology:
      return const Color(0xFF00BCD4);
    case NewsCategory.business:
      return const Color(0xFFFF9800);
    case NewsCategory.health:
      return const Color(0xFF26A69A);
    case NewsCategory.entertainment:
      return const Color(0xFFE91E63);
  }
}

IconData _catIcon(NewsCategory cat) {
  switch (cat) {
    case NewsCategory.world:
      return Icons.language_rounded;
    case NewsCategory.politics:
      return Icons.account_balance_rounded;
    case NewsCategory.sports:
      return Icons.sports_rounded;
    case NewsCategory.technology:
      return Icons.memory_rounded;
    case NewsCategory.business:
      return Icons.trending_up_rounded;
    case NewsCategory.health:
      return Icons.health_and_safety_rounded;
    case NewsCategory.entertainment:
      return Icons.theaters_rounded;
  }
}

String _catEmoji(NewsCategory cat) {
  switch (cat) {
    case NewsCategory.world:
      return '🌍';
    case NewsCategory.politics:
      return '🏛️';
    case NewsCategory.sports:
      return '⚽';
    case NewsCategory.technology:
      return '💻';
    case NewsCategory.business:
      return '📈';
    case NewsCategory.health:
      return '🏥';
    case NewsCategory.entertainment:
      return '🎬';
  }
}

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

Color _streakColor(int streak) {
  if (streak == 0) return const Color(0xFF888888);
  if (streak <= 2) return const Color(0xFFFF9800);
  if (streak <= 6) return const Color(0xFFFF5722);
  if (streak <= 13) return const Color(0xFFF44336);
  return const Color(0xFFFFD700);
}

// ─── Legacy icon helper (used by QuizHeroCard for old category ids) ───────────

IconData _legacyCatIcon(String id) {
  switch (id) {
    case 'world':
      return Icons.language_rounded;
    case 'tech':
      return Icons.memory_rounded;
    case 'business':
      return Icons.trending_up_rounded;
    case 'sports':
      return Icons.sports_soccer_rounded;
    case 'entertainment':
      return Icons.star_rounded;
    default:
      return Icons.article_rounded;
  }
}

// ─── Arc progress painter ─────────────────────────────────────────────────────

class _ArcPainter extends CustomPainter {
  final double progress; // 0.0–1.0 actual completion ratio
  final double animValue; // 0.0–1.0 draw animation progress
  final Color trackColor;
  final Color progressColor;

  const _ArcPainter({
    required this.progress,
    required this.animValue,
    required this.trackColor,
    required this.progressColor,
  });

  // 135° = lower-left; 270° sweep → ends at lower-right (90° gap at bottom)
  static const double _start = (3 * math.pi) / 4;
  static const double _sweep = (3 * math.pi) / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final r = math.min(size.width, size.height) / 2 - 5;
    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: r,
    );
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, _start, _sweep, false, stroke..color = trackColor);

    final drawn = _sweep * progress * animValue;
    if (drawn > 0.01) {
      canvas.drawArc(rect, _start, drawn, false, stroke..color = progressColor);
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.progress != progress ||
      old.animValue != animValue ||
      old.progressColor != progressColor ||
      old.trackColor != trackColor;
}

// ─────────────────────────────────────────────────────────────────────────────
// HOME SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  // ── Animation controllers ─────────────────────────────────────────────────
  late AnimationController _entryCtrl; // 1 200ms — all section entries
  late AnimationController _streakCtrl; // 500ms  — streak badge entry
  late AnimationController _pulseCtrl; // 1 200ms repeating — flame pulse
  late AnimationController _arrowCtrl; // 1 500ms repeating — game arrow

  // ── Entry animations (driven by _entryCtrl intervals) ────────────────────
  late Animation<double> _progressFade;
  late Animation<Offset> _progressSlide;
  late Animation<double> _heroFade;
  late Animation<Offset> _heroSlide;
  late Animation<double> _gamesFade;
  late Animation<Offset> _gamesSlide;
  late Animation<double> _arcAnim;

  // ── Streak badge entry ────────────────────────────────────────────────────
  late Animation<double> _streakSlideX;
  late Animation<double> _streakFade;

  // ── Flame pulse ───────────────────────────────────────────────────────────
  late Animation<double> _pulseScale;

  // ── State ─────────────────────────────────────────────────────────────────
  final GlobalKey _categorySectionKey = GlobalKey();
  final ScrollController _scrollCtrl = ScrollController();
  Map<String, Map<String, int>?> _catCompletions = {};
  Timer? _clockTimer;
  String _nextBriefLabel = '';

  void _updateNextBriefLabel() {
    final last = StorageService.getLastPlayedTimestamp();
    if (last == null) {
      setState(() => _nextBriefLabel = '');
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
    if (diff.isNegative) {
      final wasLive = _nextBriefLabel.isNotEmpty;
      setState(() => _nextBriefLabel = '');
      // Countdown just expired — reload user state so the play button re-enables
      if (wasLive) _refresh();
      return;
    }
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    setState(() => _nextBriefLabel = h > 0 ? '${h}h ${m}m' : '${m}m');
  }

  void _loadCatCompletions() {
    final updated = <String, Map<String, int>?>{};
    for (final cat in NewsCategory.values) {
      updated[cat.name] = _parseCompletion(
        StorageService.getCategoryCompletion(cat.name),
      );
    }
    _catCompletions = updated;
  }

  @override
  void initState() {
    super.initState();
    _loadCatCompletions();

    // Entry controller — 1 200ms drives all section entry animations
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));

    // Streak badge — 500ms, starts 200ms after load
    _streakCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));

    // Flame pulse — repeats indefinitely
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);

    // Game card arrow bounce
    _arrowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat();

    // Progress card: 100ms–700ms → interval 0.083–0.583
    _progressFade = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.083, 0.583, curve: Curves.easeOut),
    );
    _progressSlide = Tween<Offset>(
      begin: const Offset(0, 0.025),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.083, 0.583, curve: Curves.easeOut),
    ));

    // Hero card: 200ms–900ms → interval 0.167–0.75
    _heroFade = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.167, 0.75, curve: Curves.easeOut),
    );
    _heroSlide = Tween<Offset>(
      begin: const Offset(0, 0.033),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.167, 0.75, curve: Curves.easeOut),
    ));

    // Games: 400ms–1 000ms → interval 0.333–0.833
    _gamesFade = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.333, 0.833, curve: Curves.easeOut),
    );
    _gamesSlide = Tween<Offset>(
      begin: const Offset(0, 0.025),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.333, 0.833, curve: Curves.easeOut),
    ));

    // Arc draw: 0–1 000ms → interval 0.0–0.833
    _arcAnim = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.0, 0.833, curve: Curves.easeOut),
    );

    // Streak badge: slide 60→0, fade 0→1
    _streakSlideX = Tween<double>(begin: 60.0, end: 0.0).animate(
      CurvedAnimation(parent: _streakCtrl, curve: Curves.easeOut),
    );
    _streakFade = CurvedAnimation(parent: _streakCtrl, curve: Curves.easeOut);

    // Flame pulse: scale 1.0→1.15
    _pulseScale = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _entryCtrl.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _streakCtrl.forward();
    });

    _updateNextBriefLabel();
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) => _updateNextBriefLabel());
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _entryCtrl.dispose();
    _streakCtrl.dispose();
    _pulseCtrl.dispose();
    _arrowCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(_loadCatCompletions);
    ref.read(userProvider.notifier).reload();
  }

  void _scrollToCategories() {
    final ctx = _categorySectionKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        alignment: 0.0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);

    // Reload category completions whenever user state changes (after a quiz)
    ref.listen<UserData>(userProvider, (_, __) {
      setState(_loadCatCompletions);
    });

    final isDark = context.isDark;
    final isDailyDone = user.hasPlayedToday;
    final isPro = user.isPro &&
        AuthService.currentUser != null &&
        !AuthService.isGuest;
    final catDoneCount = _catCompletions.values.where((v) => v != null).length;
    final completedToday = (isDailyDone ? 1 : 0) + catDoneCount;

    final latestResult =
        user.recentResults.isEmpty ? null : user.recentResults.first;

    return Scaffold(
      backgroundColor: context.bgColor,
      body: RefreshIndicator(
        color: const Color(0xFFFF5722),
        onRefresh: _refresh,
        child: SafeArea(
          child: SingleChildScrollView(
            controller: _scrollCtrl,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // ── Section 1: Personal Header ───────────────────────────
                _buildHeader(context, user, isDark),
                const SizedBox(height: 24),

                // ── Section 2: Daily Progress Ring ───────────────────────
                FadeTransition(
                  opacity: _progressFade,
                  child: SlideTransition(
                    position: _progressSlide,
                    child: _buildProgressCard(
                        context, isDark, completedToday, isDailyDone),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Section 3: Today's Quiz Hero Card ────────────────────
                FadeTransition(
                  opacity: _heroFade,
                  child: SlideTransition(
                    position: _heroSlide,
                    child: QuizHeroCard(
                      user: user,
                      latestResult: latestResult,
                      onStartQuiz: () => Navigator.of(context).pushNamed(
                        '/quiz/intro',
                        arguments: {'isDailyMix': true},
                      ),
                      onPlayRealOrFake: _scrollToCategories,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Section 4: Category Quizzes ──────────────────────────
                _buildCategoryRow(context, isDark, isPro),
                const SizedBox(height: 24),

                // ── Section 5: Games ─────────────────────────────────────
                FadeTransition(
                  opacity: _gamesFade,
                  child: SlideTransition(
                    position: _gamesSlide,
                    child: _buildGamesSection(context, user, isDark),
                  ),
                ),
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

  // ── Section 1 ─────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, UserData user, bool isDark) {
    final h = DateTime.now().hour;
    final greeting = h >= 5 && h < 12
        ? 'Good morning'
        : h >= 12 && h < 18
            ? 'Good afternoon'
            : 'Good evening';
    final firstName =
        user.name.trim().isEmpty ? 'there' : user.name.split(' ').first;
    final initial =
        user.name.trim().isEmpty ? 'B' : user.name[0].toUpperCase();
    final level = (user.knowledgeScore / 200).floor() + 1;

    return AnimatedBuilder(
      animation: Listenable.merge([_streakSlideX, _streakFade]),
      builder: (_, __) => Opacity(
        opacity: _streakFade.value,
        child: Transform.translate(
          offset: Offset(_streakSlideX.value * 0.4, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Row: greeting+name (left) | avatar (right) ──────────────
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
                            fontFamily: AppFonts.body,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: context.textColor,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          '$firstName.',
                          style: TextStyle(
                            fontFamily: AppFonts.display,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.6,
                            height: 1.05,
                            color: context.textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _AvatarWithLevel(initial: initial, level: level, isDark: isDark),
                ],
              ),
              const SizedBox(height: 10),
              // ── Row: streak pill | next-drops pill ──────────────────────
              Row(
                children: [
                  // Streak pill
                  AnimatedBuilder(
                    animation: _pulseScale,
                    builder: (_, __) => Container(
                      padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Transform.scale(
                          scale: _pulseScale.value,
                          child: const Icon(
                            Icons.local_fire_department_rounded,
                            color: AppColors.accent,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Day ${user.streak} streak',
                          style: const TextStyle(
                            fontFamily: AppFonts.body,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.accentDark,
                          ),
                        ),
                      ]),
                    ),
                  ),
                  // Next drops in pill — only when countdown is live
                  if (_nextBriefLabel.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2A1A0E) : Colors.white,
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
                        Icon(
                          Icons.timer_outlined,
                          size: 13,
                          color: isDark
                              ? const Color(0xFF9C8377)
                              : const Color(0xFF9C8377),
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
                                  color: AppColors.accent,
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
          ),
        ),
      ),
    );
  }

  // ── Section 2 ─────────────────────────────────────────────────────────────

  Widget _buildProgressCard(
      BuildContext context, bool isDark, int completedToday, bool isDailyDone) {
    const accent = Color(0xFFFF5722);
    final trackColor =
        isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE0E0E0);
    final progress = (completedToday / (NewsCategory.values.length + 1).toDouble()).clamp(0.0, 1.0);

    return Container(
      height: 158,
      decoration: BoxDecoration(
        color:
            context.cardColor.withValues(alpha: context.isDark ? 0.86 : 0.96),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
            color:
                Colors.white.withValues(alpha: context.isDark ? 0.06 : 0.72)),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.10),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Row(children: [
        // Left: arc ring
        SizedBox(
          width: 110,
          height: 152,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: AnimatedBuilder(
              animation: _arcAnim,
              builder: (_, __) => CustomPaint(
                painter: _ArcPainter(
                  progress: progress,
                  animValue: _arcAnim.value,
                  trackColor: trackColor,
                  progressColor: accent,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$completedToday',
                        style: TextStyle(
                            fontFamily: AppFonts.display,
                            height: 1.02,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: context.textColor),
                      ),
                      Text(
                        '/ ${NewsCategory.values.length + 1}',
                        style: TextStyle(
                            fontFamily: AppFonts.body,
                            fontSize: 11,
                            color: context.subColor),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        // Right: quiz breakdown
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's Progress",
                  style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: context.textColor),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _ProgressRow(
                        emoji: '',
                        label: 'Daily Mix',
                        done: isDailyDone,
                        onTap: isDailyDone
                            ? null
                            : () => Navigator.of(context).pushNamed('/quiz'),
                      ),
                      ...NewsCategory.values.map((cat) {
                        final done = _catCompletions[cat.name] != null;
                        return _ProgressRow(
                          emoji: '',
                          label: cat.label,
                          done: done,
                          onTap: done
                              ? null
                              : () => Navigator.of(context).pushNamed(
                                    '/quiz/intro',
                                    arguments: {'category': cat},
                                  ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  // ── Section 4 ─────────────────────────────────────────────────────────────

  Widget _buildCategoryRow(BuildContext context, bool isDark, bool isPro) {
    final cats = NewsCategory.values.toList();
    final doneCount = _catCompletions.values.where((v) => v != null).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(
            'Category Quizzes',
            style: TextStyle(
                fontFamily: AppFonts.display,
                height: 1.02,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: context.textColor),
          ),
          const Spacer(),
          Text(
            '$doneCount/${NewsCategory.values.length} done',
            style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 13,
                color: context.subColor),
          ),
        ]),
        const SizedBox(height: 12),
        SizedBox(
          key: _categorySectionKey,
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: cats.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final cat = cats[i];
              final completion = _catCompletions[cat.name];
              // Stagger: card i starts at 300+80*i ms out of 1200ms total
              final start = (0.25 + i * 0.065).clamp(0.0, 0.9);
              final end = (start + 0.42).clamp(0.0, 1.0);
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
                child: _CategoryCard(
                  category: cat,
                  color: _catColor(cat),
                  icon: _catIcon(cat),
                  completion: completion,
                  onTap: (completion != null && !isPro)
                      ? null
                      : () => Navigator.of(context).pushNamed(
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

  // ── Section 5 ─────────────────────────────────────────────────────────────

  Widget _buildGamesSection(BuildContext context, UserData user, bool isDark) {
    final unlocked = user.hasPlayedToday;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          unlocked ? 'Keep Playing' : 'Complete a quiz to unlock',
          style: TextStyle(
              fontFamily: AppFonts.display,
              height: 1.02,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: unlocked ? context.textColor : context.subColor),
        ),
        const SizedBox(height: 12),
        _GameCard(
          emoji: '🎭',
          title: 'Real or Fake?',
          subtitle: 'Spot the fake headline',
          accentColor: const Color(0xFF5C6BC0),
          bgColor: isDark ? const Color(0xFF0A0A2D) : const Color(0xFFEDE7F6),
          borderColor: const Color(0xFF5C6BC0),
          unlocked: unlocked,
          arrowCtrl: _arrowCtrl,
          onTap: () => ref.read(selectedTabProvider.notifier).state = 1,
        ),
        const SizedBox(height: 12),
        _GameCard(
          emoji: '📅',
          title: 'Oldest to Latest',
          subtitle: 'Sort events in order',
          accentColor: const Color(0xFF1565C0),
          bgColor: isDark ? const Color(0xFF0A1A2D) : const Color(0xFFE3F2FD),
          borderColor: const Color(0xFF1565C0),
          unlocked: unlocked,
          arrowCtrl: _arrowCtrl,
          onTap: () => ref.read(selectedTabProvider.notifier).state = 1,
        ),
        const SizedBox(height: 12),
        _GameCard(
          emoji: '🗞️',
          title: 'Headline Match',
          subtitle: 'Pair briefs with headlines',
          accentColor: const Color(0xFF00BCD4),
          bgColor: isDark ? const Color(0xFF05252A) : const Color(0xFFE0F7FA),
          borderColor: const Color(0xFF00BCD4),
          unlocked: unlocked,
          arrowCtrl: _arrowCtrl,
          onTap: () => ref.read(selectedTabProvider.notifier).state = 1,
        ),
        const SizedBox(height: 12),
        _GameCard(
          emoji: '🕵️',
          title: 'Source Sleuth',
          subtitle: 'Pick the right news desk',
          accentColor: const Color(0xFFFF5722),
          bgColor: isDark ? const Color(0xFF2A0E08) : const Color(0xFFFFECE5),
          borderColor: const Color(0xFFFF5722),
          unlocked: unlocked,
          arrowCtrl: _arrowCtrl,
          onTap: () => ref.read(selectedTabProvider.notifier).state = 1,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRIVATE: Progress Row
// ─────────────────────────────────────────────────────────────────────────────

class _ProgressRow extends StatelessWidget {
  final String emoji;
  final String label;
  final bool done;
  final VoidCallback? onTap;

  const _ProgressRow({
    required this.emoji,
    required this.label,
    required this.done,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(done ? Icons.check_circle_rounded : Icons.circle_outlined,
          size: 12, color: done ? AppColors.accent : context.hintColor),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          label,
          style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 10,
              color: context.textColor),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      GestureDetector(
        onTap: done ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: done
                ? AppColors.accent
                : (context.isDark
                    ? const Color(0xFF2E2E2E)
                    : const Color(0xFFE0E0E0)),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            done ? 'Done' : 'Play',
            style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: done ? Colors.white : context.subColor),
          ),
        ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRIVATE: Category Card
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryCard extends StatefulWidget {
  final NewsCategory category;
  final Color color;
  final IconData icon;
  final Map<String, int>? completion;
  final VoidCallback? onTap;

  const _CategoryCard({
    required this.category,
    required this.color,
    required this.icon,
    required this.completion,
    required this.onTap,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.color;
    final done = widget.completion != null;

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
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: 160,
          decoration: BoxDecoration(
            color: context.cardColor
                .withValues(alpha: context.isDark ? 0.84 : 0.96),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: Colors.white
                    .withValues(alpha: context.isDark ? 0.06 : 0.72)),
            boxShadow: [
              BoxShadow(
                color: c.withValues(alpha: 0.16),
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
    return Column(
      children: [
        // Top 60%
        Expanded(
          flex: 6,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: c.withValues(alpha: 0.10),
                    boxShadow: [
                      BoxShadow(
                          color: c.withValues(alpha: 0.22), blurRadius: 20),
                    ],
                  ),
                  child: Icon(widget.icon, color: c, size: 28),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.category.label,
                  style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: c),
                ),
              ],
            ),
          ),
        ),
        // Bottom 40%
        Expanded(
          flex: 4,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: c.withValues(alpha: 0.2), width: 1),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('5 Questions',
                    style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 10,
                        color: context.subColor)),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        c.withValues(alpha: 0.92),
                        AppColors.accentDark
                      ]),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Play →',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontFamily: AppFonts.body,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDone(BuildContext context, Color c) {
    final comp = widget.completion!;
    return Column(
      children: [
        Expanded(
          flex: 6,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.accent, size: 30),
                const SizedBox(height: 4),
                Text(
                  widget.category.label,
                  style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: context.textColor),
                ),
                const SizedBox(height: 2),
                Text(
                  '${comp['correct']}/${comp['total']}',
                  style: const TextStyle(
                      fontFamily: AppFonts.display,
                      height: 1.02,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.accent),
                ),
                Text(
                  '+${comp['points']} pts',
                  style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 10,
                      color: context.subColor),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: c.withValues(alpha: 0.2), width: 1),
              ),
            ),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Done ✓',
                  style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRIVATE: Game Card
// ─────────────────────────────────────────────────────────────────────────────

class _GameCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color accentColor;
  final Color bgColor;
  final Color borderColor;
  final bool unlocked;
  final AnimationController arrowCtrl;
  final VoidCallback onTap;

  const _GameCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.bgColor,
    required this.borderColor,
    required this.unlocked,
    required this.arrowCtrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Arrow bounce: 0→4px right and back
    final arrowOffset = Tween<double>(begin: 0.0, end: 4.0).animate(
      CurvedAnimation(parent: arrowCtrl, curve: Curves.easeInOut),
    );

    return GestureDetector(
      onTap: unlocked ? onTap : null,
      child: Opacity(
        opacity: unlocked ? 1.0 : 0.45,
        child: Container(
          height: 104,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.accent
                    .withValues(alpha: context.isDark ? 0.28 : 0.16),
                context.cardColor
                    .withValues(alpha: context.isDark ? 0.88 : 0.98),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: Colors.white
                    .withValues(alpha: context.isDark ? 0.06 : 0.70)),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.14),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Row(children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.accentLight, AppColors.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.28),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                  child: Icon(_gameIcon(title), color: Colors.white, size: 24)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontFamily: AppFonts.body,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: context.textColor)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          fontFamily: AppFonts.body,
                          fontSize: 12,
                          color: context.subColor)),
                ],
              ),
            ),
            // Bouncing arrow
            AnimatedBuilder(
              animation: arrowOffset,
              builder: (_, __) {
                // Sine-wave bounce: 0→4→0 using arrowCtrl.value
                final t = arrowCtrl.value;
                final dx = 4.0 * math.sin(t * math.pi);
                return Transform.translate(
                  offset: Offset(dx, 0),
                  child: const Text(
                    'Play →',
                    style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent),
                  ),
                );
              },
            ),
          ]),
        ),
      ),
    );
  }

  IconData _gameIcon(String title) {
    if (title.contains('Real')) return Icons.fact_check_rounded;
    if (title.contains('Oldest')) return Icons.timeline_rounded;
    if (title.contains('Headline')) return Icons.compare_arrows_rounded;
    if (title.contains('Source')) return Icons.travel_explore_rounded;
    return Icons.sports_esports_rounded;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PUBLIC: Quiz Hero Card (exported for QuizPanel in screens.dart)
// ─────────────────────────────────────────────────────────────────────────────

class QuizHeroCard extends ConsumerStatefulWidget {
  final UserData user;
  final QuizResult? latestResult;
  final VoidCallback onStartQuiz;
  final VoidCallback onPlayRealOrFake;

  const QuizHeroCard({
    super.key,
    required this.user,
    required this.latestResult,
    required this.onStartQuiz,
    required this.onPlayRealOrFake,
  });

  @override
  ConsumerState<QuizHeroCard> createState() => QuizHeroCardState();
}

class QuizHeroCardState extends ConsumerState<QuizHeroCard>
    with TickerProviderStateMixin {
  late AnimationController _dotCtrl;
  late AnimationController _checkCtrl;
  late AnimationController _scoreCtrl;
  late AnimationController _btnCtrl;
  bool _buttonPressed = false;
  bool _loadingRewardAd = false;

  @override
  void initState() {
    super.initState();
    _dotCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _checkCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _scoreCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _btnCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));

    if (widget.user.hasPlayedToday) {
      _checkCtrl.forward();
      _scoreCtrl.forward();
      _dotCtrl.forward();
    } else {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _btnCtrl.forward();
      });
    }

    // Preload rewarded ad for bonus round eligibility
    final isPro = widget.user.isPro &&
        AuthService.currentUser != null &&
        !AuthService.isGuest;
    if (!isPro &&
        widget.user.hasPlayedToday &&
        !StorageService.hasBonusPlayedToday()) {
      unawaited(AdService.loadRewarded());
    }
  }

  @override
  void dispose() {
    _dotCtrl.dispose();
    _checkCtrl.dispose();
    _scoreCtrl.dispose();
    _btnCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleStartTap() async {
    if (!widget.user.hasPlayedToday) {
      widget.onStartQuiz();
      return;
    }
    final isPro = widget.user.isPro &&
        AuthService.currentUser != null &&
        !AuthService.isGuest;
    if (isPro) {
      Navigator.of(context).pushNamed('/quiz',
          arguments: {'forceRefresh': true, 'bonusRound': true});
      return;
    }
    if (StorageService.hasBonusPlayedToday() || _loadingRewardAd) return;
    setState(() => _loadingRewardAd = true);
    final earned =
        await AdService.showRewardedAndWait(allowDebugFallback: true);
    if (!mounted) return;
    setState(() => _loadingRewardAd = false);
    if (!earned) return;
    await StorageService.setBonusPlayedToday();
    if (!mounted) return;
    Navigator.of(context).pushNamed('/quiz',
        arguments: {'forceRefresh': true, 'bonusRound': true});
  }

  Future<void> _shareScore() async {
    final r = widget.latestResult;
    if (r == null) return;
    try {
      await Share.share(
          'I scored ${r.score}/${r.totalQuestions} on Briefed today! 🧠\n#Briefed');
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final played = widget.user.hasPlayedToday;
    final result = widget.latestResult;
    final isDark = context.isDark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: played
              ? (isDark
                  ? [const Color(0xFF2A1208), const Color(0xFF3A1809)]
                  : [const Color(0xFFFFF6EF), const Color(0xFFFFD8BD)])
              : (isDark
                  ? [const Color(0xFF3A1608), const Color(0xFF1F0E08)]
                  : [const Color(0xFFFFF8F1), const Color(0xFFFFC79F)]),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
            color: Colors.white.withValues(alpha: isDark ? 0.06 : 0.72)),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.22),
            blurRadius: 42,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: played && result != null
          ? _buildCompleted(context, result, isDark)
          : _buildNotPlayed(context, isDark),
    );
  }

  Widget _buildNotPlayed(BuildContext context, bool isDark) {
    final cats = AppConstants.allCategories
        .where((c) => widget.user.selectedCategories.contains(c['id']))
        .take(3)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category pills + duration
        Row(children: [
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: cats.map((c) {
                final id = c['id']!;
                final label = c['label']!;
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(_legacyCatIcon(id), size: 11, color: AppColors.accent),
                    const SizedBox(width: 4),
                    Text(label,
                        style: const TextStyle(
                            fontFamily: AppFonts.body,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent)),
                  ]),
                );
              }).toList(),
            ),
          ),
          const SizedBox(width: 8),
          Text('~2 mins',
              style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 12,
                  color: context.subColor)),
        ]),
        const SizedBox(height: 16),
        Text("Today's Quiz",
            style: TextStyle(
                fontFamily: AppFonts.display,
                height: 1.02,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: context.textColor,
                letterSpacing: -0.5)),
        const SizedBox(height: 4),
        Text('5 questions · Mixed categories',
            style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 14,
                color: context.subColor)),
        const SizedBox(height: 20),
        // Start button with elastic entry + press scale
        AnimatedBuilder(
          animation: _btnCtrl,
          builder: (_, child) {
            final scale = Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(parent: _btnCtrl, curve: Curves.elasticOut),
            );
            return Transform.scale(scale: scale.value, child: child);
          },
          child: GestureDetector(
            onTapDown: (_) => setState(() => _buttonPressed = true),
            onTapUp: (_) {
              setState(() => _buttonPressed = false);
              _handleStartTap();
            },
            onTapCancel: () => setState(() => _buttonPressed = false),
            child: AnimatedScale(
              scale: _buttonPressed ? 0.97 : 1.0,
              duration: const Duration(milliseconds: 150),
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.accentLight,
                      AppColors.accent,
                      AppColors.accentDark
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.30),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Center(
                  child: _loadingRewardAd
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text(
                          "Start Today's Quiz →",
                          style: TextStyle(
                              fontFamily: AppFonts.body,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white),
                        ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompleted(BuildContext context, QuizResult result, bool isDark) {
    final isPro = widget.user.isPro &&
        AuthService.currentUser != null &&
        !AuthService.isGuest;
    final List<bool> dots = result.attempts.isNotEmpty
        ? result.attempts.map((a) => a.correct).toList()
        : List.generate(result.totalQuestions, (i) => i < result.score);

    final scoreScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _scoreCtrl, curve: Curves.elasticOut),
    );

    return Column(
      children: [
        // Checkmark circle — fades in
        AnimatedBuilder(
          animation: _checkCtrl,
          builder: (_, __) => Opacity(
            opacity: _checkCtrl.value,
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                  color: AppColors.accent, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 26),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Score — scales in
        AnimatedBuilder(
          animation: scoreScale,
          builder: (_, child) =>
              Transform.scale(scale: scoreScale.value, child: child),
          child: Text(
            '${result.score}/${result.totalQuestions}',
            style: TextStyle(
                fontFamily: AppFonts.display,
                height: 1.02,
                fontSize: 56,
                fontWeight: FontWeight.w900,
                color: context.textColor),
          ),
        ),
        const SizedBox(height: 4),
        Text('${_fmt(result.pointsEarned)} pts earned',
            style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 16,
                color: context.subColor)),
        const SizedBox(height: 14),
        // Answer dots — staggered scale-in
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: dots.asMap().entries.map((entry) {
            final delay = (entry.key * 0.2).clamp(0.0, 0.8);
            final end = (delay + 0.2).clamp(0.0, 1.0);
            final dotAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _dotCtrl,
                curve: Interval(delay, end, curve: Curves.elasticOut),
              ),
            );
            return AnimatedBuilder(
              animation: dotAnim,
              builder: (_, __) => Transform.scale(
                scale: dotAnim.value,
                child: Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: entry.value
                        ? AppColors.accent
                        : AppColors.accentDark.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        Text(
          '🔥 ${widget.user.streak} day streak — keep it up!',
          style: const TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFFFF5722)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        // Buttons row
        Row(children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: context.textColor,
                side: BorderSide(color: context.borderColor, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _shareScore,
              child: const Text('Share Score',
                  style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5722),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: widget.onPlayRealOrFake,
              child: const Text('More Quizzes →',
                  style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
        if (isPro) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: const BorderSide(color: AppColors.accent, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _handleStartTap,
              child: const Text('Play Again →',
                  style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ],
    );
  }
}

class _AvatarWithLevel extends StatelessWidget {
  final String initial;
  final int level;
  final bool isDark;
  const _AvatarWithLevel({required this.initial, required this.level, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.accent, AppColors.accentDark],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.45),
                blurRadius: 0,
                offset: const Offset(0, 3),
              ),
              BoxShadow(
                color: context.bgColor,
                blurRadius: 0,
                spreadRadius: 2,
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
        ),
        // Level badge
        Positioned(
          bottom: -3,
          right: -6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: const Color(0xFFFFC15A),
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: context.bgColor,
                  blurRadius: 0,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Text(
              'L$level',
              style: const TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: Color(0xFF5C2E04),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
