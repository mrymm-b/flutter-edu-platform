import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_tokens.dart';
import '../../../domain/models/conversation.dart';
import '../../providers/messages_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/teacher_provider.dart';
import '../../../presentation/widgets/atmosphere_background.dart';
import '../../../presentation/widgets/glass_card.dart';
import 'home_page.dart';
import 'my_courses.dart';
import 'profile.dart';
import 'category_online_page.dart';
import 'schedule_screen.dart';
import 'student_conversation_detail_page.dart';

class Chat extends ConsumerWidget {
  const Chat({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Tok.of(context);
    final conversationsAsync = ref.watch(myConversationsProvider);
    final authState = ref.watch(authProvider);
    final isStudent = authState.user?.isStudent ?? true;

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
                              'الرسائل',
                              style: TextStyle(
                                fontSize: AppTokens.tsH1,
                                fontWeight: FontWeight.w700,
                                color: t.ink,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text('تواصل مع أساتذتك',
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
                        child: Icon(Icons.chat_bubble_outline_rounded,
                            color: t.ink2, size: 20),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Conversations ────────────────────────────────────────────
              Expanded(
                child: conversationsAsync.when(
                  loading: () => Center(
                      child: CircularProgressIndicator(color: t.accentFg)),
                  error: (err, _) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, color: t.faint, size: 48),
                        const SizedBox(height: 8),
                        Text('حدث خطأ في تحميل المحادثات',
                            style: TextStyle(color: t.muted)),
                        const SizedBox(height: 8),
                        Semantics(
                          identifier: 'chat_btn_retry',
                          child: TextButton(
                            onPressed: () =>
                                ref.invalidate(myConversationsProvider),
                            child: Text('إعادة المحاولة',
                                style: TextStyle(color: t.accentFg)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  data: (conversations) {
                    if (conversations.isEmpty) {
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
                                child: Icon(Icons.chat_bubble_outline_rounded,
                                    size: 38, color: t.accentFg),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'محادثاتك مع الأساتذة هنا',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: t.ink),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'اشترك في دورة للتواصل مع أستاذها',
                                style:
                                    TextStyle(fontSize: 13, color: t.muted),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              Semantics(
                                identifier: 'chat_btn_browse_courses',
                                child: PrimaryButton(
                                  label: 'تصفح الدورات',
                                  semanticsId: 'chat_browse_inner',
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const CategoryOnlinePage(),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.all(AppTokens.screenPad),
                      itemCount: conversations.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppTokens.cardGap),
                      itemBuilder: (context, index) => Semantics(
                        identifier: 'chat_item_conversation_$index',
                        child: _ConversationCard(
                          conversation: conversations[index],
                          isStudent: isStudent,
                          t: t,
                        ),
                      ),
                    );
                  },
                ),
              ),

              // ── Bottom Nav ───────────────────────────────────────────────
              _BottomNav(active: 1, context: context),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Conversation Card ─────────────────────────────────────────────────────────
class _ConversationCard extends ConsumerWidget {
  final Conversation conversation;
  final bool isStudent;
  final Tok t;

  const _ConversationCard({
    required this.conversation,
    required this.isStudent,
    required this.t,
  });

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'أمس';
    } else if (diff.inDays < 7) {
      const days = [
        'الاثنين', 'الثلاثاء', 'الأربعاء',
        'الخميس', 'الجمعة', 'السبت', 'الأحد'
      ];
      return days[dt.weekday - 1];
    }
    return '${dt.day}/${dt.month}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teacherName =
        ref.watch(studentNameProvider(conversation.teacherId)).valueOrNull ??
            'أستاذ';
    final firstLetter = teacherName.isNotEmpty ? teacherName[0] : 'أ';
    final unread = isStudent
        ? conversation.unreadCountStudent
        : conversation.unreadCountTeacher;
    final hasUnread = unread > 0;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StudentConversationDetailPage(
            conversation: conversation,
          ),
        ),
      ),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        radius: AppTokens.rLg,
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: t.avatarDecoration(25),
                  child: Center(
                    child: Text(
                      firstLetter,
                      style: TextStyle(
                        color: t.isDark ? Colors.white : t.accentFg,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                if (hasUnread)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: t.card, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          teacherName,
                          style: TextStyle(
                            fontSize: AppTokens.tsCardT,
                            fontWeight: FontWeight.w700,
                            color: t.ink,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatTime(conversation.lastMessageAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: hasUnread ? t.accentFg : t.faint,
                          fontWeight: hasUnread
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.lastMessage ?? 'ابدأ المحادثة',
                          style: TextStyle(
                            color: hasUnread ? t.ink2 : t.muted,
                            fontSize: 12.5,
                            fontWeight: hasUnread
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: t.accentTint,
                            borderRadius: BorderRadius.circular(
                                AppTokens.rPill),
                            border: t.isDark
                                ? Border.all(
                                    color: AppTokens.dAccentLine
                                        .withValues(alpha: 0.25))
                                : null,
                          ),
                          child: Text(
                            '$unread',
                            style: TextStyle(
                              color: t.accentFg,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
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
          color: isActive ? t.accentFg.withValues(alpha: 0.10) : Colors.transparent,
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
