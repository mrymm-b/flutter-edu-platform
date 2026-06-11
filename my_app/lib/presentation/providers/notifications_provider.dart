import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/notification.dart';
import 'auth_provider.dart';

// My Notifications
final myNotificationsProvider =
    FutureProvider<List<AppNotification>>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState.user == null) return [];

  final supabase = Supabase.instance.client;

  final response = await supabase
      .from('notifications')
      .select()
      .eq('user_id', authState.user!.id)
      .order('sent_at', ascending: false)
      .limit(50);

  return (response as List)
      .map((json) => AppNotification.fromJson(json))
      .toList();
});

// Unread Notifications Count
final unreadNotificationsCountProvider = FutureProvider<int>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState.user == null) return 0;

  final supabase = Supabase.instance.client;

  final response = await supabase
      .from('notifications')
      .select()
      .eq('user_id', authState.user!.id)
      .eq('is_read', false);

  return (response as List).length;
});

// Notifications Stream (Real-time)
final notificationsStreamProvider =
    StreamProvider<List<AppNotification>>((ref) {
  final authState = ref.watch(authProvider);
  if (authState.user == null) {
    return Stream.value([]);
  }

  final supabase = Supabase.instance.client;

  return supabase
      .from('notifications')
      .stream(primaryKey: ['id'])
      .eq('user_id', authState.user!.id)
      .order('sent_at', ascending: false)
      .map((data) =>
          data.map((json) => AppNotification.fromJson(json)).toList());
});

// Notifications Notifier
class NotificationsNotifier extends StateNotifier<AsyncValue<void>> {
  NotificationsNotifier(this.ref) : super(const AsyncValue.data(null));

  final Ref ref;
  final _supabase = Supabase.instance.client;

  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true}).eq('id', notificationId);

      ref.invalidate(myNotificationsProvider);
      ref.invalidate(unreadNotificationsCountProvider);
    } catch (e) {
      // Ignore error
    }
  }

  Future<void> markAllAsRead() async {
    final authState = ref.read(authProvider);
    if (authState.user == null) return;

    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true}).eq('user_id', authState.user!.id);

      ref.invalidate(myNotificationsProvider);
      ref.invalidate(unreadNotificationsCountProvider);
    } catch (e) {
      // Ignore error
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _supabase.from('notifications').delete().eq('id', notificationId);

      ref.invalidate(myNotificationsProvider);
      ref.invalidate(unreadNotificationsCountProvider);
    } catch (e) {
      // Ignore error
    }
  }
}

final notificationsNotifierProvider =
    StateNotifierProvider<NotificationsNotifier, AsyncValue<void>>((ref) {
  return NotificationsNotifier(ref);
});
