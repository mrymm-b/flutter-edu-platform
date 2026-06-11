import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_provider.dart';

// ── Message Type ──────────────────────────────────────────────────────────────

enum MessageType { text, reaction, system, file }

extension MessageTypeX on MessageType {
  static MessageType fromString(String? s) {
    switch (s) {
      case 'reaction':
        return MessageType.reaction;
      case 'system':
        return MessageType.system;
      case 'file':
        return MessageType.file;
      default:
        return MessageType.text;
    }
  }

  String get value {
    switch (this) {
      case MessageType.reaction:
        return 'reaction';
      case MessageType.system:
        return 'system';
      case MessageType.file:
        return 'file';
      case MessageType.text:
        return 'text';
    }
  }
}

// ── Model ─────────────────────────────────────────────────────────────────────

class SessionMessage {
  final String id;
  final String sessionId;
  final String senderId;
  final String senderName;
  final String message;
  final MessageType type;
  final String? fileUrl;
  final String? fileName;
  final bool isPinned;
  final String? replyToId;
  final DateTime sentAt;

  const SessionMessage({
    required this.id,
    required this.sessionId,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.type,
    this.fileUrl,
    this.fileName,
    this.isPinned = false,
    this.replyToId,
    required this.sentAt,
  });

  factory SessionMessage.fromJson(Map<String, dynamic> j) => SessionMessage(
        id: j['id'] as String,
        sessionId: j['session_id'] as String,
        senderId: j['sender_id'] as String,
        senderName: j['sender_name'] as String? ?? 'مستخدم',
        message: j['message'] as String,
        type: MessageTypeX.fromString(j['message_type'] as String?),
        fileUrl: j['file_url'] as String?,
        fileName: j['file_name'] as String?,
        isPinned: j['is_pinned'] as bool? ?? false,
        replyToId: j['reply_to'] as String?,
        sentAt: DateTime.parse(j['sent_at'] as String),
      );
}

// ── Chat State ────────────────────────────────────────────────────────────────

class LiveChatState {
  final List<SessionMessage> messages;
  final int unreadCount;
  final bool isMuted;
  final bool isOpen;
  final String? pinnedMessageId;

  const LiveChatState({
    this.messages = const [],
    this.unreadCount = 0,
    this.isMuted = false,
    this.isOpen = false,
    this.pinnedMessageId,
  });

  LiveChatState copyWith({
    List<SessionMessage>? messages,
    int? unreadCount,
    bool? isMuted,
    bool? isOpen,
    String? pinnedMessageId,
    bool clearPinned = false,
  }) {
    return LiveChatState(
      messages: messages ?? this.messages,
      unreadCount: unreadCount ?? this.unreadCount,
      isMuted: isMuted ?? this.isMuted,
      isOpen: isOpen ?? this.isOpen,
      pinnedMessageId: clearPinned ? null : (pinnedMessageId ?? this.pinnedMessageId),
    );
  }

  SessionMessage? get pinnedMessage {
    if (pinnedMessageId == null) return null;
    try {
      return messages.firstWhere((m) => m.id == pinnedMessageId);
    } catch (_) {
      return null;
    }
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class LiveChatNotifier extends StateNotifier<LiveChatState> {
  final String _sessionId;
  final Ref _ref;
  final _supabase = Supabase.instance.client;

  LiveChatNotifier(this._sessionId, this._ref) : super(const LiveChatState());

  // ── Chat panel open/close ──────────────────────────────────────────────────

  void openChat() {
    state = state.copyWith(isOpen: true, unreadCount: 0);
  }

  void closeChat() {
    state = state.copyWith(isOpen: false);
  }

  void toggleMute() {
    state = state.copyWith(isMuted: !state.isMuted);
  }

  // Called by stream listener when new messages arrive
  void onNewMessages(List<SessionMessage> incoming) {
    final prev = state.messages.length;
    state = state.copyWith(messages: incoming);
    if (!state.isOpen && incoming.length > prev) {
      // Don't count system messages as unread
      final realNew = incoming.skip(prev).where((m) => m.type != MessageType.system).length;
      if (realNew > 0 && !state.isMuted) {
        state = state.copyWith(unreadCount: state.unreadCount + realNew);
      }
    }
    // Keep pinned message in sync
    if (state.pinnedMessageId != null) {
      final stillExists = incoming.any((m) => m.id == state.pinnedMessageId);
      if (!stillExists) state = state.copyWith(clearPinned: true);
    }
  }

  // ── Send ──────────────────────────────────────────────────────────────────

  Future<void> sendText(String text, {String? replyToId}) async {
    final user = _ref.read(authProvider).user;
    if (user == null || text.trim().isEmpty) return;
    try {
      await _supabase.from('session_messages').insert({
        'session_id': _sessionId,
        'sender_id': user.id,
        'sender_name': user.fullName,
        'message': text.trim(),
        'message_type': MessageType.text.value,
        if (replyToId != null) 'reply_to': replyToId,
      });
    } catch (_) {}
  }

  Future<void> sendReaction(String emoji) async {
    final user = _ref.read(authProvider).user;
    if (user == null) return;
    try {
      await _supabase.from('session_messages').insert({
        'session_id': _sessionId,
        'sender_id': user.id,
        'sender_name': user.fullName,
        'message': emoji,
        'message_type': MessageType.reaction.value,
      });
    } catch (_) {}
  }

  Future<void> sendFile({
    required String fileUrl,
    required String fileName,
    String? caption,
  }) async {
    final user = _ref.read(authProvider).user;
    if (user == null) return;
    try {
      await _supabase.from('session_messages').insert({
        'session_id': _sessionId,
        'sender_id': user.id,
        'sender_name': user.fullName,
        'message': caption ?? fileName,
        'message_type': MessageType.file.value,
        'file_url': fileUrl,
        'file_name': fileName,
      });
    } catch (_) {}
  }

  // ── Moderation (teacher only) ─────────────────────────────────────────────

  Future<void> deleteMessage(String messageId) async {
    try {
      await _supabase.from('session_messages').delete().eq('id', messageId);
      if (state.pinnedMessageId == messageId) {
        state = state.copyWith(clearPinned: true);
      }
    } catch (_) {}
  }

  Future<void> pinMessage(String messageId) async {
    try {
      // Unpin previous
      if (state.pinnedMessageId != null) {
        await _supabase
            .from('session_messages')
            .update({'is_pinned': false}).eq('id', state.pinnedMessageId!);
      }
      await _supabase
          .from('session_messages')
          .update({'is_pinned': true}).eq('id', messageId);
      state = state.copyWith(pinnedMessageId: messageId);
    } catch (_) {}
  }

  Future<void> unpinMessage() async {
    if (state.pinnedMessageId == null) return;
    try {
      await _supabase
          .from('session_messages')
          .update({'is_pinned': false}).eq('id', state.pinnedMessageId!);
      state = state.copyWith(clearPinned: true);
    } catch (_) {}
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final liveChatProvider =
    StateNotifierProvider.autoDispose.family<LiveChatNotifier, LiveChatState, String>(
  (ref, sessionId) => LiveChatNotifier(sessionId, ref),
);

// Raw stream of messages — watched by the UI and by the notifier
final sessionMessagesStreamProvider =
    StreamProvider.autoDispose.family<List<SessionMessage>, String>((ref, sessionId) {
  return Supabase.instance.client
      .from('session_messages')
      .stream(primaryKey: ['id'])
      .eq('session_id', sessionId)
      .order('sent_at')
      .map((rows) => rows.map((r) => SessionMessage.fromJson(r)).toList());
});

// Convenience: participants list (distinct senders in this session, excluding system)
final sessionParticipantsProvider =
    Provider.autoDispose.family<List<({String id, String name})>, String>(
  (ref, sessionId) {
    final messages = ref.watch(sessionMessagesStreamProvider(sessionId)).valueOrNull ?? [];
    final seen = <String>{};
    final result = <({String id, String name})>[];
    for (final m in messages) {
      if (m.type != MessageType.system && seen.add(m.senderId)) {
        result.add((id: m.senderId, name: m.senderName));
      }
    }
    return result;
  },
);
