// ─────────────────────────────────────────────────────────────────────────────
// BRIEFED — App Constants
// API keys are supplied at build/run time with --dart-define.
// ─────────────────────────────────────────────────────────────────────────────

class AppConstants {
  // ── API KEYS ──────────────────────────────────────────────────────────────
  static const String groqApiKey = String.fromEnvironment('GROQ_API_KEY');
  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const String newsApiKey = String.fromEnvironment('NEWSDATA_API_KEY');

  // ── API ENDPOINTS ─────────────────────────────────────────────────────────
  static const String groqEndpoint =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String geminiEndpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';
  static const String newsEndpoint = 'https://newsdata.io/api/1/news';

  // ── APP CONFIG ────────────────────────────────────────────────────────────
  static const String appName = 'Briefed';
  static const String appTagline = 'Stay Briefed. Stay Sharp.';
  static const String defaultCountry = 'au'; // Australia fallback
  static const String defaultLanguage = 'en';
  static const int questionsPerQuiz = 5;
  static const int timerSeconds = 15;

  // ── SCORING ───────────────────────────────────────────────────────────────
  static const int pointsEasy = 10;
  static const int pointsHard = 25;
  static const int streakBonusPoints = 50; // awarded at 7+ day streak

  // ── STORAGE KEYS ─────────────────────────────────────────────────────────
  static const String keyThemeMode = 'theme_mode';
  static const String keyOnboardingDone = 'onboarding_done';
  static const String keyUserName = 'user_name';
  static const String keySelectedCategories = 'selected_categories';
  static const String keyNotificationHour = 'notification_hour';
  static const String keyNotificationMinute = 'notification_minute';
  static const String keyStreak = 'streak';
  static const String keyLastPlayedDate = 'last_played_date';
  static const String keyKnowledgeScore = 'knowledge_score';
  static const String keyTotalQuizzes = 'total_quizzes';
  static const String keyUserCountry = 'user_country';
  static const String keyCachedQuestions = 'cached_questions';
  static const String keyCachedQuestionsDate = 'cached_questions_date';
  static const String keyQuizHistory = 'quiz_history';
  static const String keyUserPhotoUrl = 'user_photo_url';

  // ── CATEGORIES ────────────────────────────────────────────────────────────
  static const List<Map<String, String>> allCategories = [
    {'id': 'world', 'label': 'World', 'newsId': 'world'},
    {'id': 'tech', 'label': 'Technology', 'newsId': 'technology'},
    {'id': 'business', 'label': 'Business', 'newsId': 'business'},
    {'id': 'sports', 'label': 'Sports', 'newsId': 'sports'},
    {'id': 'entertainment', 'label': 'Entertainment', 'newsId': 'entertainment'},
  ];

  // ── MOCK QUESTIONS (fallback if API fails) ────────────────────────────────
  static const List<Map<String, dynamic>> mockQuestions = [
    {
      'question': 'Which country became the first to pass a law banning social media for children under 16?',
      'options': ['France', 'Australia', 'Sweden', 'Germany'],
      'correct_index': 1,
      'difficulty': 'easy',
      'category': 'World',
      'explanation': 'Australia passed landmark legislation making it illegal for children under 16 to have social media accounts, the strictest such law globally.',
      'story_summary': 'Australia became the first country to ban social media for under-16s. Tech companies face fines up to \$50M for non-compliance. The law is the strictest of its kind globally.',
      'source': 'BBC News',
    },
    {
      'question': 'Which AI model recently scored in the 90th percentile on the US bar exam?',
      'options': ['Gemini Ultra', 'GPT-4o', 'Claude 3', 'Llama 3'],
      'correct_index': 1,
      'difficulty': 'easy',
      'category': 'Technology',
      'explanation': 'OpenAI\'s GPT-4o demonstrated remarkable legal reasoning, achieving scores placing it among top-tier US legal professionals.',
      'story_summary': 'GPT-4o demonstrated remarkable legal reasoning. The model showed particular strength in contract law. Legal experts are divided on the implications.',
      'source': 'The Verge',
    },
    {
      'question': 'India\'s stock market recently surpassed which market capitalisation milestone?',
      'options': ['\$3 trillion', '\$4 trillion', '\$5 trillion', '\$6 trillion'],
      'correct_index': 1,
      'difficulty': 'easy',
      'category': 'Business',
      'explanation': 'India crossed \$4 trillion in market cap, overtaking Hong Kong to become the world\'s fourth largest stock market.',
      'story_summary': 'India crossed \$4 trillion in market cap. This made India the world\'s fourth largest stock market. Foreign investors poured over \$20 billion in this year.',
      'source': 'Reuters',
    },
    {
      'question': 'Which country won the most gold medals at the 2024 Paris Olympics?',
      'options': ['China', 'France', 'Great Britain', 'United States'],
      'correct_index': 3,
      'difficulty': 'hard',
      'category': 'Sports',
      'explanation': 'The United States topped the gold medal tally at Paris 2024, continuing their dominance in the Summer Olympics.',
      'story_summary': 'The United States led the gold medal count at the Paris 2024 Olympics. France performed strongly as the host nation. China finished second overall.',
      'source': 'BBC Sport',
    },
    {
      'question': 'How many nations have now signed NASA\'s Artemis Accords for space cooperation?',
      'options': ['28 nations', '35 nations', '42 nations', '50 nations'],
      'correct_index': 2,
      'difficulty': 'hard',
      'category': 'World',
      'explanation': 'NASA\'s Artemis Accords now has 42 signatory countries, expanding international cooperation for lunar exploration and peaceful civil space activities.',
      'story_summary': 'NASA\'s Artemis Accords reached 42 signatory nations. The accords establish norms for responsible space behaviour. China and Russia have not signed.',
      'source': 'NASA',
    },
  ];

  // ── MOCK NEWS ARTICLES ────────────────────────────────────────────────────
  static const List<Map<String, dynamic>> mockArticles = [
    {
      'title': 'Australia bans social media for children under 16 — fines up to \$50M',
      'description': 'Australia has become the first country to pass legislation banning social media platforms from allowing users under 16 to create accounts. Tech companies face fines up to \$50 million for non-compliance.',
      'source_name': 'BBC News',
      'category': 'world',
      'pubDate': '2025-04-16',
      'link': 'https://bbc.com',
    },
    {
      'title': 'OpenAI\'s GPT-4o scores 90th percentile on the bar exam',
      'description': 'OpenAI\'s latest model demonstrated remarkable legal reasoning, passing the bar exam at a level that places it among the top tier of US legal professionals.',
      'source_name': 'The Verge',
      'category': 'technology',
      'pubDate': '2025-04-16',
      'link': 'https://theverge.com',
    },
    {
      'title': 'India overtakes Hong Kong as world\'s fourth largest stock market',
      'description': 'India\'s equity market crossed \$4 trillion in market capitalisation, surpassing Hong Kong and making India the fourth largest stock market globally.',
      'source_name': 'Reuters',
      'category': 'business',
      'pubDate': '2025-04-16',
      'link': 'https://reuters.com',
    },
    {
      'title': 'Australia wins back-to-back Women\'s World Cup with historic victory',
      'description': 'The Matildas claimed a stunning second consecutive FIFA Women\'s World Cup title, defeating Spain 2-1 in front of a record crowd in Sydney.',
      'source_name': 'ABC Sport',
      'category': 'sports',
      'pubDate': '2025-04-16',
      'link': 'https://abc.net.au',
    },
    {
      'title': 'Apple acquires voice-cloning AI startup for estimated \$400 million',
      'description': 'Apple has acquired a startup specialising in ultra-fast voice cloning technology that can replicate a person\'s voice from just 3 seconds of audio.',
      'source_name': 'Bloomberg',
      'category': 'technology',
      'pubDate': '2025-04-16',
      'link': 'https://bloomberg.com',
    },
    {
      'title': '42 nations now signed NASA\'s Artemis Accords for space cooperation',
      'description': 'NASA\'s Artemis Accords for peaceful civil space exploration now has 42 signatory countries, expanding international cooperation for lunar exploration.',
      'source_name': 'NASA',
      'category': 'world',
      'pubDate': '2025-04-16',
      'link': 'https://nasa.gov',
    },
  ];
}
