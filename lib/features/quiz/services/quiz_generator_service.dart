import 'dart:developer' as dev;
import '../../news/models/ranked_article.dart';
import '../../news/models/news_category.dart';
import '../models/quiz_question.dart';
import 'groq_question_service.dart';
import 'image_fetch_service.dart';
import 'quiz_cache_service.dart';

class QuizGeneratorService {
  static const _tag = 'Briefed/QuizGen';

  static const _difficultyOrder = {
    QuestionDifficulty.easy: 0,
    QuestionDifficulty.medium: 1,
    QuestionDifficulty.hard: 2,
    QuestionDifficulty.veryHard: 3,
    QuestionDifficulty.expert: 4,
  };

  static const _difficultySlots = [
    QuestionDifficulty.easy,
    QuestionDifficulty.medium,
    QuestionDifficulty.hard,
    QuestionDifficulty.veryHard,
    QuestionDifficulty.expert,
  ];

  /// Generates up to 5 quiz questions sorted easy → expert.
  /// Checks cache first; saves result to cache on fresh generation.
  static Future<List<QuizQuestion>> generate(
    List<RankedArticle> quizArticles,
    NewsCategory category, {
    bool forceRefresh = false,
  }) async {
    // if (!forceRefresh) {
    //   final cached = await QuizCacheService.load(category);
    //   if (cached != null && cached.length >= 3) {
    //     dev.log('${category.name}: serving cached quiz (${cached.length} Qs)', name: _tag);
    //     return cached;
    //   }
    // }
    print("=== BYPASSING CACHE - GENERATING FRESH ===");

    final articles = quizArticles.take(5).toList();
    if (articles.isEmpty) {
      throw Exception('QUIZ ERROR: No quiz articles for ${category.name}');
    }

    dev.log('${category.name}: generating ${articles.length} questions', name: _tag);

    final futures = articles.map(_generateSafe).toList();
    final results = await Future.wait(futures);
    var questions = results.whereType<QuizQuestion>().toList();

    if (questions.length < 3) {
      dev.log('QUIZ ERROR: Only ${questions.length} questions generated — need at least 3',
          name: _tag);
      if (questions.isEmpty) {
        throw Exception(
            'QUIZ ERROR: Failed to generate any questions for ${category.name}');
      }
      return questions;
    }

    // Enrich with Unsplash images for imageless articles
    questions = await _enrichImages(questions);

    // Sort by difficulty
    questions.sort((a, b) =>
        (_difficultyOrder[a.difficulty] ?? 2)
            .compareTo(_difficultyOrder[b.difficulty] ?? 2));

    if (questions.length > 5) questions = questions.take(5).toList();

    // Guarantee difficulty progression (easy→medium→hard→veryHard→expert)
    questions = _reassignDifficulties(questions);

    // Image questions only at Q2, Q3, Q4; max 2
    questions = _enforceImageSlots(questions);

    // Rewrite questionText for image questions (who/what/where only)
    questions = _applyImageQuestionText(questions);

    await QuizCacheService.save(category, questions);
    dev.log('${category.name}: quiz ready (${questions.length} Qs)', name: _tag);
    return questions;
  }

  static Future<QuizQuestion?> _generateSafe(RankedArticle article) async {
    try {
      return await GroqQuestionService.generateForArticle(article);
    } catch (e) {
      dev.log(
          'QUIZ ERROR: Skipped "${article.title.substring(0, article.title.length.clamp(0, 40))}": $e',
          name: _tag);
      return null;
    }
  }

  static Future<List<QuizQuestion>> _enrichImages(List<QuizQuestion> questions) async {
    final enriched = <QuizQuestion>[];
    for (final q in questions) {
      if (q.hasImage) {
        enriched.add(q);
        continue;
      }
      try {
        final url = await ImageFetchService.fetchForQuery(q.articleTitle);
        enriched.add(url != null ? q.copyWith(imageUrl: url, hasImage: true) : q);
      } catch (e) {
        dev.log('QUIZ ERROR: Unsplash fetch failed for "${q.articleTitle}": $e', name: _tag);
        enriched.add(q);
      }
    }
    return enriched;
  }

  static List<QuizQuestion> _reassignDifficulties(List<QuizQuestion> qs) {
    if (qs.length != 5) return qs;
    return List.generate(5, (i) {
      final slot = _difficultySlots[i];
      return qs[i].difficulty == slot
          ? qs[i]
          : qs[i].copyWith(difficulty: slot, points: slot.points);
    });
  }

  static List<QuizQuestion> _enforceImageSlots(List<QuizQuestion> qs) {
    int imageCount = 0;
    return List.generate(qs.length, (i) {
      final q = qs[i];
      if (!q.hasImage) return q;
      // Q1 (i=0) and Q5 (i=4) never get images
      if (i == 0 || i == 4) return q.copyWith(hasImage: false);
      if (imageCount >= 2) return q.copyWith(hasImage: false);
      imageCount++;
      return q;
    });
  }

  /// Rewrites questionText for image questions whose type is who/what/where.
  static List<QuizQuestion> _applyImageQuestionText(List<QuizQuestion> qs) {
    return qs.map((q) {
      if (!q.hasImage) return q;
      final newText = switch (q.questionType) {
        QuestionType.who   => 'Who is pictured in this photo?',
        QuestionType.what  => 'What event is shown in this image?',
        QuestionType.where => 'Which country does this scene relate to?',
        _                  => null,
      };
      return newText != null ? q.copyWith(questionText: newText) : q;
    }).toList();
  }
}
