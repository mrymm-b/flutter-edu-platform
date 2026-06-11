import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class ReplayPage extends StatefulWidget {
  final String videoUrl;
  final String sessionTitle;
  final DateTime? recordedAt;

  const ReplayPage({
    super.key,
    required this.videoUrl,
    required this.sessionTitle,
    this.recordedAt,
  });

  @override
  State<ReplayPage> createState() => _ReplayPageState();
}

class _ReplayPageState extends State<ReplayPage> {
  late VideoPlayerController _ctrl;
  bool _initialized = false;
  bool _error = false;
  bool _showControls = true;
  double _speed = 1.0;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    final uri = Uri.parse(widget.videoUrl);
    _ctrl = VideoPlayerController.networkUrl(uri);
    try {
      await _ctrl.initialize();
      _ctrl.addListener(_onPlayerChanged);
      if (mounted) {
        setState(() => _initialized = true);
        _ctrl.play();
        _scheduleHideControls();
      }
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  void _onPlayerChanged() {
    if (mounted) setState(() {});
  }

  void _scheduleHideControls() {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _ctrl.value.isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _scheduleHideControls();
  }

  void _togglePlay() {
    if (_ctrl.value.isPlaying) {
      _ctrl.pause();
      setState(() => _showControls = true);
    } else {
      _ctrl.play();
      _scheduleHideControls();
    }
  }

  void _seek(Duration delta) {
    final raw = _ctrl.value.position + delta;
    final clamped = raw < Duration.zero
        ? Duration.zero
        : raw > _ctrl.value.duration
            ? _ctrl.value.duration
            : raw;
    _ctrl.seekTo(clamped);
  }

  void _setSpeed(double speed) {
    _speed = speed;
    _ctrl.setPlaybackSpeed(speed);
    setState(() {});
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onPlayerChanged);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: _error
              ? _ErrorView(onBack: () => Navigator.pop(context))
              : !_initialized
                  ? _LoadingView(title: widget.sessionTitle)
                  : _PlayerView(
                      ctrl: _ctrl,
                      title: widget.sessionTitle,
                      recordedAt: widget.recordedAt,
                      showControls: _showControls,
                      speed: _speed,
                      onTap: _toggleControls,
                      onPlay: _togglePlay,
                      onSeekBack: () => _seek(const Duration(seconds: -10)),
                      onSeekForward: () => _seek(const Duration(seconds: 10)),
                      onSpeedChange: _setSpeed,
                      onBack: () => Navigator.pop(context),
                    ),
        ),
      ),
    );
  }
}

// ── Player View ───────────────────────────────────────────────────────────────

class _PlayerView extends StatelessWidget {
  final VideoPlayerController ctrl;
  final String title;
  final DateTime? recordedAt;
  final bool showControls;
  final double speed;
  final VoidCallback onTap;
  final VoidCallback onPlay;
  final VoidCallback onSeekBack;
  final VoidCallback onSeekForward;
  final void Function(double) onSpeedChange;
  final VoidCallback onBack;

  const _PlayerView({
    required this.ctrl,
    required this.title,
    required this.recordedAt,
    required this.showControls,
    required this.speed,
    required this.onTap,
    required this.onPlay,
    required this.onSeekBack,
    required this.onSeekForward,
    required this.onSpeedChange,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final pos = ctrl.value.position;
    final dur = ctrl.value.duration;
    final progress = dur.inMilliseconds > 0
        ? pos.inMilliseconds / dur.inMilliseconds
        : 0.0;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          // Video
          Positioned.fill(
            child: Center(
              child: AspectRatio(
                aspectRatio: ctrl.value.aspectRatio,
                child: VideoPlayer(ctrl),
              ),
            ),
          ),

          // Controls overlay
          AnimatedOpacity(
            opacity: showControls ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 250),
            child: IgnorePointer(
              ignoring: !showControls,
              child: Stack(
                children: [
                  // Top gradient + header
                  Positioned(
                    top: 0, left: 0, right: 0,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black87, Colors.transparent],
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(8, 8, 16, 32),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                            onPressed: onBack,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Cairo',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (recordedAt != null)
                                  Text(
                                    _formatDate(recordedAt!),
                                    style: const TextStyle(
                                        color: Colors.white54, fontSize: 12, fontFamily: 'Cairo'),
                                  ),
                              ],
                            ),
                          ),
                          // Speed button
                          _SpeedButton(speed: speed, onChanged: onSpeedChange),
                        ],
                      ),
                    ),
                  ),

                  // Center play controls
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _RoundBtn(
                          icon: Icons.replay_10_rounded,
                          onTap: onSeekBack,
                          size: 44,
                        ),
                        const SizedBox(width: 28),
                        _RoundBtn(
                          icon: ctrl.value.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          onTap: onPlay,
                          size: 64,
                          filled: true,
                        ),
                        const SizedBox(width: 28),
                        _RoundBtn(
                          icon: Icons.forward_10_rounded,
                          onTap: onSeekForward,
                          size: 44,
                        ),
                      ],
                    ),
                  ),

                  // Bottom gradient + seek bar
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black87, Colors.transparent],
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 32, 16, 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Time labels
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_fmt(pos),
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 12, fontFamily: 'Cairo')),
                              Text(_fmt(dur),
                                  style: const TextStyle(
                                      color: Colors.white38, fontSize: 12, fontFamily: 'Cairo')),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // Seek bar
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                              trackHeight: 3,
                              activeTrackColor: const Color(0xFF6264A7),
                              inactiveTrackColor: Colors.white24,
                              thumbColor: const Color(0xFF6264A7),
                              overlayColor: const Color(0x336264A7),
                            ),
                            child: Slider(
                              value: progress.clamp(0.0, 1.0),
                              onChanged: (v) {
                                ctrl.seekTo(dur * v);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    if (h > 0) return '$h:$m:$s';
    return '$m:$s';
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ── Speed Picker ──────────────────────────────────────────────────────────────

class _SpeedButton extends StatelessWidget {
  final double speed;
  final void Function(double) onChanged;

  const _SpeedButton({required this.speed, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<double>(
      initialValue: speed,
      color: const Color(0xFF1A1A2E),
      onSelected: onChanged,
      itemBuilder: (_) => [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
          .map((s) => PopupMenuItem(
                value: s,
                child: Text(
                  '${s}x',
                  style: TextStyle(
                    color: s == speed ? const Color(0xFF6264A7) : Colors.white70,
                    fontFamily: 'Cairo',
                    fontWeight: s == speed ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ))
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '${speed}x',
          style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'Cairo'),
        ),
      ),
    );
  }
}

// ── Round Button ──────────────────────────────────────────────────────────────

class _RoundBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final bool filled;

  const _RoundBtn({
    required this.icon,
    required this.onTap,
    required this.size,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: filled
              ? const Color(0xFF6264A7)
              : Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
          border: filled ? null : Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.52),
      ),
    );
  }
}

// ── Loading / Error Views ─────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  final String title;

  const _LoadingView({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: Color(0xFF6264A7)),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(color: Colors.white54, fontFamily: 'Cairo', fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text('جاري تحميل التسجيل...',
              style: TextStyle(color: Colors.white38, fontFamily: 'Cairo', fontSize: 12)),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onBack;

  const _ErrorView({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 56),
          const SizedBox(height: 16),
          const Text('تعذر تشغيل التسجيل',
              style: TextStyle(color: Colors.white70, fontFamily: 'Cairo', fontSize: 15)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onBack,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6264A7)),
            child: const Text('رجوع', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }
}
