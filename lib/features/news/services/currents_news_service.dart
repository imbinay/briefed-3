import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;
import '../../../config/api_config.dart';
import '../models/news_category.dart';
import '../models/ranked_article.dart';
import 'news_source_config.dart';
import 'quiz_ability_scorer.dart';

class CurrentsNewsService {
  static const _tag = 'Briefed/Currents';
  static const _searchUrl = 'https://api.currentsapi.services/v2/search';
  static const _latestNewsUrl =
      'https://api.currentsapi.services/v2/latest-news';

  // Set to true for the session once a 429 is received — avoids wasting
  // ~4s per domain call (retry delay) when the daily quota is already gone.
  static bool _rateLimited = false;

  static void resetRateLimit() => _rateLimited = false;

  static const Map<NewsCategory, String> _categoryFallbackMap = {
    NewsCategory.world: 'general',
    NewsCategory.politics: 'politics',
    NewsCategory.sports: 'sport',
    NewsCategory.technology: 'technology',
    NewsCategory.business: 'finance',
    NewsCategory.health: 'health',
    NewsCategory.entertainment: 'entertainment',
  };

  static const Map<NewsCategory, List<_DomainConfig>> _domainConfigs = {
    NewsCategory.world: [
      _DomainConfig('reuters.com'),
      _DomainConfig('bbc.co.uk'),
      _DomainConfig('apnews.com'),
      _DomainConfig('aljazeera.com'),
      _DomainConfig('theguardian.com'),
    ],
    NewsCategory.politics: [
      _DomainConfig('abc.net.au', keywords: 'politics'),
      _DomainConfig('reuters.com', keywords: 'politics'),
      _DomainConfig('bbc.co.uk', keywords: 'politics'),
      _DomainConfig('politico.com'),
      _DomainConfig('theguardian.com', keywords: 'politics'),
    ],
    NewsCategory.sports: [
      _DomainConfig('espn.com'),
      _DomainConfig('bbc.co.uk', category: 'sport'),
      _DomainConfig('theguardian.com', category: 'sport'),
      _DomainConfig('foxsports.com.au'),
      _DomainConfig('skysports.com'),
    ],
    NewsCategory.technology: [
      _DomainConfig('theverge.com'),
      _DomainConfig('techcrunch.com'),
      _DomainConfig('arstechnica.com'),
      _DomainConfig('wired.com'),
      _DomainConfig('technologyreview.com'),
    ],
    NewsCategory.business: [
      _DomainConfig('bloomberg.com'),
      _DomainConfig('ft.com'),
      _DomainConfig('cnbc.com'),
      _DomainConfig('reuters.com', keywords: 'business'),
      _DomainConfig('afr.com'),
    ],
    NewsCategory.health: [
      _DomainConfig('theguardian.com', keywords: 'health'),
      _DomainConfig('bbc.co.uk', keywords: 'health'),
      _DomainConfig('abc.net.au', keywords: 'health'),
      _DomainConfig('newscientist.com'),
      _DomainConfig('theatlantic.com', keywords: 'health'),
    ],
    NewsCategory.entertainment: [
      _DomainConfig('theguardian.com', category: 'culture'),
      _DomainConfig('bbc.co.uk', keywords: 'entertainment'),
      _DomainConfig('deadline.com'),
      _DomainConfig('variety.com'),
      _DomainConfig('hollywoodreporter.com'),
    ],
  };

  static Future<List<RankedArticle>> fetchCategory(
      NewsCategory category) async {
    final key = ApiConfig.currentsApiKey.trim();
    if (key.isEmpty) {
      dev.log('CURRENTS_API_KEY not set — skipping', name: _tag);
      return [];
    }
    if (_rateLimited) {
      dev.log('Rate-limited for session — skipping Currents', name: _tag);
      return [];
    }

    final configs = _domainConfigs[category] ?? [];
    if (configs.isEmpty) return [];

    // Stagger domain calls 200ms apart; abort the whole category on first 429
    final results = <List<RankedArticle>>[];
    for (final cfg in configs) {
      if (_rateLimited) break;
      await Future<void>.delayed(const Duration(milliseconds: 200));
      results.add(await _fetchDomain(key, cfg, category));
    }

    // Track per-domain counts for the test log
    final domainCounts = {
      for (int i = 0; i < configs.length; i++)
        configs[i].domain: results[i].length,
    };

    final merged = results.expand((r) => r).toList();

    if (category == NewsCategory.world || category == NewsCategory.sports) {
      _printDomainTest(category, configs, domainCounts, merged);
    }

    return merged;
  }

  // Wraps _doFetch so one domain failure never blocks the category.
  static Future<List<RankedArticle>> _fetchDomain(
    String apiKey,
    _DomainConfig cfg,
    NewsCategory category,
  ) async {
    try {
      return await _doFetch(apiKey, cfg, category);
    } catch (e) {
      if (e.toString().contains('HTTP 500')) {
        dev.log('${cfg.domain} 500 → using category fallback', name: _tag);
        return _fetchCategoryFallback(apiKey, category);
      }
      dev.log('${cfg.domain} fetch failed: $e', name: _tag);
      return [];
    }
  }

  static Future<List<RankedArticle>> _fetchCategoryFallback(
    String apiKey,
    NewsCategory category,
  ) async {
    try {
      final mappedCategory = _categoryFallbackMap[category] ?? 'general';
      final approvedDomains =
          (_domainConfigs[category] ?? []).map((c) => c.domain).toSet();

      final params = {
        'language': 'en',
        'category': mappedCategory,
        'country': 'gb,us,au',
        'page_size': '20',
        'apiKey': apiKey,
      };

      final uri = Uri.parse(_latestNewsUrl).replace(queryParameters: params);
      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if ((data['status'] as String? ?? '') != 'ok') return [];

      final news = data['news'] as List? ?? [];
      final articles = <RankedArticle>[];

      for (final item in news) {
        final map = item as Map<String, dynamic>;
        final url = (map['url'] as String? ?? '').trim();
        if (url.isEmpty) continue;
        final title = (map['title'] as String? ?? '').trim();
        if (title.isEmpty) continue;

        final domain = NewsSourceConfig.parseDomain(url);
        if (!approvedDomains.contains(domain)) continue;

        final imageRaw = map['image'] as String?;
        final imageUrl =
            (imageRaw?.startsWith('http') ?? false) ? imageRaw : null;

        articles.add(RankedArticle(
          id: RankedArticle.md5Id(url),
          title: title,
          summary: (map['description'] as String? ?? '').trim(),
          url: url,
          imageUrl: imageUrl,
          sourceName: NewsSourceConfig.displayName(domain),
          sourceDomain: domain,
          publishedAt: _parseDate(map['published'] as String? ?? ''),
          category: category,
          sourceQualityScore: NewsSourceConfig.qualityScore(domain),
          quizabilityScore: 0,
          quizabilityPassed: false,
          apiSource: ApiSource.currents,
        ));
      }

      return articles;
    } catch (e) {
      dev.log('Category fallback failed: $e', name: _tag);
      return [];
    }
  }

  static Future<List<RankedArticle>> _doFetch(
    String apiKey,
    _DomainConfig cfg,
    NewsCategory category,
  ) async {
    final params = <String, String>{
      'apiKey': apiKey,
      'domain': cfg.domain,
      'language': 'en',
      'page_size': '20',
    };
    if (cfg.keywords != null) params['keywords'] = cfg.keywords!;
    if (cfg.category != null) params['category'] = cfg.category!;

    final uri = Uri.parse(_searchUrl).replace(queryParameters: params);
    dev.log('GET ${cfg.domain} (${category.name})', name: _tag);

    var response = await http.get(uri).timeout(const Duration(seconds: 15));

    if (response.statusCode == 429) {
      _rateLimited = true;
      dev.log('RATE LIMITED — disabling Currents for this session', name: _tag);
      return [];
    }

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if ((data['status'] as String? ?? '') != 'ok') {
      throw Exception('API status=${data['status']}');
    }

    final news = data['news'] as List? ?? [];
    final articles = <RankedArticle>[];

    for (final item in news) {
      final map = item as Map<String, dynamic>;
      final url = (map['url'] as String? ?? '').trim();
      if (url.isEmpty) continue;
      final title = (map['title'] as String? ?? '').trim();
      if (title.isEmpty) continue;

      final domain = NewsSourceConfig.parseDomain(url);
      final effectiveDomain = domain.isNotEmpty ? domain : cfg.domain;
      final imageRaw = map['image'] as String?;
      final imageUrl =
          (imageRaw?.startsWith('http') ?? false) ? imageRaw : null;

      articles.add(RankedArticle(
        id: RankedArticle.md5Id(url),
        title: title,
        summary: (map['description'] as String? ?? '').trim(),
        url: url,
        imageUrl: imageUrl,
        sourceName: NewsSourceConfig.displayName(effectiveDomain),
        sourceDomain: effectiveDomain,
        publishedAt: _parseDate(map['published'] as String? ?? ''),
        category: category,
        sourceQualityScore: NewsSourceConfig.qualityScore(effectiveDomain),
        quizabilityScore: 0,
        quizabilityPassed: false,
        apiSource: ApiSource.currents,
      ));
    }

    dev.log('${cfg.domain}: ${articles.length} articles', name: _tag);
    return articles;
  }

  static void _printDomainTest(
    NewsCategory category,
    List<_DomainConfig> configs,
    Map<String, int> domainCounts,
    List<RankedArticle> merged,
  ) {
    // Dedup by ID for the log count (full dedup runs later in the pipeline)
    final seen = <String>{};
    final deduped = merged.where((a) => seen.add(a.id)).toList();

    final scored = deduped.map(QuizAbilityScorer.score).toList();
    final quizable = scored.where((a) => a.quizabilityPassed).toList();
    final top3 = scored.take(3).toList();

    final buf = StringBuffer();
    buf.writeln('=== CURRENTS DOMAIN TEST ===');
    buf.writeln('Category: ${category.name.toUpperCase()}');
    for (final cfg in configs) {
      final count = domainCounts[cfg.domain] ?? 0;
      buf.writeln('  ${cfg.domain.padRight(22)}→ $count articles fetched');
    }
    buf.writeln('  Total before dedup: ${merged.length}');
    buf.writeln('  After dedup: ${deduped.length}');
    buf.writeln('  Quiz-able: ${quizable.length}');
    buf.writeln('  Top 3 headlines:');
    for (int i = 0; i < top3.length; i++) {
      buf.writeln('  ${i + 1}. ${top3[i].title} | ${top3[i].sourceName}');
    }
    buf.writeln('=== END ===');
    dev.log(buf.toString(), name: _tag);
  }

  static DateTime _parseDate(String s) {
    try {
      // Currents format: "2021-07-08 19:47:11 +0000" → normalize to ISO 8601
      final normalized = s
          .trim()
          .replaceFirstMapped(
              RegExp(r'^(\d{4}-\d{2}-\d{2}) '), (m) => '${m[1]}T')
          .replaceFirst(' +', '+')
          .replaceFirst(' -', '-');
      return DateTime.parse(normalized).toLocal();
    } catch (_) {
      return DateTime.now();
    }
  }
}

class _DomainConfig {
  final String domain;
  final String? keywords;
  final String? category;

  const _DomainConfig(this.domain, {this.keywords, this.category});
}
