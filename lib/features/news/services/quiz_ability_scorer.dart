import '../models/ranked_article.dart';

class QuizAbilityScorer {
  static const _outcomeVerbs = {
    'wins',
    'beats',
    'elected',
    'appointed',
    'launches',
    'banned',
    'fined',
    'breaks',
    'sets',
    'signs',
    'signed',
    'passed',
    'approved',
    'announced',
    'revealed',
    'confirmed',
    'arrested',
    'released',
    'died',
    'opens',
    'closes',
    'cuts',
    'raises',
    'hits',
    'named',
    'found',
    'charged',
    'acquitted',
    'suspended',
    'sacked',
    'resigned',
    'struck',
    'defeated',
    'achieved',
    'reached',
    'secured',
    'halted',
    'resumes',
    'crackdown',
    'replaces',
    'settles',
    'unveils',
    'warns',
    'blocks',
  };

  static const _shoppingSignals = {
    'review',
    'deal',
    'sale',
    'discount',
    'cheaper',
    'best buy',
    'ranked',
    'guide',
    'how to',
    'tips',
    'watch',
    'listen',
    'podcast',
    'opinion',
    'analysis',
    'column',
    'explainer',
    'newsletter',
    'sponsored',
    'clone',
    'vs',
    'comparison',
    'roundup',
  };

  static const _unstableSignals = {
    'live',
    'breaking',
    'developing',
    'updating',
    'could',
    'might',
    'may',
    'perhaps',
    'possibly',
    'rumour',
    'rumoured',
    'alleged',
    'unconfirmed',
    'sources say',
    'report suggests',
    'exclusive',
    'watch',
    'opinion',
    'analysis',
    'comment',
  };

  // Regex patterns — compiled once
  static final _namedEntityRe = RegExp(r'[A-Z][a-z]+(?:\s+[A-Z][a-z]+)+');
  static final _numberStatRe =
      RegExp(r'\d+(?:\.\d+)?(?:%|bn|m|k|km|mph|years|days|hours)?');

  static RankedArticle score(RankedArticle article) {
    int pts = 0;

    // +25 Named entity (two+ consecutive capitalised words)
    if (_namedEntityRe.hasMatch(article.title)) pts += 25;

    // +25 Specific number / stat
    if (_numberStatRe.hasMatch(article.title) ||
        _numberStatRe.hasMatch(article.summary)) {
      pts += 25;
    }

    // +25 Clear outcome verb in title
    final titleLower = article.title.toLowerCase();
    if (_outcomeVerbs.any((v) => titleLower.contains(v))) pts += 25;

    // +25 Time-stable story (no unstable signals)
    if (!_unstableSignals.any((s) => titleLower.contains(s))) pts += 25;

    // -25 Shopping / review / opinion signals
    if (_shoppingSignals.any((s) => titleLower.contains(s))) pts -= 25;

    return article.copyWithScores(
      quizabilityScore: pts,
      quizabilityPassed: pts >= 50,
    );
  }
}
