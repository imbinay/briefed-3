import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/news_category.dart';
import '../models/ranked_article.dart';
import '../services/currents_news_service.dart';
import '../services/news_cache_service.dart';
import '../services/news_pipeline_service.dart';

// ── STATE ─────────────────────────────────────────────────────────────────────

class PipelineState {
  final Map<NewsCategory, List<RankedArticle>> byCategory;
  final bool isLoading;
  final String? error;
  final DateTime? updatedAt;

  const PipelineState({
    this.byCategory = const {},
    this.isLoading = true,
    this.error,
    this.updatedAt,
  });

  PipelineState copyWith({
    Map<NewsCategory, List<RankedArticle>>? byCategory,
    bool? isLoading,
    String? error,
    DateTime? updatedAt,
  }) =>
      PipelineState(
        byCategory: byCategory ?? this.byCategory,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  /// Top 10 display articles for a specific category.
  List<RankedArticle> getTopStoriesForDisplay(NewsCategory cat) =>
      byCategory[cat] ?? [];

  /// Top 5 quiz-able articles for a specific category.
  List<RankedArticle> getQuizStories(NewsCategory cat) =>
      (byCategory[cat] ?? [])
          .where((a) => a.quizabilityPassed)
          .take(5)
          .toList();

  /// "For You" feed — top 2 from each category, sorted newest-first, max 10.
  List<RankedArticle> get forYouStories {
    final all = NewsCategory.values
        .expand((cat) => (byCategory[cat] ?? []).take(2))
        .toList();
    all.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    return all.take(10).toList();
  }
}

// ── NOTIFIER ──────────────────────────────────────────────────────────────────

class PipelineNotifier extends StateNotifier<PipelineState> {
  Timer? _autoRefreshTimer;

  PipelineNotifier() : super(const PipelineState()) {
    _init();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    // Daily API limits reset at midnight — clear the session rate-limit flag so
    // a new day always gets a fresh attempt at Currents.
    CurrentsNewsService.resetRateLimit();
    unawaited(_loadAll(forceRefresh: false));
    // Auto-refresh every 4 hours to match the server Cloud Function cadence
    _autoRefreshTimer = Timer.periodic(const Duration(hours: 4), (_) {
      if (mounted) _loadAll(forceRefresh: false);
    });
  }

  Future<void> _loadAll({required bool forceRefresh}) async {
    if (!mounted) return;

    // Show loading only on first load (no cached data yet)
    if (state.byCategory.isEmpty) {
      state = state.copyWith(isLoading: true);
    }

    try {
      final results =
          await NewsPipelineService.runAll(forceRefresh: forceRefresh);
      if (!mounted) return;

      // Print the debug console test as required
      _printTestOutput(results);

      final byCategory = {
        for (final entry in results.entries) entry.key: entry.value.display,
      };
      // Only update the timestamp if at least one category got fresh data from
      // Firestore or the Guardian API. If everything was served from local cache,
      // read the real savedAt from the cache so the label reflects when the news
      // was actually fetched, not when the app was opened.
      final anyFresh = results.values.any((r) => !r.fromCache);
      DateTime updatedAt;
      if (anyFresh) {
        updatedAt = DateTime.now();
      } else {
        final timestamps = await Future.wait(
          NewsCategory.values.map(NewsCacheService.getSavedAt),
        );
        final valid = timestamps.whereType<DateTime>().toList()..sort();
        updatedAt = valid.isNotEmpty ? valid.last : (state.updatedAt ?? DateTime.now());
      }
      state = PipelineState(
          byCategory: byCategory,
          isLoading: false,
          updatedAt: updatedAt);
    } catch (e) {
      dev.log('Pipeline load failed: $e', name: 'Briefed/Pipeline');
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() => _loadAll(forceRefresh: true);

  void _printTestOutput(Map<NewsCategory, CategoryResult> results) {
    final buf = StringBuffer();
    buf.writeln('=== BRIEFED NEWS PIPELINE TEST ===');
    for (final cat in NewsCategory.values) {
      final result = results[cat];
      if (result == null) continue;
      final quizable =
          result.display.where((a) => a.quizabilityPassed).toList();
      buf.writeln('');
      buf.writeln('Category: ${cat.name.toUpperCase()}');
      buf.writeln('Stories fetched: ${result.display.length}');
      buf.writeln('After dedup: ${result.display.length}');
      buf.writeln('Quiz-able: ${quizable.length}');
      buf.writeln('Top 5 headlines:');
      final top5 = result.quiz.take(5).toList();
      for (int i = 0; i < top5.length; i++) {
        final a = top5[i];
        buf.writeln(
            '${i + 1}. ${a.title} | ${a.sourceName} | ${a.finalScore.toStringAsFixed(1)}');
      }
    }
    buf.writeln('');
    buf.writeln('=== END TEST ===');
    dev.log(buf.toString(), name: 'Briefed/PipelineTest');
  }
}

// ── PROVIDER ──────────────────────────────────────────────────────────────────

final newsPipelineProvider =
    StateNotifierProvider<PipelineNotifier, PipelineState>(
  (ref) => PipelineNotifier(),
);
