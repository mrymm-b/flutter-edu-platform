import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_tokens.dart';

// ──────────────────────────────────────────────────────────────────────────────
// AppTheme — builds ThemeData for light and dark from design tokens.
// Font: IBM Plex Sans Arabic via google_fonts.
// ──────────────────────────────────────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  // ── Light ──────────────────────────────────────────────────────────────────
  static ThemeData get light {
    final base = _textTheme(Brightness.light);
    return ThemeData(
      useMaterial3: false,
      brightness: Brightness.light,
      primaryColor: AppTokens.lAccent,
      scaffoldBackgroundColor: AppTokens.lBg,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary:          AppTokens.lAccent,
        onPrimary:        Colors.white,
        secondary:        AppTokens.lAccentFg,
        onSecondary:      Colors.white,
        surface:          AppTokens.lCard,
        onSurface:        AppTokens.lInk,
        error:            Color(0xFFDC2626),
        onError:          Colors.white,
      ),
      textTheme: base,
      appBarTheme: AppBarTheme(
        backgroundColor: AppTokens.lBg,
        foregroundColor: AppTokens.lInk,
        elevation: 0,
        titleTextStyle: base.titleLarge?.copyWith(
          fontSize: AppTokens.tsAppBar,
          fontWeight: FontWeight.w700,
          color: AppTokens.lInk,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTokens.lAccent,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.rBtn),
          ),
          textStyle: base.labelLarge?.copyWith(
            fontSize: AppTokens.tsBtn,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTokens.lAccentFg,
          side: const BorderSide(color: AppTokens.lLine),
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.rBtn),
          ),
          textStyle: base.labelLarge?.copyWith(
            fontSize: AppTokens.tsBtn,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppTokens.lBg2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.rInput),
          borderSide: const BorderSide(color: AppTokens.lLine),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.rInput),
          borderSide: const BorderSide(color: AppTokens.lLine),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.rInput),
          borderSide: const BorderSide(color: AppTokens.lAccentLine, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: TextStyle(color: AppTokens.lFaint, fontSize: 14.5),
        labelStyle: TextStyle(color: AppTokens.lInk2, fontSize: 12.5, fontWeight: FontWeight.w600),
      ),
      dividerColor: AppTokens.lLine,
      iconTheme: const IconThemeData(color: AppTokens.lInk, size: 22),
      cardColor: AppTokens.lCard,
      chipTheme: ChipThemeData(
        backgroundColor: AppTokens.lCard,
        selectedColor: AppTokens.lAccent,
        side: const BorderSide(color: AppTokens.lLine),
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppTokens.lAccent,
        linearTrackColor: AppTokens.lLine,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppTokens.lBg,
        selectedItemColor: AppTokens.lAccentFg,
        unselectedItemColor: AppTokens.lFaint,
        elevation: 0,
      ),
    );
  }

  // ── Dark ───────────────────────────────────────────────────────────────────
  static ThemeData get dark {
    final base = _textTheme(Brightness.dark);
    return ThemeData(
      useMaterial3: false,
      brightness: Brightness.dark,
      primaryColor: AppTokens.dAccent,
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary:          AppTokens.dAccent,
        onPrimary:        Colors.white,
        secondary:        AppTokens.dAccentFg,
        onSecondary:      Colors.white,
        surface:          AppTokens.dCard,
        onSurface:        AppTokens.dInk,
        error:            const Color(0xFFFF6B6B),
        onError:          Colors.white,
      ),
      textTheme: base,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppTokens.dInk,
        elevation: 0,
        titleTextStyle: base.titleLarge?.copyWith(
          fontSize: AppTokens.tsAppBar,
          fontWeight: FontWeight.w700,
          color: AppTokens.dInk,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTokens.dAccent,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.rBtn),
          ),
          textStyle: base.labelLarge?.copyWith(
            fontSize: AppTokens.tsBtn,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTokens.dAccentFg,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.rBtn),
          ),
          textStyle: base.labelLarge?.copyWith(
            fontSize: AppTokens.tsBtn,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.045),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.rInput),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.rInput),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.rInput),
          borderSide: BorderSide(
            color: AppTokens.dAccentLine.withValues(alpha: 0.42),
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: TextStyle(color: AppTokens.dFaint, fontSize: 14.5),
        labelStyle: TextStyle(color: AppTokens.dInk2, fontSize: 12.5, fontWeight: FontWeight.w600),
      ),
      dividerColor: Colors.white.withValues(alpha: 0.09),
      iconTheme: const IconThemeData(color: AppTokens.dInk, size: 22),
      cardColor: AppTokens.dCard,
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white.withValues(alpha: 0.04),
        selectedColor: AppTokens.dAccent,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.09)),
        labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTokens.dInk2),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppTokens.dAccent,
        linearTrackColor: Colors.white.withValues(alpha: 0.09),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: AppTokens.dAccentFg,
        unselectedItemColor: AppTokens.dFaint,
        elevation: 0,
      ),
    );
  }

  // ── Shared text theme ──────────────────────────────────────────────────────
  static TextTheme _textTheme(Brightness brightness) {
    final base = brightness == Brightness.dark
        ? const TextTheme().apply(bodyColor: AppTokens.dInk, displayColor: AppTokens.dInk)
        : const TextTheme().apply(bodyColor: AppTokens.lInk, displayColor: AppTokens.lInk);

    TextStyle ibm(TextStyle? s) =>
        GoogleFonts.ibmPlexSansArabic(textStyle: s ?? const TextStyle());

    return base.copyWith(
      displayLarge:  ibm(base.displayLarge),
      displayMedium: ibm(base.displayMedium),
      displaySmall:  ibm(base.displaySmall),
      headlineLarge: ibm(base.headlineLarge),
      headlineMedium:ibm(base.headlineMedium),
      headlineSmall: ibm(base.headlineSmall),
      titleLarge:    ibm(base.titleLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.w700)),
      titleMedium:   ibm(base.titleMedium?.copyWith(fontSize: 15, fontWeight: FontWeight.w600)),
      titleSmall:    ibm(base.titleSmall?.copyWith(fontSize: 13, fontWeight: FontWeight.w600)),
      bodyLarge:     ibm(base.bodyLarge?.copyWith(fontSize: 14.5)),
      bodyMedium:    ibm(base.bodyMedium?.copyWith(fontSize: 13)),
      bodySmall:     ibm(base.bodySmall?.copyWith(fontSize: 11.5)),
      labelLarge:    ibm(base.labelLarge?.copyWith(fontSize: 14.5, fontWeight: FontWeight.w600)),
      labelMedium:   ibm(base.labelMedium?.copyWith(fontSize: 12, fontWeight: FontWeight.w500)),
      labelSmall:    ibm(base.labelSmall?.copyWith(fontSize: 11, fontWeight: FontWeight.w500)),
    );
  }

  // ── Legacy compat: colours used by teacher pages via AppTheme.* ───────────
  // Keep the same names but now they just return the light-token equivalents.
  static const Color primaryBlue   = AppTokens.lAccent;
  static const Color darkBlue      = AppTokens.lAccentDeep;
  static const Color green         = Color(0xFF16A34A);
  static const Color background    = AppTokens.lBg2;
  static const Color cardBackground= AppTokens.lCard;
  static const Color textPrimary   = AppTokens.lInk;
  static const Color textSecondary = AppTokens.lMuted;
  static const Color textLight     = AppTokens.lFaint;
  static const Color borderLight   = AppTokens.lLine;
  static const Color tintBg        = AppTokens.lAccentTint;
  static const Color tintBorder    = AppTokens.lAccentLine;
  static const Color yellow        = Color(0xFFFBBF24);
  static const Color cardDark      = Color(0xFF1E293B);

  static const headerGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [AppTokens.lAccentDeep, AppTokens.lAccent],
  );

  // Legacy text styles (Cairo → IBM Plex Sans Arabic, same sizes)
  static TextStyle get heading1 => GoogleFonts.ibmPlexSansArabic(
        fontSize: 24, fontWeight: FontWeight.w700, color: AppTokens.lInk);
  static TextStyle get heading2 => GoogleFonts.ibmPlexSansArabic(
        fontSize: 20, fontWeight: FontWeight.w700, color: AppTokens.lInk);
  static TextStyle get bodyMedium => GoogleFonts.ibmPlexSansArabic(
        fontSize: 14, fontWeight: FontWeight.w400, color: AppTokens.lMuted);
  static TextStyle get caption => GoogleFonts.ibmPlexSansArabic(
        fontSize: 12, fontWeight: FontWeight.w500, color: AppTokens.lMuted);

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF18162D).withValues(alpha: 0.04),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get buttonShadow => [
        BoxShadow(
          color: AppTokens.lAccent.withValues(alpha: 0.28),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
}

