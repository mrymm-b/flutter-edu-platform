import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_tokens.dart';
import '../../providers/enrollments_provider.dart';
import '../../providers/book_purchases_provider.dart';
import '../../providers/messages_provider.dart';
import '../../providers/live_sessions_provider.dart';
import '../../../domain/models/live_session.dart';
import '../../widgets/pdf_download_button.dart';
import '../../../presentation/widgets/atmosphere_background.dart';
import '../../../presentation/widgets/glass_card.dart';
import 'home_page.dart';
import 'chat.dart';
import 'profile.dart';
import 'online_course_view.dart';
import 'student_live_view.dart';
import 'category_online_page.dart';
import 'category_books_page.dart';
import 'schedule_screen.dart';

class MyCourses extends ConsumerStatefulWidget {
  const MyCourses({super.key});

  @override
  ConsumerState<MyCourses> createState() => _MyCoursesState();
}

class _MyCoursesState extends ConsumerState<MyCourses> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final t = Tok.of(context);
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
                      AppTokens.screenPad, 20, AppTokens.screenPad, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'محتواي',
                              style: TextStyle(
                                fontSize: AppTokens.tsH1,
                                fontWeight: FontWeight.w700,
                                color: t.ink,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text('دوراتك وملازمك',
                                style:
                                    TextStyle(fontSize: 13, color: t.muted)),
                          ],
                        ),
                      ),
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
                        child:
                            Icon(Icons.book_rounded, color: t.ink2, size: 20),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Tab Bar ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppTokens.screenPad, 16, AppTokens.screenPad, 0),
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: t.isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : t.bg2,
                    borderRadius:
                        BorderRadius.circular(AppTokens.rSm),
                    border: Border.all(color: t.line),
                  ),
                  child: Row(
                    children: [
                      _tabPill(0, 'دوراتي', 'my_courses_tab_courses', t),
                      _tabPill(1, 'ملازمي', 'my_courses_tab_books', t),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),

              // ── Content ──────────────────────────────────────────────────
              Expanded(
                child: _selectedTab == 0
                    ? _buildCoursesTab(t)
                    : _buildBooksTab(t),
              ),

              // ── Bottom Nav ───────────────────────────────────────────────
              _BottomNav(active: 2, context: context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabPill(int index, String label, String semanticsId, Tok t) {
    final active = _selectedTab == index;
    return Expanded(
      child: Semantics(
        identifier: semanticsId,
        child: GestureDetector(
          onTap: () => setState(() => _selectedTab = index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            margin: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: active
                  ? (t.isDark ? AppTokens.dAccent.withValues(alpha: 0.3) : t.card)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppTokens.rSm - 3),
              border: active
                  ? Border.all(
                      color: t.isDark ? t.accentLine : t.line,
                      width: 1.0)
                  : null,
              boxShadow: active && !t.isDark
                  ? [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 1)),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: active ? t.accentFg : t.muted,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoursesTab(Tok t) {
    final myCoursesAsync = ref.watch(myCoursesProvider);
    return myCoursesAsync.when(
      loading: () => Center(
          child: CircularProgressIndicator(color: t.accentFg)),
      error: (e, _) => Center(
          child: Text('خطأ: $e', style: TextStyle(color: t.muted))),
      data: (courses) {
        if (courses.isEmpty) {
          return _emptyState(
            t: t,
            icon: Icons.school_outlined,
            title: 'ما عندك دورات بعد',
            subtitle: 'اشترك في دورة وابدأ رحلتك التعليمية',
            buttonLabel: 'تصفح الدورات',
            semanticsId: 'my_courses_btn_browse_courses',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CategoryOnlinePage()),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(AppTokens.screenPad),
          itemCount: courses.length,
          itemBuilder: (context, i) => Padding(
            padding: const EdgeInsets.only(bottom: AppTokens.cardGap + 3),
            child: _CourseCard(course: courses[i], index: i, t: t),
          ),
        );
      },
    );
  }

  Widget _buildBooksTab(Tok t) {
    final myBooksAsync = ref.watch(myPurchasedBooksProvider);
    return myBooksAsync.when(
      loading: () => Center(
          child: CircularProgressIndicator(color: t.accentFg)),
      error: (e, _) => Center(
          child: Text('خطأ: $e', style: TextStyle(color: t.muted))),
      data: (books) {
        if (books.isEmpty) {
          return _emptyState(
            t: t,
            icon: Icons.description_outlined,
            title: 'ما عندك ملازم بعد',
            subtitle: 'احصل على ملازم لمساعدتك في المذاكرة',
            buttonLabel: 'تصفح الملازم',
            semanticsId: 'my_courses_btn_browse_books',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CategoryBooksPage()),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(AppTokens.screenPad),
          itemCount: books.length,
          itemBuilder: (context, i) => Padding(
            padding: const EdgeInsets.only(bottom: AppTokens.cardGap + 3),
            child: _BookCard(book: books[i], index: i, t: t),
          ),
        );
      },
    );
  }

  Widget _emptyState({
    required Tok t,
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonLabel,
    required String semanticsId,
    required VoidCallback onTap,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.screenPad),
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
              child: Icon(icon, size: 38, color: t.accentFg),
            ),
            const SizedBox(height: 16),
            Text(title,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: t.ink)),
            const SizedBox(height: 6),
            Text(subtitle,
                style: TextStyle(fontSize: 13, color: t.muted),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Semantics(
              identifier: semanticsId,
              child: PrimaryButton(
                label: buttonLabel,
                semanticsId: '${semanticsId}_inner',
                onPressed: onTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Course Card ───────────────────────────────────────────────────────────────
class _CourseCard extends ConsumerWidget {
  final dynamic course;
  final int index;
  final Tok t;
  const _CourseCard(
      {required this.course, required this.index, required this.t});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveSessions = ref.watch(currentLiveSessionsProvider);
    final LiveSession? activeSession = liveSessions.when(
      data: (sessions) =>
          sessions.where((s) => s.courseId == course.id).firstOrNull,
      loading: () => null,
      error: (_, __) => null,
    );

    return GlassCard(
      radius: AppTokens.rLg,
      child: Column(
        children: [
          // ── Course info bar ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 15, 15, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon tile
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: t.accentTint,
                    borderRadius: BorderRadius.circular(AppTokens.rSm),
                  ),
                  child:
                      Icon(Icons.play_circle_outline, color: t.accentFg, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                      const SizedBox(height: 6),
                      Text(
                        course.title as String,
                        style: TextStyle(
                          fontSize: AppTokens.tsCardT,
                          fontWeight: FontWeight.w700,
                          color: t.ink,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Quick action
                Semantics(
                  identifier: 'my_courses_btn_continue_course_$index',
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              OnlineCourseViewScreen(courseId: course.id)),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: t.accentTint,
                        borderRadius: BorderRadius.circular(AppTokens.rPill),
                        border: Border.all(color: t.accentLine),
                      ),
                      child: Text(
                        'متابعة',
                        style: TextStyle(
                            color: t.accentFg,
                            fontSize: 12,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
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
                Expanded(
                  child: Semantics(
                    identifier: 'my_courses_btn_view_recordings_$index',
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                OnlineCourseViewScreen(courseId: course.id)),
                      ),
                      child: _actionBtn(
                        icon: Icons.play_circle_rounded,
                        label: 'التسجيلات',
                        accent: true,
                        t: t,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Semantics(
                    identifier: 'my_courses_btn_live_stream_$index',
                    child: GestureDetector(
                      onTap: () {
                        if (activeSession != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StudentLiveView(
                                courseId: activeSession.courseId,
                                sessionTitle: activeSession.title,
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('لا يوجد بث مباشر حالياً'),
                              backgroundColor: t.accentFg,
                            ),
                          );
                        }
                      },
                      child: _actionBtn(
                        icon: Icons.live_tv_rounded,
                        label: activeSession != null ? '● بث مباشر' : 'بث مباشر',
                        accent: false,
                        isLive: activeSession != null,
                        t: t,
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

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required bool accent,
    bool isLive = false,
    required Tok t,
  }) {
    final bg = isLive
        ? const Color(0xFFEF4444).withValues(alpha: 0.12)
        : (accent ? t.accentTint : (t.isDark ? Colors.white.withValues(alpha: 0.05) : t.bg2));
    final fg = isLive
        ? const Color(0xFFEF4444)
        : (accent ? t.accentFg : t.ink2);
    final border = isLive
        ? const Color(0xFFEF4444).withValues(alpha: 0.3)
        : (accent ? t.accentLine : t.line);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTokens.rSm),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Flexible(
            child: Text(label,
                style: TextStyle(
                    fontSize: 12.5,
                    color: fg,
                    fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

// ── Book Card ─────────────────────────────────────────────────────────────────
class _BookCard extends StatelessWidget {
  final dynamic book;
  final int index;
  final Tok t;
  const _BookCard({required this.book, required this.index, required this.t});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      radius: AppTokens.rLg,
      child: Column(
        children: [
          // ── Info row — mirrors _CourseCard exactly ────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 15, 15, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon tile — same 48×48 as course card
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
                      // Badge — same style as "دورة أونلاين"
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: t.accentTint,
                          borderRadius:
                              BorderRadius.circular(AppTokens.rPill),
                        ),
                        child: Text('ملزمة',
                            style: TextStyle(
                                fontSize: 10,
                                color: t.accentFg,
                                fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        book.title as String,
                        style: TextStyle(
                          fontSize: AppTokens.tsCardT,
                          fontWeight: FontWeight.w700,
                          color: t.ink,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${book.pagesCount ?? '-'} صفحة · ${book.fileSizeInMB}',
                        style:
                            TextStyle(fontSize: 11.5, color: t.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Divider — same as course card
          Container(height: 1, color: t.line),

          // ── Action buttons row — same padding as course card ──────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Semantics(
              identifier: 'my_courses_btn_download_book_$index',
              child: PdfDownloadButton(
                bookId: book.id as String,
                storagePath: book.pdfUrl as String,
                t: t,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bottom Nav ─────────────────────────────────────────────────────────────────
class _BottomNav extends ConsumerWidget {
  final int active;
  final BuildContext context;
  const _BottomNav({required this.active, required this.context});

  @override
  Widget build(BuildContext _, WidgetRef ref) {
    final t = Tok.of(context);
    final unread = ref
            .watch(myConversationsProvider)
            .valueOrNull
            ?.fold<int>(0, (sum, c) => sum + c.unreadCountStudent) ??
        0;

    return ThemedBottomNavShell(
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Semantics(
                  identifier: 'nav_home',
                  child: _item(Icons.home_rounded, 'الرئيسية', 0, t, () {
                    if (active != 0) {
                      Navigator.pushReplacement(context,
                          MaterialPageRoute(builder: (_) => const HomePage()));
                    }
                  })),
              Semantics(
                  identifier: 'nav_messages',
                  child: _chatItem(unread, t)),
              Semantics(
                  identifier: 'nav_my_courses',
                  child: _item(Icons.book_rounded, 'دوراتي', 2, t, () {
                    if (active != 2) {
                      Navigator.pushReplacement(context,
                          MaterialPageRoute(builder: (_) => const MyCourses()));
                    }
                  }, isCenter: true)),
              Semantics(
                  identifier: 'nav_schedule',
                  child: _item(
                      Icons.calendar_month_rounded, 'جدولي', 3, t, () {
                    if (active != 3) {
                      Navigator.pushReplacement(context,
                          MaterialPageRoute(
                              builder: (_) => const ScheduleScreen()));
                    }
                  })),
              Semantics(
                  identifier: 'nav_profile',
                  child: _item(Icons.person_rounded, 'حسابي', 4, t, () {
                    if (active != 4) {
                      Navigator.pushReplacement(context,
                          MaterialPageRoute(builder: (_) => const Profile()));
                    }
                  })),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chatItem(int unread, Tok t) {
    final isActive = active == 1;
    return GestureDetector(
      onTap: () {
        if (active != 1) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const Chat()));
        }
      },
      child: _navContent(
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(Icons.chat_bubble_rounded,
                color: isActive ? t.accentFg : t.faint, size: 21),
            if (unread > 0)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: Color(0xFFEF4444), shape: BoxShape.circle),
                ),
              ),
          ],
        ),
        label: 'الرسائل',
        isActive: isActive,
        t: t,
      ),
    );
  }

  Widget _item(
    IconData icon,
    String label,
    int index,
    Tok t,
    VoidCallback onTap, {
    bool isCenter = false,
  }) {
    final isActive = active == index;
    final iconSize = isCenter ? 24.0 : 21.0;
    return GestureDetector(
      onTap: onTap,
      child: _navContent(
        icon: Icon(icon, color: isActive ? t.accentFg : t.faint, size: iconSize),
        label: label,
        isActive: isActive,
        t: t,
      ),
    );
  }

  Widget _navContent({
    required Widget icon,
    required String label,
    required bool isActive,
    required Tok t,
  }) =>
      AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive
              ? t.accentFg.withValues(alpha: 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTokens.rSm),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                  fontSize: 10,
                  color: isActive ? t.accentFg : t.faint,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                )),
          ],
        ),
      );
}
