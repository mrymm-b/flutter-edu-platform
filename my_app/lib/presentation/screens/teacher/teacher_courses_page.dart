import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_tokens.dart';
import '../../../domain/models/course.dart';
import '../../../domain/models/book.dart';
import '../../providers/teacher_provider.dart';
import '../../providers/books_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/glass_card.dart';
import 'live_session_page.dart';
import 'course_materials_page.dart';

/// Courses tab content — rendered inside TeacherHomePage's IndexedStack.
class TeacherCoursesPage extends ConsumerStatefulWidget {
  const TeacherCoursesPage({super.key});

  @override
  ConsumerState<TeacherCoursesPage> createState() => _TeacherCoursesPageState();
}

class _TeacherCoursesPageState extends ConsumerState<TeacherCoursesPage> {
  int _selectedTab = 0;
  static const _tabs = ['دوراتي', 'ملازمي'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        Expanded(
            child:
                _selectedTab == 0 ? _buildCoursesTab() : _buildBooksTab()),
      ],
    );
  }

  // ── Header + Tabs ──────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    final t = Tok.of(context);
    return Container(
      decoration: BoxDecoration(
        color: t.isDark ? const Color(0xFF1E1E2E) : Colors.white,
        border: Border(bottom: BorderSide(color: t.line)),
      ),
      padding: const EdgeInsets.fromLTRB(
          AppTokens.screenPad, 24, AppTokens.screenPad, 0),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'محتواي',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: t.ink,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: List.generate(_tabs.length, (i) {
                final active = _selectedTab == i;
                final tabLabels = [
                  'teacher_courses_tab_courses',
                  'teacher_courses_tab_books'
                ];
                return Expanded(
                  child: Semantics(
                    identifier: tabLabels[i],
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: active ? t.accentFg : Colors.transparent,
                              width: 2.5,
                            ),
                          ),
                        ),
                        child: Text(
                          _tabs[i],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: active ? t.accentFg : t.muted,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // ── Courses Tab ────────────────────────────────────────────────────────────

  Widget _buildCoursesTab() {
    final t = Tok.of(context);
    final coursesAsync = ref.watch(teacherCoursesProvider);
    return coursesAsync.when(
      loading: () => Center(
          child: CircularProgressIndicator(color: t.accentFg)),
      error: (_, __) => Center(
        child: Text('تعذر تحميل الدورات',
            style: TextStyle(color: t.muted)),
      ),
      data: (courses) {
        if (courses.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.menu_book_outlined, size: 64, color: t.faint),
                const SizedBox(height: 16),
                Text(
                  'لا توجد دورات بعد',
                  style: TextStyle(fontSize: 16, color: t.muted),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(AppTokens.screenPad),
          itemCount: courses.length,
          itemBuilder: (context, i) =>
              _CourseCard(course: courses[i], index: i),
        );
      },
    );
  }

  // ── Books Tab ──────────────────────────────────────────────────────────────

  Widget _buildBooksTab() {
    final t = Tok.of(context);
    final booksAsync = ref.watch(booksProvider);
    final teacherId = ref.watch(authProvider).user?.id;

    return booksAsync.when(
      loading: () => Center(
          child: CircularProgressIndicator(color: t.accentFg)),
      error: (_, __) => Center(
        child: Text('تعذر تحميل الملازم',
            style: TextStyle(color: t.muted)),
      ),
      data: (allBooks) {
        final books = teacherId == null
            ? <Book>[]
            : allBooks.where((b) => b.teacherId == teacherId).toList();

        if (books.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.description_outlined, size: 64, color: t.faint),
                const SizedBox(height: 16),
                Text(
                  'ما رفعت ملازم بعد',
                  style: TextStyle(fontSize: 16, color: t.muted),
                ),
                const SizedBox(height: 8),
                Text(
                  'ارفع الملازم من داخل كل دورة',
                  style: TextStyle(fontSize: 13, color: t.faint),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppTokens.screenPad),
          itemCount: books.length,
          itemBuilder: (context, i) => _BookCard(book: books[i]),
        );
      },
    );
  }
}

// ── Course Card ───────────────────────────────────────────────────────────────

class _CourseCard extends StatelessWidget {
  final Course course;
  final int index;
  const _CourseCard({required this.course, required this.index});

  @override
  Widget build(BuildContext context) {
    final t = Tok.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(18),
        radius: AppTokens.rLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: t.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${course.studentsCount} طالب',
                        style: TextStyle(fontSize: 13, color: t.muted),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: t.accentTint,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${course.price.toStringAsFixed(0)} د.ب',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: t.accentFg,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    identifier: 'teacher_courses_btn_start_live_$index',
                    child: _ActionButton(
                      label: 'لايف',
                      icon: Icons.radio,
                      color: const Color(0xFFDC2626),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LiveSessionPage(
                            courseId: course.id,
                            courseTitle: course.title,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Semantics(
                    identifier: 'teacher_courses_btn_materials_$index',
                    child: _ActionButton(
                      label: 'المحتوى',
                      icon: Icons.description_outlined,
                      color: t.ink,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CourseMaterialsPage(
                            courseId: course.id,
                            courseTitle: course.title,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Book Card ─────────────────────────────────────────────────────────────────

class _BookCard extends StatelessWidget {
  final Book book;
  const _BookCard({required this.book});

  @override
  Widget build(BuildContext context) {
    final t = Tok.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        radius: AppTokens.rLg,
        child: Row(
          children: [
            Container(
              width: 56,
              height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF16A34A), Color(0xFF15803D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.description,
                  color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'ملزمة',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF15803D),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    book.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: t.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${book.pagesCount ?? '-'} صفحة  •  ${book.fileSizeInMB}',
                    style: TextStyle(fontSize: 12, color: t.muted),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${book.price.toStringAsFixed(0)} د.ب',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: t.accentFg,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Action Button ─────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    );
  }
}
