import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:screenshot/screenshot.dart';
import 'package:confetti/confetti.dart';
import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/ad_service.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/gemini_service.dart';
import '../widgets/widgets.dart';

// STATIC GAME DATA

class _RealOrFakeData {
  static const List<Map<String, dynamic>> headlines = [
    {
      'headline':
          'Australia bans social media for children under 16, fines up to \$50M',
      'isReal': true,
      'explanation':
          'Australia passed this landmark law in late 2024, the first country globally to do so.'
    },
    {
      'headline': 'Twitter rebrands to X after Elon Musk acquisition',
      'isReal': true,
      'explanation':
          'Elon Musk completed his \$44B Twitter acquisition and rebranded it to X in 2023.'
    },
    {
      'headline': 'ChatGPT reaches 100 million users in just two months',
      'isReal': true,
      'explanation':
          'ChatGPT became the fastest-growing consumer app in history when it launched in late 2022.'
    },
    {
      'headline': 'India overtakes China as world\'s most populous country',
      'isReal': true,
      'explanation':
          'India surpassed China in 2023 according to UN population estimates.'
    },
    {
      'headline': 'Scientists release first ever image of a black hole',
      'isReal': true,
      'explanation':
          'The Event Horizon Telescope released the first black hole image in April 2019.'
    },
    {
      'headline':
          'NASA\'s Artemis I successfully completes uncrewed Moon mission',
      'isReal': true,
      'explanation':
          'Artemis I launched in November 2022 and completed a 25-day mission around the Moon.'
    },
    {
      'headline':
          'OpenAI\'s GPT-4 passes the bar exam scoring in top 10 percent',
      'isReal': true,
      'explanation':
          'GPT-4 scored in approximately the 90th percentile on the Uniform Bar Examination.'
    },
    {
      'headline': 'Japan\'s population declines for 13th consecutive year',
      'isReal': true,
      'explanation':
          'Japan has faced population decline since 2011 due to low birth rates and limited immigration.'
    },
    {
      'headline': 'Netflix loses subscribers for first time in over a decade',
      'isReal': true,
      'explanation':
          'Netflix reported losing 200,000 subscribers in Q1 2022, its first loss since 2011.'
    },
    {
      'headline': 'WHO declares COVID-19 a global pandemic',
      'isReal': true,
      'explanation':
          'The World Health Organisation officially declared COVID-19 a pandemic on March 11, 2020.'
    },
    {
      'headline':
          'Apple becomes first company to reach \$3 trillion market cap',
      'isReal': true,
      'explanation':
          'Apple briefly crossed \$3 trillion in January 2022, the first company to do so.'
    },
    {
      'headline': 'Spotify launches in 80 new markets in a single day',
      'isReal': true,
      'explanation':
          'Spotify expanded to 80 new markets in February 2021 including parts of Africa and Asia.'
    },
    {
      'headline':
          'France bans all smartphones in public parks to boost social interaction',
      'isReal': false,
      'explanation':
          'France has banned phones in schools, but no such law exists for public parks.'
    },
    {
      'headline': 'Google announces plans to acquire Reddit for \$8 billion',
      'isReal': false,
      'explanation':
          'Reddit went public via IPO in 2024. Google has not acquired it.'
    },
    {
      'headline':
          'Amazon opens world\'s first fully underwater warehouse in Norway',
      'isReal': false,
      'explanation':
          'This is entirely fictional. Amazon has no underwater facilities.'
    },
    {
      'headline':
          'Tesla launches solar-powered commercial airline service by 2026',
      'isReal': false,
      'explanation':
          'Tesla operates in EVs and energy storage, not commercial aviation.'
    },
    {
      'headline':
          'Scientists confirm daily coffee consumption reverses memory loss',
      'isReal': false,
      'explanation':
          'No study confirms coffee reverses memory loss. Some suggest mild cognitive benefits only.'
    },
    {
      'headline':
          'UN passes resolution making internet access a basic human right with enforcement',
      'isReal': false,
      'explanation':
          'The UN has called internet access important but passed no binding enforcement resolution.'
    },
    {
      'headline':
          'Microsoft acquires Nintendo for \$75 billion to enter gaming hardware market',
      'isReal': false,
      'explanation':
          'Microsoft acquired Activision Blizzard but has not acquired Nintendo.'
    },
    {
      'headline':
          'New study confirms humans only use 10 percent of their brain capacity',
      'isReal': false,
      'explanation':
          'This is a long-debunked myth. Brain imaging shows all areas of the brain are regularly active.'
    },
    {
      'headline':
          'Sweden mandates four-day work week for all companies with over 50 employees',
      'isReal': false,
      'explanation':
          'Sweden trialled shorter hours in some sectors but has no national four-day work week law.'
    },
    {
      'headline':
          'Apple launches its own satellite internet service to rival Starlink',
      'isReal': false,
      'explanation': 'Apple has not launched a satellite internet service.'
    },
  ];
}

class _OldestToLatestData {
  static const List<Map<String, dynamic>> events = [
    {
      'event': 'Neil Armstrong walks on the Moon',
      'year': 1969,
      'detail': 'Apollo 11 mission, July 20, 1969'
    },
    {
      'event': 'The Berlin Wall falls',
      'year': 1989,
      'detail': 'November 9, 1989'
    },
    {
      'event': 'The World Wide Web is invented',
      'year': 1991,
      'detail': 'First website live August 6, 1991'
    },
    {
      'event': 'Amazon is founded by Jeff Bezos',
      'year': 1994,
      'detail': 'Started as an online bookstore'
    },
    {
      'event': 'Google is founded',
      'year': 1998,
      'detail': 'Incorporated September 4, 1998'
    },
    {
      'event': 'Wikipedia launches publicly',
      'year': 2001,
      'detail': 'January 15, 2001'
    },
    {
      'event': 'Facebook launches from a Harvard dorm room',
      'year': 2004,
      'detail': 'February 4, 2004'
    },
    {
      'event': 'YouTube is founded',
      'year': 2005,
      'detail': 'First video uploaded April 23, 2005'
    },
    {
      'event': 'Twitter is founded',
      'year': 2006,
      'detail': 'First tweet by Jack Dorsey, March 21, 2006'
    },
    {
      'event': 'First iPhone is unveiled by Steve Jobs',
      'year': 2007,
      'detail': 'Macworld, January 9, 2007'
    },
    {
      'event': 'Barack Obama elected as US President',
      'year': 2008,
      'detail': 'November 4, 2008'
    },
    {
      'event': 'Bitcoin is created by Satoshi Nakamoto',
      'year': 2009,
      'detail': 'Genesis block mined January 3, 2009'
    },
    {
      'event': 'Instagram launches on the App Store',
      'year': 2010,
      'detail': 'October 6, 2010'
    },
    {
      'event': 'Snapchat launches',
      'year': 2011,
      'detail': 'Originally called "Picaboo"'
    },
    {
      'event': 'SpaceX lands a rocket booster for first time',
      'year': 2015,
      'detail': 'Cape Canaveral, December 21, 2015'
    },
    {
      'event': 'TikTok launches internationally',
      'year': 2018,
      'detail': 'Merged with Musical.ly, August 2018'
    },
    {
      'event': 'COVID-19 declared a global pandemic',
      'year': 2020,
      'detail': 'WHO declaration, March 11, 2020'
    },
    {
      'event': 'Elon Musk acquires Twitter and renames it X',
      'year': 2022,
      'detail': 'October 27, 2022'
    },
    {
      'event': 'ChatGPT launches publicly',
      'year': 2022,
      'detail': 'OpenAI, November 30, 2022'
    },
    {
      'event': 'India overtakes China as world\'s most populous country',
      'year': 2023,
      'detail': 'UN confirmed mid-2023'
    },
    {
      'event': 'Australia bans social media for under-16s',
      'year': 2024,
      'detail': 'World-first law, late 2024'
    },
  ];
}

IconData _iconForCat(String id) {
  switch (id) {
    case 'world':
      return Icons.language_rounded;
    case 'tech':
      return Icons.memory_rounded;
    case 'business':
      return Icons.trending_up_rounded;
    case 'sports':
      return Icons.sports_soccer_rounded;
    case 'entertainment':
      return Icons.star_rounded;
    default:
      return Icons.article_rounded;
  }
}

String _fmt(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}K' : '$n';
String _formatReminderTime(int hour, int minute) {
  final period = hour >= 12 ? 'PM' : 'AM';
  final displayHour = hour % 12 == 0 ? 12 : hour % 12;
  final displayMinute = minute.toString().padLeft(2, '0');
  return '$displayHour:$displayMinute $period';
}

// MAIN SHELL + NAV

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});
  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  final _pages = const [
    HomeScreen(),
    BriefingScreen(),
    GamesScreen(),
    ProfileScreen()
  ];
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final user = ref.read(userProvider);
    ref.read(newsProvider.notifier).load(
      country: user.country,
      categories: const [
        'world',
        'tech',
        'business',
        'sports',
        'entertainment'
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final tab = ref.watch(selectedTabProvider);
    return Scaffold(
      body: IndexedStack(index: tab, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
            color: context.isDark ? AppColors.darkNavBg : AppColors.lightNavBg,
            border: Border(top: BorderSide(color: context.borderColor))),
        child: SafeArea(
            top: false,
            child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _NavItem(
                          icon: Icons.home_rounded,
                          label: 'Home',
                          index: 0,
                          current: tab,
                          onTap: (i) =>
                              ref.read(selectedTabProvider.notifier).state = i),
                      _NavItem(
                          icon: Icons.article_rounded,
                          label: 'Briefing',
                          index: 1,
                          current: tab,
                          onTap: (i) =>
                              ref.read(selectedTabProvider.notifier).state = i),
                      _NavItem(
                          icon: Icons.games_rounded,
                          label: 'Games',
                          index: 2,
                          current: tab,
                          onTap: (i) =>
                              ref.read(selectedTabProvider.notifier).state = i),
                      _NavItem(
                          icon: Icons.person_rounded,
                          label: 'Profile',
                          index: 3,
                          current: tab,
                          onTap: (i) =>
                              ref.read(selectedTabProvider.notifier).state = i),
                    ]))),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index, current;
  final void Function(int) onTap;
  const _NavItem(
      {required this.icon,
      required this.label,
      required this.index,
      required this.current,
      required this.onTap});
  @override
  Widget build(BuildContext context) {
    final on = current == index;
    return GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
                color: on
                    ? AppColors.accent.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14)),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon,
                  size: 28, color: on ? AppColors.accent : context.hintColor),
              const SizedBox(height: 4),
              Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: on ? AppColors.accent : context.hintColor)),
            ])));
  }
}

// SPLASH

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale, _fade;
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      final user = AuthService.currentUser;
      if (user == null) {
        Navigator.of(context).pushReplacementNamed('/signin');
      } else if (StorageService.isOnboardingDone()) {
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        Navigator.of(context).pushReplacementNamed('/onboarding');
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppColors.accent,
        body: Center(
            child: FadeTransition(
                opacity: _fade,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  ScaleTransition(
                      scale: _scale,
                      child: Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(26),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 30,
                                    offset: const Offset(0, 10))
                              ]),
                          child: const Center(
                              child: Icon(Icons.newspaper_rounded,
                                  color: AppColors.accent, size: 42)))),
                  const SizedBox(height: 20),
                  Text('Briefed.',
                      style: GoogleFonts.poppins(
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -1.5)),
                  const SizedBox(height: 6),
                  Text('STAY SHARP',
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.7),
                          letterSpacing: 3.5)),
                ]))));
  }
}

// SIGN-IN SCREEN

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});
  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  bool _showEmailForm = false;
  bool _isLogin = true;
  bool _loading = false;
  String? _error;
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _navigate() {
    if (!mounted) return;
    ref.read(userProvider.notifier).syncAuthProfile(AuthService.currentUser);
    Navigator.of(context).pushReplacementNamed(
      StorageService.isOnboardingDone() ? '/home' : '/onboarding',
    );
  }

  Future<void> _googleSignIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService.signInWithGoogle();
      _navigate();
    } catch (e) {
      setState(() {
        _error = _friendly(e.toString());
        _loading = false;
      });
    }
  }

  Future<void> _emailSubmit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_isLogin) {
        await AuthService.signInWithEmail(
            email: _emailCtrl.text, password: _passCtrl.text);
      } else {
        await AuthService.createAccount(
            email: _emailCtrl.text,
            password: _passCtrl.text,
            name: _nameCtrl.text);
      }
      _navigate();
    } catch (e) {
      setState(() {
        _error = _friendly(e.toString());
        _loading = false;
      });
    }
  }

  Future<void> _continueAsGuest() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService.continueAsGuest();
      await ref.read(userProvider.notifier).resetForGuest();
      _navigate();
    } catch (e) {
      setState(() {
        _error = _friendly(e.toString());
        _loading = false;
      });
    }
  }

  String _friendly(String raw) {
    if (raw.contains('wrong-password') || raw.contains('invalid-credential'))
      return 'Incorrect email or password.';
    if (raw.contains('user-not-found'))
      return 'No account found with this email.';
    if (raw.contains('email-already-in-use'))
      return 'An account with this email already exists.';
    if (raw.contains('weak-password'))
      return 'Password must be at least 6 characters.';
    if (raw.contains('invalid-email'))
      return 'Please enter a valid email address.';
    if (raw.contains('network-request-failed'))
      return 'No internet connection.';
    return 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
          child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 32),

                    // ── Branding ──────────────────────────────────────────────────────────
                    Center(
                        child: Column(children: [
                      Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [
                                  AppColors.accent,
                                  AppColors.accentDark
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                  color:
                                      AppColors.accent.withValues(alpha: 0.35),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8))
                            ],
                          ),
                          child: const Icon(Icons.newspaper_rounded,
                              color: Colors.white, size: 38)),
                      const SizedBox(height: 18),
                      RichText(
                          text: TextSpan(children: [
                        TextSpan(
                            text: 'Briefed',
                            style: GoogleFonts.playfairDisplay(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: context.textColor,
                                letterSpacing: -1.2)),
                        TextSpan(
                            text: '.',
                            style: GoogleFonts.playfairDisplay(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: AppColors.accent,
                                letterSpacing: -1.2)),
                      ])),
                      const SizedBox(height: 6),
                      Text('Stay sharp. Stay informed.',
                          style: GoogleFonts.sourceSans3(
                              fontSize: 14, color: context.hintColor)),
                    ])),
                    const SizedBox(height: 48),

                    // ── Google ────────────────────────────────────────────────────────────
                    GestureDetector(
                      onTap: _loading ? null : _googleSignIn,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                            color: context.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: context.border2Color)),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const _GoogleLogo(size: 22),
                              const SizedBox(width: 12),
                              Text('Continue with Google',
                                  style: GoogleFonts.sourceSans3(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: context.textColor)),
                            ]),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Email button / form ───────────────────────────────────────────────
                    if (!_showEmailForm)
                      GestureDetector(
                        onTap: _loading
                            ? null
                            : () => setState(() => _showEmailForm = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(16)),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.email_rounded,
                                    color: Colors.white, size: 20),
                                const SizedBox(width: 10),
                                Text('Continue with Email',
                                    style: GoogleFonts.sourceSans3(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white)),
                              ]),
                        ),
                      )
                    else
                      BriefedCard(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                            // Sign In / Create Account toggle
                            Container(
                                decoration: BoxDecoration(
                                    color: context.inputBg,
                                    borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.all(4),
                                child: Row(children: [
                                  Expanded(
                                      child: GestureDetector(
                                          onTap: () =>
                                              setState(() => _isLogin = true),
                                          child: AnimatedContainer(
                                              duration: const Duration(
                                                  milliseconds: 180),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 10),
                                              decoration: BoxDecoration(
                                                  color: _isLogin
                                                      ? AppColors.accent
                                                      : Colors.transparent,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10)),
                                              child: Text('Sign In',
                                                  style: GoogleFonts.sourceSans3(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: _isLogin
                                                          ? Colors.white
                                                          : context.hintColor),
                                                  textAlign:
                                                      TextAlign.center)))),
                                  Expanded(
                                      child: GestureDetector(
                                          onTap: () =>
                                              setState(() => _isLogin = false),
                                          child: AnimatedContainer(
                                              duration: const Duration(
                                                  milliseconds: 180),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 10),
                                              decoration: BoxDecoration(
                                                  color: !_isLogin
                                                      ? AppColors.accent
                                                      : Colors.transparent,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10)),
                                              child: Text('Create Account',
                                                  style: GoogleFonts.sourceSans3(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: !_isLogin
                                                          ? Colors.white
                                                          : context.hintColor),
                                                  textAlign:
                                                      TextAlign.center)))),
                                ])),
                            const SizedBox(height: 16),
                            if (!_isLogin) ...[
                              _field(_nameCtrl, 'Your name',
                                  Icons.person_outline_rounded),
                              const SizedBox(height: 10),
                            ],
                            _field(_emailCtrl, 'Email', Icons.email_outlined,
                                type: TextInputType.emailAddress),
                            const SizedBox(height: 10),
                            _field(_passCtrl, 'Password',
                                Icons.lock_outline_rounded,
                                obscure: true),
                            const SizedBox(height: 16),
                            AccentButton(
                                text: _isLogin ? 'Sign In' : 'Create Account',
                                onTap: _loading ? () {} : _emailSubmit),
                            const SizedBox(height: 8),
                            GestureDetector(
                                onTap: () => setState(() {
                                      _showEmailForm = false;
                                      _error = null;
                                    }),
                                child: Center(
                                    child: Text('Back',
                                        style: GoogleFonts.sourceSans3(
                                            fontSize: 12,
                                            color: context.hintColor)))),
                          ])),

                    // ── Error ─────────────────────────────────────────────────────────────
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: AppColors.red.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppColors.red.withValues(alpha: 0.2))),
                          child: Text(_error!,
                              style: GoogleFonts.sourceSans3(
                                  fontSize: 12, color: AppColors.red))),
                    ],

                    // ── Loading ───────────────────────────────────────────────────────────
                    if (_loading) ...[
                      const SizedBox(height: 20),
                      const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.accent, strokeWidth: 2.5)),
                    ],

                    const SizedBox(height: 40),

                    // ── Guest ─────────────────────────────────────────────────────────────
                    Center(
                        child: GestureDetector(
                      onTap: _loading ? null : _continueAsGuest,
                      child: Text('Continue as Guest',
                          style: GoogleFonts.sourceSans3(
                              fontSize: 13,
                              color: context.hintColor,
                              decoration: TextDecoration.underline,
                              decorationColor: context.hintColor)),
                    )),
                    const SizedBox(height: 24),
                  ]))),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon,
      {TextInputType? type, bool obscure = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      obscureText: obscure,
      style: GoogleFonts.sourceSans3(fontSize: 14, color: context.textColor),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.sourceSans3(color: context.hintColor, fontSize: 14),
        prefixIcon: Icon(icon, size: 18, color: context.hintColor),
        filled: true,
        fillColor: context.inputBg,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

// ONBOARDING

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0;
  final List<String> _selected = ['world', 'tech', 'business'];
  int _notifHour = 8;
  int _notifMinute = 0;
  final List<Map<String, dynamic>> _notifOptions = [
    {
      'label': '7:00 AM',
      'sub': 'Early bird',
      'icon': Icons.wb_sunny_outlined,
      'hour': 7,
      'minute': 0
    },
    {
      'label': '8:30 AM',
      'sub': 'Morning',
      'icon': Icons.light_mode_outlined,
      'hour': 8,
      'minute': 30
    },
    {
      'label': '12:00 PM',
      'sub': 'Lunch break',
      'icon': Icons.lunch_dining_outlined,
      'hour': 12,
      'minute': 0
    },
    {
      'label': '6:00 PM',
      'sub': 'Evening',
      'icon': Icons.wb_twilight_outlined,
      'hour': 18,
      'minute': 0
    },
    {
      'label': '9:00 PM',
      'sub': 'Night owl',
      'icon': Icons.nightlight_outlined,
      'hour': 21,
      'minute': 0
    },
  ];
  Future<void> _finish() async {
    await StorageService.setOnboardingDone();
    await StorageService.setSelectedCategories(_selected);
    ref.read(userProvider.notifier).updateCategories(_selected);
    ref
        .read(userProvider.notifier)
        .updateNotificationTime(_notifHour, _notifMinute);
    if (mounted) Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: context.bgColor,
        body: SafeArea(
            child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  Row(
                      children: List.generate(
                          3,
                          (i) => Expanded(
                              child: Container(
                                  margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                                  height: 3,
                                  decoration: BoxDecoration(
                                      color: i <= _step
                                          ? AppColors.accent
                                          : context.borderColor,
                                      borderRadius:
                                          BorderRadius.circular(3)))))),
                  const SizedBox(height: 28),
                  Text('0${_step + 1} / 03',
                      style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: context.hintColor,
                          letterSpacing: 2)),
                  const SizedBox(height: 8),
                  if (_step == 0) ..._buildStep0(),
                  if (_step == 1) ..._buildStep1(),
                  if (_step == 2) ..._buildStep2(),
                ]))));
  }

  List<Widget> _buildStep0() => [
        Align(
            alignment: Alignment.centerLeft,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('What do you',
                  style: Theme.of(context).textTheme.headlineLarge),
              RichText(
                  text: TextSpan(children: [
                TextSpan(
                    text: 'care about',
                    style: Theme.of(context).textTheme.headlineLarge),
                TextSpan(
                    text: '?',
                    style: Theme.of(context)
                        .textTheme
                        .headlineLarge
                        ?.copyWith(color: AppColors.accent)),
              ])),
              const SizedBox(height: 6),
              Text('Pick 2 or more topics',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: context.subColor)),
            ])),
        const SizedBox(height: 28),
        Expanded(
            child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.6),
                itemCount: AppConstants.allCategories.length,
                itemBuilder: (context, i) {
                  final cat = AppConstants.allCategories[i];
                  final id = cat['id']!;
                  final on = _selected.contains(id);
                  final color = AppColors.categoryColor(cat['label']!);
                  return GestureDetector(
                      onTap: () => setState(() {
                            if (on) {
                              if (_selected.length > 1) _selected.remove(id);
                            } else {
                              _selected.add(id);
                            }
                          }),
                      child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                              color: on
                                  ? color.withValues(alpha: 0.1)
                                  : context.cardColor,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                  color: on
                                      ? color.withValues(alpha: 0.4)
                                      : context.borderColor),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withValues(
                                        alpha: context.isDark ? 0.2 : 0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2))
                              ]),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                          width: 34,
                                          height: 34,
                                          decoration: BoxDecoration(
                                              color: on
                                                  ? color.withValues(alpha: 0.2)
                                                  : context.inputBg,
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                          child: Icon(_iconForCat(id),
                                              size: 16,
                                              color: on
                                                  ? color
                                                  : context.hintColor)),
                                      if (on)
                                        Container(
                                            width: 18,
                                            height: 18,
                                            decoration: BoxDecoration(
                                                color: color,
                                                shape: BoxShape.circle),
                                            child: const Icon(
                                                Icons.check_rounded,
                                                color: Colors.white,
                                                size: 12)),
                                    ]),
                                Text(cat['label']!,
                                    style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: on
                                            ? context.textColor
                                            : context.subColor)),
                              ])));
                })),
        const SizedBox(height: 16),
        AccentButton(
            text: 'Continue',
            onTap: () => setState(() => _step = 1),
            icon: Icons.arrow_forward_rounded),
      ];
  List<Widget> _buildStep1() => [
        Align(
            alignment: Alignment.centerLeft,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('When should',
                  style: Theme.of(context).textTheme.headlineLarge),
              RichText(
                  text: TextSpan(children: [
                TextSpan(
                    text: 'we remind',
                    style: Theme.of(context).textTheme.headlineLarge),
                TextSpan(
                    text: ' you?',
                    style: Theme.of(context)
                        .textTheme
                        .headlineLarge
                        ?.copyWith(color: AppColors.accent)),
              ])),
              const SizedBox(height: 6),
              Text("We'll ping you when today's quiz drops",
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: context.subColor)),
            ])),
        const SizedBox(height: 24),
        Expanded(
            child: ListView.separated(
                itemCount: _notifOptions.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final isCustom = i == _notifOptions.length;
                  final opt = isCustom ? null : _notifOptions[i];
                  final on = isCustom
                      ? !_notifOptions.any((o) =>
                          _notifHour == o['hour'] &&
                          _notifMinute == o['minute'])
                      : _notifHour == opt!['hour'] &&
                          _notifMinute == opt['minute'];
                  return GestureDetector(
                      onTap: () async {
                        if (isCustom) {
                          final picked = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay(
                                  hour: _notifHour, minute: _notifMinute));
                          if (picked != null && mounted)
                            setState(() {
                              _notifHour = picked.hour;
                              _notifMinute = picked.minute;
                            });
                        } else {
                          setState(() {
                            _notifHour = opt!['hour'] as int;
                            _notifMinute = opt['minute'] as int;
                          });
                        }
                      },
                      child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                              color: on
                                  ? AppColors.accent.withValues(alpha: 0.08)
                                  : context.cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: on
                                      ? AppColors.accent.withValues(alpha: 0.4)
                                      : context.borderColor)),
                          child: Row(children: [
                            Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                    color: on
                                        ? AppColors.accent
                                            .withValues(alpha: 0.15)
                                        : context.inputBg,
                                    borderRadius: BorderRadius.circular(13)),
                                child: Icon(
                                    isCustom
                                        ? Icons.edit_calendar_rounded
                                        : opt!['icon'] as IconData,
                                    color: on
                                        ? AppColors.accent
                                        : context.hintColor,
                                    size: 20)),
                            const SizedBox(width: 14),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(
                                      isCustom
                                          ? _formatReminderTime(
                                              _notifHour, _notifMinute)
                                          : opt!['label'] as String,
                                      style: GoogleFonts.poppins(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: on
                                              ? context.textColor
                                              : context.subColor)),
                                  Text(
                                      isCustom
                                          ? 'Choose your own time'
                                          : opt!['sub'] as String,
                                      style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          color: context.hintColor)),
                                ])),
                            AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: on
                                        ? AppColors.accent
                                        : Colors.transparent,
                                    border: Border.all(
                                        color: on
                                            ? AppColors.accent
                                            : context.hintColor,
                                        width: 2)),
                                child: on
                                    ? const Icon(Icons.check_rounded,
                                        color: Colors.white, size: 13)
                                    : null),
                          ])));
                })),
        const SizedBox(height: 16),
        AccentButton(
            text: 'Continue',
            onTap: () => setState(() => _step = 2),
            icon: Icons.arrow_forward_rounded),
      ];
  List<Widget> _buildStep2() => [
        const Spacer(),
        Center(
            child: Column(children: [
          Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [AppColors.accent, AppColors.purple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.35),
                        blurRadius: 28,
                        offset: const Offset(0, 8))
                  ]),
              child: const Icon(Icons.bolt_rounded,
                  color: Colors.white, size: 38)),
          const SizedBox(height: 20),
          Text("You're ready.",
              style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 10),
          Text('Stay informed. Beat your friends.\nGrow smarter every day.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: context.subColor, height: 1.6),
              textAlign: TextAlign.center),
        ])),
        const Spacer(),
        AccentButton(
            text: "Let's Go!",
            onTap: _finish,
            icon: Icons.rocket_launch_rounded),
        const SizedBox(height: 10),
        Center(
            child: Text('No account needed · All progress saved locally',
                style: GoogleFonts.poppins(
                    fontSize: 10, color: context.hintColor))),
      ];
}

// HOME SCREEN

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    return Scaffold(
        backgroundColor: context.bgColor,
        body: SafeArea(
            child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(_greeting(),
                                  style: GoogleFonts.poppins(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: context.hintColor,
                                      letterSpacing: 2)),
                              const SizedBox(height: 2),
                              RichText(
                                  text: TextSpan(children: [
                                TextSpan(
                                    text: user.name.split(' ').first,
                                    style: GoogleFonts.poppins(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w800,
                                        color: context.textColor,
                                        letterSpacing: -0.8)),
                                TextSpan(
                                    text: '.',
                                    style: GoogleFonts.poppins(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.accent)),
                              ])),
                            ])),
                        BriefedCard(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child:
                                Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.local_fire_department_rounded,
                                  color: AppColors.accent, size: 16),
                              const SizedBox(width: 5),
                              Text('${user.streak}',
                                  style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: context.textColor)),
                              const SizedBox(width: 3),
                              Text('days',
                                  style: GoogleFonts.poppins(
                                      fontSize: 9, color: context.hintColor)),
                            ])),
                      ]),
                      const SizedBox(height: 12),
                      BriefedCard(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 9),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.bolt_rounded,
                                color: AppColors.gold, size: 16),
                            const SizedBox(width: 6),
                            Text('${_fmt(user.knowledgeScore)} pts',
                                style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: context.textColor)),
                            Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                width: 1,
                                height: 14,
                                color: context.borderColor),
                            Text(user.globalRankLabel,
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.gold)),
                          ])),
                      const SizedBox(height: 18),
                      _QuizHeroCard(
                          user: user,
                          latestResult: user.recentResults.isEmpty
                              ? null
                              : user.recentResults.first,
                          onTap: () =>
                              Navigator.of(context).pushNamed('/quiz')),
                      const SizedBox(height: 14),
                      _DidYouKnowCard(),
                      const SizedBox(height: 14),
                      const Center(child: _BannerAdWidget()),
                      const SizedBox(height: 8),
                    ]))));
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'GOOD MORNING';
    if (h < 17) return 'GOOD AFTERNOON';
    return 'GOOD EVENING';
  }
}

class _QuizHeroCard extends StatefulWidget {
  final UserData user;
  final QuizResult? latestResult;
  final VoidCallback onTap;
  const _QuizHeroCard(
      {required this.user, required this.latestResult, required this.onTap});
  @override
  State<_QuizHeroCard> createState() => _QuizHeroCardState();
}

class _QuizHeroCardState extends State<_QuizHeroCard> {
  late Timer _timer;
  late Duration _remaining;
  bool _loadingRewardAd = false;

  @override
  void initState() {
    super.initState();
    _remaining = _calcRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _remaining = _calcRemaining());
    });
    if (widget.user.hasPlayedToday && !StorageService.hasBonusPlayedToday()) {
      unawaited(AdService.loadRewarded());
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Duration _calcRemaining() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1).difference(now);
  }

  String _nextQuizIn() {
    final h = _remaining.inHours;
    final m = _remaining.inMinutes % 60;
    final s = _remaining.inSeconds % 60;
    return '${h.toString().padLeft(2, '0')}h ${m.toString().padLeft(2, '0')}m ${s.toString().padLeft(2, '0')}s';
  }

  Future<void> _onTap() async {
    // Not yet played today — normal flow
    if (!widget.user.hasPlayedToday) {
      widget.onTap();
      return;
    }
    if (StorageService.hasBonusPlayedToday() || _loadingRewardAd) return;

    setState(() => _loadingRewardAd = true);
    final earned = await AdService.showRewardedAndWait(
      allowDebugFallback: true,
    );
    if (!mounted) return;
    setState(() => _loadingRewardAd = false);
    if (!earned) return;

    await StorageService.setBonusPlayedToday();
    if (!mounted) return;
    Navigator.of(context).pushNamed('/quiz', arguments: {
      'forceRefresh': true,
      'bonusRound': true,
    });
  }

  @override
  Widget build(BuildContext context) {
    final played = widget.user.hasPlayedToday;
    final bonusUsed = played && StorageService.hasBonusPlayedToday();
    final canWatchAd = played && !bonusUsed;

    final gradientColors = !played
        ? [AppColors.accent, AppColors.accentDark]
        : [const Color(0xFF888888), const Color(0xFF555555)];
    final shadowColor = !played ? AppColors.accent : Colors.grey;

    return GestureDetector(
        onTap: _onTap,
        child: Container(
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                      color: shadowColor.withValues(alpha: 0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 8))
                ]),
            padding: const EdgeInsets.all(22),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                _badge('5 Questions'),
                const SizedBox(width: 8),
                _badge('~2 mins'),
                const SizedBox(width: 8),
                _badge(played ? '✓ Done today' : 'NEW')
              ]),
              const SizedBox(height: 12),
              Text('TODAY\'S TOPICS',
                  style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.7),
                      letterSpacing: 1.5)),
              const SizedBox(height: 6),
              Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: widget.user.selectedCategories.take(3).map((cat) {
                    final label = AppConstants.allCategories.firstWhere(
                        (c) => c['id'] == cat,
                        orElse: () => {'label': cat})['label']!;
                    return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(999)),
                        child: Text(label,
                            style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)));
                  }).toList()),
              const SizedBox(height: 14),
              Text(
                  played
                      ? "You've completed today's quiz!"
                      : "How well do you know what happened today?",
                  style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                      height: 1.25)),
              const SizedBox(height: 4),
              Text(
                  !played
                      ? '3 easy · 2 hard · Fresh quiz every morning'
                      : canWatchAd
                          ? _loadingRewardAd
                              ? 'Preparing your bonus ad...'
                              : 'Earn a bonus round by watching a short ad'
                          : 'New quiz available in ${_nextQuizIn()}',
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.7))),
              const SizedBox(height: 16),
              if (!played)
                Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 14,
                              offset: const Offset(0, 4))
                        ]),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.play_arrow_rounded,
                              color: AppColors.accent, size: 20),
                          const SizedBox(width: 6),
                          Text("Start Today's Quiz",
                              style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.accent)),
                        ]))
              else if (canWatchAd)
                Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                            width: 1.5)),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _loadingRewardAd
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation(Colors.white)))
                              : const Icon(Icons.play_circle_outline_rounded,
                                  color: Colors.white, size: 20),
                          const SizedBox(width: 6),
                          Text(
                              _loadingRewardAd
                                  ? 'Preparing Ad'
                                  : 'Watch Ad · Play Again',
                              style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white)),
                          const SizedBox(width: 8),
                          Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                  color: Colors.amber,
                                  borderRadius: BorderRadius.circular(6)),
                              child: Text('AD',
                                  style: GoogleFonts.poppins(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black))),
                        ]))
              else
                Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16)),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.lock_clock,
                                color: Colors.white54, size: 16),
                            const SizedBox(width: 6),
                            Text('Come back tomorrow',
                                style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white54)),
                          ]),
                      const SizedBox(height: 2),
                      Text(_nextQuizIn(),
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.white38,
                              fontWeight: FontWeight.w600)),
                    ])),
              if (widget.latestResult != null) ...[
                const SizedBox(height: 12),
                Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.16))),
                    child: Row(children: [
                      const Icon(Icons.history_rounded,
                          color: Colors.white, size: 15),
                      const SizedBox(width: 7),
                      Expanded(
                          child: Text(
                              'Last score: ${widget.latestResult!.score}/${widget.latestResult!.totalQuestions} · ${widget.latestResult!.performanceLabel}',
                              style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      Colors.white.withValues(alpha: 0.82)))),
                    ])),
              ],
            ])));
  }

  Widget _badge(String t) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(999)),
      child: Text(t,
          style: GoogleFonts.poppins(
              fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)));
}

class _DidYouKnowCard extends ConsumerStatefulWidget {
  @override
  ConsumerState<_DidYouKnowCard> createState() => _DidYouKnowCardState();
}

class _DidYouKnowCardState extends ConsumerState<_DidYouKnowCard> {
  final _ctrl = PageController();
  int _page = 0;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final news = ref.watch(newsProvider);
    if (news.articles.isEmpty) return const SizedBox.shrink();

    // Pick up to 5 articles spread across the feed for variety
    final articles = news.articles.length <= 5
        ? news.articles
        : [0, 1, 2, 3, 4]
            .map((i) => news.articles[(i * news.articles.length ~/ 5)
                .clamp(0, news.articles.length - 1)])
            .toList();

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6A0DAD), Color(0xFF3B0FAB), Color(0xFF1565C0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(children: [
          // Decorative large quote mark
          Positioned(
              top: -8,
              left: 12,
              child: Text('"',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 120,
                    fontWeight: FontWeight.w900,
                    color: Colors.white.withValues(alpha: 0.08),
                    height: 1,
                  ))),

          // Main content
          Column(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(
              height: 180,
              child: PageView.builder(
                controller: _ctrl,
                itemCount: articles.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) {
                  final a = articles[i];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.lightbulb_rounded,
                                        color: Colors.white, size: 10),
                                    const SizedBox(width: 4),
                                    Text('DID YOU KNOW',
                                        style: GoogleFonts.sourceSans3(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: 1.2,
                                        )),
                                  ]),
                            ),
                            const Spacer(),
                            // Share
                            GestureDetector(
                              onTap: () =>
                                  Share.share('${a.title}\n\nvia Briefed'),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.share_rounded,
                                    color: Colors.white, size: 14),
                              ),
                            ),
                          ]),
                          const SizedBox(height: 14),
                          Text(
                            a.title,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.5,
                            ),
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ]),
                  );
                },
              ),
            ),

            // Source + dots
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    articles[_page].sourceName,
                    style: GoogleFonts.sourceSans3(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.8)),
                  ),
                ),
                const Spacer(),
                // Page dots
                Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      articles.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.only(left: 4),
                        width: i == _page ? 16 : 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: i == _page
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    )),
              ]),
            ),
          ]),
        ]),
      ),
    );
  }
}

// BRIEFING SCREEN

class BriefingScreen extends ConsumerStatefulWidget {
  const BriefingScreen({super.key});
  @override
  ConsumerState<BriefingScreen> createState() => _BriefingScreenState();
}

class _BriefingScreenState extends ConsumerState<BriefingScreen>
    with SingleTickerProviderStateMixin {
  static const _filters = [
    'For you',
    'Headlines',
    'Technology',
    'World',
    'Business',
    'Sports',
    'Entertainment'
  ];
  late final TabController _tabCtrl;
  final ScrollController _tabScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _filters.length, vsync: this);
    _tabCtrl.addListener(_onTabChange);
  }

  void _onTabChange() {
    if (mounted) {
      setState(() {});
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _scrollTabIntoView(_tabCtrl.index));
    }
  }

  void _scrollTabIntoView(int i) {
    if (!_tabScroll.hasClients) return;
    const itemW = 90.0;
    final screenW = MediaQuery.of(context).size.width;
    final target = (i * itemW) - (screenW / 2 - itemW / 2);
    _tabScroll.animateTo(target.clamp(0.0, _tabScroll.position.maxScrollExtent),
        duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _tabCtrl.removeListener(_onTabChange);
    _tabCtrl.dispose();
    _tabScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final news = ref.watch(newsProvider);
    return Scaffold(
        backgroundColor: context.bgColor,
        body: SafeArea(
            child: Column(children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(children: [
                Expanded(
                    child: RichText(
                        text: TextSpan(children: [
                  TextSpan(
                      text: 'Briefed',
                      style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: context.textColor,
                          letterSpacing: -0.8)),
                  TextSpan(
                      text: '.',
                      style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: AppColors.accent)),
                  TextSpan(
                      text: '  Briefing',
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: context.hintColor)),
                ]))),
                BriefedCard(
                    padding: const EdgeInsets.all(8),
                    child: Icon(Icons.search_rounded,
                        color: context.hintColor, size: 18)),
              ])),
          SizedBox(
              height: 50,
              child: ListView.builder(
                  controller: _tabScroll,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                  itemCount: _filters.length,
                  itemBuilder: (context, i) {
                    final on = _tabCtrl.index == i;
                    return GestureDetector(
                        onTap: () => _tabCtrl.animateTo(i),
                        child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                                border: Border(
                                    bottom: BorderSide(
                                        color: on
                                            ? AppColors.accent
                                            : Colors.transparent,
                                        width: 2.5))),
                            child: Center(
                                child: Text(_filters[i],
                                    style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: on
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        color: on
                                            ? AppColors.accent
                                            : context.subColor)))));
                  })),
          Divider(height: 1, color: context.borderColor),
          Expanded(
              child: news.isLoading
                  ? _buildShimmer()
                  : TabBarView(
                      controller: _tabCtrl,
                      children: _filters
                          .map((f) => RefreshIndicator(
                                color: AppColors.accent,
                                onRefresh: () =>
                                    ref.read(newsProvider.notifier).refresh(),
                                child: _buildFeed(news.articles, f),
                              ))
                          .toList())),
        ])));
  }

  List<NewsArticle> _filtered(List<NewsArticle> all, String filter) {
    switch (filter) {
      case 'For you':
        return all;
      case 'Headlines':
        return all.take(6).toList();
      default:
        return all
            .where(
                (a) => a.category.toLowerCase().contains(filter.toLowerCase()))
            .toList();
    }
  }

  Widget _buildFeed(List<NewsArticle> articles, String filter) {
    final items = _filtered(articles, filter);
    if (items.isEmpty) {
      return ListView(children: [
        Center(
            child: Padding(
                padding: const EdgeInsets.only(top: 80),
                child: Text(
                    'No ${filter == "For you" ? "stories" : filter.toLowerCase()} articles yet',
                    style: GoogleFonts.poppins(color: context.hintColor))))
      ]);
    }

    if (filter == 'For you') {
      final hero = items.first;
      final rows = items.skip(1).take(3).toList();
      String artKey(NewsArticle a) => a.link.isNotEmpty ? a.link : a.title;
      final shown = <String>{artKey(hero), ...rows.map(artKey)};

      return ListView(padding: EdgeInsets.zero, children: [
        Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const _SectionHeader(title: 'Top stories'),
              const SizedBox(height: 10),
              _HeroStoryCard(
                  article: hero, onTap: () => _openArticle(context, hero)),
            ])),
        if (rows.isNotEmpty)
          Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: BriefedCard(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
                  child: Column(
                      children: rows
                          .asMap()
                          .entries
                          .map((e) => StoryRow(
                              title: e.value.title,
                              sourceName: e.value.sourceName,
                              category: e.value.category,
                              timeAgo: e.value.timeAgo,
                              isLast: e.key == 2,
                              onTap: () => _openArticle(context, e.value)))
                          .toList()))),
        Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: _QuizPromoStrip()),
        const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: _NativeAdCard()),
        ...['technology', 'world', 'business', 'sports', 'entertainment']
            .map((cat) {
          final catArticles = articles
              .where((a) =>
                  a.category.toLowerCase() == cat && !shown.contains(artKey(a)))
              .toList();
          if (catArticles.isEmpty) return const SizedBox.shrink();
          final visible = catArticles.take(3).toList();
          for (final a in visible) {
            shown.add(artKey(a));
          }
          final label = cat[0].toUpperCase() + cat.substring(1);
          return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(child: _BannerAdWidget()),
                    const SizedBox(height: 14),
                    _SectionHeader(title: label, category: cat),
                    const SizedBox(height: 10),
                    BriefedCard(
                        padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
                        child: Column(
                            children: visible
                                .asMap()
                                .entries
                                .map((e) => StoryRow(
                                    title: e.value.title,
                                    sourceName: e.value.sourceName,
                                    category: e.value.category,
                                    timeAgo: e.value.timeAgo,
                                    isLast: e.key == min(2, visible.length - 1),
                                    onTap: () =>
                                        _openArticle(context, e.value)))
                                .toList())),
                  ]));
        }),
        const SizedBox(height: 24),
      ]);
    }

    // Headlines
    if (filter == 'Headlines') {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          Row(children: [
            const Expanded(child: _SectionHeader(title: 'Latest headlines')),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
                border:
                    Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
              ),
              child: Text(
                '${items.length} updates',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.accent,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          _HeadlineLeadCard(
            article: items.first,
            onTap: () => _openArticle(context, items.first),
          ),
          const SizedBox(height: 12),
          ...items.skip(1).toList().asMap().entries.map((e) {
            final article = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _HeadlineCard(
                article: article,
                rank: e.key + 2,
                onTap: () => _openArticle(context, article),
              ),
            );
          }),
        ],
      );
    }

    // Specific category
    final cat = filter.toLowerCase();
    return ListView(padding: EdgeInsets.zero, children: [
      Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _SectionHeader(title: filter, category: cat),
            const SizedBox(height: 10),
            _HeroStoryCard(
                article: items.first,
                onTap: () => _openArticle(context, items.first)),
          ])),
      if (items.length > 1)
        Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: BriefedCard(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
                child: Column(
                    children: items
                        .skip(1)
                        .toList()
                        .asMap()
                        .entries
                        .map((e) => StoryRow(
                            title: e.value.title,
                            sourceName: e.value.sourceName,
                            category: e.value.category,
                            timeAgo: e.value.timeAgo,
                            isLast: e.key == items.length - 2,
                            onTap: () => _openArticle(context, e.value)))
                        .toList()))),
      const Padding(
          padding: EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Center(child: _BannerAdWidget())),
      const SizedBox(height: 24),
    ]);
  }

  Widget _buildShimmer() => ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ShimmerBox(width: double.infinity, height: 140, borderRadius: 18),
            SizedBox(height: 8),
            ShimmerBox(width: 200, height: 14, borderRadius: 7),
            SizedBox(height: 6),
            ShimmerBox(width: double.infinity, height: 14, borderRadius: 7),
          ])));
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? category;
  const _SectionHeader({required this.title, this.category});
  IconData _icon(String cat) {
    switch (cat.toLowerCase()) {
      case 'technology':
        return Icons.memory_rounded;
      case 'business':
        return Icons.trending_up_rounded;
      case 'sports':
        return Icons.sports_soccer_rounded;
      case 'entertainment':
        return Icons.star_rounded;
      case 'world':
        return Icons.language_rounded;
      default:
        return Icons.article_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = category != null
        ? AppColors.categoryColor(category!)
        : context.textColor;
    return Row(children: [
      if (category != null) ...[
        Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
                color: AppColors.categoryBg(category!),
                borderRadius: BorderRadius.circular(7)),
            child: Icon(_icon(category!), size: 13, color: color)),
        const SizedBox(width: 8),
      ],
      Text(title,
          style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: context.textColor)),
      const SizedBox(width: 6),
      const Icon(Icons.chevron_right_rounded,
          color: AppColors.accent, size: 16),
    ]);
  }
}

class _HeadlineLeadCard extends StatelessWidget {
  final NewsArticle article;
  final VoidCallback? onTap;
  const _HeadlineLeadCard({required this.article, this.onTap});

  @override
  Widget build(BuildContext context) {
    final catColor = AppColors.categoryColor(article.category);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: catColor.withValues(alpha: 0.22)),
          boxShadow: [
            BoxShadow(
              color: catColor.withValues(alpha: context.isDark ? 0.16 : 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Stack(children: [
            _HeadlineImage(article: article, height: 154),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.0),
                      Colors.black.withValues(alpha: 0.58),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Row(children: [
                CategoryTag(category: article.category, small: true),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${article.sourceName}  -  ${article.timeAgo}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.86),
                    ),
                  ),
                ),
              ]),
            ),
          ]),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'LEAD STORY',
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                      color: catColor,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_rounded,
                    size: 17, color: context.hintColor),
              ]),
              const SizedBox(height: 9),
              Text(
                article.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  height: 1.32,
                  color: context.textColor,
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _HeadlineCard extends StatelessWidget {
  final NewsArticle article;
  final int rank;
  final VoidCallback? onTap;
  const _HeadlineCard({
    required this.article,
    required this.rank,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final catColor = AppColors.categoryColor(article.category);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.borderColor),
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withValues(alpha: context.isDark ? 0.18 : 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Stack(children: [
            _HeadlineImage(article: article, width: 78, height: 78),
            Positioned(
              left: 6,
              top: 6,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: context.cardColor.withValues(alpha: 0.92),
                  shape: BoxShape.circle,
                  border: Border.all(color: catColor.withValues(alpha: 0.28)),
                ),
                child: Center(
                  child: Text(
                    '$rank',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: catColor,
                    ),
                  ),
                ),
              ),
            ),
          ]),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text(
                    article.sourceName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: catColor,
                    ),
                  ),
                ),
                Text(
                  article.timeAgo,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: context.hintColor,
                  ),
                ),
              ]),
              const SizedBox(height: 5),
              Text(
                article.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                  color: context.textColor,
                ),
              ),
              const SizedBox(height: 9),
              Row(children: [
                Flexible(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: CategoryTag(category: article.category, small: true),
                  ),
                ),
                const Spacer(),
                Icon(Icons.chevron_right_rounded,
                    size: 18, color: context.hintColor),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _HeadlineImage extends StatelessWidget {
  final NewsArticle article;
  final double? width;
  final double height;
  const _HeadlineImage({
    required this.article,
    this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final catColor = AppColors.categoryColor(article.category);
    final hasImage = article.imageUrl != null && article.imageUrl!.isNotEmpty;
    Widget placeholder = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            catColor.withValues(alpha: 0.76),
            AppColors.categoryBg(article.category),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(Icons.article_rounded,
          size: min(height * 0.42, 42),
          color: Colors.white.withValues(alpha: 0.38)),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(width == null ? 0 : 13),
      child: hasImage
          ? Image.network(
              article.imageUrl!,
              width: width,
              height: height,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => placeholder,
            )
          : placeholder,
    );
  }
}

class _HeroStoryCard extends StatelessWidget {
  final NewsArticle article;
  final VoidCallback? onTap;
  const _HeroStoryCard({required this.article, this.onTap});

  Widget _placeholder(Color catColor) => Container(
        height: 200,
        decoration: BoxDecoration(
            gradient: LinearGradient(
          colors: [
            catColor.withValues(alpha: 0.6),
            catColor.withValues(alpha: 0.2)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )),
        child: Center(
            child: Icon(Icons.article_rounded,
                size: 64, color: Colors.white.withValues(alpha: 0.3))),
      );

  @override
  Widget build(BuildContext context) {
    final catColor = AppColors.categoryColor(article.category);
    final hasImage = article.imageUrl != null && article.imageUrl!.isNotEmpty;
    return GestureDetector(
        onTap: onTap,
        child: BriefedCard(
            padding: EdgeInsets.zero,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                child: hasImage
                    ? Image.network(article.imageUrl!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(catColor))
                    : _placeholder(catColor),
              ),
              Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                  color: AppColors.categoryBg(article.category),
                                  borderRadius: BorderRadius.circular(5)),
                              child: Center(
                                  child: Text(
                                      article.sourceName
                                          .substring(
                                              0,
                                              article.sourceName.length
                                                  .clamp(0, 2))
                                          .toUpperCase(),
                                      style: GoogleFonts.poppins(
                                          fontSize: 7,
                                          fontWeight: FontWeight.w900,
                                          color: catColor)))),
                          const SizedBox(width: 6),
                          Text(article.sourceName,
                              style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: context.hintColor)),
                          const SizedBox(width: 4),
                          Text('·',
                              style: TextStyle(
                                  color: context.hintColor, fontSize: 10)),
                          const SizedBox(width: 4),
                          Text(article.timeAgo,
                              style: GoogleFonts.poppins(
                                  fontSize: 11, color: context.hintColor)),
                        ]),
                        const SizedBox(height: 7),
                        Text(article.title,
                            style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: context.textColor,
                                letterSpacing: 0.1,
                                height: 1.55)),
                        const SizedBox(height: 12),
                        Row(children: [
                          CategoryTag(category: article.category, small: true),
                          const Spacer(),
                          GestureDetector(
                              onTap: () => Share.share(
                                  '${article.title}\n\n${article.link}'),
                              child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                      color: context.inputBg,
                                      borderRadius: BorderRadius.circular(10)),
                                  child: Icon(Icons.share_rounded,
                                      color: context.hintColor, size: 16))),
                        ]),
                      ])),
            ])));
  }
}

void _openArticle(BuildContext ctx, NewsArticle article) {
  showModalBottomSheet(
    context: ctx,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ArticleSheet(article: article),
  );
}

Future<void> _launchUrl(String link) async {
  final uri = Uri.tryParse(link);
  if (uri == null) return;
  try {
    await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
  } catch (_) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _ArticleSheet extends StatelessWidget {
  final NewsArticle article;
  const _ArticleSheet({required this.article});

  @override
  Widget build(BuildContext context) {
    final hasLink = article.link.isNotEmpty;
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 28),
      decoration: BoxDecoration(
        color: context.bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
              child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                      color: context.borderColor,
                      borderRadius: BorderRadius.circular(2)))),
          Row(children: [
            CategoryTag(category: article.category, small: true),
            const SizedBox(width: 8),
            Text(article.timeAgo,
                style: GoogleFonts.poppins(
                    fontSize: 11, color: context.hintColor)),
            const Spacer(),
            Text(article.sourceName,
                style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: context.subColor)),
          ]),
          const SizedBox(height: 12),
          Text(article.title,
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: context.textColor,
                  letterSpacing: -0.4,
                  height: 1.35)),
          if (article.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(article.description,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: context.subColor, height: 1.6)),
          ],
          const SizedBox(height: 20),
          Row(children: [
            GestureDetector(
              onTap: () => Share.share('${article.title}\n\n${article.link}'),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                decoration: BoxDecoration(
                    color: context.inputBg,
                    borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  Icon(Icons.share_rounded, size: 16, color: context.subColor),
                  const SizedBox(width: 6),
                  Text('Share',
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: context.subColor)),
                ]),
              ),
            ),
            if (hasLink) ...[
              const SizedBox(width: 10),
              Expanded(
                  child: AccentButton(
                text: 'Read Full Story',
                icon: Icons.open_in_new_rounded,
                fontSize: 13,
                padding: const EdgeInsets.symmetric(vertical: 13),
                onTap: () => _launchUrl(article.link),
              )),
            ],
          ]),
        ],
      ),
    );
  }
}

class _QuizPromoStrip extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final played = user.hasPlayedToday;

    void onTap() {
      if (!played) {
        Navigator.of(context).pushNamed('/quiz');
      } else {
        // Quiz already played — switch to Home tab where the full quiz card is shown
        ref.read(selectedTabProvider.notifier).state = 0;
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.08),
              border:
                  Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
              borderRadius: BorderRadius.circular(18)),
          child: Row(children: [
            Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [AppColors.accent, AppColors.accentDark]),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4))
                    ]),
                child: const Icon(Icons.bolt_rounded,
                    color: Colors.white, size: 24)),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('Test your knowledge',
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: context.textColor)),
                  Text(
                      played
                          ? 'Come back tomorrow for a fresh quiz'
                          : '5 questions from today\'s top stories',
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: context.subColor)),
                ])),
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [AppColors.accent, AppColors.accentDark]),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 3))
                    ]),
                child: Text(played ? 'View' : 'Start Quiz',
                    style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white))),
          ])),
    );
  }
}

// GAMES SCREEN

class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: context.bgColor,
        body: SafeArea(
            child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Games',
                          style: Theme.of(context).textTheme.headlineLarge),
                      const SizedBox(height: 4),
                      Text('Quick news games to sharpen your mind',
                          style: GoogleFonts.poppins(
                              fontSize: 13, color: context.subColor)),
                      const SizedBox(height: 24),
                      _GameCard(
                          gradient: const LinearGradient(
                              colors: [Color(0xFF2979FF), Color(0xFF1565C0)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight),
                          icon: Icons.fact_check_rounded,
                          title: 'Real or Fake?',
                          description:
                              'Can you tell a real headline from a convincing fake? 10 rounds, tap as fast as you can.',
                          tag: 'QUICK PLAY',
                          tagColor: AppColors.blue,
                          stats: const [
                            '10 rounds',
                            '~60 sec',
                            'Unlimited plays'
                          ],
                          onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const RealOrFakeGame()))),
                      const SizedBox(height: 16),
                      _GameCard(
                          gradient: const LinearGradient(
                              colors: [Color(0xFF7C4DFF), Color(0xFF512DA8)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight),
                          icon: Icons.timeline_rounded,
                          title: 'Oldest to Latest',
                          description:
                              'Sort 4 historical events from oldest to most recent. Sounds easy — it\'s not.',
                          tag: 'BRAIN TEASER',
                          tagColor: AppColors.purple,
                          stats: const [
                            '4 events',
                            '~45 sec',
                            'Unlimited rounds'
                          ],
                          onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const OldestToLatestGame()))),
                      const SizedBox(height: 24),
                      Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                              color: context.cardColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: context.borderColor)),
                          child: Row(children: [
                            Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                    color: context.inputBg,
                                    borderRadius: BorderRadius.circular(13)),
                                child: Icon(Icons.lock_rounded,
                                    color: context.hintColor, size: 22)),
                            const SizedBox(width: 14),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text('More games coming soon',
                                      style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: context.subColor)),
                                  Text(
                                      'Flash Headlines, News Connections & more',
                                      style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          color: context.hintColor)),
                                ])),
                          ])),
                    ]))));
  }
}

class _GameCard extends StatelessWidget {
  final LinearGradient gradient;
  final IconData icon;
  final String title, description, tag;
  final Color tagColor;
  final List<String> stats;
  final VoidCallback onTap;
  const _GameCard(
      {required this.gradient,
      required this.icon,
      required this.title,
      required this.description,
      required this.tag,
      required this.tagColor,
      required this.stats,
      required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: onTap,
        child: Container(
            decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                      color: tagColor.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8))
                ]),
            padding: const EdgeInsets.all(22),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14)),
                    child: Icon(icon, color: Colors.white, size: 26)),
                const SizedBox(width: 14),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(999)),
                      child: Text(tag,
                          style: GoogleFonts.poppins(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 1.5))),
                  const SizedBox(height: 4),
                  Text(title,
                      style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5)),
                ]),
              ]),
              const SizedBox(height: 14),
              Text(description,
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.8),
                      height: 1.55)),
              const SizedBox(height: 16),
              Row(children: [
                ...stats.map((s) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(999)),
                        child: Text(s,
                            style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.white))))),
                const Spacer(),
                Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 3))
                        ]),
                    child: Icon(Icons.play_arrow_rounded,
                        color: tagColor, size: 20)),
              ]),
            ])));
  }
}

// REAL OR FAKE GAME

class RealOrFakeGame extends StatefulWidget {
  const RealOrFakeGame({super.key});
  @override
  State<RealOrFakeGame> createState() => _RealOrFakeGameState();
}

class _RealOrFakeGameState extends State<RealOrFakeGame>
    with SingleTickerProviderStateMixin {
  late List<Map<String, dynamic>> _deck;
  int _index = 0, _score = 0;
  String? _tapped;
  bool _finished = false;
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;
  static const int _rounds = 10;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _shakeAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticOut));
    _buildDeck();
  }

  void _buildDeck() {
    final all = List<Map<String, dynamic>>.from(_RealOrFakeData.headlines)
      ..shuffle();
    _deck = all.take(_rounds).toList();
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _answer(bool guessedReal) {
    if (_tapped != null) return;
    final isReal = _deck[_index]['isReal'] as bool;
    final correct = guessedReal == isReal;
    setState(() {
      _tapped = guessedReal ? 'real' : 'fake';
      if (correct) _score++;
    });
    if (!correct) _shakeCtrl.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      if (_index + 1 >= _rounds) {
        AdService.showInterstitial(then: () {
          if (mounted) setState(() => _finished = true);
        });
      } else {
        setState(() {
          _index++;
          _tapped = null;
        });
      }
    });
  }

  void _restart() {
    _buildDeck();
    setState(() {
      _index = 0;
      _score = 0;
      _tapped = null;
      _finished = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: context.bgColor,
        appBar: AppBar(
            title: Text('Real or Fake?',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w800)),
            centerTitle: true,
            leading: BackButton(color: context.subColor),
            actions: [
              Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Center(
                      child: Text('${_index + 1}/$_rounds',
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: context.subColor))))
            ]),
        body: _finished ? _buildResult() : _buildGame());
  }

  Widget _buildGame() {
    final item = _deck[_index];
    final isReal = item['isReal'] as bool;
    final headline = item['headline'] as String;
    final explanation = item['explanation'] as String;
    final answered = _tapped != null;
    final correct = _tapped == (isReal ? 'real' : 'fake');
    return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                  value: _index / _rounds,
                  minHeight: 4,
                  backgroundColor: context.inputBg,
                  valueColor: const AlwaysStoppedAnimation(AppColors.blue))),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Round ${_index + 1} of $_rounds',
                style: GoogleFonts.poppins(
                    fontSize: 10, color: context.hintColor)),
            Row(children: [
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.green, size: 14),
              const SizedBox(width: 4),
              Text('$_score correct',
                  style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: context.subColor))
            ]),
          ]),
          const SizedBox(height: 10),
          const Center(child: _BannerAdWidget()),
          const Spacer(),
          AnimatedBuilder(
              animation: _shakeAnim,
              builder: (context, child) {
                final shake = sin(_shakeAnim.value * pi * 6) * 8;
                return Transform.translate(
                    offset: Offset(answered && !correct ? shake : 0, 0),
                    child: child);
              },
              child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                      color: answered
                          ? (correct
                              ? AppColors.green.withValues(alpha: 0.1)
                              : AppColors.red.withValues(alpha: 0.1))
                          : context.cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: answered
                              ? (correct
                                  ? AppColors.green.withValues(alpha: 0.4)
                                  : AppColors.red.withValues(alpha: 0.4))
                              : context.border2Color,
                          width: answered ? 2 : 1),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black
                                .withValues(alpha: context.isDark ? 0.2 : 0.06),
                            blurRadius: 16,
                            offset: const Offset(0, 4))
                      ]),
                  child: Column(children: [
                    Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                            color: AppColors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(999)),
                        child: Text('HEADLINE',
                            style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppColors.blue,
                                letterSpacing: 2))),
                    const SizedBox(height: 16),
                    Text(headline,
                        style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: context.textColor,
                            height: 1.5,
                            letterSpacing: -0.3),
                        textAlign: TextAlign.center),
                    if (answered) ...[
                      const SizedBox(height: 16),
                      Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: (correct ? AppColors.green : AppColors.red)
                                  .withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12)),
                          child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                    correct
                                        ? Icons.check_circle_rounded
                                        : Icons.cancel_rounded,
                                    color: correct
                                        ? AppColors.green
                                        : AppColors.red,
                                    size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      Text(
                                          correct
                                              ? 'Correct!'
                                              : 'This headline is ${isReal ? "REAL" : "FAKE"}',
                                          style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                              color: correct
                                                  ? AppColors.green
                                                  : AppColors.red)),
                                      const SizedBox(height: 3),
                                      Text(explanation,
                                          style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              color: context.subColor,
                                              height: 1.5)),
                                    ])),
                              ])),
                    ],
                  ]))),
          const Spacer(),
          if (!answered)
            Text('Is this headline real or fake?',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: context.hintColor)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
                child: _VoteBtn(
                    label: 'REAL',
                    icon: Icons.check_rounded,
                    color: AppColors.green,
                    state: answered
                        ? (_tapped == 'real'
                            ? (isReal ? 'correct' : 'wrong')
                            : (isReal ? 'reveal' : 'dim'))
                        : 'idle',
                    onTap: () => _answer(true))),
            const SizedBox(width: 12),
            Expanded(
                child: _VoteBtn(
                    label: 'FAKE',
                    icon: Icons.close_rounded,
                    color: AppColors.red,
                    state: answered
                        ? (_tapped == 'fake'
                            ? (!isReal ? 'correct' : 'wrong')
                            : (!isReal ? 'reveal' : 'dim'))
                        : 'idle',
                    onTap: () => _answer(false))),
          ]),
          const SizedBox(height: 8),
        ]));
  }

  Widget _buildResult() {
    final pct = (_score / _rounds * 100).round();
    final emoji = _score >= 9
        ? '🏆'
        : _score >= 7
            ? '🔥'
            : _score >= 5
                ? '👏'
                : '💪';
    final label = _score >= 9
        ? 'Unbeatable!'
        : _score >= 7
            ? 'Sharp Eye!'
            : _score >= 5
                ? 'Not Bad!'
                : 'Keep Practising';
    final color = _score >= 7
        ? AppColors.green
        : _score >= 5
            ? AppColors.gold
            : AppColors.orange;
    return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          const Spacer(),
          Text(emoji, style: const TextStyle(fontSize: 60)),
          const SizedBox(height: 10),
          Text(label.toUpperCase(),
              style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 2)),
          const SizedBox(height: 8),
          RichText(
              text: TextSpan(children: [
            TextSpan(
                text: '$_score',
                style: GoogleFonts.poppins(
                    fontSize: 88,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -4,
                    foreground: Paint()
                      ..shader = LinearGradient(
                              colors: [color, color.withValues(alpha: 0.6)])
                          .createShader(const Rect.fromLTWH(0, 0, 100, 100)))),
            TextSpan(
                text: '/$_rounds',
                style: GoogleFonts.poppins(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: color.withValues(alpha: 0.7))),
          ])),
          const SizedBox(height: 6),
          Text('$pct% correct',
              style:
                  GoogleFonts.poppins(fontSize: 13, color: context.subColor)),
          const Spacer(),
          const Center(child: _BannerAdWidget()),
          const SizedBox(height: 12),
          AccentButton(
              text: 'Play Again', onTap: _restart, icon: Icons.refresh_rounded),
          const SizedBox(height: 10),
          OutlineButton(
              text: 'Share Score',
              onTap: () => Share.share(
                  'I scored $_score/$_rounds on Real or Fake? on Briefed! $emoji\n#Briefed #RealOrFake'),
              icon: Icons.share_rounded),
          const SizedBox(height: 10),
          OutlineButton(text: 'Back', onTap: () => Navigator.of(context).pop()),
        ]));
  }
}

class _VoteBtn extends StatelessWidget {
  final String label, state;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _VoteBtn(
      {required this.label,
      required this.icon,
      required this.color,
      required this.state,
      required this.onTap});
  @override
  Widget build(BuildContext context) {
    final isCorrect = state == 'correct';
    final isWrong = state == 'wrong';
    final isReveal = state == 'reveal';
    final isDim = state == 'dim';
    final isIdle = state == 'idle';
    Color bg = context.cardColor;
    Color border = context.border2Color;
    Color tc = context.subColor;
    double op = 1.0;
    if (isCorrect) {
      bg = color.withValues(alpha: 0.12);
      border = color.withValues(alpha: 0.5);
      tc = color;
    } else if (isWrong) {
      bg = AppColors.red.withValues(alpha: 0.1);
      border = AppColors.red.withValues(alpha: 0.4);
      tc = AppColors.red;
    } else if (isReveal) {
      bg = color.withValues(alpha: 0.06);
      border = color.withValues(alpha: 0.25);
      tc = color;
    } else if (isDim) {
      op = 0.35;
    }
    return GestureDetector(
        onTap: isIdle ? onTap : null,
        child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: op,
            child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: border, width: isCorrect || isWrong ? 2 : 1),
                    boxShadow: isIdle
                        ? [
                            BoxShadow(
                                color: Colors.black.withValues(
                                    alpha: context.isDark ? 0.15 : 0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 3))
                          ]
                        : []),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                      isCorrect
                          ? Icons.check_circle_rounded
                          : isWrong
                              ? Icons.cancel_rounded
                              : icon,
                      color: tc,
                      size: 28),
                  const SizedBox(height: 8),
                  Text(label,
                      style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: tc)),
                ]))));
  }
}

// OLDEST TO LATEST GAME

class OldestToLatestGame extends StatefulWidget {
  const OldestToLatestGame({super.key});
  @override
  State<OldestToLatestGame> createState() => _OldestToLatestGameState();
}

class _OldestToLatestGameState extends State<OldestToLatestGame> {
  late List<Map<String, dynamic>> _round, _order;
  bool _submitted = false, _finished = false;
  int _score = 0, _roundNum = 1;
  static const int _totalRounds = 5;

  @override
  void initState() {
    super.initState();
    _newRound();
  }

  void _newRound() {
    final all = List<Map<String, dynamic>>.from(_OldestToLatestData.events)
      ..shuffle();
    _round = all.take(4).toList();
    _order = List.from(_round)..shuffle();
    _submitted = false;
  }

  List<Map<String, dynamic>> get _correctOrder => List.from(_round)
    ..sort((a, b) => (a['year'] as int).compareTo(b['year'] as int));
  bool get _isCorrect {
    final c = _correctOrder;
    for (int i = 0; i < _order.length; i++) {
      if (_order[i]['year'] != c[i]['year']) return false;
    }
    return true;
  }

  void _submit() {
    setState(() {
      _submitted = true;
      if (_isCorrect) _score++;
    });
  }

  void _next() {
    if (_roundNum >= _totalRounds) {
      AdService.showInterstitial(then: () {
        if (mounted) setState(() => _finished = true);
      });
    } else {
      setState(() {
        _roundNum++;
        _newRound();
      });
    }
  }

  void _restart() {
    setState(() {
      _score = 0;
      _roundNum = 1;
      _finished = false;
      _newRound();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: context.bgColor,
        appBar: AppBar(
            title: Text('Oldest to Latest',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w800)),
            centerTitle: true,
            leading: BackButton(color: context.subColor),
            actions: [
              Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Center(
                      child: Text('$_roundNum/$_totalRounds',
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: context.subColor))))
            ]),
        body: _finished ? _buildResult() : _buildGame());
  }

  Widget _buildGame() {
    return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                  value: (_roundNum - 1) / _totalRounds,
                  minHeight: 4,
                  backgroundColor: context.inputBg,
                  valueColor: const AlwaysStoppedAnimation(AppColors.purple))),
          const SizedBox(height: 16),
          Text('Round $_roundNum of $_totalRounds',
              style:
                  GoogleFonts.poppins(fontSize: 10, color: context.hintColor)),
          const SizedBox(height: 4),
          Text(
              _submitted
                  ? (_isCorrect
                      ? 'Correct order! 🎉'
                      : 'Not quite — here\'s the right order:')
                  : 'Sort oldest → most recent',
              style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _submitted
                      ? (_isCorrect ? AppColors.green : AppColors.red)
                      : context.textColor)),
          if (!_submitted) ...[
            const SizedBox(height: 4),
            Text('Drag to reorder the events by when they happened',
                style:
                    GoogleFonts.poppins(fontSize: 12, color: context.subColor))
          ],
          const SizedBox(height: 12),
          const Center(child: _BannerAdWidget()),
          const SizedBox(height: 12),
          Expanded(
              child: _submitted
                  ? _buildReveal()
                  : ReorderableListView.builder(
                      itemCount: _order.length,
                      onReorder: (oldIdx, newIdx) {
                        setState(() {
                          if (newIdx > oldIdx) newIdx--;
                          final item = _order.removeAt(oldIdx);
                          _order.insert(newIdx, item);
                        });
                      },
                      itemBuilder: (context, i) => _EventCard(
                          key: ValueKey(_order[i]['event']),
                          index: i,
                          event: _order[i]['event'] as String,
                          showYear: false,
                          color: AppColors.purple),
                      proxyDecorator: (child, index, animation) =>
                          Material(color: Colors.transparent, child: child))),
          const SizedBox(height: 16),
          if (!_submitted)
            AccentButton(
                text: 'Submit Order', onTap: _submit, icon: Icons.check_rounded)
          else
            AccentButton(
                text: _roundNum >= _totalRounds ? 'See Results' : 'Next Round',
                onTap: _next,
                icon: Icons.arrow_forward_rounded),
        ]));
  }

  Widget _buildReveal() {
    final correct = _correctOrder;
    return ListView.builder(
        itemCount: 4,
        itemBuilder: (context, i) {
          final correctEvent = correct[i];
          final isRight = _order[i]['year'] == correctEvent['year'];
          return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _EventCard(
                  key: ValueKey('reveal_$i'),
                  index: i,
                  event: correctEvent['event'] as String,
                  year: correctEvent['year'] as int,
                  detail: correctEvent['detail'] as String,
                  showYear: true,
                  color: isRight ? AppColors.green : AppColors.red,
                  isCorrect: isRight));
        });
  }

  Widget _buildResult() {
    final pct = (_score / _totalRounds * 100).round();
    final emoji = _score >= 5
        ? '🏆'
        : _score >= 4
            ? '🔥'
            : _score >= 3
                ? '👏'
                : '💪';
    final label = _score >= 5
        ? 'History Expert!'
        : _score >= 3
            ? 'Sharp Mind!'
            : 'Keep Learning!';
    final color = _score >= 4
        ? AppColors.green
        : _score >= 3
            ? AppColors.gold
            : AppColors.orange;
    return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          const Spacer(),
          Text(emoji, style: const TextStyle(fontSize: 60)),
          const SizedBox(height: 10),
          Text(label.toUpperCase(),
              style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 2)),
          const SizedBox(height: 8),
          RichText(
              text: TextSpan(children: [
            TextSpan(
                text: '$_score',
                style: GoogleFonts.poppins(
                    fontSize: 88,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -4,
                    foreground: Paint()
                      ..shader = LinearGradient(
                              colors: [color, color.withValues(alpha: 0.6)])
                          .createShader(const Rect.fromLTWH(0, 0, 100, 100)))),
            TextSpan(
                text: '/$_totalRounds',
                style: GoogleFonts.poppins(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: color.withValues(alpha: 0.7))),
          ])),
          const SizedBox(height: 6),
          Text('$pct% rounds correct',
              style:
                  GoogleFonts.poppins(fontSize: 13, color: context.subColor)),
          const Spacer(),
          const Center(child: _BannerAdWidget()),
          const SizedBox(height: 12),
          AccentButton(
              text: 'Play Again', onTap: _restart, icon: Icons.refresh_rounded),
          const SizedBox(height: 10),
          OutlineButton(
              text: 'Share Score',
              onTap: () => Share.share(
                  'I scored $_score/$_totalRounds on Oldest to Latest on Briefed! $emoji\n#Briefed #NewsQuiz'),
              icon: Icons.share_rounded),
          const SizedBox(height: 10),
          OutlineButton(text: 'Back', onTap: () => Navigator.of(context).pop()),
        ]));
  }
}

class _EventCard extends StatelessWidget {
  final int index;
  final String event;
  final int? year;
  final String? detail;
  final bool showYear;
  final Color color;
  final bool? isCorrect;
  const _EventCard(
      {super.key,
      required this.index,
      required this.event,
      required this.showYear,
      required this.color,
      this.year,
      this.detail,
      this.isCorrect});
  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: isCorrect == null
                ? context.cardColor
                : (isCorrect!
                    ? AppColors.green.withValues(alpha: 0.08)
                    : AppColors.red.withValues(alpha: 0.08)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isCorrect == null
                    ? context.border2Color
                    : (isCorrect!
                        ? AppColors.green.withValues(alpha: 0.4)
                        : AppColors.red.withValues(alpha: 0.4))),
            boxShadow: [
              BoxShadow(
                  color: Colors.black
                      .withValues(alpha: context.isDark ? 0.15 : 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2))
            ]),
        child: Row(children: [
          Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                  color: isCorrect == null
                      ? color.withValues(alpha: 0.12)
                      : (isCorrect!
                          ? AppColors.green.withValues(alpha: 0.15)
                          : AppColors.red.withValues(alpha: 0.15)),
                  borderRadius: BorderRadius.circular(10)),
              child: Center(
                  child: isCorrect == null
                      ? Text('${index + 1}',
                          style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: color))
                      : Icon(
                          isCorrect!
                              ? Icons.check_rounded
                              : Icons.close_rounded,
                          color: isCorrect! ? AppColors.green : AppColors.red,
                          size: 18))),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(event,
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: context.textColor,
                        height: 1.4)),
                if (showYear && year != null) ...[
                  const SizedBox(height: 3),
                  Text(detail ?? '$year',
                      style: GoogleFonts.poppins(
                          fontSize: 10, color: context.hintColor))
                ],
              ])),
          if (!showYear)
            Icon(Icons.drag_handle_rounded, color: context.hintColor, size: 20),
          if (showYear && year != null && isCorrect != null)
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: (isCorrect! ? AppColors.green : AppColors.red)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999)),
                child: Text('$year',
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isCorrect! ? AppColors.green : AppColors.red))),
        ]));
  }
}

// QUIZ SCREEN

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key});
  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _tickPlayer = AudioPlayer();
  Timer? _musicTimer;
  bool _isMusicPlaying = false;
  int _musicStep = 0;
  int? _lastTickSecond;
  int? _lastTickQuestionIndex;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      _start(
        forceRefresh: args?['forceRefresh'] == true,
        bonusRound: args?['bonusRound'] == true,
      );
    });
  }

  @override
  void dispose() {
    _musicTimer?.cancel();
    unawaited(_musicPlayer.stop());
    unawaited(_musicPlayer.dispose());
    unawaited(_tickPlayer.stop());
    unawaited(_tickPlayer.dispose());
    super.dispose();
  }

  Future<void> _start({
    bool forceRefresh = false,
    bool bonusRound = false,
  }) async {
    final news = ref.read(newsProvider);
    await ref.read(quizProvider.notifier).startQuiz(
          news.articles,
          forceRefresh: forceRefresh,
          bonusRound: bonusRound,
        );
  }

  void _syncQuizAudio(QuizState quiz) {
    final hasQuestion =
        quiz.questions.isNotEmpty && quiz.currentQuestion != null;
    final isActive = quiz.status == QuizStatus.active && hasQuestion;
    final shouldTick = isActive && quiz.currentAnswer == null;

    if (isActive) {
      unawaited(_startQuizMusic());
    } else {
      unawaited(_stopQuizMusic());
      _lastTickSecond = null;
      _lastTickQuestionIndex = null;
    }

    if (!shouldTick) {
      _lastTickSecond = null;
      _lastTickQuestionIndex = quiz.currentIndex;
      return;
    }

    final isNewQuestion = _lastTickQuestionIndex != quiz.currentIndex;
    final isNewSecond = _lastTickSecond != quiz.timeLeft;
    if ((isNewQuestion || isNewSecond) && quiz.timeLeft > 0) {
      _lastTickQuestionIndex = quiz.currentIndex;
      _lastTickSecond = quiz.timeLeft;
      unawaited(_playQuizTick(isUrgent: quiz.timeLeft <= 5));
    }
  }

  Future<void> _startQuizMusic() async {
    if (_isMusicPlaying) return;
    _isMusicPlaying = true;
    _musicStep = 0;
    await _playMusicPulse();
    _musicTimer = Timer.periodic(const Duration(milliseconds: 680), (_) {
      unawaited(_playMusicPulse());
    });
  }

  Future<void> _stopQuizMusic() async {
    if (!_isMusicPlaying) return;
    _isMusicPlaying = false;
    _musicTimer?.cancel();
    _musicTimer = null;
    await _musicPlayer.stop();
  }

  Future<void> _playMusicPulse() async {
    if (!_isMusicPlaying) return;
    const notes = [196, 247, 330, 247, 175, 220, 294, 220];
    final frequency = notes[_musicStep % notes.length];
    _musicStep++;
    try {
      await _musicPlayer.stop();
      await _musicPlayer.setReleaseMode(ReleaseMode.stop);
      await _musicPlayer.setVolume(0.32);
      await _musicPlayer.play(BytesSource(_makeMusicPulse(frequency)));
    } catch (_) {
      // Keep quiz play independent from device audio availability.
    }
  }

  Future<void> _playQuizTick({required bool isUrgent}) async {
    try {
      await _tickPlayer.stop();
      await _tickPlayer.setVolume(isUrgent ? 0.22 : 0.14);
      await _tickPlayer.play(BytesSource(_makeTickSound(isUrgent: isUrgent)));
    } catch (_) {
      // Audio should never block quiz play.
    }
  }

  @override
  Widget build(BuildContext context) {
    final quiz = ref.watch(quizProvider);
    _syncQuizAudio(quiz);
    if (quiz.status == QuizStatus.finished) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted)
          AdService.showInterstitial(then: () {
            if (mounted) Navigator.of(context).pushReplacementNamed('/result');
          });
      });
    }
    return Scaffold(
        backgroundColor: context.bgColor,
        body: SafeArea(child: _buildBody(quiz)));
  }

  Widget _buildBody(QuizState quiz) {
    switch (quiz.status) {
      case QuizStatus.loading:
        return _buildLoading();
      case QuizStatus.error:
        return _buildError(quiz.errorMessage ?? 'Unknown error');
      default:
        if (quiz.questions.isEmpty) return _buildLoading();
        return _buildQuiz(quiz);
    }
  }

  Widget _buildLoading() => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(18)),
            child: const Icon(Icons.newspaper_rounded,
                color: AppColors.accent, size: 30)),
        const SizedBox(height: 16),
        Text('Generating today\'s quiz...',
            style: GoogleFonts.poppins(fontSize: 14, color: context.subColor)),
        const SizedBox(height: 8),
        Text('Powered by AI',
            style: GoogleFonts.poppins(fontSize: 11, color: context.hintColor)),
        const SizedBox(height: 20),
        const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(AppColors.accent))),
      ]));
  Widget _buildError(String msg) => Center(
      child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.red, size: 48),
            const SizedBox(height: 16),
            Text('Quiz failed to load',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: AppColors.red.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.red.withValues(alpha: 0.2))),
                child: Text(msg,
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: context.subColor, height: 1.6))),
            const SizedBox(height: 20),
            AccentButton(
                text: 'Retry (fresh)',
                onTap: () => _start(forceRefresh: true),
                icon: Icons.refresh_rounded),
            const SizedBox(height: 10),
            OutlineButton(
                text: 'Use offline questions',
                onTap: () {
                  final mockQs = GeminiService.mockQuestions();
                  ref.read(quizProvider.notifier).loadMock(mockQs);
                }),
          ])));
  Widget _buildQuiz(QuizState quiz) {
    final q = quiz.currentQuestion!;
    final sel = quiz.currentAnswer;
    final revealed = sel != null;
    return Column(children: [
      Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Row(children: [
            GestureDetector(
                onTap: () {
                  ref.read(quizProvider.notifier).reset();
                  Navigator.of(context).pop();
                },
                child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                        color: context.cardColor,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: context.borderColor)),
                    child: Icon(Icons.arrow_back_rounded,
                        color: context.subColor, size: 18))),
            const Spacer(),
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                    color: (q.isEasy ? AppColors.green : AppColors.orange)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                        color: (q.isEasy ? AppColors.green : AppColors.orange)
                            .withValues(alpha: 0.35))),
                child: Text(
                    q.difficulty[0].toUpperCase() + q.difficulty.substring(1),
                    style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: q.isEasy ? AppColors.green : AppColors.orange))),
          ])),
      Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                  value: quiz.currentIndex / quiz.questions.length,
                  minHeight: 4,
                  backgroundColor: context.inputBg,
                  valueColor: const AlwaysStoppedAnimation(AppColors.accent)))),
      Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: _QuizTimerBar(
              timeLeft: quiz.timeLeft,
              totalTime: AppConstants.timerSeconds,
              answered: revealed)),
      Expanded(
          child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Row(children: [
                      CategoryTag(category: q.category),
                      const SizedBox(width: 10),
                      Text(
                          '${quiz.currentIndex + 1} of ${quiz.questions.length}',
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: context.hintColor))
                    ]),
                    const SizedBox(height: 16),
                    Text(q.question,
                        style: GoogleFonts.poppins(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: context.textColor,
                            letterSpacing: -0.4,
                            height: 1.4)),
                    const SizedBox(height: 24),
                    ...q.options.asMap().entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: OptionButton(
                            text: e.value,
                            index: e.key,
                            isSelected: sel == e.key,
                            isCorrect: e.key == q.correctIndex,
                            isRevealed: revealed,
                            onTap: () => ref
                                .read(quizProvider.notifier)
                                .answerQuestion(e.key)))),
                    if (revealed) ...[
                      const SizedBox(height: 6),
                      Container(
                          decoration: BoxDecoration(
                              color: context.cardColor,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: context.borderColor),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withValues(
                                        alpha: context.isDark ? 0.2 : 0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2))
                              ]),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                        color: AppColors.accent
                                            .withValues(alpha: 0.06),
                                        borderRadius:
                                            const BorderRadius.vertical(
                                                top: Radius.circular(18))),
                                    child: Row(children: [
                                      const Icon(Icons.newspaper_rounded,
                                          color: AppColors.accent, size: 15),
                                      const SizedBox(width: 8),
                                      Text('STORY BEHIND THIS',
                                          style: GoogleFonts.poppins(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.accent,
                                              letterSpacing: 1.5))
                                    ])),
                                Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(q.storySummary,
                                              style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  color: context.subColor,
                                                  height: 1.7)),
                                          const SizedBox(height: 8),
                                          Row(children: [
                                            Text(q.source,
                                                style: GoogleFonts.poppins(
                                                    fontSize: 10,
                                                    color: context.hintColor)),
                                            Text(' · ',
                                                style: TextStyle(
                                                    color: context.hintColor,
                                                    fontSize: 10)),
                                            Text('Read full story',
                                                style: GoogleFonts.poppins(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.accent))
                                          ]),
                                        ])),
                              ])),
                      const SizedBox(height: 8),
                    ],
                  ]))),
      if (revealed)
        Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: AccentButton(
                text: quiz.currentIndex + 1 >= quiz.questions.length
                    ? 'See My Results'
                    : 'Next Question',
                onTap: () => ref.read(quizProvider.notifier).nextQuestion(),
                icon: quiz.currentIndex + 1 >= quiz.questions.length
                    ? Icons.emoji_events_rounded
                    : Icons.arrow_forward_rounded)),
    ]);
  }
}

class _QuizTimerBar extends StatelessWidget {
  final int timeLeft;
  final int totalTime;
  final bool answered;

  const _QuizTimerBar(
      {required this.timeLeft,
      required this.totalTime,
      required this.answered});

  Color _color(BuildContext context) {
    if (answered) return AppColors.green;
    if (timeLeft > totalTime * 0.5) return AppColors.green;
    if (timeLeft > totalTime * 0.25) return AppColors.gold;
    return AppColors.red;
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    final progress = answered ? 1.0 : (timeLeft / totalTime).clamp(0.0, 1.0);
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOut,
                widthFactor: progress,
                heightFactor: 1,
                child: Container(color: color.withValues(alpha: 0.14)),
              ),
            ),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                      answered
                          ? Icons.check_circle_rounded
                          : Icons.timer_rounded,
                      color: color,
                      size: 15),
                  const SizedBox(width: 7),
                  Text(
                    answered ? 'Answered' : '$timeLeft',
                    style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: color),
                  ),
                  if (!answered) ...[
                    const SizedBox(width: 2),
                    Text('sec',
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: color.withValues(alpha: 0.8))),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// RESULT SCREEN

final Map<int, Uint8List> _musicPulseCache = {};
Uint8List? _softTickCache;
Uint8List? _urgentTickCache;

Uint8List _makeWav({
  required int sampleRate,
  required int numSamples,
  required int Function(int sampleIndex) sampleAt,
}) {
  final dataSize = numSamples * 2;
  final bytes = ByteData(44 + dataSize);
  for (final e in {0: 0x52, 1: 0x49, 2: 0x46, 3: 0x46}.entries) {
    bytes.setUint8(e.key, e.value);
  }
  bytes.setUint32(4, 36 + dataSize, Endian.little);
  for (final e in {
    8: 0x57,
    9: 0x41,
    10: 0x56,
    11: 0x45,
    12: 0x66,
    13: 0x6D,
    14: 0x74,
    15: 0x20
  }.entries) {
    bytes.setUint8(e.key, e.value);
  }
  bytes.setUint32(16, 16, Endian.little);
  bytes.setUint16(20, 1, Endian.little);
  bytes.setUint16(22, 1, Endian.little);
  bytes.setUint32(24, sampleRate, Endian.little);
  bytes.setUint32(28, sampleRate * 2, Endian.little);
  bytes.setUint16(32, 2, Endian.little);
  bytes.setUint16(34, 16, Endian.little);
  for (final e in {36: 0x64, 37: 0x61, 38: 0x74, 39: 0x61}.entries) {
    bytes.setUint8(e.key, e.value);
  }
  bytes.setUint32(40, dataSize, Endian.little);
  for (int i = 0; i < numSamples; i++) {
    bytes.setInt16(44 + i * 2, sampleAt(i).clamp(-32768, 32767), Endian.little);
  }
  return bytes.buffer.asUint8List();
}

Uint8List _makeMusicPulse(int frequency) {
  final cached = _musicPulseCache[frequency];
  if (cached != null) return cached;
  const sampleRate = 22050;
  const durationSeconds = 0.46;
  final numSamples = (sampleRate * durationSeconds).round();

  final pulse = _makeWav(
    sampleRate: sampleRate,
    numSamples: numSamples,
    sampleAt: (i) {
      final t = i / sampleRate;
      final progress = i / numSamples;
      final attack = (progress / 0.12).clamp(0.0, 1.0);
      final release = pow(1 - progress, 1.8).toDouble();
      final envelope = attack * release;
      final base = frequency.toDouble();
      final value = (sin(2 * pi * base * t) * 0.38) +
          (sin(2 * pi * base * 1.5 * t) * 0.08) +
          (sin(2 * pi * base * 2.0 * t) * 0.06);

      return (value * 32767 * envelope).round();
    },
  );
  _musicPulseCache[frequency] = pulse;
  return pulse;
}

Uint8List _makeTickSound({required bool isUrgent}) {
  final cached = isUrgent ? _urgentTickCache : _softTickCache;
  if (cached != null) return cached;

  const sampleRate = 22050;
  final durationSeconds = isUrgent ? 0.085 : 0.055;
  final numSamples = (sampleRate * durationSeconds).round();
  final frequency = isUrgent ? 1200 : 880;
  final amplitude = isUrgent ? 0.35 : 0.22;

  final tick = _makeWav(
    sampleRate: sampleRate,
    numSamples: numSamples,
    sampleAt: (i) {
      final t = i / sampleRate;
      final envelope = pow(1 - (i / numSamples), 3).toDouble();
      final click = sin(2 * pi * frequency * t) +
          (0.35 * sin(2 * pi * frequency * 1.5 * t));
      return (click * 32767 * amplitude * envelope).round();
    },
  );

  if (isUrgent) {
    _urgentTickCache = tick;
  } else {
    _softTickCache = tick;
  }
  return tick;
}

// Generates a raw PCM WAV tone — no asset files required
Uint8List _makeBeep(int frequency, double durationSeconds,
    {double amplitude = 0.4}) {
  const sampleRate = 22050;
  final numSamples = (sampleRate * durationSeconds).round();
  return _makeWav(
      sampleRate: sampleRate,
      numSamples: numSamples,
      sampleAt: (i) {
        final fade = i > numSamples * 0.8
            ? 1.0 - (i - numSamples * 0.8) / (numSamples * 0.2)
            : 1.0;
        final sample = (sin(2 * pi * frequency * i / sampleRate) *
                32767 *
                amplitude *
                fade)
            .round()
            .clamp(-32768, 32767);
        return sample;
      });
}

Future<void> _playNote(int freq, double dur) async {
  final p = AudioPlayer();
  await p.play(BytesSource(_makeBeep(freq, dur)));
  await Future.delayed(Duration(milliseconds: (dur * 1000).round() + 40));
  await p.dispose();
}

Future<void> _playResultSound(int score, int total) async {
  if (score == total) {
    // Perfect: triumphant ascending chord
    await _playNote(523, 0.10);
    await _playNote(659, 0.10);
    await _playNote(784, 0.10);
    await _playNote(1047, 0.30);
  } else if (score >= (total * 0.8).ceil()) {
    // Great: two rising notes
    await _playNote(659, 0.10);
    await _playNote(880, 0.25);
  } else if (score >= 3) {
    // OK: single positive note
    await _playNote(523, 0.22);
  } else {
    // Poor: low descending notes
    await _playNote(330, 0.12);
    await _playNote(220, 0.30);
  }
}

class ResultScreen extends ConsumerStatefulWidget {
  const ResultScreen({super.key});
  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen>
    with TickerProviderStateMixin {
  late ConfettiController _confetti;
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;
  final ScreenshotController _screenshotCtrl = ScreenshotController();
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 4));
    _scaleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _scaleAnim = CurvedAnimation(parent: _scaleCtrl, curve: Curves.elasticOut);
    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -5.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -5.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));
    _scaleCtrl.forward();
    _saveResult();
  }

  Future<void> _saveResult() async {
    if (_saved) return;
    _saved = true;
    final quiz = ref.read(quizProvider);
    final result = quiz.buildResult();
    await ref.read(userProvider.notifier).afterQuiz(result);
    final score = quiz.score;
    final total = quiz.questions.length;
    unawaited(_playResultSound(score, total));
    if (score == total) {
      _confetti.play();
      HapticFeedback.heavyImpact();
      Future.delayed(
          const Duration(milliseconds: 200), HapticFeedback.heavyImpact);
      Future.delayed(
          const Duration(milliseconds: 400), HapticFeedback.heavyImpact);
    } else if (score >= total * 0.8) {
      _confetti.play();
      HapticFeedback.heavyImpact();
      Future.delayed(
          const Duration(milliseconds: 250), HapticFeedback.lightImpact);
    } else if (score >= 3) {
      _confetti.play();
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.vibrate();
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) _shakeCtrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _confetti.dispose();
    _scaleCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  Color _scoreColor(int score, int total) {
    if (score == total || score >= total * 0.8) return AppColors.green;
    if (score >= total * 0.6) return AppColors.gold;
    if (score >= total * 0.4) return AppColors.orange;
    return AppColors.red;
  }

  @override
  Widget build(BuildContext context) {
    final quiz = ref.watch(quizProvider);
    final user = ref.watch(userProvider);
    final score = quiz.score;
    final total = quiz.questions.length;
    final result = quiz.buildResult();
    final sc = _scoreColor(score, total);
    final bgColor = context.isDark
        ? context.bgColor
        : score >= total * 0.8
            ? const Color(0xFFE8FFF0)
            : score >= total * 0.6
                ? const Color(0xFFFFF8E8)
                : context.bgColor;
    return Scaffold(
        backgroundColor: bgColor,
        body: Stack(children: [
          Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                  confettiController: _confetti,
                  blastDirection: pi / 2,
                  emissionFrequency: score == total ? 0.08 : 0.05,
                  numberOfParticles: score == total
                      ? 30
                      : score >= total * 0.8
                          ? 20
                          : 12,
                  maxBlastForce: 20,
                  minBlastForce: 8,
                  gravity: 0.2,
                  colors: const [
                    AppColors.accent,
                    AppColors.green,
                    AppColors.gold,
                    AppColors.blue,
                    AppColors.purple
                  ])),
          SafeArea(
              child: Column(children: [
            Expanded(
                child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                    child: Column(children: [
                      const SizedBox(height: 2),
                      AnimatedBuilder(
                          animation: _shakeAnim,
                          builder: (_, child) => Transform.translate(
                              offset: Offset(_shakeAnim.value, 0),
                              child: child),
                          child: ScaleTransition(
                              scale: _scaleAnim,
                              child: Column(children: [
                                Text(result.performanceEmoji,
                                    style: const TextStyle(fontSize: 46)),
                                const SizedBox(height: 2),
                                Text(result.performanceLabel.toUpperCase(),
                                    style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: sc,
                                        letterSpacing: 2.5)),
                                const SizedBox(height: 2),
                                TweenAnimationBuilder<int>(
                                  tween: IntTween(begin: 0, end: score),
                                  duration: const Duration(milliseconds: 900),
                                  curve: Curves.easeOut,
                                  builder: (_, v, __) => RichText(
                                      text: TextSpan(children: [
                                    TextSpan(
                                        text: '$v',
                                        style: GoogleFonts.poppins(
                                            fontSize: 86,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: -5,
                                            foreground: Paint()
                                              ..shader = LinearGradient(
                                                  colors: [
                                                    sc,
                                                    sc.withValues(alpha: 0.6)
                                                  ]).createShader(
                                                  const Rect.fromLTWH(
                                                      0, 0, 100, 100)))),
                                    TextSpan(
                                        text: '/$total',
                                        style: GoogleFonts.poppins(
                                            fontSize: 36,
                                            fontWeight: FontWeight.w800,
                                            color: sc.withValues(alpha: 0.8))),
                                  ])),
                                ),
                                Container(
                                    width: 200,
                                    height: 10,
                                    decoration: BoxDecoration(
                                        color: Colors.black
                                            .withValues(alpha: 0.08),
                                        borderRadius:
                                            BorderRadius.circular(999)),
                                    child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        child: LinearProgressIndicator(
                                            value: score / total,
                                            backgroundColor: Colors.transparent,
                                            valueColor:
                                                AlwaysStoppedAnimation(sc)))),
                                const SizedBox(height: 6),
                                Text('${result.percentageString} correct',
                                    style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black.withValues(
                                            alpha:
                                                context.isDark ? 0.4 : 0.35))),
                              ]))),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(
                            child: StatCard(
                                icon: Icons.local_fire_department_rounded,
                                value: '${user.streak}',
                                label: 'Streak',
                                color: AppColors.accent)),
                        const SizedBox(width: 10),
                        Expanded(
                            child: StatCard(
                                icon: Icons.bolt_rounded,
                                value: '+${result.pointsEarned}',
                                label: 'Points',
                                color: AppColors.gold)),
                        const SizedBox(width: 10),
                        Expanded(
                            child: StatCard(
                                icon: Icons.emoji_events_rounded,
                                value: user.globalRankLabel,
                                label: 'Global',
                                color: AppColors.purple)),
                      ]),
                      const SizedBox(height: 14),
                      Screenshot(
                          controller: _screenshotCtrl,
                          child: _ShareCard(
                              score: score, total: total, result: result)),
                      const SizedBox(height: 10),
                      AccentButton(
                          text: 'Share Your Result',
                          onTap: _share,
                          icon: Icons.share_rounded),
                      const SizedBox(height: 10),
                      GestureDetector(
                          onTap: () =>
                              Navigator.of(context).pushNamed('/hot-take'),
                          child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                  color:
                                      AppColors.purple.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: AppColors.purple
                                          .withValues(alpha: 0.25))),
                              child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                        Icons.local_fire_department_rounded,
                                        color: AppColors.purple,
                                        size: 16),
                                    const SizedBox(width: 8),
                                    Text("Today's Hot Take",
                                        style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.purple)),
                                  ]))),
                      const SizedBox(height: 8),
                    ]))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
              child: OutlineButton(
                  text: 'Want to Play More Games?',
                  icon: Icons.games_rounded,
                  onTap: () {
                    ref.read(quizProvider.notifier).reset();
                    final nav = Navigator.of(context);
                    final tab = ref.read(selectedTabProvider.notifier);
                    AdService.showInterstitial(then: () {
                      tab.state = 2;
                      nav.pushNamedAndRemoveUntil('/home', (_) => false);
                    });
                  }),
            ),
          ])),
        ]));
  }

  Future<void> _share() async {
    final quiz = ref.read(quizProvider);
    final result = quiz.buildResult();
    await Share.share(
        'I scored ${result.score}/${result.totalQuestions} on Briefed! ${result.performanceEmoji} ${result.performanceLabel}\n#Briefed #StaySharp');
  }
}

class _ShareCard extends StatelessWidget {
  final int score, total;
  final QuizResult result;
  const _ShareCard(
      {required this.score, required this.total, required this.result});
  @override
  Widget build(BuildContext context) {
    return Container(
        decoration:
            BoxDecoration(borderRadius: BorderRadius.circular(22), boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: context.isDark ? 0.3 : 0.1),
              blurRadius: 20,
              offset: const Offset(0, 6))
        ]),
        child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Column(children: [
              Container(
                  padding: const EdgeInsets.all(18),
                  decoration: const BoxDecoration(
                      gradient: LinearGradient(
                          colors: [AppColors.accent, AppColors.accentDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight)),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text('Briefed.',
                              style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white)),
                          const Spacer(),
                          Row(children: [
                            ...List.generate(
                                score,
                                (_) => Container(
                                    width: 8,
                                    height: 8,
                                    margin: const EdgeInsets.only(left: 3),
                                    decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle))),
                            ...List.generate(
                                total - score,
                                (_) => Container(
                                    width: 8,
                                    height: 8,
                                    margin: const EdgeInsets.only(left: 3),
                                    decoration: BoxDecoration(
                                        color:
                                            Colors.white.withValues(alpha: 0.3),
                                        shape: BoxShape.circle))),
                          ]),
                        ]),
                        const SizedBox(height: 10),
                        Text('$score/$total — ${result.performanceLabel}',
                            style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.8)),
                        const SizedBox(height: 4),
                        Text(
                            '${result.pointsEarned} points · ${result.percentageString} correct',
                            style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.75))),
                      ])),
              Container(
                  color: context.cardColor,
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
                  child: Row(children: [
                    Text('#Briefed',
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent)),
                    const SizedBox(width: 8),
                    Text('#StaySharp',
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent)),
                    const Spacer(),
                    Text('briefedapp.com',
                        style: GoogleFonts.poppins(
                            fontSize: 10, color: context.hintColor)),
                  ])),
            ])));
  }
}

// HOT TAKE SCREEN

class HotTakeScreen extends ConsumerWidget {
  const HotTakeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ht = ref.watch(hotTakeProvider);
    return Scaffold(
        backgroundColor: context.bgColor,
        appBar: AppBar(
            title: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.local_fire_department_rounded,
                  color: AppColors.accent, size: 18),
              SizedBox(width: 8),
              Text("Today's Hot Take")
            ]),
            centerTitle: true,
            leading: BackButton(color: context.subColor)),
        body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              const SizedBox(height: 20),
              Text(ht.question,
                  style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: context.textColor,
                      letterSpacing: -0.5,
                      height: 1.4),
                  textAlign: TextAlign.center),
              const SizedBox(height: 36),
              Row(children: [
                Expanded(
                    child: _VoteButton(
                        label: 'YES',
                        icon: Icons.thumb_up_rounded,
                        color: AppColors.green,
                        isVoted: ht.userVote == 'yes',
                        disabled: ht.userVote != null,
                        onTap: () =>
                            ref.read(hotTakeProvider.notifier).vote('yes'))),
                const SizedBox(width: 12),
                Expanded(
                    child: _VoteButton(
                        label: 'NO',
                        icon: Icons.thumb_down_rounded,
                        color: AppColors.red,
                        isVoted: ht.userVote == 'no',
                        disabled: ht.userVote != null,
                        onTap: () =>
                            ref.read(hotTakeProvider.notifier).vote('no'))),
              ]),
              if (ht.userVote != null) ...[
                const SizedBox(height: 28),
                BriefedCard(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Row(children: [
                        const Icon(Icons.bar_chart_rounded,
                            color: AppColors.accent, size: 16),
                        const SizedBox(width: 8),
                        Text('${_fmt(ht.total)} users voted',
                            style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: context.hintColor,
                                letterSpacing: 1.5))
                      ]),
                      const SizedBox(height: 16),
                      _ResultBar(
                          label: 'YES',
                          percent: ht.yesPercent,
                          color: AppColors.green),
                      const SizedBox(height: 12),
                      _ResultBar(
                          label: 'NO',
                          percent: ht.noPercent,
                          color: AppColors.red),
                      const SizedBox(height: 16),
                      AccentButton(
                          text: 'Share This Take',
                          onTap: () {
                            final pct = ht.userVote == 'yes'
                                ? ht.yesPercent
                                : ht.noPercent;
                            Share.share(
                                'I voted ${ht.userVote!.toUpperCase()} — and $pct% of Briefed users agree!\n\n"${ht.question}"\n\n#Briefed #HotTake');
                          },
                          icon: Icons.share_rounded),
                    ])),
              ],
              const Spacer(),
              OutlineButton(
                  text: 'Back to Home',
                  onTap: () => Navigator.of(context)
                      .pushNamedAndRemoveUntil('/home', (_) => false),
                  icon: Icons.home_rounded),
            ])));
  }
}

class _VoteButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isVoted, disabled;
  final VoidCallback onTap;
  const _VoteButton(
      {required this.label,
      required this.icon,
      required this.color,
      required this.isVoted,
      required this.disabled,
      required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: disabled ? null : onTap,
        child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
                color:
                    isVoted ? color.withValues(alpha: 0.1) : context.cardColor,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                    color: isVoted
                        ? color.withValues(alpha: 0.45)
                        : context.borderColor),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black
                          .withValues(alpha: context.isDark ? 0.2 : 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3))
                ]),
            child: Column(children: [
              Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                      color: isVoted
                          ? color.withValues(alpha: 0.2)
                          : context.inputBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: isVoted
                              ? color.withValues(alpha: 0.3)
                              : context.borderColor)),
                  child: Icon(icon,
                      color: isVoted ? color : context.hintColor, size: 26)),
              const SizedBox(height: 10),
              Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: isVoted ? color : context.subColor)),
            ])));
  }
}

class _ResultBar extends StatelessWidget {
  final String label;
  final int percent;
  final Color color;
  const _ResultBar(
      {required this.label, required this.percent, required this.color});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: context.subColor)),
        const Spacer(),
        Text('$percent%',
            style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w900, color: color)),
      ]),
      const SizedBox(height: 6),
      ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: percent / 100),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => LinearProgressIndicator(
                  value: v,
                  minHeight: 10,
                  backgroundColor: context.inputBg,
                  valueColor: AlwaysStoppedAnimation(color)))),
    ]);
  }
}

Widget _buildAvatar(String? photoUrl, double size) {
  final fallback = Container(
    width: size,
    height: size,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
          colors: [AppColors.accent, AppColors.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight),
      shape: BoxShape.circle,
    ),
    child: Icon(Icons.person_rounded, color: Colors.white, size: size * 0.48),
  );
  if (photoUrl == null || photoUrl.isEmpty) return fallback;
  return ClipOval(
    child: Image.network(
      photoUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
      loadingBuilder: (_, child, progress) =>
          progress == null ? child : fallback,
      errorBuilder: (_, __, ___) => fallback,
    ),
  );
}

// PROFILE SCREEN — with leaderboard

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final authUser = ref.watch(authStateProvider).valueOrNull;
    final isGuest = authUser == null || authUser.isAnonymous;
    final leaderboardAsync = ref.watch(leaderboardProvider);
    final streakDays = _buildStreakDays(user);
    final activeDays = streakDays.where((d) => d.result != null).length;
    final results = user.recentResults;

    // Average score
    final avgPct = results.isEmpty
        ? 0.0
        : results.map((r) => r.percentage).reduce((a, b) => a + b) /
            results.length;

    // This-week stats (last 7 calendar days)
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final weekResults = results.where((r) {
      try {
        return DateTime.parse(r.date).isAfter(weekAgo);
      } catch (_) {
        return false;
      }
    }).toList();
    final bestWeekPct = weekResults.isEmpty
        ? 0
        : weekResults
            .map((r) => (r.percentage * 100).round())
            .reduce((a, b) => a > b ? a : b);
    final weekDays = weekResults.map((r) => r.date).toSet().length;

    // Category accuracy (from all results)
    final catMap = <String, List<double>>{};
    for (final r in results) {
      for (final cat in r.categories) {
        catMap.putIfAbsent(cat, () => []).add(r.percentage);
      }
    }
    final catAccuracy = catMap.entries
        .map((e) =>
            MapEntry(e.key, e.value.reduce((a, b) => a + b) / e.value.length))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Sparkline: last 7 results oldest-first
    final sparkValues =
        results.take(7).toList().reversed.map((r) => r.percentage).toList();

    return Scaffold(
        backgroundColor: context.bgColor,
        body: SafeArea(
            child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Header ──────────────────────────────────────────────────────────────
                      Row(children: [
                        _buildAvatar(authUser?.photoURL, 54),
                        const SizedBox(width: 14),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(user.name,
                                  style:
                                      Theme.of(context).textTheme.titleLarge),
                              Text('${user.totalQuizzes} quizzes completed',
                                  style: GoogleFonts.sourceSans3(
                                      fontSize: 11, color: context.hintColor)),
                            ])),
                        GestureDetector(
                            onTap: () =>
                                Navigator.of(context).pushNamed('/settings'),
                            child: BriefedCard(
                                padding: const EdgeInsets.all(9),
                                child: Icon(Icons.settings_rounded,
                                    color: context.hintColor, size: 18))),
                      ]),
                      if (isGuest) ...[
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () =>
                              Navigator.of(context).pushNamed('/settings'),
                          child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                  color: AppColors.blue.withValues(alpha: 0.07),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: AppColors.blue
                                          .withValues(alpha: 0.2))),
                              child: Row(children: [
                                const Icon(Icons.sync_rounded,
                                    color: AppColors.blue, size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: Text(
                                        'Sign in to sync your progress across devices',
                                        style: GoogleFonts.sourceSans3(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.blue))),
                                const Icon(Icons.chevron_right_rounded,
                                    color: AppColors.blue, size: 16),
                              ])),
                        ),
                      ],
                      const SizedBox(height: 20),

                      // ── Stat Cards ───────────────────────────────────────────────────────────
                      Row(children: [
                        Expanded(
                            child: StatCard(
                                icon: Icons.local_fire_department_rounded,
                                value: '${user.streak}',
                                label: 'Streak',
                                color: AppColors.accent)),
                        const SizedBox(width: 10),
                        Expanded(
                            child: StatCard(
                                icon: Icons.bolt_rounded,
                                value: _fmt(user.knowledgeScore),
                                label: 'Score',
                                color: AppColors.gold)),
                        const SizedBox(width: 10),
                        Expanded(
                            child: StatCard(
                                icon: Icons.emoji_events_rounded,
                                value: user.globalRankLabel,
                                label: 'Global',
                                color: AppColors.purple)),
                      ]),
                      const SizedBox(height: 12),

                      // ── Avg score + sparkline ────────────────────────────────────────────────
                      if (results.isNotEmpty) ...[
                        BriefedCard(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Row(children: [
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      Text('AVG SCORE',
                                          style: GoogleFonts.sourceSans3(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                              color: context.hintColor,
                                              letterSpacing: 1.5)),
                                      const SizedBox(height: 4),
                                      Text('${(avgPct * 100).round()}%',
                                          style: GoogleFonts.playfairDisplay(
                                              fontSize: 28,
                                              fontWeight: FontWeight.w900,
                                              color: avgPct >= 0.8
                                                  ? AppColors.green
                                                  : avgPct >= 0.6
                                                      ? AppColors.accent
                                                      : AppColors.red)),
                                      Text(
                                          'across ${results.length} quiz${results.length == 1 ? '' : 'zes'}',
                                          style: GoogleFonts.sourceSans3(
                                              fontSize: 10,
                                              color: context.hintColor)),
                                    ])),
                                if (sparkValues.length >= 2) ...[
                                  const SizedBox(width: 12),
                                  Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text('TREND',
                                            style: GoogleFonts.sourceSans3(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w700,
                                                color: context.hintColor,
                                                letterSpacing: 1.5)),
                                        const SizedBox(height: 8),
                                        _ScoreSparkline(
                                            values: sparkValues,
                                            width: 110,
                                            height: 44),
                                      ]),
                                ],
                              ]),
                            ])),
                        const SizedBox(height: 12),
                      ],

                      // ── This Week ────────────────────────────────────────────────────────────
                      if (weekResults.isNotEmpty) ...[
                        BriefedCard(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text('THIS WEEK',
                                  style: GoogleFonts.sourceSans3(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: context.hintColor,
                                      letterSpacing: 1.5)),
                              const SizedBox(height: 12),
                              Row(children: [
                                _miniStat(context, '${weekResults.length}',
                                    'Quizzes', AppColors.blue),
                                _miniStat(context, '$bestWeekPct%',
                                    'Best Score', AppColors.green),
                                _miniStat(context, '$weekDays', 'Days Active',
                                    AppColors.purple),
                              ]),
                            ])),
                        const SizedBox(height: 12),
                      ],

                      // ── Leaderboard ─────────────────────────────────────────────────────────
                      Row(children: [
                        Text('Leaderboard',
                            style: Theme.of(context).textTheme.titleMedium),
                        const Spacer(),
                        Text('Global',
                            style: GoogleFonts.sourceSans3(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppColors.accent)),
                      ]),
                      const SizedBox(height: 10),
                      if (isGuest)
                        BriefedCard(
                            child: Column(children: [
                          const Icon(Icons.leaderboard_rounded,
                              size: 32, color: AppColors.accent),
                          const SizedBox(height: 8),
                          Text('Sign in to see the global leaderboard',
                              style: GoogleFonts.sourceSans3(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: context.subColor),
                              textAlign: TextAlign.center),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () =>
                                Navigator.of(context).pushNamed('/settings'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  borderRadius: BorderRadius.circular(12)),
                              child: Text('Sign In',
                                  style: GoogleFonts.sourceSans3(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white)),
                            ),
                          ),
                        ]))
                      else
                        leaderboardAsync.when(
                          loading: () => BriefedCard(
                              child: Column(
                                  children: List.generate(
                                      5,
                                      (_) => Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 8),
                                            child: Row(children: [
                                              Container(
                                                  width: 24,
                                                  height: 14,
                                                  decoration: BoxDecoration(
                                                      color: context.inputBg,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4))),
                                              const SizedBox(width: 10),
                                              Container(
                                                  width: 34,
                                                  height: 34,
                                                  decoration: BoxDecoration(
                                                      color: context.inputBg,
                                                      shape: BoxShape.circle)),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                  child: Container(
                                                      height: 14,
                                                      decoration: BoxDecoration(
                                                          color:
                                                              context.inputBg,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      4)))),
                                            ]),
                                          )))),
                          error: (_, __) => BriefedCard(
                              child: Center(
                                  child: Text('Could not load leaderboard',
                                      style: GoogleFonts.sourceSans3(
                                          fontSize: 12,
                                          color: context.hintColor)))),
                          data: (entries) {
                            if (entries.isEmpty)
                              return BriefedCard(
                                  child: Center(
                                      child: Text(
                                          'No scores yet — play a quiz!',
                                          style: GoogleFonts.sourceSans3(
                                              fontSize: 12,
                                              color: context.hintColor))));
                            return BriefedCard(
                                padding: EdgeInsets.zero,
                                child: Column(
                                    children: entries.asMap().entries.map((e) {
                                  final entry = e.value;
                                  final rank = e.key + 1;
                                  final isLast = e.key == entries.length - 1;
                                  if (entry.isSeparator) {
                                    return Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 4),
                                              child: Row(children: [
                                                const Expanded(
                                                    child: Divider()),
                                                Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8),
                                                    child: Text('your rank',
                                                        style: GoogleFonts
                                                            .sourceSans3(
                                                                fontSize: 9,
                                                                color: context
                                                                    .hintColor,
                                                                letterSpacing:
                                                                    1))),
                                                const Expanded(
                                                    child: Divider()),
                                              ])),
                                          _leaderboardRow(context, entry, '?',
                                              isLast: true),
                                        ]);
                                  }
                                  return _leaderboardRow(
                                      context,
                                      entry,
                                      rank <= 3
                                          ? ['🥇', '🥈', '🥉'][rank - 1]
                                          : '$rank',
                                      isLast: isLast);
                                }).toList()));
                          },
                        ),
                      const SizedBox(height: 20),

                      // ── Category Accuracy ────────────────────────────────────────────────────
                      if (catAccuracy.isNotEmpty) ...[
                        Text('Category Accuracy',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 10),
                        BriefedCard(
                            child: Column(
                                children: catAccuracy.take(5).map((e) {
                          final color = AppColors.categoryColor(e.key);
                          return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      Text(
                                          e.key[0].toUpperCase() +
                                              e.key.substring(1),
                                          style: GoogleFonts.sourceSans3(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: context.subColor)),
                                      const Spacer(),
                                      Text('${(e.value * 100).round()}%',
                                          style: GoogleFonts.sourceSans3(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800,
                                              color: color)),
                                    ]),
                                    const SizedBox(height: 5),
                                    ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        child: TweenAnimationBuilder<double>(
                                            tween:
                                                Tween(begin: 0, end: e.value),
                                            duration: const Duration(
                                                milliseconds: 900),
                                            curve: Curves.easeOutCubic,
                                            builder: (_, v, __) =>
                                                LinearProgressIndicator(
                                                    value: v,
                                                    minHeight: 8,
                                                    backgroundColor:
                                                        context.inputBg,
                                                    valueColor:
                                                        AlwaysStoppedAnimation(
                                                            color)))),
                                  ]));
                        }).toList())),
                        const SizedBox(height: 20),
                      ],

                      // ── Streak calendar ──────────────────────────────────────────────────────
                      BriefedCard(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Row(children: [
                              Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                      gradient: const LinearGradient(colors: [
                                        AppColors.accent,
                                        AppColors.orange
                                      ]),
                                      borderRadius: BorderRadius.circular(13),
                                      boxShadow: [
                                        BoxShadow(
                                            color: AppColors.accent
                                                .withValues(alpha: 0.22),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4))
                                      ]),
                                  child: const Icon(
                                      Icons.local_fire_department_rounded,
                                      color: Colors.white,
                                      size: 21)),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text('STREAK CALENDAR',
                                        style: GoogleFonts.sourceSans3(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                            color: context.hintColor,
                                            letterSpacing: 1.5)),
                                    const SizedBox(height: 2),
                                    Text(
                                        user.streak > 0
                                            ? '${user.streak} day flame is alive'
                                            : 'Start your flame today',
                                        style: GoogleFonts.sourceSans3(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: context.textColor)),
                                  ])),
                              Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                      color: AppColors.accent
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                          color: AppColors.accent
                                              .withValues(alpha: 0.22))),
                                  child: Text('$activeDays/35',
                                      style: GoogleFonts.sourceSans3(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.accent))),
                            ]),
                            const SizedBox(height: 14),
                            Row(children: [
                              _streakMetric(context, '${user.streak}',
                                  'Current', AppColors.accent),
                              _streakMetric(context, '${user.longestStreak}',
                                  'Best', AppColors.gold),
                              _streakMetric(context, '$activeDays', 'Active',
                                  AppColors.purple),
                            ]),
                            const SizedBox(height: 14),
                            Row(
                                children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                                    .map((d) => Expanded(
                                        child: Text(d,
                                            style: GoogleFonts.sourceSans3(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w800,
                                                color: context.hintColor),
                                            textAlign: TextAlign.center)))
                                    .toList()),
                            const SizedBox(height: 6),
                            GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 7,
                                        crossAxisSpacing: 6,
                                        mainAxisSpacing: 6),
                                itemCount: streakDays.length,
                                itemBuilder: (_, i) => _StreakCalendarTile(
                                    day: streakDays[i],
                                    delay: Duration(milliseconds: 18 * i))),
                            const SizedBox(height: 12),
                            Row(children: [
                              Text('Less',
                                  style: GoogleFonts.sourceSans3(
                                      fontSize: 10, color: context.hintColor)),
                              const SizedBox(width: 6),
                              ...[0.18, 0.34, 0.52, 0.72].map((a) => Container(
                                  width: 15,
                                  height: 8,
                                  margin: const EdgeInsets.only(right: 4),
                                  decoration: BoxDecoration(
                                      color:
                                          AppColors.accent.withValues(alpha: a),
                                      borderRadius:
                                          BorderRadius.circular(999)))),
                              Text('More',
                                  style: GoogleFonts.sourceSans3(
                                      fontSize: 10, color: context.hintColor)),
                              const Spacer(),
                              Text('Last 5 weeks',
                                  style: GoogleFonts.sourceSans3(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: context.hintColor)),
                            ]),
                          ])),
                      const SizedBox(height: 16),

                      // ── Badges ───────────────────────────────────────────────────────────────
                      BriefedCard(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Row(children: [
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text('BADGES',
                                        style: GoogleFonts.sourceSans3(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                            color: context.hintColor,
                                            letterSpacing: 1.5)),
                                    const SizedBox(height: 2),
                                    Text(
                                        '${_earnedBadgeCount(user)} of 5 unlocked',
                                        style: GoogleFonts.sourceSans3(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: context.textColor)),
                                  ])),
                              Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                      color:
                                          AppColors.gold.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                          color: AppColors.gold
                                              .withValues(alpha: 0.22))),
                                  child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                            Icons.workspace_premium_rounded,
                                            color: AppColors.gold,
                                            size: 14),
                                        const SizedBox(width: 5),
                                        Text('Milestones',
                                            style: GoogleFonts.sourceSans3(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.gold)),
                                      ])),
                            ]),
                            const SizedBox(height: 12),
                            _badge(
                                context,
                                Icons.star_rounded,
                                AppColors.green,
                                'First Quiz',
                                'Complete your first daily quiz',
                                user.totalQuizzes,
                                1),
                            const SizedBox(height: 8),
                            _badge(
                                context,
                                Icons.local_fire_department_rounded,
                                AppColors.accent,
                                '7 Day Streak',
                                'Keep your quiz streak alive for a full week',
                                user.streak,
                                7),
                            const SizedBox(height: 8),
                            _badge(
                                context,
                                Icons.emoji_events_rounded,
                                AppColors.gold,
                                '30 Day Streak',
                                'Build a month-long streak',
                                user.streak,
                                30),
                            const SizedBox(height: 8),
                            _badge(
                                context,
                                Icons.bolt_rounded,
                                AppColors.purple,
                                'Perfect Score',
                                'Score every question correctly in one quiz',
                                user.recentResults
                                        .any((r) => r.score == r.totalQuestions)
                                    ? 1
                                    : 0,
                                1),
                            const SizedBox(height: 8),
                            _badge(
                                context,
                                Icons.menu_book_rounded,
                                AppColors.blue,
                                '10 Quizzes',
                                'Finish ten quizzes to prove the habit',
                                user.totalQuizzes,
                                10),
                          ])),

                      // ── Recent Quizzes ───────────────────────────────────────────────────────
                      if (user.recentResults.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        BriefedCard(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Row(children: [
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      Text('RECENT QUIZZES',
                                          style: GoogleFonts.sourceSans3(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              color: context.hintColor,
                                              letterSpacing: 1.5)),
                                      const SizedBox(height: 2),
                                      Text(
                                          'Last ${user.recentResults.take(5).length} attempts',
                                          style: GoogleFonts.sourceSans3(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800,
                                              color: context.textColor)),
                                    ])),
                                Text('${(avgPct * 100).round()}% avg',
                                    style: GoogleFonts.sourceSans3(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.accent)),
                              ]),
                              const SizedBox(height: 12),
                              ...user.recentResults.take(5).map((r) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _RecentQuizRow(result: r),
                                  )),
                            ])),
                      ],
                    ]))));
  }

  Widget _leaderboardRow(
      BuildContext context, LeaderboardEntry entry, String rankLabel,
      {required bool isLast}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: entry.isYou
            ? AppColors.accent.withValues(alpha: 0.06)
            : Colors.transparent,
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: context.borderColor)),
        borderRadius: isLast
            ? const BorderRadius.vertical(bottom: Radius.circular(20))
            : null,
      ),
      child: Row(children: [
        SizedBox(
            width: 28,
            child: Text(rankLabel,
                style: GoogleFonts.sourceSans3(
                    fontSize: 14,
                    color:
                        rankLabel == '🥇' ? AppColors.gold : context.hintColor),
                textAlign: TextAlign.center)),
        const SizedBox(width: 10),
        Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: entry.isYou
                        ? AppColors.accent.withValues(alpha: 0.4)
                        : context.borderColor)),
            padding: const EdgeInsets.all(1),
            child: _buildAvatar(entry.photoUrl, 34)),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(entry.isYou ? '${entry.name} (you)' : entry.name,
              style: GoogleFonts.sourceSans3(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: entry.isYou ? AppColors.accent : context.textColor)),
          Row(children: [
            const Icon(Icons.local_fire_department_rounded,
                color: AppColors.orange, size: 11),
            const SizedBox(width: 3),
            Text('${entry.streak} day streak',
                style: GoogleFonts.sourceSans3(
                    fontSize: 10, color: context.hintColor))
          ]),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(_fmt(entry.score),
              style: GoogleFonts.sourceSans3(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: entry.isYou ? AppColors.accent : context.textColor)),
          Text('pts',
              style: GoogleFonts.sourceSans3(
                  fontSize: 9, color: context.hintColor)),
        ]),
      ]),
    );
  }

  Widget _miniStat(
      BuildContext context, String value, String label, Color color) {
    return Expanded(
        child: Column(children: [
      Text(value,
          style: GoogleFonts.playfairDisplay(
              fontSize: 22, fontWeight: FontWeight.w900, color: color)),
      const SizedBox(height: 2),
      Text(label,
          style:
              GoogleFonts.sourceSans3(fontSize: 10, color: context.hintColor),
          textAlign: TextAlign.center),
    ]));
  }

  Widget _streakMetric(
      BuildContext context, String value, String label, Color color) {
    return Expanded(
        child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: color.withValues(alpha: 0.18))),
            child: Column(children: [
              Text(value,
                  style: GoogleFonts.sourceSans3(
                      fontSize: 18, fontWeight: FontWeight.w900, color: color)),
              Text(label,
                  style: GoogleFonts.sourceSans3(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: context.hintColor)),
            ])));
  }

  int _earnedBadgeCount(UserData user) {
    return [
      user.totalQuizzes >= 1,
      user.streak >= 7,
      user.streak >= 30,
      user.recentResults.any((r) => r.score == r.totalQuestions),
      user.totalQuizzes >= 10,
    ].where((earned) => earned).length;
  }

  Widget _badge(BuildContext ctx, IconData icon, Color color, String label,
      String description, int progress, int target) {
    final clamped = progress.clamp(0, target);
    final earned = clamped >= target;
    final pct = target == 0 ? 1.0 : (clamped / target).clamp(0.0, 1.0);
    return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: earned
                ? color.withValues(alpha: 0.08)
                : ctx.inputBg.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color:
                    earned ? color.withValues(alpha: 0.26) : ctx.borderColor)),
        child: Row(children: [
          Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                  color: earned ? color.withValues(alpha: 0.16) : ctx.cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: earned
                          ? color.withValues(alpha: 0.35)
                          : ctx.borderColor)),
              child: Icon(earned ? icon : Icons.lock_rounded,
                  color: earned ? color : ctx.hintColor, size: 20)),
          const SizedBox(width: 11),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(children: [
                  Expanded(
                      child: Text(label,
                          style: GoogleFonts.sourceSans3(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: earned ? ctx.textColor : ctx.subColor))),
                  Text(earned ? 'Unlocked' : '$clamped/$target',
                      style: GoogleFonts.sourceSans3(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: earned ? color : ctx.hintColor)),
                ]),
                const SizedBox(height: 2),
                Text(description,
                    style: GoogleFonts.sourceSans3(
                        fontSize: 10, color: ctx.hintColor, height: 1.25)),
                const SizedBox(height: 7),
                ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 5,
                        backgroundColor:
                            ctx.borderColor.withValues(alpha: 0.45),
                        valueColor: AlwaysStoppedAnimation(
                            earned ? color : color.withValues(alpha: 0.55)))),
              ])),
        ]));
  }

  List<_StreakDay> _buildStreakDays(UserData user) {
    final today = DateTime.now();
    final byDate = <String, QuizResult>{};
    for (final r in user.recentResults) {
      byDate[r.date] = r;
    }
    return List.generate(35, (i) {
      final d = today.subtract(Duration(days: 34 - i));
      final ds = d.toIso8601String().substring(0, 10);
      final isToday =
          d.year == today.year && d.month == today.month && d.day == today.day;
      return _StreakDay(date: d, result: byDate[ds], isToday: isToday);
    });
  }
}

class _StreakDay {
  final DateTime date;
  final QuizResult? result;
  final bool isToday;

  const _StreakDay(
      {required this.date, required this.result, required this.isToday});
}

class _StreakCalendarTile extends StatelessWidget {
  final _StreakDay day;
  final Duration delay;

  const _StreakCalendarTile({required this.day, required this.delay});

  @override
  Widget build(BuildContext context) {
    final result = day.result;
    final active = result != null;
    final pct = result?.percentage ?? 0.0;
    final color = !active
        ? context.inputBg
        : pct >= 0.8
            ? AppColors.green
            : pct >= 0.6
                ? AppColors.accent
                : pct >= 0.4
                    ? AppColors.orange
                    : AppColors.red;
    final label = day.date.day.toString();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 360 + delay.inMilliseconds),
      curve: Curves.easeOutBack,
      builder: (context, v, child) =>
          Transform.scale(scale: 0.75 + (0.25 * v), child: child),
      child: Container(
        decoration: BoxDecoration(
          color: active
              ? color.withValues(alpha: 0.2 + (pct * 0.45))
              : context.inputBg,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
              color: day.isToday
                  ? AppColors.accent
                  : active
                      ? color.withValues(alpha: 0.42)
                      : context.borderColor,
              width: day.isToday ? 1.6 : 1),
          boxShadow: active
              ? [
                  BoxShadow(
                      color: color.withValues(alpha: 0.14),
                      blurRadius: 8,
                      offset: const Offset(0, 3))
                ]
              : null,
        ),
        child: Stack(children: [
          Center(
              child: active
                  ? Icon(
                      result.score == result.totalQuestions
                          ? Icons.star_rounded
                          : Icons.check_rounded,
                      size: 13,
                      color: Colors.white)
                  : Text(label,
                      style: GoogleFonts.sourceSans3(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: context.hintColor.withValues(alpha: 0.72)))),
          if (day.isToday)
            Align(
                alignment: Alignment.topRight,
                child: Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                        color: AppColors.accent, shape: BoxShape.circle))),
        ]),
      ),
    );
  }
}

class _RecentQuizRow extends StatelessWidget {
  final QuizResult result;

  const _RecentQuizRow({required this.result});

  @override
  Widget build(BuildContext context) {
    final color = result.score == result.totalQuestions
        ? AppColors.green
        : result.percentage >= 0.6
            ? AppColors.accent
            : result.percentage >= 0.4
                ? AppColors.orange
                : AppColors.red;
    final categories = result.categories.take(2).toList();
    return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.055),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.16))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: color.withValues(alpha: 0.25))),
                child: Center(
                    child: Text('${result.score}/${result.totalQuestions}',
                        style: GoogleFonts.sourceSans3(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: color)))),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(children: [
                    Expanded(
                        child: Text(result.performanceLabel,
                            style: GoogleFonts.sourceSans3(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: context.textColor))),
                    Text(result.percentageString,
                        style: GoogleFonts.sourceSans3(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: color)),
                  ]),
                  const SizedBox(height: 3),
                  Text(_formatResultDate(result.date),
                      style: GoogleFonts.sourceSans3(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: context.hintColor)),
                  const SizedBox(height: 8),
                  ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                          value: result.percentage,
                          minHeight: 6,
                          backgroundColor:
                              context.borderColor.withValues(alpha: 0.45),
                          valueColor: AlwaysStoppedAnimation(color))),
                ])),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _recentMeta(context, Icons.bolt_rounded,
                '+${result.pointsEarned} pts', AppColors.gold),
            const SizedBox(width: 8),
            _recentMeta(context, Icons.timer_rounded,
                _formatDuration(result.timeTakenSeconds), AppColors.blue),
            const Spacer(),
            if (categories.isNotEmpty)
              Flexible(
                  child: Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 5,
                      runSpacing: 5,
                      children: categories
                          .map((c) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                  color: AppColors.categoryColor(c)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(999)),
                              child: Text(c[0].toUpperCase() + c.substring(1),
                                  style: GoogleFonts.sourceSans3(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.categoryColor(c)))))
                          .toList())),
          ]),
        ]));
  }

  Widget _recentMeta(
      BuildContext context, IconData icon, String label, Color color) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: color),
      const SizedBox(width: 3),
      Text(label,
          style: GoogleFonts.sourceSans3(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: context.hintColor)),
    ]);
  }
}

String _formatResultDate(String raw) {
  try {
    final date = DateTime.parse(raw);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '$diff days ago';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  } catch (_) {
    return raw;
  }
}

String _formatDuration(int seconds) {
  if (seconds <= 0) return 'no time';
  final minutes = seconds ~/ 60;
  final rest = seconds % 60;
  if (minutes == 0) return '${rest}s';
  return '${minutes}m ${rest}s';
}

// Sparkline chart using CustomPainter
class _ScoreSparkline extends StatelessWidget {
  final List<double> values;
  final double width;
  final double height;
  const _ScoreSparkline(
      {required this.values, required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _SparklinePainter(
          values: values, color: AppColors.accent, isDark: context.isDark),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color color;
  final bool isDark;
  const _SparklinePainter(
      {required this.values, required this.color, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV).clamp(0.1, 1.0);

    double xOf(int i) => i / (values.length - 1) * size.width;
    double yOf(double v) =>
        size.height -
        ((v - minV) / range * size.height * 0.85 + size.height * 0.075);

    final path = Path();
    path.moveTo(xOf(0), yOf(values[0]));
    for (int i = 1; i < values.length; i++) {
      final cx = (xOf(i - 1) + xOf(i)) / 2;
      path.cubicTo(
          cx, yOf(values[i - 1]), cx, yOf(values[i]), xOf(i), yOf(values[i]));
    }

    // Fill under the line
    final fillPath = Path.from(path);
    fillPath.lineTo(xOf(values.length - 1), size.height);
    fillPath.lineTo(xOf(0), size.height);
    fillPath.close();
    canvas.drawPath(
        fillPath,
        Paint()
          ..shader = LinearGradient(colors: [
            color.withValues(alpha: 0.25),
            color.withValues(alpha: 0.0)
          ], begin: Alignment.topCenter, end: Alignment.bottomCenter)
              .createShader(Rect.fromLTWH(0, 0, size.width, size.height)));

    // Line
    canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round);

    // Dot at last value
    canvas.drawCircle(Offset(xOf(values.length - 1), yOf(values.last)), 3.5,
        Paint()..color = color);
    canvas.drawCircle(
        Offset(xOf(values.length - 1), yOf(values.last)),
        3.5,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.values != values || old.color != color;
}

// SETTINGS SCREEN — fully interactive

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final user = ref.watch(userProvider);
    final authUser = ref.watch(authStateProvider).valueOrNull;
    final isSignedIn = authUser != null && !authUser.isAnonymous;
    final authEmail = authUser?.email ?? authUser?.displayName;
    return Scaffold(
        backgroundColor: context.bgColor,
        appBar: AppBar(
            title: const Text('Settings'),
            leading: BackButton(color: context.subColor)),
        body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const _SectionLabel('APPEARANCE'),
              BriefedCard(
                  child: Row(children: [
                Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12)),
                    child: Icon(
                        themeMode == ThemeMode.dark
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        color: AppColors.accent,
                        size: 20)),
                const SizedBox(width: 14),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('Theme',
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: context.textColor)),
                      Text(
                          themeMode == ThemeMode.dark
                              ? 'Dark mode'
                              : themeMode == ThemeMode.system
                                  ? 'System default'
                                  : 'Light mode',
                          style: GoogleFonts.poppins(
                              fontSize: 10, color: context.hintColor)),
                    ])),
                Container(
                    decoration: BoxDecoration(
                        color: context.inputBg,
                        borderRadius: BorderRadius.circular(12)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      _ThemeChip(
                          icon: Icons.light_mode_rounded,
                          active: themeMode == ThemeMode.light,
                          onTap: () =>
                              ref.read(themeProvider.notifier).setLight()),
                      _ThemeChip(
                          icon: Icons.dark_mode_rounded,
                          active: themeMode == ThemeMode.dark,
                          onTap: () =>
                              ref.read(themeProvider.notifier).setDark()),
                      _ThemeChip(
                          icon: Icons.phone_android_rounded,
                          active: themeMode == ThemeMode.system,
                          onTap: () =>
                              ref.read(themeProvider.notifier).setSystem()),
                    ])),
              ])),
              const SizedBox(height: 20),
              const _SectionLabel('PREFERENCES'),
              BriefedCard(
                  padding: EdgeInsets.zero,
                  child: Column(children: [
                    _SettingsTile(
                        icon: Icons.language_rounded,
                        color: AppColors.blue,
                        title: 'News Categories',
                        sub: '${user.selectedCategories.length} selected',
                        onTap: () => _showCategoriesSheet(context, ref, user)),
                    Divider(height: 1, color: context.borderColor),
                    _SettingsTile(
                        icon: Icons.notifications_rounded,
                        color: AppColors.accent,
                        title: 'Daily Reminder',
                        sub: _formatReminderTime(
                            user.notificationHour, user.notificationMinute),
                        onTap: () => _showNotifSheet(context, ref, user)),
                  ])),
              const SizedBox(height: 20),
              const _SectionLabel('ACCOUNT'),
              BriefedCard(
                  padding: EdgeInsets.zero,
                  child: Column(children: [
                    _SettingsTile(
                        icon: Icons.person_rounded,
                        color: AppColors.purple,
                        title: 'Edit Profile',
                        sub: user.name,
                        onTap: () => _showEditNameDialog(context, ref, user)),
                    Divider(height: 1, color: context.borderColor),
                    _SettingsTile(
                        icon: Icons.lock_rounded,
                        color: AppColors.green,
                        title: 'Privacy',
                        sub: 'Your data stays on-device',
                        onTap: () => _showPrivacySheet(context)),
                    Divider(height: 1, color: context.borderColor),
                    if (isSignedIn)
                      _SettingsTile(
                          icon: Icons.logout_rounded,
                          color: AppColors.red,
                          title: 'Sign Out',
                          sub: authEmail ?? 'Signed in',
                          onTap: () => _handleSignOut(context))
                    else
                      _SettingsTile(
                          icon: Icons.login_rounded,
                          color: AppColors.blue,
                          title: 'Sign In / Create Account',
                          sub: 'Sync your progress across devices',
                          onTap: () => _showAuthSheet(context, ref)),
                  ])),
              const SizedBox(height: 20),
              const _SectionLabel('SUBSCRIPTION'),
              BriefedCard(
                  borderColor: AppColors.gold.withValues(alpha: 0.35),
                  onTap: () => _showProSheet(context),
                  child: Row(children: [
                    Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.star_rounded,
                            color: AppColors.gold, size: 20)),
                    const SizedBox(width: 14),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text('Upgrade to Pro',
                              style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.gold)),
                          Text('₹149/month · Unlock everything',
                              style: GoogleFonts.poppins(
                                  fontSize: 10, color: context.hintColor)),
                        ])),
                    const Icon(Icons.chevron_right_rounded, size: 18),
                  ])),
            ])));
  }

  void _showCategoriesSheet(
      BuildContext context, WidgetRef ref, UserData user) {
    final selected = List<String>.from(user.selectedCategories);
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: context.cardColor,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
              return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                            child: Container(
                                width: 40,
                                height: 4,
                                margin: const EdgeInsets.only(bottom: 20),
                                decoration: BoxDecoration(
                                    color: ctx.borderColor,
                                    borderRadius: BorderRadius.circular(2)))),
                        Text('News Categories',
                            style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: ctx.textColor)),
                        const SizedBox(height: 4),
                        Text(
                            'Choose what topics appear in your quiz and briefing',
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: ctx.subColor)),
                        const SizedBox(height: 20),
                        GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            childAspectRatio: 2.8,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            children: AppConstants.allCategories.map((cat) {
                              final id = cat['id']!;
                              final on = selected.contains(id);
                              final color =
                                  AppColors.categoryColor(cat['label']!);
                              return GestureDetector(
                                  onTap: () => setS(() {
                                        if (on) {
                                          if (selected.length > 1)
                                            selected.remove(id);
                                        } else {
                                          selected.add(id);
                                        }
                                      }),
                                  child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 180),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 10),
                                      decoration: BoxDecoration(
                                          color: on
                                              ? color.withValues(alpha: 0.1)
                                              : ctx.inputBg,
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          border: Border.all(
                                              color: on
                                                  ? color.withValues(alpha: 0.4)
                                                  : ctx.borderColor)),
                                      child: Row(children: [
                                        Icon(_iconForCat(id),
                                            size: 16,
                                            color: on ? color : ctx.hintColor),
                                        const SizedBox(width: 8),
                                        Text(cat['label']!,
                                            style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: on
                                                    ? ctx.textColor
                                                    : ctx.subColor)),
                                        if (on) ...[
                                          const Spacer(),
                                          Icon(Icons.check_circle_rounded,
                                              size: 14, color: color)
                                        ],
                                      ])));
                            }).toList()),
                        const SizedBox(height: 20),
                        AccentButton(
                            text: 'Save',
                            onTap: () {
                              ref
                                  .read(userProvider.notifier)
                                  .updateCategories(selected);
                              Navigator.of(ctx).pop();
                            },
                            icon: Icons.check_rounded),
                      ]));
            }));
  }

  void _showNotifSheet(BuildContext context, WidgetRef ref, UserData user) {
    final options = [
      {
        'label': '7:00 AM',
        'sub': 'Early bird',
        'icon': Icons.wb_sunny_outlined,
        'hour': 7,
        'minute': 0
      },
      {
        'label': '8:30 AM',
        'sub': 'Morning',
        'icon': Icons.light_mode_outlined,
        'hour': 8,
        'minute': 30
      },
      {
        'label': '12:00 PM',
        'sub': 'Lunch break',
        'icon': Icons.lunch_dining_outlined,
        'hour': 12,
        'minute': 0
      },
      {
        'label': '6:00 PM',
        'sub': 'Evening',
        'icon': Icons.wb_twilight_outlined,
        'hour': 18,
        'minute': 0
      },
      {
        'label': '9:00 PM',
        'sub': 'Night owl',
        'icon': Icons.nightlight_outlined,
        'hour': 21,
        'minute': 0
      },
    ];
    int selectedHour = user.notificationHour;
    int selectedMinute = user.notificationMinute;
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: context.cardColor,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
              return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                            child: Container(
                                width: 40,
                                height: 4,
                                margin: const EdgeInsets.only(bottom: 20),
                                decoration: BoxDecoration(
                                    color: ctx.borderColor,
                                    borderRadius: BorderRadius.circular(2)))),
                        Text('Daily Reminder',
                            style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: ctx.textColor)),
                        const SizedBox(height: 4),
                        Text("When should we remind you to take today's quiz?",
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: ctx.subColor)),
                        const SizedBox(height: 20),
                        ...options.map((opt) {
                          final on = selectedHour == opt['hour'] &&
                              selectedMinute == opt['minute'];
                          return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: GestureDetector(
                                  onTap: () => setS(() {
                                        selectedHour = opt['hour'] as int;
                                        selectedMinute = opt['minute'] as int;
                                      }),
                                  child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 180),
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                          color: on
                                              ? AppColors.accent
                                                  .withValues(alpha: 0.08)
                                              : ctx.inputBg,
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          border: Border.all(
                                              color: on
                                                  ? AppColors.accent
                                                      .withValues(alpha: 0.4)
                                                  : ctx.borderColor)),
                                      child: Row(children: [
                                        Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                                color: on
                                                    ? AppColors.accent
                                                        .withValues(alpha: 0.15)
                                                    : ctx.cardColor,
                                                borderRadius:
                                                    BorderRadius.circular(12)),
                                            child: Icon(opt['icon'] as IconData,
                                                color: on
                                                    ? AppColors.accent
                                                    : ctx.hintColor,
                                                size: 20)),
                                        const SizedBox(width: 14),
                                        Expanded(
                                            child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                              Text(opt['label'] as String,
                                                  style: GoogleFonts.poppins(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: on
                                                          ? ctx.textColor
                                                          : ctx.subColor)),
                                              Text(opt['sub'] as String,
                                                  style: GoogleFonts.poppins(
                                                      fontSize: 11,
                                                      color: ctx.hintColor)),
                                            ])),
                                        AnimatedContainer(
                                            duration: const Duration(
                                                milliseconds: 180),
                                            width: 22,
                                            height: 22,
                                            decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: on
                                                    ? AppColors.accent
                                                    : Colors.transparent,
                                                border: Border.all(
                                                    color: on
                                                        ? AppColors.accent
                                                        : ctx.hintColor,
                                                    width: 2)),
                                            child: on
                                                ? const Icon(
                                                    Icons.check_rounded,
                                                    color: Colors.white,
                                                    size: 13)
                                                : null),
                                      ]))));
                        }),
                        Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: GestureDetector(
                                onTap: () async {
                                  final picked = await showTimePicker(
                                      context: ctx,
                                      initialTime: TimeOfDay(
                                          hour: selectedHour,
                                          minute: selectedMinute));
                                  if (picked != null)
                                    setS(() {
                                      selectedHour = picked.hour;
                                      selectedMinute = picked.minute;
                                    });
                                },
                                child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                        color: options.any((o) =>
                                                selectedHour == o['hour'] &&
                                                selectedMinute == o['minute'])
                                            ? ctx.inputBg
                                            : AppColors.accent
                                                .withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                            color: options.any((o) =>
                                                    selectedHour == o['hour'] &&
                                                    selectedMinute ==
                                                        o['minute'])
                                                ? ctx.borderColor
                                                : AppColors.accent
                                                    .withValues(alpha: 0.4))),
                                    child: Row(children: [
                                      Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                              color: ctx.cardColor,
                                              borderRadius:
                                                  BorderRadius.circular(12)),
                                          child: Icon(
                                              Icons.edit_calendar_rounded,
                                              color: options.any((o) =>
                                                      selectedHour ==
                                                          o['hour'] &&
                                                      selectedMinute ==
                                                          o['minute'])
                                                  ? ctx.hintColor
                                                  : AppColors.accent,
                                              size: 20)),
                                      const SizedBox(width: 14),
                                      Expanded(
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                            Text(
                                                _formatReminderTime(
                                                    selectedHour,
                                                    selectedMinute),
                                                style: GoogleFonts.poppins(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color: ctx.textColor)),
                                            Text('Choose your own time',
                                                style: GoogleFonts.poppins(
                                                    fontSize: 11,
                                                    color: ctx.hintColor)),
                                          ])),
                                      const Icon(Icons.chevron_right_rounded,
                                          size: 18),
                                    ])))),
                        AccentButton(
                            text: 'Save',
                            onTap: () {
                              ref
                                  .read(userProvider.notifier)
                                  .updateNotificationTime(
                                      selectedHour, selectedMinute);
                              Navigator.of(ctx).pop();
                            },
                            icon: Icons.check_rounded),
                      ]));
            }));
  }

  void _showEditNameDialog(BuildContext context, WidgetRef ref, UserData user) {
    final ctrl = TextEditingController(text: user.name);
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
                backgroundColor: ctx.cardColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                title: Text('Edit Profile',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w800, color: ctx.textColor)),
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextField(
                      controller: ctrl,
                      autofocus: true,
                      style: GoogleFonts.poppins(color: ctx.textColor),
                      decoration: InputDecoration(
                          labelText: 'Your name',
                          labelStyle: GoogleFonts.poppins(color: ctx.hintColor),
                          filled: true,
                          fillColor: ctx.inputBg,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  const BorderSide(color: AppColors.accent)))),
                ]),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text('Cancel',
                          style: GoogleFonts.poppins(color: ctx.hintColor))),
                  TextButton(
                      onPressed: () {
                        final name = ctrl.text.trim();
                        if (name.isNotEmpty)
                          ref.read(userProvider.notifier).updateName(name);
                        Navigator.of(ctx).pop();
                      },
                      child: Text('Save',
                          style: GoogleFonts.poppins(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w800))),
                ]));
  }

  void _showPrivacySheet(BuildContext context) {
    showModalBottomSheet(
        context: context,
        backgroundColor: context.cardColor,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (ctx) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                      child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                              color: ctx.borderColor,
                              borderRadius: BorderRadius.circular(2)))),
                  Text('Privacy',
                      style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: ctx.textColor)),
                  const SizedBox(height: 16),
                  ...[
                    (
                      'Your data stays on-device',
                      'All quiz scores, streaks, and preferences are stored locally. Nothing is sent to our servers.',
                      Icons.phone_android_rounded,
                      AppColors.green
                    ),
                    (
                      'No account required',
                      'Briefed works without an account. Your identity is never collected or stored.',
                      Icons.person_off_rounded,
                      AppColors.blue
                    ),
                    (
                      'API usage',
                      'We send news headlines (not personal data) to Groq/Gemini to generate quiz questions. No personal info included.',
                      Icons.api_rounded,
                      AppColors.purple
                    ),
                  ].map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                    color: item.$4.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10)),
                                child: Icon(item.$3, color: item.$4, size: 18)),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(item.$1,
                                      style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: ctx.textColor)),
                                  const SizedBox(height: 3),
                                  Text(item.$2,
                                      style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          color: ctx.subColor,
                                          height: 1.55)),
                                ])),
                          ]))),
                ])));
  }

  void _showProSheet(BuildContext context) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: context.cardColor,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (ctx) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Center(
                  child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                          color: ctx.borderColor,
                          borderRadius: BorderRadius.circular(2)))),
              Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [AppColors.gold, Color(0xFFFF9100)]),
                      borderRadius: BorderRadius.circular(18)),
                  child: const Icon(Icons.star_rounded,
                      color: Colors.white, size: 30)),
              const SizedBox(height: 14),
              Text('Briefed Pro',
                  style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: ctx.textColor)),
              Text('₹149 / month',
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.gold,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              ...[
                ('Unlimited quiz replays', Icons.replay_rounded),
                (
                  'Monthly Wrapped — your news personality',
                  Icons.auto_awesome_rounded
                ),
                (
                  'Advanced stats and category breakdowns',
                  Icons.bar_chart_rounded
                ),
                ('Early access to new games', Icons.games_rounded),
                ('Remove all ads (when added)', Icons.block_rounded),
              ].map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(children: [
                    Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(9)),
                        child: Icon(f.$2, color: AppColors.gold, size: 16)),
                    const SizedBox(width: 12),
                    Text(f.$1,
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: ctx.textColor)),
                  ]))),
              const SizedBox(height: 8),
              Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [AppColors.gold, Color(0xFFFF9100)]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.gold.withValues(alpha: 0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 6))
                      ]),
                  child: Center(
                      child: Text('Start Free Trial',
                          style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Colors.white)))),
              const SizedBox(height: 8),
              Text('7-day free trial · Cancel anytime',
                  style:
                      GoogleFonts.poppins(fontSize: 11, color: ctx.hintColor)),
            ])));
  }

  void _showAuthSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: context.cardColor,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (_) => _AuthSheet(ref: ref));
  }

  void _handleSignOut(BuildContext context) {
    // Capture Navigator before any async gap — the auth stream will rebuild
    // SettingsScreen during signOut(), making the original context stale.
    final nav = Navigator.of(context);
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
                backgroundColor: ctx.cardColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                title: Text('Sign Out',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w800, color: ctx.textColor)),
                content: Text('Are you sure you want to sign out?',
                    style:
                        GoogleFonts.poppins(fontSize: 13, color: ctx.subColor)),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text('Cancel',
                          style: GoogleFonts.poppins(color: ctx.hintColor))),
                  TextButton(
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        await AuthService.signOut();
                        nav.pushNamedAndRemoveUntil('/signin', (_) => false);
                      },
                      child: Text('Sign Out',
                          style: GoogleFonts.poppins(
                              color: AppColors.red,
                              fontWeight: FontWeight.w800))),
                ]));
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: GoogleFonts.poppins(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: context.hintColor,
              letterSpacing: 2)));
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, sub;
  final VoidCallback onTap;
  const _SettingsTile(
      {required this.icon,
      required this.color,
      required this.title,
      required this.sub,
      required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: onTap,
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(children: [
              Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: color, size: 18)),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(title,
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: context.textColor)),
                    Text(sub,
                        style: GoogleFonts.poppins(
                            fontSize: 10, color: context.hintColor)),
                  ])),
              Icon(Icons.chevron_right_rounded,
                  color: context.hintColor, size: 18),
            ])));
  }
}

class _ThemeChip extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _ThemeChip(
      {required this.icon, required this.active, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 34,
            height: 34,
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
                color: active ? context.cardColor : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
                border: active ? Border.all(color: context.borderColor) : null,
                boxShadow: active
                    ? [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2))
                      ]
                    : []),
            child: Icon(icon,
                size: 16,
                color: active ? AppColors.accent : context.hintColor)));
  }
}

// ─── Auth Sheet ───────────────────────────────────────────────────────────────

class _AuthSheet extends ConsumerStatefulWidget {
  final WidgetRef ref;
  const _AuthSheet({required this.ref});
  @override
  ConsumerState<_AuthSheet> createState() => _AuthSheetState();
}

class _AuthSheetState extends ConsumerState<_AuthSheet> {
  bool _isSignUp = false;
  bool _isLoading = false;
  String? _error;
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      if (_isSignUp) {
        final cred = await AuthService.createAccount(
            email: _emailCtrl.text,
            password: _passwordCtrl.text,
            name: _nameCtrl.text.trim());
        ref.read(userProvider.notifier).syncAuthProfile(cred.user);
      } else {
        final cred = await AuthService.signInWithEmail(
            email: _emailCtrl.text, password: _passwordCtrl.text);
        ref.read(userProvider.notifier).syncAuthProfile(cred.user);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _error = _friendly(e);
        _isLoading = false;
      });
    }
  }

  Future<void> _googleSignIn() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final cred = await AuthService.signInWithGoogle();
      ref.read(userProvider.notifier).syncAuthProfile(cred.user);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _error = _friendly(e);
        _isLoading = false;
      });
    }
  }

  String _friendly(Object e) {
    final s = e.toString();
    if (s.contains('user-not-found'))
      return 'No account found with this email.';
    if (s.contains('wrong-password') || s.contains('invalid-credential'))
      return 'Incorrect password.';
    if (s.contains('email-already-in-use'))
      return 'An account with this email already exists.';
    if (s.contains('weak-password'))
      return 'Password must be at least 6 characters.';
    if (s.contains('invalid-email'))
      return 'Please enter a valid email address.';
    if (s.contains('network-request-failed')) return 'No internet connection.';
    return 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.fromLTRB(
            20, 8, 20, MediaQuery.of(context).viewInsets.bottom + 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(
              child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                      color: context.borderColor,
                      borderRadius: BorderRadius.circular(2)))),

          // Sign In / Create Account toggle
          Container(
            decoration: BoxDecoration(
                color: context.inputBg,
                borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.all(4),
            child: Row(children: [
              _tab('Sign In', !_isSignUp),
              _tab('Create Account', _isSignUp)
            ]),
          ),
          const SizedBox(height: 20),

          if (_isSignUp) ...[
            _field(_nameCtrl, 'Your name', Icons.person_outline_rounded),
            const SizedBox(height: 12),
          ],
          _field(_emailCtrl, 'Email address', Icons.mail_outline_rounded,
              type: TextInputType.emailAddress),
          const SizedBox(height: 12),
          _field(_passwordCtrl, 'Password', Icons.lock_outline_rounded,
              obscure: true),
          const SizedBox(height: 16),

          if (_error != null) ...[
            Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                    color: AppColors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.red.withValues(alpha: 0.25))),
                child: Text(_error!,
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppColors.red))),
            const SizedBox(height: 14),
          ],

          // Primary button
          GestureDetector(
              onTap: _isLoading ? null : _submit,
              child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [AppColors.accent, AppColors.accentDark]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 5))
                      ]),
                  child: Center(
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : Text(_isSignUp ? 'Create Account' : 'Sign In',
                              style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white))))),
          const SizedBox(height: 14),

          Row(children: [
            Expanded(child: Divider(color: context.borderColor)),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('or',
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: context.hintColor))),
            Expanded(child: Divider(color: context.borderColor)),
          ]),
          const SizedBox(height: 14),

          // Google Sign In
          GestureDetector(
              onTap: _isLoading ? null : _googleSignIn,
              child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                      color: context.inputBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.borderColor)),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const _GoogleLogo(size: 20),
                        const SizedBox(width: 10),
                        Text('Continue with Google',
                            style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: context.textColor)),
                      ]))),
        ]));
  }

  Widget _tab(String label, bool active) => Expanded(
      child: GestureDetector(
          onTap: () => setState(() {
                _isSignUp = label == 'Create Account';
                _error = null;
              }),
          child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                  color: active ? context.cardColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: active
                      ? [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 2))
                        ]
                      : []),
              child: Text(label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color:
                          active ? context.textColor : context.hintColor)))));

  Widget _field(TextEditingController ctrl, String label, IconData icon,
          {bool obscure = false, TextInputType type = TextInputType.text}) =>
      TextField(
          controller: ctrl,
          obscureText: obscure,
          keyboardType: type,
          style: GoogleFonts.poppins(color: context.textColor, fontSize: 14),
          decoration: InputDecoration(
              labelText: label,
              labelStyle:
                  GoogleFonts.poppins(color: context.hintColor, fontSize: 13),
              prefixIcon: Icon(icon, color: context.hintColor, size: 18),
              filled: true,
              fillColor: context.inputBg,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.accent))));
}

// ─────────────────────────────────────────────────────────────────────────────
// GOOGLE LOGO WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class _GoogleLogo extends StatelessWidget {
  final double size;
  const _GoogleLogo({this.size = 24});

  @override
  Widget build(BuildContext context) => SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleGPainter()));
}

class _GoogleGPainter extends CustomPainter {
  static const _blue = Color(0xFF4285F4);
  static const _red = Color(0xFFEA4335);
  static const _yellow = Color(0xFFFBBC05);
  static const _green = Color(0xFF34A853);

  @override
  void paint(Canvas canvas, Size s) {
    final cx = s.width / 2, cy = s.height / 2;
    final r = s.width * 0.40;
    final thick = s.width * 0.20;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thick
      ..strokeCap = StrokeCap.butt;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);

    paint.color = _blue;
    canvas.drawArc(rect, -0.42, 0.86, false, paint);
    paint.color = _green;
    canvas.drawArc(rect, 0.44, 1.48, false, paint);
    paint.color = _yellow;
    canvas.drawArc(rect, 1.92, 1.08, false, paint);
    paint.color = _red;
    canvas.drawArc(rect, 3.00, 2.54, false, paint);

    final halfBar = thick / 2;
    canvas.drawRect(
      Rect.fromLTRB(cx, cy - halfBar, cx + r + halfBar, cy + halfBar),
      Paint()
        ..color = _blue
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_GoogleGPainter _) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// AD WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

// Adaptive banner — loads after first frame so it can read screen width
class _BannerAdWidget extends StatefulWidget {
  const _BannerAdWidget();
  @override
  State<_BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<_BannerAdWidget> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    final width = MediaQuery.of(context).size.width.truncate();
    final size =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
    if (!mounted) return;
    _ad = BannerAd(
      adUnitId: AdIds.banner,
      size: size ?? AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, _) => ad.dispose(),
      ),
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _ad == null) return const SizedBox.shrink();
    return SizedBox(
      width: _ad!.size.width.toDouble(),
      height: _ad!.size.height.toDouble(),
      child: AdWidget(ad: _ad!),
    );
  }
}

// Small native ad template — used in the Briefing feed
class _NativeAdCard extends StatefulWidget {
  const _NativeAdCard();
  @override
  State<_NativeAdCard> createState() => _NativeAdCardState();
}

class _NativeAdCardState extends State<_NativeAdCard> {
  NativeAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _ad = NativeAd(
      adUnitId: AdIds.native,
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, _) => ad.dispose(),
      ),
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.small,
        cornerRadius: 20,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: AppColors.accent,
          style: NativeTemplateFontStyle.bold,
          size: 14,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.black87,
          style: NativeTemplateFontStyle.bold,
          size: 14,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.grey,
          style: NativeTemplateFontStyle.normal,
          size: 12,
        ),
      ),
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _ad == null) return const SizedBox.shrink();
    return SizedBox(height: 90, child: AdWidget(ad: _ad!));
  }
}
