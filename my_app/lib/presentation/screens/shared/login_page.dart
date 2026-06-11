import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_tokens.dart';
import '../../../presentation/widgets/atmosphere_background.dart';
import '../../providers/auth_provider.dart';
import '../student/home_page.dart';
import '../student/register_page.dart';
import '../teacher/teacher_home_page.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _phoneController = TextEditingController();
  String? _phoneError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).clearError();
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _onLogin() {
    FocusScope.of(context).unfocus();
    final phone = _phoneController.text.trim();

    if (phone.isEmpty) {
      setState(() => _phoneError = 'الرجاء إدخال رقم الهاتف');
      return;
    }
    if (!RegExp(r'^\d+$').hasMatch(phone)) {
      setState(() => _phoneError = 'الرجاء إدخال أرقام فقط');
      return;
    }
    if (phone.length != 8) {
      setState(() => _phoneError = 'رقم الهاتف غير صحيح');
      return;
    }

    setState(() => _phoneError = null);
    ref.read(authProvider.notifier).loginWithPhone('+973$phone');
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (_, next) {
      if (next.isAuthenticated && next.user != null && context.mounted) {
        final dest =
            next.user!.isTeacher ? const TeacherHomePage() : const HomePage();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => dest),
          (_) => false,
        );
      }
    });

    final authState = ref.watch(authProvider);
    final t = Tok.of(context);
    final hasFieldError = _phoneError != null;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: AtmosphereBackground(
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.screenPad, vertical: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Title block ──────────────────────────────────────
                    Text(
                      'تسجيل الدخول',
                      style: TextStyle(
                        fontSize: AppTokens.tsH1,
                        fontWeight: FontWeight.w700,
                        color: t.ink,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'أهلاً بعودتك — تابع من حيث توقفت',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: t.muted,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Phone field label ────────────────────────────────
                    Text(
                      'رقم الهاتف',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: t.ink2,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ── Phone row: +973 code box + field ─────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Country code
                        Container(
                          width: 78,
                          height: 52,
                          decoration: BoxDecoration(
                            color: t.card,
                            borderRadius:
                                BorderRadius.circular(AppTokens.rInput),
                            border: Border.all(
                              color: hasFieldError
                                  ? const Color(0xFFDC2626)
                                  : t.line,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '+973',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: t.ink,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Phone input
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: Semantics(
                              identifier: 'login_field_phone',
                              child: TextField(
                                controller: _phoneController,
                                keyboardType: TextInputType.number,
                                textDirection: TextDirection.ltr,
                                onSubmitted: (_) => _onLogin(),
                                onChanged: (_) {
                                  if (_phoneError != null) {
                                    setState(() => _phoneError = null);
                                  }
                                  ref
                                      .read(authProvider.notifier)
                                      .clearError();
                                },
                                style: TextStyle(
                                    fontSize: 14.5, color: t.ink),
                                decoration: InputDecoration(
                                  hintText: '3312 3456',
                                  hintStyle: TextStyle(
                                    color: t.faint,
                                    fontSize: 14.5,
                                  ),
                                  filled: true,
                                  fillColor: t.bg2,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppTokens.rInput),
                                    borderSide:
                                        BorderSide(color: t.line),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppTokens.rInput),
                                    borderSide: BorderSide(
                                      color: hasFieldError
                                          ? const Color(0xFFDC2626)
                                          : t.line,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppTokens.rInput),
                                    borderSide: BorderSide(
                                      color: hasFieldError
                                          ? const Color(0xFFDC2626)
                                          : t.accentLine,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // ── Field error ──────────────────────────────────────
                    if (_phoneError != null) ...[
                      const SizedBox(height: 6),
                      Semantics(
                        identifier: 'login_error_field_phone',
                        child: Text(
                          _phoneError!,
                          style: const TextStyle(
                              color: Color(0xFFDC2626), fontSize: 12),
                        ),
                      ),
                    ],

                    // ── Server error ─────────────────────────────────────
                    if (authState.error != null) ...[
                      const SizedBox(height: 14),
                      Semantics(
                        identifier: 'login_error_server',
                        child: Container(
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626).withValues(alpha: 0.08),
                            borderRadius:
                                BorderRadius.circular(AppTokens.rSm),
                            border: Border.all(
                                color: const Color(0xFFDC2626)
                                    .withValues(alpha: 0.25)),
                          ),
                          child: Text(
                            authState.error!,
                            style: const TextStyle(
                                color: Color(0xFFDC2626), fontSize: 13.5),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // ── Login button ─────────────────────────────────────
                    PrimaryButton(
                      label: 'دخول',
                      semanticsId: 'login_btn_submit',
                      isLoading: authState.isLoading,
                      onPressed: _onLogin,
                    ),

                    const SizedBox(height: 16),

                    // ── Register link ────────────────────────────────────
                    Semantics(
                      identifier: 'login_btn_go_to_register',
                      child: Center(
                        child: TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const RegisterPage()),
                          ),
                          child: Text(
                            'ليس لديك حساب؟ سجّل الآن',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: t.accentFg,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
