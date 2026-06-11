import 'dart:ui';
import 'package:flutter/material.dart';

// ─── palette ──────────────────────────────────────────────────────────────────
const _kRed     = Color(0xFFDC2626);
const _kRedDeep = Color(0xFFB91C1C);

// ─── LivePrimaryPill ──────────────────────────────────────────────────────────
/// Frosted-glass pill that holds the 3 primary call-control buttons.
class LivePrimaryPill extends StatelessWidget {
  final Widget leading;
  final Widget center;
  final Widget trailing;

  const LivePrimaryPill({
    super.key,
    required this.leading,
    required this.center,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(48),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          height: 74,
          padding: const EdgeInsets.symmetric(horizontal: 26),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.52),
            borderRadius: BorderRadius.circular(48),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.13),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              leading,
              const SizedBox(width: 24),
              center,
              const SizedBox(width: 24),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

// ─── LivePillButton ────────────────────────────────────────────────────────────
/// Animated button inside the primary pill.
/// [danger] → red background (muted / off states).
/// [bgColor] → fully overrides background (e.g. amber for raise-hand).
class LivePillButton extends StatefulWidget {
  final IconData icon;
  final bool danger;
  final Color? bgColor;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const LivePillButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.danger = false,
    this.bgColor,
    this.onLongPress,
  });

  @override
  State<LivePillButton> createState() => _LivePillButtonState();
}

class _LivePillButtonState extends State<LivePillButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.bgColor ??
        (widget.danger ? _kRed : Colors.white.withValues(alpha: 0.19));

    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) {
        setState(() => _down = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _down = false),
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _down ? 0.86 : 1.0,
        duration: const Duration(milliseconds: 85),
        curve: Curves.easeOut,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Icon(widget.icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

// ─── LiveEndButton ─────────────────────────────────────────────────────────────
/// The prominent red gradient end-call button.
class LiveEndButton extends StatefulWidget {
  final VoidCallback onTap;
  const LiveEndButton({super.key, required this.onTap});

  @override
  State<LiveEndButton> createState() => _LiveEndButtonState();
}

class _LiveEndButtonState extends State<LiveEndButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) {
        setState(() => _down = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.86 : 1.0,
        duration: const Duration(milliseconds: 85),
        curve: Curves.easeOut,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_kRed, _kRedDeep],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _kRed.withValues(alpha: 0.48),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Icon(Icons.call_end, color: Colors.white, size: 26),
        ),
      ),
    );
  }
}

// ─── LiveSecButton ─────────────────────────────────────────────────────────────
/// Compact icon button for the secondary strip (with optional notification badge).
/// [loading] replaces the icon with a small spinner and disables taps.
/// [activeColor] overrides the white tint used for active background/icon (e.g. red for REC, green for screen share).
class LiveSecButton extends StatefulWidget {
  final IconData icon;
  final bool active;
  final bool disabled;
  final bool loading;
  final Color? activeColor;
  final int badge;
  final Color badgeColor;
  final VoidCallback? onTap;

  const LiveSecButton({
    super.key,
    required this.icon,
    this.active = false,
    this.disabled = false,
    this.loading = false,
    this.activeColor,
    this.badge = 0,
    this.badgeColor = const Color(0xFFEF4444),
    this.onTap,
  });

  @override
  State<LiveSecButton> createState() => _LiveSecButtonState();
}

class _LiveSecButtonState extends State<LiveSecButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final eff = !widget.disabled && !widget.loading;
    final accent = widget.activeColor;
    final iconColor = (widget.disabled || widget.loading)
        ? Colors.white24
        : widget.active
            ? (accent ?? Colors.white)
            : Colors.white60;
    final bgColor = (widget.disabled || widget.loading)
        ? Colors.white.withValues(alpha: 0.04)
        : widget.active
            ? (accent != null
                ? accent.withValues(alpha: 0.22)
                : Colors.white.withValues(alpha: 0.22))
            : Colors.white.withValues(alpha: 0.10);
    final borderColor = (widget.disabled || widget.loading)
        ? Colors.white.withValues(alpha: 0.08)
        : widget.active
            ? (accent != null
                ? accent.withValues(alpha: 0.55)
                : Colors.white.withValues(alpha: 0.36))
            : Colors.white.withValues(alpha: 0.12);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) { if (eff) setState(() => _down = true); },
      onTapUp: (_) {
        if (eff) {
          setState(() => _down = false);
          widget.onTap?.call();
        }
      },
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.80 : 1.0,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: 0.8),
              ),
              child: widget.loading
                  ? const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white38, strokeWidth: 2),
                      ),
                    )
                  : Icon(widget.icon, color: iconColor, size: 20),
            ),
            if (widget.badge > 0)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: widget.badgeColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black54, width: 1),
                  ),
                  child: Center(
                    child: Text(
                      widget.badge > 9 ? '9+' : '${widget.badge}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── More Sheet ────────────────────────────────────────────────────────────────

class LiveMoreItem {
  final IconData icon;
  final String label;
  final bool active;
  final Color? activeColor;
  final bool danger;
  final VoidCallback onTap;

  const LiveMoreItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.danger = false,
    this.activeColor,
  });
}

void showLiveMoreSheet(BuildContext context, List<LiveMoreItem> items) {
  if (items.isEmpty) return;
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: false,
    builder: (_) => Directionality(
      textDirection: TextDirection.rtl,
      child: _MoreSheet(items: items),
    ),
  );
}

class _MoreSheet extends StatelessWidget {
  final List<LiveMoreItem> items;
  const _MoreSheet({required this.items});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Container(
        color: const Color(0xFF111827),
        padding: EdgeInsets.fromLTRB(
          20, 12, 20, 24 + MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 16,
                crossAxisSpacing: 8,
                childAspectRatio: 0.78,
              ),
              itemCount: items.length,
              itemBuilder: (ctx, i) {
                final item = items[i];
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                    item.onTap();
                  },
                  child: _MoreTile(item: item),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  final LiveMoreItem item;
  const _MoreTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final accent = item.danger
        ? _kRed
        : (item.activeColor ?? const Color(0xFF6264A7));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: item.active || item.danger
                ? accent.withValues(alpha: 0.22)
                : Colors.white.withValues(alpha: 0.08),
            shape: BoxShape.circle,
            border: Border.all(
              color: item.active || item.danger
                  ? accent.withValues(alpha: 0.55)
                  : Colors.white.withValues(alpha: 0.10),
            ),
          ),
          child: Icon(
            item.icon,
            color: item.active || item.danger ? accent : Colors.white70,
            size: 24,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          item.label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 11,
            fontFamily: 'Cairo',
            height: 1.2,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
