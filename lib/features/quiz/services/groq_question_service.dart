import 'dart:convert';
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;
import '../../../config/api_config.dart';
import '../../../core/constants.dart';
import '../../news/models/ranked_article.dart';
import '../models/quiz_question.dart';

class GroqQuestionService {
  static const _tag = 'Briefed/QuizGen';
  static const _groqEndpoint =
      'https://api.groq.com/openai/v1/chat/completions';

  static const _systemPrompt = '''
You are a quiz question writer for a news quiz app called Briefed. Your job is to write one sharp, engaging multiple choice question from a news article.

STRICT RULES:
1. Question must be maximum 12 words
2. Start with Who / What / When / Where / Which
3. The correct answer must be a specific fact from the article — a name, number, place, or outcome
4. Wrong answers must be believable — not obviously wrong. Use real names/places/numbers that are plausible but incorrect
5. Never write opinion or analysis questions
6. Never reference "the article" or "according to the report" in the question
7. The explanation must be exactly 2 sentences and teach the reader something real
8. Return ONLY valid JSON. No preamble, no markdown, no backticks

JSON format:
{
  "questionText": "string (max 12 words)",
  "questionType": "who|what|when|where|which",
  "options": ["string","string","string","string"],
  "correctAnswerIndex": 0,
  "explanation": "string (2 sentences)",
  "difficulty": "easy|medium|hard|veryHard|expert"
}

Difficulty guide:
- easy: The answer is in the headline itself
- medium: Answer requires reading the summary
- hard: Requires knowing context beyond article
- veryHard: Specific number/date/stat question
- expert: Requires connecting multiple facts
''';

  static Future<QuizQuestion> generateForArticle(RankedArticle article) async {
    final userMsg = '''
Article title: ${article.title}
Article summary: ${article.summary}
Source: ${article.sourceName}
Category: ${article.category.name}

Write one quiz question from this article.
''';

    if (ApiConfig.groqApiKey.isNotEmpty) {
      try {
        print("CALLING AI FOR: ${article.title}");
        final q = await _callGroq(userMsg, article);
        dev.log('Generated via Groq: ${article.title.substring(0, article.title.length.clamp(0, 40))}', name: _tag);
        return q;
      } catch (e) {
        dev.log('Groq failed: $e — trying Gemini', name: _tag);
      }
    }

    const geminiKey = AppConstants.geminiApiKey;
    if (geminiKey.isNotEmpty) {
      try {
        final q = await _callGemini(userMsg, article);
        dev.log('Generated via Gemini: ${article.title.substring(0, article.title.length.clamp(0, 40))}', name: _tag);
        return q;
      } catch (e) {
        dev.log('Gemini failed: $e', name: _tag);
      }
    }

    throw Exception('Question generation failed for: ${article.title}');
  }

  static Future<QuizQuestion> _callGroq(
      String userMsg, RankedArticle article) async {
    final body = jsonEncode({
      'model': 'llama3-70b-8192',
      'temperature': 0.7,
      'max_tokens': 512,
      'messages': [
        {'role': 'system', 'content': _systemPrompt},
        {'role': 'user', 'content': userMsg},
      ],
      'response_format': {'type': 'json_object'},
    });

    final response = await http
        .post(
          Uri.parse(_groqEndpoint),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${ApiConfig.groqApiKey}',
          },
          body: body,
        )
        .timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) {
      throw Exception('Groq HTTP ${response.statusCode}: ${response.body.substring(0, response.body.length.clamp(0, 200))}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final content =
        data['choices']?[0]?['message']?['content'] as String? ?? '';
    return _parse(content, article);
  }

  static Future<QuizQuestion> _callGemini(
      String userMsg, RankedArticle article) async {
    final prompt = '$_systemPrompt\n\n$userMsg';
    final body = jsonEncode({
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 512},
    });

    final response = await http
        .post(
          Uri.parse('${AppConstants.geminiEndpoint}?key=${AppConstants.geminiApiKey}'),
          headers: {'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Gemini HTTP ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final text = data['candidates']?[0]?['content']?['parts']?[0]?['text']
            as String? ??
        '';
    return _parse(text, article);
  }

  static QuizQuestion _parse(String raw, RankedArticle article) {
    final cleaned =
        raw.replaceAll('```json', '').replaceAll('```', '').trim();
    late final Map<String, dynamic> parsed;
    try {
      parsed = jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('JSON parse failed: $e\nRaw: ${cleaned.substring(0, cleaned.length.clamp(0, 300))}');
    }

    final questionText = (parsed['questionText'] as String? ?? '').trim();
    final typeStr = (parsed['questionType'] as String? ?? 'what').toLowerCase();
    final options = List<String>.from(parsed['options'] as List? ?? []);
    final correctIdx = (parsed['correctAnswerIndex'] as num? ?? 0).toInt();
    final explanation = (parsed['explanation'] as String? ?? '').trim();
    final diffStr = (parsed['difficulty'] as String? ?? 'medium').trim();

    if (questionText.isEmpty || options.length < 4) {
      throw Exception('Invalid AI response: question or options missing');
    }

    final difficulty = QuestionDifficulty.fromString(diffStr);

    return QuizQuestion(
      id: '${article.id}_${DateTime.now().millisecondsSinceEpoch}',
      articleId: article.id,
      articleTitle: article.title,
      articleSummary: article.summary,
      articleSourceName: article.sourceName,
      questionText: questionText,
      questionType: QuestionType.values.firstWhere(
        (t) => t.name == typeStr,
        orElse: () => QuestionType.what,
      ),
      options: options.take(4).toList(),
      correctAnswerIndex: correctIdx.clamp(0, 3),
      explanation: explanation,
      difficulty: difficulty,
      points: difficulty.points,
      imageUrl: article.imageUrl,
      hasImage: article.imageUrl != null && article.imageUrl!.isNotEmpty,
      category: article.category,
      generatedAt: DateTime.now(),
    );
  }
}
