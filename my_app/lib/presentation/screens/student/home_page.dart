import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_tokens.dart';
import '../../../core/utils/toast.dart';
import '../../../domain/models/live_session.dart';
import '../../../domain/models/conversation.dart';
import '../../providers/enrollments_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/live_sessions_provider.dart';
import '../../providers/messages_provider.dart';
import '../../providers/teacher_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../../presentation/widgets/atmosphere_background.dart';
import '../../../presentation/widgets/glass_card.dart';
import 'cart.dart';
import 'notifications_page.dart';
import 'category_online_page.dart';
import 'category_books_page.dart';
import 'my_courses.dart';
import 'chat.dart';
import 'profile.dart';
import 'private_lessons_page.dart';
import 'online_course_view.dart';
import 'student_live_view.dart';
import 'search_page.dart';
import 'schedule_screen.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cartProvider.notifier).loadCart();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Tok.of(context);

    final user = ref.watch(authProvider).user;
    final myCoursesAsync = ref.watch(myCoursesProvider);
    final liveSessionsAsync = ref.watch(currentLiveSessionsProvider);
    final upcomingAsync = ref.watch(upcomingLiveSessionsProvider);
    final conversationsAsync = ref.watch(myConversationsProvider);
    final cartCount = ref.watch(cartProvider).itemCount;
    final unreadNotifCount =
        ref.watch(unreadNotificationsCountProvider).valueOrNull ?? 0;
    final enrollments = ref.watch(myEnrollmentsProvider).valueOrNull ?? [];
    final enrolledCourseIds = enrollments.map((e) => e.courseId).toSet();
    final name = user?.fullName ?? 'الطالب';
    final firstLetter = name.isNotEmpty ? name[0] : 'ط';

    // Live session toast
    ref.listen<AsyncValue<List<LiveSession>>>(currentLiveSessionsProvider,
        (prev, next) {
      final prevList = (prev?.valueOrNull ?? [])
          .where((s) => enrolledCourseIds.contains(s.courseId))
          .toList();
      final nextList = (next.valueOrNull ?? [])
          .where((s) => enrolledCourseIds.contains(s.courseId))
          .toList();
      if (prevList.isEmpty && nextList.isNotEmpty && mounted) {
        final session = nextList.first;
        showAppToast(
          context,
          message: 'بدأت جلسة مباشرة في ${session.title}!',
          icon: Icons.circle,
          duration: const Duration(seconds: 8),
          action: SnackBarAction(
            label: 'انضم الآن',
            textColor: Colors.white,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StudentLiveView(
                  courseId: session.courseId,
                  sessionTitle: session.title,
                ),
              ),
            ),
          ),
        );
      }
    });

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: AtmosphereBackground(
          child: Column(
            children: [
              // ── Status-bar-aware top spacing + header row ──────────────
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppTokens.screenPad, 14, AppTokens.screenPad, 0),
                  child: Column(
                    children: [
                      _buildGreetingRow(t, name, firstLetter, cartCount,
                          unreadNotifCount, context),
                      const SizedBox(height: 14),
                      _buildSearchBar(t, context),
                    ],
                  ),
                ),
              ),

              // ── Scrollable body ────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                      AppTokens.screenPad, 20, AppTokens.screenPad, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 0 — Live banner
                      liveSessionsAsync.when(
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (sessions) {
                          final relevant = sessions
                              .where((s) =>
                                  enrolledCourseIds.contains(s.courseId))
                              .toList();
                          if (relevant.isEmpty) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(
                                bottom: AppTokens.sectionGap),
                            child: _LiveBanner(
                                session: relevant.first, t: t),
                          );
                        },
                      ),

                      // 2 — Continue learning
                      myCoursesAsync.when(
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (courses) {
                          if (courses.isEmpty) return const SizedBox.shrink();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionLabel('أكمل تعلّمك', t),
                              const SizedBox(height: 10),
                              _ContinueLearningCard(
                                t: t,
                                course: courses.first,
                                enrollment: enrollments
                                    .where(
                                        (e) => e.courseId == courses.first.id)
                                    .firstOrNull,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => OnlineCourseViewScreen(
                                        courseId: courses.first.id),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppTokens.sectionGap),
                            ],
                          );
                        },
                      ),

                      // 3 — Upcoming sessions
                      upcomingAsync.when(
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (sessions) {
                          final upcoming = sessions.take(2).toList();
                          if (upcoming.isEmpty) return const SizedBox.shrink();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionLabel('الجلسات القادمة', t),
                              const SizedBox(height: 10),
                              ...upcoming.map(
                                  (s) => _UpcomingRow(session: s, t: t)),
                              const SizedBox(height: AppTokens.sectionGap),
                            ],
                          );
                        },
                      ),

                      // 4 — Bento grid (no section title — flows after continue-learning)
                      _BentoGrid(t: t, ctx: context),

                      // 5 — Last message
                      conversationsAsync.when(
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (conversations) {
                          if (conversations.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: AppTokens.sectionGap),
                              _SectionLabel('آخر رسالة', t),
                              const SizedBox(height: 10),
                              _LastMessageRow(
                                  conversation: conversations.first, t: t),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              // ── Bottom nav ────────────────────────────────────────────
              _BottomNav(active: 0, context: context),
            ],
          ),
        ),
      ),
    );
  }

  // ── Greeting row ────────────────────────────────────────────────────────────
  Widget _buildGreetingRow(Tok t, String name, String firstLetter,
      int cartCount, int unreadNotifCount, BuildContext ctx) {
    return Row(
      children: [
        // Avatar
        Container(
          width: 40,
          height: 40,
          decoration: t.avatarDecoration(20),
          child: Center(
            child: Text(
              firstLetter,
              style: TextStyle(
                color: t.isDark ? Colors.white : t.accentFg,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Greeting text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'مرحباً،',
                style: TextStyle(fontSize: 11.5, color: t.muted, height: 1.2),
              ),
              Text(
                name,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: t.ink,
                    height: 1.2),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        // Bell
        Semantics(
          label: 'الإشعارات',
          identifier: 'home_btn_notifications',
          child: GestureDetector(
            onTap: () => Navigator.push(ctx,
                MaterialPageRoute(builder: (_) => const NotificationsPage())),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _iconBtn(Icons.notifications_outlined, t),
                if (unreadNotifCount > 0)
                  Positioned(
                    top: -2,
                    left: -2,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                          color: Color(0xFFEF4444), shape: BoxShape.circle),
                      child: Center(
                        child: Text(
                          unreadNotifCount > 9 ? '9+' : '$unreadNotifCount',
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
        const SizedBox(width: 8),
        // Cart
        Semantics(
          label: 'سلة المشتريات',
          identifier: 'home_btn_open_cart',
          child: GestureDetector(
            onTap: () => Navigator.push(ctx,
                MaterialPageRoute(builder: (_) => const CartScreen())),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _iconBtn(Icons.shopping_bag_outlined, t),
                if (cartCount > 0)
                  Positioned(
                    top: -2,
                    left: -2,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                          color: Color(0xFFEF4444), shape: BoxShape.circle),
                      constraints:
                          const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '$cartCount',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _iconBtn(IconData icon, Tok t) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: t.isDark
            ? Colors.white.withValues(alpha: 0.06)
            : t.bg2,
        shape: BoxShape.circle,
        border: Border.all(color: t.line),
      ),
      child: Icon(icon, color: t.ink2, size: 20),
    );
  }

  // ── Search bar ──────────────────────────────────────────────────────────────
  Widget _buildSearchBar(Tok t, BuildContext ctx) {
    return Semantics(
      identifier: 'home_btn_search',
      child: GestureDetector(
        onTap: () => Navigator.push(
            ctx, MaterialPageRoute(builder: (_) => const SearchPage())),
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: t.isDark
                ? Colors.white.withValues(alpha: 0.045)
                : t.bg2,
            borderRadius: BorderRadius.circular(AppTokens.rInput),
            border: Border.all(
              color: t.isDark
                  ? Colors.white.withValues(alpha: 0.10)
                  : t.line,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.search_rounded, color: t.faint, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'ابحث عن دورة أو ملزمة…',
                  style: TextStyle(fontSize: 14, color: t.faint),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section label ──────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  final Tok t;
  const _SectionLabel(this.text, this.t);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          fontSize: AppTokens.tsSecLbl,
          fontWeight: FontWeight.w600,
          color: t.ink,
        ),
      );
}

// ── Live Banner ────────────────────────────────────────────────────────────────
class _LiveBanner extends StatelessWidget {
  final LiveSession session;
  final Tok t;
  const _LiveBanner({required this.session, required this.t});

  @override
  Widget build(BuildContext context) {
    final startedAt = session.startedAt;
    final timeLabel = startedAt != null
        ? 'بدأت ${startedAt.hour.toString().padLeft(2, '0')}:${startedAt.minute.toString().padLeft(2, '0')}'
        : '';
    return Semantics(
      identifier: 'home_banner_live_session',
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StudentLiveView(
              courseId: session.courseId,
              sessionTitle: session.title,
            ),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withValues(alpha: t.isDark ? 0.12 : 0.08),
            borderRadius: BorderRadius.circular(AppTokens.rMd),
            border: Border.all(
                color: const Color(0xFFEF4444)
                    .withValues(alpha: t.isDark ? 0.35 : 0.3)),
          ),
          child: Row(
            children: [
              const _PulseDot(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('جلسة مباشرة — ${session.title}',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFDC2626))),
                    if (timeLabel.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(timeLabel,
                          style: TextStyle(
                              fontSize: 11,
                              color: const Color(0xFFEF4444)
                                  .withValues(alpha: 0.8))),
                    ],
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(AppTokens.rSm),
                ),
                child: const Text('انضم الآن',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulseDot extends StatelessWidget {
  const _PulseDot();

  @override
  Widget build(BuildContext context) => Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
            color: Color(0xFFEF4444), shape: BoxShape.circle),
      );
}

// ── Continue Learning Card ─────────────────────────────────────────────────────
class _ContinueLearningCard extends ConsumerWidget {
  final Tok t;
  final dynamic course;
  final dynamic enrollment;
  final VoidCallback onTap;
  const _ContinueLearningCard({
    required this.t,
    required this.course,
    required this.enrollment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teacherName =
        ref.watch(studentNameProvider(course.teacherId)).valueOrNull ?? 'المعلم';
    final progress = (enrollment?.progress ?? 0.0) as double;
    final progressFraction = (progress / 100).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: EdgeInsets.zero,
        radius: AppTokens.rMd,
        child: SizedBox(
          height: 122,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTokens.rMd),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Right: purple accent strip ───────────────────────────────
                Container(
                  width: 58,
                  color: t.accentFg,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.play_circle_filled_rounded,
                          color: Colors.white, size: 28),
                      const SizedBox(height: 6),
                      Text(
                        '${progress.toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'مكتمل',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
                // ── Left: content ────────────────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 13, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Title + teacher
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              course.title as String,
                              style: TextStyle(
                                fontSize: AppTokens.tsCardT,
                                fontWeight: FontWeight.w700,
                                color: t.ink,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'أ. $teacherName',
                              style: TextStyle(fontSize: 12, color: t.muted),
                            ),
                          ],
                        ),
                        // Progress bar + resume button
                        Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: LinearProgressIndicator(
                                value: progressFraction,
                                backgroundColor: t.accentTint,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    t.accentFg),
                                minHeight: 5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Semantics(
                              identifier: 'home_btn_resume_course',
                              child: Container(
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: t.accentFg,
                                  borderRadius:
                                      BorderRadius.circular(AppTokens.rSm),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'متابعة',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(width: 5),
                                    Icon(Icons.play_arrow_rounded,
                                        color: Colors.white, size: 13),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Upcoming Row ───────────────────────────────────────────────────────────────
class _UpcomingRow extends StatelessWidget {
  final LiveSession session;
  final Tok t;
  const _UpcomingRow({required this.session, required this.t});

  @override
  Widget build(BuildContext context) {
    final dt = session.scheduledAt;
    final now = DateTime.now();
    String timeLabel = '';
    if (dt != null) {
      final diff = dt.difference(now);
      final time =
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      if (diff.inDays == 0) {
        timeLabel = 'اليوم $time';
      } else if (diff.inDays == 1) {
        timeLabel = 'غداً $time';
      } else {
        timeLabel = '${dt.day}/${dt.month} $time';
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.cardGap),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        radius: AppTokens.rMd,
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: t.accentTint,
                borderRadius: BorderRadius.circular(AppTokens.rSm),
              ),
              child: Icon(Icons.calendar_today_outlined,
                  size: 18, color: t.accentFg),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(session.title,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: t.ink),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (timeLabel.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(timeLabel,
                        style: TextStyle(fontSize: 11, color: t.muted)),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: t.accentTint,
                borderRadius: BorderRadius.circular(AppTokens.rPill),
              ),
              child: Text('قادم',
                  style: TextStyle(
                      fontSize: 11,
                      color: t.accentFg,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bento Grid ─────────────────────────────────────────────────────────────────
class _BentoGrid extends StatelessWidget {
  final Tok t;
  final BuildContext ctx;
  const _BentoGrid({required this.t, required this.ctx});

  static const _gap = 8.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Row 1: hero card (دورات أونلاين) + tall side card (ملازم PDF)
        SizedBox(
          height: 144,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 2,
                child: _HeroCell(t: t, ctx: ctx),
              ),
              const SizedBox(width: _gap),
              Expanded(
                child: _BentoCell(
                  t: t,
                  icon: Icons.description_rounded,
                  title: 'ملازم PDF',
                  subtitle: 'تحميل وقراءة',
                  semanticId: 'home_bento_books',
                  onTap: () => Navigator.push(ctx,
                      MaterialPageRoute(
                          builder: (_) => const CategoryBooksPage())),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: _gap),
        // Row 2: دروس خصوصية + حاسبة المعدل
        SizedBox(
          height: 115,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _BentoCell(
                  t: t,
                  icon: Icons.school_rounded,
                  title: 'دروس خصوصية',
                  subtitle: 'أونلاين · حضوري',
                  semanticId: 'home_bento_private_lessons',
                  onTap: () => Navigator.push(ctx,
                      MaterialPageRoute(
                          builder: (_) => const PrivateLessonsPage())),
                ),
              ),
              const SizedBox(width: _gap),
              Expanded(
                child: _BentoCell(
                  t: t,
                  icon: Icons.calculate_rounded,
                  title: 'حاسبة المعدل',
                  subtitle: 'احسب معدلك',
                  semanticId: 'home_bento_gpa',
                  comingSoon: true,
                  onTap: () => ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: const Text('حاسبة المعدل — قريباً'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: t.accentFg,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Hero cell — solid purple gradient, white text
class _HeroCell extends StatelessWidget {
  final Tok t;
  final BuildContext ctx;
  const _HeroCell({required this.t, required this.ctx});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: 'home_bento_online_courses',
      child: GestureDetector(
        onTap: () => Navigator.push(
            ctx, MaterialPageRoute(builder: (_) => const CategoryOnlinePage())),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4E4CA6), Color(0xFF7577BC)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(AppTokens.rLg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon tile
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppTokens.rSm),
                ),
                child: const Icon(Icons.play_circle_filled_rounded,
                    color: Colors.white, size: 24),
              ),
              const Spacer(),
              const Text(
                'دورات أونلاين',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'شروحات مباشرة + تسجيلات',
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.7)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Secondary bento cell — GlassCard style
class _BentoCell extends StatelessWidget {
  final Tok t;
  final IconData icon;
  final String title;
  final String subtitle;
  final String semanticId;
  final VoidCallback onTap;
  final bool comingSoon;

  const _BentoCell({
    required this.t,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.semanticId,
    required this.onTap,
    this.comingSoon = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: semanticId,
      child: GestureDetector(
        onTap: onTap,
        child: GlassCard(
          padding: const EdgeInsets.all(13),
          radius: AppTokens.rLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: t.accentTint,
                      borderRadius: BorderRadius.circular(AppTokens.rSm),
                    ),
                    child: Icon(icon, color: t.accentFg, size: 20),
                  ),
                  if (comingSoon)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: t.bg2,
                        borderRadius:
                            BorderRadius.circular(AppTokens.rPill),
                        border: Border.all(color: t.line),
                      ),
                      child: Text('قريباً',
                          style: TextStyle(
                              fontSize: 9,
                              color: t.muted,
                              fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
              const Spacer(),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: t.ink,
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: TextStyle(fontSize: 10.5, color: t.muted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Last Message Row ───────────────────────────────────────────────────────────
class _LastMessageRow extends ConsumerWidget {
  final Conversation conversation;
  final Tok t;
  const _LastMessageRow({required this.conversation, required this.t});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teacherName =
        ref.watch(studentNameProvider(conversation.teacherId)).valueOrNull ??
            'أستاذ';
    final firstLetter = teacherName.isNotEmpty ? teacherName[0] : 'أ';
    final hasUnread = conversation.unreadCountStudent > 0;

    return Semantics(
      identifier: 'nav_messages',
      child: GestureDetector(
        onTap: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Chat()),
        ),
        child: GlassCard(
          padding: const EdgeInsets.all(14),
          radius: AppTokens.rMd,
          child: Row(
            children: [
              // Avatar
              Container(
                width: 44,
                height: 44,
                decoration: t.avatarDecoration(22),
                child: Center(
                  child: Text(firstLetter,
                      style: TextStyle(
                          color: t.isDark ? Colors.white : t.accentFg,
                          fontWeight: FontWeight.w700,
                          fontSize: 16)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(teacherName,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: t.ink)),
                        if (conversation.lastMessageAt != null)
                          Text(_formatTime(conversation.lastMessageAt!),
                              style:
                                  TextStyle(fontSize: 11, color: t.muted)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.lastMessage ?? 'ابدأ المحادثة',
                            style: TextStyle(
                                fontSize: 12,
                                color:
                                    hasUnread ? t.ink2 : t.muted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasUnread) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: t.accentTint,
                              borderRadius:
                                  BorderRadius.circular(AppTokens.rPill),
                              border: t.isDark
                                  ? Border.all(
                                      color: AppTokens.dAccentLine
                                          .withValues(alpha: 0.25))
                                  : null,
                            ),
                            child: Text(
                                '${conversation.unreadCountStudent}',
                                style: TextStyle(
                                    color: t.accentFg,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'أمس';
    }
    return '${dt.day}/${dt.month}';
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
              // ── Center tab: دوراتي — hero position ────────────────────────
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
      child: _navItemContent(
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
      child: _navItemContent(
        icon: Icon(icon, color: isActive ? t.accentFg : t.faint, size: iconSize),
        label: label,
        isActive: isActive,
        t: t,
      ),
    );
  }

  Widget _navItemContent({
    required Widget icon,
    required String label,
    required bool isActive,
    required Tok t,
  }) {
    return AnimatedContainer(
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
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isActive ? t.accentFg : t.faint,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
