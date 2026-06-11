import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/config/tap_config.dart';
import 'auth_provider.dart';
import 'cart_provider.dart';
import 'enrollments_provider.dart';
import 'book_purchases_provider.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

enum CheckoutStatus {
  idle,
  processing,          // Creating Tap charge via Edge Function
  pendingVerification, // URL opened — user is on Tap's hosted page
  verifying,           // Verifying charge via Edge Function
  success,
  failed,
}

class CheckoutState {
  final CheckoutStatus status;
  final String? error;
  final String? tapChargeId;

  CheckoutState({
    this.status = CheckoutStatus.idle,
    this.error,
    this.tapChargeId,
  });

  CheckoutState copyWith({
    CheckoutStatus? status,
    String? error,
    String? tapChargeId,
  }) {
    return CheckoutState(
      status: status ?? this.status,
      error: error,
      tapChargeId: tapChargeId ?? this.tapChargeId,
    );
  }

  bool get isIdle => status == CheckoutStatus.idle;
  bool get isProcessing => status == CheckoutStatus.processing;
  bool get isPendingVerification =>
      status == CheckoutStatus.pendingVerification;
  bool get isVerifying => status == CheckoutStatus.verifying;
  bool get isSuccess => status == CheckoutStatus.success;
  bool get isFailed => status == CheckoutStatus.failed;
  bool get isBusy => isProcessing || isVerifying;
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class CheckoutNotifier extends StateNotifier<CheckoutState> {
  CheckoutNotifier(this.ref) : super(CheckoutState());

  final Ref ref;
  final _supabase = Supabase.instance.client;

  /// Step 1 — Create a Tap charge via Edge Function and open Tap's hosted page.
  Future<void> initCheckout(List<CartItemDetail> items, double total) async {
    final authState = ref.read(authProvider);
    if (authState.user == null) {
      state = state.copyWith(
          status: CheckoutStatus.failed, error: 'يجب تسجيل الدخول أولاً');
      return;
    }

    state = state.copyWith(status: CheckoutStatus.processing);

    try {
      final user = authState.user!;
      final localPhone = user.phone.startsWith('+973')
          ? user.phone.substring(4)
          : user.phone;
      final firstName = user.fullName.split(' ').first;

      final result = await _supabase.functions.invoke(
        TapConfig.edgeFunction,
        body: {
          'action': 'create-charge',
          'amount': total,
          'currency': TapConfig.currency,
          'customerFirstName': firstName,
          'customerCountryCode': '973',
          'customerPhone': localPhone,
          'description': 'منصة تعليمية - دورات أونلاين',
          'redirectUrl': TapConfig.redirectUrl,
        },
      );

      final data = result.data as Map<String, dynamic>;
      final chargeId = data['chargeId'] as String;
      final checkoutUrl = data['checkoutUrl'] as String;

      await launchUrl(
        Uri.parse(checkoutUrl),
        mode: LaunchMode.externalApplication,
      );

      state = state.copyWith(
        status: CheckoutStatus.pendingVerification,
        tapChargeId: chargeId,
      );
    } catch (e) {
      state = state.copyWith(
        status: CheckoutStatus.failed,
        error: 'تعذر الاتصال ببوابة الدفع. تحقق من الاتصال وحاول مجدداً.',
      );
    }
  }

  /// Step 2 — After user returns from Tap, verify the charge and fulfil order.
  Future<void> verifyAndFulfill(List<CartItemDetail> items) async {
    final chargeId = state.tapChargeId;
    if (chargeId == null) return;

    final authState = ref.read(authProvider);
    if (authState.user == null) return;

    state = state.copyWith(status: CheckoutStatus.verifying);

    try {
      final result = await _supabase.functions.invoke(
        TapConfig.edgeFunction,
        body: {
          'action': 'verify-charge',
          'chargeId': chargeId,
        },
      );

      final data = result.data as Map<String, dynamic>;
      final tapStatus = data['status'] as String? ?? '';

      if (tapStatus != 'CAPTURED') {
        final msg = switch (tapStatus) {
          'DECLINED' => 'تم رفض الدفع من البنك',
          'CANCELLED' => 'تم إلغاء عملية الدفع',
          'FAILED' => 'فشلت عملية الدفع',
          _ =>
            'لم يكتمل الدفع بعد (الحالة: $tapStatus). أتمم الدفع على صفحة Tap ثم اضغط "تحقق من الدفع" مجدداً.',
        };
        state = state.copyWith(status: CheckoutStatus.failed, error: msg);
        return;
      }

      // Payment captured ✅
      final total = items.fold<double>(0, (s, i) => s + i.price);
      final now = DateTime.now().toIso8601String();

      // Write payment record and retrieve its generated ID.
      final paymentRow = await _supabase
          .from('payments')
          .insert({
            'user_id': authState.user!.id,
            'amount': total,
            'status': 'completed',
            'tap_id': chargeId,
          })
          .select('id')
          .single();
      final paymentId = paymentRow['id'] as String;

      // Fulfil each purchased item.
      // upsert + ignoreDuplicates makes this safe to call twice
      // (requires UNIQUE(student_id, course_id) and UNIQUE(student_id, book_id)
      // constraints on the respective tables).
      for (final item in items) {
        if (item.itemType == 'course' && item.courseId != null) {
          await _supabase.from('enrollments').upsert(
            {
              'student_id': authState.user!.id,
              'course_id': item.courseId,
              'purchased_at': now,
              'price_paid': item.price,
              'payment_id': paymentId,
            },
            onConflict: 'student_id,course_id',
            ignoreDuplicates: true,
          );
        } else if (item.itemType == 'book' && item.bookId != null) {
          await _supabase.from('book_purchases').upsert(
            {
              'student_id': authState.user!.id,
              'book_id': item.bookId,
              'purchased_at': now,
              'price_paid': item.price,
              'payment_id': paymentId,
            },
            onConflict: 'student_id,book_id',
            ignoreDuplicates: true,
          );
        }
      }

      // Clear cart then force-refresh every provider that depends on
      // enrollments / book_purchases so MyCourses shows up-to-date data.
      await ref.read(cartProvider.notifier).clearCart();
      ref.invalidate(myEnrollmentsProvider);
      ref.invalidate(myCoursesProvider);
      ref.invalidate(myPurchasedBooksProvider);
      ref.invalidate(myBookPurchasesProvider);

      state = state.copyWith(
          status: CheckoutStatus.success, tapChargeId: chargeId);
    } catch (e) {
      state = state.copyWith(
        status: CheckoutStatus.failed,
        error: 'تعذر التحقق من حالة الدفع. تواصل مع الدعم إذا تم خصم المبلغ.',
      );
    }
  }

  void reset() => state = CheckoutState();
}

final checkoutProvider =
    StateNotifierProvider<CheckoutNotifier, CheckoutState>((ref) {
  return CheckoutNotifier(ref);
});
