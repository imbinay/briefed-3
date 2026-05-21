import 'package:flutter/material.dart';
import '../../news/models/news_category.dart';

enum QuestionType { who, what, when, where, which, howMany, howMuch }

enum QuestionDifficulty {
  easy,
  medium,
  hard,
  veryHard,
  expert;

  int get points {
    switch (this) {
      case easy:
        return 10;
      case medium:
        return 20;
      case hard:
        return 30;
      case veryHard:
        return 40;
      case expert:
        return 50;
    }
  }

  String get label {
    switch (this) {
      case easy:
        return 'Easy';
      case medium:
        return 'Medium';
      case hard:
        return 'Hard';
      case veryHard:
        return 'Very Hard';
      case expert:
        return 'Expert';
    }
  }

  Color get color {
    switch (this) {
      case easy:
        return const Color(0xFF00C853);
      case medium:
        return const Color(0xFFFFD600);
      case hard:
        return const Color(0xFFFF9100);
      case veryHard:
        return const Color(0xFFFF1744);
      case expert:
        return const Color(0xFF7C4DFF);
    }
  }

  static QuestionDifficulty fromString(String s) {
    switch (s.toLowerCase().replaceAll(' ', '').replaceAll('_', '')) {
      case 'easy':
        return easy;
      case 'medium':
        return medium;
      case 'hard':
        return hard;
      case 'veryhard':
        return veryHard;
      case 'expert':
        return expert;
      default:
        return medium;
    }
  }
}

class QuizQuestion {
  final String id;
  final String articleId;
  final String articleTitle;
  final String articleSummary;
  final String articleSourceName;
  final String questionText;
  final QuestionType questionType;
  final List<String> options;
  final int correctAnswerIndex;
  final String explanation;
  final QuestionDifficulty difficulty;
  final int points;
  final String? imageUrl;
  final bool hasImage;
  final NewsCategory category;
  final DateTime generatedAt;

  const QuizQuestion({
    required this.id,
    required this.articleId,
    required this.articleTitle,
    required this.articleSummary,
    required this.articleSourceName,
    required this.questionText,
    required this.questionType,
    required this.options,
    required this.correctAnswerIndex,
    required this.explanation,
    required this.difficulty,
    required this.points,
    this.imageUrl,
    required this.hasImage,
    required this.category,
    required this.generatedAt,
  });

  QuizQuestion copyWith({
    String? questionText,
    String? imageUrl,
    bool? hasImage,
    QuestionDifficulty? difficulty,
    int? points,
  }) =>
      QuizQuestion(
        id: id,
        articleId: articleId,
        articleTitle: articleTitle,
        articleSummary: articleSummary,
        articleSourceName: articleSourceName,
        questionText: questionText ?? this.questionText,
        questionType: questionType,
        options: options,
        correctAnswerIndex: correctAnswerIndex,
        explanation: explanation,
        difficulty: difficulty ?? this.difficulty,
        points: points ?? this.points,
        imageUrl: imageUrl ?? this.imageUrl,
        hasImage: hasImage ?? this.hasImage,
        category: category,
        generatedAt: generatedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'articleId': articleId,
        'articleTitle': articleTitle,
        'articleSummary': articleSummary,
        'articleSourceName': articleSourceName,
        'questionText': questionText,
        'questionType': questionType.name,
        'options': options,
        'correctAnswerIndex': correctAnswerIndex,
        'explanation': explanation,
        'difficulty': difficulty.name,
        'points': points,
        if (imageUrl != null) 'imageUrl': imageUrl,
        'hasImage': hasImage,
        'category': category.name,
        'generatedAt': generatedAt.toIso8601String(),
      };

  factory QuizQuestion.fromJson(Map<String, dynamic> j) => QuizQuestion(
        id: j['id'] as String,
        articleId: j['articleId'] as String,
        articleTitle: j['articleTitle'] as String,
        articleSummary: j['articleSummary'] as String? ?? '',
        articleSourceName: j['articleSourceName'] as String,
        questionText: j['questionText'] as String,
        questionType: QuestionType.values.firstWhere(
          (t) => t.name == j['questionType'],
          orElse: () => QuestionType.what,
        ),
        options: List<String>.from(j['options'] as List),
        correctAnswerIndex: (j['correctAnswerIndex'] as num).toInt(),
        explanation: j['explanation'] as String? ?? '',
        difficulty: QuestionDifficulty.fromString(
            j['difficulty'] as String? ?? 'medium'),
        points: (j['points'] as num).toInt(),
        imageUrl: j['imageUrl'] as String?,
        hasImage: j['hasImage'] as bool? ?? false,
        category: NewsCategory.fromString(j['category'] as String? ?? '') ??
            NewsCategory.world,
        generatedAt: DateTime.tryParse(j['generatedAt'] as String? ?? '') ??
            DateTime.now(),
      );
}
