import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_tokens.dart';
import '../../providers/cart_provider.dart';
import '../../providers/payment_provider.dart';
import '../../../presentation/widgets/atmosphere_background.dart';
import '../../../presentation/widgets/glass_card.dart';
import 'my_courses.dart';

class CheckoutScreen extends ConsumerWidget {
  final List<CartItemDetail> items;
  final double total;

  const CheckoutScreen({
    super.key,
    required this.items,
    required this.total,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Tok.of(context);
    final checkoutState = ref.watch(checkoutProvider);

    ref.listen(checkoutProvider, (_, next) {
      if (next.isSuccess) {
        Future.delayed(const Duration(seconds: 2), () {
          if (context.mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const MyCourses()),
              (route) => false,
            );
          }
        });
      }
    });

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: AtmosphereBackground(
          child: checkoutState.isSuccess
              ? _buildSuccess(t)
              : _buildCheckout(context, ref, checkoutState, t),
        ),
      ),
    );
  }

  // ── Success Screen ─────────────────────────────────────────────────────────

  Widget _buildSuccess(Tok t) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: t.accentTint,
                shape: BoxShape.circle,
                border: Border.all(color: t.accentLine, width: 2),
              ),
              child: Icon(Icons.check_rounded, color: t.accentFg, size: 46),
            ),
            const SizedBox(height: 24),
            Text(
              'تم الدفع بنجاح! 🎉',
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w800, color: t.ink),
            ),
            const SizedBox(height: 10),
            Text(
              'يمكنك الآن الوصول إلى محتواك في "دوراتي"',
              style: TextStyle(fontSize: 14, color: t.muted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text('جاري التحويل...',
                style: TextStyle(fontSize: 12, color: t.faint)),
          ],
        ),
      ),
    );
  }

  // ── Checkout Form ──────────────────────────────────────────────────────────

  Widget _buildCheckout(
      BuildContext context, WidgetRef ref, CheckoutState state, Tok t) {
    final totalStr = total.truncateToDouble() == total
        ? total.toStringAsFixed(0)
        : total.toStringAsFixed(2);

    return Stack(
      children: [
        Column(
          children: [
            // ── Flat Header ────────────────────────────────────────────────
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppTokens.screenPad, 16, AppTokens.screenPad, 0),
                child: Row(
                  children: [
                    Semantics(
                      label: 'رجوع',
                      identifier: 'checkout_btn_back',
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: t.isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : t.bg2,
                            borderRadius:
                                BorderRadius.circular(AppTokens.rSm),
                            border: Border.all(color: t.line),
                          ),
                          child: Icon(Icons.arrow_back_ios_new,
                              color: t.ink2, size: 15),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('إتمام الدفع',
                              style: TextStyle(
                                  fontSize: AppTokens.tsAppBar,
                                  fontWeight: FontWeight.w700,
                                  color: t.ink)),
                          Text('${items.length == 1 ? 'عنصر واحد' : items.length == 2 ? 'عنصران' : '${items.length} عناصر'} في الطلب',
                              style:
                                  TextStyle(fontSize: 12, color: t.muted)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Scrollable content ─────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                    AppTokens.screenPad,
                    0,
                    AppTokens.screenPad,
                    state.isBusy ? 24 : 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Section: ملخص الطلب ─────────────────────────────────
                    _SectionLabel('ملخص الطلب', t),
                    const SizedBox(height: 10),

                    GlassCard(
                      padding: EdgeInsets.zero,
                      radius: AppTokens.rLg,
                      child: Column(
                        children: [
                          // Items
                          ...items.asMap().entries.map((entry) {
                            final i = entry.key;
                            final item = entry.value;
                            final priceStr = item.price
                                    .truncateToDouble() ==
                                item.price
                                ? item.price.toStringAsFixed(0)
                                : item.price.toStringAsFixed(2);
                            final isCourse = item.itemType == 'course';

                            return Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      14, 12, 14, 12),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: t.accentTint,
                                          borderRadius:
                                              BorderRadius.circular(
                                                  AppTokens.rSm),
                                        ),
                                        child: Icon(
                                          isCourse
                                              ? Icons
                                                  .play_circle_outline_rounded
                                              : Icons
                                                  .description_outlined,
                                          color: t.accentFg,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.title,
                                              style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: t.ink),
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 3),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 7,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: t.accentTint,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        AppTokens.rPill),
                                              ),
                                              child: Text(item.typeLabel,
                                                  style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: t.accentFg)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        '$priceStr د.ب',
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: t.accentFg),
                                      ),
                                    ],
                                  ),
                                ),
                                if (i < items.length - 1)
                                  Divider(height: 1, color: t.line),
                              ],
                            );
                          }),

                          // Total row
                          Divider(height: 1, color: t.line),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text('الإجمالي',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: t.ink)),
                                Text('$totalStr د.ب',
                                    style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        color: t.accentFg)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Section: طريقة الدفع / حالة الدفع ──────────────────
                    if (state.isPendingVerification) ...[
                      _SectionLabel('حالة الدفع', t),
                      const SizedBox(height: 10),
                      GlassCard(
                        padding: const EdgeInsets.all(14),
                        radius: AppTokens.rLg,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: t.accentTint,
                                borderRadius:
                                    BorderRadius.circular(AppTokens.rSm),
                              ),
                              child: Icon(Icons.open_in_browser_rounded,
                                  color: t.accentFg, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('تم فتح صفحة Tap للدفع',
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: t.ink)),
                                  const SizedBox(height: 4),
                                  Text(
                                    'أتمم عملية الدفع في المتصفح، ثم ارجع هنا واضغط "تأكيد الدفع".',
                                    style: TextStyle(
                                        fontSize: 12, color: t.muted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      _SectionLabel('طريقة الدفع', t),
                      const SizedBox(height: 10),
                      _TapBadge(t: t),
                    ],

                    // ── Error ────────────────────────────────────────────────
                    if (state.isFailed && state.error != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius:
                              BorderRadius.circular(AppTokens.rMd),
                          border: Border.all(
                              color: const Color(0xFFFCA5A5)),
                        ),
                        child: Text(state.error!,
                            style: const TextStyle(
                                color: Color(0xFFDC2626), fontSize: 13)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),

        // ── Loading overlay ────────────────────────────────────────────────
        if (state.isBusy)
          Container(
            color: Colors.black.withValues(alpha: 0.45),
            child: Center(
              child: GlassCard(
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 28),
                radius: AppTokens.rLg,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: t.accentFg),
                    const SizedBox(height: 16),
                    Text(
                      state.isVerifying
                          ? 'جاري التحقق من الدفع...'
                          : 'جاري الاتصال ببوابة Tap...',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: t.ink),
                    ),
                    const SizedBox(height: 4),
                    Text('يرجى الانتظار',
                        style: TextStyle(fontSize: 12, color: t.muted)),
                  ],
                ),
              ),
            ),
          ),

        // ── Bottom action button ───────────────────────────────────────────
        if (!state.isBusy)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: t.bg2,
                border: Border(top: BorderSide(color: t.line)),
              ),
              padding: EdgeInsets.fromLTRB(
                  16, 12, 16,
                  MediaQuery.of(context).padding.bottom + 16),
              child: state.isPendingVerification
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Semantics(
                            identifier: 'checkout_btn_verify_payment',
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => ref
                                    .read(checkoutProvider.notifier)
                                    .verifyAndFulfill(items),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color(0xFF16A34A),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 15),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          AppTokens.rLg)),
                                  elevation: 0,
                                ),
                                child: const Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.verified_outlined,
                                        size: 17),
                                    SizedBox(width: 8),
                                    Text('تأكيد الدفع',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed: () => ref
                                  .read(checkoutProvider.notifier)
                                  .initCheckout(items, total),
                              child: Text('فتح صفحة الدفع مجدداً',
                                  style: TextStyle(
                                      color: t.accentFg, fontSize: 13)),
                            ),
                          ),
                        ],
                      )
                    : Semantics(
                        identifier: 'checkout_btn_pay',
                        child: SizedBox(
                          width: double.infinity,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color.lerp(t.accentFg, Colors.black,
                                      0.12)!,
                                  t.accentFg,
                                ],
                                begin: Alignment.centerRight,
                                end: Alignment.centerLeft,
                              ),
                              borderRadius: BorderRadius.circular(
                                  AppTokens.rLg),
                            ),
                            child: ElevatedButton(
                              onPressed: () => ref
                                  .read(checkoutProvider.notifier)
                                  .initCheckout(items, total),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 15),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppTokens.rLg)),
                                elevation: 0,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                      Icons.lock_outline_rounded,
                                      size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    'ادفع $totalStr د.ب',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
            ),
          ),
      ],
    );
  }
}

// ── Section label ──────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  final Tok t;
  const _SectionLabel(this.text, this.t);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: t.ink));
  }
}

// ── Tap Payments Badge ─────────────────────────────────────────────────────────

class _TapBadge extends StatelessWidget {
  final Tok t;
  const _TapBadge({required this.t});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      radius: AppTokens.rLg,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: t.accentTint,
              borderRadius: BorderRadius.circular(AppTokens.rSm),
            ),
            child: Icon(Icons.credit_card_rounded,
                color: t.accentFg, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('بطاقات الدفع المدعومة',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: t.ink)),
              const SizedBox(height: 3),
              Text('BENEFIT · Visa · Mastercard · Apple Pay',
                  style: TextStyle(fontSize: 11, color: t.muted)),
            ],
          ),
        ],
      ),
    );
  }
}
