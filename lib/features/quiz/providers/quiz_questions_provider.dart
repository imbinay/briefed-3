import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../news/models/news_category.dart';
import '../../news/providers/news_pipeline_provider.dart';
import '../models/quiz_question.dart';
import '../services/quiz_cache_service.dart';
import '../services/quiz_generator_service.dart';

/// Fetches (or generates) the 5-question set for a given category.
///
/// Usage:
///   final questions = await ref.read(quizQuestionsProvider(category).future);
///
/// The provider checks the daily cache first; generates fresh questions
/// only when no valid cache exists for today.
final quizQuestionsProvider =
    FutureProvider.family<List<QuizQuestion>, NewsCategory>((ref, category) async {
  // Serve from cache if available
  final cached = await QuizCacheService.load(category);
  if (cached != null && cached.length >= 3) return cached;

  // Generate fresh questions via the news pipeline
  final pipeline = ref.read(newsPipelineProvider);
  final articles = pipeline.getQuizStories(category);
  if (articles.isEmpty) {
    throw Exception(
        'QUIZ ERROR: No quiz articles available for ${category.name}. '
        'Refresh the news feed and try again.');
  }

  return QuizGeneratorService.generate(articles, category);
});

/// Force-regenerates questions for a category, bypassing the daily cache.
final quizQuestionsRefreshProvider =
    FutureProvider.family<List<QuizQuestion>, NewsCategory>((ref, category) async {
  await QuizCacheService.invalidate(category);
  final pipeline = ref.read(newsPipelineProvider);
  final articles = pipeline.getQuizStories(category);
  if (articles.isEmpty) {
    throw Exception(
        'QUIZ ERROR: No quiz articles available for ${category.name}.');
  }
  return QuizGeneratorService.generate(articles, category, forceRefresh: true);
});
