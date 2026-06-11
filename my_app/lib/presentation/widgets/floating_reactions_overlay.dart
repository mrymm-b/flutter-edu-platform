import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/live_chat_provider.dart';

// Each floating reaction: emoji + random X + unique key for animation
class _FloatingItem {
  final String emoji;
  final double x; // 0.0 – 1.0 (fraction of screen width)
  final Key key;

  _FloatingItem({required this.emoji, required this.x}) : key = UniqueKey();
}

// ── Overlay Widget ────────────────────────────────────────────────────────────

class FloatingReactionsOverlay extends ConsumerStatefulWidget {
  final String sessionId;

  const FloatingReactionsOverlay({super.key, required this.sessionId});

  @override
  ConsumerState<FloatingReactionsOverlay> createState() => _FloatingReactionsOverlayState();
}

class _FloatingReactionsOverlayState extends ConsumerState<FloatingReactionsOverlay> {
  final _rand = Random();
  final _active = <_FloatingItem>[];
  String? _lastSeenId;

  @override
  Widget build(BuildContext context) {
    // Watch for new reaction messages
    ref.listen(sessionMessagesStreamProvider(widget.sessionId), (prev, next) {
      next.whenData((msgs) {
        // Only process messages newer than what we've seen
        final reactions = msgs
            .where((m) => m.type == MessageType.reaction)
            .toList();
        if (reactions.isEmpty) return;

        final latest = reactions.last;
        if (latest.id == _lastSeenId) return;
        _lastSeenId = latest.id;

        // Find all new reactions since last seen
        final prevId = prev?.valueOrNull
            ?.where((m) => m.type == MessageType.reaction)
            .lastOrNull
            ?.id;
        final newReactions = prevId == null
            ? [latest]
            : reactions.skipWhile((m) => m.id != prevId).skip(1).toList();

        for (final msg in newReactions) {
          _addReaction(msg.message);
        }
      });
    });

    if (_active.isEmpty) return const SizedBox.shrink();

    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: _active.map((item) => _FloatingReactionBubble(
                key: item.key,
                emoji: item.emoji,
                xFraction: item.x,
                onDone: () {
                  if (mounted) setState(() => _active.remove(item));
                },
              )).toList(),
        ),
      ),
    );
  }

  void _addReaction(String emoji) {
    if (!mounted) return;
    setState(() {
      _active.add(_FloatingItem(
        emoji: emoji,
        x: 0.15 + _rand.nextDouble() * 0.7, // 15%–85% of screen width
      ));
      // Cap at 12 simultaneous animations
      if (_active.length > 12) _active.removeAt(0);
    });
  }
}

// ── Single Floating Bubble ────────────────────────────────────────────────────

class _FloatingReactionBubble extends StatefulWidget {
  final String emoji;
  final double xFraction;
  final VoidCallback onDone;

  const _FloatingReactionBubble({
    super.key,
    required this.emoji,
    required this.xFraction,
    required this.onDone,
  });

  @override
  State<_FloatingReactionBubble> createState() => _FloatingReactionBubbleState();
}

class _FloatingReactionBubbleState extends State<_FloatingReactionBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _yAnim;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200));

    _yAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _fadeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 10),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 70),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_ctrl);
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.3, end: 1.3), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 10),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 75),
    ]).animate(_ctrl);

    _ctrl.forward().then((_) => widget.onDone());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    final x = widget.xFraction * screenW - 24;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final y = screenH * 0.75 - _yAnim.value * screenH * 0.55;
        return Positioned(
          left: x,
          top: y,
          child: Opacity(
            opacity: _fadeAnim.value,
            child: Transform.scale(
              scale: _scaleAnim.value,
              child: Text(widget.emoji, style: const TextStyle(fontSize: 38)),
            ),
          ),
        );
      },
    );
  }
}
