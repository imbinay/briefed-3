import 'dart:math' as math;
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../providers/providers.dart';
import '../services/storage_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS  (warm cream + punchy orange, Bricolage Grotesque + Manrope)
// ─────────────────────────────────────────────────────────────────────────────

class _T {
  static const accent = AppColors.accent;
  static const accentDark = AppColors.accentDark;

  static Color bg(bool dark) =>
      dark ? const Color(0xFF1A0F08) : const Color(0xFFFFF1E2);
  static Color surface(bool dark) =>
      dark ? const Color(0xFF3A2016) : Colors.white;
  static Color ink(bool dark) =>
      dark ? const Color(0xFFFFF6EC) : const Color(0xFF1F1612);
  static Color ink2(bool dark) =>
      dark ? const Color(0xFFE6CFB8) : const Color(0xFF5A4438);
  static Color muted(bool dark) =>
      dark ? const Color(0xFF9A7E68) : const Color(0xFF9C8377);
  static Color line(bool dark) =>
      dark ? const Color(0xFF3A2516) : const Color(0xFFF4E2CE);
  static Color primarySoft(bool dark) =>
      dark ? const Color(0xFF3A1F0F) : const Color(0xFFFFE0C8);

  // Duolingo-style chunky button
  static BoxDecoration primaryBtn = BoxDecoration(
    color: accent,
    borderRadius: BorderRadius.circular(18),
    boxShadow: const [BoxShadow(color: accentDark, offset: Offset(0, 4))],
  );

  static TextStyle displayStyle(bool dark, {double size = 30}) => TextStyle(
        fontFamily: AppFonts.display,
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: ink(dark),
        letterSpacing: -0.025 * size,
        height: 1.04,
      );
}

// Category design data (matches the design spec)
class _Cat {
  final String label;
  final String emoji;
  final Color fg;
  final Color bg;
  final int stories;
  final bool hot;
  const _Cat({
    required this.label,
    required this.emoji,
    required this.fg,
    required this.bg,
    required this.stories,
    this.hot = false,
  });
}

const _categories = [
  _Cat(
      label: 'Politics',
      emoji: '🏛️',
      fg: Color(0xFF3B5BDB),
      bg: Color(0xFFE0E7FF),
      stories: 14,
      hot: true),
  _Cat(
      label: 'Technology',
      emoji: '💻',
      fg: Color(0xFF7C3AED),
      bg: Color(0xFFEDE9FE),
      stories: 22),
  _Cat(
      label: 'Sports',
      emoji: '⚽',
      fg: Color(0xFF16A34A),
      bg: Color(0xFFDCFCE7),
      stories: 18),
  _Cat(
      label: 'World',
      emoji: '🌍',
      fg: Color(0xFF0EA5E9),
      bg: Color(0xFFDBEEFB),
      stories: 27,
      hot: true),
  _Cat(
      label: 'Business',
      emoji: '💼',
      fg: Color(0xFFD97706),
      bg: Color(0xFFFEF3C7),
      stories: 11),
  _Cat(
      label: 'Science',
      emoji: '🔬',
      fg: Color(0xFF0891B2),
      bg: Color(0xFFCFFAFE),
      stories: 9),
  _Cat(
      label: 'Entertainment',
      emoji: '🎬',
      fg: Color(0xFFDB2777),
      bg: Color(0xFFFCE7F3),
      stories: 16),
  _Cat(
      label: 'Health',
      emoji: '🩺',
      fg: Color(0xFF059669),
      bg: Color(0xFFD1FAE5),
      stories: 7),
];

// Map from the legacy category ID format to the label
const _catIdMap = {
  'world': 'World',
  'tech': 'Technology',
  'business': 'Business',
  'sports': 'Sports',
  'entertainment': 'Entertainment',
  'politics': 'Politics',
  'science': 'Science',
  'health': 'Health',
};

// Map label → legacy ID for storage
const _labelToId = {
  'World': 'world',
  'Technology': 'tech',
  'Business': 'business',
  'Sports': 'sports',
  'Entertainment': 'entertainment',
  'Politics': 'politics',
  'Science': 'science',
  'Health': 'health',
};

// ─────────────────────────────────────────────────────────────────────────────
// WEEKLY-ROTATING WELCOME HEADLINES
// Each inner list is 3 cards: [back, middle, front].  Pick by ISO week number.
// ─────────────────────────────────────────────────────────────────────────────

class _HeadlineDef {
  final String cat;
  final Color catFg;
  final Color catBg;
  final String emoji;
  final String title;
  final String source;
  final bool highlight;
  const _HeadlineDef({
    required this.cat, required this.catFg, required this.catBg,
    required this.emoji, required this.title, required this.source,
    this.highlight = false,
  });
}

const _weeklyHeadlines = [
  // Week group A
  [
    _HeadlineDef(cat: 'World', catFg: Color(0xFF0EA5E9), catBg: Color(0xFFDBEEFB), emoji: '🌍',
        title: 'UN climate summit sets binding carbon targets for 2035', source: 'Reuters'),
    _HeadlineDef(cat: 'Politics', catFg: Color(0xFF3B5BDB), catBg: Color(0xFFE0E7FF), emoji: '🏛️',
        title: 'Senate passes landmark infrastructure spending bill', source: 'AP News'),
    _HeadlineDef(cat: 'Technology', catFg: Color(0xFF7C3AED), catBg: Color(0xFFEDE9FE), emoji: '💻',
        title: 'AI model breaks reasoning benchmark, rivals human experts', source: 'The Verge', highlight: true),
  ],
  // Week group B
  [
    _HeadlineDef(cat: 'Sports', catFg: Color(0xFF16A34A), catBg: Color(0xFFDCFCE7), emoji: '⚽',
        title: 'Champions League quarter-finals: shock upsets across the board', source: 'ESPN'),
    _HeadlineDef(cat: 'Business', catFg: Color(0xFFD97706), catBg: Color(0xFFFEF3C7), emoji: '💼',
        title: 'Federal Reserve holds rates as inflation inches lower', source: 'Bloomberg'),
    _HeadlineDef(cat: 'World', catFg: Color(0xFF0EA5E9), catBg: Color(0xFFDBEEFB), emoji: '🌍',
        title: 'G7 leaders agree on joint response to Middle East tensions', source: 'BBC News', highlight: true),
  ],
  // Week group C
  [
    _HeadlineDef(cat: 'Health', catFg: Color(0xFF059669), catBg: Color(0xFFD1FAE5), emoji: '🩺',
        title: 'New study links ultra-processed foods to cognitive decline', source: 'New Scientist'),
    _HeadlineDef(cat: 'Technology', catFg: Color(0xFF7C3AED), catBg: Color(0xFFEDE9FE), emoji: '💻',
        title: 'SpaceX Starship completes first full-duration orbital burn', source: 'Ars Technica'),
    _HeadlineDef(cat: 'Politics', catFg: Color(0xFF3B5BDB), catBg: Color(0xFFE0E7FF), emoji: '🏛️',
        title: 'Snap elections called as coalition government collapses', source: 'The Guardian', highlight: true),
  ],
  // Week group D
  [
    _HeadlineDef(cat: 'Business', catFg: Color(0xFFD97706), catBg: Color(0xFFFEF3C7), emoji: '💼',
        title: 'Markets rally as tech earnings beat expectations by wide margin', source: 'FT'),
    _HeadlineDef(cat: 'Science', catFg: Color(0xFF0891B2), catBg: Color(0xFFCFFAFE), emoji: '🔬',
        title: 'James Webb captures earliest galaxy ever observed', source: 'NASA'),
    _HeadlineDef(cat: 'Entertainment', catFg: Color(0xFFDB2777), catBg: Color(0xFFFCE7F3), emoji: '🎬',
        title: 'Record-breaking box office weekend as blockbuster season opens', source: 'Variety', highlight: true),
  ],
];

List<_HeadlineDef> _headlinesForThisWeek() {
  final week = _isoWeekNumber(DateTime.now());
  return _weeklyHeadlines[week % _weeklyHeadlines.length];
}

int _isoWeekNumber(DateTime date) {
  final thursday = date.subtract(Duration(days: date.weekday - 4));
  final firstThursday = DateTime(thursday.year, 1, 1)
      .subtract(Duration(days: DateTime(thursday.year, 1, 1).weekday - 4));
  return ((thursday.difference(firstThursday).inDays) / 7).floor() + 1;
}

// Weekly queued-card sets for the All Set screen
const _weeklyQueued = [
  [
    (emoji: '⚽', cat: 'SPORTS',    color: Color(0xFF16A34A), title: 'F1 sprint shake-up at Suzuka…'),
    (emoji: '🏛️', cat: 'POLITICS',  color: Color(0xFF3B5BDB), title: 'Fed signals patience on rates…'),
    (emoji: '💻', cat: 'TECHNOLOGY', color: Color(0xFF7C3AED), title: 'AI rivals human expert reasoning…'),
  ],
  [
    (emoji: '🌍', cat: 'WORLD',      color: Color(0xFF0EA5E9), title: 'G7 agrees on joint action plan…'),
    (emoji: '💼', cat: 'BUSINESS',   color: Color(0xFFD97706), title: 'Markets rally on earnings beat…'),
    (emoji: '💻', cat: 'TECHNOLOGY', color: Color(0xFF7C3AED), title: 'SpaceX Starship orbital burn…'),
  ],
  [
    (emoji: '🩺', cat: 'HEALTH',      color: Color(0xFF059669), title: 'Ultra-processed foods study…'),
    (emoji: '🏛️', cat: 'POLITICS',    color: Color(0xFF3B5BDB), title: 'Snap elections called as coalition…'),
    (emoji: '🔬', cat: 'SCIENCE',     color: Color(0xFF0891B2), title: 'Webb captures earliest galaxy…'),
  ],
  [
    (emoji: '🎬', cat: 'ENTERTAINMENT', color: Color(0xFFDB2777), title: 'Record box office weekend…'),
    (emoji: '⚽', cat: 'SPORTS',       color: Color(0xFF16A34A), title: 'Champions League upsets…'),
    (emoji: '💼', cat: 'BUSINESS',     color: Color(0xFFD97706), title: 'Fed holds rates, inflation eases…'),
  ],
];

class _FeaturePill extends StatelessWidget {
  final bool dark;
  final String emoji;
  final String label;
  const _FeaturePill({required this.dark, required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 5, 10, 5),
      decoration: BoxDecoration(
        color: _T.surface(dark),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _T.line(dark)),
        boxShadow: dark ? null : [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 1)),
        ],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(emoji, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _T.ink2(dark),
        )),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WELCOME SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _floatCtrl;
  late AnimationController _entryCtrl;
  late Animation<double> _heroFade;
  late Animation<Offset> _heroSlide;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;
  late Animation<double> _btnFade;

  final List<_HeadlineDef> _headlines = _headlinesForThisWeek();

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _heroFade = CurvedAnimation(
        parent: _entryCtrl, curve: const Interval(0.0, 0.6, curve: Curves.easeOut));
    _heroSlide = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _entryCtrl,
            curve: const Interval(0.0, 0.6, curve: Curves.easeOut)));
    _textFade = CurvedAnimation(
        parent: _entryCtrl, curve: const Interval(0.3, 0.8, curve: Curves.easeOut));
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _entryCtrl,
            curve: const Interval(0.3, 0.8, curve: Curves.easeOut)));
    _btnFade = CurvedAnimation(
        parent: _entryCtrl, curve: const Interval(0.55, 1.0, curve: Curves.easeOut));

    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: _T.bg(dark),
      body: Stack(
        children: [
          // Atmospheric glow
          Positioned(
            top: -120,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accent.withValues(alpha: 0.30),
                      AppColors.accent.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(children: [
                    _BriefedLogo(dark: dark),
                    const Spacer(),
                    TextButton(
                      onPressed: () =>
                          Navigator.of(context).pushReplacementNamed('/signin'),
                      child: Text(
                        'Skip →',
                        style: TextStyle(
                          fontFamily: AppFonts.body,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: _T.ink2(dark),
                        ),
                      ),
                    ),
                  ]),
                ),

                // Hero card stack
                FadeTransition(
                  opacity: _heroFade,
                  child: SlideTransition(
                    position: _heroSlide,
                    child: SizedBox(
                      height: 282,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Floating sparkles
                          Positioned(
                            top: 4,
                            right: 30,
                            child: _FloatWidget(
                              ctrl: _floatCtrl,
                              delay: 0,
                              child: const Text('✦',
                                  style: TextStyle(
                                      fontSize: 18,
                                      color: AppColors.accent)),
                            ),
                          ),
                          Positioned(
                            top: 90,
                            right: 50,
                            child: _FloatWidget(
                              ctrl: _floatCtrl,
                              delay: 0.4,
                              child: const Text('✦',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF3B5BDB))),
                            ),
                          ),
                          Positioned(
                            top: 190,
                            left: 10,
                            child: _FloatWidget(
                              ctrl: _floatCtrl,
                              delay: 0.7,
                              child: const Text('✦',
                                  style: TextStyle(
                                      fontSize: 15,
                                      color: Color(0xFF7C3AED))),
                            ),
                          ),

                          // Back card
                          Positioned(
                            top: 20,
                            left: 20,
                            right: 68,
                            child: _FloatWidget(
                              ctrl: _floatCtrl,
                              delay: 0.2,
                              amplitude: 5,
                              child: Transform.rotate(
                                angle: -4 * math.pi / 180,
                                child: _HeadlineCard(
                                  dark: dark,
                                  cat: _headlines[0].cat,
                                  catFg: _headlines[0].catFg,
                                  catBg: _headlines[0].catBg,
                                  emoji: _headlines[0].emoji,
                                  title: _headlines[0].title,
                                  source: _headlines[0].source,
                                  highlight: false,
                                ),
                              ),
                            ),
                          ),

                          // Middle card
                          Positioned(
                            top: 108,
                            left: 44,
                            right: 14,
                            child: _FloatWidget(
                              ctrl: _floatCtrl,
                              delay: 0.6,
                              amplitude: 5,
                              child: Transform.rotate(
                                angle: 3 * math.pi / 180,
                                child: _HeadlineCard(
                                  dark: dark,
                                  cat: _headlines[1].cat,
                                  catFg: _headlines[1].catFg,
                                  catBg: _headlines[1].catBg,
                                  emoji: _headlines[1].emoji,
                                  title: _headlines[1].title,
                                  source: _headlines[1].source,
                                  highlight: false,
                                ),
                              ),
                            ),
                          ),

                          // Front highlighted card
                          Positioned(
                            top: 196,
                            left: 16,
                            right: 24,
                            child: _FloatWidget(
                              ctrl: _floatCtrl,
                              delay: 1.0,
                              amplitude: 5,
                              child: Transform.rotate(
                                angle: -1.5 * math.pi / 180,
                                child: _HeadlineCard(
                                  dark: dark,
                                  cat: _headlines[2].cat,
                                  catFg: _headlines[2].catFg,
                                  catBg: _headlines[2].catBg,
                                  emoji: _headlines[2].emoji,
                                  title: _headlines[2].title,
                                  source: _headlines[2].source,
                                  highlight: true,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Tagline
                FadeTransition(
                  opacity: _textFade,
                  child: SlideTransition(
                    position: _textSlide,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontFamily: AppFonts.display,
                                fontSize: 38,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.95,
                                height: 1.04,
                              ),
                              children: [
                                TextSpan(
                                    text: 'The news,\n',
                                    style: TextStyle(color: _T.ink(dark))),
                                TextSpan(
                                    text: 'played daily.',
                                    style: const TextStyle(
                                        color: AppColors.accent)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Five questions a day. Two minutes. Earn streaks, climb the leaderboard, actually keep up.',
                            style: TextStyle(
                              fontFamily: AppFonts.body,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _T.ink2(dark),
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // Social proof
                FadeTransition(
                  opacity: _textFade,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Wrap(spacing: 8, runSpacing: 8, children: [
                      _FeaturePill(dark: dark, emoji: '⚡', label: '5 questions · 2 min'),
                      _FeaturePill(dark: dark, emoji: '🔥', label: 'Daily streaks'),
                      _FeaturePill(dark: dark, emoji: '📰', label: 'Updated weekly'),
                    ]),
                  ),
                ),

                const Spacer(),

                // Bottom CTAs
                FadeTransition(
                  opacity: _btnFade,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    child: Column(children: [
                      // Primary CTA
                      _ChunkyButton(
                        label: "Get started",
                        icon: Icons.arrow_forward_rounded,
                        onTap: () => Navigator.of(context)
                            .pushReplacementNamed('/signin'),
                      ),
                      const SizedBox(height: 14),
                      // Secondary sign-in link
                      GestureDetector(
                        onTap: () => Navigator.of(context)
                            .pushReplacementNamed('/signin'),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: TextStyle(
                              fontFamily: AppFonts.body,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _T.ink2(dark),
                            ),
                            children: const [
                              TextSpan(text: 'Already have an account? '),
                              TextSpan(
                                text: 'Log in',
                                style: TextStyle(
                                  color: AppColors.accent,
                                  decoration: TextDecoration.underline,
                                  decorationColor: AppColors.accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ONBOARDING SCREEN  (3 steps: Interests → Daily Pace → All Set)
// ─────────────────────────────────────────────────────────────────────────────

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {
  int _step = 0; // 0=Interests, 1=Goal, 2=AllSet

  // Interests state
  final Set<String> _selectedLabels = {'Politics', 'Technology', 'Sports', 'World'};

  // Goal state
  String _goal = 'balanced'; // casual | balanced | all-in

  // Notification
  int _notifHour = 9;
  int _notifMinute = 0;

  late ConfettiController _confettiCtrl;

  // Page transition
  late AnimationController _pageCtrl;
  late Animation<double> _pageFade;

  @override
  void initState() {
    super.initState();
    _confettiCtrl =
        ConfettiController(duration: const Duration(seconds: 6));
    _pageCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 380));
    _pageFade = CurvedAnimation(parent: _pageCtrl, curve: Curves.easeOut);
    _pageCtrl.forward();
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_step == 1) {
      _confettiCtrl.play();
    }
    _pageCtrl.reverse().then((_) {
      setState(() => _step++);
      _pageCtrl.forward();
    });
  }

  void _back() {
    if (_step == 0) {
      Navigator.of(context).pushReplacementNamed('/signin');
      return;
    }
    _pageCtrl.reverse().then((_) {
      setState(() => _step--);
      _pageCtrl.forward();
    });
  }

  Future<void> _finish() async {
    final ids = _selectedLabels
        .map((l) => _labelToId[l])
        .whereType<String>()
        .toList();
    if (ids.isEmpty) ids.addAll(['world', 'tech', 'business']);

    final goalQ = {'casual': 1, 'balanced': 3, 'all-in': 5}[_goal] ?? 3;
    // Map goal to preferred notification hour
    _notifHour = {'casual': 9, 'balanced': 9, 'all-in': 7}[_goal] ?? 9;

    await StorageService.setOnboardingDone();
    await StorageService.setSelectedCategories(ids);
    ref.read(userProvider.notifier).updateCategories(ids);
    ref
        .read(userProvider.notifier)
        .updateNotificationTime(_notifHour, _notifMinute);

    // Store daily goal preference
    await StorageService.setDailyGoal(goalQ);

    if (mounted) Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(userProvider);
    final displayName = user.name.trim().isEmpty ? 'Briefed user' : user.name.split(' ').first;

    return Scaffold(
      backgroundColor: _T.bg(dark),
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Confetti (step 3)
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiCtrl,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.05,
              numberOfParticles: 30,
              gravity: 0.25,
              colors: const [
                AppColors.accent,
                Color(0xFFFFC15A),
                Color(0xFF3B5BDB),
                Color(0xFF16A34A),
                Color(0xFFDB2777),
              ],
            ),
          ),

          FadeTransition(
            opacity: _pageFade,
            child: SafeArea(
              child: _buildStep(dark, displayName),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(bool dark, String displayName) {
    switch (_step) {
      case 0:
        return _InterestsStep(
          dark: dark,
          selected: _selectedLabels,
          onBack: _back,
          onContinue: _next,
          onToggle: (label) {
            setState(() {
              if (_selectedLabels.contains(label)) {
                if (_selectedLabels.length > 1) _selectedLabels.remove(label);
              } else {
                _selectedLabels.add(label);
              }
            });
          },
          onSurprise: () {
            final shuffled = List.from(_categories)..shuffle();
            setState(() {
              _selectedLabels.clear();
              _selectedLabels.addAll(
                  shuffled.take(4 + math.Random().nextInt(2)).map((c) => (c as _Cat).label));
            });
          },
        );
      case 1:
        return _GoalStep(
          dark: dark,
          goal: _goal,
          onBack: _back,
          onContinue: _next,
          onGoalChanged: (g) => setState(() => _goal = g),
        );
      case 2:
        return _AllSetStep(
          dark: dark,
          onFinish: _finish,
          onBack: _back,
          userName: displayName,
        );
      default:
        return const SizedBox();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 0 — INTERESTS
// ─────────────────────────────────────────────────────────────────────────────

class _InterestsStep extends StatefulWidget {
  final bool dark;
  final Set<String> selected;
  final VoidCallback onBack;
  final VoidCallback onContinue;
  final void Function(String) onToggle;
  final VoidCallback onSurprise;

  const _InterestsStep({
    required this.dark,
    required this.selected,
    required this.onBack,
    required this.onContinue,
    required this.onToggle,
    required this.onSurprise,
  });

  @override
  State<_InterestsStep> createState() => _InterestsStepState();
}

class _InterestsStepState extends State<_InterestsStep>
    with TickerProviderStateMixin {
  late AnimationController _staggerCtrl;
  late AnimationController _ringCtrl;
  late AnimationController _checkBounceCtrl;

  @override
  void initState() {
    super.initState();
    _staggerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
    _ringCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _checkBounceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    if (widget.selected.length >= 3) {
      _ringCtrl.forward();
      _checkBounceCtrl.forward();
    }
  }

  @override
  void didUpdateWidget(_InterestsStep old) {
    super.didUpdateWidget(old);
    final wasOk = old.selected.length >= 3;
    final isOk = widget.selected.length >= 3;
    if (!wasOk && isOk) {
      _ringCtrl.forward();
      _checkBounceCtrl.forward();
    } else if (wasOk && !isOk) {
      _ringCtrl.reverse();
      _checkBounceCtrl.reverse();
    }
  }

  @override
  void dispose() {
    _staggerCtrl.dispose();
    _ringCtrl.dispose();
    _checkBounceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ok = widget.selected.length >= 3;
    final progress = (widget.selected.length / 5.0).clamp(0.0, 1.0);

    return Stack(
      children: [
        Positioned.fill(
          child: Column(
          children: [
        _OnbHeader(step: 1, onBack: widget.onBack, dark: widget.dark),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("What's on\nyour radar?",
                        style: _T.displayStyle(widget.dark, size: 30)),
                    const SizedBox(height: 8),
                    Text(
                      "Pick at least 3 — we'll tune your daily brief.",
                      style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _T.ink2(widget.dark),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Counter ring
              SizedBox(
                width: 72,
                height: 72,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(72, 72),
                      painter: _RingPainter(
                        value: progress,
                        trackColor: _T.line(widget.dark),
                        fillColor: ok
                            ? AppColors.accent
                            : AppColors.accent.withValues(alpha: 0.45),
                        strokeWidth: 7,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 250),
                          style: TextStyle(
                            fontFamily: AppFonts.display,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: ok ? AppColors.accent : _T.ink2(widget.dark),
                          ),
                          child: Text('${widget.selected.length}'),
                        ),
                        Text(
                          'PICKED',
                          style: TextStyle(
                            fontFamily: AppFonts.body,
                            fontSize: 7,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.08,
                            color: _T.muted(widget.dark),
                          ),
                        ),
                      ],
                    ),
                    // Check badge
                    if (ok)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: ScaleTransition(
                          scale: CurvedAnimation(
                              parent: _checkBounceCtrl,
                              curve: const ElasticOutCurve(0.8)),
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                    color: AppColors.accentDark,
                                    offset: Offset(0, 2))
                              ],
                            ),
                            child: const Icon(Icons.check_rounded,
                                color: Colors.white, size: 13),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Helper + surprise me
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: Row(children: [
            Expanded(
              child: Text(
                ok
                    ? 'Looking good. Add a couple more for variety.'
                    : '${3 - widget.selected.length} more topic${(3 - widget.selected.length) == 1 ? '' : 's'} to continue',
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _T.muted(widget.dark),
                ),
              ),
            ),
            TextButton.icon(
              onPressed: widget.onSurprise,
              icon: const Text('✦', style: TextStyle(fontSize: 11, color: AppColors.accent)),
              label: const Text(
                'Surprise me',
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.accent,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ]),
        ),

        // Interest grid
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 80),
            child: GridView.builder(
              clipBehavior: Clip.none,
              padding: const EdgeInsets.only(top: 12),
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.15,
              ),
              itemCount: _categories.length,
              itemBuilder: (ctx, i) {
                final cat = _categories[i];
                final sel = widget.selected.contains(cat.label);
                final cardAnim = CurvedAnimation(
                  parent: _staggerCtrl,
                  curve: Interval(
                    (i * 0.07).clamp(0.0, 0.7),
                    ((i * 0.07) + 0.4).clamp(0.0, 1.0),
                    curve: Curves.easeOut,
                  ),
                );
                return AnimatedBuilder(
                  animation: cardAnim,
                  builder: (_, child) => Opacity(
                    opacity: cardAnim.value,
                    child: Transform.translate(
                      offset: Offset(0, 12 * (1 - cardAnim.value)),
                      child: child,
                    ),
                  ),
                  child: _InterestCard(
                    cat: cat,
                    selected: sel,
                    dark: widget.dark,
                    onTap: () => widget.onToggle(cat.label),
                  ),
                );
              },
            ),
          ),
        ),
      ],
          ),  // Column
        ),  // Positioned.fill
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _InterestsCta(
            dark: widget.dark,
            selectedCount: widget.selected.length,
            onContinue: widget.onContinue,
          ),
        ),
      ],
    );
  }
}

class _InterestCard extends StatefulWidget {
  final _Cat cat;
  final bool selected;
  final bool dark;
  final VoidCallback onTap;
  const _InterestCard(
      {required this.cat,
      required this.selected,
      required this.dark,
      required this.onTap});
  @override
  State<_InterestCard> createState() => _InterestCardState();
}

class _InterestCardState extends State<_InterestCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceCtrl;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    if (widget.selected) _bounceCtrl.forward();
  }

  @override
  void didUpdateWidget(_InterestCard old) {
    super.didUpdateWidget(old);
    if (!old.selected && widget.selected) {
      _bounceCtrl.forward(from: 0);
    } else if (old.selected && !widget.selected) {
      _bounceCtrl.reverse();
    }
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.cat;
    final sel = widget.selected;
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: sel ? c.bg : _T.surface(widget.dark),
          borderRadius: BorderRadius.circular(18),
          boxShadow: sel
              ? [
                  BoxShadow(
                      color: c.fg.withValues(alpha: 0.32),
                      offset: const Offset(0, 5),
                      blurRadius: 0,
                      spreadRadius: 0),
                  BoxShadow(
                      color: c.fg.withValues(alpha: 0.18),
                      offset: const Offset(0, 14),
                      blurRadius: 24,
                      spreadRadius: -14),
                  BoxShadow(
                      color: c.fg.withValues(alpha: 0.0),
                      offset: Offset.zero,
                      blurRadius: 0,
                      spreadRadius: 0),
                ]
              : [
                  BoxShadow(
                      color: Colors.black.withValues(
                          alpha: widget.dark ? 0.15 : 0.06),
                      blurRadius: 14,
                      offset: const Offset(0, 6))
                ],
          border: sel
              ? Border.all(color: c.fg, width: 2)
              : Border.all(
                  color: widget.dark
                      ? _T.muted(widget.dark).withValues(alpha: 0.4)
                      : _T.line(widget.dark).withValues(alpha: 0.6),
                  width: 1),
        ),
        transform: sel
            ? Matrix4.translationValues(0, -3, 0)
            : Matrix4.identity(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Emoji icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: sel ? Colors.white : c.bg,
                    borderRadius: BorderRadius.circular(13),
                    border: sel
                        ? Border.all(color: c.fg.withValues(alpha: 0.3))
                        : null,
                  ),
                  child: Center(
                      child: Text(c.emoji,
                          style: const TextStyle(fontSize: 23))),
                ),
                const Spacer(),
                // Check badge
                ScaleTransition(
                  scale: CurvedAnimation(
                      parent: _bounceCtrl,
                      curve: const ElasticOutCurve(0.8)),
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: sel ? c.fg : Colors.transparent,
                      shape: BoxShape.circle,
                      border: sel
                          ? null
                          : Border.all(
                              color: _T.line(widget.dark), width: 1.5),
                    ),
                    child: sel
                        ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 13)
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              c.label,
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: sel ? c.fg : _T.ink(widget.dark),
                letterSpacing: -0.01,
              ),
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                Text(
                  '${c.stories} stories today',
                  style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: sel
                        ? c.fg.withValues(alpha: 0.7)
                        : _T.ink2(widget.dark),
                  ),
                ),
                if (c.hot) ...[
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: sel
                          ? c.fg.withValues(alpha: 0.15)
                          : c.bg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_fire_department_rounded,
                            size: 8, color: c.fg),
                        const SizedBox(width: 2),
                        Text(
                          'HOT',
                          style: TextStyle(
                            fontFamily: AppFonts.body,
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            color: c.fg,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 1 — DAILY GOAL
// ─────────────────────────────────────────────────────────────────────────────

class _GoalStep extends StatefulWidget {
  final bool dark;
  final String goal;
  final VoidCallback onBack;
  final VoidCallback onContinue;
  final void Function(String) onGoalChanged;

  const _GoalStep({
    required this.dark,
    required this.goal,
    required this.onBack,
    required this.onContinue,
    required this.onGoalChanged,
  });

  @override
  State<_GoalStep> createState() => _GoalStepState();
}

class _GoalStepState extends State<_GoalStep>
    with SingleTickerProviderStateMixin {
  late AnimationController _flameCtrl;

  @override
  void initState() {
    super.initState();
    _flameCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _flameCtrl.dispose();
    super.dispose();
  }

  String _fmtNum(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  static const _goals = [
    _GoalData(
        key: 'casual',
        name: 'Casual',
        flames: 1,
        q: 1,
        mins: '~30s',
        xp: 50,
        tag: 'Quick check-in'),
    _GoalData(
        key: 'balanced',
        name: 'Balanced',
        flames: 2,
        q: 3,
        mins: '~2 min',
        xp: 150,
        tag: '1.2K picked today',
        popular: true),
    _GoalData(
        key: 'all-in',
        name: 'All in',
        flames: 3,
        q: 5,
        mins: '~4 min',
        xp: 250,
        tag: 'Wake-up reps'),
  ];

  @override
  Widget build(BuildContext context) {
    final current = _goals.firstWhere((g) => g.key == widget.goal);
    final monthlyStories = current.q * 30;
    final monthlyXp = current.xp * 30;

    return Column(
      children: [
        _OnbHeader(step: 2, onBack: widget.onBack, dark: widget.dark),

        // Title
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pick your\ndaily pace.',
                        style: _T.displayStyle(widget.dark, size: 30)),
                    const SizedBox(height: 8),
                    Text(
                      "The smaller goal you'll keep beats the bigger one you won't.",
                      style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _T.ink2(widget.dark),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AnimatedBuilder(
                animation: _flameCtrl,
                builder: (_, __) => Transform.scale(
                  scale: 1.0 + 0.08 * _flameCtrl.value,
                  child: const Text('🔥',
                      style: TextStyle(fontSize: 36)),
                ),
              ),
            ],
          ),
        ),

        // Goal cards
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Column(
            children: _goals.map((g) {
              final sel = widget.goal == g.key;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _GoalCard(
                    goal: g,
                    selected: sel,
                    dark: widget.dark,
                    onTap: () => widget.onGoalChanged(g.key)),
              );
            }).toList(),
          ),
        ),

        // Live forecast
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _T.ink(widget.dark),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.trending_up_rounded,
                    color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: RichText(
                    key: ValueKey('${current.q}'),
                    text: TextSpan(
                      style: const TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.4,
                      ),
                      children: [
                        const TextSpan(text: "In 30 days you'll know "),
                        TextSpan(
                          text: '$monthlyStories stories',
                          style: const TextStyle(
                              color: Color(0xFFFFD6B8),
                              fontWeight: FontWeight.w800),
                        ),
                        const TextSpan(text: ' and earn '),
                        TextSpan(
                          text: '${_fmtNum(monthlyXp)} XP',
                          style: const TextStyle(
                              color: Color(0xFFFFD6B8),
                              fontWeight: FontWeight.w800),
                        ),
                        const TextSpan(text: '.'),
                      ],
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ),

        // Daily nudge
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _T.surface(widget.dark),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(
                        alpha: widget.dark ? 0.15 : 0.05),
                    blurRadius: 14,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Row(children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _T.primarySoft(widget.dark),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.notifications_rounded,
                    color: AppColors.accent, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Daily nudge',
                        style: TextStyle(
                          fontFamily: AppFonts.body,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: _T.ink(widget.dark),
                        )),
                    Text('Most pick mornings · keeps streaks alive',
                        style: TextStyle(
                          fontFamily: AppFonts.body,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _T.ink2(widget.dark),
                        )),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () async {
                  // Time picker not needed for visual polish
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: _T.ink(widget.dark),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          offset: const Offset(0, 3))
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '09:00',
                        style: TextStyle(
                          fontFamily: AppFonts.body,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: _T.bg(widget.dark),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right_rounded,
                          size: 13, color: _T.bg(widget.dark)),
                    ],
                  ),
                ),
              ),
            ]),
          ),
        ),

        const Spacer(),

        // CTA
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          child: _ChunkyButton(
            label: 'Lock it in',
            icon: Icons.arrow_forward_rounded,
            onTap: widget.onContinue,
          ),
        ),
      ],
    );
  }
}

class _GoalCard extends StatelessWidget {
  final _GoalData goal;
  final bool selected;
  final bool dark;
  final VoidCallback onTap;
  const _GoalCard(
      {required this.goal,
      required this.selected,
      required this.dark,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: selected
            ? Matrix4.translationValues(0, -2, 0)
            : Matrix4.identity(),
        padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : _T.surface(dark),
          borderRadius: BorderRadius.circular(18),
          boxShadow: selected
              ? [
                  const BoxShadow(
                      color: AppColors.accentDark,
                      offset: Offset(0, 5)),
                  BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 12)),
                ]
              : [
                  BoxShadow(
                      color: Colors.black
                          .withValues(alpha: dark ? 0.12 : 0.05),
                      blurRadius: 14,
                      offset: const Offset(0, 4))
                ],
        ),
        child: Row(children: [
          // Q/DAY badge
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: selected
                  ? Colors.white.withValues(alpha: 0.22)
                  : _T.primarySoft(dark),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${goal.q}',
                  style: TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : AppColors.accent,
                    height: 1,
                  ),
                ),
                Text(
                  'Q/DAY',
                  style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.08,
                    color: selected
                        ? Colors.white.withValues(alpha: 0.8)
                        : _T.muted(dark),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(
                    goal.name,
                    style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: selected ? Colors.white : _T.ink(dark),
                      letterSpacing: -0.01,
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Flame icons
                  ...List.generate(
                    goal.flames,
                    (_) => const Text('🔥',
                        style: TextStyle(fontSize: 11)),
                  ),
                  if (goal.popular) ...[
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: selected
                            ? Colors.white.withValues(alpha: 0.22)
                            : const Color(0xFFFFC15A),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'POPULAR',
                        style: TextStyle(
                          fontFamily: AppFonts.body,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: selected ? Colors.white : const Color(0xFF5C2E04),
                        ),
                      ),
                    ),
                  ],
                ]),
                const SizedBox(height: 2),
                Text(
                  goal.tag,
                  style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? Colors.white.withValues(alpha: 0.75)
                        : _T.muted(dark),
                  ),
                ),
                const SizedBox(height: 5),
                Row(children: [
                  Icon(Icons.timer_outlined,
                      size: 10,
                      color: selected
                          ? Colors.white.withValues(alpha: 0.85)
                          : _T.ink2(dark)),
                  const SizedBox(width: 3),
                  Text(
                    goal.mins,
                    style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? Colors.white.withValues(alpha: 0.85)
                          : _T.ink2(dark),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(Icons.bolt_rounded,
                      size: 11,
                      color: selected
                          ? Colors.white.withValues(alpha: 0.85)
                          : _T.ink2(dark)),
                  Text(
                    '+${goal.xp} XP/day',
                    style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? Colors.white.withValues(alpha: 0.85)
                          : _T.ink2(dark),
                    ),
                  ),
                ]),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Radio circle
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? Colors.white : Colors.transparent,
              border: selected
                  ? null
                  : Border.all(color: _T.line(dark), width: 2),
            ),
            child: selected
                ? const Icon(Icons.check_rounded,
                    color: AppColors.accent, size: 13)
                : null,
          ),
        ]),
      ),
    );
  }
}

class _GoalData {
  final String key;
  final String name;
  final int flames;
  final int q;
  final String mins;
  final int xp;
  final String tag;
  final bool popular;
  const _GoalData({
    required this.key,
    required this.name,
    required this.flames,
    required this.q,
    required this.mins,
    required this.xp,
    required this.tag,
    this.popular = false,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 2 — ALL SET
// ─────────────────────────────────────────────────────────────────────────────

class _AllSetStep extends StatefulWidget {
  final bool dark;
  final VoidCallback onFinish;
  final VoidCallback onBack;
  final String userName;
  const _AllSetStep(
      {required this.dark, required this.onFinish, required this.onBack, required this.userName});
  @override
  State<_AllSetStep> createState() => _AllSetStepState();
}

class _AllSetStepState extends State<_AllSetStep>
    with TickerProviderStateMixin {
  late AnimationController _medalCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _floatCtrl;
  late AnimationController _xpRollCtrl;
  int _xp = 0;

  late final List<({String emoji, String cat, Color color, String title})> _queued =
      _weeklyQueued[_isoWeekNumber(DateTime.now()) % _weeklyQueued.length];

  @override
  void initState() {
    super.initState();
    _medalCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..forward();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat();
    _floatCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3200))
      ..repeat(reverse: true);

    // XP roll: 0 → 20 over 1.2s
    _xpRollCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..forward();
    _xpRollCtrl.addListener(() {
      final v = (20 * _xpRollCtrl.value).round();
      if (v != _xp) setState(() => _xp = v);
    });
  }

  @override
  void dispose() {
    _medalCtrl.dispose();
    _pulseCtrl.dispose();
    _floatCtrl.dispose();
    _xpRollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _OnbHeader(step: 3, onBack: widget.onBack, dark: widget.dark),

          const SizedBox(height: 12),

          // Medal hero
          Stack(
            alignment: Alignment.center,
            children: [
              // Pulse ring
              AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, __) {
                  final scale = 1.0 + 0.45 * _pulseCtrl.value;
                  final opacity = (1 - _pulseCtrl.value) * 0.55;
                  return Transform.scale(
                    scale: scale,
                    child: Opacity(
                      opacity: opacity,
                      child: Container(
                        width: 116,
                        height: 116,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppColors.accent, width: 3),
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Medal circle
              ScaleTransition(
                scale: CurvedAnimation(
                    parent: _medalCtrl,
                    curve: const ElasticOutCurve(0.7)),
                child: Container(
                  width: 116,
                  height: 116,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [Color(0xFFFF9A62), AppColors.accent],
                      center: Alignment(-0.3, -0.3),
                    ),
                    boxShadow: const [
                      BoxShadow(
                          color: AppColors.accentDark,
                          offset: Offset(0, 8)),
                      BoxShadow(
                          color: Color(0x8DFF6A1A),
                          blurRadius: 40,
                          offset: Offset(0, 20)),
                    ],
                  ),
                  child: const Center(
                    child: Text('🔥', style: TextStyle(fontSize: 52)),
                  ),
                ),
              ),

              // Floating sparkles
              Positioned(
                top: 0,
                right: 80,
                child: _FloatWidget(
                    ctrl: _floatCtrl,
                    delay: 0,
                    amplitude: 6,
                    child: const Text('✦',
                        style: TextStyle(
                            fontSize: 20, color: AppColors.accent))),
              ),
              Positioned(
                bottom: 10,
                left: 66,
                child: _FloatWidget(
                    ctrl: _floatCtrl,
                    delay: 0.4,
                    amplitude: 7,
                    child: const Text('✦',
                        style: TextStyle(
                            fontSize: 16, color: Color(0xFF3B5BDB)))),
              ),
              Positioned(
                top: 20,
                right: 58,
                child: _FloatWidget(
                    ctrl: _floatCtrl,
                    delay: 0.7,
                    amplitude: 5,
                    child: const Text('✦',
                        style: TextStyle(
                            fontSize: 12, color: Color(0xFF7C3AED)))),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Title
          Text(
            "You're in, ${widget.userName}.",
            style: _T.displayStyle(widget.dark, size: 32),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Text(
              'Your daily brief is loaded. Take it now to start your streak.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _T.ink2(widget.dark),
                height: 1.4,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // +XP bonus pill
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(999),
              boxShadow: const [
                BoxShadow(color: AppColors.accentDark, offset: Offset(0, 3))
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bolt_rounded,
                    size: 13, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  '+$_xp XP',
                  style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'welcome bonus',
                  style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Fanned preview cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'QUEUED FOR YOU',
                  style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: _T.muted(widget.dark),
                    letterSpacing: 0.08,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 88,
                  child: Stack(
                    children: [
                      // Back card
                      Positioned(
                        top: 8,
                        left: 26,
                        right: 62,
                        child: Transform.rotate(
                          angle: -3 * math.pi / 180,
                          child: _QueuedCard(
                            dark: widget.dark,
                            catColor: _queued[0].color,
                            catLabel: '${_queued[0].emoji} ${_queued[0].cat}',
                            headline: _queued[0].title,
                          ),
                        ),
                      ),
                      // Middle card
                      Positioned(
                        top: 6,
                        left: 42,
                        right: 32,
                        child: Transform.rotate(
                          angle: 2 * math.pi / 180,
                          child: _QueuedCard(
                            dark: widget.dark,
                            catColor: _queued[1].color,
                            catLabel: '${_queued[1].emoji} ${_queued[1].cat}',
                            headline: _queued[1].title,
                          ),
                        ),
                      ),
                      // Front orange card
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: const [
                              BoxShadow(
                                  color: AppColors.accentDark,
                                  offset: Offset(0, 5)),
                              BoxShadow(
                                  color: Color(0x72FF5A1F),
                                  blurRadius: 20,
                                  offset: Offset(0, 10)),
                            ],
                          ),
                          child: Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '${_queued[2].emoji} ${_queued[2].cat}',
                                style: const TextStyle(
                                  fontFamily: AppFonts.body,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.bolt_rounded,
                                      size: 9, color: Colors.white),
                                  Text(
                                    '+50 XP',
                                    style: TextStyle(
                                      fontFamily: AppFonts.body,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ]),
                        ),
                      ),
                      Positioned(
                        top: 28,
                        left: 12,
                        right: 12,
                        child: Text(
                          _queued[2].title,
                          style: const TextStyle(
                            fontFamily: AppFonts.body,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Streak grid: 7 days
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YOUR FIRST WEEK',
                  style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: _T.muted(widget.dark),
                    letterSpacing: 0.08,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(7, (i) {
                    final isToday = i == 0;
                    final days = ['T', 'W', 'T', 'F', 'S', 'S', 'M'];
                    return Expanded(
                      child: Padding(
                        padding:
                            EdgeInsets.only(right: i < 6 ? 6 : 0),
                        child: Column(children: [
                          Text(
                            days[i],
                            style: TextStyle(
                              fontFamily: AppFonts.body,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: _T.muted(widget.dark),
                            ),
                          ),
                          const SizedBox(height: 4),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: 34,
                            decoration: BoxDecoration(
                              color: isToday
                                  ? AppColors.accent
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(11),
                              border: isToday
                                  ? null
                                  : Border.all(
                                      color: _T.line(widget.dark),
                                      width: 1.5,
                                      strokeAlign:
                                          BorderSide.strokeAlignInside,
                                      style: BorderStyle.none,
                                    ),
                              boxShadow: isToday
                                  ? const [
                                      BoxShadow(
                                          color: AppColors.accentDark,
                                          offset: Offset(0, 3))
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: isToday
                                  ? const Text('🔥',
                                      style: TextStyle(fontSize: 16))
                                  : Text(
                                      '${i + 1}',
                                      style: TextStyle(
                                        fontFamily: AppFonts.body,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: _T.muted(widget.dark),
                                      ),
                                    ),
                            ),
                          ),
                        ]),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // CTA
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 36),
            child: _ChunkyButton(
              label: 'Start my first brief',
              icon: Icons.play_arrow_rounded,
              onTap: widget.onFinish,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED COMPONENTS
// ─────────────────────────────────────────────────────────────────────────────

class _OnbHeader extends StatelessWidget {
  final int step;
  final VoidCallback onBack;
  final bool dark;
  const _OnbHeader({required this.step, required this.onBack, required this.dark});

  @override
  Widget build(BuildContext context) {
    final progress = step / 3.0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(children: [
        // Back button
        GestureDetector(
          onTap: onBack,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _T.surface(dark),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: _T.line(dark), offset: const Offset(0, 2))
              ],
            ),
            child: Icon(Icons.arrow_back_rounded,
                size: 18, color: _T.ink2(dark)),
          ),
        ),
        const SizedBox(width: 12),

        // Progress bar
        Expanded(
          child: Stack(children: [
            Container(
              height: 10,
              decoration: BoxDecoration(
                color: _T.line(dark),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeInOut,
              height: 10,
              width: (MediaQuery.of(context).size.width - 108) * progress,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.accent, AppColors.accentDark],
                ),
                borderRadius: BorderRadius.circular(5),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x55FF5A1F),
                      blurRadius: 6,
                      offset: Offset(0, 2))
                ],
              ),
            ),
            // Step pips
            ...List.generate(3, (i) {
              final frac = (i + 1) / 3.0;
              return Positioned(
                left: (MediaQuery.of(context).size.width - 108) * frac - 2,
                top: 3,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (i + 1) <= step
                        ? Colors.white.withValues(alpha: 0.8)
                        : Colors.black.withValues(alpha: 0.15),
                  ),
                ),
              );
            }),
          ]),
        ),
        const SizedBox(width: 12),

        // Step counter
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _T.surface(dark),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(color: _T.line(dark), offset: const Offset(0, 2))
            ],
          ),
          child: Text(
            '$step/3',
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: _T.ink2(dark),
            ),
          ),
        ),
      ]),
    );
  }
}

// Bottom CTA button (Duolingo-style: 4px hard shadow, depresses on press)
class _ChunkyButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _ChunkyButton(
      {required this.label, required this.icon, required this.onTap});
  @override
  State<_ChunkyButton> createState() => _ChunkyButtonState();
}

class _ChunkyButtonState extends State<_ChunkyButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        transform: _pressed
            ? Matrix4.translationValues(0, 4, 0)
            : Matrix4.identity(),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(18),
            boxShadow: _pressed
                ? const []
                : const [
                    BoxShadow(
                        color: AppColors.accentDark, offset: Offset(0, 4))
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.label,
                style: const TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.01,
                ),
              ),
              const SizedBox(width: 8),
              Icon(widget.icon, color: Colors.white, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// Floating animation wrapper
class _FloatWidget extends AnimatedWidget {
  final Widget child;
  final double delay; // 0.0–1.0 phase offset
  final double amplitude; // px, default 6

  const _FloatWidget({
    required AnimationController ctrl,
    required this.child,
    this.delay = 0,
    this.amplitude = 6,
  }) : super(listenable: ctrl);

  @override
  Widget build(BuildContext context) {
    final ctrl = listenable as AnimationController;
    final t = ((ctrl.value + delay) % 1.0);
    final y = amplitude * math.sin(t * math.pi);
    return Transform.translate(offset: Offset(0, -y), child: child);
  }
}

// Ring progress painter
class _RingPainter extends CustomPainter {
  final double value;
  final Color trackColor;
  final Color fillColor;
  final double strokeWidth;

  const _RingPainter({
    required this.value,
    required this.trackColor,
    required this.fillColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, paint..color = trackColor);
    if (value > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * value,
        false,
        paint..color = fillColor,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.fillColor != fillColor;
}

// Floating headline card (Welcome screen)
class _HeadlineCard extends StatelessWidget {
  final bool dark;
  final String cat;
  final Color catFg;
  final Color catBg;
  final String emoji;
  final String title;
  final String source;
  final bool highlight;

  const _HeadlineCard({
    required this.dark,
    required this.cat,
    required this.catFg,
    required this.catBg,
    required this.emoji,
    required this.title,
    required this.source,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlight ? AppColors.accent : _T.surface(dark),
        borderRadius: BorderRadius.circular(18),
        boxShadow: highlight
            ? const [
                BoxShadow(
                    color: AppColors.accentDark, offset: Offset(0, 6)),
                BoxShadow(
                    color: Color(0x80FF5A1F),
                    blurRadius: 24,
                    offset: Offset(0, 14)),
              ]
            : [
                BoxShadow(
                    color: Colors.black.withValues(alpha: dark ? 0.20 : 0.12),
                    blurRadius: 22,
                    offset: const Offset(0, 10)),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Category chip
          if (highlight)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$emoji ${cat.toUpperCase()}',
                style: const TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: catBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 10)),
                  const SizedBox(width: 4),
                  Text(
                    cat.toUpperCase(),
                    style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: catFg,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 7),
          Text(
            title,
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: highlight ? Colors.white : _T.ink(dark),
              height: 1.25,
              letterSpacing: -0.005,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 5),
          Text(
            '$source · 2h ago',
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: highlight
                  ? Colors.white.withValues(alpha: 0.75)
                  : _T.muted(dark),
            ),
          ),
        ],
      ),
    );
  }
}

// Queued card (small card in the fanned stack on All Set screen)
class _QueuedCard extends StatelessWidget {
  final bool dark;
  final Color catColor;
  final String catLabel;
  final String headline;
  const _QueuedCard(
      {required this.dark,
      required this.catColor,
      required this.catLabel,
      required this.headline});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _T.surface(dark),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: dark ? 0.18 : 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: catColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              catLabel,
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 8,
                fontWeight: FontWeight.w800,
                color: catColor,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            headline,
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: _T.ink(dark),
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

// Briefed logo wordmark
class _BriefedLogo extends StatelessWidget {
  final bool dark;
  const _BriefedLogo({required this.dark});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.accent, AppColors.accentDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(
                      color: AppColors.accentDark, offset: Offset(0, 3))
                ],
              ),
              child: const Center(
                child: Text(
                  'B',
                  style: TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
              ),
            ),
            Positioned(
              top: -3,
              right: -3,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC15A),
                  shape: BoxShape.circle,
                  border: Border.all(color: _T.bg(dark), width: 2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        Text(
          'Briefed',
          style: TextStyle(
            fontFamily: AppFonts.display,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _T.ink(dark),
            letterSpacing: -0.36,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM SHEET: fixed CTA overlay on Interests step
// ─────────────────────────────────────────────────────────────────────────────

// This is rendered as a Positioned overlay inside the Interests step body
class _InterestsCta extends StatelessWidget {
  final bool dark;
  final int selectedCount;
  final VoidCallback onContinue;
  const _InterestsCta(
      {required this.dark,
      required this.selectedCount,
      required this.onContinue});

  @override
  Widget build(BuildContext context) {
    final ok = selectedCount >= 3;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _T.bg(dark).withValues(alpha: 0),
            _T.bg(dark),
            _T.bg(dark),
          ],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: _ChunkyButton(
        label: ok ? 'Continue with $selectedCount' : 'Pick ${3 - selectedCount} more',
        icon: Icons.arrow_forward_rounded,
        onTap: ok ? onContinue : () {},
      ),
    );
  }
}
