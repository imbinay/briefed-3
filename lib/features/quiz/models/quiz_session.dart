import '../../news/models/news_category.dart';
import 'quiz_question.dart';

enum NewQuizStatus { idle, loading, active, revealed, finished, error }

class QuizSession {
  final NewsCategory? category;
  final bool isDailyMix;
  final List<QuizQuestion> questions;
  final int currentIndex;
  final List<int?> answers; // -1 = timeout, null = unanswered
  final List<int> secondsTaken;
  final List<int> speedBonuses;
  final int timeLeft;
  final NewQuizStatus status;
  final String? error;
  final int totalPoints;
  final bool revealingExplanation;

  const QuizSession({
    this.category,
    this.isDailyMix = false,
    this.questions = const [],
    this.currentIndex = 0,
    this.answers = const [],
    this.secondsTaken = const [],
    this.speedBonuses = const [],
    this.timeLeft = 10,
    this.status = NewQuizStatus.idle,
    this.error,
    this.totalPoints = 0,
    this.revealingExplanation = false,
  });

  QuizQuestion? get currentQuestion =>
      currentIndex < questions.length ? questions[currentIndex] : null;

  int? get currentAnswer =>
      currentIndex < answers.length ? answers[currentIndex] : null;

  bool get isAnswered => currentAnswer != null;

  int get score {
    int c = 0;
    for (int i = 0; i < answers.length && i < questions.length; i++) {
      if (answers[i] == questions[i].correctAnswerIndex) c++;
    }
    return c;
  }

  static int speedBonusFor(int secondsTaken) {
    if (secondsTaken < 3) return 10;
    if (secondsTaken <= 6) return 5;
    return 0;
  }

  QuizSession copyWith({
    NewsCategory? category,
    bool? isDailyMix,
    List<QuizQuestion>? questions,
    int? currentIndex,
    List<int?>? answers,
    List<int>? secondsTaken,
    List<int>? speedBonuses,
    int? timeLeft,
    NewQuizStatus? status,
    String? error,
    int? totalPoints,
    bool? revealingExplanation,
  }) =>
      QuizSession(
        category: category ?? this.category,
        isDailyMix: isDailyMix ?? this.isDailyMix,
        questions: questions ?? this.questions,
        currentIndex: currentIndex ?? this.currentIndex,
        answers: answers ?? this.answers,
        secondsTaken: secondsTaken ?? this.secondsTaken,
        speedBonuses: speedBonuses ?? this.speedBonuses,
        timeLeft: timeLeft ?? this.timeLeft,
        status: status ?? this.status,
        error: error,
        totalPoints: totalPoints ?? this.totalPoints,
        revealingExplanation: revealingExplanation ?? this.revealingExplanation,
      );
}
