import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/toast.dart';
import '../../../domain/models/course.dart';
import '../../../domain/models/book.dart';
import '../../providers/cart_provider.dart';
import 'course_detail.dart';

const _kPurple = Color(0xFF6264A7);
const _kDark   = Color(0xFF464775);
const _kBg     = Color(0xFFF3F2F1);
const _kGreen  = Color(0xFF059669);

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _controller = TextEditingController();
  final _focus      = FocusNode();
  final _supabase   = Supabase.instance.client;

  Timer?        _debounce;
  List<Course>  _courses  = [];
  List<Book>    _books    = [];
  bool          _loading  = false;
  bool          _searched = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() { _courses = []; _books = []; _searched = false; _loading = false; });
      return;
    }
    setState(() => _loading = true);
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(value.trim()));
  }

  Future<void> _search(String query) async {
    try {
      final results = await Future.wait([
        _supabase.from('courses').select().ilike('title', '%$query%').eq('is_active', true),
        _supabase.from('books').select().ilike('title', '%$query%').eq('is_active', true),
      ]);
      if (!mounted) return;
      setState(() {
        _courses  = (results[0] as List).map((e) => Course.fromJson(e as Map<String, dynamic>)).toList();
        _books    = (results[1] as List).map((e) => Book.fromJson(e as Map<String, dynamic>)).toList();
        _loading  = false;
        _searched = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() { _loading = false; _searched = true; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _kBg,
        body: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_kDark, _kPurple],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new,
                              color: Colors.white, size: 18),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: _controller,
                            focusNode: _focus,
                            textDirection: TextDirection.rtl,
                            onChanged: _onChanged,
                            style: const TextStyle(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'ابحث عن دورة أو ملزمة...',
                              hintStyle: const TextStyle(
                                  color: Color(0xFF9CA3AF), fontSize: 14),
                              prefixIcon: _loading
                                  ? const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: SizedBox(
                                        width: 16, height: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2, color: _kPurple),
                                      ),
                                    )
                                  : const Icon(Icons.search_rounded,
                                      color: Color(0xFF9CA3AF)),
                              suffixIcon: _controller.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.close,
                                          color: Color(0xFF9CA3AF), size: 18),
                                      onPressed: () {
                                        _controller.clear();
                                        _onChanged('');
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Results ─────────────────────────────────────────────────────
            Expanded(
              child: !_searched
                  ? _buildPrompt()
                  : (_courses.isEmpty && _books.isEmpty)
                      ? _buildNoResults()
                      : ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            if (_courses.isNotEmpty) ...[
                              _sectionLabel(
                                  'دورات', _courses.length, Icons.play_circle_outline),
                              const SizedBox(height: 8),
                              ..._courses.map((c) => _CourseResult(
                                    course: c,
                                    inCart: cartState.items
                                        .any((i) => i.courseId == c.id),
                                    onAddToCart: () => _addToCart(
                                        itemType: 'course', courseId: c.id),
                                  )),
                              if (_books.isNotEmpty) const SizedBox(height: 16),
                            ],
                            if (_books.isNotEmpty) ...[
                              _sectionLabel(
                                  'ملازم', _books.length, Icons.description_outlined),
                              const SizedBox(height: 8),
                              ..._books.map((b) => _BookResult(
                                    book: b,
                                    inCart: cartState.items
                                        .any((i) => i.bookId == b.id),
                                    onAddToCart: () => _addToCart(
                                        itemType: 'book', bookId: b.id),
                                  )),
                            ],
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addToCart({
    required String itemType,
    String? courseId,
    String? bookId,
  }) async {
    final ok = await ref.read(cartProvider.notifier).addToCart(
          itemType: itemType,
          courseId: courseId,
          bookId: bookId,
        );
    if (!mounted) return;
    showAppToast(context,
        message:
            ok ? 'تمت الإضافة للسلة' : 'فشلت الإضافة، حاول مجدداً',
        type: ok ? ToastType.success : ToastType.error);
  }

  Widget _buildPrompt() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_rounded, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 14),
          const Text('ابحث عن دورة أو ملزمة',
              style: TextStyle(fontSize: 16, color: Color(0xFF6B7280))),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 14),
          const Text('لا توجد نتائج',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF374151))),
          const SizedBox(height: 4),
          const Text('جرب كلمة بحث مختلفة',
              style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
        ],
      ),
    );
  }

  Widget _sectionLabel(String title, int count, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 15, color: _kPurple),
        const SizedBox(width: 6),
        Text('$title ($count)',
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A))),
      ],
    );
  }
}

// ── Course result card ────────────────────────────────────────────────────────

class _CourseResult extends StatelessWidget {
  final Course course;
  final bool inCart;
  final VoidCallback onAddToCart;

  const _CourseResult({
    required this.course,
    required this.inCart,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: const Border(right: BorderSide(color: _kPurple, width: 3)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: _kPurple.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.play_circle_outline,
                  color: _kPurple, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(course.title,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text('${course.price.toStringAsFixed(0)} د.ب',
                      style: const TextStyle(
                          fontSize: 13,
                          color: _kPurple,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _chip(
                  label: 'تفاصيل',
                  bg: Colors.white,
                  fg: _kPurple,
                  border: _kPurple,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            CourseDetailPage(courseId: course.id)),
                  ),
                ),
                const SizedBox(height: 6),
                _chip(
                  label: inCart ? 'في السلة' : 'أضف',
                  bg: inCart ? const Color(0xFF9CA3AF) : _kPurple,
                  fg: Colors.white,
                  onTap: inCart ? null : onAddToCart,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Book result card ──────────────────────────────────────────────────────────

class _BookResult extends StatelessWidget {
  final Book book;
  final bool inCart;
  final VoidCallback onAddToCart;

  const _BookResult({
    required this.book,
    required this.inCart,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: const Border(right: BorderSide(color: _kGreen, width: 3)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: _kGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.description_outlined,
                  color: _kGreen, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(book.title,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text('${book.price.toStringAsFixed(0)} د.ب',
                      style: const TextStyle(
                          fontSize: 13,
                          color: _kGreen,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _chip(
              label: inCart ? 'في السلة' : 'أضف',
              bg: inCart ? const Color(0xFF9CA3AF) : _kGreen,
              fg: Colors.white,
              onTap: inCart ? null : onAddToCart,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared chip button ────────────────────────────────────────────────────────

Widget _chip({
  required String label,
  required Color bg,
  required Color fg,
  Color? border,
  VoidCallback? onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: border != null ? Border.all(color: border) : null,
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 12, color: fg, fontWeight: FontWeight.w600)),
    ),
  );
}
