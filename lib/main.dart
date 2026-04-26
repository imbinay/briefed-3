import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme.dart';
import 'providers/providers.dart';
import 'services/ad_service.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'screens/screens.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor:           Colors.transparent,
    statusBarBrightness:      Brightness.light,
    statusBarIconBrightness:  Brightness.dark,
  ));

  // Init local storage
  await Firebase.initializeApp();
  await AuthService.initGoogleSignIn();
  await StorageService.init();
  await AdService.init();
  AdService.preload();
  await NotificationService.scheduleDailyReminder(
    hour: StorageService.getNotificationHour(),
    minute: StorageService.getNotificationMinute(),
    requestPermission: false,
  );

  runApp(
    const ProviderScope(
      child: BriefedApp(),
    ),
  );
}

class BriefedApp extends ConsumerWidget {
  const BriefedApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title:            'Briefed',
      debugShowCheckedModeBanner: false,
      theme:            AppTheme.light(),
      darkTheme:        AppTheme.dark(),
      themeMode:        themeMode,
      initialRoute:     '/splash',
      routes: {
        '/splash':    (_) => const SplashScreen(),
        '/signin':    (_) => const SignInScreen(),
        '/onboarding':(_) => const OnboardingScreen(),
        '/home':      (_) => const MainShell(),
        '/quiz':      (_) => const QuizScreen(),
        '/result':    (_) => const ResultScreen(),
        '/hot-take':  (_) => const HotTakeScreen(),
        '/settings':  (_) => const SettingsScreen(),
      },
    );
  }
}
