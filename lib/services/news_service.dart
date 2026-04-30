import 'dart:convert';
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/models.dart';

class NewsService {
  /// Fetch headlines from NewsData.io.
  /// Free plan limits: max 5 categories per request, max size 10.
  /// Throws on any failure so the caller can handle fallback/error state.
  static Future<List<NewsArticle>> fetchHeadlines({
    required String country,
    required List<String> categories,
    int size = 10,
  }) async {
    final apiKey = AppConstants.newsApiKey.trim();
    if (apiKey.isEmpty) {
      throw Exception(
          'NEWSDATA_API_KEY not configured — run with --dart-define-from-file=api_keys.json');
    }

    final cat = categories.map(_newsDataCategory).join(',');
    final uri = Uri.parse(AppConstants.newsEndpoint).replace(
      queryParameters: {
        'apikey': apiKey,
        'country': country,
        'language': AppConstants.defaultLanguage,
        'category': cat,
        'size': size.clamp(1, 10).toString(),
      },
    );

    dev.log(
      '[News] GET $country | categories=$cat | size=${size.clamp(1, 10)}',
      name: 'Briefed',
    );

    final response =
        await http.get(uri).timeout(const Duration(seconds: 15));

    dev.log('[News] HTTP ${response.statusCode}', name: 'Briefed');

    if (response.statusCode != 200) {
      throw Exception(
          'HTTP ${response.statusCode}: ${response.body.substring(0, response.body.length.clamp(0, 300))}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    // NewsData.io returns status:"error" in the body even on HTTP 200
    if (data['status'] == 'error') {
      final code = data['code'] ?? 'unknown';
      final msg = data['message'] ?? data['results']?.toString() ?? '';
      dev.log('[News] API error — code: $code | message: $msg',
          name: 'Briefed');
      throw Exception('[$code] $msg');
    }

    final results = data['results'] as List? ?? [];
    final articles = results
        .map((e) => NewsArticle.fromJson(e as Map<String, dynamic>))
        .where((a) => a.title.isNotEmpty)
        .toList();

    if (articles.isEmpty) {
      throw Exception('API returned no usable articles');
    }

    dev.log('[News] Loaded ${articles.length} live articles', name: 'Briefed');
    return articles;
  }

  static String _newsDataCategory(String category) {
    for (final item in AppConstants.allCategories) {
      if (item['id'] == category) return item['newsId'] ?? category;
    }
    return category;
  }

  /// Group articles by category for Briefing screen sections
  static Map<String, List<NewsArticle>> groupByCategory(
      List<NewsArticle> articles) {
    final Map<String, List<NewsArticle>> grouped = {};
    for (final article in articles) {
      final cat = article.category.toLowerCase();
      grouped.putIfAbsent(cat, () => []).add(article);
    }
    return grouped;
  }
}
