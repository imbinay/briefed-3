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
You are a quiz question writer for Briefed, a daily news quiz app.
Your questions must feel like a smart pub trivia night — specific,
engaging, and satisfying to answer correctly.

CORE RULES:
1. Question must be a complete grammatical sentence (15–20 words)
2. Must start with: Who / What / When / Where / Which / How many / How much
3. Include enough context so the question makes sense on its own
   BAD:  "How many soldiers and police?"
   GOOD: "How many soldiers did Bolivia deploy to clear roadblocks near La Paz?"
4. NEVER reference "the article", "the report", journalist names, or the source
   BAD:  "What did Bloomberg report about the supertanker?"
   GOOD: "Which country was the US Navy-halted supertanker ultimately heading to?"
5. The correct answer must be a specific fact — a name, number, place, or outcome
6. All 4 options must be the same type:
   - If correct answer is a country → all 4 options are countries
   - If correct answer is a number → all 4 options are numbers
   - If correct answer is a person → all 4 options are person names
7. Wrong options must be believable — real names/places/numbers that are plausible
8. NEVER write questions where the answer is obvious from the headline
   The answer must require knowing a detail from the article body
9. NEVER write about: celebrity gossip, opinion pieces, product reviews,
   shopping deals, or vague ongoing situations
10. Explanation: exactly 2 sentences.
    Sentence 1: state the correct answer and key context.
    Sentence 2: add one genuinely interesting related fact.
11. Return ONLY raw JSON. No markdown, no backticks, no preamble.

GREAT question examples:
"How many soldiers did Bolivia deploy to clear protest roadblocks near La Paz?"
"Which airline did Berkshire Hathaway invest \$2.65 billion in during May 2026?"
"What score did the San Antonio Spurs defeat the Minnesota Timberwolves by?"
"Which country did the US Navy halt a supertanker from reaching?"
"How much did Warren Buffett and Stephen Curry raise for charity at auction?"
"Who resigned from the UK cabinet to contest the Labour leadership against Starmer?"

BORING question examples — never do these:
"How many soldiers and police?" ← incomplete, no context
"What score Spurs beat Timberwolves?" ← grammatically broken
"How much less is clone?" ← meaningless without context
"What happened in Louisiana?" ← vague, no specific fact
"Who will stand against Starmer?" ← too vague, no context

JSON format — return exactly this structure:
{
  "questionText": "complete grammatical sentence 15-20 words",
  "questionType": "who|what|when|where|which|how_many|how_much",
  "options": ["string","string","string","string"],
  "correctAnswerIndex": 0,
  "explanation": "exactly 2 sentences. First: answer + context. Second: interesting related fact.",
  "difficulty": "easy|medium|hard|veryHard|expert"
}

Difficulty guide:
easy     = answer is well-known, most people would get it
medium   = requires following the news somewhat
hard     = requires knowing a specific detail
veryHard = a specific number, date, or stat
expert   = requires connecting multiple pieces of information
''';

  static Future<QuizQuestion> generateForArticle(RankedArticle article) async {
    print('=== GENERATING Q FOR: ${article.title}');
    print('=== SUMMARY LENGTH: ${article.summary.length} chars');

    final userMsg = '''
Article title: ${article.title}
Article URL: ${article.url}
Article summary: ${article.summary}
Source: ${article.sourceName}
Category: ${article.category.name}

Context: The summary above is the full text available. Write a quiz question
based only on specific facts stated in this summary — a name, number, place,
date, or outcome that is clearly stated. Do not invent facts.

Write one quiz question from this article.
''';

    if (ApiConfig.groqApiKey.isNotEmpty) {
      try {
        print("CALLING AI FOR: ${article.title}");
        final q = await _callGroq(userMsg, article);
        dev.log(
            'Generated via Groq: ${article.title.substring(0, article.title.length.clamp(0, 40))}',
            name: _tag);
        return q;
      } catch (e) {
        print('GROQ FAILED: $e → trying Gemini');
      }
    }

    const geminiKey = AppConstants.geminiApiKey;
    if (geminiKey.isNotEmpty) {
      try {
        final q = await _callGemini(userMsg, article);
        dev.log(
            'Generated via Gemini: ${article.title.substring(0, article.title.length.clamp(0, 40))}',
            name: _tag);
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
      'model': 'llama-3.3-70b-versatile',
      'temperature': 0.5,
      'max_tokens': 1000,
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

    print('GROQ RAW RESPONSE: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception(
          'Groq HTTP ${response.statusCode}: ${response.body.substring(0, response.body.length.clamp(0, 200))}');
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
          Uri.parse(AppConstants.geminiEndpoint),
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': AppConstants.geminiApiKey,
          },
          body: body,
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Gemini HTTP ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final text =
        data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String? ??
            '';
    return _parse(text, article);
  }

  static QuizQuestion _parse(String raw, RankedArticle article) {
    final cleaned = raw.replaceAll('```json', '').replaceAll('```', '').trim();
    late final Map<String, dynamic> parsed;
    try {
      parsed = jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (e) {
      throw Exception(
          'JSON parse failed: $e\nRaw: ${cleaned.substring(0, cleaned.length.clamp(0, 300))}');
    }

    final questionText = (parsed['questionText'] as String? ?? '').trim();
    final typeStr = (parsed['questionType'] as String? ?? 'what')
        .toLowerCase()
        .replaceAll('_', '');
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
        (t) => t.name.toLowerCase() == typeStr,
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
