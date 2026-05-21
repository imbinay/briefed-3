import 'dart:convert';
import 'dart:developer' as dev;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/news_category.dart';
import '../models/ranked_article.dart';

class NewsCacheService {
  static const _tag = 'Briefed/Cache';
  static const _ttlMinutes = 240; // 4 hours — matches Cloud Function schedule

  static String _key(NewsCategory cat) {
    final date = DateTime.now().toIso8601String().substring(0, 10);
    return 'briefed_news_v4_${cat.name}_$date';
  }

  static Future<List<RankedArticle>?> load(NewsCategory cat) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _key(cat);
      final raw = prefs.getString(key);
      if (raw == null) return null;

      final map = jsonDecode(raw) as Map<String, dynamic>;
      final savedAt = DateTime.tryParse(map['savedAt'] as String? ?? '');
      if (savedAt == null) return null;

      final age = DateTime.now().difference(savedAt).inMinutes;
      if (age > _ttlMinutes) {
        dev.log('${cat.name}: cache expired (${age}m)', name: _tag);
        return null;
      }

      final list = map['articles'] as List? ?? [];
      final articles = list
          .map((e) => RankedArticle.fromJson(e as Map<String, dynamic>))
          .toList();
      dev.log('${cat.name}: loaded ${articles.length} from cache', name: _tag);
      return articles;
    } catch (e) {
      dev.log('${cat.name}: cache load error — $e', name: _tag);
      return null;
    }
  }

  /// Returns cached articles ignoring TTL — used when Firestore is unreachable
  /// so a Firestore outage never triggers live API calls.
  static Future<List<RankedArticle>?> loadStale(NewsCategory cat) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(cat));
      if (raw == null) return null;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final list = map['articles'] as List? ?? [];
      final articles = list
          .map((e) => RankedArticle.fromJson(e as Map<String, dynamic>))
          .toList();
      dev.log('${cat.name}: loaded ${articles.length} stale articles', name: _tag);
      return articles;
    } catch (e) {
      dev.log('${cat.name}: stale cache load error — $e', name: _tag);
      return null;
    }
  }

  /// Returns the timestamp of when this category's cache was last written,
  /// or null if no cache exists for today.
  static Future<DateTime?> getSavedAt(NewsCategory cat) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(cat));
      if (raw == null) return null;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return DateTime.tryParse(map['savedAt'] as String? ?? '');
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(
      NewsCategory cat, List<RankedArticle> articles) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = jsonEncode({
        'savedAt': DateTime.now().toIso8601String(),
        'articles': articles.map((a) => a.toJson()).toList(),
      });
      await prefs.setString(_key(cat), payload);
      dev.log('${cat.name}: saved ${articles.length} articles', name: _tag);
    } catch (e) {
      dev.log('${cat.name}: cache save error — $e', name: _tag);
    }
  }
}
