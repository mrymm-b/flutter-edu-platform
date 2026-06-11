import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/toast.dart';
import '../../providers/courses_provider.dart';
import '../../providers/enrollments_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/teacher_provider.dart';
import 'cart.dart';
import 'online_course_view.dart';

const _kPurple = Color(0xFF6264A7);
const _kDark = Color(0xFF464775);
const _kBg = Color(0xFFF3F2F1);

class CourseDetailPage extends ConsumerWidget {
  final String courseId;
  const CourseDetailPage({super.key, required this.courseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courseAsync = ref.watch(courseProvider(courseId));
    final isEnrolledAsync = ref.watch(isEnrolledProvider(courseId));
    final cartState = ref.watch(cartProvider);
    final cartCount = cartState.itemCount;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _kBg,
        body: courseAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(color: _kPurple)),
          error: (err, _) => Center(child: Text('خطأ: $err')),
          data: (course) {
            final isEnrolled = isEnrolledAsync.value ?? false;
            final inCart =
                cartState.items.any((i) => i.courseId == course.id);
            final teacherNameAsync =
                ref.watch(studentNameProvider(course.teacherId));
            final teacherName =
                teacherNameAsync.valueOrNull ?? 'المعلم';

            return Column(
              children: [
                // ── Gradient Header ─────────────────────────────────────────
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [_kDark, _kPurple],
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Semantics(
                                identifier: 'course_detail_btn_back',
                                child: GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.arrow_back_ios_new,
                                        color: Colors.white, size: 18),
                                  ),
                                ),
                              ),
                              Semantics(
                                identifier: 'course_detail_btn_open_cart',
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
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withValues(alpha: 0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                            Icons.shopping_cart_outlined,
                                            color: Colors.white,
                                            size: 20),
                                      ),
                                      if (cartCount > 0)
                                        Positioned(
                                          top: -2,
                                          left: -2,
                                          child: Container(
                                            width: 16,
                                            height: 16,
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
                                                  fontWeight: FontWeight.bold,
                                                ),
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
                          const SizedBox(height: 18),
                          Text(
                            course.title,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'أ. $teacherName',
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFFBFC0E0)),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _chip(
                                icon: Icons.people_outline,
                                label: course.studentsCount == 0
                                    ? 'جديد'
                                    : '${course.studentsCount} طالب',
                              ),
                              const SizedBox(width: 8),
                              _chip(
                                icon: Icons.language_outlined,
                                label: 'عربي',
                              ),
                              if (isEnrolled) ...[
                                const SizedBox(width: 8),
                                _chip(
                                  icon: Icons.check_circle_outline,
                                  label: 'مسجل',
                                  green: true,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Scrollable body ─────────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Price / Action card ────────────────────────────
                        _card(
                          child: isEnrolled
                              ? Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF16A34A)
                                            .withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.check_circle,
                                          color: Color(0xFF16A34A), size: 22),
                                    ),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'أنت مسجل في هذه الدورة',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF16A34A),
                                            ),
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            'يمكنك الوصول لكل المحتوى',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF6B7280)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Semantics(
                                      identifier: 'course_detail_btn_start',
                                      child: OutlinedButton(
                                        onPressed: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                OnlineCourseViewScreen(
                                                    courseId: course.id),
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: _kPurple,
                                          side:
                                              const BorderSide(color: _kPurple),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 8),
                                        ),
                                        child: const Text('ابدأ',
                                            style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          course.price.toStringAsFixed(
                                              course.price
                                                          .truncateToDouble() ==
                                                      course.price
                                                  ? 0
                                                  : 2),
                                          style: const TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                            color: _kDark,
                                          ),
                                        ),
                                        const Padding(
                                          padding:
                                              EdgeInsets.only(bottom: 5),
                                          child: Text(
                                            ' د.ب',
                                            style: TextStyle(
                                                fontSize: 16,
                                                color: Color(0xFF64748B),
                                                fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    SizedBox(
                                      width: double.infinity,
                                      child: Semantics(
                                        identifier: 'course_detail_btn_add_to_cart',
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            gradient: inCart
                                                ? null
                                                : const LinearGradient(
                                                    colors: [_kDark, _kPurple],
                                                    begin:
                                                        Alignment.centerRight,
                                                    end: Alignment.centerLeft,
                                                  ),
                                            color: inCart
                                                ? const Color(0xFF9CA3AF)
                                                : null,
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                          child: ElevatedButton.icon(
                                            onPressed: inCart
                                                ? null
                                                : () async {
                                                    final ok = await ref
                                                        .read(cartProvider
                                                            .notifier)
                                                        .addToCart(
                                                          itemType: 'course',
                                                          courseId: course.id,
                                                        );
                                                    if (!context.mounted) return;
                                                    showAppToast(context,
                                                        message: ok
                                                            ? 'تمت إضافة "${course.title}" للسلة'
                                                            : 'فشلت الإضافة، حاول مجدداً',
                                                        type: ok
                                                            ? ToastType.success
                                                            : ToastType.error);
                                                  },
                                            icon: Icon(
                                              inCart
                                                  ? Icons.check_rounded
                                                  : Icons
                                                      .add_shopping_cart_rounded,
                                              size: 18,
                                            ),
                                            label: Text(
                                              inCart ? 'في السلة' : 'أضف للسلة',
                                              style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.transparent,
                                              shadowColor: Colors.transparent,
                                              foregroundColor: Colors.white,
                                              disabledBackgroundColor:
                                                  Colors.transparent,
                                              disabledForegroundColor:
                                                  Colors.white,
                                              padding: const EdgeInsets.symmetric(
                                                  vertical: 14),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(14)),
                                              elevation: 0,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),

                        const SizedBox(height: 12),

                        // ── Description ───────────────────────────────────
                        if (course.description != null &&
                            course.description!.isNotEmpty) ...[
                          _card(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _sectionTitle('عن الدورة'),
                                const SizedBox(height: 10),
                                Text(
                                  course.description!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF374151),
                                    height: 1.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // ── What you'll learn ─────────────────────────────
                        _card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionTitle('ماذا ستتعلم؟'),
                              const SizedBox(height: 12),
                              ...[
                                'شرح أسبوعي شامل للنصوص والقواعد',
                                'بث مباشر تفاعلي مع المعلم',
                                'تسجيلات الحصص متاحة للمراجعة',
                                'ملزمتي النصوص والقواعد PDF',
                              ].map(
                                (point) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.only(top: 2),
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF16A34A)
                                              .withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.check,
                                            size: 12,
                                            color: Color(0xFF16A34A)),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          point,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF374151),
                                            height: 1.4,
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

                        const SizedBox(height: 12),

                        // ── Course info ───────────────────────────────────
                        _card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionTitle('معلومات الدورة'),
                              const SizedBox(height: 12),
                              _infoRow(Icons.calendar_today_outlined,
                                  'تاريخ الإضافة',
                                  '${course.createdAt.day}/${course.createdAt.month}/${course.createdAt.year}'),
                              const Divider(
                                  height: 20, color: Color(0xFFE2E8F0)),
                              _infoRow(Icons.people_outline, 'عدد الطلاب',
                                  '${course.studentsCount} طالب'),
                              const Divider(
                                  height: 20, color: Color(0xFFE2E8F0)),
                              _infoRow(Icons.language_outlined, 'اللغة',
                                  'العربية'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _chip(
      {required IconData icon, required String label, bool green = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: green
            ? const Color(0xFF16A34A).withValues(alpha: 0.2)
            : Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 13,
              color: green ? const Color(0xFF86EFAC) : Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: green ? const Color(0xFF86EFAC) : Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: _kPurple,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _kPurple.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 16, color: _kPurple),
        ),
        const SizedBox(width: 12),
        Text(label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
        const Spacer(),
        Text(value,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827))),
      ],
    );
  }
}
