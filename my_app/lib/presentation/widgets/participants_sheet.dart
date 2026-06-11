import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/participants_provider.dart';
import '../providers/session_attendance_provider.dart';

// ── Entry point ───────────────────────────────────────────────────────────────

void showParticipantsSheet(
  BuildContext context, {
  required String sessionId,
  required bool isTeacher,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ParticipantsSheet(sessionId: sessionId, isTeacher: isTeacher),
  );
}

// ── Sheet ─────────────────────────────────────────────────────────────────────

class ParticipantsSheet extends ConsumerStatefulWidget {
  final String sessionId;
  final bool isTeacher;

  const ParticipantsSheet({
    super.key,
    required this.sessionId,
    required this.isTeacher,
  });

  @override
  ConsumerState<ParticipantsSheet> createState() => _ParticipantsSheetState();
}

class _ParticipantsSheetState extends ConsumerState<ParticipantsSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: widget.isTeacher ? 3 : 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(participantsProvider(widget.sessionId));
    final pendingCount = state.pendingHandCount;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A2E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Icon(Icons.people_alt_rounded, color: Colors.white70, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'المشاركون',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo'),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6264A7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${state.onlineCount} متصل',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 11, fontFamily: 'Cairo'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Tabs
              TabBar(
                controller: _tab,
                labelColor: const Color(0xFF6264A7),
                unselectedLabelColor: Colors.white38,
                indicatorColor: const Color(0xFF6264A7),
                labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                tabs: [
                  const Tab(text: 'متصلون الآن'),
                  const Tab(text: 'الكل'),
                  if (widget.isTeacher)
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('رفع اليد', style: TextStyle(fontFamily: 'Cairo')),
                          if (pendingCount > 0) ...[
                            const SizedBox(width: 4),
                            Container(
                              width: 18,
                              height: 18,
                              decoration: const BoxDecoration(
                                  color: Color(0xFFEF4444), shape: BoxShape.circle),
                              child: Center(
                                child: Text(
                                  '$pendingCount',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),

              // Tab views
              Expanded(
                child: TabBarView(
                  controller: _tab,
                  children: [
                    _ParticipantsList(records: state.online, scrollCtrl: ctrl),
                    _ParticipantsList(records: state.participants, scrollCtrl: ctrl),
                    if (widget.isTeacher)
                      _HandRaisesList(
                        hands: state.pendingHands,
                        notifier: ref.read(participantsProvider(widget.sessionId).notifier),
                        scrollCtrl: ctrl,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Participants List ─────────────────────────────────────────────────────────

class _ParticipantsList extends StatelessWidget {
  final List<AttendanceRecord> records;
  final ScrollController scrollCtrl;

  const _ParticipantsList({required this.records, required this.scrollCtrl});

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const Center(
        child: Text('لا يوجد مشاركون بعد',
            style: TextStyle(color: Colors.white38, fontFamily: 'Cairo')),
      );
    }
    return ListView.builder(
      controller: scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: records.length,
      itemBuilder: (_, i) => _ParticipantTile(record: records[i]),
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  final AttendanceRecord record;

  const _ParticipantTile({required this.record});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: record.isOnline
                    ? [const Color(0xFF6264A7), const Color(0xFF464775)]
                    : [Colors.grey.shade700, Colors.grey.shade800],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                record.studentName.isNotEmpty ? record.studentName[0] : 'ط',
                style: const TextStyle(
                    color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.studentName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Cairo')),
                Text(
                  record.isOnline ? 'متصل الآن' : 'مدة: ${record.durationLabel}',
                  style: TextStyle(
                      color: record.isOnline
                          ? const Color(0xFF22C55E)
                          : Colors.white38,
                      fontSize: 11,
                      fontFamily: 'Cairo'),
                ),
              ],
            ),
          ),
          // Online dot
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: record.isOnline ? const Color(0xFF22C55E) : Colors.white24,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hand Raises List (teacher only) ──────────────────────────────────────────

class _HandRaisesList extends StatelessWidget {
  final List<HandRaise> hands;
  final ParticipantsNotifier notifier;
  final ScrollController scrollCtrl;

  const _HandRaisesList({
    required this.hands,
    required this.notifier,
    required this.scrollCtrl,
  });

  @override
  Widget build(BuildContext context) {
    if (hands.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.back_hand_outlined, color: Colors.white24, size: 48),
            SizedBox(height: 12),
            Text('لا توجد طلبات رفع يد',
                style: TextStyle(color: Colors.white38, fontFamily: 'Cairo')),
          ],
        ),
      );
    }
    return ListView.builder(
      controller: scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: hands.length,
      itemBuilder: (_, i) {
        final hand = hands[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              const Icon(Icons.back_hand_rounded, color: Color(0xFFF59E0B), size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(hand.studentName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Cairo')),
              ),
              TextButton(
                onPressed: () => notifier.rejectHand(hand.id),
                style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                child: const Text('رفض', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
              ),
              const SizedBox(width: 4),
              ElevatedButton(
                onPressed: () => notifier.approveHand(hand.id, hand.studentName),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('موافقة', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
              ),
            ],
          ),
        );
      },
    );
  }
}
