import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'news_category.dart';

class RankedArticle {
  final String id;
  final String title;
  final String summary;
  final String url;
  final String? imageUrl;
  final String sourceName;
  final String sourceDomain;
  final DateTime publishedAt;
  final NewsCategory category;
  final int sourceQualityScore;
  final int quizabilityScore;
  final bool quizabilityPassed;
  final ApiSource apiSource;

  const RankedArticle({
    required this.id,
    required this.title,
    required this.summary,
    required this.url,
    this.imageUrl,
    required this.sourceName,
    required this.sourceDomain,
    required this.publishedAt,
    required this.category,
    required this.sourceQualityScore,
    required this.quizabilityScore,
    required this.quizabilityPassed,
    required this.apiSource,
  });

  static String md5Id(String url) {
    final bytes = utf8.encode(url.trim().toLowerCase());
    return md5.convert(bytes).toString();
  }

  int get recencyScore {
    final diff = DateTime.now().difference(publishedAt);
    if (diff.inHours < 2) return 100;
    if (diff.inHours < 6) return 75;
    if (diff.inHours < 12) return 50;
    return 25;
  }

  double get finalScore =>
      (sourceQualityScore * 0.5) +
      (quizabilityScore * 0.3) +
      (recencyScore * 0.2);

  /// Returns imageUrl when present, otherwise a seeded picsum photo so every
  /// article always renders a real image (seed = first 8 chars of MD5 id).
  String get effectiveImageUrl {
    if (imageUrl != null && imageUrl!.isNotEmpty) return imageUrl!;
    final seed = id.length >= 8 ? id.substring(0, 8) : id;
    return 'https://picsum.photos/seed/$seed/800/450';
  }

  bool get isOlderThan24Hours =>
      DateTime.now().difference(publishedAt).inHours >= 24;

  String get timeAgo {
    final diff = DateTime.now().difference(publishedAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  RankedArticle copyWithScores({
    required int quizabilityScore,
    required bool quizabilityPassed,
  }) =>
      RankedArticle(
        id: id,
        title: title,
        summary: summary,
        url: url,
        imageUrl: imageUrl,
        sourceName: sourceName,
        sourceDomain: sourceDomain,
        publishedAt: publishedAt,
        category: category,
        sourceQualityScore: sourceQualityScore,
        quizabilityScore: quizabilityScore,
        quizabilityPassed: quizabilityPassed,
        apiSource: apiSource,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'summary': summary,
        'url': url,
        if (imageUrl != null) 'imageUrl': imageUrl,
        'sourceName': sourceName,
        'sourceDomain': sourceDomain,
        'publishedAt': publishedAt.toIso8601String(),
        'category': category.name,
        'sourceQualityScore': sourceQualityScore,
        'quizabilityScore': quizabilityScore,
        'quizabilityPassed': quizabilityPassed,
        'apiSource': apiSource.name,
      };

  factory RankedArticle.fromJson(Map<String, dynamic> j) => RankedArticle(
        id: j['id'] as String,
        title: j['title'] as String,
        summary: j['summary'] as String? ?? '',
        url: j['url'] as String,
        imageUrl: j['imageUrl'] as String?,
        sourceName: j['sourceName'] as String,
        sourceDomain: j['sourceDomain'] as String,
        publishedAt: DateTime.parse(j['publishedAt'] as String),
        category: NewsCategory.fromString(j['category'] as String) ??
            NewsCategory.world,
        sourceQualityScore: (j['sourceQualityScore'] as num).toInt(),
        quizabilityScore: (j['quizabilityScore'] as num).toInt(),
        quizabilityPassed: j['quizabilityPassed'] as bool? ?? false,
        apiSource: ApiSource.values.firstWhere(
          (s) => s.name == j['apiSource'],
          orElse: () => ApiSource.newsdata,
        ),
      );
}
