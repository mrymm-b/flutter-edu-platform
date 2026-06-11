import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../student/home_page.dart';
import '../teacher/teacher_home_page.dart';

const _kPurple = Color(0xFF6264A7);
const _kDark   = Color(0xFF464775);
const _kBg     = Color(0xFFF3F2F1);

class OtpVerificationPage extends ConsumerStatefulWidget {
  final bool isLogin;

  const OtpVerificationPage({super.key, required this.isLogin});

  @override
  ConsumerState<OtpVerificationPage> createState() =>
      _OtpVerificationPageState();
}

class _OtpVerificationPageState extends ConsumerState<OtpVerificationPage> {
  final _otpController = TextEditingController();
  Timer? _resendTimer;
  int _secondsLeft = 60;
  String? _otpError;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _resendTimer?.cancel();
    setState(() => _secondsLeft = 60);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft == 0) {
        t.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _onVerify() {
    final token = _otpController.text.trim();

    if (token.isEmpty) {
      setState(() => _otpError = 'أدخل رمز التحقق');
      return;
    }
    if (token.length < 6) {
      setState(() => _otpError = 'الرمز يجب أن يكون 6 أرقام');
      return;
    }

    setState(() => _otpError = null);

    if (widget.isLogin) {
      ref.read(authProvider.notifier).verifyLoginOtp(token);
    } else {
      ref.read(authProvider.notifier).verifyRegisterOtp(token);
    }
  }

  void _onResend() {
    _otpController.clear();
    setState(() => _otpError = null);
    ref.read(authProvider.notifier).resendOtp();
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.isAuthenticated && next.user != null && context.mounted) {
        final destination =
            next.user!.isTeacher ? const TeacherHomePage() : const HomePage();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => destination),
          (route) => false,
        );
      }
    });

    final authState = ref.watch(authProvider);
    final phone = authState.pendingPhone ?? '';
    final hasFieldError = _otpError != null;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _kBg,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Back button — 44pt touch target
                  Align(
                    alignment: Alignment.centerRight,
                    child: Semantics(
                      identifier: 'otp_btn_back',
                      child: GestureDetector(
                        onTap: authState.isLoading
                            ? null
                            : () => Navigator.pop(context),
                        child: SizedBox(
                          height: 44,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.arrow_back_ios_new,
                                  size: 14,
                                  color: authState.isLoading
                                      ? const Color(0xFF9CA3AF)
                                      : _kPurple),
                              const SizedBox(width: 4),
                              Text(
                                'تغيير رقم الهاتف',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: authState.isLoading
                                      ? const Color(0xFF9CA3AF)
                                      : _kPurple,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Lock icon
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_kDark, _kPurple],
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.lock_outline,
                          color: Colors.white, size: 36),
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'أدخل رمز التحقق',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'أُرسل رمز مكوّن من 6 أرقام إلى\n$phone',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // OTP input
                  Semantics(
                    identifier: 'otp_field_code',
                    child: TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 6,
                      autofocus: true,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (value) {
                        if (_otpError != null) setState(() => _otpError = null);
                        if (value.length == 6) _onVerify();
                      },
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                        letterSpacing: 12,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: '------',
                        hintStyle: const TextStyle(
                          color: Color(0xFFD1D5DB),
                          fontSize: 28,
                          letterSpacing: 12,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: hasFieldError
                                ? const Color(0xFFDC2626)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: hasFieldError
                                ? const Color(0xFFDC2626)
                                : _kPurple,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 18),
                      ),
                      onSubmitted: (_) => _onVerify(),
                    ),
                  ),

                  // Inline OTP field error
                  if (_otpError != null) ...[
                    const SizedBox(height: 8),
                    Semantics(
                      identifier: 'otp_error_field_code',
                      child: Text(
                        _otpError!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Color(0xFFDC2626), fontSize: 12),
                      ),
                    ),
                  ],

                  // Server / auth error
                  if (authState.error != null) ...[
                    const SizedBox(height: 14),
                    Semantics(
                      identifier: 'otp_error_server',
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Text(
                          authState.error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Color(0xFFDC2626), fontSize: 14),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Verify button
                  Semantics(
                    identifier: 'otp_btn_verify',
                    child: SizedBox(
                      width: double.infinity,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: authState.isLoading
                              ? null
                              : const LinearGradient(
                                  colors: [_kDark, _kPurple],
                                  begin: Alignment.centerRight,
                                  end: Alignment.centerLeft,
                                ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ElevatedButton(
                          onPressed: authState.isLoading ? null : _onVerify,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: authState.isLoading
                                ? Colors.grey.withValues(alpha: 0.3)
                                : Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: authState.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'تحقق',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Resend
                  Center(
                    child: _secondsLeft > 0
                        ? Text(
                            'إعادة الإرسال بعد $_secondsLeft ثانية',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF9CA3AF),
                            ),
                          )
                        : Semantics(
                            identifier: 'otp_btn_resend',
                            child: TextButton(
                              onPressed:
                                  authState.isLoading ? null : _onResend,
                              child: const Text(
                                'إعادة إرسال الرمز',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _kPurple,
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
    );
  }
}
