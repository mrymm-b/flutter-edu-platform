import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/course.dart';
import '../../domain/models/book.dart';
import '../../domain/models/live_session.dart';
import 'auth_provider.dart';
import 'messages_provider.dart';

// Teacher's courses (requires teacher_id column in courses table)
final teacherCoursesProvider = FutureProvider<List<Course>>((ref) async {
  final user = ref.watch(authProvider).user;
  if (user == null || !user.isTeacher) return [];

  final supabase = Supabase.instance.client;
  final response = await supabase
      .from('courses')
      .select()
      .eq('teacher_id', user.id)
      .order('created_at', ascending: false);

  return (response as List).map((json) => Course.fromJson(json)).toList();
});

// Total students across teacher's courses
final teacherTotalStudentsProvider = FutureProvider<int>((ref) async {
  final courses = await ref.watch(teacherCoursesProvider.future);
  return courses.fold<int>(0, (sum, c) => sum + c.studentsCount);
});

// Books uploaded for a specific course
final teacherCourseBooksProvider =
    FutureProvider.family<List<Book>, String>((ref, courseId) async {
  final response = await Supabase.instance.client
      .from('books')
      .select()
      .eq('course_id', courseId)
      .order('created_at', ascending: false);

  return (response as List).map((json) => Book.fromJson(json)).toList();
});

// ── Live Session State ────────────────────────────────────────────────────────

class LiveSessionState {
  final bool isLive;
  final String? sessionId;
  final String? courseId;
  final String? channelName;
  final bool startSessionFailed;

  const LiveSessionState({
    this.isLive = false,
    this.sessionId,
    this.courseId,
    this.channelName,
    this.startSessionFailed = false,
  });

  LiveSessionState copyWith({
    bool? isLive,
    String? sessionId,
    String? courseId,
    String? channelName,
    bool? startSessionFailed,
  }) {
    return LiveSessionState(
      isLive: isLive ?? this.isLive,
      sessionId: sessionId ?? this.sessionId,
      courseId: courseId ?? this.courseId,
      channelName: channelName ?? this.channelName,
      startSessionFailed: startSessionFailed ?? this.startSessionFailed,
    );
  }
}

class LiveSessionNotifier extends StateNotifier<LiveSessionState> {
  LiveSessionNotifier() : super(const LiveSessionState());

  final _supabase = Supabase.instance.client;

  Future<void> startSession({
    required String courseId,
    required String title,
    required String teacherId,
  }) async {
    try {
      debugPrint('[LiveSession] startSession: inserting live_sessions (teacher=$teacherId, course=$courseId)...');
      final response = await _supabase
          .from('live_sessions')
          .insert({
            'course_id': courseId,
            'teacher_id': teacherId,
            'title': title,
            'status': 'live',
            'started_at': DateTime.now().toIso8601String(),
            'agora_channel_name': courseId,
          })
          .select()
          .single();

      final id = response['id'] as String;
      debugPrint('[LiveSession] startSession: success → sessionId=$id');
      state = state.copyWith(
        isLive: true,
        sessionId: id,
        courseId: courseId,
        channelName: 'course_$courseId',
      );
    } catch (e) {
      debugPrint('[LiveSession] startSession ERROR: $e');
      state = state.copyWith(
        isLive: true,
        courseId: courseId,
        channelName: 'course_$courseId',
        startSessionFailed: true,
      );
    }
  }

  Future<void> retryStartSession({
    required String courseId,
    required String title,
    required String teacherId,
  }) async {
    // Clear the failure flag before retrying
    state = state.copyWith(startSessionFailed: false);
    await startSession(courseId: courseId, title: title, teacherId: teacherId);
  }

  Future<void> endSession() async {
    if (state.sessionId != null) {
      try {
        await _supabase.from('live_sessions').update({
          'status': 'ended',
          'ended_at': DateTime.now().toIso8601String(),
        }).eq('id', state.sessionId!);
      } catch (_) {}
    }
    state = const LiveSessionState();
  }
}

final liveSessionNotifierProvider =
    StateNotifierProvider<LiveSessionNotifier, LiveSessionState>(
  (_) => LiveSessionNotifier(),
);

// ── Additional teacher providers ──────────────────────────────────────────────

/// Full name of any user by ID — used to resolve student names in chat.
final studentNameProvider = FutureProvider.family<String, String>(
  (ref, userId) async {
    final response = await Supabase.instance.client
        .from('users')
        .select('full_name')
        .eq('id', userId)
        .single();
    return (response['full_name'] as String?) ?? 'طالب';
  },
);

/// Ended live sessions for a single course (recordings list).
final teacherCourseRecordingsProvider =
    FutureProvider.family<List<LiveSession>, String>((ref, courseId) async {
  final response = await Supabase.instance.client
      .from('live_sessions')
      .select()
      .eq('course_id', courseId)
      .eq('status', 'ended')
      .order('ended_at', ascending: false);
  return (response as List).map((j) => LiveSession.fromJson(j)).toList();
});

/// Recent ended sessions across all of this teacher's courses (home activity feed).
final teacherRecentSessionsProvider =
    FutureProvider<List<LiveSession>>((ref) async {
  final user = ref.watch(authProvider).user;
  if (user == null || !user.isTeacher) return [];
  final response = await Supabase.instance.client
      .from('live_sessions')
      .select()
      .eq('teacher_id', user.id)
      .eq('status', 'ended')
      .order('ended_at', ascending: false)
      .limit(3);
  return (response as List).map((j) => LiveSession.fromJson(j)).toList();
});

/// Total unread messages across all of this teacher's conversations.
final teacherUnreadCountProvider = FutureProvider<int>((ref) async {
  final conversations = await ref.watch(myConversationsProvider.future);
  return conversations.fold<int>(0, (sum, c) => sum + c.unreadCountTeacher);
});
