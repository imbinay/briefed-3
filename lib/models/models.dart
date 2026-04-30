// ─────────────────────────────────────────────────────────────────────────────
// QUESTION MODEL
// ─────────────────────────────────────────────────────────────────────────────

class Question {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String difficulty; // 'easy' or 'hard'
  final String category;
  final String explanation;
  final String storySummary;
  final String source;

  const Question({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.difficulty,
    required this.category,
    required this.explanation,
    required this.storySummary,
    required this.source,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      question: json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctIndex: json['correct_index'] ?? 0,
      difficulty: json['difficulty'] ?? 'easy',
      category: json['category'] ?? 'World',
      explanation: json['explanation'] ?? '',
      storySummary: json['story_summary'] ?? '',
      source: json['source'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'question': question,
        'options': options,
        'correct_index': correctIndex,
        'difficulty': difficulty,
        'category': category,
        'explanation': explanation,
        'story_summary': storySummary,
        'source': source,
      };

  bool get isEasy => difficulty.toLowerCase() == 'easy';
}

// ─────────────────────────────────────────────────────────────────────────────
// QUIZ RESULT MODEL
// ─────────────────────────────────────────────────────────────────────────────

class QuestionAttempt {
  final String category;
  final String difficulty;
  final bool correct;
  final int selectedIndex;
  final int correctIndex;

  const QuestionAttempt({
    required this.category,
    required this.difficulty,
    required this.correct,
    required this.selectedIndex,
    required this.correctIndex,
  });

  factory QuestionAttempt.fromJson(Map<String, dynamic> json) {
    return QuestionAttempt(
      category: json['category'] ?? 'World',
      difficulty: json['difficulty'] ?? 'easy',
      correct: json['correct'] == true,
      selectedIndex: json['selected_index'] ?? -1,
      correctIndex: json['correct_index'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'category': category,
        'difficulty': difficulty,
        'correct': correct,
        'selected_index': selectedIndex,
        'correct_index': correctIndex,
      };
}

class QuizResult {
  final String date;
  final int score;
  final int totalQuestions;
  final int pointsEarned;
  final int timeTakenSeconds;
  final List<String> categories;
  final List<QuestionAttempt> attempts;

  const QuizResult({
    required this.date,
    required this.score,
    required this.totalQuestions,
    required this.pointsEarned,
    required this.timeTakenSeconds,
    required this.categories,
    this.attempts = const [],
  });

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    final rawAttempts = json['attempts'];
    return QuizResult(
      date: json['date'] ?? '',
      score: json['score'] ?? 0,
      totalQuestions: json['total_questions'] ?? 5,
      pointsEarned: json['points_earned'] ?? 0,
      timeTakenSeconds: json['time_taken_seconds'] ?? 0,
      categories: List<String>.from(json['categories'] ?? []),
      attempts: rawAttempts is List
          ? rawAttempts
              .whereType<Map>()
              .map((e) => QuestionAttempt.fromJson(
                  e.map((key, value) => MapEntry(key.toString(), value))))
              .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'score': score,
        'total_questions': totalQuestions,
        'points_earned': pointsEarned,
        'time_taken_seconds': timeTakenSeconds,
        'categories': categories,
        'attempts': attempts.map((e) => e.toJson()).toList(),
      };

  double get percentage => score / totalQuestions;
  String get percentageString => '${(percentage * 100).round()}%';

  String get performanceLabel {
    if (score == totalQuestions) return 'Perfect!';
    if (score >= totalQuestions * 0.8) return 'Brilliant!';
    if (score >= totalQuestions * 0.6) return 'Sharp Mind';
    if (score >= totalQuestions * 0.4) return 'Good Work';
    if (score >= totalQuestions * 0.2) return 'Getting There';
    return 'Keep Going';
  }

  String get performanceEmoji {
    if (score == totalQuestions) return '🏆';
    if (score >= totalQuestions * 0.8) return '🔥';
    if (score >= totalQuestions * 0.6) return '⚡';
    if (score >= totalQuestions * 0.4) return '👏';
    if (score >= totalQuestions * 0.2) return '💪';
    return '😅';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NEWS ARTICLE MODEL
// ─────────────────────────────────────────────────────────────────────────────

class NewsArticle {
  final String title;
  final String description;
  final String sourceName;
  final String category;
  final String pubDate;
  final String link;
  final String? imageUrl;

  const NewsArticle({
    required this.title,
    required this.description,
    required this.sourceName,
    required this.category,
    required this.pubDate,
    required this.link,
    this.imageUrl,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      title: json['title'] ?? '',
      description: json['description'] ?? json['content'] ?? '',
      sourceName: (json['source_name'] ?? json['source_id'] ?? 'News')
          .toString()
          .replaceAll('_', ' '),
      category: () {
        final cat = json['category'];
        const known = {
          'world',
          'technology',
          'business',
          'sports',
          'entertainment'
        };
        const skip = {
          'top',
          'trending',
          'latest',
          'breaking',
          'domestic',
          'other'
        };
        if (cat is List) {
          // Prefer a recognised category so tabs always have content
          for (final c in cat) {
            final s = c.toString().toLowerCase();
            if (known.contains(s)) return s;
          }
          for (final c in cat) {
            final s = c.toString().toLowerCase();
            if (!skip.contains(s)) return s;
          }
          return cat.isNotEmpty ? cat.first.toString() : 'world';
        }
        return (cat ?? 'world').toString();
      }(),
      pubDate: json['pubDate'] ?? json['pub_date'] ?? '',
      link: json['link'] ?? '',
      imageUrl: json['image_url'],
    );
  }

  String get sourceInitials {
    final words = sourceName.split(' ');
    if (words.length >= 2) return '${words[0][0]}${words[1][0]}'.toUpperCase();
    return sourceName.substring(0, sourceName.length.clamp(0, 2)).toUpperCase();
  }

  String get timeAgo {
    try {
      final dt = DateTime.parse(pubDate);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return 'Today';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// USER MODEL
// ─────────────────────────────────────────────────────────────────────────────

class UserData {
  final String name;
  final String photoUrl;
  final int streak;
  final int longestStreak;
  final int knowledgeScore;
  final int totalQuizzes;
  final String lastPlayedDate;
  final List<String> selectedCategories;
  final String country;
  final int notificationHour;
  final int notificationMinute;
  final List<QuizResult> recentResults;
  final bool isPro;

  const UserData({
    this.name = 'Briefed User',
    this.photoUrl = '',
    this.streak = 0,
    this.longestStreak = 0,
    this.knowledgeScore = 0,
    this.totalQuizzes = 0,
    this.lastPlayedDate = '',
    this.selectedCategories = const ['world', 'tech', 'business'],
    this.country = 'au',
    this.notificationHour = 8,
    this.notificationMinute = 0,
    this.recentResults = const [],
    this.isPro = false,
  });

  String get initials {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  bool get hasPlayedToday {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return lastPlayedDate == today;
  }

  String get globalRankLabel {
    if (knowledgeScore > 5000) return 'Top 5%';
    if (knowledgeScore > 3000) return 'Top 12%';
    if (knowledgeScore > 1500) return 'Top 25%';
    if (knowledgeScore > 500) return 'Top 50%';
    return 'Beginner';
  }

  UserData copyWith({
    String? name,
    String? photoUrl,
    int? streak,
    int? longestStreak,
    int? knowledgeScore,
    int? totalQuizzes,
    String? lastPlayedDate,
    List<String>? selectedCategories,
    String? country,
    int? notificationHour,
    int? notificationMinute,
    List<QuizResult>? recentResults,
    bool? isPro,
  }) {
    return UserData(
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      streak: streak ?? this.streak,
      longestStreak: longestStreak ?? this.longestStreak,
      knowledgeScore: knowledgeScore ?? this.knowledgeScore,
      totalQuizzes: totalQuizzes ?? this.totalQuizzes,
      lastPlayedDate: lastPlayedDate ?? this.lastPlayedDate,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      country: country ?? this.country,
      notificationHour: notificationHour ?? this.notificationHour,
      notificationMinute: notificationMinute ?? this.notificationMinute,
      recentResults: recentResults ?? this.recentResults,
      isPro: isPro ?? this.isPro,
    );
  }
}
