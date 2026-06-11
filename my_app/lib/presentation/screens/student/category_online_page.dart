import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_tokens.dart';
import '../../../core/utils/toast.dart';
import '../../../domain/models/course.dart';
import '../../providers/courses_provider.dart';
import '../../providers/subjects_provider.dart';
import '../../providers/cart_provider.dart';
import '../../../presentation/widgets/atmosphere_background.dart';
import '../../../presentation/widgets/glass_card.dart';
import 'cart.dart';
import 'course_detail.dart';

class CategoryOnlinePage extends ConsumerStatefulWidget {
  const CategoryOnlinePage({super.key});

  @override
  ConsumerState<CategoryOnlinePage> createState() =>
      _CategoryOnlinePageState();
}

class _CategoryOnlinePageState extends ConsumerState<CategoryOnlinePage> {
  String? _selectedSubjectId;

  @override
  Widget build(BuildContext context) {
    final t = Tok.of(context);
    final subjectsAsync = ref.watch(subjectsProvider);
    final coursesAsync = _selectedSubjectId == null
        ? ref.watch(coursesProvider)
        : ref.watch(coursesBySubjectProvider(_selectedSubjectId!));
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
                      // Back button
                      Semantics(
                        label: 'رجوع',
                        identifier: 'category_online_btn_back',
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
                              'الدورات الأونلاين',
                              style: TextStyle(
                                fontSize: AppTokens.tsAppBar,
                                fontWeight: FontWeight.w700,
                                color: t.ink,
                              ),
                            ),
                            Text('شروحات مباشرة + تسجيلات',
                                style:
                                    TextStyle(fontSize: 12, color: t.muted)),
                          ],
                        ),
                      ),

                      // Cart button
                      Semantics(
                        label: 'سلة المشتريات',
                        identifier: 'category_online_btn_open_cart',
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
                      height: 36,
                      child: LinearProgressIndicator()),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (subjects) => SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: subjects.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(width: 7),
                      itemBuilder: (_, i) {
                        final isAll = i == 0;
                        final subject = isAll ? null : subjects[i - 1];
                        final isSelected = isAll
                            ? _selectedSubjectId == null
                            : _selectedSubjectId == subject!.id;
                        final label =
                            isAll ? 'الكل' : subject!.displayName;

                        return Semantics(
                          identifier: 'category_online_chip_filter_$i',
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
                                        ? Colors.white.withValues(alpha: 0.06)
                                        : t.bg2),
                                borderRadius: BorderRadius.circular(
                                    AppTokens.rPill),
                                border: Border.all(
                                  color: isSelected
                                      ? t.accentFg
                                      : t.line,
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

              // ── Courses list ─────────────────────────────────────────────
              Expanded(
                child: coursesAsync.when(
                  loading: () => Center(
                      child: CircularProgressIndicator(color: t.accentFg)),
                  error: (err, _) => _errorState(err, t, context, ref),
                  data: (courses) {
                    if (courses.isEmpty) {
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
                              child: Icon(Icons.school_outlined,
                                  size: 38, color: t.accentFg),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'لا توجد دورات متاحة',
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
                      padding: const EdgeInsets.all(AppTokens.screenPad),
                      itemCount: courses.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppTokens.cardGap),
                      itemBuilder: (context, i) =>
                          _CourseCard(course: courses[i], index: i, t: t),
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

  Widget _errorState(Object err, Tok t, BuildContext ctx, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: t.faint, size: 48),
          const SizedBox(height: 8),
          Text('حدث خطأ: $err',
              style: TextStyle(color: t.muted),
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Semantics(
            identifier: 'category_online_btn_retry',
            child: TextButton(
              onPressed: () => ref.invalidate(coursesProvider),
              child: Text('إعادة المحاولة',
                  style: TextStyle(color: t.accentFg)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Course Card ───────────────────────────────────────────────────────────────
class _CourseCard extends ConsumerWidget {
  final Course course;
  final int index;
  final Tok t;
  const _CourseCard(
      {required this.course, required this.index, required this.t});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final cartItem = cartState.items
        .where((i) => i.courseId == course.id)
        .firstOrNull;
    final inCart = cartItem != null;
    final isNew = course.studentsCount == 0;

    return GlassCard(
      padding: EdgeInsets.zero,
      radius: AppTokens.rLg,
      child: Column(
        children: [
          // ── Info row ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 15, 15, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail / icon tile
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: t.accentTint,
                    borderRadius: BorderRadius.circular(AppTokens.rSm),
                  ),
                  child: Icon(Icons.play_circle_outline_rounded,
                      color: t.accentFg, size: 24),
                ),
                const SizedBox(width: 12),

                // Title + meta
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge row: "دورة أونلاين" + "جديد" (purple)
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
                            child: Text('دورة أونلاين',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: t.accentFg,
                                    fontWeight: FontWeight.w700)),
                          ),
                          if (isNew) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: t.accentFg,
                                borderRadius:
                                    BorderRadius.circular(AppTokens.rPill),
                              ),
                              child: const Text('جديد',
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
                        course.title,
                        style: TextStyle(
                          fontSize: AppTokens.tsCardT,
                          fontWeight: FontWeight.w800,
                          color: t.ink,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      if (course.description != null &&
                          course.description!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          course.description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: t.muted),
                        ),
                      ],

                      const SizedBox(height: 8),

                      // Meta row: students + price
                      Row(
                        children: [
                          Icon(Icons.people_outline_rounded,
                              size: 13, color: t.faint),
                          const SizedBox(width: 4),
                          Text(
                            isNew
                                ? 'أول المشتركين'
                                : '${course.studentsCount} طالب',
                            style: TextStyle(
                                fontSize: 11.5, color: t.faint),
                          ),
                          const Spacer(),
                          // Price — prominent purple
                          Text(
                            '${course.price.toStringAsFixed(0)} د.ب',
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

          // ── Action buttons ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Row(
              children: [
                // Secondary — التفاصيل
                Semantics(
                  identifier: 'category_online_btn_details_$index',
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CourseDetailPage(courseId: course.id),
                      ),
                    ),
                    child: Container(
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
                      child: Text('التفاصيل',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: t.ink2)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Primary / Destructive — أضف للسلة أو إزالة
                Expanded(
                  child: Semantics(
                    identifier: 'category_online_btn_add_to_cart_$index',
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
                                    itemType: 'course',
                                    courseId: course.id,
                                  );
                              if (!context.mounted) return;
                              showAppToast(context,
                                  message: ok
                                      ? 'تمت إضافة "${course.title}" للسلة'
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
                          mainAxisAlignment: MainAxisAlignment.center,
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
