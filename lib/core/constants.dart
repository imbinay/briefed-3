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
  static const String defaultAnonymousName = 'Briefed Explorer';
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
  static const String keyIsPro = 'is_pro';

  // ── CATEGORIES ────────────────────────────────────────────────────────────
  static const List<Map<String, String>> allCategories = [
    {'id': 'world', 'label': 'World', 'newsId': 'world'},
    {'id': 'tech', 'label': 'Technology', 'newsId': 'technology'},
    {'id': 'business', 'label': 'Business', 'newsId': 'business'},
    {'id': 'sports', 'label': 'Sports', 'newsId': 'sports'},
    {
      'id': 'entertainment',
      'label': 'Entertainment',
      'newsId': 'entertainment'
    },
  ];

  // ── MOCK QUESTIONS (fallback if API fails) ────────────────────────────────
  static const List<Map<String, dynamic>> mockQuestions = [
    {
      'question':
          'Which state\'s majority-Black congressional district was struck down by the US Supreme Court?',
      'options': ['Georgia', 'Louisiana', 'Alabama', 'Mississippi'],
      'correct_index': 1,
      'difficulty': 'easy',
      'category': 'Politics',
      'explanation':
          'The Supreme Court ruling focused on Louisiana\'s congressional map and a district created to give Black voters a stronger chance to elect a preferred candidate.',
      'story_summary':
          'The decision became one of the leading US political stories of the day. It matters because congressional maps can shape representation and party control in close elections.',
      'source': 'Associated Press',
    },
    {
      'question':
          'Which US defence secretary was scheduled to testify before a Senate committee?',
      'options': ['Pete Hegseth', 'Lloyd Austin', 'Mark Esper', 'Robert Gates'],
      'correct_index': 0,
      'difficulty': 'easy',
      'category': 'Politics',
      'explanation':
          'AP listed Defense Secretary Pete Hegseth\'s Senate committee testimony among its top stories for April 30, 2026.',
      'story_summary':
          'Cabinet testimony can become a major accountability moment for an administration. Senators use these hearings to question policy, spending, and agency leadership.',
      'source': 'Associated Press',
    },
    {
      'question':
          'Which region was recovering from widespread blackouts in AP\'s April 29 top stories?',
      'options': [
        'Spain and Portugal',
        'Japan and South Korea',
        'Canada and Alaska',
        'Brazil and Argentina'
      ],
      'correct_index': 0,
      'difficulty': 'easy',
      'category': 'World',
      'explanation':
          'Spain and Portugal were highlighted as recovering from blackouts, making the Iberian power disruption a prominent international story.',
      'story_summary':
          'Large power failures can ripple through transport, hospitals, communications, and businesses. Recovery stories often focus on both restoring service and finding the cause.',
      'source': 'Associated Press',
    },
    {
      'question':
          'Why was the White House Correspondents\' Dinner shooting still in the news?',
      'options': [
        'Court filings described the suspect\'s actions before the attack',
        'The dinner was moved permanently out of Washington',
        'The suspect was elected to public office',
        'The event was converted into a sports fundraiser'
      ],
      'correct_index': 0,
      'difficulty': 'hard',
      'category': 'World',
      'explanation':
          'AP reported that court filings said the suspect took a picture of himself before the attack, adding detail to the investigation.',
      'story_summary':
          'Follow-up reporting after major security incidents often centers on motive, planning, and missed warning signs. Those details can influence future protective measures.',
      'source': 'Associated Press',
    },
    {
      'question':
          'What made Microsoft\'s Copilot rollout to Accenture notable in tech news?',
      'options': [
        'It was described as a very large enterprise deployment',
        'It removed Copilot from Microsoft 365',
        'It replaced Accenture\'s consulting business with hardware sales',
        'It made Copilot available only to government workers'
      ],
      'correct_index': 0,
      'difficulty': 'hard',
      'category': 'Technology',
      'explanation':
          'Reuters was cited in tech coverage saying Microsoft was rolling out Microsoft 365 Copilot across Accenture\'s roughly 743,000 employees.',
      'story_summary':
          'Large workplace AI deployments are watched closely because they test whether generative AI can move from pilots into everyday enterprise use. The scale gives Microsoft a major case study.',
      'source': 'Reuters',
    },
  ];

  // ── MOCK NEWS ARTICLES ────────────────────────────────────────────────────
  static const List<Map<String, dynamic>> mockArticles = [
    {
      'title':
          'Supreme Court strikes down Louisiana majority-Black congressional district',
      'description':
          'The US Supreme Court ruling over Louisiana\'s congressional map became one of AP\'s top stories for April 30, 2026.',
      'source_name': 'Associated Press',
      'category': 'politics',
      'pubDate': '2026-04-30',
      'link': 'https://apnews.com',
    },
    {
      'title': 'Defense Secretary Hegseth to testify before Senate committee',
      'description':
          'AP highlighted Defense Secretary Pete Hegseth\'s planned Senate committee testimony among the day\'s major US political stories.',
      'source_name': 'Associated Press',
      'category': 'politics',
      'pubDate': '2026-04-30',
      'link': 'https://apnews.com',
    },
    {
      'title': 'Spain and Portugal recover from widespread blackouts',
      'description':
          'AP\'s April 29 top stories included Spain and Portugal recovering after major blackouts affected the region.',
      'source_name': 'Associated Press',
      'category': 'world',
      'pubDate': '2026-04-29',
      'link': 'https://apnews.com',
    },
    {
      'title':
          'Court filings add detail in White House Correspondents\' Dinner shooting case',
      'description':
          'AP reported that filings said the shooting suspect took a picture of himself before the attack.',
      'source_name': 'Associated Press',
      'category': 'world',
      'pubDate': '2026-04-30',
      'link': 'https://apnews.com',
    },
    {
      'title':
          'Microsoft rolls out Copilot to more than 740,000 Accenture workers',
      'description':
          'Reuters was cited in tech coverage describing the Accenture rollout as a major enterprise AI deployment.',
      'source_name': 'Reuters',
      'category': 'technology',
      'pubDate': '2026-04-29',
      'link': 'https://reuters.com',
    },
    {
      'title': 'King Charles III to finish US tour',
      'description':
          'AP listed King Charles III finishing his US tour among its top stories for April 30, 2026.',
      'source_name': 'Associated Press',
      'category': 'world',
      'pubDate': '2026-04-30',
      'link': 'https://apnews.com',
    },
  ];
}
