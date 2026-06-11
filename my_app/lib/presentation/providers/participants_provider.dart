import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_provider.dart';
import 'session_attendance_provider.dart';

// ── Hand Raise ────────────────────────────────────────────────────────────────

enum HandRaiseStatus { pending, approved, rejected }

class HandRaise {
  final String id;
  final String sessionId;
  final String studentId;
  final String studentName;
  final HandRaiseStatus status;
  final DateTime raisedAt;

  const HandRaise({
    required this.id,
    required this.sessionId,
    required this.studentId,
    required this.studentName,
    required this.status,
    required this.raisedAt,
  });

  factory HandRaise.fromJson(Map<String, dynamic> j) => HandRaise(
        id: j['id'] as String,
        sessionId: j['session_id'] as String,
        studentId: j['student_id'] as String,
        studentName: j['student_name'] as String? ?? 'طالب',
        status: _statusFrom(j['status'] as String?),
        raisedAt: DateTime.parse(j['raised_at'] as String),
      );

  static HandRaiseStatus _statusFrom(String? s) => switch (s) {
        'approved' => HandRaiseStatus.approved,
        'rejected' => HandRaiseStatus.rejected,
        _ => HandRaiseStatus.pending,
      };

  bool get isPending => status == HandRaiseStatus.pending;
  bool get isApproved => status == HandRaiseStatus.approved;
}

// ── State ─────────────────────────────────────────────────────────────────────

class ParticipantsState {
  final List<AttendanceRecord> participants;
  final List<HandRaise> handRaises;
  final bool myHandRaised;

  const ParticipantsState({
    this.participants = const [],
    this.handRaises = const [],
    this.myHandRaised = false,
  });

  List<AttendanceRecord> get online => participants.where((r) => r.isOnline).toList();
  List<AttendanceRecord> get offline => participants.where((r) => !r.isOnline).toList();
  List<HandRaise> get pendingHands => handRaises.where((h) => h.isPending).toList();
  int get onlineCount => online.length;
  int get pendingHandCount => pendingHands.length;

  ParticipantsState copyWith({
    List<AttendanceRecord>? participants,
    List<HandRaise>? handRaises,
    bool? myHandRaised,
  }) =>
      ParticipantsState(
        participants: participants ?? this.participants,
        handRaises: handRaises ?? this.handRaises,
        myHandRaised: myHandRaised ?? this.myHandRaised,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class ParticipantsNotifier extends StateNotifier<ParticipantsState> {
  final String _sessionId;
  final Ref _ref;
  final _db = Supabase.instance.client;

  ParticipantsNotifier(this._sessionId, this._ref) : super(const ParticipantsState());

  void updateParticipants(List<AttendanceRecord> records) =>
      state = state.copyWith(participants: records);

  void updateHandRaises(List<HandRaise> raises) {
    final uid = _ref.read(authProvider).user?.id;
    final myHand = uid != null && raises.any((h) => h.studentId == uid && h.isPending);
    state = state.copyWith(handRaises: raises, myHandRaised: myHand);
  }

  // ── Student ────────────────────────────────────────────────────────────────

  Future<void> raiseHand() async {
    final user = _ref.read(authProvider).user;
    if (user == null) return;
    try {
      await _db.from('session_hand_raises').upsert({
        'session_id': _sessionId,
        'student_id': user.id,
        'student_name': user.fullName,
        'status': 'pending',
        'raised_at': DateTime.now().toIso8601String(),
      }, onConflict: 'session_id,student_id');
      state = state.copyWith(myHandRaised: true);
    } catch (_) {}
  }

  Future<void> lowerHand() async {
    final user = _ref.read(authProvider).user;
    if (user == null) return;
    try {
      await _db
          .from('session_hand_raises')
          .delete()
          .eq('session_id', _sessionId)
          .eq('student_id', user.id);
      state = state.copyWith(myHandRaised: false);
    } catch (_) {}
  }

  // ── Teacher ────────────────────────────────────────────────────────────────

  Future<void> approveHand(String raiseId, String studentName) async {
    try {
      await _db
          .from('session_hand_raises')
          .update({'status': 'approved'}).eq('id', raiseId);
      await _db.from('session_messages').insert({
        'session_id': _sessionId,
        'sender_id': 'system',
        'sender_name': 'النظام',
        'message': 'تم السماح لـ $studentName بالتحدث',
        'message_type': 'system',
      });
    } catch (_) {}
  }

  Future<void> rejectHand(String raiseId) async {
    try {
      await _db
          .from('session_hand_raises')
          .update({'status': 'rejected'}).eq('id', raiseId);
    } catch (_) {}
  }

  Future<void> dismissHand(String raiseId) async {
    try {
      await _db.from('session_hand_raises').delete().eq('id', raiseId);
    } catch (_) {}
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final handRaisesStreamProvider =
    StreamProvider.autoDispose.family<List<HandRaise>, String>((ref, sessionId) {
  return Supabase.instance.client
      .from('session_hand_raises')
      .stream(primaryKey: ['id'])
      .eq('session_id', sessionId)
      .order('raised_at')
      .map((rows) => rows.map((r) => HandRaise.fromJson(r)).toList());
});

final participantsProvider =
    StateNotifierProvider.autoDispose.family<ParticipantsNotifier, ParticipantsState, String>(
  (ref, sessionId) {
    final notifier = ParticipantsNotifier(sessionId, ref);
    ref.listen(sessionAttendanceStreamProvider(sessionId), (_, next) {
      next.whenData(notifier.updateParticipants);
    });
    ref.listen(handRaisesStreamProvider(sessionId), (_, next) {
      next.whenData(notifier.updateHandRaises);
    });
    return notifier;
  },
);
