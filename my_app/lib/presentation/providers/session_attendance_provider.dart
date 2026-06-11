import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

class AttendanceRecord {
  final String id;
  final String sessionId;
  final String studentId;
  final String studentName;
  final DateTime joinedAt;
  final DateTime? leftAt;
  final int totalDuration; // seconds

  const AttendanceRecord({
    required this.id,
    required this.sessionId,
    required this.studentId,
    required this.studentName,
    required this.joinedAt,
    this.leftAt,
    required this.totalDuration,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> j) => AttendanceRecord(
        id: j['id'] as String,
        sessionId: j['session_id'] as String,
        studentId: j['student_id'] as String,
        studentName: j['users']?['full_name'] as String? ?? 'طالب',
        joinedAt: DateTime.parse(j['joined_at'] as String),
        leftAt: j['left_at'] != null
            ? DateTime.parse(j['left_at'] as String)
            : null,
        totalDuration: j['total_duration'] as int? ?? 0,
      );

  bool get isOnline => leftAt == null;

  String get durationLabel {
    final m = totalDuration ~/ 60;
    final s = totalDuration % 60;
    // ignore: unnecessary_brace_in_string_interps — braces required before Arabic Unicode letters
    if (m == 0) return '${s}ث';
    return '$mد $sث';
  }
}

// ── Stream Provider (real-time) ───────────────────────────────────────────────

final sessionAttendanceStreamProvider =
    StreamProvider.autoDispose.family<List<AttendanceRecord>, String>(
  (ref, sessionId) {
    // Stream attendance rows with joined user name
    // Note: Supabase .stream() doesn't support .select() with joins,
    // so we use a periodic poll approach for the name, but stream for presence.
    return Supabase.instance.client
        .from('session_attendance')
        .stream(primaryKey: ['id'])
        .eq('session_id', sessionId)
        .order('joined_at')
        .asyncMap((rows) async {
          // Fetch user names in one query
          if (rows.isEmpty) return <AttendanceRecord>[];
          final ids = rows.map((r) => r['student_id'] as String).toList();
          final users = await Supabase.instance.client
              .from('users')
              .select('id, full_name')
              .inFilter('id', ids);
          final nameMap = {
            for (final u in users as List)
              u['id'] as String: u['full_name'] as String? ?? 'طالب',
          };
          return rows.map((r) {
            final copy = Map<String, dynamic>.from(r);
            copy['users'] = {'full_name': nameMap[r['student_id']] ?? 'طالب'};
            return AttendanceRecord.fromJson(copy);
          }).toList();
        });
  },
);

// ── Derived: online count ─────────────────────────────────────────────────────

final onlineAttendanceCountProvider =
    Provider.autoDispose.family<int, String>((ref, sessionId) {
  final records =
      ref.watch(sessionAttendanceStreamProvider(sessionId)).valueOrNull ?? [];
  return records.where((r) => r.isOnline).length;
});

// ── Session summary (for ended sessions) ──────────────────────────────────────

final sessionAttendanceSummaryProvider =
    FutureProvider.family<List<AttendanceRecord>, String>(
        (ref, sessionId) async {
  final rows = await Supabase.instance.client
      .from('session_attendance')
      .select('*, users(full_name)')
      .eq('session_id', sessionId)
      .order('joined_at');
  return (rows as List).map((r) => AttendanceRecord.fromJson(r)).toList();
});
