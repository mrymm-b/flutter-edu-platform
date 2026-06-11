import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_tokens.dart';
import '../../providers/auth_provider.dart';
import '../../providers/teacher_provider.dart';
import '../../providers/messages_provider.dart';
import '../../widgets/atmosphere_background.dart';
import '../../widgets/glass_card.dart';
import 'teacher_courses_page.dart';
import 'teacher_chat_page.dart';
import 'teacher_profile_page.dart';
import 'live_session_page.dart';
import 'upload_material_page.dart';

class TeacherHomePage extends ConsumerStatefulWidget {
  const TeacherHomePage({super.key});

  @override
  ConsumerState<TeacherHomePage> createState() => _TeacherHomePageState();
}

class _TeacherHomePageState extends ConsumerState<TeacherHomePage> {
  int _currentIndex = 0;
  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = [
      _HomeTab(onSwitchToMessages: () => setState(() => _currentIndex = 2)),
      const TeacherCoursesPage(),
      const TeacherChatPage(),
      const TeacherProfilePage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: AtmosphereBackground(
          child: IndexedStack(index: _currentIndex, children: _tabs),
        ),
        bottomNavigationBar: _BottomNav(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
        ),
      ),
    );
  }
}

// ── Bottom Navigation ─────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = Tok.of(context);
    const items = [
      (Icons.home_outlined, Icons.home_rounded, 'الرئيسية'),
      (Icons.menu_book_outlined, Icons.menu_book_rounded, 'دوراتي'),
      (Icons.chat_bubble_outline, Icons.chat_bubble_rounded, 'الرسائل'),
      (Icons.person_outline, Icons.person_rounded, 'حسابي'),
    ];
    const navLabels = [
      'teacher_nav_home',
      'teacher_nav_courses',
      'teacher_nav_chat',
      'teacher_nav_profile',
    ];

    return Container(
      decoration: BoxDecoration(
        color: t.isDark ? const Color(0xFF1E1E2E) : Colors.white,
        border: Border(top: BorderSide(color: t.line)),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 20, offset: Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final active = currentIndex == i;
              return Semantics(
                identifier: navLabels[i],
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: active ? t.accentFg.withValues(alpha: 0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          active ? items[i].$2 : items[i].$1,
                          size: 22,
                          color: active ? t.accentFg : t.muted,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          items[i].$3,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: active ? FontWeight.bold : FontWeight.normal,
                            color: active ? t.accentFg : t.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ── Home Tab ──────────────────────────────────────────────────────────────────

class _HomeTab extends ConsumerWidget {
  final VoidCallback onSwitchToMessages;
  const _HomeTab({required this.onSwitchToMessages});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Tok.of(context);
    final user = ref.watch(authProvider).user;
    final coursesAsync = ref.watch(teacherCoursesProvider);
    final totalStudentsAsync = ref.watch(teacherTotalStudentsProvider);
    final unreadCountAsync = ref.watch(teacherUnreadCountProvider);

    final totalStudents = totalStudentsAsync.when(
        data: (n) => n, loading: () => 0, error: (_, __) => 0);
    final totalCourses = coursesAsync.when(
        data: (c) => c.length, loading: () => 0, error: (_, __) => 0);
    final unreadCount = unreadCountAsync.when(
        data: (n) => n, loading: () => 0, error: (_, __) => 0);

    return Column(
      children: [
        // ── Flat header ──────────────────────────────────────────────────────
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppTokens.screenPad, 16, AppTokens.screenPad, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('مرحباً 👋',
                              style: TextStyle(fontSize: 13, color: t.muted)),
                          const SizedBox(height: 2),
                          Text(
                            'أ. ${user?.fullName ?? ''}',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: t.ink),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: t.accentTint,
                        shape: BoxShape.circle,
                        border: Border.all(color: t.accentLine),
                      ),
                      child:
                          Icon(Icons.person_rounded, color: t.accentFg, size: 24),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        value: '$totalStudents',
                        label: 'طالب',
                        icon: Icons.people_rounded,
                        t: t,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatCard(
                        value: '$totalCourses',
                        label: 'دورة',
                        icon: Icons.menu_book_rounded,
                        t: t,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatCard(
                        value: unreadCount > 0 ? '$unreadCount' : '—',
                        label: 'رسائل',
                        icon: Icons.chat_bubble_rounded,
                        t: t,
                        highlight: unreadCount > 0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // ── Content ──────────────────────────────────────────────────────────
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                AppTokens.screenPad, 14, AppTokens.screenPad, 24),
            children: [
              _LiveButton(coursesAsync: coursesAsync),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.upload_file_rounded,
                      label: 'رفع ملزمة',
                      color: const Color(0xFF16A34A),
                      bgColor: const Color(0xFFF0FDF4),
                      onTap: () {
                        final courses = coursesAsync.value;
                        final courseId = courses?.isNotEmpty == true
                            ? courses!.first.id
                            : '';
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                UploadMaterialPage(courseId: courseId),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.chat_bubble_rounded,
                      label: 'الرسائل',
                      color: t.accentFg,
                      bgColor: t.accentTint,
                      badge: unreadCount,
                      onTap: onSwitchToMessages,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'آخر النشاطات',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: t.ink),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: t.accentTint,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'حديثاً',
                      style: TextStyle(
                          fontSize: 12,
                          color: t.accentFg,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const _ActivitySection(),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Tok t;
  final bool highlight;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.t,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 13,
                  color: highlight
                      ? const Color(0xFFFBBF24)
                      : t.accentFg),
              const SizedBox(width: 3),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: highlight ? const Color(0xFFFBBF24) : t.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: t.muted)),
        ],
      ),
    );
  }
}

// ── Live Button ───────────────────────────────────────────────────────────────

class _LiveButton extends StatelessWidget {
  final AsyncValue coursesAsync;
  const _LiveButton({required this.coursesAsync});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: 'teacher_home_btn_start_live',
      child: GestureDetector(
        onTap: () {
          final courses = coursesAsync.value as List?;
          final courseId =
              courses?.isNotEmpty == true ? courses!.first.id : 'demo';
          final courseTitle =
              courses?.isNotEmpty == true ? courses!.first.title : 'بث مباشر';
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  LiveSessionPage(courseId: courseId, courseTitle: courseTitle),
            ),
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.radio_rounded,
                    color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ابدأ البث المباشر',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'طلابك بانتظارك الآن',
                      style: TextStyle(color: Color(0xFFFECACA), fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left, color: Colors.white, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Quick Action Card ─────────────────────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  final int badge;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    final t = Tok.of(context);
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                if (badge > 0)
                  Positioned(
                    top: -2,
                    left: -2,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$badge',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: t.ink),
              ),
            ),
            Icon(Icons.chevron_left, size: 18, color: t.faint),
          ],
        ),
      ),
    );
  }
}

// ── Activity Section ──────────────────────────────────────────────────────────

class _ActivitySection extends ConsumerWidget {
  const _ActivitySection();

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays == 1) return 'أمس';
    return 'منذ ${diff.inDays} أيام';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Tok.of(context);
    final sessionsAsync = ref.watch(teacherRecentSessionsProvider);
    final conversationsAsync = ref.watch(myConversationsProvider);

    if (sessionsAsync.isLoading || conversationsAsync.isLoading) {
      return SizedBox(
          height: 60,
          child: Center(
              child: CircularProgressIndicator(color: t.accentFg)));
    }

    final sessions = sessionsAsync.value ?? [];
    final conversations = conversationsAsync.value ?? [];
    final unreadConvos =
        conversations.where((c) => c.unreadCountTeacher > 0).toList();

    final items = <_ActivityItem>[];
    for (final s in sessions.take(2)) {
      items.add(_ActivityItem(
        icon: Icons.live_tv_rounded,
        iconBg: const Color(0xFFF0FDF4),
        iconColor: const Color(0xFF16A34A),
        title: s.title,
        subtitle: _timeAgo(s.endedAt ?? s.startedAt),
        tag: 'بث',
        tagColor: const Color(0xFF16A34A),
        time: s.endedAt ?? s.startedAt ?? s.createdAt,
      ));
    }
    for (final c in unreadConvos.take(2)) {
      items.add(_ActivityItem(
        icon: Icons.chat_bubble_rounded,
        iconBg: t.accentTint,
        iconColor: t.accentFg,
        title: 'رسالة جديدة',
        subtitle: _timeAgo(c.lastMessageAt),
        tag: '${c.unreadCountTeacher} جديد',
        tagColor: t.accentFg,
        time: c.lastMessageAt ?? c.createdAt,
      ));
    }
    items.sort((a, b) => b.time.compareTo(a.time));

    if (items.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, color: t.faint, size: 24),
            const SizedBox(width: 10),
            Text('لا توجد نشاطات حديثة',
                style: TextStyle(color: t.muted, fontSize: 14)),
          ],
        ),
      );
    }

    return Column(
      children: items
          .take(3)
          .map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ActivityCard(item: item),
              ))
          .toList(),
    );
  }
}

class _ActivityItem {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String tag;
  final Color tagColor;
  final DateTime time;

  _ActivityItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.tagColor,
    required this.time,
  });
}

class _ActivityCard extends StatelessWidget {
  final _ActivityItem item;
  const _ActivityCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final t = Tok.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: item.iconBg,
                borderRadius: BorderRadius.circular(12)),
            child: Icon(item.icon, color: item.iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: t.ink,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(item.subtitle,
                    style: TextStyle(color: t.muted, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: item.tagColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              item.tag,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: item.tagColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
