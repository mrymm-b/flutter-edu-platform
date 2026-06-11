import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/live_session.dart';

// All Live Sessions
final liveSessionsProvider = FutureProvider<List<LiveSession>>((ref) async {
  final supabase = Supabase.instance.client;

  final response = await supabase
      .from('live_sessions')
      .select()
      .order('scheduled_at', ascending: false);

  return (response as List).map((json) => LiveSession.fromJson(json)).toList();
});

// Live Sessions by Course
final liveSessionsByCourseProvider =
    FutureProvider.family<List<LiveSession>, String>(
  (ref, courseId) async {
    final supabase = Supabase.instance.client;

    final response = await supabase
        .from('live_sessions')
        .select()
        .eq('course_id', courseId)
        .order('scheduled_at', ascending: false);

    return (response as List)
        .map((json) => LiveSession.fromJson(json))
        .toList();
  },
);

// Current Live Sessions
final currentLiveSessionsProvider =
    FutureProvider<List<LiveSession>>((ref) async {
  final supabase = Supabase.instance.client;

  final response = await supabase
      .from('live_sessions')
      .select()
      .eq('status', 'live')
      .order('started_at', ascending: false);

  return (response as List).map((json) => LiveSession.fromJson(json)).toList();
});

// Upcoming Live Sessions
final upcomingLiveSessionsProvider =
    FutureProvider<List<LiveSession>>((ref) async {
  final supabase = Supabase.instance.client;

  final response = await supabase
      .from('live_sessions')
      .select()
      .eq('status', 'scheduled')
      .gte('scheduled_at', DateTime.now().toIso8601String())
      .order('scheduled_at', ascending: true);

  return (response as List).map((json) => LiveSession.fromJson(json)).toList();
});

// Single Live Session
final liveSessionProvider = FutureProvider.family<LiveSession, String>(
  (ref, sessionId) async {
    final supabase = Supabase.instance.client;

    final response = await supabase
        .from('live_sessions')
        .select()
        .eq('id', sessionId)
        .single();

    return LiveSession.fromJson(response);
  },
);
