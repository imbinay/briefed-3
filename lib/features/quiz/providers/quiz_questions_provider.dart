import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../news/models/news_category.dart';
import '../../news/providers/news_pipeline_provider.dart';
import '../models/quiz_question.dart';
import '../services/quiz_generator_service.dart';

/// Fetches (or generates) the 5-question set for the current news cycle.
/// Pass [NewsCategory.world] (or omit) for the daily mix (one per category).
/// Pass a specific category to get 5 questions from that category only.
final quizQuestionsProvider =
    FutureProvider.family<List<QuizQuestion>, NewsCategory>(
        (ref, category) async {
  final pipeline = ref.read(newsPipelineProvider);
  return QuizGeneratorService.generate(pipeline, category: category);
});

/// Force-regenerates questions, bypassing the daily cache.
final quizQuestionsRefreshProvider =
    FutureProvider.family<List<QuizQuestion>, NewsCategory>(
        (ref, category) async {
  final pipeline = ref.read(newsPipelineProvider);
  return QuizGeneratorService.generate(pipeline,
      forceRefresh: true, category: category);
});
