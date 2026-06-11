import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/conversation.dart';
import '../../domain/models/message.dart';
import 'auth_provider.dart';

// My Conversations
final myConversationsProvider = FutureProvider<List<Conversation>>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState.user == null) return [];

  final supabase = Supabase.instance.client;

  final response = await supabase
      .from('conversations')
      .select()
      .or('student_id.eq.${authState.user!.id},teacher_id.eq.${authState.user!.id}')
      .order('last_message_at', ascending: false);

  return (response as List).map((json) => Conversation.fromJson(json)).toList();
});

// Messages in Conversation
final messagesProvider = FutureProvider.family<List<Message>, String>(
  (ref, conversationId) async {
    final supabase = Supabase.instance.client;

    final response = await supabase
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('sent_at', ascending: true);

    return (response as List).map((json) => Message.fromJson(json)).toList();
  },
);

// Messages Stream (Real-time)
final messagesStreamProvider = StreamProvider.family<List<Message>, String>(
  (ref, conversationId) {
    final supabase = Supabase.instance.client;

    return supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('sent_at', ascending: true)
        .map((data) => data.map((json) => Message.fromJson(json)).toList());
  },
);

// Send Message Notifier
class MessagesNotifier extends StateNotifier<AsyncValue<void>> {
  MessagesNotifier(this.ref) : super(const AsyncValue.data(null));

  final Ref ref;
  final _supabase = Supabase.instance.client;

  Future<void> sendMessage({
    required String conversationId,
    required String message,
    String messageType = 'text',
    String? mediaUrl,
  }) async {
    final authState = ref.read(authProvider);
    if (authState.user == null) return;

    state = const AsyncValue.loading();

    try {
      await _supabase.from('messages').insert({
        'conversation_id': conversationId,
        'sender_id': authState.user!.id,
        'message': message,
        'message_type': messageType,
        if (mediaUrl != null) 'media_url': mediaUrl,
        'sent_at': DateTime.now().toIso8601String(),
      });

      final isTeacher = authState.user!.isTeacher;
      final unreadField =
          isTeacher ? 'unread_count_student' : 'unread_count_teacher';
      final conv = await _supabase
          .from('conversations')
          .select(unreadField)
          .eq('id', conversationId)
          .single();
      final currentUnread = (conv[unreadField] as int?) ?? 0;
      await _supabase.from('conversations').update({
        'last_message': message,
        'last_message_at': DateTime.now().toIso8601String(),
        unreadField: currentUnread + 1,
      }).eq('id', conversationId);

      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<bool> sendMediaMessage({
    required String conversationId,
    required String filePath,
    required String messageType, // 'image' or 'voice'
  }) async {
    final authState = ref.read(authProvider);
    if (authState.user == null) return false;

    try {
      final bytes = await File(filePath).readAsBytes();
      final ext = messageType == 'image' ? 'jpg' : 'm4a';
      final fileName =
          '${authState.user!.id}_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final contentType =
          messageType == 'image' ? 'image/jpeg' : 'audio/m4a';

      await _supabase.storage.from('chat-media').uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(contentType: contentType),
          );

      final url =
          _supabase.storage.from('chat-media').getPublicUrl(fileName);

      final displayText =
          messageType == 'image' ? '📷 صورة' : '🎤 رسالة صوتية';

      await sendMessage(
        conversationId: conversationId,
        message: displayText,
        messageType: messageType,
        mediaUrl: url,
      );

      return true;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  Future<void> markAsRead(String messageId) async {
    try {
      await _supabase
          .from('messages')
          .update({'is_read': true}).eq('id', messageId);
    } catch (e) {
      // Ignore
    }
  }

  Future<void> resetUnread(String conversationId) async {
    final authState = ref.read(authProvider);
    if (authState.user == null) return;
    final isTeacher = authState.user!.isTeacher;
    final field =
        isTeacher ? 'unread_count_teacher' : 'unread_count_student';
    try {
      await _supabase
          .from('conversations')
          .update({field: 0}).eq('id', conversationId);
    } catch (_) {}
  }
}

final messagesNotifierProvider =
    StateNotifierProvider<MessagesNotifier, AsyncValue<void>>((ref) {
  return MessagesNotifier(ref);
});
