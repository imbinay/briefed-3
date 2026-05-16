import 'dart:convert';
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;
import '../../../config/api_config.dart';
import '../models/news_category.dart';
import '../models/ranked_article.dart';
class GuardianNewsService {
  static const _tag = 'Briefed/Guardian';
  static const _domain = 'theguardian.com';
  static const _sourceName = 'The Guardian';
  static const _qualityScore = 100; // Tier 1

  static const Map<NewsCategory, String> _sections = {
    NewsCategory.world: 'world',
    NewsCategory.politics: 'politics',
    NewsCategory.sports: 'sport',
    NewsCategory.technology: 'technology',
    NewsCategory.business: 'business',
  };

  static Future<List<RankedArticle>> fetchCategory(
      NewsCategory category) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final params = {
      'api-key': ApiConfig.guardianApiKey,
      'section': _sections[category]!,
      'show-fields': 'headline,trailText,thumbnail,shortUrl',
      'show-elements': 'image',
      'page-size': '20',
      'order-by': 'newest',
      'from-date': today,
    };

    final uri = Uri.parse('${ApiConfig.guardianBaseUrl}/search')
        .replace(queryParameters: params);

    dev.log('GET ${category.name}', name: _tag);

    final response =
        await http.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final resp = data['response'] as Map<String, dynamic>? ?? {};
    if ((resp['status'] as String? ?? '') != 'ok') {
      throw Exception('API status=${resp['status']}');
    }

    final results = resp['results'] as List? ?? [];
    final articles = <RankedArticle>[];

    for (final item in results) {
      final map = item as Map<String, dynamic>;
      final fields = map['fields'] as Map<String, dynamic>? ?? {};
      final url = (map['webUrl'] as String? ?? '').trim();
      if (url.isEmpty) continue;
      final title =
          ((fields['headline'] ?? map['webTitle']) as String? ?? '').trim();
      if (title.isEmpty) continue;
      final summary = (fields['trailText'] as String? ?? '').trim();
      final imageUrl = _bestImage(map, fields);
      final publishedAt =
          _parseDate(map['webPublicationDate'] as String? ?? '');

      articles.add(RankedArticle(
        id: RankedArticle.md5Id(url),
        title: title,
        summary: summary,
        url: url,
        imageUrl: (imageUrl?.isNotEmpty ?? false) ? imageUrl : null,
        sourceName: _sourceName,
        sourceDomain: _domain,
        publishedAt: publishedAt,
        category: category,
        sourceQualityScore: _qualityScore,
        quizabilityScore: 0,
        quizabilityPassed: false,
        apiSource: ApiSource.guardian,
      ));
    }

    dev.log('${category.name}: ${articles.length} articles', name: _tag);
    return articles;
  }

  static String? _bestImage(
      Map<String, dynamic> item, Map<String, dynamic> fields) {
    // 1 — try elements (main image, largest asset)
    final elements = item['elements'] as List? ?? [];
    for (final el in elements) {
      final e = el as Map<String, dynamic>;
      if ((e['relation'] as String? ?? '') != 'main') continue;
      if ((e['type'] as String? ?? '') != 'image') continue;
      final assets = e['assets'] as List? ?? [];
      String? best;
      int bestWidth = 0;
      for (final a in assets) {
        final asset = a as Map<String, dynamic>;
        final file = asset['file'] as String? ?? '';
        if (file.isEmpty) continue;
        final w = (asset['typeData']?['width'] as num? ?? 0).toInt();
        if (w > bestWidth) {
          bestWidth = w;
          best = file;
        }
      }
      if (best != null) return best;
    }
    // 2 — fall back to thumbnail field
    final thumb = fields['thumbnail'] as String?;
    return (thumb?.startsWith('http') ?? false) ? thumb : null;
  }

  static DateTime _parseDate(String s) {
    try {
      return DateTime.parse(s).toLocal();
    } catch (_) {
      return DateTime.now();
    }
  }
}
