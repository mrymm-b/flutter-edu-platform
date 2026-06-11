import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/config/app_tokens.dart';

// ──────────────────────────────────────────────────────────────────────────────
// GlassCard
//
// Light: plain white card + 1px line border + soft shadow.
// Dark:  BackdropFilter blur(16) + translucent gradient + hairline border
//        + inner top-corner violet glow.
//
// Usage:
//   GlassCard(
//     padding: EdgeInsets.all(16),
//     child: ...,
//   )
// ──────────────────────────────────────────────────────────────────────────────
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.radius = AppTokens.rCard,
    this.lightColor,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final Color? lightColor;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = Tok.of(context);
    final r = BorderRadius.circular(radius);

    if (margin != null) {
      return Padding(
        padding: margin!,
        child: _build(isDark, t, r),
      );
    }
    return _build(isDark, t, r);
  }

  Widget _build(bool isDark, Tok t, BorderRadius r) {
    if (!isDark) {
      return Container(
        padding: padding,
        decoration: BoxDecoration(
          color: lightColor ?? t.card,
          borderRadius: r,
          border: Border.all(color: t.line),
          boxShadow: t.cardShadow,
        ),
        child: child,
      );
    }

    // Dark: glass with blur + gradient + corner glow
    return ClipRRect(
      borderRadius: r,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xCC3A315C), Color(0xD7282142)],
            ),
            borderRadius: r,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.085),
            ),
            boxShadow: [
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
            ],
          ),
          child: Stack(
            children: [
              // Inner top-right violet corner glow
              Positioned(
                top: 0,
                right: 0,
                child: IgnorePointer(
                  child: SizedBox(
                    width: 160,
                    height: 110,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0.6, -0.6),
                          radius: 0.85,
                          colors: [
                            const Color(0xFF967AFA).withValues(alpha: 0.20),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// RowCard — icon tile (42×42) + title/subtitle + trailing chevron
// ──────────────────────────────────────────────────────────────────────────────
class RowCard extends StatelessWidget {
  const RowCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconAccent = false,
    this.onTap,
    this.trailing,
    this.semanticsId,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool iconAccent;   // true → accent-tint icon tile; false → bg2
  final VoidCallback? onTap;
  final Widget? trailing;
  final String? semanticsId;

  @override
  Widget build(BuildContext context) {
    final t = Tok.of(context);
    final iconBg = iconAccent ? t.accentTint : t.bg2;
    final iconColor = iconAccent ? t.accentFg : t.ink2;

    Widget content = GlassCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.cardPad + 1,
        vertical: 15,
      ),
      child: Row(
        children: [
          // Icon tile
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
              border: Theme.of(context).brightness == Brightness.dark
                  ? Border.all(
                      color: Colors.white.withValues(alpha: 0.06),
                    )
                  : null,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: AppTokens.tsCardT,
                    fontWeight: FontWeight.w600,
                    color: t.ink,
                    height: 1.2,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(fontSize: 12, color: t.muted),
                  ),
                ],
              ],
            ),
          ),
          // Trailing
          if (trailing != null)
            trailing!
          else
            Icon(Icons.chevron_left, size: 18, color: t.faint),
        ],
      ),
    );

    if (onTap != null || semanticsId != null) {
      content = Semantics(
        identifier: semanticsId,
        child: GestureDetector(onTap: onTap, child: content),
      );
    }
    return content;
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// DarkBottomNav — frosted glass shelf for dark mode bottom navigation
// Light mode: plain white card + top border (same as existing impl)
// ──────────────────────────────────────────────────────────────────────────────
class ThemedBottomNavShell extends StatelessWidget {
  const ThemedBottomNavShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = Tok.of(context);

    if (!isDark) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: t.line, width: 1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: child,
      );
    }

    // Dark: frosted glass shelf
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF140F26).withValues(alpha: 0.74),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
