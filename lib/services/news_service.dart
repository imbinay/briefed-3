import 'dart:convert';
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/models.dart';

class NewsService {
  /// Fetch headlines from NewsData.io.
  /// Free plan limits: max 5 categories per request, max size 10.
  /// Falls back to mock articles if the request fails or returns no articles.
  static Future<List<NewsArticle>> fetchHeadlines({
    required String country,
    required List<String> categories,
    int size = 10,
  }) async {
    if (AppConstants.newsApiKey == 'YOUR_NEW_NEWSDATA_KEY' ||
        AppConstants.newsApiKey.isEmpty) {
      return _mockArticles();
    }

    try {
      final cat = categories.map(_newsDataCategory).join(',');
      final uri = Uri.parse(AppConstants.newsEndpoint).replace(
        queryParameters: {
          'apikey':   AppConstants.newsApiKey,
          'country':  country,
          'language': AppConstants.defaultLanguage,
          'category': cat,
          'size':     size.clamp(1, 10).toString(),
        },
      );

      final response =
          await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        // NewsData.io returns status:"error" in the body even on HTTP 200
        if (data['status'] == 'error') {
          dev.log('[News] API error: ${data['results']}', name: 'Briefed');
          return _mockArticles();
        }

        final results = data['results'] as List? ?? [];
        final articles = results
            .map((e) => NewsArticle.fromJson(e as Map<String, dynamic>))
            .where((a) => a.title.isNotEmpty && a.description.isNotEmpty)
            .toList();

        if (articles.isNotEmpty) return articles;
      } else {
        dev.log(
          '[News] HTTP ${response.statusCode}: ${response.body.substring(0, response.body.length.clamp(0, 200))}',
          name: 'Briefed',
        );
      }
    } catch (e) {
      dev.log('[News] fetchHeadlines failed: $e', name: 'Briefed');
    }

    dev.log('[News] Falling back to mock articles', name: 'Briefed');
    return _mockArticles();
  }

  static List<NewsArticle> _mockArticles() {
    return AppConstants.mockArticles
        .map((e) => NewsArticle.fromJson(e))
        .toList();
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
