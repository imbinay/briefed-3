import 'dart:developer' as dev;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../news/models/news_category.dart';
import '../models/quiz_question.dart';

/// Reads pre-generated quiz questions from Firestore `quiz_cache/{key}`.
/// The Cloud Function regenerates these every ~6 hours alongside the news cache.
class FirestoreQuizService {
  static const _tag = 'Briefed/FirestoreQuiz';
  static const _collection = 'quiz_cache';

  // Daily mix is stored under "daily_mix"; category quizzes under category.name
  static const _maxCacheAge = Duration(hours: 8);

  static final _firestore = FirebaseFirestore.instance;

  /// [category] null = daily mix; non-null = category quiz
  static Future<List<QuizQuestion>?> fetchQuestions(
      NewsCategory? category) async {
    final key = category?.name ?? 'daily_mix';
    try {
      final doc = await _firestore
          .collection(_collection)
          .doc(key)
          .get()
          .timeout(const Duration(seconds: 8));

      if (!doc.exists) {
        dev.log('No server quiz cache for $key', name: _tag);
        return null;
      }

      final data = doc.data()!;
      final updatedAt = (data['updatedAt'] as Timestamp?)?.toDate();
      if (updatedAt == null) return null;

      final age = DateTime.now().difference(updatedAt);
      if (age > _maxCacheAge) {
        dev.log('$key quiz cache is ${age.inHours}h old — skipping', name: _tag);
        return null;
      }

      final rawList = data['questions'] as List<dynamic>? ?? [];
      final questions = rawList
          .whereType<Map<String, dynamic>>()
          .map(QuizQuestion.fromJson)
          .toList();

      if (questions.isEmpty) return null;

      dev.log(
          '$key: ${questions.length} questions from server cache '
          '(${age.inMinutes}m old)',
          name: _tag);
      return questions;
    } catch (e) {
      dev.log('Firestore quiz fetch failed for $key: $e', name: _tag);
      return null;
    }
  }
}
