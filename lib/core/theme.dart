import 'package:flutter/material.dart';

class AppFonts {
  static const String display = 'BricolageGrotesque';
  static const String body = 'Manrope';
  static const String mono = 'JetBrainsMono';
}

// ─────────────────────────────────────────────────────────────────────────────
// BRIEFED — Theme System
// ─────────────────────────────────────────────────────────────────────────────

class AppColors {
  // Accent — premium orange identity
  static const Color accent = Color(0xFFFF5A1F);
  static const Color accentDark = Color(0xFFE13E00);
  static const Color accentLight = Color(0xFFFF9A62);
  static const Color ember = Color(0xFFFF7A2F);
  static const Color cream = Color(0xFFFFF8F1);
  static const Color warmSurface = Color(0xFFFFFCF8);

  // Semantic
  static const Color green = Color(0xFF2E7D32);
  static const Color red = Color(0xFFD84315);
  static const Color blue = Color(0xFF2196F3);
  static const Color purple = Color(0xFF9C27B0);
  static const Color gold = Color(0xFFFFB23F);
  static const Color orange = Color(0xFFFF9800);
  static const Color teal = Color(0xFF00BCD4);
  static const Color pink = Color(0xFFE91E63);

  // Category colors
  static Color categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'world':
        return const Color(0xFF2196F3);
      case 'technology':
      case 'tech':
        return const Color(0xFF00BCD4);
      case 'business':
        return const Color(0xFFFF9800);
      case 'science':
        return const Color(0xFF9C27B0);
      case 'sports':
        return const Color(0xFF4CAF50);
      case 'entertainment':
        return const Color(0xFFE91E63);
      case 'politics':
        return const Color(0xFF9C27B0);
      case 'health':
        return const Color(0xFF26A69A);
      default:
        return accent;
    }
  }

  static Color categoryBg(String category) {
    return categoryColor(category).withValues(alpha: 0.10);
  }

  // Light theme palette
  static const Color lightBg = Color(0xFFFFF7EF);
  static const Color lightBg2 = Color(0xFFFFEFE2);
  static const Color lightCard = Color(0xFFFFFCF8);
  static const Color lightText = Color(0xFF21130D);
  static const Color lightSub = Color(0xA621130D);
  static const Color lightHint = Color(0x6621130D);
  static const Color lightBorder = Color(0x0F8A3A00);
  static const Color lightBorder2 = Color(0x1A8A3A00);
  static const Color lightInputBg = Color(0xFFFFEFE5);
  static const Color lightNavBg = Color(0xEFFFFCF8);

  // Dark theme palette
  static const Color darkBg = Color(0xFF140B07);
  static const Color darkBg2 = Color(0xFF21100A);
  static const Color darkCard = Color(0xFF24140E);
  static const Color darkText = Color(0xFFFFF6EE);
  static const Color darkSub = Color(0xA6FFF6EE);
  static const Color darkHint = Color(0x66FFF6EE);
  static const Color darkBorder = Color(0x18FFB071);
  static const Color darkBorder2 = Color(0x2BFFB071);
  static const Color darkInputBg = Color(0xFF301A11);
  static const Color darkNavBg = Color(0xE61B0E09);
}

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.accent,
        secondary: AppColors.accentLight,
        surface: AppColors.lightCard,
        onPrimary: Colors.white,
        onSurface: AppColors.lightText,
      ),
      scaffoldBackgroundColor: AppColors.lightBg,
      textTheme: _buildTextTheme(AppColors.lightText),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: AppFonts.display,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.lightText,
          letterSpacing: -0.3,
          height: 1.02,
        ),
        iconTheme: IconThemeData(color: AppColors.lightText),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide.none,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightNavBg,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.lightHint,
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        secondary: AppColors.accentLight,
        surface: AppColors.darkCard,
        onPrimary: Colors.white,
        onSurface: AppColors.darkText,
      ),
      scaffoldBackgroundColor: AppColors.darkBg,
      textTheme: _buildTextTheme(AppColors.darkText),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: AppFonts.display,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.darkText,
          letterSpacing: -0.3,
          height: 1.02,
        ),
        iconTheme: IconThemeData(color: AppColors.darkText),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide.none,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkNavBg,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.darkHint,
      ),
    );
  }

  static TextTheme _buildTextTheme(Color textColor) {
    return TextTheme(
      // Bricolage Grotesque — display/headline style from the design handoff.
      displayLarge: TextStyle(
          fontFamily: AppFonts.display,
          fontSize: 57,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.1,
          height: 1.02,
          color: textColor),
      displayMedium: TextStyle(
          fontFamily: AppFonts.display,
          fontSize: 45,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.9,
          height: 1.02,
          color: textColor),
      displaySmall: TextStyle(
          fontFamily: AppFonts.display,
          fontSize: 36,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.7,
          height: 1.02,
          color: textColor),
      headlineLarge: TextStyle(
          fontFamily: AppFonts.display,
          fontSize: 32,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.64,
          height: 1.02,
          color: textColor),
      headlineMedium: TextStyle(
          fontFamily: AppFonts.display,
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.56,
          height: 1.02,
          color: textColor),
      headlineSmall: TextStyle(
          fontFamily: AppFonts.display,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.48,
          height: 1.02,
          color: textColor),
      titleLarge: TextStyle(
          fontFamily: AppFonts.display,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.44,
          height: 1.02,
          color: textColor),
      // Manrope — body/UI style from the design handoff.
      titleMedium: TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: textColor),
      titleSmall: TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: textColor),
      bodyLarge: TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textColor),
      bodyMedium: TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textColor),
      bodySmall: TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: textColor),
      labelLarge: TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: textColor),
      labelMedium: TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor),
      labelSmall: TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textColor),
    );
  }
}

// Extension to get theme-aware colors easily
extension ThemeExtension on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get bgColor => isDark ? AppColors.darkBg : AppColors.lightBg;
  Color get cardColor => isDark ? AppColors.darkCard : AppColors.lightCard;
  Color get textColor => isDark ? AppColors.darkText : AppColors.lightText;
  Color get subColor => isDark ? AppColors.darkSub : AppColors.lightSub;
  Color get hintColor => isDark ? AppColors.darkHint : AppColors.lightHint;
  Color get borderColor =>
      isDark ? AppColors.darkBorder : AppColors.lightBorder;
  Color get border2Color =>
      isDark ? AppColors.darkBorder2 : AppColors.lightBorder2;
  Color get inputBg => isDark ? AppColors.darkInputBg : AppColors.lightInputBg;
}
