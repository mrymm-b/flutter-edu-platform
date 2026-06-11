import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/agora_config.dart';
import 'auth_provider.dart';
import 'teacher_provider.dart';

// ── Args (record = structural equality, safe as Riverpod family key) ──────────

typedef LiveSessionKey = ({
  String courseId,
  String courseTitle,
  bool isTeacher,
});

// ── Enums ─────────────────────────────────────────────────────────────────────

enum LivePhase { idle, initializing, live, paused, reconnecting, error, ended }

enum NetQuality { unknown, excellent, good, poor, bad, offline }

// ── State ─────────────────────────────────────────────────────────────────────

class LiveSessionState {
  final LivePhase phase;
  final String? sessionId;
  final String? error;

  // Media controls (teacher = local, student = remote mute)
  final bool micMuted;
  final bool cameraOff;
  final bool isAudioOnly;
  final bool isFrontCamera;

  // Stats
  final int viewerCount;
  final NetQuality networkQuality;
  final int elapsedSeconds;

  // Student-specific
  final bool hasTeacherVideo;
  final int? remoteUid;

  // Reconnect
  final bool showReconnectBanner;
  final int reconnectAttempts;

  // UX
  final bool isBuffering;      // student: remote video loading/frozen
  final bool showControls;     // auto-hide controls (student view)
  final bool isScreenSharing;  // teacher: currently publishing screen share

  const LiveSessionState({
    this.phase = LivePhase.idle,
    this.sessionId,
    this.error,
    this.micMuted = false,
    this.cameraOff = false,
    this.isAudioOnly = false,
    this.isFrontCamera = true,
    this.viewerCount = 0,
    this.networkQuality = NetQuality.unknown,
    this.elapsedSeconds = 0,
    this.hasTeacherVideo = false,
    this.remoteUid,
    this.showReconnectBanner = false,
    this.reconnectAttempts = 0,
    this.isBuffering = false,
    this.showControls = true,
    this.isScreenSharing = false,
  });

  LiveSessionState copyWith({
    LivePhase? phase,
    String? sessionId,
    String? error,
    bool? micMuted,
    bool? cameraOff,
    bool? isAudioOnly,
    bool? isFrontCamera,
    int? viewerCount,
    NetQuality? networkQuality,
    int? elapsedSeconds,
    bool? hasTeacherVideo,
    int? remoteUid,
    bool clearRemoteUid = false,
    bool? showReconnectBanner,
    int? reconnectAttempts,
    bool? isBuffering,
    bool? showControls,
    bool? isScreenSharing,
  }) {
    return LiveSessionState(
      phase: phase ?? this.phase,
      sessionId: sessionId ?? this.sessionId,
      error: error ?? this.error,
      micMuted: micMuted ?? this.micMuted,
      cameraOff: cameraOff ?? this.cameraOff,
      isAudioOnly: isAudioOnly ?? this.isAudioOnly,
      isFrontCamera: isFrontCamera ?? this.isFrontCamera,
      viewerCount: viewerCount ?? this.viewerCount,
      networkQuality: networkQuality ?? this.networkQuality,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      hasTeacherVideo: hasTeacherVideo ?? this.hasTeacherVideo,
      remoteUid: clearRemoteUid ? null : (remoteUid ?? this.remoteUid),
      showReconnectBanner: showReconnectBanner ?? this.showReconnectBanner,
      reconnectAttempts: reconnectAttempts ?? this.reconnectAttempts,
      isBuffering: isBuffering ?? this.isBuffering,
      showControls: showControls ?? this.showControls,
      isScreenSharing: isScreenSharing ?? this.isScreenSharing,
    );
  }

  bool get isLive => phase == LivePhase.live;
  bool get isPaused => phase == LivePhase.paused;
  bool get isReconnecting => phase == LivePhase.reconnecting;
  bool get isEnded => phase == LivePhase.ended;
  bool get hasError => phase == LivePhase.error;
  bool get isInitializing => phase == LivePhase.initializing;
}

// ── Controller ────────────────────────────────────────────────────────────────

class LiveSessionController extends StateNotifier<LiveSessionState>
    with WidgetsBindingObserver {
  final LiveSessionKey _key;
  final Ref _ref;

  RtcEngine? _engine;
  Timer? _elapsedTimer;
  Timer? _reconnectTimer;
  Timer? _controlsTimer;
  bool _disposed = false;

  static const _maxReconnects = 5;
  static const _reconnectDelays = [2, 4, 8, 16, 32]; // seconds (exponential)

  LiveSessionController(this._key, this._ref) : super(const LiveSessionState()) {
    WidgetsBinding.instance.addObserver(this);
  }

  // ── Public API ──────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_disposed || state.phase != LivePhase.idle) return;
    _setState(state.copyWith(phase: LivePhase.initializing));
    debugPrint('[LiveSession] initialize: start (isTeacher=${_key.isTeacher}, web=$kIsWeb)');

    try {
      debugPrint('[LiveSession] initialize: requesting permissions...');
      await _requestPermissions();
      debugPrint('[LiveSession] initialize: creating engine...');
      await _createEngine();
      debugPrint('[LiveSession] initialize: registering callbacks...');
      _registerCallbacks();

      if (_key.isTeacher) {
        debugPrint('[LiveSession] initialize: _setupBroadcaster...');
        await _setupBroadcaster();
      } else {
        debugPrint('[LiveSession] initialize: _setupAudience...');
        await _setupAudience();
      }
      debugPrint('[LiveSession] initialize: complete ✓');
    } catch (e, st) {
      debugPrint('[LiveSession] initialize ERROR: $e\n$st');
      _setError('تعذر تهيئة البث: $e');
    }
  }

  Future<void> toggleMic() async {
    if (_engine == null) return;
    final muted = !state.micMuted;
    await _engine!.muteLocalAudioStream(muted);
    _setState(state.copyWith(micMuted: muted));
  }

  Future<void> toggleCamera() async {
    if (_engine == null || state.isScreenSharing) return;
    final off = !state.cameraOff;
    await _engine!.muteLocalVideoStream(off || state.isPaused);
    if (!off) {
      // Ensure channel is publishing camera after it was initially off.
      await _engine!.updateChannelMediaOptions(const ChannelMediaOptions(
        publishCameraTrack: true,
      ));
    }
    _setState(state.copyWith(cameraOff: off));
  }

  Future<void> flipCamera() async {
    if (_engine == null || state.cameraOff || state.isScreenSharing) return;
    await _engine!.switchCamera();
    _setState(state.copyWith(isFrontCamera: !state.isFrontCamera));
  }

  Future<void> toggleScreenShare() async {
    if (_engine == null || !_key.isTeacher) return;
    if (state.isScreenSharing) {
      debugPrint('[LiveSession] toggleScreenShare: stopping screen capture...');
      try {
        await _engine!.stopScreenCapture();
        await _engine!.updateChannelMediaOptions(ChannelMediaOptions(
          publishScreenCaptureVideo: false,
          publishScreenCaptureAudio: false,
          publishCameraTrack: !state.cameraOff && !state.isPaused,
          publishMicrophoneTrack: !state.micMuted && !state.isPaused,
        ));
        if (!state.cameraOff && !state.isPaused && !kIsWeb) {
          try { await _engine!.startPreview(); } catch (_) {}
        }
        _setState(state.copyWith(isScreenSharing: false));
        debugPrint('[LiveSession] toggleScreenShare: stopped ✓');
      } catch (e) {
        debugPrint('[LiveSession] toggleScreenShare: stopScreenCapture error: $e');
      }
    } else {
      debugPrint('[LiveSession] toggleScreenShare: starting screen capture...');
      try {
        await _engine!.startScreenCapture(const ScreenCaptureParameters2(
          captureAudio: false,
          captureVideo: true,
        ));
        await _engine!.updateChannelMediaOptions(ChannelMediaOptions(
          publishScreenCaptureVideo: true,
          publishScreenCaptureAudio: false,
          publishCameraTrack: false,
          publishMicrophoneTrack: !state.micMuted && !state.isPaused,
        ));
        _setState(state.copyWith(isScreenSharing: true));
        debugPrint('[LiveSession] toggleScreenShare: started ✓');
      } catch (e) {
        debugPrint('[LiveSession] toggleScreenShare: startScreenCapture error: $e');
        rethrow;
      }
    }
  }

  Future<void> toggleAudioOnly() async {
    if (_engine == null) return;
    final audioOnly = !state.isAudioOnly;
    if (audioOnly) {
      await _engine!.disableVideo();
    } else {
      await _engine!.enableVideo();
      if (!state.cameraOff && !state.isPaused) await _engine!.startPreview();
    }
    _setState(state.copyWith(isAudioOnly: audioOnly));
  }

  Future<void> togglePause() async {
    if (_engine == null) return;
    final pausing = state.isLive;
    if (pausing) {
      await _engine!.muteLocalVideoStream(true);
      await _engine!.muteLocalAudioStream(true);
      _setState(state.copyWith(phase: LivePhase.paused));
    } else {
      await _engine!.muteLocalVideoStream(state.cameraOff || state.isAudioOnly);
      await _engine!.muteLocalAudioStream(state.micMuted);
      _setState(state.copyWith(phase: LivePhase.live));
    }
    await _updateSessionStatus(pausing ? 'paused' : 'live');
    await _sendSystemMessage(pausing ? 'تم إيقاف البث مؤقتاً' : 'استُؤنف البث');
  }

  Future<void> toggleRemoteAudio() async {
    if (_engine == null) return;
    final muted = !state.micMuted;
    await _engine!.muteAllRemoteAudioStreams(muted);
    _setState(state.copyWith(micMuted: muted));
  }

  Future<void> endSession() async {
    _elapsedTimer?.cancel();
    _reconnectTimer?.cancel();
    await _sendSystemMessage('انتهت الجلسة المباشرة');
    await _releaseEngine();
    await _ref.read(liveSessionNotifierProvider.notifier).endSession();
    _setState(state.copyWith(phase: LivePhase.ended));
  }

  Future<void> leaveSession() async {
    _elapsedTimer?.cancel();
    _reconnectTimer?.cancel();
    await _recordAttendanceLeave();
    await _releaseEngine();
    _setState(state.copyWith(phase: LivePhase.ended));
  }

  // Called from the UI retry banner after a manual DB re-insert succeeds.
  void setSessionId(String id) {
    if (!_disposed && mounted) _setState(state.copyWith(sessionId: id));
  }

  Future<void> retryConnect() async {
    _reconnectTimer?.cancel();
    _setState(state.copyWith(reconnectAttempts: 0));
    await _attemptReconnect();
  }

  // Reveal controls and reset auto-hide timer (student view)
  void revealControls() {
    _controlsTimer?.cancel();
    if (!_disposed) _setState(state.copyWith(showControls: true));
    _controlsTimer = Timer(const Duration(seconds: 4), () {
      if (!_disposed && !state.isReconnecting && !state.isBuffering) {
        _setState(state.copyWith(showControls: false));
      }
    });
  }

  RtcEngine? get engine => _engine;

  // ── App Lifecycle ───────────────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_disposed) return;
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _onBackground();
      case AppLifecycleState.resumed:
        _onForeground();
      case AppLifecycleState.detached:
        _onDetach();
      default:
        break;
    }
  }

  void _onBackground() {
    if (_key.isTeacher && _engine != null && state.isLive) {
      // Pause local video to save battery; keep audio so students hear teacher
      _engine!.muteLocalVideoStream(true);
    }
  }

  void _onForeground() {
    if (_key.isTeacher && _engine != null && !state.cameraOff && !state.isAudioOnly && state.isLive) {
      _engine!.muteLocalVideoStream(false);
    }
    // Auto-reconnect if we lost connection while in background
    if (state.isReconnecting || state.showReconnectBanner) {
      _attemptReconnect();
    }
  }

  void _onDetach() {
    // App killed — best-effort cleanup without awaiting
    if (_key.isTeacher) {
      _ref.read(liveSessionNotifierProvider.notifier).endSession();
    } else {
      _recordAttendanceLeave();
    }
  }

  // ── Agora Setup ─────────────────────────────────────────────────────────────

  Future<void> _requestPermissions() async {
    if (kIsWeb) {
      // On web, the browser handles camera/mic access natively via getUserMedia
      // when joinChannel is called. permission_handler does not support web.
      debugPrint('[LiveSession] _requestPermissions: web — skipping (browser handles via getUserMedia)');
      return;
    }
    final needed = _key.isTeacher
        ? [Permission.camera, Permission.microphone]
        : [Permission.microphone];
    final statuses = await needed.request();
    final denied = statuses.values.any((s) => s.isDenied || s.isPermanentlyDenied);
    if (denied) throw Exception('يجب السماح بالوصول للكاميرا والميكروفون');
  }

  Future<void> _createEngine() async {
    debugPrint('[LiveSession] _createEngine: creating RTC engine...');
    _engine = createAgoraRtcEngine();
    debugPrint('[LiveSession] _createEngine: calling initialize (appId=${AgoraConfig.appId.substring(0, 8)}...)');
    await _engine!.initialize(const RtcEngineContext(
      appId: AgoraConfig.appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));
    debugPrint('[LiveSession] _createEngine: done ✓');
  }

  void _registerCallbacks() {
    _engine!.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: _onJoinSuccess,
      onUserJoined: _onUserJoined,
      onUserOffline: _onUserOffline,
      onNetworkQuality: _onNetworkQuality,
      onConnectionStateChanged: _onConnectionStateChanged,
      onTokenPrivilegeWillExpire: _onTokenExpiring,
      onError: _onAgoraError,
      onRemoteVideoStateChanged: _onRemoteVideoState,
    ));
  }

  Future<void> _setupBroadcaster() async {
    // Default: join with mic and camera muted so teacher controls when to go live.
    if (!_disposed) _setState(state.copyWith(micMuted: true, cameraOff: true));

    debugPrint('[LiveSession] _setupBroadcaster: setClientRole broadcaster...');
    await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    debugPrint('[LiveSession] _setupBroadcaster: enableVideo...');
    await _engine!.enableVideo();
    debugPrint('[LiveSession] _setupBroadcaster: enableAudio...');
    await _engine!.enableAudio();

    if (!kIsWeb) {
      // On native, startPreview can be called before joinChannel to show
      // local camera feed immediately (permissions already granted above).
      debugPrint('[LiveSession] _setupBroadcaster: startPreview (native, pre-join)...');
      await _engine!.startPreview();
    }

    debugPrint('[LiveSession] _setupBroadcaster: joinChannel (mic+camera off by default)...');
    await _joinChannel();

    if (kIsWeb) {
      // On web, getUserMedia runs inside joinChannel — startPreview after join.
      debugPrint('[LiveSession] _setupBroadcaster: startPreview (web, post-join)...');
      try {
        await _engine!.startPreview();
      } catch (e) {
        debugPrint('[LiveSession] _setupBroadcaster: startPreview failed on web (non-fatal): $e');
      }
    }

    final teacherId = _ref.read(authProvider).user?.id ?? '';
    debugPrint('[LiveSession] _setupBroadcaster: creating Supabase session (teacherId=$teacherId)...');
    await _ref.read(liveSessionNotifierProvider.notifier).startSession(
          courseId: _key.courseId,
          title: _key.courseTitle,
          teacherId: teacherId,
        );
    String? sessionId = _ref.read(liveSessionNotifierProvider).sessionId;
    debugPrint('[LiveSession] _setupBroadcaster: first attempt sessionId=$sessionId');

    // If the first attempt failed, retry once after a short delay.
    // This handles transient network issues. If it fails again, the UI will
    // show a retry banner (startSessionFailed=true).
    if (sessionId == null && !_disposed) {
      debugPrint('[LiveSession] _setupBroadcaster: first attempt failed, retrying in 3s...');
      await Future.delayed(const Duration(seconds: 3));
      if (!_disposed) {
        await _ref.read(liveSessionNotifierProvider.notifier).retryStartSession(
              courseId: _key.courseId,
              title: _key.courseTitle,
              teacherId: teacherId,
            );
        sessionId = _ref.read(liveSessionNotifierProvider).sessionId;
        debugPrint('[LiveSession] _setupBroadcaster: retry sessionId=$sessionId');
      }
    }

    if (sessionId != null && !_disposed) {
      _setState(state.copyWith(sessionId: sessionId));
      await _sendSystemMessage('بدأت الجلسة المباشرة');
    } else {
      debugPrint('[LiveSession] _setupBroadcaster: WARNING — all startSession attempts failed. '
          'startSessionFailed=${_ref.read(liveSessionNotifierProvider).startSessionFailed}');
    }
    debugPrint('[LiveSession] _setupBroadcaster: complete ✓ state.sessionId=${state.sessionId}');
  }

  Future<void> _setupAudience() async {
    await _engine!.setClientRole(role: ClientRoleType.clientRoleAudience);
    await _engine!.enableVideo();
    await _engine!.enableAudio();
    await _joinChannel();
    await _fetchSessionId();
    if (state.sessionId != null) {
      await _recordAttendanceJoin(state.sessionId!);
    }
  }

  Future<void> _joinChannel() async {
    final token = await _fetchToken();
    final channelId = AgoraConfig.channelId(_key.courseId);
    debugPrint('[LiveSession] _joinChannel: channelId=$channelId token=${token.isEmpty ? "empty(no-token)" : "set"}');
    await _engine!.joinChannel(
      token: token,
      channelId: channelId,
      uid: 0,
      options: ChannelMediaOptions(
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        clientRoleType: _key.isTeacher
            ? ClientRoleType.clientRoleBroadcaster
            : ClientRoleType.clientRoleAudience,
        // Derive publish state from current state so reconnects restore the
        // correct camera/mic/screen-share configuration automatically.
        publishCameraTrack:
            _key.isTeacher && !state.cameraOff && !state.isScreenSharing && !state.isPaused,
        publishMicrophoneTrack:
            _key.isTeacher && !state.micMuted && !state.isPaused,
        publishScreenCaptureVideo:
            _key.isTeacher && state.isScreenSharing,
        autoSubscribeAudio: !_key.isTeacher,
        autoSubscribeVideo: !_key.isTeacher,
      ),
    );
    debugPrint('[LiveSession] _joinChannel: joinChannel() returned — waiting for onJoinChannelSuccess callback');
  }

  Future<String> _fetchToken() async {
    // TODO: fetch from Supabase Edge Function when token auth is enabled
    // final res = await Supabase.instance.client.functions.invoke(
    //   'agora-token',
    //   body: {'channelName': channelId, 'uid': 0, 'role': isTeacher ? 1 : 2},
    // );
    // return res.data['token'] as String;
    return AgoraConfig.token;
  }

  Future<void> _releaseEngine() async {
    if (_engine == null) return;
    try {
      if (_key.isTeacher) await _engine!.stopPreview();
      await _engine!.leaveChannel();
      await _engine!.release();
    } catch (_) {}
    _engine = null;
  }

  // ── Agora Callbacks ─────────────────────────────────────────────────────────

  void _onJoinSuccess(RtcConnection connection, int elapsed) {
    if (_disposed) return;
    _reconnectTimer?.cancel();
    _setState(state.copyWith(
      phase: LivePhase.live,
      showReconnectBanner: false,
      reconnectAttempts: 0,
    ));
    _startElapsedTimer();
  }

  void _onUserJoined(RtcConnection connection, int remoteUid, int elapsed) {
    if (_disposed) return;
    if (_key.isTeacher) {
      _setState(state.copyWith(viewerCount: state.viewerCount + 1));
    } else {
      // Mark video incoming + start buffering until first frame decoded
      _setState(state.copyWith(hasTeacherVideo: true, remoteUid: remoteUid, isBuffering: true));
    }
  }

  void _onRemoteVideoState(
    RtcConnection connection,
    int remoteUid,
    RemoteVideoState videoState,
    RemoteVideoStateReason reason,
    int elapsed,
  ) {
    if (_disposed || _key.isTeacher) return;
    final buffering = videoState == RemoteVideoState.remoteVideoStateFrozen ||
        videoState == RemoteVideoState.remoteVideoStateStarting;
    final decoded = videoState == RemoteVideoState.remoteVideoStateDecoding;
    if (buffering || decoded) {
      _setState(state.copyWith(isBuffering: buffering));
    }
  }

  void _onUserOffline(RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
    if (_disposed) return;
    if (_key.isTeacher) {
      _setState(state.copyWith(viewerCount: (state.viewerCount - 1).clamp(0, 9999)));
    } else if (state.remoteUid == remoteUid) {
      _setState(state.copyWith(hasTeacherVideo: false, clearRemoteUid: true));
    }
  }

  void _onNetworkQuality(RtcConnection connection, int remoteUid,
      QualityType txQuality, QualityType rxQuality) {
    if (_disposed || remoteUid != 0) return;
    final q = _mapQuality(_key.isTeacher ? txQuality : rxQuality);
    _setState(state.copyWith(networkQuality: q));
  }

  void _onConnectionStateChanged(RtcConnection connection,
      ConnectionStateType connState, ConnectionChangedReasonType reason) {
    if (_disposed) return;
    if (connState == ConnectionStateType.connectionStateDisconnected ||
        connState == ConnectionStateType.connectionStateFailed) {
      _setState(state.copyWith(
        phase: LivePhase.reconnecting,
        showReconnectBanner: true,
      ));
      _scheduleReconnect();
    } else if (connState == ConnectionStateType.connectionStateConnected) {
      _reconnectTimer?.cancel();
      _setState(state.copyWith(
        phase: state.isPaused ? LivePhase.paused : LivePhase.live,
        showReconnectBanner: false,
        reconnectAttempts: 0,
      ));
    }
  }

  void _onTokenExpiring(RtcConnection connection, String token) async {
    final newToken = await _fetchToken();
    await _engine?.renewToken(newToken);
  }

  void _onAgoraError(ErrorCodeType err, String msg) {
    if (_disposed) return;
    // Only surface fatal errors
    if (err == ErrorCodeType.errFailed ||
        err == ErrorCodeType.errInvalidToken ||
        err == ErrorCodeType.errJoinChannelRejected) {
      _setError('خطأ في البث (${err.index})');
    }
  }

  // ── Reconnect ───────────────────────────────────────────────────────────────

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    final attempt = state.reconnectAttempts;
    if (attempt >= _maxReconnects) {
      _setError('تعذر إعادة الاتصال بعد $_maxReconnects محاولات');
      return;
    }
    final delaySec = _reconnectDelays[attempt.clamp(0, _reconnectDelays.length - 1)];
    _reconnectTimer = Timer(Duration(seconds: delaySec), _attemptReconnect);
    _setState(state.copyWith(reconnectAttempts: attempt + 1));
  }

  Future<void> _attemptReconnect() async {
    if (_disposed || _engine == null) return;
    try {
      await _joinChannel();
    } catch (_) {
      _scheduleReconnect();
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  void _startElapsedTimer() {
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_disposed) _setState(state.copyWith(elapsedSeconds: state.elapsedSeconds + 1));
    });
  }

  NetQuality _mapQuality(QualityType q) {
    switch (q) {
      case QualityType.qualityExcellent:
        return NetQuality.excellent;
      case QualityType.qualityGood:
        return NetQuality.good;
      case QualityType.qualityPoor:
        return NetQuality.poor;
      case QualityType.qualityBad:
      case QualityType.qualityVbad:
        return NetQuality.bad;
      case QualityType.qualityDown:
        return NetQuality.offline;
      default:
        return NetQuality.unknown;
    }
  }

  Future<void> _fetchSessionId() async {
    try {
      final res = await Supabase.instance.client
          .from('live_sessions')
          .select('id')
          .eq('course_id', _key.courseId)
          .inFilter('status', ['live', 'paused'])
          .maybeSingle();
      if (res != null && !_disposed) {
        _setState(state.copyWith(sessionId: res['id'] as String));
      }
    } catch (_) {}
  }

  Future<void> _updateSessionStatus(String status) async {
    final sid = state.sessionId;
    if (sid == null) return;
    try {
      await Supabase.instance.client
          .from('live_sessions')
          .update({'status': status}).eq('id', sid);
    } catch (_) {}
  }

  Future<void> _sendSystemMessage(String text) async {
    final sid = state.sessionId;
    if (sid == null) return;
    try {
      await Supabase.instance.client.from('session_messages').insert({
        'session_id': sid,
        'sender_id': _ref.read(authProvider).user?.id ?? 'system',
        'sender_name': 'النظام',
        'message': text,
        'message_type': 'system',
      });
    } catch (_) {}
  }

  Future<void> _recordAttendanceJoin(String sessionId) async {
    final user = _ref.read(authProvider).user;
    if (user == null) return;
    try {
      await Supabase.instance.client.from('session_attendance').upsert({
        'session_id': sessionId,
        'student_id': user.id,
        'joined_at': DateTime.now().toIso8601String(),
        'total_duration': 0,
      }, onConflict: 'session_id,student_id');
    } catch (_) {}
  }

  Future<void> _recordAttendanceLeave() async {
    final sid = state.sessionId;
    final user = _ref.read(authProvider).user;
    if (sid == null || user == null) return;
    try {
      await Supabase.instance.client.from('session_attendance').update({
        'left_at': DateTime.now().toIso8601String(),
        'total_duration': state.elapsedSeconds,
      }).eq('session_id', sid).eq('student_id', user.id);
    } catch (_) {}
  }

  void _setState(LiveSessionState s) {
    if (!_disposed && mounted) state = s;
  }

  void _setError(String msg) {
    _elapsedTimer?.cancel();
    _reconnectTimer?.cancel();
    if (!_disposed && mounted) {
      state = state.copyWith(phase: LivePhase.error, error: msg);
    }
  }

  // ── Disposal ─────────────────────────────────────────────────────────────────

  void cleanup() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _elapsedTimer?.cancel();
    _reconnectTimer?.cancel();
    _controlsTimer?.cancel();
    // Fire-and-forget: engine release (dispose may be called synchronously)
    _releaseEngine();
  }

  @override
  void dispose() {
    cleanup();
    super.dispose();
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final liveSessionControllerProvider = StateNotifierProvider.autoDispose
    .family<LiveSessionController, LiveSessionState, LiveSessionKey>(
  (ref, key) {
    final controller = LiveSessionController(key, ref);
    ref.onDispose(controller.cleanup);
    return controller;
  },
);
