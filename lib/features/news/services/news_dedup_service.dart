import '../models/news_category.dart';
import '../models/ranked_article.dart';

class NewsDedupService {
  static const _stopwords = {
    'the', 'a', 'an', 'in', 'on', 'at', 'to', 'for', 'of', 'and',
    'or', 'but', 'is', 'are', 'was', 'were', 'says', 'say', 'after',
    'over', 'as', 'with', 'by', 'from', 'its', 'it', 'has', 'have',
    'had', 'will', 'would', 'about', 'that',
  };

  /// Deduplicates a list of articles from multiple sources.
  /// Prioritises higher sourceQualityScore; tiebreak: Currents > Guardian > NewsData.
  static List<RankedArticle> deduplicate(List<RankedArticle> articles) {
    // Step 1 — exact URL dedup (keep higher quality score)
    final byUrl = <String, RankedArticle>{};
    for (final a in articles) {
      final key = _normaliseUrl(a.url);
      if (!byUrl.containsKey(key)) {
        byUrl[key] = a;
      } else if (_betterSource(a, byUrl[key]!)) {
        byUrl[key] = a;
      }
    }
    final unique = byUrl.values.toList();

    // Step 2 & 3 — Jaccard similarity + shared keyword cluster dedup
    final kept = <RankedArticle>[];
    for (final candidate in unique) {
      bool isDupe = false;
      for (final existing in kept) {
        if (_isDuplicate(candidate, existing)) {
          isDupe = true;
          // Replace existing with better source if candidate wins
          if (_betterSource(candidate, existing)) {
            kept.remove(existing);
            kept.add(candidate);
          }
          break;
        }
      }
      if (!isDupe) kept.add(candidate);
    }

    return kept;
  }

  static bool _isDuplicate(RankedArticle a, RankedArticle b) {
    final wa = _keywords(a.title);
    final wb = _keywords(b.title);
    if (wa.isEmpty || wb.isEmpty) return false;

    // Jaccard score >= 0.6
    final intersection = wa.intersection(wb).length;
    final union = wa.union(wb).length;
    if (union > 0 && intersection / union >= 0.6) return true;

    // Shared keyword cluster: 3+ consecutive meaningful words
    final listA = _keywordList(a.title);
    final listB = _keywordList(b.title);
    return _hasConsecutiveCluster(listA, listB, 3);
  }

  static bool _hasConsecutiveCluster(
      List<String> a, List<String> b, int n) {
    if (a.length < n || b.length < n) return false;
    for (int i = 0; i <= a.length - n; i++) {
      final cluster = a.sublist(i, i + n).join(' ');
      for (int j = 0; j <= b.length - n; j++) {
        if (b.sublist(j, j + n).join(' ') == cluster) return true;
      }
    }
    return false;
  }

  static Set<String> _keywords(String title) =>
      Set<String>.from(_keywordList(title));

  static List<String> _keywordList(String title) => title
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
      .split(' ')
      .where((w) => w.length > 2 && !_stopwords.contains(w))
      .toList();

  static String _normaliseUrl(String url) {
    try {
      final uri = Uri.parse(url.toLowerCase().trim());
      return '${uri.host}${uri.path}'.replaceAll(RegExp(r'/$'), '');
    } catch (_) {
      return url.toLowerCase().trim();
    }
  }

  /// Returns true if [a] is a better source than [b].
  static bool _betterSource(RankedArticle a, RankedArticle b) {
    if (a.sourceQualityScore != b.sourceQualityScore) {
      return a.sourceQualityScore > b.sourceQualityScore;
    }
    // Tiebreak: Currents > Guardian > NewsData
    return _apiPriority(a.apiSource) < _apiPriority(b.apiSource);
  }

  static int _apiPriority(ApiSource s) {
    switch (s) {
      case ApiSource.currents:
        return 0;
      case ApiSource.guardian:
        return 1;
      case ApiSource.newsdata:
        return 2;
    }
  }
}
