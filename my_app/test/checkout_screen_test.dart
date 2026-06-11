import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bh_arab_app/presentation/providers/cart_provider.dart';
import 'package:bh_arab_app/presentation/providers/payment_provider.dart';
import 'package:bh_arab_app/presentation/screens/student/checkout_screen.dart';

// ---------------------------------------------------------------------------
// Fake notifier — overrides async methods to avoid real API / DB calls.
// ---------------------------------------------------------------------------

class _FakeCheckoutNotifier extends CheckoutNotifier {
  _FakeCheckoutNotifier(CheckoutState seed, Ref ref) : super(ref) {
    // Seed the notifier with the desired state for each test scenario.
    state = seed;
  }

  @override
  Future<void> initCheckout(List<CartItemDetail> items, double total) async {
    state = CheckoutState(
      status: CheckoutStatus.pendingVerification,
      tapChargeId: 'test_charge_123',
    );
  }

  @override
  Future<void> verifyAndFulfill(List<CartItemDetail> items) async {
    state = CheckoutState(status: CheckoutStatus.success);
  }

  @override
  void reset() => state = CheckoutState();
}

// ---------------------------------------------------------------------------
// Shared fixtures
// ---------------------------------------------------------------------------

final _testItems = [
  CartItemDetail(
    cartId: 'cart_1',
    itemType: 'course',
    title: 'دورة الرياضيات',
    price: 10.0,
    courseId: 'course_1',
  ),
  CartItemDetail(
    cartId: 'cart_2',
    itemType: 'book',
    title: 'ملزمة الفيزياء',
    price: 5.0,
    bookId: 'book_1',
  ),
];

const _testTotal = 15.0;

Widget _buildTestApp(CheckoutState seed) {
  return ProviderScope(
    overrides: [
      checkoutProvider.overrideWith(
        (ref) => _FakeCheckoutNotifier(seed, ref),
      ),
    ],
    child: MaterialApp(
      home: CheckoutScreen(items: _testItems, total: _testTotal),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    try {
      // CheckoutNotifier eagerly reads Supabase.instance.client in its field
      // initializer, so we must initialize Supabase before any test that
      // constructs _FakeCheckoutNotifier (which extends CheckoutNotifier).
      // Fake credentials are sufficient — no real network calls are made.
      await Supabase.initialize(
        url: 'https://test-project.supabase.co',
        anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
            '.eyJzdWIiOiJ0ZXN0Iiwicm9sZSI6ImFub24ifQ'
            '.test_signature_only',
      );
    } catch (_) {
      // Already initialized in a previous test run.
    }
  });

  // ── Unit: CheckoutState ──────────────────────────────────────────────────

  group('CheckoutState', () {
    test('isIdle is true only when status is idle', () {
      final s = CheckoutState(status: CheckoutStatus.idle);
      expect(s.isIdle, isTrue);
      expect(s.isBusy, isFalse);
      expect(s.isSuccess, isFalse);
      expect(s.isFailed, isFalse);
      expect(s.isPendingVerification, isFalse);
    });

    test('isBusy is true for processing and verifying', () {
      expect(
          CheckoutState(status: CheckoutStatus.processing).isBusy, isTrue);
      expect(
          CheckoutState(status: CheckoutStatus.verifying).isBusy, isTrue);
      expect(CheckoutState(status: CheckoutStatus.idle).isBusy, isFalse);
    });

    test('isPendingVerification carries the tapChargeId', () {
      final s = CheckoutState(
        status: CheckoutStatus.pendingVerification,
        tapChargeId: 'chg_abc',
      );
      expect(s.isPendingVerification, isTrue);
      expect(s.tapChargeId, 'chg_abc');
    });

    test('isFailed exposes the error message', () {
      const msg = 'تعذر الاتصال ببوابة الدفع';
      final s = CheckoutState(status: CheckoutStatus.failed, error: msg);
      expect(s.isFailed, isTrue);
      expect(s.error, msg);
    });

    test('isSuccess is true when payment is captured', () {
      expect(
          CheckoutState(status: CheckoutStatus.success).isSuccess, isTrue);
    });

    test('copyWith preserves unchanged fields', () {
      final original = CheckoutState(
        status: CheckoutStatus.idle,
        tapChargeId: 'chg_original',
      );
      final updated = original.copyWith(status: CheckoutStatus.processing);
      expect(updated.status, CheckoutStatus.processing);
      expect(updated.tapChargeId, 'chg_original');
    });

    test('copyWith resets error to null when not provided', () {
      final withError = CheckoutState(
        status: CheckoutStatus.failed,
        error: 'some error',
      );
      final reset = withError.copyWith(status: CheckoutStatus.idle);
      expect(reset.error, isNull);
    });
  });

  // ── Widget: idle state ───────────────────────────────────────────────────

  group('CheckoutScreen — idle state', () {
    testWidgets('shows header title and item count', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(CheckoutState(status: CheckoutStatus.idle)),
      );
      await tester.pump();

      expect(find.text('إتمام الدفع'), findsOneWidget);
      expect(find.text('2 عنصر في طلبك'), findsOneWidget);
    });

    testWidgets('shows all cart item titles and type labels', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(CheckoutState(status: CheckoutStatus.idle)),
      );
      await tester.pump();

      expect(find.text('دورة الرياضيات'), findsOneWidget);
      expect(find.text('ملزمة الفيزياء'), findsOneWidget);
      expect(find.text('دورة أونلاين'), findsOneWidget);
      expect(find.text('ملزمة PDF'), findsOneWidget);
    });

    testWidgets('shows the correct order total', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(CheckoutState(status: CheckoutStatus.idle)),
      );
      await tester.pump();

      // The order summary row shows "15 د.ب" as the grand total.
      expect(find.text('15 د.ب'), findsOneWidget);
    });

    testWidgets('shows Tap Payments badge with supported methods',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(CheckoutState(status: CheckoutStatus.idle)),
      );
      await tester.pump();

      expect(find.text('Tap Payments'), findsOneWidget);
      expect(
        find.text('Visa / Mastercard / BENEFIT / Apple Pay'),
        findsOneWidget,
      );
    });

    testWidgets('shows pay button with total amount', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(CheckoutState(status: CheckoutStatus.idle)),
      );
      await tester.pump();

      expect(find.text('ادفع 15 د.ب عبر Tap'), findsOneWidget);
    });

    testWidgets('shows ملخص الطلب and طريقة الدفع section titles',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(CheckoutState(status: CheckoutStatus.idle)),
      );
      await tester.pump();

      expect(find.text('ملخص الطلب'), findsOneWidget);
      expect(find.text('طريقة الدفع'), findsOneWidget);
    });
  });

  // ── Widget: pending verification state ──────────────────────────────────

  group('CheckoutScreen — pending verification state', () {
    // Local helper — getters are not valid inside function bodies.
    CheckoutState pendingState() => CheckoutState(
          status: CheckoutStatus.pendingVerification,
          tapChargeId: 'chg_test',
        );

    testWidgets('shows payment pending info box', (tester) async {
      await tester.pumpWidget(_buildTestApp(pendingState()));
      await tester.pump();

      expect(find.text('تم فتح صفحة Tap للدفع'), findsOneWidget);
      expect(
        find.text(
          'أتمم عملية الدفع في المتصفح، ثم ارجع هنا واضغط "تأكيد الدفع".',
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows تأكيد الدفع and re-open buttons', (tester) async {
      await tester.pumpWidget(_buildTestApp(pendingState()));
      await tester.pump();

      expect(find.text('تأكيد الدفع'), findsOneWidget);
      expect(find.text('فتح صفحة الدفع مجدداً'), findsOneWidget);
    });

    testWidgets('hides the initial pay button', (tester) async {
      await tester.pumpWidget(_buildTestApp(pendingState()));
      await tester.pump();

      expect(find.text('ادفع 15 د.ب عبر Tap'), findsNothing);
    });

    testWidgets('shows حالة الدفع instead of طريقة الدفع', (tester) async {
      await tester.pumpWidget(_buildTestApp(pendingState()));
      await tester.pump();

      expect(find.text('حالة الدفع'), findsOneWidget);
      expect(find.text('طريقة الدفع'), findsNothing);
    });
  });

  // ── Widget: busy / loading state ─────────────────────────────────────────

  group('CheckoutScreen — busy state', () {
    testWidgets('shows spinner and "connecting to Tap" while processing',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(CheckoutState(status: CheckoutStatus.processing)),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('جاري الاتصال ببوابة Tap...'), findsOneWidget);
      expect(find.text('يرجى الانتظار'), findsOneWidget);
    });

    testWidgets('shows "verifying payment" message while verifying',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          CheckoutState(
            status: CheckoutStatus.verifying,
            tapChargeId: 'chg_test',
          ),
        ),
      );
      await tester.pump();

      expect(find.text('جاري التحقق من الدفع...'), findsOneWidget);
    });

    testWidgets('hides all action buttons while busy', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(CheckoutState(status: CheckoutStatus.processing)),
      );
      await tester.pump();

      expect(find.text('ادفع 15 د.ب عبر Tap'), findsNothing);
      expect(find.text('تأكيد الدفع'), findsNothing);
    });
  });

  // ── Widget: failed state ─────────────────────────────────────────────────

  group('CheckoutScreen — failed state', () {
    testWidgets('shows the error message in a red container', (tester) async {
      const errorMsg =
          'تعذر الاتصال ببوابة الدفع. تحقق من الاتصال وحاول مجدداً.';
      await tester.pumpWidget(
        _buildTestApp(
          CheckoutState(status: CheckoutStatus.failed, error: errorMsg),
        ),
      );
      await tester.pump();

      expect(find.text(errorMsg), findsOneWidget);
    });

    testWidgets('still shows pay button so user can retry', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          CheckoutState(
              status: CheckoutStatus.failed, error: 'خطأ غير متوقع'),
        ),
      );
      await tester.pump();

      expect(find.text('ادفع 15 د.ب عبر Tap'), findsOneWidget);
    });
  });

  // ── Widget: success state ────────────────────────────────────────────────

  group('CheckoutScreen — success state', () {
    testWidgets('shows full-screen success view', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(CheckoutState(status: CheckoutStatus.success)),
      );
      await tester.pump();

      expect(find.text('تم الدفع بنجاح! 🎉'), findsOneWidget);
      expect(
        find.text('يمكنك الآن الوصول إلى محتواك في "دوراتي"'),
        findsOneWidget,
      );
      expect(find.text('جاري التحويل...'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });

    testWidgets('hides the checkout form when successful', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(CheckoutState(status: CheckoutStatus.success)),
      );
      await tester.pump();

      expect(find.text('إتمام الدفع'), findsNothing);
      expect(find.text('ادفع 15 د.ب عبر Tap'), findsNothing);
    });
  });

  // ── Widget: interactions ─────────────────────────────────────────────────

  group('CheckoutScreen — interactions', () {
    testWidgets(
        'tapping pay button calls initCheckout and shows pending state',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(CheckoutState(status: CheckoutStatus.idle)),
      );
      await tester.pump();

      await tester.tap(find.text('ادفع 15 د.ب عبر Tap'));
      await tester.pump();

      expect(find.text('تم فتح صفحة Tap للدفع'), findsOneWidget);
      expect(find.text('تأكيد الدفع'), findsOneWidget);
    });

    testWidgets(
        'tapping verify button calls verifyAndFulfill and shows success',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          CheckoutState(
            status: CheckoutStatus.pendingVerification,
            tapChargeId: 'chg_test',
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('تأكيد الدفع'));
      await tester.pump();

      expect(find.text('تم الدفع بنجاح! 🎉'), findsOneWidget);
    });

    testWidgets(
        'tapping re-open button calls initCheckout again',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          CheckoutState(
            status: CheckoutStatus.pendingVerification,
            tapChargeId: 'chg_old',
          ),
        ),
      );
      await tester.pump();

      // Tapping "فتح صفحة الدفع مجدداً" calls initCheckout which in the fake
      // notifier transitions to pendingVerification with a new chargeId.
      await tester.tap(find.text('فتح صفحة الدفع مجدداً'));
      await tester.pump();

      // Still in pendingVerification (re-opened), not failure.
      expect(find.text('تم فتح صفحة Tap للدفع'), findsOneWidget);
    });
  });
}
