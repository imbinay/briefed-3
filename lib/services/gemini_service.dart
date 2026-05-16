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
  // ── Prompt — includes descriptions for context-rich, analytical questions ─
  static const String _prompt = '''
You are an expert news quiz writer for a mobile app. Your job is to turn a list of news articles into 5 outstanding quiz questions.

Output ONLY valid JSON. No markdown. No explanation. Start with { and end with }.

STEP 1 — SELECT: From the articles provided, choose the 5 most globally significant, thought-provoking stories. Skip minor local events, celebrity gossip, or stories with too little context.

STEP 2 — WRITE one question per selected story following these rules:

Question quality:
- A great question makes the reader pause and think — it should feel like a genuine test of understanding, not a memory test
- Frame questions as scenarios or implications: "Why did X happen?", "What does this signal about Y?", "Which group stands to gain most from Z?"
- NEVER ask a question whose answer appears word-for-word in the headline or context
- NEVER ask about exact dates, death tolls, or facts that age poorly
- Vary the angle: causes, consequences, who benefits, what precedent it sets, what the alternatives were

Wrong options:
- Must be genuinely plausible — things a smart person could reasonably guess
- Use common misconceptions, adjacent real-world facts, or plausible-but-wrong outcomes
- Never use obviously absurd options

Answer quality:
- Correct answer must be clearly supported by the context snippet — not a guess
- Mark difficulty "easy" if the answer is in the context; "hard" if it requires inference

Explanation:
- 2 sentences — reveal WHY it matters beyond the headline: the systemic cause, historical parallel, or future implication
- Never restate the question or just confirm the answer

STEP 3 — Spread questions across different stories. Do not write 2 questions about the same article.

JSON format (one object per question):
{"questions":[{"question":"...","options":["A","B","C","D"],"correct_index":0,"difficulty":"easy","category":"World","explanation":"2 sentences on the bigger picture.","story_summary":"2-3 sentences of full context.","source":"Source name"}]}
''';

  // ─────────────────────────────────────────────────────────────────────────
  // PUBLIC ENTRY POINT
  // ─────────────────────────────────────────────────────────────────────────

  static Future<List<Question>> generateQuestions({
    required List<NewsArticle> articles,
    bool forceRefresh = false,
    bool bonusRound = false,
    int? replaySeed,
    String? categoryFilter,
  }) async {
    final isCategoryQuiz = categoryFilter != null;

    // 1. Return cache if fresh (only for daily quiz)
    // TEMP: cache bypass disabled
    // if (!forceRefresh && !bonusRound && !isCategoryQuiz) {
    //   final cached = StorageService.getCachedQuestions();
    //   if (cached != null && cached.length == AppConstants.questionsPerQuiz) {
    //     dev.log('[Quiz] Returning ${cached.length} cached questions',
    //         name: 'Briefed');
    //     return cached;
    //   }
    // } else if (forceRefresh && !bonusRound && !isCategoryQuiz) {
    //   await StorageService.clearQuestionCache();
    //   dev.log('[Quiz] Cache cleared', name: 'Briefed');
    // }
    print("=== BYPASSING CACHE - GENERATING FRESH ===");
    print("=== articles count: ${articles.length} ===");

    List<NewsArticle> sourceArticles;
    if (isCategoryQuiz) {
      final filtered = articles
          .where((a) =>
              a.category.toLowerCase() == categoryFilter.toLowerCase())
          .toList();
      sourceArticles = _quizArticles(filtered.isNotEmpty ? filtered : articles);
      dev.log(
          '[Quiz] Category quiz "$categoryFilter" — ${filtered.length} matching articles',
          name: 'Briefed');
    } else if (bonusRound) {
      sourceArticles = _bonusArticles(articles, replaySeed: replaySeed);
    } else {
      sourceArticles = _quizArticles(articles);
    }
    if (sourceArticles.isEmpty) {
      return mockQuestions(bonusRound: bonusRound, replaySeed: replaySeed);
    }

    // Send up to 15 top-ranked articles so the AI can select the best 5 stories.
    // Articles with no description are deprioritised by the scorer.
    final headlines = sourceArticles.take(15).toList().asMap().entries.map((e) {
      final i = e.key + 1;
      final a = e.value;
      final category = a.category.trim().isEmpty ? 'News' : a.category.trim();
      final source = a.sourceName.trim().isEmpty ? 'News' : a.sourceName.trim();
      final desc = a.description.trim();
      final snippet = desc.isNotEmpty
          ? '\n  Context: ${desc.length > 280 ? '${desc.substring(0, 280)}…' : desc}'
          : '';
      return '$i. [$category] ${a.title} (Source: $source)$snippet';
    }).join('\n\n');

    final variantHint =
        replaySeed == null ? '' : ' Replay variant: $replaySeed.';
    final count = sourceArticles.take(15).length;
    final String userMsg;
    if (isCategoryQuiz) {
      final label = categoryFilter[0].toUpperCase() + categoryFilter.substring(1);
      userMsg =
          'Here are $count $label news articles. Select the 5 most interesting and write one question per story:\n\n$headlines\n\nReturn only JSON.';
    } else if (bonusRound) {
      userMsg =
          'Here are $count news articles.$variantHint Select 5 different stories from the daily quiz and write a BONUS question for each — different angles, different answer positions:\n\n$headlines\n\nReturn only JSON.';
    } else {
      userMsg =
          'Here are $count news articles. Select the 5 most globally significant stories and write one question per story:\n\n$headlines\n\nReturn only JSON.';
    }

    // 2. Try Groq first
    const groqKey = AppConstants.groqApiKey;
    if (groqKey.isNotEmpty && groqKey != 'YOUR_GROQ_API_KEY') {
      dev.log('[Quiz] Trying Groq...', name: 'Briefed');
      try {
        final qs = await _callGroq(userMsg);
        if (qs.length == AppConstants.questionsPerQuiz) {
          if (!bonusRound && !isCategoryQuiz) await StorageService.cacheQuestions(qs);
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
          if (!bonusRound && !isCategoryQuiz) await StorageService.cacheQuestions(qs);
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
    final ranked = _quizArticles(articles);
    if (ranked.isEmpty) return ranked;
    final offset = replaySeed ?? AppConstants.questionsPerQuiz;
    final rotated = [
      ...ranked.skip(offset % ranked.length),
      ...ranked.take(offset % ranked.length),
    ];
    if (rotated.length > AppConstants.questionsPerQuiz) {
      return rotated.take(AppConstants.questionsPerQuiz).toList();
    }
    return rotated.reversed.toList();
  }

  static List<NewsArticle> _quizArticles(List<NewsArticle> articles) {
    final seen = <String>{};
    final deduped = <NewsArticle>[];
    for (final article in articles) {
      final title = article.title.trim();
      if (title.isEmpty) continue;
      final key = article.link.trim().isNotEmpty
          ? article.link.trim().toLowerCase()
          : title.toLowerCase();
      if (seen.add(key)) deduped.add(article);
    }

    final indexed = deduped.asMap().entries.toList()
      ..sort((a, b) {
        final scoreDiff =
            _quizArticleScore(b.value) - _quizArticleScore(a.value);
        if (scoreDiff != 0) return scoreDiff;
        return a.key.compareTo(b.key);
      });
    return indexed.map((e) => e.value).toList();
  }

  static int _quizArticleScore(NewsArticle article) {
    final title = article.title.toLowerCase();
    final source = article.sourceName.toLowerCase();
    final category = article.category.toLowerCase();
    var score = 0;

    // Articles with a description give the AI real context to write good questions.
    if (article.description.trim().length > 60) { score += 10; }
    else if (article.description.trim().isNotEmpty) { score += 4; }

    if (category.contains('world')) score += 12;
    if (category.contains('science')) score += 10;
    if (category.contains('business') || category.contains('technology')) {
      score += 8;
    }
    if (category.contains('sports') || category.contains('entertainment')) {
      score += 2;
    }

    const trustedGlobalSources = [
      'associated press',
      'ap news',
      'reuters',
      'bbc',
      'the guardian',
      'cnn',
      'abc news',
      'cbs news',
      'nbc news',
      'npr',
      'al jazeera',
      'financial times',
      'bloomberg',
      'the wall street journal',
      'new york times',
      'washington post',
    ];
    for (final trusted in trustedGlobalSources) {
      if (source.contains(trusted)) {
        score += 12;
        break;
      }
    }

    const globalSignals = [
      'president',
      'prime minister',
      'election',
      'government',
      'supreme court',
      'congress',
      'parliament',
      'war',
      'ceasefire',
      'ukraine',
      'russia',
      'china',
      'india',
      'israel',
      'gaza',
      'iran',
      'united nations',
      'nato',
      'climate',
      'tariff',
      'trade',
      'economy',
      'inflation',
      'interest rate',
      'market',
      'stock',
      'ai',
      'artificial intelligence',
      'openai',
      'google',
      'microsoft',
      'apple',
      'meta',
      'tesla',
      'nvidia',
      'space',
      'nasa',
      'world cup',
      'olympics',
    ];
    for (final signal in globalSignals) {
      if (title.contains(signal)) score += 5;
    }

    const localSignals = [
      'local',
      'council',
      'suburb',
      'county',
      'school board',
      'traffic',
      'road closure',
      'weather warning',
    ];
    for (final signal in localSignals) {
      if (title.contains(signal)) score -= 6;
    }

    return score;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // GROQ — OpenAI-compatible, Llama 3.1 70B
  // Free: 14,400 req/day, 30 req/min
  // ─────────────────────────────────────────────────────────────────────────

  static Future<List<Question>> _callGroq(String userMsg) async {
    final body = jsonEncode({
      'model': 'llama-3.3-70b-versatile',
      'temperature': 0.6,
      'max_tokens': 2500,
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
        'temperature': 0.6,
        'maxOutputTokens': 2500,
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
