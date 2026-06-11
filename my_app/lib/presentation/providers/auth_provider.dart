import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../../domain/models/user.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;
  final bool otpSent;
  final String? pendingPhone;
  final String? pendingName;   // registration only
  final String? pendingGrade;  // registration only

  AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
    this.otpSent = false,
    this.pendingPhone,
    this.pendingName,
    this.pendingGrade,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
    bool? otpSent,
    String? pendingPhone,
    String? pendingName,
    String? pendingGrade,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error, // null intentionally clears error
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      otpSent: otpSent ?? this.otpSent,
      pendingPhone: pendingPhone ?? this.pendingPhone,
      pendingName: pendingName ?? this.pendingName,
      pendingGrade: pendingGrade ?? this.pendingGrade,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState()) {
    // Detect token expiry / remote sign-out while the user is active.
    // When Supabase fires signedOut, clear local state — navigation listeners
    // in each screen will redirect to WelcomePage / LoginPage automatically.
    _authSub = _supabase.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedOut && state.isAuthenticated) {
        debugPrint('[Auth] session expired or revoked — clearing state');
        state = AuthState();
      }
    });
  }

  late final StreamSubscription _authSub;
  final _supabase = Supabase.instance.client;

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }

  // ── Login: Step 1 — send OTP ───────────────────────────────────────────────

  Future<void> sendLoginOtp(String phone) async {
    state = AuthState(isLoading: true);
    try {
      await _supabase.auth.signInWithOtp(phone: phone);
      state = AuthState(otpSent: true, pendingPhone: phone);
    } on AuthException catch (e) {
      debugPrint('[Auth] sendLoginOtp: ${e.message}');
      state = AuthState(error: 'تعذر إرسال رمز التحقق. تحقق من رقم الهاتف وحاول مجدداً.');
    } catch (e) {
      debugPrint('[Auth] sendLoginOtp: $e');
      state = AuthState(error: 'تعذر الاتصال. تحقق من الإنترنت وحاول مجدداً.');
    }
  }

  // ── Login: Step 2 — verify OTP then load profile ───────────────────────────

  Future<void> verifyLoginOtp(String token) async {
    final phone = state.pendingPhone;
    if (phone == null) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _supabase.auth.verifyOTP(
        phone: phone,
        token: token,
        type: OtpType.sms,
      );
      final response = await _supabase
          .from('users')
          .select()
          .eq('phone', phone)
          .maybeSingle();
      if (response == null) {
        await _supabase.auth.signOut();
        state = AuthState(error: 'لم يتم العثور على حساب بهذا الرقم ($phone)');
        return;
      }
      final user = User.fromJson(response);
      debugPrint('[Auth] login verified — role=${user.role}');
      state = AuthState(user: user, isAuthenticated: true);
    } on AuthException catch (e) {
      debugPrint('[Auth] verifyLoginOtp: ${e.message}');
      state = state.copyWith(isLoading: false, error: _mapOtpError(e.message));
    } catch (e) {
      debugPrint('[Auth] verifyLoginOtp: $e');
      state = state.copyWith(isLoading: false, error: 'حدث خطأ، حاول مجدداً');
    }
  }

  // ── Register: Step 1 — check duplicate + send OTP ──────────────────────────

  Future<void> sendRegisterOtp({
    required String phone,
    required String fullName,
    required String gradeLevel,
  }) async {
    state = AuthState(isLoading: true);
    try {
      final existing = await _supabase
          .from('users')
          .select('id')
          .eq('phone', phone)
          .maybeSingle();
      if (existing != null) {
        state = AuthState(error: 'هذا الرقم مسجل بالفعل. يرجى تسجيل الدخول.');
        return;
      }
      await _supabase.auth.signInWithOtp(phone: phone);
      state = AuthState(
        otpSent: true,
        pendingPhone: phone,
        pendingName: fullName,
        pendingGrade: gradeLevel,
      );
    } on AuthException catch (e) {
      debugPrint('[Auth] sendRegisterOtp: ${e.message}');
      state = AuthState(error: 'تعذر إرسال رمز التحقق. تحقق من رقم الهاتف وحاول مجدداً.');
    } catch (e) {
      debugPrint('[Auth] sendRegisterOtp: $e');
      state = AuthState(error: 'تعذر الاتصال. تحقق من الإنترنت وحاول مجدداً.');
    }
  }

  // ── Register: Step 2 — verify OTP then create user row ─────────────────────

  Future<void> verifyRegisterOtp(String token) async {
    final phone = state.pendingPhone;
    final name = state.pendingName;
    final grade = state.pendingGrade;
    if (phone == null || name == null || grade == null) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _supabase.auth.verifyOTP(
        phone: phone,
        token: token,
        type: OtpType.sms,
      );
      final response = await _supabase.from('users').insert({
        'phone': phone,
        'full_name': name,
        'role': 'student',
        'grade_level': grade,
        'phone_verified': true,
      }).select().single();
      final user = User.fromJson(response);
      debugPrint('[Auth] registered — id=${user.id}');
      state = AuthState(user: user, isAuthenticated: true);
    } on AuthException catch (e) {
      debugPrint('[Auth] verifyRegisterOtp: ${e.message}');
      state = state.copyWith(isLoading: false, error: _mapOtpError(e.message));
    } catch (e) {
      debugPrint('[Auth] verifyRegisterOtp: $e');
      state = state.copyWith(
          isLoading: false, error: 'حدث خطأ أثناء إنشاء الحساب. تواصل مع الدعم.');
    }
  }

  // ── Resend OTP ─────────────────────────────────────────────────────────────

  Future<void> resendOtp() async {
    final phone = state.pendingPhone;
    if (phone == null) return;
    try {
      await _supabase.auth.signInWithOtp(phone: phone);
    } on AuthException catch (e) {
      debugPrint('[Auth] resendOtp: ${e.message}');
      state = state.copyWith(error: _mapOtpError(e.message));
    } catch (e) {
      debugPrint('[Auth] resendOtp: $e');
      state = state.copyWith(error: 'تعذر إعادة الإرسال. حاول بعد قليل.');
    }
  }

  // ── Dev bypass — direct DB lookup, no OTP ─────────────────────────────────
  // Remove these two methods and restore OTP pages before production.

  Future<void> loginWithPhone(String phone) async {
    state = AuthState(isLoading: true);
    try {
      debugPrint('[Auth] loginWithPhone: signing in anonymously…');
      await _supabase.auth.signInAnonymously();
      debugPrint('[Auth] loginWithPhone: querying users for phone=$phone');
      final response = await _supabase
          .from('users')
          .select()
          .eq('phone', phone)
          .maybeSingle();
      debugPrint('[Auth] loginWithPhone: query response=$response');
      if (response == null) {
        state = AuthState(error: 'لم يتم العثور على حساب بهذا الرقم ($phone)');
        return;
      }
      final user = User.fromJson(response);
      debugPrint('[Auth] login — role=${user.role}');
      state = AuthState(user: user, isAuthenticated: true);
    } on AuthException catch (e) {
      debugPrint('[Auth] loginWithPhone AuthException: status=${e.statusCode} message=${e.message}');
      state = AuthState(error: 'تعذر تسجيل الدخول. تحقق من رقم الهاتف وحاول مجدداً.');
    } on PostgrestException catch (e) {
      debugPrint('[Auth] loginWithPhone PostgrestException: code=${e.code} message=${e.message} details=${e.details} hint=${e.hint}');
      state = AuthState(error: 'تعذر تسجيل الدخول. تحقق من رقم الهاتف وحاول مجدداً.');
    } catch (e, st) {
      debugPrint('[Auth] loginWithPhone unknown error: $e\n$st');
      state = AuthState(error: 'تعذر الاتصال. تحقق من الإنترنت وحاول مجدداً.');
    }
  }

  Future<void> registerWithPhone({
    required String phone,
    required String fullName,
    required String gradeLevel,
  }) async {
    state = AuthState(isLoading: true);
    try {
      await _supabase.auth.signInAnonymously();
      final existing = await _supabase
          .from('users')
          .select('id')
          .eq('phone', phone)
          .maybeSingle();
      if (existing != null) {
        state = AuthState(error: 'هذا الرقم مسجل بالفعل. يرجى تسجيل الدخول.');
        return;
      }
      final response = await _supabase.from('users').insert({
        'phone': phone,
        'full_name': fullName,
        'role': 'student',
        'grade_level': gradeLevel,
        'phone_verified': false,
      }).select().single();
      final user = User.fromJson(response);
      debugPrint('[Auth] registered — id=${user.id}');
      state = AuthState(user: user, isAuthenticated: true);
    } on AuthException catch (e) {
      debugPrint('[Auth] registerWithPhone: ${e.message}');
      state = AuthState(error: 'تعذر إنشاء الحساب. حاول مجدداً.');
    } catch (e) {
      debugPrint('[Auth] registerWithPhone: $e');
      state = AuthState(error: 'تعذر الاتصال. تحقق من الإنترنت وحاول مجدداً.');
    }
  }

  // ── Logout ─────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      // Force-clear local session even if the server request fails
      // (e.g. no internet). The token will eventually expire server-side.
      debugPrint('[Auth] signOut error (ignored): $e');
    }
    state = AuthState();
  }

  // ── Clear error ────────────────────────────────────────────────────────────

  void clearError() {
    if (state.error != null) state = state.copyWith(error: null);
  }

  // ── Update profile ─────────────────────────────────────────────────────────

  Future<void> updateProfile({
    String? fullName,
    String? avatarUrl,
    String? gradeLevel,
  }) async {
    if (state.user == null) return;
    try {
      await _supabase.from('users').update({
        if (fullName != null) 'full_name': fullName,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (gradeLevel != null) 'grade_level': gradeLevel,
      }).eq('id', state.user!.id);
      state = state.copyWith(
        user: state.user!.copyWith(
          fullName: fullName ?? state.user!.fullName,
          avatarUrl: avatarUrl ?? state.user!.avatarUrl,
          gradeLevel: gradeLevel ?? state.user!.gradeLevel,
        ),
      );
    } catch (_) {
      state = state.copyWith(error: 'فشل تحديث الملف الشخصي');
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _mapOtpError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('invalid') ||
        lower.contains('expired') ||
        lower.contains('incorrect')) {
      return 'رمز التحقق غير صحيح أو انتهت صلاحيته. حاول مجدداً.';
    }
    if (lower.contains('rate') || lower.contains('limit')) {
      return 'تجاوزت الحد المسموح. انتظر دقيقة ثم حاول.';
    }
    return 'حدث خطأ في التحقق. حاول مجدداً.';
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
