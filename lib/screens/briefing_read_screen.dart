import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme.dart';
import '../features/news/models/news_category.dart';
import '../features/news/models/ranked_article.dart';
import '../features/news/providers/news_pipeline_provider.dart';

class BriefingReadScreen extends ConsumerStatefulWidget {
  const BriefingReadScreen({super.key});
  @override
  ConsumerState<BriefingReadScreen> createState() => _BriefingReadScreenState();
}

class _BriefingReadScreenState extends ConsumerState<BriefingReadScreen> {
  final _readIds = <String>{};

  int get _readCount => _readIds.length;

  static const _order = [
    NewsCategory.world,
    NewsCategory.politics,
    NewsCategory.sports,
    NewsCategory.technology,
    NewsCategory.business,
    NewsCategory.health,
    NewsCategory.entertainment,
  ];

  List<RankedArticle> _getArticles(PipelineState pipeline) {
    final result = <RankedArticle>[];
    for (final cat in _order) {
      final articles = pipeline.byCategory[cat] ?? [];
      if (articles.isEmpty) continue;
      final quizable = articles.where((a) => a.quizabilityPassed).toList();
      result.add(quizable.isNotEmpty ? quizable.first : articles.first);
    }
    return result;
  }

  static Color _catColor(NewsCategory cat) {
    switch (cat) {
      case NewsCategory.world:
        return const Color(0xFF2196F3);
      case NewsCategory.politics:
        return const Color(0xFF9C27B0);
      case NewsCategory.sports:
        return const Color(0xFF4CAF50);
      case NewsCategory.technology:
        return const Color(0xFF00BCD4);
      case NewsCategory.business:
        return const Color(0xFFFF9800);
      case NewsCategory.health:
        return const Color(0xFF26A69A);
      case NewsCategory.entertainment:
        return const Color(0xFFE91E63);
    }
  }

  static String _catEmoji(NewsCategory cat) {
    switch (cat) {
      case NewsCategory.world:
        return '🌍';
      case NewsCategory.politics:
        return '🏛️';
      case NewsCategory.sports:
        return '⚽';
      case NewsCategory.technology:
        return '💻';
      case NewsCategory.business:
        return '📈';
      case NewsCategory.health:
        return '🏥';
      case NewsCategory.entertainment:
        return '🎬';
    }
  }

  @override
  Widget build(BuildContext context) {
    final pipeline = ref.watch(newsPipelineProvider);
    final articles = _getArticles(pipeline);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.of(context).pop(),
                color: context.textColor,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Expanded(
                child: Text(
                  "Today's Briefing",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: context.textColor),
                ),
              ),
              Text(
                '$_readCount/${_order.length} read',
                style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFFF5722)),
              ),
            ]),
          ),
          // Progress bar
          Stack(children: [
            Container(height: 4, color: context.borderColor),
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
              height: 4,
              width: screenWidth * (_readCount / _order.length),
              color: const Color(0xFFFF5722),
            ),
          ]),
          // Body
          Expanded(
            child: pipeline.isLoading && articles.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFF5722)))
                : articles.isEmpty
                    ? Center(
                        child: Text('No stories yet — pull down to refresh',
                            style: TextStyle(
                                fontFamily: AppFonts.body,
                                fontSize: 14,
                                color: context.hintColor)))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                        itemCount: articles.length + 1,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          if (index == articles.length) {
                            return _buildQuizButton(context);
                          }
                          final article = articles[index];
                          return _BriefingStoryCard(
                            article: article,
                            catColor: _catColor(article.category),
                            catEmoji: _catEmoji(article.category),
                            isRead: _readIds.contains(article.id),
                            onMarkRead: () =>
                                setState(() => _readIds.add(article.id)),
                          );
                        },
                      ),
          ),
        ]),
      ),
    );
  }

  Widget _buildQuizButton(BuildContext context) {
    final visible = _readCount >= 5;
    return AnimatedOpacity(
      opacity: visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 400),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF5722),
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          onPressed: visible
              ? () {
                  final nav = Navigator.of(context);
                  nav.pop();
                  nav.pushNamed('/quiz/intro', arguments: {'isDailyMix': true});
                }
              : null,
          child: Text(
            "Take Today's Quiz →",
            style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 16,
                fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}

// ── Story card ────────────────────────────────────────────────────────────────

class _BriefingStoryCard extends StatefulWidget {
  final RankedArticle article;
  final Color catColor;
  final String catEmoji;
  final bool isRead;
  final VoidCallback onMarkRead;

  const _BriefingStoryCard({
    required this.article,
    required this.catColor,
    required this.catEmoji,
    required this.isRead,
    required this.onMarkRead,
  });

  @override
  State<_BriefingStoryCard> createState() => _BriefingStoryCardState();
}

class _BriefingStoryCardState extends State<_BriefingStoryCard> {
  bool _expanded = false;

  void _onTap() {
    if (!_expanded) {
      setState(() => _expanded = true);
      if (!widget.isRead) widget.onMarkRead();
    } else {
      setState(() => _expanded = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.catColor;
    final a = widget.article;

    return GestureDetector(
      onTap: _onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                widget.isRead ? c.withValues(alpha: 0.6) : context.borderColor,
            width: 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category header strip
            Container(
              height: 36,
              color: c.withValues(alpha: 0.15),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(children: [
                Text(widget.catEmoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  a.category.label,
                  style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: c),
                ),
                const Spacer(),
                Text(
                  widget.isRead ? '✓ Read' : 'Tap to read',
                  style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: widget.isRead ? c : context.hintColor),
                ),
              ]),
            ),
            // Article image
            if (a.imageUrl != null && a.imageUrl!.isNotEmpty)
              SizedBox(
                height: 180,
                width: double.infinity,
                child: Image.network(
                  a.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: c.withValues(alpha: 0.12),
                    child: Icon(Icons.image_not_supported_rounded,
                        size: 40, color: c.withValues(alpha: 0.35)),
                  ),
                ),
              ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Source row
                  Row(children: [
                    Text(
                      a.sourceName,
                      style: TextStyle(
                          fontFamily: AppFonts.body,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: c),
                    ),
                    Text(' · ',
                        style:
                            TextStyle(color: context.hintColor, fontSize: 11)),
                    Text(
                      a.timeAgo,
                      style: TextStyle(
                          fontFamily: AppFonts.body,
                          fontSize: 11,
                          color: context.hintColor),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  // Headline
                  Text(
                    a.title,
                    maxLines: _expanded ? null : 2,
                    overflow: _expanded
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                    style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: context.textColor,
                        height: 1.3),
                  ),
                  // Summary (animates in when expanded)
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    child: _expanded && a.summary.isNotEmpty
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 12),
                              Text(
                                a.summary,
                                style: TextStyle(
                                    fontFamily: AppFonts.body,
                                    fontSize: 13,
                                    color: context.subColor,
                                    height: 1.5),
                              ),
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: () async {
                                  final uri = Uri.parse(a.url);
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri,
                                        mode: LaunchMode.inAppBrowserView);
                                  }
                                },
                                child: Text(
                                  'Read full story →',
                                  style: TextStyle(
                                      fontFamily: AppFonts.body,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: c),
                                ),
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
