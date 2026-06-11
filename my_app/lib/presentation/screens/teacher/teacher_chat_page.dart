import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_tokens.dart';
import '../../../domain/models/conversation.dart';
import '../../providers/messages_provider.dart';
import '../../providers/teacher_provider.dart';
import '../../widgets/glass_card.dart';
import 'teacher_conversation_detail_page.dart';

class TeacherChatPage extends ConsumerWidget {
  const TeacherChatPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Tok.of(context);
    final conversationsAsync = ref.watch(myConversationsProvider);

    return Column(
      children: [
        // ── Header ──────────────────────────────────────────────────────────
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppTokens.screenPad, 16, AppTokens.screenPad, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الرسائل',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: t.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'محادثاتك مع طلابك',
                      style: TextStyle(fontSize: 13, color: t.muted),
                    ),
                  ],
                ),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: t.accentTint,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.chat_bubble_rounded,
                      color: t.accentFg, size: 20),
                ),
              ],
            ),
          ),
        ),

        Divider(height: 1, color: t.line),

        // ── List ────────────────────────────────────────────────────────────
        Expanded(
          child: conversationsAsync.when(
            loading: () =>
                Center(child: CircularProgressIndicator(color: t.accentFg)),
            error: (_, __) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      color: Colors.red, size: 48),
                  const SizedBox(height: 8),
                  Text('تعذر تحميل الرسائل',
                      style: TextStyle(color: t.muted)),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () =>
                        ref.invalidate(myConversationsProvider),
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            ),
            data: (conversations) {
              if (conversations.isEmpty) {
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
                        child: Icon(Icons.chat_bubble_outline_rounded,
                            size: 38, color: t.accentFg),
                      ),
                      const SizedBox(height: 16),
                      Text('لا توجد رسائل بعد',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: t.ink)),
                      const SizedBox(height: 6),
                      Text('ستظهر محادثات طلابك هنا',
                          style: TextStyle(fontSize: 13, color: t.muted)),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(AppTokens.screenPad),
                itemCount: conversations.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) => Semantics(
                  identifier: 'teacher_chat_item_conversation_$i',
                  child: _ConversationCard(
                    conversation: conversations[i],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TeacherConversationDetailPage(
                          conversation: conversations[i],
                        ),
                      ),
                    ).then((_) => ref.invalidate(myConversationsProvider)),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ConversationCard extends ConsumerWidget {
  final Conversation conversation;
  final VoidCallback onTap;

  const _ConversationCard({required this.conversation, required this.onTap});

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'أمس';
    } else if (diff.inDays < 7) {
      const days = ['الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
      return days[dt.weekday - 1];
    }
    return '${dt.day}/${dt.month}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Tok.of(context);
    final unread = conversation.unreadCountTeacher;
    final studentNameAsync =
        ref.watch(studentNameProvider(conversation.studentId));
    final studentName = studentNameAsync.when(
      data: (name) => name,
      loading: () => '...',
      error: (_, __) => 'طالب',
    );
    final hasUnread = unread > 0;

    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        lightColor: hasUnread ? t.accentTint : null,
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6264A7), Color(0xFF464775)],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Icon(Icons.person_rounded,
                      color: Colors.white, size: 24),
                ),
                if (hasUnread)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: t.isDark
                                ? const Color(0xFF1E1E2E)
                                : Colors.white,
                            width: 2),
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
                          studentName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: hasUnread
                                ? FontWeight.bold
                                : FontWeight.w600,
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
                          color: hasUnread ? t.accentFg : t.muted,
                          fontWeight: hasUnread
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          conversation.lastMessage ?? 'ابدأ المحادثة',
                          style: TextStyle(
                            color: hasUnread ? t.ink2 : t.muted,
                            fontSize: 13,
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
                            color: t.accentFg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$unread',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
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
