import 'package:flutter/material.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Design Tokens — One purple family · Light "Quiet A" · Dark "Midnight Indigo atmosphere"
// ──────────────────────────────────────────────────────────────────────────────

class AppTokens {
  AppTokens._();

  // ── LIGHT raw values ───────────────────────────────────────────────────────
  static const Color lAccent      = Color(0xFF5B54C2);
  static const Color lAccentPress = Color(0xFF4A44A6);
  static const Color lAccentDeep  = Color(0xFF37327E);
  static const Color lAccentFg    = Color(0xFF564FB8);
  static const Color lAccentTint  = Color(0xFFECEBFA);
  static const Color lAccentLine  = Color(0xFFD8D5F2);
  static const Color lInk         = Color(0xFF16151D);
  static const Color lInk2        = Color(0xFF3C3B47);
  static const Color lMuted       = Color(0xFF79767F);
  static const Color lFaint       = Color(0xFFAAA8B3);
  static const Color lLine        = Color(0xFFECEBF0);
  static const Color lLine2       = Color(0xFFF4F3F7);
  static const Color lBg          = Color(0xFFFFFFFF);
  static const Color lBg2         = Color(0xFFF7F7FB);
  static const Color lCard        = Color(0xFFFFFFFF);

  // ── DARK raw values ────────────────────────────────────────────────────────
  static const Color dAccent      = Color(0xFF7E5BF0);
  static const Color dAccentPress = Color(0xFF6B49E0);
  static const Color dAccentFg    = Color(0xFFBBA9FF);
  // dAccentTint = dAccent.withValues(alpha:.22) — computed, not const
  static const Color dAccentLine  = Color(0xFF9678FF);
  // dLine  = white.withValues(alpha:.09) — computed
  // dLine2 = white.withValues(alpha:.05) — computed
  static const Color dInk         = Color(0xFFF3F1FB);
  static const Color dInk2        = Color(0xFFCFC9E2);
  static const Color dMuted       = Color(0xFF9A93B5);
  static const Color dFaint       = Color(0xFF6E6890);
  static const Color dBg          = Color(0xFF16122A);
  static const Color dBg2         = Color(0xFF221C39);
  static const Color dCard        = Color(0xFF241E3C);

  // ── Radii ──────────────────────────────────────────────────────────────────
  static const double rSm    = 12.0;
  static const double rMd    = 16.0;
  static const double rLg    = 20.0;
  static const double rPill  = 999.0;
  static const double rInput = 14.0;
  static const double rBtn   = 14.0;
  static const double rBtnSm = 12.0;
  static const double rCard  = 16.0;

  // ── Spacing ────────────────────────────────────────────────────────────────
  static const double screenPad  = 18.0;
  static const double sectionGap = 24.0;
  static const double cardPad    = 15.0;
  static const double cardGap    = 11.0;

  // ── Typography sizes ───────────────────────────────────────────────────────
  static const double tsH1      = 22.0;  // screen title
  static const double tsAppBar  = 18.0;
  static const double tsCardT   = 14.5;  // card title
  static const double tsSecLbl  = 13.0;  // section label
  static const double tsEyebrow = 11.5;  // muted label
  static const double tsBody    = 13.0;
  static const double tsMeta    = 11.5;
  static const double tsBtn     = 14.5;
  static const double tsPrice   = 19.0;
}

// ──────────────────────────────────────────────────────────────────────────────
//  Tok — context-aware token accessor
//  Usage: final t = Tok.of(context);  →  t.accent, t.card, t.ink …
// ──────────────────────────────────────────────────────────────────────────────
class Tok {
  const Tok._({
    required this.isDark,
    required this.accent,
    required this.accentPress,
    required this.accentFg,
    required this.accentTint,
    required this.accentLine,
    required this.ink,
    required this.ink2,
    required this.muted,
    required this.faint,
    required this.line,
    required this.line2,
    required this.bg,
    required this.bg2,
    required this.card,
  });

  final bool isDark;

  // Brand
  final Color accent;
  final Color accentPress;
  final Color accentFg;

  // Pre-computed with correct opacity
  final Color accentTint;  // soft active/selected bg
  final Color accentLine;  // focus ring / accent borders

  // Text hierarchy
  final Color ink;    // primary text
  final Color ink2;   // secondary text
  final Color muted;  // tertiary text
  final Color faint;  // placeholders

  // Surfaces & borders
  final Color line;   // hairlines
  final Color line2;  // dividers
  final Color bg;     // page background
  final Color bg2;    // input fill / inset surface
  final Color card;   // card background

  // ── Factory ────────────────────────────────────────────────────────────────
  static Tok of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _dark : _light;

  // ── Static instances ───────────────────────────────────────────────────────
  static const _light = Tok._(
    isDark:      false,
    accent:      AppTokens.lAccent,
    accentPress: AppTokens.lAccentPress,
    accentFg:    AppTokens.lAccentFg,
    accentTint:  AppTokens.lAccentTint,
    accentLine:  AppTokens.lAccentLine,
    ink:         AppTokens.lInk,
    ink2:        AppTokens.lInk2,
    muted:       AppTokens.lMuted,
    faint:       AppTokens.lFaint,
    line:        AppTokens.lLine,
    line2:       AppTokens.lLine2,
    bg:          AppTokens.lBg,
    bg2:         AppTokens.lBg2,
    card:        AppTokens.lCard,
  );

  // Dark uses runtime-computed opacities where required
  static final _dark = Tok._(
    isDark:      true,
    accent:      AppTokens.dAccent,
    accentPress: AppTokens.dAccentPress,
    accentFg:    AppTokens.dAccentFg,
    accentTint:  AppTokens.dAccent.withValues(alpha: 0.22),
    accentLine:  AppTokens.dAccentLine.withValues(alpha: 0.42),
    ink:         AppTokens.dInk,
    ink2:        AppTokens.dInk2,
    muted:       AppTokens.dMuted,
    faint:       AppTokens.dFaint,
    line:        Colors.white.withValues(alpha: 0.09),
    line2:       Colors.white.withValues(alpha: 0.05),
    bg:          AppTokens.dBg,
    bg2:         AppTokens.dBg2,
    card:        AppTokens.dCard,
  );

  // ── Computed helpers ────────────────────────────────────────────────────────

  List<BoxShadow> get cardShadow => isDark
      ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.7),
            blurRadius: 38,
            offset: const Offset(0, 16),
            spreadRadius: -14,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ]
      : [
          BoxShadow(
            color: const Color(0xFF18162D).withValues(alpha: 0.04),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ];

  // Primary button box shadow (dark only)
  List<BoxShadow> get primaryBtnShadow => isDark
      ? [
          BoxShadow(
            color: AppTokens.dAccent.withValues(alpha: 0.6),
            blurRadius: 28,
            offset: const Offset(0, 12),
            spreadRadius: -8,
          ),
        ]
      : [];

  // Avatar background
  BoxDecoration avatarDecoration(double radius) => isDark
      ? BoxDecoration(
          gradient: const RadialGradient(
            center: Alignment(-0.36, -0.56),
            radius: 0.9,
            colors: [Color(0xFF9A78F6), Color(0xFF5B3FD0)],
            stops: [0.0, 0.72],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTokens.dAccent.withValues(alpha: 0.6),
              blurRadius: 26,
              offset: const Offset(0, 10),
              spreadRadius: -6,
            ),
          ],
        )
      : BoxDecoration(
          color: accentTint,
          shape: BoxShape.circle,
        );
}
