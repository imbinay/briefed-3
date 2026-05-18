import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../news/models/news_category.dart';
import '../../news/providers/news_pipeline_provider.dart';
import '../models/quiz_result.dart';
import '../models/quiz_session.dart';
import '../services/quiz_generator_service.dart';

class NewQuizNotifier extends StateNotifier<QuizSession> {
  final Ref _ref;
  Timer? _questionTimer;
  Timer? _advanceTimer;

  NewQuizNotifier(this._ref) : super(const QuizSession());

  @override
  void dispose() {
    _questionTimer?.cancel();
    _advanceTimer?.cancel();
    super.dispose();
  }

  Future<void> startQuiz(NewsCategory category,
      {bool forceRefresh = false, bool isDailyMix = false}) async {
    _questionTimer?.cancel();
    _advanceTimer?.cancel();
    state = QuizSession(
        category: category,
        isDailyMix: isDailyMix,
        status: NewQuizStatus.loading);

    try {
      final pipeline = _ref.read(newsPipelineProvider);

      final questions = await QuizGeneratorService.generate(
        pipeline,
        forceRefresh: forceRefresh,
        category: isDailyMix ? null : category,
      );
      if (!mounted) return;

      if (questions.isEmpty) {
        state = state.copyWith(
          status: NewQuizStatus.error,
          error:
              'Not enough news articles to build a quiz right now. Pull to refresh the news feed and try again.',
        );
        return;
      }

      state = QuizSession(
        category: category,
        isDailyMix: isDailyMix,
        questions: questions,
        answers: List.filled(questions.length, null),
        secondsTaken: List.filled(questions.length, 0),
        speedBonuses: List.filled(questions.length, 0),
        timeLeft: 20,
        status: NewQuizStatus.active,
      );
      _startTimer();
    } catch (e) {
      dev.log('Quiz start failed: $e', name: 'Briefed/NewQuiz');
      if (!mounted) return;
      state = state.copyWith(status: NewQuizStatus.error, error: e.toString());
    }
  }

  void answerQuestion(int selectedIndex) {
    if (!mounted) return;
    if (state.status != NewQuizStatus.active) return;
    if (state.currentAnswer != null) return;

    _questionTimer?.cancel();

    final secondsTaken = 20 - state.timeLeft;
    final q = state.currentQuestion!;
    final isCorrect = selectedIndex == q.correctAnswerIndex;
    final bonus = isCorrect ? QuizSession.speedBonusFor(secondsTaken) : 0;
    final earned = isCorrect ? q.points + bonus : 0;

    final newAnswers = List<int?>.from(state.answers);
    newAnswers[state.currentIndex] = selectedIndex;
    final newTaken = List<int>.from(state.secondsTaken);
    newTaken[state.currentIndex] = secondsTaken;
    final newBonuses = List<int>.from(state.speedBonuses);
    newBonuses[state.currentIndex] = bonus;

    state = state.copyWith(
      answers: newAnswers,
      secondsTaken: newTaken,
      speedBonuses: newBonuses,
      totalPoints: state.totalPoints + earned,
      revealingExplanation: true,
      status: NewQuizStatus.revealed,
    );

    // Auto-advance after explanation window
    _advanceTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) _advance();
    });
  }

  void skipExplanation() {
    _advanceTimer?.cancel();
    _advance();
  }

  void _advance() {
    if (!mounted) return;
    final nextIndex = state.currentIndex + 1;
    if (nextIndex >= state.questions.length) {
      state = state.copyWith(
        status: NewQuizStatus.finished,
        revealingExplanation: false,
      );
      return;
    }
    state = state.copyWith(
      currentIndex: nextIndex,
      timeLeft: 20,
      status: NewQuizStatus.active,
      revealingExplanation: false,
    );
    _startTimer();
  }

  void _startTimer() {
    _questionTimer?.cancel();
    _questionTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (state.status != NewQuizStatus.active) {
        t.cancel();
        return;
      }
      if (state.timeLeft <= 1) {
        t.cancel();
        if (state.currentAnswer == null) answerQuestion(-1); // timeout
      } else {
        state = state.copyWith(timeLeft: state.timeLeft - 1);
      }
    });
  }

  NewQuizResult buildResult() {
    final questions = state.questions;
    final answers = state.answers;
    int base = 0;
    int bonus = 0;
    for (int i = 0; i < questions.length; i++) {
      if (i < answers.length && answers[i] == questions[i].correctAnswerIndex) {
        base += questions[i].points;
        if (i < state.speedBonuses.length) bonus += state.speedBonuses[i];
      }
    }
    return NewQuizResult(
      category: state.category ?? NewsCategory.world,
      correctCount: state.score,
      totalQuestions: questions.length,
      basePoints: base,
      speedBonusTotal: bonus,
      totalPoints: state.totalPoints,
      questions: questions,
      answers: answers,
      completedAt: DateTime.now(),
    );
  }

  void reset() {
    _questionTimer?.cancel();
    _advanceTimer?.cancel();
    state = const QuizSession();
  }
}

final newQuizProvider = StateNotifierProvider<NewQuizNotifier, QuizSession>(
  (ref) => NewQuizNotifier(ref),
);
