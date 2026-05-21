import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/theme.dart';
import '../../../models/models.dart';
import '../../../providers/providers.dart';
import '../../../services/storage_service.dart';
import '../../news/models/news_category.dart';
import '../models/quiz_question.dart';
import '../models/quiz_result.dart';
import '../models/quiz_session.dart';
import '../providers/new_quiz_provider.dart';
import '../../../screens/screens.dart' show showBriefedProSheet;

// ── CATEGORY SELECT ───────────────────────────────────────────────────────────

class CategorySelectScreen extends ConsumerWidget {
  const CategorySelectScreen({super.key});

  static const _cats = [
    NewsCategory.world,
    NewsCategory.politics,
    NewsCategory.sports,
    NewsCategory.technology,
    NewsCategory.business,
    NewsCategory.health,
    NewsCategory.entertainment,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Choose Category',
            style: TextStyle(
                fontFamily: AppFonts.display,
                height: 1.02,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: context.textColor)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('What are you briefed on today?',
                  style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 14,
                      color: context.subColor)),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.separated(
                  itemCount: _cats.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) =>
                      _CategoryTile(category: _cats[i]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryTile extends ConsumerWidget {
  final NewsCategory category;
  const _CategoryTile({required this.category});

  static const _proGated = {
    NewsCategory.politics,
    NewsCategory.technology,
    NewsCategory.business,
    NewsCategory.health,
    NewsCategory.entertainment,
  };

  static void _showProUpsell(BuildContext context, WidgetRef ref) {
    showBriefedProSheet(context, ref);
  }

  Color _color() {
    switch (category) {
      case NewsCategory.world:
        return AppColors.blue;
      case NewsCategory.politics:
        return AppColors.purple;
      case NewsCategory.sports:
        return AppColors.green;
      case NewsCategory.technology:
        return AppColors.teal;
      case NewsCategory.business:
        return AppColors.orange;
      case NewsCategory.health:
        return const Color(0xFF26A69A);
      case NewsCategory.entertainment:
        return const Color(0xFFE91E63);
    }
  }

  IconData _icon() {
    switch (category) {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = _color();
    final user = ref.watch(userProvider);
    final authUser = ref.watch(authStateProvider).valueOrNull;
    final isPro = user.isPro && authUser != null && !authUser.isAnonymous;
    final isLocked = _proGated.contains(category) && !isPro;
    final playedToday = !isPro &&
        StorageService.getCategoryCompletion(category.name) != null;

    // ── Pro-locked tile ───────────────────────────────────────────────────────
    if (isLocked) {
      return GestureDetector(
        onTap: () => _showProUpsell(context, ref),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
          ),
          child: Row(children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.lock_rounded,
                  color: AppColors.gold, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(category.label,
                          style: TextStyle(
                              fontFamily: AppFonts.body,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: context.textColor)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('PRO',
                            style: TextStyle(
                                fontFamily: AppFonts.body,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: AppColors.gold,
                                letterSpacing: 0.8)),
                      ),
                    ]),
                    const SizedBox(height: 3),
                    Text('Upgrade to Pro to unlock',
                        style: TextStyle(
                            fontFamily: AppFonts.body,
                            fontSize: 12,
                            color: context.hintColor)),
                  ]),
            ),
            const Icon(Icons.star_rounded, size: 16, color: AppColors.gold),
          ]),
        ),
      );
    }

    // ── Normal / completed tile ───────────────────────────────────────────────
    return GestureDetector(
      onTap: () {
        Navigator.of(context)
            .pushNamed('/quiz/intro', arguments: {'category': category});
      },
      child: Opacity(
        opacity: playedToday ? 0.55 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: playedToday
                    ? context.borderColor
                    : c.withValues(alpha: 0.25)),
            boxShadow: [
              BoxShadow(
                  color: c.withValues(alpha: playedToday ? 0.0 : 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: Row(children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: c.withValues(alpha: playedToday ? 0.06 : 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(playedToday ? Icons.check_rounded : _icon(),
                  color: playedToday ? AppColors.green : c, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(category.label,
                        style: TextStyle(
                            fontFamily: AppFonts.body,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: context.textColor)),
                    const SizedBox(height: 3),
                    Text(
                        playedToday
                            ? 'Completed today · Come back tomorrow'
                            : '5 questions · Easy → Expert',
                        style: TextStyle(
                            fontFamily: AppFonts.body,
                            fontSize: 12,
                            color: playedToday
                                ? AppColors.green
                                : context.hintColor)),
                  ]),
            ),
            Icon(
                playedToday
                    ? Icons.lock_clock_rounded
                    : Icons.arrow_forward_ios_rounded,
                size: 16,
                color: playedToday ? AppColors.green : context.hintColor),
          ]),
        ),
      ),
    );
  }
}

// ── QUIZ INTRO ────────────────────────────────────────────────────────────────

class QuizIntroScreen extends ConsumerWidget {
  const QuizIntroScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = ModalRoute.of(context)?.settings.arguments as Map? ?? {};
    final category = args['category'] as NewsCategory? ?? NewsCategory.world;
    final isDailyMix = args['isDailyMix'] as bool? ?? false;

    final user = ref.watch(userProvider);
    final authUser = ref.watch(authStateProvider).valueOrNull;
    final isPro = user.isPro && authUser != null && !authUser.isAnonymous;
    final isLocked = _CategoryTile._proGated.contains(category) && !isPro;
    final playedToday = !isPro &&
        StorageService.getCategoryCompletion(category.name) != null;

    final c = _catColor(category);
    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: isLocked
                      ? AppColors.gold.withValues(alpha: 0.12)
                      : c.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                    isLocked ? Icons.lock_rounded : _catIcon(category),
                    color: isLocked ? AppColors.gold : c,
                    size: 48),
              ),
              const SizedBox(height: 28),
              Text(category.label,
                  style: TextStyle(
                      fontFamily: AppFonts.display,
                      height: 1.02,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: context.textColor)),
              const SizedBox(height: 10),
              Text('5 Questions · ~2 mins',
                  style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 15,
                      color: context.subColor)),
              const SizedBox(height: 6),
              Text('Easy → Expert',
                  style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isLocked ? AppColors.gold : c)),
              const Spacer(),
              if (!isLocked)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: context.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Row(children: [
                    const Icon(Icons.bolt_rounded,
                        color: AppColors.gold, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('Answer fast for speed bonus points',
                          style: TextStyle(
                              fontFamily: AppFonts.body,
                              fontSize: 13,
                              color: context.subColor,
                              height: 1.4)),
                    ),
                  ]),
                ),
              const SizedBox(height: 20),
              // ── Pro locked ─────────────────────────────────────────────────
              if (isLocked) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 18),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.3)),
                  ),
                  child: const Row(children: [
                    Icon(Icons.star_rounded,
                        color: AppColors.gold, size: 22),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This category is part of Briefed Pro. Upgrade to unlock all 7 categories.',
                        style: TextStyle(
                            fontFamily: AppFonts.body,
                            fontSize: 13,
                            color: AppColors.gold,
                            height: 1.4),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: () => showBriefedProSheet(context, ref),
                    child: const Text('Upgrade to Pro',
                        style: TextStyle(
                            fontFamily: AppFonts.body,
                            fontSize: 17,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Back',
                      style: TextStyle(
                          fontFamily: AppFonts.body,
                          color: context.hintColor,
                          fontSize: 14)),
                ),
              // ── Already played (free user) ────────────────────────────────
              ] else if (playedToday) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 18),
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppColors.green.withValues(alpha: 0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.check_circle_rounded,
                        color: AppColors.green, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "You've already completed today's ${category.label} quiz. Come back tomorrow!",
                        style: const TextStyle(
                            fontFamily: AppFonts.body,
                            fontSize: 14,
                            color: AppColors.green,
                            height: 1.4),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.textColor,
                      side: BorderSide(color: context.borderColor),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Back to Categories',
                        style: TextStyle(
                            fontFamily: AppFonts.body,
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              // ── Ready to play ─────────────────────────────────────────────
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      ref
                          .read(newQuizProvider.notifier)
                          .startQuiz(category, isDailyMix: isDailyMix);
                      Navigator.of(context)
                          .pushReplacementNamed('/quiz/play');
                    },
                    child: Text(
                        isPro && StorageService.getCategoryCompletion(category.name) != null
                            ? 'Play Again'
                            : 'Tap to Start',
                        style: const TextStyle(
                            fontFamily: AppFonts.body,
                            fontSize: 17,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
                if (isPro && StorageService.getCategoryCompletion(category.name) != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      'Same questions · Fresh quiz generates every 4 hours',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontFamily: AppFonts.body,
                          fontSize: 11,
                          color: context.hintColor),
                    ),
                  ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Back',
                      style: TextStyle(
                          fontFamily: AppFonts.body,
                          color: context.hintColor,
                          fontSize: 14)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _catColor(NewsCategory c) {
    switch (c) {
      case NewsCategory.world:
        return AppColors.blue;
      case NewsCategory.politics:
        return AppColors.purple;
      case NewsCategory.sports:
        return AppColors.green;
      case NewsCategory.technology:
        return AppColors.teal;
      case NewsCategory.business:
        return AppColors.orange;
      case NewsCategory.health:
        return const Color(0xFF26A69A);
      case NewsCategory.entertainment:
        return const Color(0xFFE91E63);
    }
  }

  IconData _catIcon(NewsCategory c) {
    switch (c) {
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
}

// ── NEW QUIZ SCREEN ───────────────────────────────────────────────────────────

class NewQuizScreen extends ConsumerStatefulWidget {
  const NewQuizScreen({super.key});
  @override
  ConsumerState<NewQuizScreen> createState() => _NewQuizScreenState();
}

class _NewQuizScreenState extends ConsumerState<NewQuizScreen>
    with TickerProviderStateMixin {
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;
  late AnimationController _flashCtrl;
  late Animation<double> _flashAnim;
  late AnimationController _ptsCtrl;
  late Animation<double> _ptsAnim;

  int _lastShakeIndex = -1;
  int _lastPts = 0;
  Color _flashColor = Colors.green;

  @override
  void initState() {
    super.initState();

    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: -4.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -4.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));

    _flashCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _flashAnim = CurvedAnimation(parent: _flashCtrl, curve: Curves.easeOut);

    _ptsCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _ptsAnim = CurvedAnimation(parent: _ptsCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    _flashCtrl.dispose();
    _ptsCtrl.dispose();
    super.dispose();
  }

  void _onAnswered(QuizSession prev, QuizSession next) {
    final q = next.currentQuestion ?? prev.questions[prev.currentIndex];
    final answer = next.currentAnswer ?? prev.answers[prev.currentIndex];
    final isCorrect = answer == q.correctAnswerIndex;

    if (isCorrect) {
      _flashColor = AppColors.green;
      HapticFeedback.lightImpact();
      _lastPts = q.points +
          (next.speedBonuses.isNotEmpty
              ? next.speedBonuses[prev.currentIndex]
              : 0);
      _ptsCtrl.forward(from: 0);
    } else {
      _flashColor = AppColors.red;
      HapticFeedback.mediumImpact();
      if (_lastShakeIndex != prev.currentIndex) {
        _lastShakeIndex = prev.currentIndex;
        _shakeCtrl.forward(from: 0);
      }
      _lastPts = 0;
    }

    _flashCtrl.forward(from: 0).then((_) => _flashCtrl.reverse());
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(newQuizProvider);

    ref.listen<QuizSession>(newQuizProvider, (prev, next) {
      if (prev == null) return;
      if (prev.status == NewQuizStatus.active &&
          next.status == NewQuizStatus.revealed) {
        _onAnswered(prev, next);
      }
      if (next.status == NewQuizStatus.finished) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/quiz/result');
          }
        });
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(child: _buildBody(context, session)),
    );
  }

  Widget _buildBody(BuildContext context, QuizSession session) {
    if (session.status == NewQuizStatus.loading) {
      return _buildLoading(session.category);
    }
    if (session.status == NewQuizStatus.error) {
      return _buildError(context, session);
    }
    if (session.questions.isEmpty) {
      return _buildLoading(session.category);
    }

    final q = session.currentQuestion!;
    final answer = session.currentAnswer;
    final revealed = session.status == NewQuizStatus.revealed ||
        session.revealingExplanation;

    return Stack(children: [
      Column(children: [
        _TopBar(
          session: session,
          onQuit: () => _showQuitDialog(context),
        ),
        _SegmentedProgress(session: session),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: CurvedAnimation(parent: anim, curve: Curves.easeIn),
              child: child,
            ),
            child: SingleChildScrollView(
              key: ValueKey(session.currentIndex),
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              child: Column(children: [
                // Metadata row: difficulty + pts + category
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(children: [
                    _DifficultyBadge(difficulty: q.difficulty),
                    const SizedBox(width: 8),
                    Text(
                      '+${q.points} pts',
                      style: const TextStyle(
                          fontFamily: AppFonts.body,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gold),
                    ),
                    const Spacer(),
                    _CategoryPill(category: q.category),
                  ]),
                ),
                // 16:9 question display card with timer bar
                _QuestionDisplay(
                  question: q,
                  timeLeft: session.timeLeft,
                  revealed: revealed,
                ),
                const SizedBox(height: 14),
                // Answer option cards
                ...q.options.asMap().entries.map((e) {
                  final idx = e.key;
                  final text = e.value;
                  final isSelected = answer == idx;
                  final isCorrect = idx == q.correctAnswerIndex;
                  final isWrong = revealed && isSelected && !isCorrect;
                  final isDisabled = revealed && !isCorrect && !isSelected;

                  Widget option = _OptionCard(
                    index: idx,
                    text: text,
                    isSelected: isSelected,
                    isCorrect: isCorrect,
                    isRevealed: revealed,
                    isDisabled: isDisabled,
                    onTap: revealed
                        ? null
                        : () => ref
                            .read(newQuizProvider.notifier)
                            .answerQuestion(idx),
                  );

                  if (isWrong) {
                    option = AnimatedBuilder(
                      animation: _shakeAnim,
                      builder: (ctx, child) => Transform.translate(
                          offset: Offset(_shakeAnim.value, 0), child: child),
                      child: option,
                    );
                  }

                  return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: option);
                }),
                // Explanation panel — slides up on reveal
                _ExplanationPanel(
                  visible: revealed,
                  question: q,
                  session: session,
                  onNext: () =>
                      ref.read(newQuizProvider.notifier).skipExplanation(),
                  isLast: session.currentIndex + 1 >= session.questions.length,
                ),
              ]),
            ),
          ),
        ),
        // Full-width timer bar pinned to very bottom of screen
        _TimerBar(timeLeft: session.timeLeft),
      ]),
      // Screen colour flash overlay
      IgnorePointer(
        child: AnimatedBuilder(
          animation: _flashAnim,
          builder: (ctx, _) => Container(
            color: _flashColor.withValues(alpha: _flashAnim.value * 0.13),
          ),
        ),
      ),
      // Floating "+X pts" animation
      if (_lastPts > 0)
        Positioned(
          bottom: 260,
          left: 0,
          right: 0,
          child: AnimatedBuilder(
            animation: _ptsAnim,
            builder: (ctx, _) => Opacity(
              opacity: (1 - _ptsAnim.value * 1.4).clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, -70 * _ptsAnim.value),
                child: Center(
                  child: Text(
                    '+$_lastPts pts',
                    style: const TextStyle(
                        fontFamily: AppFonts.display,
                        height: 1.02,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppColors.gold),
                  ),
                ),
              ),
            ),
          ),
        ),
    ]);
  }

  void _showQuitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Quit Quiz?',
            style: TextStyle(
                fontFamily: AppFonts.body,
                fontWeight: FontWeight.w800,
                color: Colors.white)),
        content: const Text('Your progress will be lost.',
            style: TextStyle(
                fontFamily: AppFonts.body,
                color: Colors.white70,
                fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Keep Going',
                style: TextStyle(
                    fontFamily: AppFonts.body,
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () {
              ref.read(newQuizProvider.notifier).reset();
              Navigator.of(ctx).pop();
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
            child: const Text('Quit',
                style: TextStyle(
                    fontFamily: AppFonts.body,
                    color: AppColors.red,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading(NewsCategory? category) {
    return const Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        CircularProgressIndicator(color: AppColors.accent),
        SizedBox(height: 20),
        Text(
          'Generating quiz…',
          style: TextStyle(
              fontFamily: AppFonts.body, fontSize: 15, color: Colors.white70),
        ),
        SizedBox(height: 8),
        Text('Powered by AI',
            style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 12,
                color: Colors.white38)),
      ]),
    );
  }

  Widget _buildError(BuildContext context, QuizSession session) {
    final isAlreadyPlayed = session.error == 'already_played_today';
    final isNotReady = session.error == 'quiz_not_ready';

    final icon = isAlreadyPlayed
        ? Icons.check_circle_outline_rounded
        : isNotReady
            ? Icons.hourglass_top_rounded
            : Icons.error_outline_rounded;
    final iconColor = isAlreadyPlayed ? AppColors.green : AppColors.red;
    final title = isAlreadyPlayed
        ? "All done for today!"
        : isNotReady
            ? "Quiz being prepared"
            : "Quiz failed to load";
    final body = isAlreadyPlayed
        ? "You've already completed this quiz today.\nCome back tomorrow for fresh questions."
        : isNotReady
            ? "Your daily quiz is being generated.\nCheck back in a few minutes."
            : session.error ?? '';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: iconColor, size: 56),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  fontFamily: AppFonts.display,
                  height: 1.02,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
          const SizedBox(height: 10),
          Text(body,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 13,
                  color: Colors.white54,
                  height: 1.5)),
          const SizedBox(height: 24),
          if (!isAlreadyPlayed)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white),
              onPressed: () {
                if (session.category != null) {
                  ref
                      .read(newQuizProvider.notifier)
                      .startQuiz(session.category!);
                } else {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Try Again',
                  style: TextStyle(
                      fontFamily: AppFonts.body, fontWeight: FontWeight.w700)),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
            child: Text(isAlreadyPlayed ? 'Back to Home' : 'Go Home',
                style: const TextStyle(
                    fontFamily: AppFonts.body, color: Colors.white54)),
          ),
        ]),
      ),
    );
  }
}

// ── TOP BAR ───────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final QuizSession session;
  final VoidCallback onQuit;
  const _TopBar({required this.session, required this.onQuit});

  @override
  Widget build(BuildContext context) {
    final total = session.questions.length;
    final current = session.currentIndex + 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 14, 0),
      child: Row(children: [
        IconButton(
          icon:
              const Icon(Icons.close_rounded, color: Colors.white54, size: 22),
          onPressed: onQuit,
        ),
        Expanded(
          child: Text(
            'Q$current of $total',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white60),
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, anim) => ScaleTransition(
              scale: anim, child: FadeTransition(opacity: anim, child: child)),
          child: Row(
            key: ValueKey(session.totalPoints),
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.bolt_rounded, color: AppColors.gold, size: 16),
              const SizedBox(width: 3),
              Text(
                '${session.totalPoints}',
                style: const TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.gold),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

// ── SEGMENTED PROGRESS ────────────────────────────────────────────────────────

class _SegmentedProgress extends StatelessWidget {
  final QuizSession session;
  const _SegmentedProgress({required this.session});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: List.generate(session.questions.length, (i) {
          final isCurrent = i == session.currentIndex &&
              session.status != NewQuizStatus.finished;
          final answer = i < session.answers.length ? session.answers[i] : null;
          final isAnswered = answer != null;
          final isCorrect = isAnswered &&
              i < session.questions.length &&
              answer == session.questions[i].correctAnswerIndex;

          Color color;
          if (isCurrent) {
            color = AppColors.accent;
          } else if (!isAnswered) {
            color = const Color(0xFF2A2A2A);
          } else if (isCorrect) {
            color = AppColors.green;
          } else {
            color = AppColors.red;
          }

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                  right: i < session.questions.length - 1 ? 4 : 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 6,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: isCurrent
                      ? [
                          BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.55),
                              blurRadius: 8,
                              spreadRadius: 1)
                        ]
                      : null,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── DIFFICULTY BADGE ──────────────────────────────────────────────────────────

class _DifficultyBadge extends StatelessWidget {
  final QuestionDifficulty difficulty;
  const _DifficultyBadge({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final c = difficulty.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withValues(alpha: 0.3)),
      ),
      child: Text(
        difficulty.label,
        style: TextStyle(
            fontFamily: AppFonts.body,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: c,
            letterSpacing: 0.3),
      ),
    );
  }
}

// ── CATEGORY PILL ─────────────────────────────────────────────────────────────

class _CategoryPill extends StatelessWidget {
  final NewsCategory category;
  const _CategoryPill({required this.category});

  Color _color() {
    switch (category) {
      case NewsCategory.world:
        return AppColors.blue;
      case NewsCategory.politics:
        return AppColors.purple;
      case NewsCategory.sports:
        return AppColors.green;
      case NewsCategory.technology:
        return AppColors.teal;
      case NewsCategory.business:
        return AppColors.orange;
      case NewsCategory.health:
        return const Color(0xFF26A69A);
      case NewsCategory.entertainment:
        return const Color(0xFFE91E63);
    }
  }

  IconData _icon() {
    switch (category) {
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

  @override
  Widget build(BuildContext context) {
    final c = _color();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(_icon(), color: c, size: 11),
        const SizedBox(width: 4),
        Text(
          category.label,
          style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: c),
        ),
      ]),
    );
  }
}

// ── QUESTION DISPLAY ──────────────────────────────────────────────────────────

class _QuestionDisplay extends StatelessWidget {
  final QuizQuestion question;
  final int timeLeft;
  final bool revealed;
  const _QuestionDisplay(
      {required this.question, required this.timeLeft, required this.revealed});

  Color _catColor() {
    switch (question.category) {
      case NewsCategory.world:
        return AppColors.blue;
      case NewsCategory.politics:
        return AppColors.purple;
      case NewsCategory.sports:
        return AppColors.green;
      case NewsCategory.technology:
        return AppColors.teal;
      case NewsCategory.business:
        return AppColors.orange;
      case NewsCategory.health:
        return const Color(0xFF26A69A);
      case NewsCategory.entertainment:
        return const Color(0xFFE91E63);
    }
  }

  IconData _catIcon() {
    switch (question.category) {
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

  @override
  Widget build(BuildContext context) {
    final catColor = _catColor();
    final catIcon = _catIcon();

    final hasImg = question.imageUrl != null && question.imageUrl!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Show 16:9 image only when one actually exists
        if (hasImg) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                question.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    _IconBackground(catColor, catIcon),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        // Question text — larger and centred when no image
        Text(
          question.questionText,
          style: TextStyle(
            fontFamily: AppFonts.body,
            fontSize: hasImg ? 18 : 22,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1.3,
          ),
          textAlign: hasImg ? TextAlign.left : TextAlign.center,
        ),
        const SizedBox(height: 8),
        // Source name + countdown timer on same row
        Row(children: [
          Text(
            'Source: ${question.articleSourceName}',
            style: const TextStyle(
                fontFamily: AppFonts.body, fontSize: 12, color: Colors.white54),
          ),
          const Spacer(),
          if (!revealed) _TimerCountdown(timeLeft: timeLeft),
        ]),
      ],
    );
  }
}

class _IconBackground extends StatelessWidget {
  final Color color;
  final IconData icon;
  const _IconBackground(this.color, this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.18), const Color(0xFF0D0D0D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: color.withValues(alpha: 0.38),
                  blurRadius: 44,
                  spreadRadius: 12)
            ],
          ),
          child: Icon(icon, color: color, size: 62),
        ),
      ),
    );
  }
}

class _TimerCountdown extends StatelessWidget {
  final int timeLeft;
  const _TimerCountdown({required this.timeLeft});

  @override
  Widget build(BuildContext context) {
    final urgent = timeLeft < 5;
    return Text(
      '${timeLeft}s',
      style: TextStyle(
        fontFamily: AppFonts.body,
        fontSize: urgent ? 24 : 16,
        fontWeight: FontWeight.w900,
        color: urgent ? AppColors.red : Colors.grey,
      ),
    );
  }
}

// ── TIMER BAR ─────────────────────────────────────────────────────────────────

class _TimerBar extends StatelessWidget {
  final int timeLeft;
  const _TimerBar({required this.timeLeft});

  Color _barColor() {
    if (timeLeft > 6) return AppColors.orange;
    if (timeLeft > 3) return AppColors.gold;
    return AppColors.red;
  }

  @override
  Widget build(BuildContext context) {
    final fraction = (timeLeft / 10.0).clamp(0.0, 1.0);
    return LayoutBuilder(builder: (ctx, constraints) {
      return Stack(children: [
        Container(height: 4, color: const Color(0xFF1A1A1A)),
        AnimatedContainer(
          duration: const Duration(milliseconds: 900),
          curve: Curves.linear,
          height: 4,
          width: constraints.maxWidth * fraction,
          color: _barColor(),
        ),
      ]);
    });
  }
}

// ── OPTION CARD ───────────────────────────────────────────────────────────────

class _OptionCard extends StatelessWidget {
  final int index;
  final String text;
  final bool isSelected;
  final bool isCorrect;
  final bool isRevealed;
  final bool isDisabled;
  final VoidCallback? onTap;

  const _OptionCard({
    required this.index,
    required this.text,
    required this.isSelected,
    required this.isCorrect,
    required this.isRevealed,
    required this.isDisabled,
    required this.onTap,
  });

  static const _labels = ['A', 'B', 'C', 'D'];

  Color _bg() {
    if (!isRevealed) {
      return isSelected ? const Color(0xFF241E15) : const Color(0xFF1A1A1A);
    }
    if (isCorrect) return const Color(0xFF1B3A1F);
    if (isSelected) return const Color(0xFF3A1B1B);
    return const Color(0xFF1A1A1A);
  }

  Color _border() {
    if (!isRevealed) {
      return isSelected ? AppColors.accent : const Color(0xFF333333);
    }
    if (isCorrect) return AppColors.green;
    if (isSelected) return AppColors.red;
    return const Color(0xFF2A2A2A);
  }

  Color _circleColor() {
    if (!isRevealed) {
      return isSelected ? AppColors.accent : const Color(0xFF2A2A2A);
    }
    if (isCorrect) return AppColors.green;
    if (isSelected) return AppColors.red;
    return const Color(0xFF2A2A2A);
  }

  @override
  Widget build(BuildContext context) {
    final label = _labels[index];
    Widget circleChild;
    if (isRevealed && isCorrect) {
      circleChild =
          const Icon(Icons.check_rounded, size: 14, color: Colors.white);
    } else if (isRevealed && isSelected) {
      circleChild =
          const Icon(Icons.close_rounded, size: 14, color: Colors.white);
    } else {
      circleChild = Text(
        label,
        style: TextStyle(
            fontFamily: AppFonts.body,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : Colors.white54),
      );
    }

    final card = GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        constraints: const BoxConstraints(minHeight: 58),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _bg(),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _border(),
            width: isRevealed && (isCorrect || isSelected) ? 1.5 : 1.0,
          ),
        ),
        child: Row(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 30,
            height: 30,
            decoration:
                BoxDecoration(color: _circleColor(), shape: BoxShape.circle),
            child: Center(child: circleChild),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 15,
                color: isDisabled ? Colors.white38 : Colors.white,
                fontWeight:
                    isRevealed && isCorrect ? FontWeight.w700 : FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isRevealed && isCorrect)
            const Icon(Icons.check_circle_rounded,
                color: AppColors.green, size: 18),
        ]),
      ),
    );

    return isDisabled ? Opacity(opacity: 0.4, child: card) : card;
  }
}

// ── EXPLANATION PANEL ─────────────────────────────────────────────────────────

class _ExplanationPanel extends StatefulWidget {
  final bool visible;
  final QuizQuestion question;
  final QuizSession session;
  final VoidCallback onNext;
  final bool isLast;

  const _ExplanationPanel({
    required this.visible,
    required this.question,
    required this.session,
    required this.onNext,
    required this.isLast,
  });

  @override
  State<_ExplanationPanel> createState() => _ExplanationPanelState();
}

class _ExplanationPanelState extends State<_ExplanationPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _sizeAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 380));
    _sizeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    if (widget.visible) _ctrl.forward();
  }

  @override
  void didUpdateWidget(_ExplanationPanel old) {
    super.didUpdateWidget(old);
    if (widget.visible && !old.visible) {
      _ctrl.forward();
    } else if (!widget.visible && old.visible) {
      _ctrl.reset();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final answer = widget.session.currentAnswer;
    final isCorrect =
        answer != null && answer == widget.question.correctAnswerIndex;

    return SizeTransition(
      sizeFactor: _sizeAnim,
      axisAlignment: -1,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF2A2A2A)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Correct / Wrong header
                Row(children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCorrect
                          ? AppColors.green.withValues(alpha: 0.18)
                          : AppColors.red.withValues(alpha: 0.18),
                    ),
                    child: Icon(
                      isCorrect ? Icons.check_rounded : Icons.close_rounded,
                      color: isCorrect ? AppColors.green : AppColors.red,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isCorrect
                          ? 'Correct!'
                          : 'Not quite — ${widget.question.options[widget.question.correctAnswerIndex]}',
                      style: TextStyle(
                          fontFamily: AppFonts.body,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isCorrect ? AppColors.green : AppColors.red),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                // Did you know header
                const Row(children: [
                  Icon(Icons.lightbulb_outline_rounded,
                      color: AppColors.gold, size: 14),
                  SizedBox(width: 6),
                  Text('Did you know?',
                      style: TextStyle(
                          fontFamily: AppFonts.body,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.gold)),
                ]),
                const SizedBox(height: 7),
                Text(
                  widget.question.explanation,
                  style: const TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 13,
                      color: Colors.white70,
                      height: 1.65),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13)),
                      elevation: 0,
                    ),
                    onPressed: widget.onNext,
                    child: Text(
                      widget.isLast ? 'See Results →' : 'Next →',
                      style: const TextStyle(
                          fontFamily: AppFonts.body,
                          fontSize: 15,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── RESULT SCREEN ─────────────────────────────────────────────────────────────

class NewResultScreen extends ConsumerStatefulWidget {
  const NewResultScreen({super.key});
  @override
  ConsumerState<NewResultScreen> createState() => _NewResultScreenState();
}

class _NewResultScreenState extends ConsumerState<NewResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _entryCtrl;
  late Animation<double> _entryAnim;
  late AnimationController _arcCtrl;
  late Animation<double> _arcAnim;
  late ConfettiController _confetti;
  final ScreenshotController _screenshot = ScreenshotController();
  late NewQuizResult _result;
  bool _saved = false;

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _entryAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.elasticOut);

    _arcCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _arcAnim = CurvedAnimation(parent: _arcCtrl, curve: Curves.easeOut);

    _confetti = ConfettiController(duration: const Duration(seconds: 4));

    _result = ref.read(newQuizProvider.notifier).buildResult();
    _entryCtrl.forward();
    _arcCtrl.forward();

    if (_result.correctCount >= 4) {
      _confetti.play();
      HapticFeedback.heavyImpact();
    } else if (_result.correctCount >= 3) {
      HapticFeedback.mediumImpact();
    }

    _saveStats();
  }

  Future<void> _saveStats() async {
    if (_saved) return;
    _saved = true;
    final session = ref.read(newQuizProvider);
    // Convert to legacy QuizResult for stats tracking
    final attempts = _result.questions.asMap().entries.map((e) {
      final i = e.key;
      final q = e.value;
      final sel = i < _result.answers.length ? _result.answers[i] : null;
      return QuestionAttempt(
        category: q.category.name,
        difficulty: q.difficulty.name,
        correct: sel == q.correctAnswerIndex,
        selectedIndex: sel ?? -1,
        correctIndex: q.correctAnswerIndex,
      );
    }).toList();

    // Daily mix covers all categories — mark all as done
    final categories = session.isDailyMix
        ? NewsCategory.values.map((c) => c.name).toList()
        : [_result.category.name];

    final legacy = QuizResult(
      date: DateTime.now().toIso8601String().substring(0, 10),
      score: _result.correctCount,
      totalQuestions: _result.totalQuestions,
      pointsEarned: _result.totalPoints,
      timeTakenSeconds: 0,
      categories: categories,
      attempts: attempts,
    );
    await ref.read(userProvider.notifier).afterQuiz(legacy);
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _arcCtrl.dispose();
    _confetti.dispose();
    super.dispose();
  }

  Future<void> _shareResult() async {
    try {
      final bytes = await _screenshot.capture(pixelRatio: 2.0);
      if (bytes == null) return;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/briefed_score.png');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            'I scored ${_result.correctCount}/${_result.totalQuestions} on Briefed! 🧠',
      );
    } catch (e) {
      // Share failed silently
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _result.correctCount >= 4
        ? AppColors.green
        : _result.correctCount >= 3
            ? AppColors.gold
            : AppColors.red;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Stack(children: [
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            colors: const [
              AppColors.accent,
              AppColors.gold,
              AppColors.green,
              AppColors.blue,
            ],
            numberOfParticles: 20,
          ),
        ),
        SafeArea(
          child: ScaleTransition(
            scale: _entryAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                const SizedBox(height: 20),
                // Score circle
                _ScoreCircle(
                    result: _result, color: color, animation: _arcAnim),
                const SizedBox(height: 12),
                Text(_result.scoreLabel,
                    style: const TextStyle(
                        fontFamily: AppFonts.display,
                        height: 1.02,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white)),
                const SizedBox(height: 24),
                // Points card
                _PointsCard(result: _result),
                const SizedBox(height: 20),
                // Answer review
                _AnswerReview(result: _result),
                const SizedBox(height: 20),
                // Streak
                _StreakBanner(streak: ref.watch(userProvider).streak),
                const SizedBox(height: 20),
                // Share button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: _shareResult,
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: const Text('Share My Score',
                        style: TextStyle(
                            fontFamily: AppFonts.body,
                            fontSize: 16,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(height: 12),
                // Next actions
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF333333)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        ref.read(newQuizProvider.notifier).reset();
                        Navigator.of(context)
                            .pushReplacementNamed('/quiz/select');
                      },
                      child: const Text('Play Again',
                          style: TextStyle(
                              fontFamily: AppFonts.body,
                              fontSize: 14,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF333333)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () =>
                          Navigator.of(context).pushNamed('/hot-take'),
                      child: const Text('Try Hot Take',
                          style: TextStyle(
                              fontFamily: AppFonts.body,
                              fontSize: 14,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(context)
                      .pushNamedAndRemoveUntil('/home', (_) => false),
                  child: const Text('Back to Home',
                      style: TextStyle(
                          fontFamily: AppFonts.body,
                          color: Colors.white38,
                          fontSize: 14)),
                ),
                // Hidden share card for screenshot
                Opacity(
                  opacity: 0,
                  child: Screenshot(
                    controller: _screenshot,
                    child: _ShareCard(result: _result),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── SCORE CIRCLE ──────────────────────────────────────────────────────────────

class _ScoreCircle extends StatelessWidget {
  final NewQuizResult result;
  final Color color;
  final Animation<double> animation;
  const _ScoreCircle(
      {required this.result, required this.color, required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (ctx, _) => CustomPaint(
        size: const Size(160, 160),
        painter: _ArcPainter(
          progress: animation.value * result.percentage,
          color: color,
        ),
        child: SizedBox(
          width: 160,
          height: 160,
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('${result.correctCount}/${result.totalQuestions}',
                  style: const TextStyle(
                      fontFamily: AppFonts.display,
                      height: 1.02,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.white)),
              const Text('correct',
                  style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 12,
                      color: Colors.white54)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double progress;
  final Color color;
  const _ArcPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    final bgPaint = Paint()
      ..color = const Color(0xFF2A2A2A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.progress != progress || old.color != color;
}

// ── POINTS CARD ───────────────────────────────────────────────────────────────

class _PointsCard extends StatelessWidget {
  final NewQuizResult result;
  const _PointsCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.emoji_events_rounded,
              color: AppColors.gold, size: 22),
          const SizedBox(width: 10),
          Text('${result.totalPoints} pts',
              style: const TextStyle(
                  fontFamily: AppFonts.display,
                  height: 1.02,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white)),
          if (result.speedBonusTotal > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text('+${result.speedBonusTotal} speed bonus',
                  style: const TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gold)),
            ),
          ],
        ],
      ),
    );
  }
}

// ── ANSWER REVIEW ─────────────────────────────────────────────────────────────

class _AnswerReview extends StatefulWidget {
  final NewQuizResult result;
  const _AnswerReview({required this.result});
  @override
  State<_AnswerReview> createState() => _AnswerReviewState();
}

class _AnswerReviewState extends State<_AnswerReview> {
  final Set<int> _expanded = {};

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Your Answers',
          style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white)),
      const SizedBox(height: 12),
      ...widget.result.questions.asMap().entries.map((e) {
        final i = e.key;
        final q = e.value;
        final answer =
            i < widget.result.answers.length ? widget.result.answers[i] : null;
        final isCorrect = answer == q.correctAnswerIndex;
        final isExpanded = _expanded.contains(i);

        return GestureDetector(
          onTap: () => setState(
              () => isExpanded ? _expanded.remove(i) : _expanded.add(i)),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isCorrect
                      ? AppColors.green.withValues(alpha: 0.3)
                      : AppColors.red.withValues(alpha: 0.3)),
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(
                  isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: isCorrect ? AppColors.green : AppColors.red,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(q.questionText,
                      style: const TextStyle(
                          fontFamily: AppFonts.body,
                          fontSize: 13,
                          color: Colors.white,
                          fontWeight: FontWeight.w600),
                      maxLines: isExpanded ? null : 1,
                      overflow: isExpanded ? null : TextOverflow.ellipsis),
                ),
                Icon(
                  isExpanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  color: Colors.white38,
                  size: 18,
                ),
              ]),
              if (!isCorrect) ...[
                const SizedBox(height: 6),
                Text('Correct: ${q.options[q.correctAnswerIndex]}',
                    style: const TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 11,
                        color: AppColors.green)),
              ],
              if (isExpanded) ...[
                const SizedBox(height: 10),
                Text(q.explanation,
                    style: const TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 12,
                        color: Colors.white60,
                        height: 1.5)),
              ],
            ]),
          ),
        );
      }),
    ]);
  }
}

// ── STREAK BANNER ─────────────────────────────────────────────────────────────

class _StreakBanner extends StatelessWidget {
  final int streak;
  const _StreakBanner({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        const Text('🔥', style: TextStyle(fontSize: 28)),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$streak day streak',
              style: const TextStyle(
                  fontFamily: AppFonts.display,
                  height: 1.02,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white)),
          const Text('Keep it up!',
              style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 12,
                  color: Colors.white54)),
        ]),
      ]),
    );
  }
}

// ── SHARE CARD ────────────────────────────────────────────────────────────────

class _ShareCard extends StatelessWidget {
  final NewQuizResult result;
  const _ShareCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final dots = List.generate(result.totalQuestions, (i) {
      final ans = i < result.answers.length ? result.answers[i] : null;
      final correct = ans == result.questions[i].correctAnswerIndex;
      return correct ? AppColors.green : AppColors.red;
    });

    return Container(
      width: 400,
      color: const Color(0xFF0D0D0D),
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('Briefed',
                style: TextStyle(
                    fontFamily: AppFonts.display,
                    height: 1.02,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white)),
            Text('.',
                style: TextStyle(
                    fontFamily: AppFonts.display,
                    height: 1.02,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.accent)),
          ]),
          const SizedBox(height: 24),
          Text('${result.correctCount}/${result.totalQuestions}',
              style: const TextStyle(
                  fontFamily: AppFonts.display,
                  height: 1.02,
                  fontSize: 64,
                  fontWeight: FontWeight.w900,
                  color: Colors.white)),
          Text(result.category.label,
              style: const TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 16,
                  color: Colors.white54)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: dots
                .map((c) => Container(
                      width: 18,
                      height: 18,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration:
                          BoxDecoration(color: c, shape: BoxShape.circle),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          Text('🏆 ${result.totalPoints} pts',
              style: const TextStyle(
                  fontFamily: AppFonts.display,
                  height: 1.02,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.gold)),
          const SizedBox(height: 24),
          const Text('briefedapp.com',
              style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 13,
                  color: Colors.white38)),
        ],
      ),
    );
  }
}
