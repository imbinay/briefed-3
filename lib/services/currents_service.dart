import 'dart:convert';
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/models.dart';

class CurrentsService {
  /// Fetch latest news from Currents API.
  /// Free plan: 600 req/day. Non-fatal — caller should catch errors.
  static Future<List<NewsArticle>> fetchHeadlines({
    required String country,
    required List<String> categories,
    int size = 10,
  }) async {
    final apiKey = AppConstants.currentsApiKey.trim();
    if (apiKey.isEmpty) throw Exception('CURRENTS_API_KEY not configured');

    final params = <String, String>{
      'apiKey': apiKey,
      'language': 'en',
    };
    final isWorld = country == 'world';
    if (!isWorld && country.isNotEmpty) params['country'] = country;

    final uri = Uri.parse(AppConstants.currentsEndpoint)
        .replace(queryParameters: params);

    dev.log('[Currents] GET country=${isWorld ? "world(global)" : country}',
        name: 'Briefed');

    final response = await http.get(uri).timeout(const Duration(seconds: 15));

    dev.log('[Currents] HTTP ${response.statusCode}', name: 'Briefed');

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (data['status'] != 'ok') {
      throw Exception('Currents error: ${data['message'] ?? 'unknown'}');
    }

    final results = (data['news'] as List? ?? []).take(size);
    final articles = results
        .map((e) => _toArticle(e as Map<String, dynamic>))
        .where((a) => a.title.isNotEmpty && a.link.isNotEmpty)
        .toList();

    if (articles.isEmpty) throw Exception('No articles from Currents');

    dev.log('[Currents] Loaded ${articles.length} articles', name: 'Briefed');
    return articles;
  }

  static NewsArticle _toArticle(Map<String, dynamic> e) {
    final url = e['url'] as String? ?? '';
    return NewsArticle(
      title: e['title'] as String? ?? '',
      description: e['description'] as String? ?? '',
      sourceName: _domainLabel(url),
      category: _mapCategory(e['category']),
      pubDate: e['published'] as String? ?? '',
      link: url,
      imageUrl: e['image'] as String?,
    );
  }

  // Extract a readable label from the article URL (e.g. "Bbc" → "BBC").
  static String _domainLabel(String url) {
    try {
      final host = Uri.parse(url).host.replaceFirst(RegExp(r'^www\.'), '');
      final name = host.split('.').reversed.skip(1).first;
      return name[0].toUpperCase() + name.substring(1);
    } catch (_) {
      return 'News';
    }
  }

  // Map Currents category array to app category string.
  static String _mapCategory(dynamic cat) {
    final raw = cat is List
        ? cat.map((c) => c.toString().toLowerCase()).toList()
        : [cat?.toString().toLowerCase() ?? ''];
    for (final c in raw) {
      if (c.contains('tech') || c.contains('science')) {
        return 'technology';
      }
      if (c.contains('business') || c.contains('finance')) {
        return 'business';
      }
      if (c.contains('sport')) {
        return 'sports';
      }
      if (c.contains('entertainment')) {
        return 'entertainment';
      }
      if (c.contains('politic') ||
          c.contains('world') ||
          c.contains('general')) {
        return 'world';
      }
    }
    return 'world';
  }
}
