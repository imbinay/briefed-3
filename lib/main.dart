import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:in_app_purchase/in_app_purchase.dart' if (dart.library.js_interop) 'core/iap_stub.dart';
import 'core/theme.dart';
import 'providers/providers.dart';
import 'services/ad_service.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/pro_purchase_service.dart';
import 'services/storage_service.dart';
import 'screens/screens.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait on mobile only
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  // Status bar style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarBrightness: Brightness.light,
    statusBarIconBrightness: Brightness.dark,
  ));

  // Init local storage
  await Firebase.initializeApp(
    options: kIsWeb ? DefaultFirebaseOptions.currentPlatform : null,
  );
  await AuthService.initGoogleSignIn();
  await StorageService.init();
  await AdService.init();
  final signedInPro = StorageService.getIsPro() &&
      AuthService.currentUser != null &&
      !AuthService.isGuest;
  AdService.configure(adsEnabled: !signedInPro);
  AdService.preload();
  if (!kIsWeb) {
    await NotificationService.scheduleDailyReminder(
      hour: StorageService.getNotificationHour(),
      minute: StorageService.getNotificationMinute(),
      requestPermission: false,
    );
  }

  runApp(
    const ProviderScope(
      child: ProPurchaseListener(
        child: BriefedApp(),
      ),
    ),
  );
}

class ProPurchaseListener extends ConsumerStatefulWidget {
  final Widget child;
  const ProPurchaseListener({super.key, required this.child});

  @override
  ConsumerState<ProPurchaseListener> createState() =>
      _ProPurchaseListenerState();
}

class _ProPurchaseListenerState extends ConsumerState<ProPurchaseListener> {
  StreamSubscription<List<PurchaseDetails>>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = ProPurchaseService.purchaseStream.listen(_handlePurchases);
  }

  Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (!ProPurchaseService.isProPurchase(purchase)) continue;

      if (ProPurchaseService.unlocksPro(purchase) &&
          AuthService.currentUser != null &&
          !AuthService.isGuest) {
        await ref.read(userProvider.notifier).activateProFromPurchase(purchase);
      }

      await ProPurchaseService.complete(purchase);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class BriefedApp extends ConsumerWidget {
  const BriefedApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Briefed',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      initialRoute: '/splash',
      routes: {
        '/splash': (_) => const SplashScreen(),
        '/signin': (_) => const SignInScreen(),
        '/onboarding': (_) => const OnboardingScreen(),
        '/home': (_) => const MainShell(),
        '/quiz': (_) => const QuizScreen(),
        '/result': (_) => const ResultScreen(),
        '/hot-take': (_) => const HotTakeScreen(),
        '/settings': (_) => const SettingsScreen(),
      },
    );
  }
}
