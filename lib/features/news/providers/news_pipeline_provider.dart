import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/news_category.dart';
import '../models/ranked_article.dart';
import '../services/news_pipeline_service.dart';

// ── STATE ─────────────────────────────────────────────────────────────────────

class PipelineState {
  final Map<NewsCategory, List<RankedArticle>> byCategory;
  final bool isLoading;
  final String? error;

  const PipelineState({
    this.byCategory = const {},
    this.isLoading = true,
    this.error,
  });

  PipelineState copyWith({
    Map<NewsCategory, List<RankedArticle>>? byCategory,
    bool? isLoading,
    String? error,
  }) =>
      PipelineState(
        byCategory: byCategory ?? this.byCategory,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );

  /// Top 10 display articles for a specific category.
  List<RankedArticle> getTopStoriesForDisplay(NewsCategory cat) =>
      byCategory[cat] ?? [];

  /// Top 5 quiz-able articles for a specific category.
  List<RankedArticle> getQuizStories(NewsCategory cat) =>
      (byCategory[cat] ?? []).where((a) => a.quizabilityPassed).take(5).toList();

  /// "For You" feed — top 2 from each category, re-sorted by finalScore, max 10.
  List<RankedArticle> get forYouStories {
    final all = NewsCategory.values
        .expand((cat) => (byCategory[cat] ?? []).take(2))
        .toList();
    all.sort((a, b) => b.finalScore.compareTo(a.finalScore));
    return all.take(10).toList();
  }
}

// ── NOTIFIER ──────────────────────────────────────────────────────────────────

class PipelineNotifier extends StateNotifier<PipelineState> {
  PipelineNotifier() : super(const PipelineState()) {
    _init();
  }

  Future<void> _init() async {
    // Serve cache immediately for each category, then refresh in background
    unawaited(_loadAll(forceRefresh: false));
  }

  Future<void> _loadAll({required bool forceRefresh}) async {
    if (!mounted) return;

    // Show loading only on first load (no cached data yet)
    if (state.byCategory.isEmpty) {
      state = state.copyWith(isLoading: true);
    }

    try {
      final results = await NewsPipelineService.runAll(forceRefresh: forceRefresh);
      if (!mounted) return;

      // Print the debug console test as required
      _printTestOutput(results);

      final byCategory = {
        for (final entry in results.entries) entry.key: entry.value.display,
      };
      state = PipelineState(byCategory: byCategory, isLoading: false);
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
      final quizable = result.display.where((a) => a.quizabilityPassed).toList();
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
