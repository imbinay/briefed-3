import '../../news/models/news_category.dart';
import 'quiz_question.dart';

class NewQuizResult {
  final NewsCategory category;
  final int correctCount;
  final int totalQuestions;
  final int basePoints;
  final int speedBonusTotal;
  final int totalPoints;
  final List<QuizQuestion> questions;
  final List<int?> answers;
  final DateTime completedAt;

  const NewQuizResult({
    required this.category,
    required this.correctCount,
    required this.totalQuestions,
    required this.basePoints,
    required this.speedBonusTotal,
    required this.totalPoints,
    required this.questions,
    required this.answers,
    required this.completedAt,
  });

  double get percentage =>
      totalQuestions > 0 ? correctCount / totalQuestions : 0.0;

  String get scoreLabel {
    switch (correctCount) {
      case 5:  return 'Perfect! 🔥';
      case 4:  return 'Excellent! ⭐';
      case 3:  return 'Good Work 👍';
      case 2:  return 'Keep Going 📚';
      case 1:  return 'Try Again 💪';
      default: return "Don't Give Up 🧠";
    }
  }
}
