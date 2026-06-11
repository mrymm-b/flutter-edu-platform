import 'package:flutter/material.dart';
import '../../core/config/app_tokens.dart';

// ──────────────────────────────────────────────────────────────────────────────
// AtmosphereBackground
//
// Light: transparent pass-through (Scaffold bg handles the white).
// Dark:  deep indigo base gradient + 3 soft violet radial blooms.
//
// Usage:
//   Scaffold(
//     backgroundColor: Colors.transparent,
//     body: AtmosphereBackground(child: /* content */),
//   )
// ──────────────────────────────────────────────────────────────────────────────
class AtmosphereBackground extends StatelessWidget {
  const AtmosphereBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (Theme.of(context).brightness != Brightness.dark) {
      return ColoredBox(color: AppTokens.lBg, child: child);
    }

    return Stack(
      children: [
        // ── Base: deep indigo gradient (fixed, does not scroll) ───────────────
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1C1737),
                  Color(0xFF16122A),
                  Color(0xFF110D20),
                ],
                stops: [0.0, 0.46, 1.0],
              ),
            ),
          ),
        ),

        // ── Bloom 1: top-center violet (135% × 55%, centre top) ──────────────
        Positioned(
          top: -60,
          left: 0,
          right: 0,
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.55,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 0.7,
                  colors: [
                    const Color(0xFF8B5CF6).withValues(alpha: 0.32),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),

        // ── Bloom 2: top-right (90% × 45%) ───────────────────────────────────
        Positioned(
          top: -40,
          right: -100,
          child: SizedBox(
            width: MediaQuery.sizeOf(context).width * 0.85,
            height: MediaQuery.sizeOf(context).height * 0.45,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.5, -0.5),
                  radius: 0.8,
                  colors: [
                    const Color(0xFF6350E0).withValues(alpha: 0.22),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),

        // ── Bloom 3: left side (80% × 52%) ───────────────────────────────────
        Positioned(
          top: 80,
          left: -100,
          child: SizedBox(
            width: MediaQuery.sizeOf(context).width * 0.7,
            height: MediaQuery.sizeOf(context).height * 0.52,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.3, 0),
                  radius: 0.7,
                  colors: [
                    const Color(0xFFA860EC).withValues(alpha: 0.14),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),

        // ── Content ────────────────────────────────────────────────────────────
        child,
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// PrimaryButton helper — flat on light, gradient + glow on dark
// ──────────────────────────────────────────────────────────────────────────────
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.height = 50,
    this.radius = AppTokens.rBtn,
    this.semanticsId,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;
  final double radius;
  final String? semanticsId;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = Tok.of(context);

    Widget btn = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        foregroundColor: Colors.white,
        minimumSize: Size(double.infinity, height),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        elevation: 0,
        disabledBackgroundColor: Colors.transparent,
      ),
      child: isLoading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2.5),
            )
          : Text(
              label,
              style: const TextStyle(
                  fontSize: AppTokens.tsBtn, fontWeight: FontWeight.w600),
            ),
    );

    final decoration = isDark
        ? BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF9168F5), Color(0xFF7E5BF0), Color(0xFF6A47E2)],
              stops: [0.0, 0.52, 1.0],
            ),
            borderRadius: BorderRadius.circular(radius),
            boxShadow: [
              BoxShadow(
                color: AppTokens.dAccent.withValues(alpha: 0.60),
                blurRadius: 28,
                offset: const Offset(0, 12),
                spreadRadius: -8,
              ),
            ],
          )
        : BoxDecoration(
            color: isLoading
                ? t.accent.withValues(alpha: 0.4)
                : t.accent,
            borderRadius: BorderRadius.circular(radius),
          );

    Widget result = SizedBox(
      width: double.infinity,
      height: height,
      child: DecoratedBox(
        decoration: decoration,
        child: btn,
      ),
    );

    if (semanticsId != null) {
      result = Semantics(identifier: semanticsId, child: result);
    }
    return result;
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// GhostButton — card bg + line border, accentFg text
// ──────────────────────────────────────────────────────────────────────────────
class GhostButton extends StatelessWidget {
  const GhostButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 50,
    this.radius = AppTokens.rBtn,
    this.semanticsId,
  });

  final String label;
  final VoidCallback? onPressed;
  final double height;
  final double radius;
  final String? semanticsId;

  @override
  Widget build(BuildContext context) {
    final t = Tok.of(context);
    Widget btn = SizedBox(
      width: double.infinity,
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: t.accentFg,
          backgroundColor: t.card,
          side: BorderSide(color: t.line),
          minimumSize: Size(double.infinity, height),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius)),
        ),
        child: Text(
          label,
          style: TextStyle(
              fontSize: AppTokens.tsBtn,
              fontWeight: FontWeight.w600,
              color: t.accentFg),
        ),
      ),
    );
    if (semanticsId != null) {
      btn = Semantics(identifier: semanticsId, child: btn);
    }
    return btn;
  }
}
