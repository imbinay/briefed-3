import 'dart:developer' as dev;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/news_category.dart';
import '../models/ranked_article.dart';

/// Reads pre-cached news from Firestore `news_cache/{category}`.
/// The Cloud Function refreshes this collection every 2 hours.
class FirestoreNewsService {
  static const _tag = 'Briefed/FirestoreCache';
  static const _collection = 'news_cache';

  // How stale the server cache can be before we skip it and go direct.
  static const _maxCacheAge = Duration(hours: 10);

  static final _firestore = FirebaseFirestore.instance;

  static Future<List<RankedArticle>> fetchCategory(
      NewsCategory category) async {
    try {
      final doc = await _firestore
          .collection(_collection)
          .doc(category.name)
          .get()
          .timeout(const Duration(seconds: 8));

      if (!doc.exists) {
        dev.log('No server cache for ${category.name}', name: _tag);
        return [];
      }

      final data = doc.data()!;
      final updatedAt = (data['updatedAt'] as Timestamp?)?.toDate();
      if (updatedAt == null) return [];

      final age = DateTime.now().difference(updatedAt);
      if (age > _maxCacheAge) {
        dev.log(
            '${category.name} cache is ${age.inMinutes}m old — skipping',
            name: _tag);
        return [];
      }

      final rawList = data['articles'] as List<dynamic>? ?? [];
      final articles = rawList
          .whereType<Map<String, dynamic>>()
          .map(RankedArticle.fromJson)
          .toList();

      dev.log(
          '${category.name}: ${articles.length} articles from server cache '
          '(${age.inMinutes}m old)',
          name: _tag);
      return articles;
    } catch (e) {
      dev.log('Firestore fetch failed for ${category.name}: $e', name: _tag);
      return [];
    }
  }
}
