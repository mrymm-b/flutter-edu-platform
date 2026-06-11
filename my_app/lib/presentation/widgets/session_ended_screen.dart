import 'package:flutter/material.dart';

class SessionEndedScreen extends StatelessWidget {
  final bool isTeacher;
  final int durationSeconds;
  final int viewerCount; // teacher only
  final String sessionTitle;
  final VoidCallback onClose;

  const SessionEndedScreen({
    super.key,
    required this.isTeacher,
    required this.durationSeconds,
    required this.sessionTitle,
    required this.onClose,
    this.viewerCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6264A7), Color(0xFF464775)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6264A7).withValues(alpha: 0.4),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 44,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    isTeacher ? 'انتهى البث بنجاح' : 'انتهت الحصة',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    sessionTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                      fontFamily: 'Cairo',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 32),

                  // Stats
                  _StatsRow(
                    items: [
                      _StatItem(
                        icon: Icons.timer_outlined,
                        label: 'المدة',
                        value: _fmt(durationSeconds),
                      ),
                      if (isTeacher)
                        _StatItem(
                          icon: Icons.people_outline,
                          label: 'الحضور',
                          value: '$viewerCount',
                        ),
                      _StatItem(
                        icon: isTeacher
                            ? Icons.cast_connected_outlined
                            : Icons.school_outlined,
                        label: isTeacher ? 'البث' : 'الحصة',
                        value: isTeacher ? 'مكتمل' : 'مكتملة',
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Close button
                  SizedBox(
                    width: double.infinity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF464775), Color(0xFF6264A7)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ElevatedButton(
                        onPressed: onClose,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          isTeacher ? 'العودة للدورات' : 'العودة',
                          style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 15,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _fmt(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h}س ${m}د'; // ignore: unnecessary_brace_in_string_interps
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class _StatsRow extends StatelessWidget {
  final List<_StatItem> items;

  const _StatsRow({required this.items});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: items
          .map((item) => Expanded(child: _StatCard(item: item)))
          .toList(),
    );
  }
}

class _StatItem {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({required this.icon, required this.label, required this.value});
}

class _StatCard extends StatelessWidget {
  final _StatItem item;

  const _StatCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(item.icon, color: const Color(0xFF6264A7), size: 22),
          const SizedBox(height: 6),
          Text(
            item.value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.label,
            style: const TextStyle(color: Colors.white38, fontSize: 11, fontFamily: 'Cairo'),
          ),
        ],
      ),
    );
  }
}
