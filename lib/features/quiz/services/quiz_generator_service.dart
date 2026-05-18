import 'dart:developer' as dev;
import '../../news/models/news_category.dart';
import '../../news/models/ranked_article.dart';
import '../../news/providers/news_pipeline_provider.dart';
import '../models/quiz_question.dart';
import 'groq_question_service.dart';
import 'quiz_cache_service.dart';

class QuizGeneratorService {
  static const _tag = 'Briefed/QuizGen';

  // Articles with these keywords in the title are skipped
  static const _skipTitleKeywords = [
    'celebrity',
    'gossip',
    'rumour',
    'rumored',
    'fashion',
    'style',
    'outfit',
    'dressed',
    'dating',
    'relationship',
    'breakup',
    'divorce',
    'reality tv',
    'bachelor',
    'bachelorette',
    'according to sources',
    'sources say',
    'opinion:',
    'analysis:',
    'comment:',
    'column:',
    'opinion',
    'opinions',
    'editorial',
    'commentary',
    'environmental promise',
    'watch:',
    'listen:',
    'podcast:',
    'video:',
    'horoscope',
    'astrology',
    'obituary',
    'crossword',
    'puzzle',
    'recipe',
    'weather',
    'letter to the editor',
    'advertorial',
    'sponsored',
    'quiz:',
    'your daily',
    'ronda rousey',
    'wwe',
    'ufc fighter',
    'boxing match',
    'kardashian',
    'taylor swift',
  ];

  // Articles from these domains are skipped
  static const _skipDomains = [
    'tmz.com',
    'pagesix.com',
    'dailymail.co.uk',
    'eonline.com',
    'people.com',
    'usmagazine.com',
    'hollywoodlife.com',
    'reddit.com',
    'twitter.com',
    'x.com',
    'facebook.com',
    'instagram.com',
    'tiktok.com',
    'youtube.com',
  ];

  static const _difficultySlots = [
    QuestionDifficulty.easy,
    QuestionDifficulty.medium,
    QuestionDifficulty.hard,
    QuestionDifficulty.veryHard,
    QuestionDifficulty.expert,
  ];

  static const _difficultyOrder = {
    QuestionDifficulty.easy: 0,
    QuestionDifficulty.medium: 1,
    QuestionDifficulty.hard: 2,
    QuestionDifficulty.veryHard: 3,
    QuestionDifficulty.expert: 4,
  };

  static bool _shouldSkip(RankedArticle a) {
    if (a.summary.length < 100) {
      print(
          'SKIPPED: ${a.title} — summary too short (${a.summary.length} chars)');
      return true;
    }
    final title = a.title.toLowerCase();
    final domain = a.sourceDomain.toLowerCase();
    for (final d in _skipDomains) {
      if (domain.contains(d)) {
        print('SKIPPED: ${a.title} — domain blocked ($d)');
        return true;
      }
    }
    if (a.url.contains('/commentisfree/') || a.url.contains('/opinion/')) {
      print('SKIPPED: ${a.title} — opinion URL');
      return true;
    }
    for (final k in _skipTitleKeywords) {
      if (title.contains(k)) {
        print('SKIPPED: ${a.title} — title keyword ($k)');
        return true;
      }
    }
    return false;
  }

  /// Generates 5 quiz questions sorted easy → expert.
  /// When [category] is null: daily mix — one article per category (existing behaviour).
  /// When [category] is set: category quiz — up to 5 articles from that category only.
  /// Checks cache first; saves result to cache on fresh generation.
  static Future<List<QuizQuestion>> generate(
    PipelineState pipeline, {
    bool forceRefresh = false,
    NewsCategory? category,
  }) async {
    final cacheCategory = category ?? NewsCategory.world;

    if (!forceRefresh) {
      final cached = await QuizCacheService.load(cacheCategory);
      if (cached != null && cached.isNotEmpty) {
        dev.log('Serving cached quiz (${cached.length} Qs)', name: _tag);
        return cached;
      }
    }

    final articles = <RankedArticle>[];

    if (category != null) {
      // Category quiz — pick up to 5 articles from this category first
      final pool = (pipeline.byCategory[category] ?? [])
          .where((a) => a.quizabilityPassed && !_shouldSkip(a))
          .toList();

      if (pool.length < 3) {
        // Not enough quiz-able articles — fall back to any non-skipped in category
        final fallback = (pipeline.byCategory[category] ?? [])
            .where((a) => !_shouldSkip(a))
            .toList();
        articles.addAll(fallback.take(5));
      } else {
        articles.addAll(pool.take(5));
      }

      // Still short? Pad with quiz-able articles from other categories
      if (articles.length < 5) {
        dev.log(
          '${category.name}: only ${articles.length} articles — padding from other categories',
          name: _tag,
        );
        final usedIds = articles.map((a) => a.id).toSet();
        final extra = NewsCategory.values
            .where((c) => c != category)
            .expand((c) => pipeline.byCategory[c] ?? <RankedArticle>[])
            .where((a) =>
                a.quizabilityPassed &&
                !_shouldSkip(a) &&
                !usedIds.contains(a.id))
            .take(5 - articles.length)
            .toList();
        articles.addAll(extra);
        dev.log(
            'Added ${extra.length} cross-category fallback articles', name: _tag);
      }
    } else {
      // Daily mix — pick the best article from each category
      for (final cat in NewsCategory.values) {
        final pool = (pipeline.byCategory[cat] ?? [])
            .where((a) => a.quizabilityPassed && !_shouldSkip(a))
            .toList();

        if (pool.isNotEmpty) {
          articles.add(pool.first);
          dev.log(
            '✓ ${cat.name}: "${pool.first.title.substring(0, pool.first.title.length.clamp(0, 50))}"',
            name: _tag,
          );
        } else {
          // Fallback: any non-filtered article from this category
          final fallback = (pipeline.byCategory[cat] ?? [])
              .where((a) => !_shouldSkip(a))
              .toList();
          if (fallback.isNotEmpty) {
            articles.add(fallback.first);
            print('NO VALID ARTICLE for ${cat.name} using fallback');
            dev.log('⚠ ${cat.name}: fallback to non-quiz article', name: _tag);
          } else {
            print('NO VALID ARTICLE for ${cat.name} using fallback');
            dev.log('✗ ${cat.name}: no articles available', name: _tag);
          }
        }
      }
    }

    if (articles.isEmpty) {
      dev.log('No articles available for quiz', name: _tag);
      return [];
    }

    dev.log('Generating ${articles.length} questions in parallel…', name: _tag);

    final futures = articles.map(_generateSafe).toList();
    final results = await Future.wait(futures);
    var questions = results.whereType<QuizQuestion>().toList();

    // Not enough questions? Try additional fallback articles one by one
    if (questions.length < 5) {
      dev.log(
        'Only ${questions.length} questions — trying extra fallback articles',
        name: _tag,
      );
      final usedIds = articles.map((a) => a.id).toSet();
      final fallbackPool = pipeline.byCategory.values
          .expand((list) => list)
          .where((a) =>
              a.quizabilityPassed &&
              !_shouldSkip(a) &&
              !usedIds.contains(a.id))
          .toList();

      for (final fallback in fallbackPool) {
        if (questions.length >= 5) break;
        final q = await _generateSafe(fallback);
        if (q != null) questions.add(q);
      }
    }

    if (questions.isEmpty) {
      dev.log('No questions could be generated', name: _tag);
      return [];
    }

    // Sort by AI-assigned difficulty
    questions.sort((a, b) => (_difficultyOrder[a.difficulty] ?? 2)
        .compareTo(_difficultyOrder[b.difficulty] ?? 2));

    if (questions.length > 5) questions = questions.take(5).toList();

    // Guarantee difficulty progression easy → medium → hard → veryHard → expert
    if (questions.length == 5) {
      questions = List.generate(5, (i) {
        final slot = _difficultySlots[i];
        return questions[i].difficulty == slot
            ? questions[i]
            : questions[i].copyWith(difficulty: slot, points: slot.points);
      });
    }

    // Exactly 1 image question, must be at index 1, 2, or 3 (Q2–Q4)
    questions = _enforceImageSlot(questions);

    // Remove questions about the same story (same opening words or same correct answer)
    final seen = <String>{};
    questions = questions.where((q) {
      final words = q.questionText.toLowerCase().split(' ').take(5).join(' ');
      if (seen.contains(words)) return false;
      seen.add(words);
      final answer = q.options[q.correctAnswerIndex].toLowerCase();
      if (seen.contains('ans_$answer')) return false;
      seen.add('ans_$answer');
      return true;
    }).toList();

    if (category != null) {
      print('=== CATEGORY QUIZ: ${category.name.toUpperCase()} ===');
      print('Articles from ${category.name}: ${articles.length}');
      for (final a in articles) {
        print('  - ${a.title.substring(0, a.title.length.clamp(0, 50))}');
      }
    } else {
      print('=== DAILY MIX QUIZ ===');
      for (final a in articles) {
        print(
            '  - [${a.category.name}] ${a.title.substring(0, a.title.length.clamp(0, 40))}');
      }
    }
    print('=== QUIZ GENERATION ===');
    for (var i = 0; i < questions.length; i++) {
      final q = questions[i];
      print(
          'Q${i + 1}: ${q.articleTitle} | ${q.category.name} | ${q.difficulty.name} | ${q.points}pts');
      print('    Question: ${q.questionText}');
      print('    Correct: ${q.options[q.correctAnswerIndex]}');
      print('    Has image: ${q.hasImage}');
    }
    print('=== END ===');

    await QuizCacheService.save(cacheCategory, questions);
    return questions;
  }

  static Future<QuizQuestion?> _generateSafe(RankedArticle article) async {
    try {
      return await GroqQuestionService.generateForArticle(article);
    } catch (e) {
      dev.log(
        'Skipped "${article.title.substring(0, article.title.length.clamp(0, 40))}": $e',
        name: _tag,
      );
      return null;
    }
  }

  /// Keeps at most 1 image question (Q2–Q4 only), modifies its questionText
  /// to reference the image, and strips hasImage from all other questions.
  static List<QuizQuestion> _enforceImageSlot(List<QuizQuestion> qs) {
    int? chosen;
    for (var i = 1; i <= 3 && i < qs.length; i++) {
      final url = qs[i].imageUrl;
      if (qs[i].hasImage &&
          url != null &&
          url.isNotEmpty &&
          !url.toLowerCase().contains('none')) {
        chosen = i;
        break;
      }
    }
    return List.generate(qs.length, (i) {
      final q = qs[i];
      if (i == chosen) {
        final newText = switch (q.questionType) {
          QuestionType.who => 'Who is shown in this image?',
          QuestionType.what ||
          QuestionType.where =>
            'What does this image show?',
          QuestionType.which => 'Which country does this image relate to?',
          _ => q.questionText,
        };
        return q.copyWith(questionText: newText, hasImage: true);
      }
      return q.hasImage ? q.copyWith(hasImage: false) : q;
    });
  }
}
