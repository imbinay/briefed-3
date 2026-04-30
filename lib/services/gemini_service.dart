import 'dart:convert';
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/models.dart';
import 'storage_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// QUESTION SERVICE
// Tries Groq first (much higher free limits), falls back to Gemini,
// then falls back to mock questions. Questions cached once per day.
// ─────────────────────────────────────────────────────────────────────────────

class GeminiException implements Exception {
  final String message;
  final String? detail;
  GeminiException(this.message, {this.detail});

  @override
  String toString() => detail != null ? '$message\n\nDetail: $detail' : message;
}

class GeminiService {
  // ── Lean prompt — ~60% fewer tokens than the previous version ────────────
  static const String _prompt = '''
You generate multiple choice quiz questions from news headlines for a mobile app.

Output ONLY valid JSON. No markdown. No explanation. Start with { and end with }.

Rules:
- Exactly 5 questions total
- Prioritise the most newsworthy, widely reported stories in the supplied headlines
- Questions 1-3: easy (answerable from headline)
- Questions 4-5: hard (need deeper understanding)
- Each question: exactly 4 options, all plausible
- Keep the correct option unambiguous and supported by the supplied headline
- No questions about exact dates or death tolls
- Avoid trivia that will feel stale quickly, unless the headline itself is about a durable outcome
- Use concise, high-signal explanations that teach the context behind the answer
- Neutral tone

JSON format:
{"questions":[{"question":"...","options":["A","B","C","D"],"correct_index":0,"difficulty":"easy","category":"World","explanation":"1-2 sentences.","story_summary":"2-3 sentences about the story.","source":"Source name"}]}
''';

  // ─────────────────────────────────────────────────────────────────────────
  // PUBLIC ENTRY POINT
  // ─────────────────────────────────────────────────────────────────────────

  static Future<List<Question>> generateQuestions({
    required List<NewsArticle> articles,
    bool forceRefresh = false,
    bool bonusRound = false,
    int? replaySeed,
  }) async {
    // 1. Return cache if fresh
    if (!forceRefresh && !bonusRound) {
      final cached = StorageService.getCachedQuestions();
      if (cached != null && cached.length == AppConstants.questionsPerQuiz) {
        dev.log('[Quiz] Returning ${cached.length} cached questions',
            name: 'Briefed');
        return cached;
      }
    } else if (forceRefresh && !bonusRound) {
      await StorageService.clearQuestionCache();
      dev.log('[Quiz] Cache cleared', name: 'Briefed');
    }

    final sourceArticles = bonusRound
        ? _bonusArticles(articles, replaySeed: replaySeed)
        : articles;
    if (sourceArticles.isEmpty) {
      return mockQuestions(bonusRound: bonusRound, replaySeed: replaySeed);
    }

    // Build the headlines string — only top 5 to keep tokens low
    final headlines =
        sourceArticles.take(5).map((a) => '- ${a.title}').join('\n');

    final variantHint =
        replaySeed == null ? '' : ' Replay variant: $replaySeed.';
    final userMsg = bonusRound
        ? 'Generate a different 5-question BONUS quiz from these headlines.$variantHint Avoid repeating the daily quiz wording, answer positions, or angles:\n$headlines\n\nReturn only JSON.'
        : 'Generate 5 quiz questions from these headlines:\n$headlines\n\nReturn only JSON.';

    // 2. Try Groq first
    const groqKey = AppConstants.groqApiKey;
    if (groqKey.isNotEmpty && groqKey != 'YOUR_GROQ_API_KEY') {
      dev.log('[Quiz] Trying Groq...', name: 'Briefed');
      try {
        final qs = await _callGroq(userMsg);
        if (qs.length == AppConstants.questionsPerQuiz) {
          if (!bonusRound) await StorageService.cacheQuestions(qs);
          dev.log('[Quiz] Groq success — ${qs.length} questions',
              name: 'Briefed');
          return qs;
        }
      } catch (e) {
        dev.log('[Quiz] Groq failed: $e — trying Gemini...', name: 'Briefed');
      }
    } else {
      dev.log('[Quiz] Groq key not set — skipping', name: 'Briefed');
    }

    // 3. Try Gemini as fallback
    const geminiKey = AppConstants.geminiApiKey;
    if (geminiKey.isNotEmpty && geminiKey != 'YOUR_NEW_GEMINI_API_KEY') {
      dev.log('[Quiz] Trying Gemini...', name: 'Briefed');
      try {
        final qs = await _callGemini(userMsg);
        if (qs.length == AppConstants.questionsPerQuiz) {
          if (!bonusRound) await StorageService.cacheQuestions(qs);
          dev.log('[Quiz] Gemini success — ${qs.length} questions',
              name: 'Briefed');
          return qs;
        }
      } catch (e) {
        dev.log('[Quiz] Gemini failed: $e', name: 'Briefed');
        dev.log(
            '[Quiz] Falling back to mock questions after Gemini failure: $e',
            name: 'Briefed');
        return mockQuestions(bonusRound: bonusRound);
      }
    }

    // 4. Neither key is set
    return mockQuestions(bonusRound: bonusRound, replaySeed: replaySeed);
  }

  static List<NewsArticle> _bonusArticles(
    List<NewsArticle> articles, {
    int? replaySeed,
  }) {
    if (articles.isEmpty) return articles;
    final offset = replaySeed ?? AppConstants.questionsPerQuiz;
    final rotated = [
      ...articles.skip(offset % articles.length),
      ...articles.take(offset % articles.length),
    ];
    if (rotated.length > AppConstants.questionsPerQuiz) {
      return rotated.take(AppConstants.questionsPerQuiz).toList();
    }
    return rotated.reversed.toList();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // GROQ — OpenAI-compatible, Llama 3.1 70B
  // Free: 14,400 req/day, 30 req/min
  // ─────────────────────────────────────────────────────────────────────────

  static Future<List<Question>> _callGroq(String userMsg) async {
    final body = jsonEncode({
      'model': 'llama-3.3-70b-versatile',
      'temperature': 0.7,
      'max_tokens': 1500,
      'messages': [
        {'role': 'system', 'content': _prompt},
        {'role': 'user', 'content': userMsg},
      ],
      'response_format': {'type': 'json_object'}, // forces valid JSON output
    });

    late http.Response response;
    try {
      response = await http
          .post(
            Uri.parse(AppConstants.groqEndpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${AppConstants.groqApiKey}',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 20));
    } catch (e) {
      throw GeminiException('Groq network error', detail: e.toString());
    }

    dev.log('[Groq] HTTP ${response.statusCode}', name: 'Briefed');

    if (response.statusCode != 200) {
      String errMsg = 'HTTP ${response.statusCode}';
      try {
        errMsg = jsonDecode(response.body)['error']?['message'] ?? errMsg;
      } catch (_) {}
      throw GeminiException('Groq error: $errMsg',
          detail:
              response.body.substring(0, response.body.length.clamp(0, 400)));
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final content =
        data['choices']?[0]?['message']?['content'] as String? ?? '';

    dev.log('[Groq] Response length: ${content.length}', name: 'Briefed');

    return _parseQuestions(content);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // GEMINI — fallback
  // ─────────────────────────────────────────────────────────────────────────

  static Future<List<Question>> _callGemini(String userMsg) async {
    final body = jsonEncode({
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': '$_prompt\n\n$userMsg'}
          ],
        }
      ],
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 1500,
      },
    });

    late http.Response response;
    try {
      response = await http
          .post(
            Uri.parse(
                '${AppConstants.geminiEndpoint}?key=${AppConstants.geminiApiKey}'),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 25));
    } catch (e) {
      throw GeminiException('Gemini network error', detail: e.toString());
    }

    dev.log('[Gemini] HTTP ${response.statusCode}', name: 'Briefed');

    if (response.statusCode != 200) {
      String errMsg = 'HTTP ${response.statusCode}';
      try {
        errMsg = jsonDecode(response.body)['error']?['message'] ?? errMsg;
      } catch (_) {}
      throw GeminiException('Gemini error: $errMsg',
          detail:
              response.body.substring(0, response.body.length.clamp(0, 400)));
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final blockReason = data['promptFeedback']?['blockReason'];
    if (blockReason != null) {
      throw GeminiException('Gemini blocked prompt',
          detail: 'blockReason: $blockReason');
    }

    final candidates = data['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw GeminiException('Gemini returned no candidates',
          detail:
              response.body.substring(0, response.body.length.clamp(0, 400)));
    }

    final text =
        candidates.first['content']?['parts']?.first?['text'] as String? ?? '';
    if (text.isEmpty) {
      throw GeminiException('Gemini returned empty text',
          detail: jsonEncode(candidates.first));
    }

    return _parseQuestions(text);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SHARED JSON PARSER
  // ─────────────────────────────────────────────────────────────────────────

  static List<Question> _parseQuestions(String raw) {
    final cleaned = raw.replaceAll('```json', '').replaceAll('```', '').trim();

    dev.log(
        '[Quiz] Parsing: ${cleaned.substring(0, cleaned.length.clamp(0, 200))}',
        name: 'Briefed');

    late Map<String, dynamic> parsed;
    try {
      parsed = jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (e) {
      throw GeminiException(
        'JSON parse error',
        detail:
            '$e\n\nRaw: ${cleaned.substring(0, cleaned.length.clamp(0, 400))}',
      );
    }

    final qList = parsed['questions'] as List?;
    if (qList == null || qList.isEmpty) {
      throw GeminiException(
        'No "questions" key in response',
        detail: 'Keys found: ${parsed.keys.toList()}',
      );
    }

    return qList
        .map((e) => Question.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MOCK FALLBACK
  // ─────────────────────────────────────────────────────────────────────────

  static List<Question> mockQuestions(
      {bool bonusRound = false, int? replaySeed}) {
    final questions =
        AppConstants.mockQuestions.map((e) => Question.fromJson(e)).toList();
    if (!bonusRound || questions.isEmpty) return questions;
    final offset = replaySeed ?? 1;
    return [
      ...questions.skip(offset % questions.length),
      ...questions.take(offset % questions.length),
    ];
  }
}
