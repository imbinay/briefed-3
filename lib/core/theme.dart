import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BRIEFED — Theme System
// ─────────────────────────────────────────────────────────────────────────────

class AppColors {
  // Accent — vibrant orange-red, works on both light and dark
  static const Color accent      = Color(0xFFFF4500);
  static const Color accentDark  = Color(0xFFCC3700);
  static const Color accentLight = Color(0xFFFF6B35);

  // Semantic
  static const Color green  = Color(0xFF00C853);
  static const Color red    = Color(0xFFFF1744);
  static const Color blue   = Color(0xFF2979FF);
  static const Color purple = Color(0xFF7C4DFF);
  static const Color gold   = Color(0xFFFFD600);
  static const Color orange = Color(0xFFFF9100);
  static const Color teal   = Color(0xFF00BCD4);
  static const Color pink   = Color(0xFFE91E63);

  // Category colors
  static Color categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'world':         return blue;
      case 'technology':    return teal;
      case 'tech':          return teal;
      case 'business':      return orange;
      case 'science':       return purple;
      case 'sports':        return pink;
      case 'entertainment': return gold;
      default:              return blue;
    }
  }

  static Color categoryBg(String category) {
    return categoryColor(category).withOpacity(0.12);
  }

  // Light theme palette
  static const Color lightBg        = Color(0xFFF5F5F1);
  static const Color lightBg2       = Color(0xFFEEEEE8);
  static const Color lightCard      = Color(0xFFFFFFFF);
  static const Color lightText      = Color(0xFF0D0D0D);
  static const Color lightSub       = Color(0x8C0D0D0D);
  static const Color lightHint      = Color(0x4D0D0D0D);
  static const Color lightBorder    = Color(0x120D0D0D);
  static const Color lightBorder2   = Color(0x210D0D0D);
  static const Color lightInputBg   = Color(0xFFEFEFEB);
  static const Color lightNavBg     = Color(0xFFFFFFFF);

  // Dark theme palette
  static const Color darkBg         = Color(0xFF0D0D0D);
  static const Color darkBg2        = Color(0xFF151515);
  static const Color darkCard       = Color(0xFF1C1C1C);
  static const Color darkText       = Color(0xFFF5F5F0);
  static const Color darkSub        = Color(0x8CF5F5F0);
  static const Color darkHint       = Color(0x47F5F5F0);
  static const Color darkBorder     = Color(0x12FFFFFF);
  static const Color darkBorder2    = Color(0x21FFFFFF);
  static const Color darkInputBg    = Color(0xFF222222);
  static const Color darkNavBg      = Color(0xFF111111);
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
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.lightText,
          letterSpacing: -0.3,
          wordSpacing: 1.5,
        ),
        iconTheme: const IconThemeData(color: AppColors.lightText),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.lightBorder, width: 1),
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
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.darkText,
          letterSpacing: -0.3,
          wordSpacing: 1.5,
        ),
        iconTheme: const IconThemeData(color: AppColors.darkText),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
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
      // Playfair Display — editorial headlines
      displayLarge:  GoogleFonts.playfairDisplay(fontSize: 57, fontWeight: FontWeight.w900, letterSpacing: -2,   wordSpacing: 2.0, color: textColor),
      displayMedium: GoogleFonts.playfairDisplay(fontSize: 45, fontWeight: FontWeight.w900, letterSpacing: -1.5, wordSpacing: 2.0, color: textColor),
      displaySmall:  GoogleFonts.playfairDisplay(fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: -0.8, wordSpacing: 1.5, color: textColor),
      headlineLarge: GoogleFonts.playfairDisplay(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.5, wordSpacing: 1.5, color: textColor),
      headlineMedium:GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.3, wordSpacing: 1.5, color: textColor),
      headlineSmall: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.2, wordSpacing: 1.5, color: textColor),
      titleLarge:    GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.2, wordSpacing: 1.5, color: textColor),
      // Source Sans 3 — clean UI / body text
      titleMedium:   GoogleFonts.sourceSans3(fontSize: 16, fontWeight: FontWeight.w700, wordSpacing: 1.2, color: textColor),
      titleSmall:    GoogleFonts.sourceSans3(fontSize: 14, fontWeight: FontWeight.w700, wordSpacing: 1.2, color: textColor),
      bodyLarge:     GoogleFonts.sourceSans3(fontSize: 16, fontWeight: FontWeight.w400, wordSpacing: 1.5, color: textColor),
      bodyMedium:    GoogleFonts.sourceSans3(fontSize: 14, fontWeight: FontWeight.w400, wordSpacing: 1.5, color: textColor),
      bodySmall:     GoogleFonts.sourceSans3(fontSize: 12, fontWeight: FontWeight.w400, wordSpacing: 1.2, color: textColor),
      labelLarge:    GoogleFonts.sourceSans3(fontSize: 14, fontWeight: FontWeight.w700, wordSpacing: 1.2, color: textColor),
      labelMedium:   GoogleFonts.sourceSans3(fontSize: 12, fontWeight: FontWeight.w600, wordSpacing: 1.0, color: textColor),
      labelSmall:    GoogleFonts.sourceSans3(fontSize: 10, fontWeight: FontWeight.w600, wordSpacing: 1.0, color: textColor),
    );
  }
}

// Extension to get theme-aware colors easily
extension ThemeExtension on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get bgColor    => isDark ? AppColors.darkBg    : AppColors.lightBg;
  Color get cardColor  => isDark ? AppColors.darkCard   : AppColors.lightCard;
  Color get textColor  => isDark ? AppColors.darkText   : AppColors.lightText;
  Color get subColor   => isDark ? AppColors.darkSub    : AppColors.lightSub;
  Color get hintColor  => isDark ? AppColors.darkHint   : AppColors.lightHint;
  Color get borderColor=> isDark ? AppColors.darkBorder : AppColors.lightBorder;
  Color get border2Color=>isDark ? AppColors.darkBorder2: AppColors.lightBorder2;
  Color get inputBg    => isDark ? AppColors.darkInputBg: AppColors.lightInputBg;
}
