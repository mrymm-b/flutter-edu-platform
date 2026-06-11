import 'package:flutter/material.dart';
import '../../../core/config/app_tokens.dart';
import '../../../presentation/widgets/atmosphere_background.dart';
import '../student/register_page.dart';
import 'login_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Tok.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: AtmosphereBackground(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTokens.screenPad),
              child: Column(
                children: [
                  const Spacer(flex: 3),

                  // ── Logo lockup ─────────────────────────────────────────
                  Semantics(
                    label: 'منصة التعليم الشاملة',
                    child: Image.asset(
                      'assets/logo.png',
                      width: 180,
                      height: 90,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.school_rounded,
                        size: 72,
                        color: t.accent,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Tagline with thin divider rules ─────────────────────
                  ExcludeSemantics(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 36,
                          height: 1.5,
                          color: t.line,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'منصة التعليم الشاملة',
                          style: TextStyle(
                            fontSize: 13.5,
                            color: t.muted,
                            fontWeight: FontWeight.w400,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 36,
                          height: 1.5,
                          color: t.line,
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 3),

                  // ── Primary: تسجيل الدخول ───────────────────────────────
                  PrimaryButton(
                    label: 'تسجيل الدخول',
                    semanticsId: 'welcome_btn_login',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Ghost: إنشاء حساب ───────────────────────────────────
                  GhostButton(
                    label: 'إنشاء حساب',
                    semanticsId: 'welcome_btn_register',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterPage()),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Legal text ──────────────────────────────────────────
                  Text(
                    'بالمتابعة فإنك توافق على الشروط وسياسة الخصوصية',
                    style: TextStyle(
                      fontSize: 11,
                      color: t.faint,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
