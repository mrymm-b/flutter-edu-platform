import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/toast.dart';
import '../../providers/auth_provider.dart';
import '../../providers/live_session_controller.dart';
import '../../providers/live_chat_provider.dart';
import '../../providers/participants_provider.dart';
import '../../providers/recording_controller.dart';
import '../../providers/teacher_provider.dart' show liveSessionNotifierProvider;
import '../../widgets/live_chat_panel.dart';
import '../../widgets/participants_sheet.dart';
import '../../widgets/floating_reactions_overlay.dart';
import '../../widgets/session_ended_screen.dart';
import '../../widgets/lecture_resources_panel.dart';
import '../../widgets/live_controls.dart';

// Height of the controls bar — used to offset panels above it.
const _kControlsH = 215.0;

class LiveSessionPage extends ConsumerStatefulWidget {
  final String courseId;
  final String courseTitle;

  const LiveSessionPage({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

  @override
  ConsumerState<LiveSessionPage> createState() => _LiveSessionPageState();
}

class _LiveSessionPageState extends ConsumerState<LiveSessionPage> {
  late final LiveSessionKey _key;
  bool _showResources = false;

  @override
  void initState() {
    super.initState();
    _key = (courseId: widget.courseId, courseTitle: widget.courseTitle, isTeacher: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(liveSessionControllerProvider(_key).notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(liveSessionControllerProvider(_key));
    final ctrl = ref.read(liveSessionControllerProvider(_key).notifier);

    // Show ended screen instead of popping immediately
    ref.listen(liveSessionControllerProvider(_key), (_, next) {
      if (next.isEnded && mounted) {
        showAppToast(context, message: 'تم إنهاء البث', color: const Color(0xFF6264A7));
      }
    });

    // Session ended — show stats screen
    if (state.isEnded) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: SessionEndedScreen(
            isTeacher: true,
            durationSeconds: state.elapsedSeconds,
            viewerCount: state.viewerCount,
            sessionTitle: widget.courseTitle,
            onClose: () => Navigator.pop(context),
          ),
        ),
      );
    }

    return PopScope(
      canPop: state.hasError || state.isInitializing,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => const _ConfirmEndDialog(isPop: true),
        );
        if (confirm == true) await ctrl.endSession();
      },
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(child: _buildBody(context, state, ctrl)),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, LiveSessionState state, LiveSessionController ctrl) {
    if (state.hasError) {
      return _ErrorView(message: state.error!, onBack: () => Navigator.pop(context));
    }
    if (state.isInitializing) {
      return const _LoadingView(message: 'جاري تهيئة البث...');
    }

    final teacherState = ref.watch(liveSessionNotifierProvider);
    final teacherSid = teacherState.sessionId;
    final sid = state.sessionId ?? teacherSid;
    final sessionInitFailed = teacherState.startSessionFailed && sid == null;

    final liveChatState = sid != null ? ref.watch(liveChatProvider(sid)) : null;
    final showChat = liveChatState?.isOpen ?? false;

    return Stack(
      children: [
        // ── Camera preview ──────────────────────────────────────────────────
        Positioned.fill(child: _VideoView(state: state, ctrl: ctrl)),

        // ── Recording toast listener ────────────────────────────────────────
        if (sid != null) _RecordingListener(sessionId: sid),

        // ── Floating reactions ──────────────────────────────────────────────
        if (sid != null) FloatingReactionsOverlay(sessionId: sid),

        // ── Reconnect banner ────────────────────────────────────────────────
        if (state.showReconnectBanner)
          Positioned(
            top: 0, left: 0, right: 0,
            child: _ReconnectBanner(attempts: state.reconnectAttempts, onRetry: ctrl.retryConnect),
          ),

        // ── Top bar ─────────────────────────────────────────────────────────
        Positioned(
          top: 0, left: 0, right: 0,
          child: _TopBar(state: state, sessionId: sid),
        ),

        // ── Session init failed banner ──────────────────────────────────────
        // Shown when Agora is live but Supabase insert failed (RLS or network).
        // Tap "إعادة المحاولة" to retry the DB insert without restarting Agora.
        if (sessionInitFailed)
          Positioned(
            top: 72, left: 16, right: 16,
            child: _SessionInitFailedBanner(
              onRetry: () async {
                final teacherId = ref.read(authProvider).user?.id ?? '';
                await ref.read(liveSessionNotifierProvider.notifier).retryStartSession(
                  courseId: widget.courseId,
                  title: widget.courseTitle,
                  teacherId: teacherId,
                );
                final newSid = ref.read(liveSessionNotifierProvider).sessionId;
                if (newSid != null) {
                  ref.read(liveSessionControllerProvider(_key).notifier)
                      .setSessionId(newSid);
                }
              },
            ),
          ),

        // ── Chat panel ──────────────────────────────────────────────────────
        if (showChat && sid != null)
          Positioned(
            bottom: _kControlsH,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.44,
            child: LiveChatPanel(
              sessionId: sid,
              isTeacher: true,
              onClose: () => ref.read(liveChatProvider(sid).notifier).closeChat(),
            ),
          ),

        // ── Resources panel ─────────────────────────────────────────────────
        if (_showResources && sid != null)
          Positioned(
            bottom: _kControlsH,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.44,
            child: LectureResourcesPanel(
              sessionId: sid,
              teacherId: _teacherIdFromRef(),
              onClose: () => setState(() => _showResources = false),
            ),
          ),

        // ── Bottom controls ─────────────────────────────────────────────────
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: _BottomControls(
            state: state,
            sessionId: sid,
            courseId: widget.courseId,
            ctrl: ctrl,
            showResources: _showResources,
            onEnd: () => _confirmEnd(context, ctrl),
            onToggleResources: () => setState(() {
              _showResources = !_showResources;
              if (_showResources && showChat && sid != null) {
                ref.read(liveChatProvider(sid).notifier).closeChat();
              }
            }),
            onToggleChat: () {
              if (sid == null) return;
              setState(() => _showResources = false);
              if (showChat) {
                ref.read(liveChatProvider(sid).notifier).closeChat();
              } else {
                ref.read(liveChatProvider(sid).notifier).openChat();
              }
            },
            onShowParticipants: () {
              if (sid != null) {
                showParticipantsSheet(context, sessionId: sid, isTeacher: true);
              }
            },
          ),
        ),
      ],
    );
  }

  String? _teacherIdFromRef() => ref.read(authProvider).user?.id;

  Future<void> _confirmEnd(BuildContext context, LiveSessionController ctrl) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const _ConfirmEndDialog(isPop: false),
    );
    if (confirmed == true) {
      if (state.sessionId != null) {
        await ref
            .read(recordingControllerProvider(state.sessionId!).notifier)
            .stopRecording(widget.courseId);
      }
      await ctrl.endSession();
    }
  }

  LiveSessionState get state => ref.read(liveSessionControllerProvider(_key));
}

// ── Video View ────────────────────────────────────────────────────────────────

class _VideoView extends StatelessWidget {
  final LiveSessionState state;
  final LiveSessionController ctrl;

  const _VideoView({required this.state, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final showBlack =
        state.cameraOff || state.isAudioOnly || state.isPaused || state.isScreenSharing;
    if (showBlack || ctrl.engine == null) {
      final IconData icon;
      final String label;
      if (state.isScreenSharing) {
        icon = Icons.screen_share_outlined;
        label = 'مشاركة الشاشة نشطة';
      } else if (state.isPaused) {
        icon = Icons.pause_circle_outline;
        label = 'البث متوقف مؤقتاً';
      } else if (state.isAudioOnly) {
        icon = Icons.mic;
        label = 'وضع الصوت فقط';
      } else {
        icon = Icons.videocam_off;
        label = 'الكاميرا مغلقة — انقر للتفعيل';
      }
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  color: state.isScreenSharing
                      ? const Color(0xFF22C55E)
                      : Colors.white24,
                  size: 64),
              const SizedBox(height: 12),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white38, fontFamily: 'Cairo', fontSize: 14)),
            ],
          ),
        ),
      );
    }
    return AgoraVideoView(
      controller: VideoViewController(
        rtcEngine: ctrl.engine!,
        canvas: const VideoCanvas(uid: 0),
      ),
    );
  }
}

// ── Top Bar ───────────────────────────────────────────────────────────────────

class _TopBar extends ConsumerWidget {
  final LiveSessionState state;
  final String? sessionId;

  const _TopBar({required this.state, required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recState = sessionId != null
        ? ref.watch(recordingControllerProvider(sessionId!))
        : null;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Status badge
          _StatusBadge(state: state),
          const SizedBox(width: 8),
          // Timer
          Text(
            _fmt(state.elapsedSeconds),
            style: const TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'Cairo'),
          ),
          const SizedBox(width: 10),
          // Viewers
          Row(
            children: [
              const Icon(Icons.people_outline, color: Colors.white54, size: 15),
              const SizedBox(width: 3),
              Text('${state.viewerCount}',
                  style: const TextStyle(color: Colors.white54, fontSize: 13, fontFamily: 'Cairo')),
            ],
          ),
          const Spacer(),
          // Screen share indicator
          if (state.isScreenSharing) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.45)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.screen_share_outlined,
                      color: Color(0xFF22C55E), size: 12),
                  SizedBox(width: 4),
                  Text('مشاركة الشاشة',
                      style: TextStyle(
                          color: Color(0xFF22C55E),
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],
          // REC indicator
          if (recState != null && recState.isActive) ...[
            _RecIndicator(elapsed: recState.elapsedLabel),
            const SizedBox(width: 10),
          ],
          // Network quality
          _NetIcon(quality: state.networkQuality),
        ],
      ),
    );
  }

  String _fmt(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

// ── REC Indicator ─────────────────────────────────────────────────────────────

class _RecIndicator extends StatefulWidget {
  final String elapsed;

  const _RecIndicator({required this.elapsed});

  @override
  State<_RecIndicator> createState() => _RecIndicatorState();
}

class _RecIndicatorState extends State<_RecIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blink;

  @override
  void initState() {
    super.initState();
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _blink,
      builder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(
              opacity: _blink.value,
              child: const Icon(Icons.circle, color: Colors.red, size: 8),
            ),
            const SizedBox(width: 5),
            Text(
              'REC ${widget.elapsed}',
              style: const TextStyle(
                  color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bottom Controls ───────────────────────────────────────────────────────────
// Layout: [secondary: chat | participants | files | rec | screen-share]
//          [primary pill: mic | end | camera (long-press = flip)]

class _BottomControls extends ConsumerWidget {
  final LiveSessionState state;
  final String? sessionId;
  final String courseId;
  final LiveSessionController ctrl;
  final bool showResources;
  final VoidCallback onEnd;
  final VoidCallback onToggleResources;
  final VoidCallback onToggleChat;
  final VoidCallback onShowParticipants;

  const _BottomControls({
    required this.state,
    required this.sessionId,
    required this.courseId,
    required this.ctrl,
    required this.showResources,
    required this.onEnd,
    required this.onToggleResources,
    required this.onToggleChat,
    required this.onShowParticipants,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sid = sessionId;

    final unread   = sid != null ? ref.watch(liveChatProvider(sid)).unreadCount          : 0;
    final chatOpen = sid != null ? ref.watch(liveChatProvider(sid)).isOpen               : false;
    final pending  = sid != null ? ref.watch(participantsProvider(sid)).pendingHandCount  : 0;
    final recState = sid != null ? ref.watch(recordingControllerProvider(sid))           : null;

    final recLoading = recState?.phase == RecordingPhase.acquiring ||
        recState?.phase == RecordingPhase.stopping;
    final recActive = recState?.isActive ?? false;
    final recIcon   = recActive ? Icons.stop_circle_outlined : Icons.fiber_manual_record;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: 0.90),
            Colors.black.withValues(alpha: 0.32),
            Colors.transparent,
          ],
          stops: const [0.0, 0.60, 1.0],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Secondary strip: chat | participants | files | recording ─────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Chat
              LiveSecButton(
                icon: chatOpen
                    ? Icons.chat_bubble_rounded
                    : Icons.chat_bubble_outline_rounded,
                active: chatOpen,
                badge: unread,
                disabled: sid == null,
                onTap: sid != null ? onToggleChat : null,
              ),
              const SizedBox(width: 24),
              // Participants
              LiveSecButton(
                icon: Icons.people_alt_rounded,
                badge: pending,
                badgeColor: const Color(0xFFF59E0B),
                disabled: sid == null,
                onTap: sid != null ? onShowParticipants : null,
              ),
              const SizedBox(width: 24),
              // Files / resources
              LiveSecButton(
                icon: Icons.folder_open_rounded,
                active: showResources,
                disabled: sid == null,
                onTap: sid != null ? onToggleResources : null,
              ),
              const SizedBox(width: 24),
              // Recording
              LiveSecButton(
                icon: recIcon,
                active: recActive,
                loading: recLoading,
                disabled: sid == null,
                activeColor: const Color(0xFFEF4444),
                onTap: sid == null || recLoading
                    ? null
                    : () => _onRecordingTap(context, ref, sid, recState),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // ── Screen share toggle pill ────────────────────────────────────
          _ScreenSharePill(
            isSharing: state.isScreenSharing,
            onTap: () => _onScreenShareTap(context),
          ),
          const SizedBox(height: 10),
          // ── Primary pill ────────────────────────────────────────────────
          Center(
            child: LivePrimaryPill(
              leading: Semantics(
                identifier: 'live_session_btn_mute',
                child: LivePillButton(
                  icon: state.micMuted ? Icons.mic_off : Icons.mic,
                  danger: state.micMuted,
                  onTap: ctrl.toggleMic,
                ),
              ),
              center: Semantics(
                identifier: 'live_session_btn_end',
                child: LiveEndButton(onTap: onEnd),
              ),
              trailing: Semantics(
                identifier: 'live_session_btn_flip_camera',
                child: LivePillButton(
                  icon: (state.cameraOff || state.isScreenSharing)
                      ? Icons.videocam_off
                      : Icons.videocam,
                  danger: state.cameraOff || state.isScreenSharing,
                  onTap: state.isScreenSharing ? () {} : ctrl.toggleCamera,
                  onLongPress:
                      (state.cameraOff || state.isScreenSharing) ? null : ctrl.flipCamera,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  void _onRecordingTap(
    BuildContext context,
    WidgetRef ref,
    String sid,
    RecordingState? recState,
  ) {
    final notifier = ref.read(recordingControllerProvider(sid).notifier);
    if (recState?.isActive == true) {
      notifier.stopRecording(courseId);
    } else if (recState?.canStart ?? true) {
      notifier.startRecording(courseId);
    }
  }

  Future<void> _onScreenShareTap(BuildContext context) async {
    try {
      await ctrl.toggleScreenShare();
    } catch (e) {
      if (context.mounted) {
        showAppToast(context,
            message: 'تعذر مشاركة الشاشة: $e', type: ToastType.error);
      }
    }
  }
}

// ── Recording Listener (toast feedback) ───────────────────────────────────────

class _RecordingListener extends ConsumerWidget {
  final String sessionId;
  const _RecordingListener({required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(recordingControllerProvider(sessionId), (prev, next) {
      if (!context.mounted || prev?.phase == next.phase) return;
      switch (next.phase) {
        case RecordingPhase.acquiring:
          showAppToast(context,
              message: 'جاري بدء التسجيل...',
              type: ToastType.info,
              icon: Icons.fiber_manual_record);
        case RecordingPhase.recording:
          showAppToast(context,
              message: 'التسجيل يعمل الآن',
              type: ToastType.success,
              icon: Icons.fiber_manual_record);
        case RecordingPhase.stopping:
          showAppToast(context,
              message: 'جاري إيقاف التسجيل...',
              type: ToastType.info);
        case RecordingPhase.completed:
          showAppToast(context,
              message: 'تم حفظ التسجيل',
              type: ToastType.success);
        case RecordingPhase.failed:
          showAppToast(context,
              message: 'فشل التسجيل: ${next.error ?? "خطأ"}',
              type: ToastType.error,
              duration: const Duration(seconds: 4));
        default:
          break;
      }
    });
    return const SizedBox.shrink();
  }
}

// ── Session Init Failed Banner ────────────────────────────────────────────────
// Shown when Agora joined successfully but Supabase session insert failed.
// The teacher can retry without restarting the Agora broadcast.

class _SessionInitFailedBanner extends StatelessWidget {
  final VoidCallback onRetry;
  const _SessionInitFailedBanner({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xE61A1200),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Color(0xFFF59E0B), size: 18),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'تعذّر تهيئة الجلسة — الدردشة والمشاركون معطّلة',
              style: TextStyle(
                  color: Colors.white70, fontFamily: 'Cairo', fontSize: 11),
            ),
          ),
          const SizedBox(width: 8),
          Semantics(
            identifier: 'live_session_btn_retry',
            child: GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
                ),
                child: const Text('إعادة المحاولة',
                    style: TextStyle(
                        color: Color(0xFFF59E0B),
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reconnect Banner ──────────────────────────────────────────────────────────

class _ReconnectBanner extends StatelessWidget {
  final int attempts;
  final VoidCallback onRetry;

  const _ReconnectBanner({required this.attempts, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xCC1A1A2E),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(color: Colors.white54, strokeWidth: 2),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              attempts < 5 ? 'إعادة الاتصال... (محاولة $attempts)' : 'تعذر الاتصال',
              style: const TextStyle(color: Colors.white70, fontFamily: 'Cairo', fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('إعادة المحاولة',
                style: TextStyle(color: Color(0xFF6264A7), fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }
}

// ── Status Badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final LiveSessionState state;

  const _StatusBadge({required this.state});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    if (state.isPaused) {
      color = Colors.orange;
      label = 'متوقف';
    } else if (state.isReconnecting) {
      color = Colors.yellow;
      label = 'إعادة اتصال';
    } else {
      color = const Color(0xFFDC2626);
      label = 'مباشر';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (state.isLive) ...[
            const Icon(Icons.circle, color: Colors.white, size: 7),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  fontFamily: 'Cairo')),
        ],
      ),
    );
  }
}

// ── Network Icon ──────────────────────────────────────────────────────────────

class _NetIcon extends StatelessWidget {
  final NetQuality quality;

  const _NetIcon({required this.quality});

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final Color color;
    switch (quality) {
      case NetQuality.excellent:
      case NetQuality.good:
        icon = Icons.signal_wifi_4_bar;
        color = const Color(0xFF22C55E);
      case NetQuality.poor:
        icon = Icons.network_wifi_3_bar;
        color = const Color(0xFFF59E0B);
      case NetQuality.bad:
      case NetQuality.offline:
        icon = Icons.signal_wifi_bad;
        color = const Color(0xFFEF4444);
      default:
        icon = Icons.signal_wifi_4_bar;
        color = Colors.white38;
    }
    return Icon(icon, color: color, size: 16);
  }
}

// ── Screen Share Pill ─────────────────────────────────────────────────────────
/// Pill-shaped toggle for camera-mode ↔ screen-share mode.
/// Inactive: subtle white capsule "مشاركة الشاشة"
/// Active: green gradient capsule "إيقاف المشاركة"
class _ScreenSharePill extends StatefulWidget {
  final bool isSharing;
  final VoidCallback onTap;

  const _ScreenSharePill({required this.isSharing, required this.onTap});

  @override
  State<_ScreenSharePill> createState() => _ScreenSharePillState();
}

class _ScreenSharePillState extends State<_ScreenSharePill> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) {
        setState(() => _down = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            gradient: widget.isSharing
                ? const LinearGradient(
                    colors: [Color(0xFF15803D), Color(0xFF22C55E)],
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                  )
                : null,
            color: widget.isSharing ? null : Colors.white.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isSharing
                  ? const Color(0xFF22C55E).withValues(alpha: 0.65)
                  : Colors.white.withValues(alpha: 0.22),
              width: 1.0,
            ),
            boxShadow: widget.isSharing
                ? [
                    BoxShadow(
                      color: const Color(0xFF22C55E).withValues(alpha: 0.36),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.isSharing
                    ? Icons.stop_screen_share_outlined
                    : Icons.present_to_all_outlined,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Text(
                  widget.isSharing ? 'إيقاف المشاركة' : 'مشاركة الشاشة',
                  key: ValueKey(widget.isSharing),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Confirm End Dialog ────────────────────────────────────────────────────────

class _ConfirmEndDialog extends StatelessWidget {
  final bool isPop;

  const _ConfirmEndDialog({required this.isPop});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Text(isPop ? 'مغادرة البث' : 'إنهاء البث'),
        content: Text(isPop
            ? 'سيستمر البث لو غادرت. هل تريد الإنهاء؟'
            : 'هل تريد إنهاء البث المباشر؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false), child: const Text('لا')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('إنهاء'),
          ),
        ],
      ),
    );
  }
}

// ── Loading / Error Views ─────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  final String message;

  const _LoadingView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: Colors.white54),
          const SizedBox(height: 20),
          Text(message,
              style: const TextStyle(color: Colors.white54, fontSize: 15, fontFamily: 'Cairo')),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onBack;

  const _ErrorView({required this.message, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 56),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(color: Colors.white70, fontSize: 14, fontFamily: 'Cairo')),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: onBack, child: const Text('رجوع')),
          ],
        ),
      ),
    );
  }
}
