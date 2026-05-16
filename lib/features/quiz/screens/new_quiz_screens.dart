import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/theme.dart';
import '../../../models/models.dart';
import '../../../providers/providers.dart';
import '../../news/models/news_category.dart';
import '../models/quiz_question.dart';
import '../models/quiz_result.dart';
import '../models/quiz_session.dart';
import '../providers/new_quiz_provider.dart';

// ── CATEGORY SELECT ───────────────────────────────────────────────────────────

class CategorySelectScreen extends ConsumerWidget {
  const CategorySelectScreen({super.key});

  static const _cats = [
    NewsCategory.world,
    NewsCategory.politics,
    NewsCategory.sports,
    NewsCategory.technology,
    NewsCategory.business,
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
            style: GoogleFonts.dmSans(
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
                  style: GoogleFonts.dmSans(
                      fontSize: 14, color: context.subColor)),
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

  Color _color() {
    switch (category) {
      case NewsCategory.world:      return AppColors.blue;
      case NewsCategory.politics:   return AppColors.purple;
      case NewsCategory.sports:     return AppColors.green;
      case NewsCategory.technology: return AppColors.teal;
      case NewsCategory.business:   return AppColors.orange;
    }
  }

  IconData _icon() {
    switch (category) {
      case NewsCategory.world:      return Icons.language_rounded;
      case NewsCategory.politics:   return Icons.account_balance_rounded;
      case NewsCategory.sports:     return Icons.sports_rounded;
      case NewsCategory.technology: return Icons.memory_rounded;
      case NewsCategory.business:   return Icons.trending_up_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = _color();
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed('/quiz/intro',
            arguments: {'category': category});
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
                color: c.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Row(children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_icon(), color: c, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(category.label,
                  style: GoogleFonts.dmSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: context.textColor)),
              const SizedBox(height: 3),
              Text('5 questions · Easy → Expert',
                  style: GoogleFonts.dmSans(
                      fontSize: 12, color: context.hintColor)),
            ]),
          ),
          Icon(Icons.arrow_forward_ios_rounded,
              size: 16, color: context.hintColor),
        ]),
      ),
    );
  }
}

// ── QUIZ INTRO ────────────────────────────────────────────────────────────────

class QuizIntroScreen extends ConsumerWidget {
  const QuizIntroScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map? ?? {};
    final category = args['category'] as NewsCategory? ?? NewsCategory.world;

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
                  color: c.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(_catIcon(category), color: c, size: 48),
              ),
              const SizedBox(height: 28),
              Text(category.label,
                  style: GoogleFonts.dmSans(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: context.textColor)),
              const SizedBox(height: 10),
              Text('5 Questions · ~2 mins',
                  style: GoogleFonts.dmSans(
                      fontSize: 15, color: context.subColor)),
              const SizedBox(height: 6),
              Text('Easy → Expert',
                  style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: c)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.borderColor),
                ),
                child: Row(children: [
                  const Icon(Icons.bolt_rounded, color: AppColors.gold, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Answer fast for speed bonus points',
                        style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: context.subColor,
                            height: 1.4)),
                  ),
                ]),
              ),
              const SizedBox(height: 20),
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
                        .startQuiz(category);
                    Navigator.of(context).pushReplacementNamed('/quiz/play');
                  },
                  child: Text('Tap to Start',
                      style: GoogleFonts.dmSans(
                          fontSize: 17, fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Back',
                    style: GoogleFonts.dmSans(
                        color: context.hintColor, fontSize: 14)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _catColor(NewsCategory c) {
    switch (c) {
      case NewsCategory.world:      return AppColors.blue;
      case NewsCategory.politics:   return AppColors.purple;
      case NewsCategory.sports:     return AppColors.green;
      case NewsCategory.technology: return AppColors.teal;
      case NewsCategory.business:   return AppColors.orange;
    }
  }

  IconData _catIcon(NewsCategory c) {
    switch (c) {
      case NewsCategory.world:      return Icons.language_rounded;
      case NewsCategory.politics:   return Icons.account_balance_rounded;
      case NewsCategory.sports:     return Icons.sports_rounded;
      case NewsCategory.technology: return Icons.memory_rounded;
      case NewsCategory.business:   return Icons.trending_up_rounded;
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
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;
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

    _scaleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _scaleAnim =
        CurvedAnimation(parent: _scaleCtrl, curve: Curves.elasticOut);

    _ptsCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _ptsAnim = CurvedAnimation(parent: _ptsCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    _flashCtrl.dispose();
    _scaleCtrl.dispose();
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
      _scaleCtrl.forward(from: 0);
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

    // Navigate away when finished
    ref.listen<QuizSession>(newQuizProvider, (prev, next) {
      if (prev == null) return;
      // Trigger animations when answer is revealed
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
      body: SafeArea(
        child: _buildBody(context, session),
      ),
    );
  }

  Widget _buildBody(BuildContext context, QuizSession session) {
    if (session.status == NewQuizStatus.loading) {
      return _buildLoading(context, session.category);
    }
    if (session.status == NewQuizStatus.error) {
      return _buildError(context, session);
    }
    if (session.questions.isEmpty) {
      return _buildLoading(context, session.category);
    }

    final q = session.currentQuestion!;
    final answer = session.currentAnswer;
    final revealed = session.status == NewQuizStatus.revealed ||
        session.revealingExplanation;

    return Stack(children: [
      Column(children: [
        _ProgressBar(session: session),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Points + question counter row
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        '${session.totalPoints} pts',
                        key: ValueKey(session.totalPoints),
                        style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.gold),
                      ),
                    ),
                    const Spacer(),
                    _DifficultyBadge(difficulty: q.difficulty),
                  ]),
                ),
                _QuestionCard(question: q, session: session),
                const SizedBox(height: 16),
                // Answer options
                ...q.options.asMap().entries.map((e) {
                  final idx = e.key;
                  final text = e.value;
                  final isSelected = answer == idx;
                  final isCorrect = idx == q.correctAnswerIndex;
                  final isWrong = revealed && isSelected && !isCorrect;

                  Widget option = _OptionCard(
                    index: idx,
                    text: text,
                    isSelected: isSelected,
                    isCorrect: isCorrect,
                    isRevealed: revealed,
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
                          offset: Offset(_shakeAnim.value, 0),
                          child: child),
                      child: option,
                    );
                  }

                  if (isSelected && !isWrong) {
                    option = ScaleTransition(
                        scale: Tween<double>(begin: 1.0, end: 1.02)
                            .animate(_scaleAnim),
                        child: option);
                  }

                  return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: option);
                }),
                // Timer bar
                _TimerBar(timeLeft: session.timeLeft, revealed: revealed),
                // Explanation card
                if (revealed) ...[
                  const SizedBox(height: 12),
                  _ExplanationCard(question: q, session: session),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      onPressed: () => ref
                          .read(newQuizProvider.notifier)
                          .skipExplanation(),
                      child: Text(
                        session.currentIndex + 1 >=
                                session.questions.length
                            ? 'See Results'
                            : 'Next Question',
                        style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ]),
      // Screen colour flash
      IgnorePointer(
        child: AnimatedBuilder(
          animation: _flashAnim,
          builder: (ctx, _) => Container(
            color: _flashColor.withValues(
                alpha: _flashAnim.value * 0.15),
          ),
        ),
      ),
      // Floating "+X pts"
      if (_lastPts > 0)
        Positioned(
          bottom: 240,
          left: 0,
          right: 0,
          child: AnimatedBuilder(
            animation: _ptsAnim,
            builder: (ctx, _) => Opacity(
              opacity: (1 - _ptsAnim.value).clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, -60 * _ptsAnim.value),
                child: Center(
                  child: Text(
                    '+$_lastPts pts',
                    style: GoogleFonts.dmSans(
                        fontSize: 26,
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

  Widget _buildLoading(BuildContext context, NewsCategory? category) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const CircularProgressIndicator(color: AppColors.accent),
        const SizedBox(height: 20),
        Text(
          'Generating ${category?.label ?? ''} quiz…',
          style: GoogleFonts.dmSans(
              fontSize: 15, color: Colors.white70),
        ),
        const SizedBox(height: 8),
        Text('Powered by AI',
            style: GoogleFonts.dmSans(
                fontSize: 12, color: Colors.white38)),
      ]),
    );
  }

  Widget _buildError(BuildContext context, QuizSession session) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.red, size: 56),
          const SizedBox(height: 16),
          Text('Quiz failed to load',
              style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
          const SizedBox(height: 10),
          Text(session.error ?? '',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                  fontSize: 13, color: Colors.white54)),
          const SizedBox(height: 24),
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
            child: Text('Try Again',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(context).popUntil((r) => r.isFirst),
            child: Text('Go Home',
                style:
                    GoogleFonts.dmSans(color: Colors.white54)),
          ),
        ]),
      ),
    );
  }
}

// ── PROGRESS BAR ──────────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  final QuizSession session;
  const _ProgressBar({required this.session});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: List.generate(session.questions.length, (i) {
          final isCurrent = i == session.currentIndex &&
              session.status != NewQuizStatus.finished;
          final answer =
              i < session.answers.length ? session.answers[i] : null;
          final isAnswered = answer != null;
          final isCorrect = isAnswered &&
              answer == session.questions[i].correctAnswerIndex;

          Color color;
          if (!isAnswered && !isCurrent) {
            color = const Color(0xFF2A2A2A);
          } else if (isCurrent) {
            color = AppColors.accent;
          } else if (isCorrect) {
            color = AppColors.green;
          } else {
            color = AppColors.red;
          }

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < 4 ? 6 : 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 5,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── DIFFICULTY BADGE ─────────────────────────────────────────────────────────

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
        style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: c,
            letterSpacing: 0.3),
      ),
    );
  }
}

// ── QUESTION CARD ─────────────────────────────────────────────────────────────

class _QuestionCard extends StatelessWidget {
  final QuizQuestion question;
  final QuizSession session;
  const _QuestionCard({required this.question, required this.session});

  Color _catColor() {
    switch (question.category) {
      case NewsCategory.world:      return AppColors.blue;
      case NewsCategory.politics:   return AppColors.purple;
      case NewsCategory.sports:     return AppColors.green;
      case NewsCategory.technology: return AppColors.teal;
      case NewsCategory.business:   return AppColors.orange;
    }
  }

  IconData _catIcon() {
    switch (question.category) {
      case NewsCategory.world:      return Icons.language_rounded;
      case NewsCategory.politics:   return Icons.account_balance_rounded;
      case NewsCategory.sports:     return Icons.sports_rounded;
      case NewsCategory.technology: return Icons.memory_rounded;
      case NewsCategory.business:   return Icons.trending_up_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final catColor = _catColor();

    if (question.hasImage && question.imageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.network(
              question.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: catColor.withValues(alpha: 0.2),
                child: Icon(_catIcon(), color: catColor, size: 48),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.85),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(question.questionText,
                    style: GoogleFonts.dmSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Text('Source: ${question.articleSourceName}',
                    style: GoogleFonts.dmSans(
                        fontSize: 11, color: Colors.white60)),
              ],
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: catColor.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text('${question.points} pts',
                  style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
            ),
          ),
        ]),
      );
    }

    // Text-only card
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(children: [
        Icon(_catIcon(),
            size: 48, color: catColor.withValues(alpha: 0.7)),
        const SizedBox(height: 16),
        Text(
          question.questionText,
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.4),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('Source: ${question.articleSourceName}',
              style: GoogleFonts.dmSans(
                  fontSize: 11, color: Colors.white38)),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: catColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text('${question.points} pts',
                style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: catColor)),
          ),
        ]),
      ]),
    );
  }
}

// ── OPTION CARD ───────────────────────────────────────────────────────────────

class _OptionCard extends StatelessWidget {
  final int index;
  final String text;
  final bool isSelected;
  final bool isCorrect;
  final bool isRevealed;
  final VoidCallback? onTap;

  const _OptionCard({
    required this.index,
    required this.text,
    required this.isSelected,
    required this.isCorrect,
    required this.isRevealed,
    required this.onTap,
  });

  static const _labels = ['A', 'B', 'C', 'D'];

  Color _bg() {
    if (!isRevealed) return const Color(0xFF1E1E1E);
    if (isCorrect) return AppColors.green.withValues(alpha: 0.15);
    if (isSelected) return AppColors.red.withValues(alpha: 0.15);
    return const Color(0xFF1E1E1E);
  }

  Color _border() {
    if (!isRevealed) {
      return isSelected ? AppColors.accent : const Color(0xFF333333);
    }
    if (isCorrect) return AppColors.green;
    if (isSelected) return AppColors.red;
    return const Color(0xFF2A2A2A);
  }

  @override
  Widget build(BuildContext context) {
    final label = _labels[index];
    final iconOverride = isRevealed
        ? (isCorrect
            ? Icons.check_rounded
            : (isSelected ? Icons.close_rounded : null))
        : null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: _bg(),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border()),
        ),
        child: Row(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isRevealed && isCorrect
                  ? AppColors.green
                  : isRevealed && isSelected
                      ? AppColors.red
                      : const Color(0xFF2A2A2A),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: iconOverride != null
                  ? Icon(iconOverride, size: 14, color: Colors.white)
                  : Text(label,
                      style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white60)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.dmSans(
                  fontSize: 15,
                  color: isRevealed && !isCorrect && !isSelected
                      ? Colors.white38
                      : Colors.white,
                  fontWeight: isCorrect && isRevealed
                      ? FontWeight.w700
                      : FontWeight.w500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ]),
      ),
    );
  }
}

// ── TIMER BAR ─────────────────────────────────────────────────────────────────

class _TimerBar extends StatelessWidget {
  final int timeLeft;
  final bool revealed;
  const _TimerBar({required this.timeLeft, required this.revealed});

  Color _color() {
    if (revealed) return AppColors.green;
    if (timeLeft > 6) return AppColors.orange;
    if (timeLeft > 3) return AppColors.gold;
    return AppColors.red;
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    final progress = revealed ? 0.0 : (timeLeft / 10).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 800),
          height: 3,
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0xFF2A2A2A),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ),
    );
  }
}

// ── EXPLANATION CARD ──────────────────────────────────────────────────────────

class _ExplanationCard extends StatelessWidget {
  final QuizQuestion question;
  final QuizSession session;
  const _ExplanationCard({required this.question, required this.session});

  @override
  Widget build(BuildContext context) {
    final answer = session.currentAnswer;
    final isCorrect = answer == question.correctAnswerIndex;
    final color = isCorrect ? AppColors.green : AppColors.red;
    final label = isCorrect ? 'Correct!' : 'Not quite';

    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(
            isCorrect
                ? Icons.check_circle_rounded
                : Icons.info_outline_rounded,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(label,
              style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: color)),
          if (!isCorrect) ...[
            const Spacer(),
            Text('Correct: ${question.options[question.correctAnswerIndex]}',
                style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: AppColors.green,
                    fontWeight: FontWeight.w600)),
          ],
        ]),
        const SizedBox(height: 10),
        Text(question.explanation,
            style: GoogleFonts.dmSans(
                fontSize: 13, color: Colors.white70, height: 1.6)),
      ]),
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
    _entryAnim =
        CurvedAnimation(parent: _entryCtrl, curve: Curves.elasticOut);

    _arcCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _arcAnim = CurvedAnimation(parent: _arcCtrl, curve: Curves.easeOut);

    _confetti =
        ConfettiController(duration: const Duration(seconds: 4));

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

    final legacy = QuizResult(
      date: DateTime.now().toIso8601String().substring(0, 10),
      score: _result.correctCount,
      totalQuestions: _result.totalQuestions,
      pointsEarned: _result.totalPoints,
      timeTakenSeconds: 0,
      categories: [_result.category.name],
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
                    result: _result,
                    color: color,
                    animation: _arcAnim),
                const SizedBox(height: 12),
                Text(_result.scoreLabel,
                    style: GoogleFonts.dmSans(
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
                    label: Text('Share My Score',
                        style: GoogleFonts.dmSans(
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
                        side: const BorderSide(
                            color: Color(0xFF333333)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        ref.read(newQuizProvider.notifier).reset();
                        Navigator.of(context)
                            .pushReplacementNamed('/quiz/select');
                      },
                      child: Text('Play Again',
                          style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(
                            color: Color(0xFF333333)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () =>
                          Navigator.of(context).pushNamed('/hot-take'),
                      child: Text('Try Hot Take',
                          style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(context)
                      .pushNamedAndRemoveUntil('/home', (_) => false),
                  child: Text('Back to Home',
                      style: GoogleFonts.dmSans(
                          color: Colors.white38, fontSize: 14)),
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
      {required this.result,
      required this.color,
      required this.animation});

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
                  style: GoogleFonts.dmSans(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.white)),
              Text('correct',
                  style: GoogleFonts.dmSans(
                      fontSize: 12, color: Colors.white54)),
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
              style: GoogleFonts.dmSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white)),
          if (result.speedBonusTotal > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text('+${result.speedBonusTotal} speed bonus',
                  style: GoogleFonts.dmSans(
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
      Text('Your Answers',
          style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white)),
      const SizedBox(height: 12),
      ...widget.result.questions.asMap().entries.map((e) {
        final i = e.key;
        final q = e.value;
        final answer = i < widget.result.answers.length
            ? widget.result.answers[i]
            : null;
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
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(
                      isCorrect
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      color: isCorrect ? AppColors.green : AppColors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(q.questionText,
                          style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: Colors.white,
                              fontWeight: FontWeight.w600),
                          maxLines: isExpanded ? null : 1,
                          overflow: isExpanded
                              ? null
                              : TextOverflow.ellipsis),
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
                    Text(
                        'Correct: ${q.options[q.correctAnswerIndex]}',
                        style: GoogleFonts.dmSans(
                            fontSize: 11, color: AppColors.green)),
                  ],
                  if (isExpanded) ...[
                    const SizedBox(height: 10),
                    Text(q.explanation,
                        style: GoogleFonts.dmSans(
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
              style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white)),
          Text('Keep it up!',
              style: GoogleFonts.dmSans(
                  fontSize: 12, color: Colors.white54)),
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
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('Briefed',
                style: GoogleFonts.dmSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white)),
            Text('.',
                style: GoogleFonts.dmSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.accent)),
          ]),
          const SizedBox(height: 24),
          Text('${result.correctCount}/${result.totalQuestions}',
              style: GoogleFonts.dmSans(
                  fontSize: 64,
                  fontWeight: FontWeight.w900,
                  color: Colors.white)),
          Text(result.category.label,
              style: GoogleFonts.dmSans(
                  fontSize: 16, color: Colors.white54)),
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
              style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.gold)),
          const SizedBox(height: 24),
          Text('briefedapp.com',
              style: GoogleFonts.dmSans(
                  fontSize: 13, color: Colors.white38)),
        ],
      ),
    );
  }
}
