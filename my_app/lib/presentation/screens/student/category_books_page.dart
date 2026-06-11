import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_tokens.dart';
import '../../../core/utils/toast.dart';
import '../../../domain/models/book.dart';
import '../../providers/books_provider.dart';
import '../../providers/subjects_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/book_purchases_provider.dart';
import '../../widgets/pdf_download_button.dart';
import '../../../presentation/widgets/atmosphere_background.dart';
import '../../../presentation/widgets/glass_card.dart';
import 'cart.dart';

class CategoryBooksPage extends ConsumerStatefulWidget {
  const CategoryBooksPage({super.key});

  @override
  ConsumerState<CategoryBooksPage> createState() =>
      _CategoryBooksPageState();
}

class _CategoryBooksPageState extends ConsumerState<CategoryBooksPage> {
  String? _selectedSubjectId;

  @override
  Widget build(BuildContext context) {
    final t = Tok.of(context);
    final subjectsAsync = ref.watch(subjectsProvider);
    final booksAsync = _selectedSubjectId == null
        ? ref.watch(booksProvider)
        : ref.watch(booksBySubjectProvider(_selectedSubjectId!));
    final cartCount = ref.watch(cartProvider).itemCount;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: AtmosphereBackground(
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────────────────
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppTokens.screenPad, 16, AppTokens.screenPad, 0),
                  child: Row(
                    children: [
                      // Back
                      Semantics(
                        label: 'رجوع',
                        identifier: 'category_books_btn_back',
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: t.isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : t.bg2,
                              borderRadius:
                                  BorderRadius.circular(AppTokens.rSm),
                              border: Border.all(color: t.line),
                            ),
                            child: Icon(Icons.arrow_back_ios_new,
                                color: t.ink2, size: 17),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Title
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'الملازم',
                              style: TextStyle(
                                fontSize: AppTokens.tsAppBar,
                                fontWeight: FontWeight.w700,
                                color: t.ink,
                              ),
                            ),
                            Text('ملازم PDF للتحميل',
                                style: TextStyle(
                                    fontSize: 12, color: t.muted)),
                          ],
                        ),
                      ),

                      // Cart
                      Semantics(
                        label: 'سلة المشتريات',
                        identifier: 'category_books_btn_open_cart',
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const CartScreen()),
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: t.isDark
                                      ? Colors.white.withValues(alpha: 0.06)
                                      : t.bg2,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: t.line),
                                ),
                                child: Icon(Icons.shopping_cart_outlined,
                                    color: t.ink2, size: 20),
                              ),
                              if (cartCount > 0)
                                Positioned(
                                  top: -2,
                                  left: -2,
                                  child: Container(
                                    width: 17,
                                    height: 17,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFEF4444),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$cartCount',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Subject filter chips ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppTokens.screenPad, 14, AppTokens.screenPad, 0),
                child: subjectsAsync.when(
                  loading: () => const SizedBox(
                      height: 36, child: LinearProgressIndicator()),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (subjects) => SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: subjects.length + 1,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: 7),
                      itemBuilder: (_, i) {
                        final isAll = i == 0;
                        final subject = isAll ? null : subjects[i - 1];
                        final isSelected = isAll
                            ? _selectedSubjectId == null
                            : _selectedSubjectId == subject!.id;
                        final label =
                            isAll ? 'الكل' : subject!.displayName;

                        return Semantics(
                          identifier: 'category_books_chip_filter_$i',
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _selectedSubjectId =
                                  isAll ? null : subject!.id;
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 140),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 7),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? t.accentFg
                                    : (t.isDark
                                        ? Colors.white
                                            .withValues(alpha: 0.06)
                                        : t.bg2),
                                borderRadius: BorderRadius.circular(
                                    AppTokens.rPill),
                                border: Border.all(
                                  color: isSelected ? t.accentFg : t.line,
                                ),
                              ),
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : t.muted,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // ── Books list ───────────────────────────────────────────────
              Expanded(
                child: booksAsync.when(
                  loading: () => Center(
                      child: CircularProgressIndicator(color: t.accentFg)),
                  error: (err, _) => Center(
                    child: Text('خطأ: $err',
                        style: TextStyle(color: t.muted)),
                  ),
                  data: (books) {
                    if (books.isEmpty) {
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
                              child: Icon(Icons.description_outlined,
                                  size: 38, color: t.accentFg),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'لا توجد ملازم متاحة',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: t.ink),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.separated(
                      padding:
                          const EdgeInsets.all(AppTokens.screenPad),
                      itemCount: books.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppTokens.cardGap),
                      itemBuilder: (context, i) =>
                          _BookCard(book: books[i], index: i, t: t),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Book Card ─────────────────────────────────────────────────────────────────
class _BookCard extends ConsumerWidget {
  final Book book;
  final int index;
  final Tok t;
  const _BookCard(
      {required this.book, required this.index, required this.t});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final cartItem =
        cartState.items.where((i) => i.bookId == book.id).firstOrNull;
    final inCart = cartItem != null;
    final purchasedAsync = ref.watch(myPurchasedBooksProvider);
    final purchased =
        purchasedAsync.valueOrNull?.any((b) => b.id == book.id) ?? false;

    return GlassCard(
      padding: EdgeInsets.zero,
      radius: AppTokens.rLg,
      child: Column(
        children: [
          // ── Info row — mirrors category_online_page exactly ───────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 15, 15, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon tile — 48×48 purple
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: t.accentTint,
                    borderRadius: BorderRadius.circular(AppTokens.rSm),
                  ),
                  child: Icon(Icons.menu_book_rounded,
                      color: t.accentFg, size: 22),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: t.accentTint,
                              borderRadius:
                                  BorderRadius.circular(AppTokens.rPill),
                            ),
                            child: Text('ملزمة PDF',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: t.accentFg,
                                    fontWeight: FontWeight.w700)),
                          ),
                          if (purchased) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: t.accentFg,
                                borderRadius:
                                    BorderRadius.circular(AppTokens.rPill),
                              ),
                              child: const Text('مشتراة',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Title — heavy
                      Text(
                        book.title,
                        style: TextStyle(
                          fontSize: AppTokens.tsCardT,
                          fontWeight: FontWeight.w800,
                          color: t.ink,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),

                      // Meta + price
                      Row(
                        children: [
                          Icon(Icons.description_outlined,
                              size: 13, color: t.faint),
                          const SizedBox(width: 4),
                          Text(
                            '${book.pagesCount ?? '-'} صفحة · ${book.fileSizeInMB}',
                            style: TextStyle(fontSize: 11.5, color: t.faint),
                          ),
                          const Spacer(),
                          Text(
                            '${book.price.toStringAsFixed(0)} د.ب',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: t.accentFg,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Container(height: 1, color: t.line),

          // ── Actions ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: purchased
                // Purchased → download button (token style)
                ? Semantics(
                    identifier: 'category_books_btn_download_$index',
                    child: PdfDownloadButton(
                      bookId: book.id,
                      storagePath: book.pdfUrl,
                      t: t,
                    ),
                  )
                // Not purchased → secondary + primary/destructive
                : Row(
                    children: [
                      // Secondary — معاينة
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 16),
                        decoration: BoxDecoration(
                          color: t.isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : t.bg2,
                          borderRadius:
                              BorderRadius.circular(AppTokens.rSm),
                          border: Border.all(color: t.line),
                        ),
                        child: Text('معاينة',
                            style: TextStyle(
                                fontSize: 13,
                                color: t.ink2,
                                fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 8),

                      // Primary / Destructive — أضف للسلة / إزالة
                      Expanded(
                        child: Semantics(
                          identifier:
                              'category_books_btn_add_to_cart_$index',
                          child: GestureDetector(
                            onTap: inCart
                                ? () async {
                                    await ref
                                        .read(cartProvider.notifier)
                                        .removeFromCart(cartItem.cartId);
                                    if (!context.mounted) return;
                                    showAppToast(context,
                                        message: 'تمت الإزالة من السلة',
                                        type: ToastType.info);
                                  }
                                : () async {
                                    final ok = await ref
                                        .read(cartProvider.notifier)
                                        .addToCart(
                                          itemType: 'book',
                                          bookId: book.id,
                                        );
                                    if (!context.mounted) return;
                                    showAppToast(context,
                                        message: ok
                                            ? 'تمت إضافة "${book.title}" للسلة'
                                            : 'فشلت الإضافة للسلة، حاول مجدداً',
                                        type: ok
                                            ? ToastType.success
                                            : ToastType.error);
                                  },
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: inCart
                                    ? const Color(0xFFEF4444).withValues(
                                        alpha: t.isDark ? 0.15 : 0.08)
                                    : t.accentFg,
                                borderRadius:
                                    BorderRadius.circular(AppTokens.rSm),
                                border: Border.all(
                                  color: inCart
                                      ? const Color(0xFFEF4444)
                                          .withValues(alpha: 0.35)
                                      : t.accentFg,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    inCart
                                        ? Icons.remove_shopping_cart_rounded
                                        : Icons.add_shopping_cart_rounded,
                                    size: 15,
                                    color: inCart
                                        ? const Color(0xFFEF4444)
                                        : Colors.white,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    inCart ? 'إزالة من السلة' : 'أضف للسلة',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: inCart
                                          ? const Color(0xFFEF4444)
                                          : Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
