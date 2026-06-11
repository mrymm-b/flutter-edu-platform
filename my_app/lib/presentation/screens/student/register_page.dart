import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_tokens.dart';
import '../../../presentation/widgets/atmosphere_background.dart';
import '../../providers/auth_provider.dart';
import 'home_page.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _nameController  = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedGrade  = 'grade_11';
  String? _nameError;
  String? _phoneError;

  static const _grades = [
    ('grade_10', 'الصف العاشر'),
    ('grade_11', 'الصف الحادي عشر'),
    ('grade_12', 'الصف الثاني عشر'),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onRegister() {
    FocusScope.of(context).unfocus();
    final name  = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    String? nameErr;
    if (name.isEmpty) {
      nameErr = 'الاسم الكامل مطلوب';
    } else if (name.length < 2) {
      nameErr = 'الاسم قصير جداً';
    }

    String? phoneErr;
    if (phone.isEmpty) {
      phoneErr = 'الرجاء إدخال رقم الهاتف';
    } else if (!RegExp(r'^\d+$').hasMatch(phone)) {
      phoneErr = 'الرجاء إدخال أرقام فقط';
    } else if (phone.length != 8) {
      phoneErr = 'رقم الهاتف غير صحيح';
    }

    if (nameErr != null || phoneErr != null) {
      setState(() { _nameError = nameErr; _phoneError = phoneErr; });
      return;
    }

    setState(() { _nameError = null; _phoneError = null; });
    ref.read(authProvider.notifier).registerWithPhone(
      phone: '+973$phone',
      fullName: name,
      gradeLevel: _selectedGrade,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (_, next) {
      if (next.isAuthenticated && context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
          (_) => false,
        );
      }
    });

    final authState = ref.watch(authProvider);
    final t = Tok.of(context);

    InputDecoration inputDeco({
      required String hint,
      required bool hasError,
      TextStyle? style,
    }) =>
        InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: t.faint, fontSize: 14.5),
          filled: true,
          fillColor: t.bg2,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTokens.rInput),
            borderSide: BorderSide(color: t.line),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTokens.rInput),
            borderSide: BorderSide(
              color: hasError ? const Color(0xFFDC2626) : t.line,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTokens.rInput),
            borderSide: BorderSide(
              color: hasError ? const Color(0xFFDC2626) : t.accentLine,
              width: 1.5,
            ),
          ),
        );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: AtmosphereBackground(
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.screenPad, vertical: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Title block ──────────────────────────────────────
                    Text(
                      'إنشاء حساب',
                      style: TextStyle(
                        fontSize: AppTokens.tsH1,
                        fontWeight: FontWeight.w700,
                        color: t.ink,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'سجّل الآن وابدأ رحلتك التعليمية',
                      style: TextStyle(fontSize: 13.5, color: t.muted),
                    ),

                    const SizedBox(height: 32),

                    // ── الاسم الكامل ─────────────────────────────────────
                    Text(
                      'الاسم الكامل',
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: t.ink2),
                    ),
                    const SizedBox(height: 8),
                    Semantics(
                      identifier: 'register_field_name',
                      child: TextField(
                        controller: _nameController,
                        keyboardType: TextInputType.name,
                        style: TextStyle(fontSize: 14.5, color: t.ink),
                        onChanged: (_) {
                          if (_nameError != null) setState(() => _nameError = null);
                        },
                        decoration: inputDeco(
                            hint: 'أحمد محمد',
                            hasError: _nameError != null),
                      ),
                    ),
                    if (_nameError != null) ...[
                      const SizedBox(height: 6),
                      Semantics(
                        identifier: 'register_error_field_name',
                        child: Text(_nameError!,
                            style: const TextStyle(
                                color: Color(0xFFDC2626), fontSize: 12)),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // ── رقم الهاتف ───────────────────────────────────────
                    Text(
                      'رقم الهاتف',
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: t.ink2),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 78,
                          height: 52,
                          decoration: BoxDecoration(
                            color: t.card,
                            borderRadius: BorderRadius.circular(AppTokens.rInput),
                            border: Border.all(
                              color: _phoneError != null
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
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: Semantics(
                              identifier: 'register_field_phone',
                              child: TextField(
                                controller: _phoneController,
                                keyboardType: TextInputType.number,
                                textDirection: TextDirection.ltr,
                                style: TextStyle(fontSize: 14.5, color: t.ink),
                                onChanged: (_) {
                                  if (_phoneError != null) setState(() => _phoneError = null);
                                  ref.read(authProvider.notifier).clearError();
                                },
                                decoration: inputDeco(
                                    hint: '3312 3456',
                                    hasError: _phoneError != null),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_phoneError != null) ...[
                      const SizedBox(height: 6),
                      Semantics(
                        identifier: 'register_error_field_phone',
                        child: Text(_phoneError!,
                            style: const TextStyle(
                                color: Color(0xFFDC2626), fontSize: 12)),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // ── المرحلة الدراسية ─────────────────────────────────
                    Text(
                      'المرحلة الدراسية',
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: t.ink2),
                    ),
                    const SizedBox(height: 8),
                    Semantics(
                      identifier: 'register_field_grade',
                      child: Container(
                        decoration: BoxDecoration(
                          color: t.bg2,
                          borderRadius: BorderRadius.circular(AppTokens.rInput),
                          border: Border.all(color: t.line),
                        ),
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedGrade,
                          isExpanded: true,
                          dropdownColor: t.card,
                          style: TextStyle(fontSize: 14.5, color: t.ink),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                          ),
                          items: _grades
                              .map((g) => DropdownMenuItem<String>(
                                    value: g.$1,
                                    child: Text(g.$2),
                                  ))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _selectedGrade = v);
                          },
                        ),
                      ),
                    ),

                    // ── Server error ─────────────────────────────────────
                    if (authState.error != null) ...[
                      const SizedBox(height: 14),
                      Semantics(
                        identifier: 'register_error_server',
                        child: Container(
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(AppTokens.rSm),
                            border: Border.all(
                                color: const Color(0xFFDC2626)
                                    .withValues(alpha: 0.25)),
                          ),
                          child: Text(authState.error!,
                              style: const TextStyle(
                                  color: Color(0xFFDC2626), fontSize: 13.5)),
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // ── Submit ───────────────────────────────────────────
                    PrimaryButton(
                      label: 'إنشاء الحساب',
                      semanticsId: 'register_btn_submit',
                      isLoading: authState.isLoading,
                      onPressed: _onRegister,
                    ),

                    const SizedBox(height: 20),

                    Semantics(
                      identifier: 'register_btn_go_to_login',
                      child: Center(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'لديك حساب؟ سجّل دخولك',
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
