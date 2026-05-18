import 'dart:developer' as dev;
import '../models/news_category.dart';
import '../models/ranked_article.dart';
import 'currents_news_service.dart';
import 'firestore_news_service.dart';
import 'guardian_news_service.dart';
import 'newsdata_news_service.dart';
import 'news_dedup_service.dart';
import 'news_source_config.dart';
import 'quiz_ability_scorer.dart';
import 'news_cache_service.dart';

class NewsPipelineService {
  static const _tag = 'Briefed/Pipeline';

  // ── PUBLIC PASSTHROUGH HELPERS (used by individual services) ─────────────

  static bool isApproved(String domain, NewsCategory category) =>
      NewsSourceConfig.isApproved(domain, category);

  static String displayName(String domain) =>
      NewsSourceConfig.displayName(domain);

  static int qualityScore(String domain) =>
      NewsSourceConfig.qualityScore(domain);

  // ── PIPELINE RESULT ───────────────────────────────────────────────────────

  /// Runs the full pipeline for a single category.
  /// Returns [display] (top 10) and [quiz] (top 5 quiz-able).
  static Future<CategoryResult> runCategory(
    NewsCategory category, {
    bool forceRefresh = false,
  }) async {
    // 1 — Serve local cache immediately if fresh
    if (!forceRefresh) {
      final cached = await NewsCacheService.load(category);
      if (cached != null && cached.isNotEmpty) {
        return _buildResult(category, cached, fromCache: true);
      }
    }

    // 2 — Try Firestore server cache (populated by Cloud Function every 2h)
    final serverArticles = await _safeFetch(
        'Firestore/${category.name}',
        () => FirestoreNewsService.fetchCategory(category));
    if (serverArticles.isNotEmpty) {
      await NewsCacheService.save(category, serverArticles);
      return _buildResult(category, serverArticles, fromCache: true);
    }

    // 3 — Fetch PRIMARY (Currents) + SECONDARY (Guardian) in parallel
    final futures = await Future.wait([
      _safeFetch('Currents/${category.name}',
          () => CurrentsNewsService.fetchCategory(category)),
      _safeFetch('Guardian/${category.name}',
          () => GuardianNewsService.fetchCategory(category)),
    ]);

    var combined = [...futures[0], ...futures[1]];

    // 3 — Deduplicate
    final deduped = NewsDedupService.deduplicate(combined);

    // 4 — Score quiz-ability
    var scored = deduped.map(QuizAbilityScorer.score).toList();

    // 5 — Discard articles older than 48 hours
    scored = scored
        .where((a) =>
            DateTime.now().difference(a.publishedAt).inHours < 48)
        .toList();

    // 6 — Check if fallback is needed (fewer than 5 quiz-able)
    final quizableCount = scored.where((a) => a.quizabilityPassed).length;
    if (quizableCount < 5) {
      dev.log(
          '${category.name}: only $quizableCount quiz-able → triggering NewsData fallback',
          name: _tag);
      final fallback = await _safeFetch('NewsData/${category.name}',
          () => NewsdataNewsService.fetchCategory(category));
      if (fallback.isNotEmpty) {
        final scoredFallback = fallback.map(QuizAbilityScorer.score).toList();
        final merged =
            NewsDedupService.deduplicate([...scored, ...scoredFallback]);
        scored = merged
            .where((a) =>
                DateTime.now().difference(a.publishedAt).inHours < 48)
            .toList();
      }
    }

    // 7 — Sort by finalScore descending
    scored.sort((a, b) => b.finalScore.compareTo(a.finalScore));

    // 8 — Cache and return
    if (scored.isNotEmpty) await NewsCacheService.save(category, scored);

    _debugLog(category, combined.length, deduped.length, scored);
    return _buildResult(category, scored);
  }

  static CategoryResult _buildResult(
    NewsCategory category,
    List<RankedArticle> ranked, {
    bool fromCache = false,
  }) {
    // Quality gate: Tier 3+ sources (score ≥ 60) or quiz-able articles only.
    // Falls back to unfiltered top-10 if the gate leaves fewer than 3 articles.
    var display = ranked
        .where((a) => a.sourceQualityScore >= 60 || a.quizabilityPassed)
        .take(10)
        .toList();
    if (display.length < 3) display = ranked.take(10).toList();

    final quiz = display.where((a) => a.quizabilityPassed).take(5).toList();
    return CategoryResult(
      category: category,
      display: display,
      quiz: quiz,
      fromCache: fromCache,
    );
  }

  /// Runs the pipeline for all 5 categories in parallel.
  static Future<Map<NewsCategory, CategoryResult>> runAll({
    bool forceRefresh = false,
  }) async {
    final results = await Future.wait(
      NewsCategory.values.map(
        (cat) => runCategory(cat, forceRefresh: forceRefresh),
      ),
    );
    return {for (final r in results) r.category: r};
  }

  static Future<List<RankedArticle>> _safeFetch(
    String label,
    Future<List<RankedArticle>> Function() fn,
  ) async {
    try {
      return await fn();
    } catch (e) {
      dev.log('$label fetch failed: $e', name: _tag);
      return [];
    }
  }

  static void _debugLog(
    NewsCategory category,
    int fetched,
    int afterDedup,
    List<RankedArticle> scored,
  ) {
    final quizable = scored.where((a) => a.quizabilityPassed).toList();
    final top5 = quizable.take(5).toList();
    final buf = StringBuffer();
    buf.writeln('Category: ${category.name.toUpperCase()}');
    buf.writeln('Stories fetched: $fetched');
    buf.writeln('After dedup: $afterDedup');
    buf.writeln('Quiz-able: ${quizable.length}');
    buf.writeln('Top 5 headlines:');
    for (int i = 0; i < top5.length; i++) {
      final a = top5[i];
      buf.writeln(
          '${i + 1}. ${a.title} | ${a.sourceName} | ${a.finalScore.toStringAsFixed(1)}');
    }
    dev.log(buf.toString(), name: _tag);
  }
}

class CategoryResult {
  final NewsCategory category;
  final List<RankedArticle> display; // top 10
  final List<RankedArticle> quiz; // top 5 quiz-able
  final bool fromCache;

  const CategoryResult({
    required this.category,
    required this.display,
    required this.quiz,
    this.fromCache = false,
  });
}
