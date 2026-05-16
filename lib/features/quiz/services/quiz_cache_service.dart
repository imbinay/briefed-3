import 'dart:convert';
import 'dart:developer' as dev;
import 'package:shared_preferences/shared_preferences.dart';
import '../../news/models/news_category.dart';
import '../models/quiz_question.dart';

class QuizCacheService {
  static const _tag = 'Briefed/QuizCache';

  static String cacheKey(NewsCategory cat) {
    final date = DateTime.now().toIso8601String().substring(0, 10);
    return 'briefed_quiz_v2_${cat.name}_$date';
  }

  static Future<List<QuizQuestion>?> load(NewsCategory cat) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(cacheKey(cat));
      if (raw == null) return null;
      final list = jsonDecode(raw) as List;
      final questions = list
          .map((e) => QuizQuestion.fromJson(e as Map<String, dynamic>))
          .toList();
      dev.log('${cat.name}: loaded ${questions.length} cached questions', name: _tag);
      return questions;
    } catch (e) {
      dev.log('${cat.name}: cache load failed: $e', name: _tag);
      return null;
    }
  }

  static Future<void> save(NewsCategory cat, List<QuizQuestion> questions) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        cacheKey(cat),
        jsonEncode(questions.map((q) => q.toJson()).toList()),
      );
      dev.log('${cat.name}: cached ${questions.length} questions', name: _tag);
    } catch (e) {
      dev.log('${cat.name}: cache save failed: $e', name: _tag);
    }
  }

  static Future<void> invalidate(NewsCategory cat) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(cacheKey(cat));
    } catch (_) {}
  }
}
