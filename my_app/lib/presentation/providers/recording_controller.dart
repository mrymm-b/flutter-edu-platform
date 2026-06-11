import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Enum ──────────────────────────────────────────────────────────────────────

enum RecordingPhase { idle, acquiring, recording, stopping, completed, failed }

// ── State ─────────────────────────────────────────────────────────────────────

class RecordingState {
  final RecordingPhase phase;
  final int elapsedSeconds;
  final String? resourceId;
  final String? sid;
  final String? fileUrl;
  final String? error;

  const RecordingState({
    this.phase = RecordingPhase.idle,
    this.elapsedSeconds = 0,
    this.resourceId,
    this.sid,
    this.fileUrl,
    this.error,
  });

  bool get isRecording => phase == RecordingPhase.recording;
  bool get isActive => phase == RecordingPhase.recording || phase == RecordingPhase.acquiring;
  bool get canStart => phase == RecordingPhase.idle || phase == RecordingPhase.failed;
  bool get isCompleted => phase == RecordingPhase.completed;

  String get elapsedLabel {
    final h = elapsedSeconds ~/ 3600;
    final m = (elapsedSeconds % 3600) ~/ 60;
    final s = elapsedSeconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  RecordingState copyWith({
    RecordingPhase? phase,
    int? elapsedSeconds,
    String? resourceId,
    String? sid,
    String? fileUrl,
    String? error,
  }) =>
      RecordingState(
        phase: phase ?? this.phase,
        elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
        resourceId: resourceId ?? this.resourceId,
        sid: sid ?? this.sid,
        fileUrl: fileUrl ?? this.fileUrl,
        error: error ?? this.error,
      );
}

// ── Controller ────────────────────────────────────────────────────────────────

class RecordingController extends StateNotifier<RecordingState> {
  final String _sessionId;
  Timer? _timer;
  bool _disposed = false;

  RecordingController(this._sessionId) : super(const RecordingState());

  // ── Start ──────────────────────────────────────────────────────────────────

  Future<void> startRecording(String channelId) async {
    if (!state.canStart) return;
    _set(state.copyWith(phase: RecordingPhase.acquiring, error: null));
    try {
      final res = await Supabase.instance.client.functions.invoke(
        'agora-recording',
        body: {'action': 'start', 'channelId': channelId, 'sessionId': _sessionId},
      );
      final data = (res.data as Map?)?.cast<String, dynamic>() ?? {};
      final resourceId = data['resourceId'] as String?;
      final sid = data['sid'] as String?;

      if (resourceId == null || sid == null) {
        _set(state.copyWith(phase: RecordingPhase.failed, error: 'تعذر بدء التسجيل'));
        return;
      }

      _set(state.copyWith(phase: RecordingPhase.recording, resourceId: resourceId, sid: sid));
      _startTimer();

      await Supabase.instance.client.from('session_recordings').insert({
        'session_id': _sessionId,
        'resource_id': resourceId,
        'recording_sid': sid,
        'status': 'recording',
        'started_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (!_disposed) _set(state.copyWith(phase: RecordingPhase.failed, error: '$e'));
    }
  }

  // ── Stop ───────────────────────────────────────────────────────────────────

  Future<void> stopRecording(String channelId) async {
    if (!state.isRecording) return;
    _timer?.cancel();
    _set(state.copyWith(phase: RecordingPhase.stopping));
    try {
      final res = await Supabase.instance.client.functions.invoke(
        'agora-recording',
        body: {
          'action': 'stop',
          'channelId': channelId,
          'resourceId': state.resourceId,
          'sid': state.sid,
          'sessionId': _sessionId,
        },
      );
      final data = (res.data as Map?)?.cast<String, dynamic>() ?? {};
      final fileUrl = data['fileUrl'] as String?;

      await Supabase.instance.client
          .from('session_recordings')
          .update({
            'status': fileUrl != null ? 'completed' : 'failed',
            'stopped_at': DateTime.now().toIso8601String(),
            if (fileUrl != null) 'file_url': fileUrl,
          })
          .eq('session_id', _sessionId)
          .eq('recording_sid', state.sid ?? '');

      _set(state.copyWith(phase: RecordingPhase.completed, fileUrl: fileUrl));
    } catch (e) {
      if (!_disposed) _set(state.copyWith(phase: RecordingPhase.failed, error: '$e'));
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_disposed && state.isRecording) {
        _set(state.copyWith(elapsedSeconds: state.elapsedSeconds + 1));
      }
    });
  }

  void _set(RecordingState s) {
    if (!_disposed && mounted) state = s;
  }

  void cleanup() {
    _disposed = true;
    _timer?.cancel();
  }

  @override
  void dispose() {
    cleanup();
    super.dispose();
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final recordingControllerProvider = StateNotifierProvider.autoDispose
    .family<RecordingController, RecordingState, String>(
  (ref, sessionId) {
    final ctrl = RecordingController(sessionId);
    ref.onDispose(ctrl.cleanup);
    return ctrl;
  },
);

// Completed recordings for a session (for replay list)
final sessionRecordingsProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, sessionId) async {
  final rows = await Supabase.instance.client
      .from('session_recordings')
      .select()
      .eq('session_id', sessionId)
      .eq('status', 'completed')
      .order('started_at', ascending: false);
  return (rows as List).cast<Map<String, dynamic>>();
});
