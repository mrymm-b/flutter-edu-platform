import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/agora_config.dart';
import '../../providers/live_session_controller.dart';
import '../../providers/live_chat_provider.dart';
import '../../providers/participants_provider.dart';
import '../../widgets/live_chat_panel.dart';
import '../../widgets/participants_sheet.dart';
import '../../widgets/floating_reactions_overlay.dart';
import '../../widgets/session_ended_screen.dart';
import '../../widgets/lecture_resources_panel.dart';
import '../../widgets/live_controls.dart';

const _kControlsH = 152.0;

class StudentLiveView extends ConsumerStatefulWidget {
  final String courseId;
  final String sessionTitle;

  const StudentLiveView({
    super.key,
    required this.courseId,
    required this.sessionTitle,
  });

  @override
  ConsumerState<StudentLiveView> createState() => _StudentLiveViewState();
}

class _StudentLiveViewState extends ConsumerState<StudentLiveView> {
  late final LiveSessionKey _key;
  bool _showResources = false;

  @override
  void initState() {
    super.initState();
    _key = (courseId: widget.courseId, courseTitle: widget.sessionTitle, isTeacher: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(liveSessionControllerProvider(_key).notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(liveSessionControllerProvider(_key));
    final ctrl = ref.read(liveSessionControllerProvider(_key).notifier);

    // Session ended → show stats screen (don't auto-pop)
    if (state.isEnded) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: SessionEndedScreen(
            isTeacher: false,
            durationSeconds: state.elapsedSeconds,
            sessionTitle: widget.sessionTitle,
            onClose: () => Navigator.pop(context),
          ),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(child: _buildBody(context, state, ctrl)),
      ),
    );
  }

  Widget _buildBody(BuildContext context, LiveSessionState state, LiveSessionController ctrl) {
    if (state.hasError) {
      return _ErrorView(message: state.error!, onBack: () => Navigator.pop(context));
    }
    if (state.isInitializing) {
      return const _WaitingView(engineReady: false, title: '');
    }

    final sid = state.sessionId;
    final liveChatState = sid != null ? ref.watch(liveChatProvider(sid)) : null;
    final showChat = liveChatState?.isOpen ?? false;
    final unread = liveChatState?.unreadCount ?? 0;

    return GestureDetector(
      onTap: ctrl.revealControls,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          // ── Remote video ────────────────────────────────────────────────
          Positioned.fill(
            child: _RemoteVideoView(
              state: state,
              ctrl: ctrl,
              title: widget.sessionTitle,
            ),
          ),

          // ── Buffering indicator ─────────────────────────────────────────
          if (state.isBuffering && state.hasTeacherVideo)
            const Positioned.fill(child: _BufferingOverlay()),

          // ── Floating reactions ──────────────────────────────────────────
          if (sid != null) FloatingReactionsOverlay(sessionId: sid),

          // ── Reconnect overlay ───────────────────────────────────────────
          if (state.showReconnectBanner)
            Positioned.fill(child: _ReconnectOverlay(state: state, onRetry: ctrl.retryConnect)),

          // ── Top bar ─────────────────────────────────────────────────────
          AnimatedOpacity(
            opacity: state.showControls ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Positioned(
              top: 0, left: 0, right: 0,
              child: _TopBar(
                state: state,
                title: widget.sessionTitle,
                sessionId: sid,
                onShowParticipants: () {
                  if (sid != null) {
                    showParticipantsSheet(context, sessionId: sid, isTeacher: false);
                  }
                },
              ),
            ),
          ),

          // ── Chat panel ──────────────────────────────────────────────────
          if (showChat && sid != null)
            Positioned(
              bottom: _kControlsH,
              left: 0,
              right: 0,
              height: MediaQuery.of(context).size.height * 0.44,
              child: LiveChatPanel(
                sessionId: sid,
                isTeacher: false,
                onClose: () => ref.read(liveChatProvider(sid).notifier).closeChat(),
              ),
            ),

          // ── Resources panel ─────────────────────────────────────────────
          if (_showResources && sid != null)
            Positioned(
              bottom: _kControlsH,
              left: 0,
              right: 0,
              height: MediaQuery.of(context).size.height * 0.44,
              child: LectureResourcesPanel(
                sessionId: sid,
                onClose: () => setState(() => _showResources = false),
              ),
            ),

          // ── Bottom controls ─────────────────────────────────────────────
          AnimatedOpacity(
            opacity: state.showControls ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Positioned(
              bottom: 0, left: 0, right: 0,
              child: IgnorePointer(
                ignoring: !state.showControls,
                child: _BottomControls(
                  state: state,
                  sessionId: sid,
                  unread: unread,
                  chatOpen: showChat,
                  showResources: _showResources,
                  ctrl: ctrl,
                  onLeave: () => _confirmLeave(context, ctrl),
                  onToggleChat: () {
                    if (sid == null) return;
                    setState(() => _showResources = false);
                    if (showChat) {
                      ref.read(liveChatProvider(sid).notifier).closeChat();
                    } else {
                      ref.read(liveChatProvider(sid).notifier).openChat();
                    }
                  },
                  onToggleResources: () => setState(() {
                    _showResources = !_showResources;
                    if (_showResources && showChat && sid != null) {
                      ref.read(liveChatProvider(sid).notifier).closeChat();
                    }
                  }),
                  onShowParticipants: () {
                    if (sid != null) {
                      showParticipantsSheet(context, sessionId: sid, isTeacher: false);
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLeave(BuildContext context, LiveSessionController ctrl) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('مغادرة البث'),
          content: const Text('هل تريد مغادرة البث المباشر؟'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false), child: const Text('لا')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('مغادرة'),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true) await ctrl.leaveSession();
  }
}

// ── Remote Video View ─────────────────────────────────────────────────────────

class _RemoteVideoView extends StatelessWidget {
  final LiveSessionState state;
  final LiveSessionController ctrl;
  final String title;

  const _RemoteVideoView({required this.state, required this.ctrl, required this.title});

  @override
  Widget build(BuildContext context) {
    if (!state.hasTeacherVideo || state.remoteUid == null || ctrl.engine == null) {
      return _WaitingView(engineReady: state.isLive, title: title);
    }
    return AgoraVideoView(
      controller: VideoViewController.remote(
        rtcEngine: ctrl.engine!,
        canvas: VideoCanvas(uid: state.remoteUid!),
        connection: RtcConnection(channelId: AgoraConfig.channelId(state.sessionId ?? '')),
      ),
    );
  }
}

// ── Buffering Overlay ─────────────────────────────────────────────────────────

class _BufferingOverlay extends StatelessWidget {
  const _BufferingOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF6264A7), strokeWidth: 3),
            SizedBox(height: 14),
            Text('جاري تحميل الفيديو...',
                style: TextStyle(color: Colors.white60, fontFamily: 'Cairo', fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

// ── Reconnect Overlay ─────────────────────────────────────────────────────────

class _ReconnectOverlay extends StatelessWidget {
  final LiveSessionState state;
  final VoidCallback onRetry;

  const _ReconnectOverlay({required this.state, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.72),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.white54),
            const SizedBox(height: 16),
            Text(
              state.reconnectAttempts < 5
                  ? 'إعادة الاتصال... (محاولة ${state.reconnectAttempts})'
                  : 'تعذر الاتصال بالبث',
              style: const TextStyle(color: Colors.white70, fontSize: 14, fontFamily: 'Cairo'),
            ),
            const SizedBox(height: 12),
            if (state.reconnectAttempts >= 5)
              TextButton(
                onPressed: onRetry,
                child: const Text('إعادة المحاولة',
                    style: TextStyle(color: Color(0xFF6264A7), fontFamily: 'Cairo')),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Top Bar ───────────────────────────────────────────────────────────────────

class _TopBar extends ConsumerWidget {
  final LiveSessionState state;
  final String title;
  final String? sessionId;
  final VoidCallback onShowParticipants;

  const _TopBar({
    required this.state,
    required this.title,
    required this.sessionId,
    required this.onShowParticipants,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onlineCount = sessionId != null
        ? ref.watch(participantsProvider(sessionId!)).onlineCount
        : 0;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          // Back
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: Colors.black38, borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 10),
          // Title
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Live badge
          if (state.hasTeacherVideo)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: const Color(0xFFDC2626), borderRadius: BorderRadius.circular(20)),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, color: Colors.white, size: 7),
                  SizedBox(width: 4),
                  Text('مباشر',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold,
                          fontSize: 11, fontFamily: 'Cairo')),
                ],
              ),
            ),
          // Timer
          if (state.elapsedSeconds > 0) ...[
            const SizedBox(width: 8),
            Text(_fmt(state.elapsedSeconds),
                style: const TextStyle(color: Colors.white54, fontSize: 12, fontFamily: 'Cairo')),
          ],
          const SizedBox(width: 8),
          // Participants count (tappable)
          GestureDetector(
            onTap: onShowParticipants,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.people_outline, color: Colors.white54, size: 14),
                  const SizedBox(width: 3),
                  Text('$onlineCount',
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12, fontFamily: 'Cairo')),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          _NetIcon(quality: state.networkQuality),
        ],
      ),
    );
  }

  String _fmt(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }
}

// ── Bottom Controls ───────────────────────────────────────────────────────────
// Layout: [secondary strip: chat | participants | files | more]
//          [primary pill: mute | leave | raise-hand]

class _BottomControls extends ConsumerWidget {
  final LiveSessionState state;
  final String? sessionId;
  final int unread;
  final bool chatOpen;
  final bool showResources;
  final LiveSessionController ctrl;
  final VoidCallback onLeave;
  final VoidCallback onToggleChat;
  final VoidCallback onToggleResources;
  final VoidCallback onShowParticipants;

  const _BottomControls({
    required this.state,
    required this.sessionId,
    required this.unread,
    required this.chatOpen,
    required this.showResources,
    required this.ctrl,
    required this.onLeave,
    required this.onToggleChat,
    required this.onToggleResources,
    required this.onShowParticipants,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sid = sessionId;
    final myHandRaised =
        sid != null ? ref.watch(participantsProvider(sid)).myHandRaised : false;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: 0.88),
            Colors.black.withValues(alpha: 0.30),
            Colors.transparent,
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Secondary strip ─────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LiveSecButton(
                icon: chatOpen
                    ? Icons.chat_bubble_rounded
                    : Icons.chat_bubble_outline_rounded,
                active: chatOpen,
                badge: unread,
                disabled: sid == null,
                onTap: sid != null ? onToggleChat : null,
              ),
              const SizedBox(width: 32),
              LiveSecButton(
                icon: Icons.people_alt_rounded,
                disabled: sid == null,
                onTap: sid != null ? onShowParticipants : null,
              ),
              const SizedBox(width: 32),
              LiveSecButton(
                icon: Icons.folder_open_rounded,
                active: showResources,
                disabled: sid == null,
                onTap: sid != null ? onToggleResources : null,
              ),
            ],
          ),
          const SizedBox(height: 14),
          // ── Primary pill ────────────────────────────────────────────────
          Center(
            child: LivePrimaryPill(
              leading: Semantics(
                identifier: 'live_view_btn_mute',
                child: LivePillButton(
                  icon: state.micMuted ? Icons.volume_off : Icons.volume_up,
                  danger: state.micMuted,
                  onTap: ctrl.toggleRemoteAudio,
                ),
              ),
              center: Semantics(
                identifier: 'live_view_btn_leave',
                child: LiveEndButton(onTap: onLeave),
              ),
              trailing: LivePillButton(
                icon: myHandRaised
                    ? Icons.back_hand_rounded
                    : Icons.back_hand_outlined,
                bgColor: myHandRaised
                    ? const Color(0xFFF59E0B)
                    : null,
                onTap: () {
                  if (sid == null) return;
                  final n = ref.read(participantsProvider(sid).notifier);
                  if (myHandRaised) { n.lowerHand(); } else { n.raiseHand(); }
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

}

// ── Waiting View ──────────────────────────────────────────────────────────────

class _WaitingView extends StatelessWidget {
  final bool engineReady;
  final String title;

  const _WaitingView({required this.engineReady, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F172A),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!engineReady) ...[
              const CircularProgressIndicator(color: Colors.white38),
              const SizedBox(height: 20),
              const Text('جاري الانضمام...',
                  style: TextStyle(color: Colors.white38, fontSize: 14, fontFamily: 'Cairo')),
            ] else ...[
              const Icon(Icons.live_tv_outlined, color: Color(0xFF374151), size: 72),
              const SizedBox(height: 20),
              if (title.isNotEmpty)
                Text(title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo')),
              const SizedBox(height: 10),
              const Text('في انتظار بدء الأستاذ للبث...',
                  style: TextStyle(color: Colors.white38, fontSize: 13, fontFamily: 'Cairo')),
            ],
          ],
        ),
      ),
    );
  }
}


// ── Network Quality Icon ──────────────────────────────────────────────────────

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
                style: const TextStyle(color: Colors.white70, fontSize: 14, fontFamily: 'Cairo')),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: onBack, child: const Text('رجوع')),
          ],
        ),
      ),
    );
  }
}
