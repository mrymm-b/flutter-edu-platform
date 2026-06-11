import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_tokens.dart';
import '../../providers/cart_provider.dart';
import '../../providers/payment_provider.dart';
import '../../../presentation/widgets/atmosphere_background.dart';
import '../../../presentation/widgets/glass_card.dart';
import 'checkout_screen.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(cartProvider.notifier).loadCart());
  }

  @override
  Widget build(BuildContext context) {
    final t = Tok.of(context);
    final cartState = ref.watch(cartProvider);
    final bottom = MediaQuery.of(context).padding.bottom;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: AtmosphereBackground(
          child: Column(
            children: [
              // ── Header ────────────────────────────────────────────────────
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppTokens.screenPad, 16, AppTokens.screenPad, 0),
                  child: Row(
                    children: [
                      Semantics(
                        label: 'رجوع',
                        identifier: 'cart_btn_back',
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
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text('سلة المشتريات',
                                    style: TextStyle(
                                        fontSize: AppTokens.tsAppBar,
                                        fontWeight: FontWeight.w700,
                                        color: t.ink)),
                                if (cartState.itemCount > 0) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    constraints:
                                        const BoxConstraints(minWidth: 22),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: t.accentFg,
                                      borderRadius: BorderRadius.circular(
                                          AppTokens.rPill),
                                    ),
                                    child: Text('${cartState.itemCount}',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white),
                                        textAlign: TextAlign.center),
                                  ),
                                ],
                              ],
                            ),
                            Text('مراجعة وإتمام الشراء',
                                style:
                                    TextStyle(fontSize: 12, color: t.muted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 6),

              // ── Content ───────────────────────────────────────────────────
              Expanded(
                child: cartState.isLoading
                    ? Center(
                        child:
                            CircularProgressIndicator(color: t.accentFg))
                    : cartState.items.isEmpty
                        ? _buildEmpty(t)
                        : _buildList(context, cartState, t, bottom),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(Tok t) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: t.accentTint,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.shopping_cart_outlined,
                size: 38, color: t.accentFg),
          ),
          const SizedBox(height: 14),
          Text('السلة فارغة',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: t.ink)),
          const SizedBox(height: 6),
          Text('أضف دورات أو ملازم للمتابعة',
              style: TextStyle(fontSize: 13, color: t.muted)),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, CartState cartState, Tok t,
      double bottomInset) {
    final price = cartState.totalPrice;
    final priceStr = price.truncateToDouble() == price
        ? price.toStringAsFixed(0)
        : price.toStringAsFixed(2);
    final countLabel =
        '${cartState.itemCount} ${cartState.itemCount == 1 ? 'عنصر' : 'عناصر'}';

    return ListView(
      padding: EdgeInsets.fromLTRB(
          AppTokens.screenPad, 0, AppTokens.screenPad, bottomInset + 16),
      children: [
        // ── Items ──────────────────────────────────────────────────────
        for (final item in cartState.items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _CartItemCard(
              item: item,
              t: t,
              onDelete: () => ref
                  .read(cartProvider.notifier)
                  .removeFromCart(item.cartId),
            ),
          ),

        // ── Separator before summary ───────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Divider(color: t.line, thickness: 0.75),
        ),

        // ── Summary — vertical, right-aligned (RTL start) ──────────────
        GlassCard(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          radius: AppTokens.rLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('الإجمالي',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: t.muted)),
              const SizedBox(height: 3),
              Text('$priceStr د.ب',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: t.accentFg,
                      height: 1.1)),
              const SizedBox(height: 2),
              Text(countLabel,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: t.ink2)),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── Checkout button ────────────────────────────────────────────
        Semantics(
          identifier: 'cart_btn_checkout',
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.lerp(t.accentFg, Colors.black, 0.12)!,
                  t.accentFg,
                ],
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
              ),
              borderRadius: BorderRadius.circular(AppTokens.rLg),
            ),
            child: ElevatedButton(
              onPressed: () {
                ref.read(checkoutProvider.notifier).reset();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CheckoutScreen(
                      items: cartState.items,
                      total: cartState.totalPrice,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppTokens.rLg)),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline_rounded, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'متابعة الدفع  ·  $priceStr د.ب',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Cart Item Card ─────────────────────────────────────────────────────────────
// Single compact row: [icon] [title / badge / price] [small trash]

class _CartItemCard extends StatelessWidget {
  final CartItemDetail item;
  final Tok t;
  final VoidCallback onDelete;
  const _CartItemCard(
      {required this.item, required this.t, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isCourse = item.itemType == 'course';
    final priceStr = item.price.truncateToDouble() == item.price
        ? item.price.toStringAsFixed(0)
        : item.price.toStringAsFixed(2);

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      radius: AppTokens.rLg,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon tile 40×40
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: t.accentTint,
              borderRadius: BorderRadius.circular(AppTokens.rMd),
            ),
            child: Icon(
              isCourse
                  ? Icons.play_circle_outline_rounded
                  : Icons.description_outlined,
              color: t.accentFg,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Title → badge → price (tight, all together)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: t.ink,
                      fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: t.accentTint,
                        borderRadius:
                            BorderRadius.circular(AppTokens.rPill),
                      ),
                      child: Text(item.typeLabel,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: t.accentFg)),
                    ),
                    const SizedBox(width: 8),
                    Text('$priceStr د.ب',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: t.accentFg)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 6),

          // Small trash icon — faint red tint, no drama
          Semantics(
            label: 'حذف من السلة',
            identifier: 'cart_btn_remove_item',
            child: GestureDetector(
              onTap: onDelete,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(AppTokens.rSm),
                ),
                child: Icon(Icons.delete_outline_rounded,
                    size: 15,
                    color: const Color(0xFFEF4444)
                        .withValues(alpha: 0.6)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
