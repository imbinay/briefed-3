import '../models/news_category.dart';

class NewsSourceConfig {
  // ── APPROVED SOURCES PER CATEGORY ────────────────────────────────────────

  static const Map<NewsCategory, Set<String>> approvedSources = {
    NewsCategory.world: {
      'bbc.co.uk', 'reuters.com', 'apnews.com', 'theguardian.com',
      'aljazeera.com', 'abc.net.au', 'france24.com', 'dw.com',
      'theconversation.com', 'foreignpolicy.com',
    },
    NewsCategory.politics: {
      'bbc.co.uk', 'abc.net.au', 'theguardian.com', 'smh.com.au',
      'theaustralian.com.au', 'theage.com.au', 'politico.com',
      'thehill.com', 'apnews.com', 'reuters.com', 'crikey.com.au',
      'theconversation.com',
    },
    NewsCategory.sports: {
      'espn.com', 'bbc.co.uk', 'foxsports.com.au', 'theguardian.com',
      'skysports.com', 'theathletic.com', 'afl.com.au', 'cricket.com.au',
      'sportingnews.com', 'abc.net.au',
    },
    NewsCategory.technology: {
      'theverge.com', 'techcrunch.com', 'arstechnica.com', 'wired.com',
      'engadget.com', 'technologyreview.com', '9to5google.com', '9to5mac.com',
      'theguardian.com', 'abc.net.au',
    },
    NewsCategory.business: {
      'ft.com', 'bloomberg.com', 'cnbc.com', 'afr.com', 'wsj.com',
      'forbes.com', 'businessinsider.com', 'theguardian.com',
      'reuters.com', 'abc.net.au',
    },
  };

  // ── SOURCE QUALITY SCORES (Tier 1=100, 2=80, 3=60, 4=40) ─────────────────

  static const Map<String, int> _qualityScores = {
    // Tier 1 — 100
    'reuters.com': 100, 'apnews.com': 100, 'bbc.co.uk': 100,
    'ft.com': 100, 'bloomberg.com': 100, 'theguardian.com': 100,
    // Tier 2 — 80
    'espn.com': 80, 'techcrunch.com': 80, 'theverge.com': 80,
    'arstechnica.com': 80, 'abc.net.au': 80, 'afr.com': 80,
    'theathletic.com': 80, 'politico.com': 80,
    // Tier 3 — 60
    'wired.com': 60, 'cnbc.com': 60, 'smh.com.au': 60,
    'theage.com.au': 60, 'foxsports.com.au': 60, 'wsj.com': 60,
    'aljazeera.com': 60, 'france24.com': 60, 'engadget.com': 60,
    'forbes.com': 60, 'theconversation.com': 60,
  };

  static int qualityScore(String domain) =>
      _qualityScores[domain] ?? 40; // Tier 4 default

  // ── DISPLAY NAMES ─────────────────────────────────────────────────────────

  static const Map<String, String> _displayNames = {
    'bbc.co.uk': 'BBC News',
    'reuters.com': 'Reuters',
    'theguardian.com': 'The Guardian',
    'apnews.com': 'AP News',
    'espn.com': 'ESPN',
    'techcrunch.com': 'TechCrunch',
    'theverge.com': 'The Verge',
    'bloomberg.com': 'Bloomberg',
    'ft.com': 'Financial Times',
    'afr.com': 'AFR',
    'abc.net.au': 'ABC News',
    'afl.com.au': 'AFL',
    'cnbc.com': 'CNBC',
    'foxsports.com.au': 'Fox Sports',
    'wired.com': 'Wired',
    'politico.com': 'Politico',
    'smh.com.au': 'Sydney Morning Herald',
    'theage.com.au': 'The Age',
    'aljazeera.com': 'Al Jazeera',
    'france24.com': 'France 24',
    'dw.com': 'DW News',
    'arstechnica.com': 'Ars Technica',
    'theathletic.com': 'The Athletic',
    'forbes.com': 'Forbes',
    'wsj.com': 'Wall Street Journal',
    'businessinsider.com': 'Business Insider',
    'technologyreview.com': 'MIT Technology Review',
    'engadget.com': 'Engadget',
    '9to5google.com': '9to5Google',
    '9to5mac.com': '9to5Mac',
    'theconversation.com': 'The Conversation',
    'thehill.com': 'The Hill',
    'skysports.com': 'Sky Sports',
    'cricket.com.au': 'Cricket Australia',
    'sportingnews.com': 'Sporting News',
    'foreignpolicy.com': 'Foreign Policy',
    'crikey.com.au': 'Crikey',
    'theaustralian.com.au': 'The Australian',
  };

  static String displayName(String domain) {
    if (_displayNames.containsKey(domain)) return _displayNames[domain]!;
    // Capitalise domain name as fallback
    final base = domain.split('.').first;
    return base.isEmpty
        ? domain
        : base[0].toUpperCase() + base.substring(1);
  }

  static bool isApproved(String domain, NewsCategory category) =>
      approvedSources[category]?.contains(domain) ?? false;

  static String parseDomain(String url) {
    try {
      final host = Uri.parse(url).host.toLowerCase();
      return host.startsWith('www.') ? host.substring(4) : host;
    } catch (_) {
      return '';
    }
  }
}
