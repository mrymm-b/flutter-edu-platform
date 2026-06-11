import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/live_chat_provider.dart';
import '../providers/auth_provider.dart';

const _kPurple = Color(0xFF6264A7);
const _kReactions = ['👍', '❤️', '😂', '👏', '🔥', '🤔'];

class LiveChatPanel extends ConsumerStatefulWidget {
  final String sessionId;
  final bool isTeacher;
  final VoidCallback onClose;

  const LiveChatPanel({
    super.key,
    required this.sessionId,
    required this.isTeacher,
    required this.onClose,
  });

  @override
  ConsumerState<LiveChatPanel> createState() => _LiveChatPanelState();
}

class _LiveChatPanelState extends ConsumerState<LiveChatPanel> {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  String? _replyToId;
  String? _replyToText;

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    ref.read(liveChatProvider(widget.sessionId).notifier).sendText(
          text,
          replyToId: _replyToId,
        );
    _textCtrl.clear();
    setState(() {
      _replyToId = null;
      _replyToText = null;
    });
  }

  void _setReply(SessionMessage msg) {
    setState(() {
      _replyToId = msg.id;
      _replyToText = msg.message;
    });
  }

  void _clearReply() => setState(() {
        _replyToId = null;
        _replyToText = null;
      });

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(liveChatProvider(widget.sessionId));
    final messagesAsync = ref.watch(sessionMessagesStreamProvider(widget.sessionId));
    final currentUserId = ref.read(authProvider).user?.id ?? '';

    // Sync stream → notifier so unread count works
    ref.listen(sessionMessagesStreamProvider(widget.sessionId), (_, next) {
      next.whenData(
        (msgs) => ref.read(liveChatProvider(widget.sessionId).notifier).onNewMessages(msgs),
      );
    });

    final pinned = chatState.pinnedMessage;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xEE0F0F1A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          // ── Drag handle ──────────────────────────────────────────────────
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Header ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 8, 0),
            child: Row(
              children: [
                const Icon(Icons.chat_bubble_rounded, color: _kPurple, size: 16),
                const SizedBox(width: 8),
                const Text(
                  'الشات المباشر',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    fontFamily: 'Cairo',
                  ),
                ),
                const Spacer(),
                // Mute toggle
                IconButton(
                  onPressed: () =>
                      ref.read(liveChatProvider(widget.sessionId).notifier).toggleMute(),
                  icon: Icon(
                    chatState.isMuted ? Icons.notifications_off : Icons.notifications,
                    color: chatState.isMuted ? Colors.white38 : Colors.white54,
                    size: 18,
                  ),
                  tooltip: chatState.isMuted ? 'إلغاء الكتم' : 'كتم',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
                IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close_rounded, color: Colors.white38, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              ],
            ),
          ),

          // ── Pinned message ───────────────────────────────────────────────
          if (pinned != null)
            GestureDetector(
              onTap: widget.isTeacher
                  ? () => ref
                      .read(liveChatProvider(widget.sessionId).notifier)
                      .unpinMessage()
                  : null,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _kPurple.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _kPurple.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.push_pin, color: _kPurple, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        pinned.message,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontFamily: 'Cairo',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.isTeacher)
                      const Icon(Icons.close, color: Colors.white38, size: 14),
                  ],
                ),
              ),
            ),

          // ── Reactions bar ────────────────────────────────────────────────
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
              children: _kReactions
                  .map((e) => _ReactionChip(
                        emoji: e,
                        onTap: () => ref
                            .read(liveChatProvider(widget.sessionId).notifier)
                            .sendReaction(e),
                      ))
                  .toList(),
            ),
          ),

          const Divider(color: Colors.white12, height: 1),

          // ── Messages ─────────────────────────────────────────────────────
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: _kPurple, strokeWidth: 2),
              ),
              error: (_, __) => const Center(
                child: Text('تعذر تحميل الرسائل',
                    style: TextStyle(color: Colors.white38, fontFamily: 'Cairo')),
              ),
              data: (messages) {
                _scrollToBottom();
                if (messages.isEmpty) {
                  return const _EmptyChat();
                }
                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final msg = messages[i];
                    return _MessageTile(
                      key: ValueKey(msg.id),
                      msg: msg,
                      isMine: msg.senderId == currentUserId,
                      isTeacher: widget.isTeacher,
                      onReply: () => _setReply(msg),
                      onDelete: widget.isTeacher
                          ? () => ref
                              .read(liveChatProvider(widget.sessionId).notifier)
                              .deleteMessage(msg.id)
                          : null,
                      onPin: widget.isTeacher && msg.type == MessageType.text
                          ? () => ref
                              .read(liveChatProvider(widget.sessionId).notifier)
                              .pinMessage(msg.id)
                          : null,
                    );
                  },
                );
              },
            ),
          ),

          // ── Reply preview ────────────────────────────────────────────────
          if (_replyToText != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              color: Colors.white.withValues(alpha: 0.05),
              child: Row(
                children: [
                  const Icon(Icons.reply, color: _kPurple, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _replyToText!,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 11, fontFamily: 'Cairo'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: _clearReply,
                    icon: const Icon(Icons.close, color: Colors.white38, size: 16),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                ],
              ),
            ),

          // ── Input ────────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textCtrl,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                        color: Colors.white, fontFamily: 'Cairo', fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'اكتب رسالة...',
                      hintStyle: const TextStyle(
                          color: Colors.white38, fontFamily: 'Cairo', fontSize: 13),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.08),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _send,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(color: _kPurple, shape: BoxShape.circle),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
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

// ── Reaction Chip ─────────────────────────────────────────────────────────────

class _ReactionChip extends StatelessWidget {
  final String emoji;
  final VoidCallback onTap;

  const _ReactionChip({required this.emoji, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 6),
        width: 38,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white12),
        ),
        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 17))),
      ),
    );
  }
}

// ── Message Tile ──────────────────────────────────────────────────────────────

class _MessageTile extends StatelessWidget {
  final SessionMessage msg;
  final bool isMine;
  final bool isTeacher;
  final VoidCallback? onReply;
  final VoidCallback? onDelete;
  final VoidCallback? onPin;

  const _MessageTile({
    super.key,
    required this.msg,
    required this.isMine,
    required this.isTeacher,
    this.onReply,
    this.onDelete,
    this.onPin,
  });

  @override
  Widget build(BuildContext context) {
    // System messages — centered pill
    if (msg.type == MessageType.system) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              msg.message,
              style: const TextStyle(
                  color: Colors.white38, fontSize: 11, fontFamily: 'Cairo'),
            ),
          ),
        ),
      );
    }

    // Reaction messages — centered emoji
    if (msg.type == MessageType.reaction) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Center(
          child: Text(
            '${msg.senderName}: ${msg.message}',
            style: const TextStyle(fontSize: 14, color: Colors.white54, fontFamily: 'Cairo'),
          ),
        ),
      );
    }

    // File messages
    if (msg.type == MessageType.file) {
      return _FileMessageTile(msg: msg, isMine: isMine);
    }

    // Text messages
    return GestureDetector(
      onLongPress: (onDelete != null || onPin != null)
          ? () => _showActions(context)
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          // In RTL: start = right, end = left
          // My messages cluster at start (right), others at end (left)
          mainAxisAlignment: isMine ? MainAxisAlignment.start : MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (isMine) const SizedBox(width: 36),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: isMine
                      ? _kPurple.withValues(alpha: 0.75)
                      : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: isMine ? const Radius.circular(16) : const Radius.circular(4),
                    bottomRight: isMine ? const Radius.circular(4) : const Radius.circular(16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment:
                      isMine ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isMine)
                      Text(
                        msg.senderName,
                        style: const TextStyle(
                          color: Color(0xFFBFC0E0),
                          fontSize: 10,
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    Text(
                      msg.message,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 12, fontFamily: 'Cairo'),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatTime(msg.sentAt),
                      style: const TextStyle(color: Colors.white38, fontSize: 9),
                    ),
                  ],
                ),
              ),
            ),
            if (!isMine) const SizedBox(width: 36),
          ],
        ),
      ),
    );
  }

  void _showActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onReply != null)
                ListTile(
                  leading: const Icon(Icons.reply, color: Colors.white70),
                  title: const Text('رد', style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
                  onTap: () {
                    Navigator.pop(context);
                    onReply?.call();
                  },
                ),
              if (onPin != null)
                ListTile(
                  leading: const Icon(Icons.push_pin, color: _kPurple),
                  title: const Text('تثبيت', style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
                  onTap: () {
                    Navigator.pop(context);
                    onPin?.call();
                  },
                ),
              if (onDelete != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('حذف', style: TextStyle(color: Colors.red, fontFamily: 'Cairo')),
                  onTap: () {
                    Navigator.pop(context);
                    onDelete?.call();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ── File Message ──────────────────────────────────────────────────────────────

class _FileMessageTile extends StatelessWidget {
  final SessionMessage msg;
  final bool isMine;

  const _FileMessageTile({required this.msg, required this.isMine});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (isMine) const SizedBox(width: 36),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isMine
                    ? _kPurple.withValues(alpha: 0.75)
                    : Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.insert_drive_file, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          msg.fileName ?? msg.message,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12, fontFamily: 'Cairo'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (msg.message != msg.fileName && msg.message.isNotEmpty)
                          Text(
                            msg.message,
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 10, fontFamily: 'Cairo'),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!isMine) const SizedBox(width: 36),
        ],
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyChat extends StatelessWidget {
  const _EmptyChat();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline, color: Colors.white12, size: 40),
          SizedBox(height: 10),
          Text('لا رسائل بعد',
              style: TextStyle(color: Colors.white24, fontFamily: 'Cairo', fontSize: 13)),
          SizedBox(height: 4),
          Text('ابدأ المحادثة...',
              style: TextStyle(color: Colors.white12, fontFamily: 'Cairo', fontSize: 11)),
        ],
      ),
    );
  }
}
