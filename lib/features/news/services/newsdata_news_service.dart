import 'dart:convert';
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;
import '../../../config/api_config.dart';
import '../models/news_category.dart';
import '../models/ranked_article.dart';
import 'news_source_config.dart';

class NewsdataNewsService {
  static const _tag = 'Briefed/NewsData';

  static const Map<NewsCategory, Map<String, String>> _categoryParams = {
    NewsCategory.world: {'category': 'world', 'country': 'au,gb,us'},
    NewsCategory.politics: {'category': 'politics', 'country': 'au'},
    NewsCategory.sports: {'category': 'sports', 'country': 'au,gb,us'},
    NewsCategory.technology: {'category': 'technology'},
    NewsCategory.business: {'category': 'business', 'country': 'au'},
    NewsCategory.health: {'category': 'health', 'country': 'au,gb,us'},
    NewsCategory.entertainment: {'category': 'entertainment', 'country': 'au,gb,us'},
  };

  static Future<List<RankedArticle>> fetchCategory(
      NewsCategory category) async {
    final key = ApiConfig.newsdataApiKey.trim();
    if (key.isEmpty) {
      dev.log('NEWSDATA_API_KEY not set — skipping', name: _tag);
      return [];
    }

    final extra = Map<String, String>.from(_categoryParams[category]!);
    final params = {
      'apikey': key,
      'language': 'en',
      'size': '10',
      ...extra,
    };

    final uri = Uri.parse('${ApiConfig.newsdataBaseUrl}/news')
        .replace(queryParameters: params);

    dev.log('GET ${category.name} (fallback)', name: _tag);

    final response = await http.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['status'] == 'error') {
      final code = data['code'] ?? 'unknown';
      throw Exception('[$code] ${data['message'] ?? ''}');
    }

    final results = data['results'] as List? ?? [];
    final articles = <RankedArticle>[];

    for (final item in results) {
      final map = item as Map<String, dynamic>;
      final url = (map['link'] as String? ?? '').trim();
      if (url.isEmpty) continue;
      final domain = NewsSourceConfig.parseDomain(url);
      if (!NewsSourceConfig.isApproved(domain, category)) continue;
      final title = (map['title'] as String? ?? '').trim();
      if (title.isEmpty) continue;
      final imageUrl = map['image_url'] as String?;
      articles.add(RankedArticle(
        id: RankedArticle.md5Id(url),
        title: title,
        summary: (map['description'] as String? ?? '').trim(),
        url: url,
        imageUrl: (imageUrl?.isNotEmpty ?? false) ? imageUrl : null,
        sourceName: NewsSourceConfig.displayName(domain),
        sourceDomain: domain,
        publishedAt: _parseDate(map['pubDate'] as String? ?? ''),
        category: category,
        sourceQualityScore: NewsSourceConfig.qualityScore(domain),
        quizabilityScore: 0,
        quizabilityPassed: false,
        apiSource: ApiSource.newsdata,
      ));
    }

    dev.log('${category.name}: ${articles.length} approved', name: _tag);
    return articles;
  }

  static DateTime _parseDate(String s) {
    try {
      return DateTime.parse(s).toLocal();
    } catch (_) {
      return DateTime.now();
    }
  }
}
