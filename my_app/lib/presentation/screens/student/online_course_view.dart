import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/utils/toast.dart';
import '../../../domain/models/live_session.dart';
import '../../providers/courses_provider.dart';
import '../../providers/enrollments_provider.dart';
import '../../providers/live_sessions_provider.dart';
import 'student_live_view.dart';

class OnlineCourseViewScreen extends ConsumerWidget {
  final String courseId;

  const OnlineCourseViewScreen({super.key, required this.courseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courseAsync = ref.watch(courseProvider(courseId));
    final isEnrolledAsync = ref.watch(isEnrolledProvider(courseId));
    final sessionsAsync = ref.watch(liveSessionsByCourseProvider(courseId));

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: courseAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
          error: (err, _) => Center(
            child: Text('خطأ: $err',
                style: const TextStyle(color: Colors.white)),
          ),
          data: (course) {
            final isEnrolled = isEnrolledAsync.value ?? false;

            return Column(
              children: [
                // ── Header ──────────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF111827),
                    border: Border(
                        bottom: BorderSide(color: Color(0xFF1F2937))),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Row(
                      children: [
                        Semantics(
                          identifier: 'online_course_view_btn_back',
                          child: IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.chevron_left,
                                color: Colors.white, size: 24),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                course.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (course.description != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  course.description!,
                                  style: const TextStyle(
                                    color: Color(0xFF9CA3AF),
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        // Students count badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1F2937),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.people_outline,
                                  color: Color(0xFF9CA3AF), size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '${course.studentsCount}',
                                style: const TextStyle(
                                  color: Color(0xFF9CA3AF),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Not enrolled banner ──────────────────────────────────────
                if (!isEnrolled)
                  Container(
                    width: double.infinity,
                    color: const Color(0xFF7C2D12),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: const Row(
                      children: [
                        Icon(Icons.lock_outline,
                            color: Color(0xFFFED7AA), size: 16),
                        SizedBox(width: 8),
                        Text(
                          'أنت غير مشترك في هذه الدورة',
                          style: TextStyle(
                              color: Color(0xFFFED7AA), fontSize: 13),
                        ),
                      ],
                    ),
                  ),

                // ── Sessions list ────────────────────────────────────────────
                Expanded(
                  child: sessionsAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: Colors.white54),
                    ),
                    error: (err, _) => Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.white54, size: 48),
                          const SizedBox(height: 8),
                          Text(
                            'تعذر تحميل الجلسات',
                            style: TextStyle(color: Colors.white54),
                          ),
                          Semantics(
                            identifier: 'online_course_view_btn_retry',
                            child: TextButton(
                              onPressed: () => ref.invalidate(
                                  liveSessionsByCourseProvider(courseId)),
                              child: const Text('إعادة المحاولة',
                                  style: TextStyle(color: Colors.white70)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    data: (sessions) => _SessionsList(
                      sessions: sessions,
                      isEnrolled: isEnrolled,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Sessions List ─────────────────────────────────────────────────────────────

class _SessionsList extends StatelessWidget {
  final List<LiveSession> sessions;
  final bool isEnrolled;

  const _SessionsList({
    required this.sessions,
    required this.isEnrolled,
  });

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.live_tv_outlined, color: Color(0xFF374151), size: 64),
            SizedBox(height: 16),
            Text(
              'لا توجد جلسات بعد',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'ستظهر الجلسات هنا عند جدولتها',
              style: TextStyle(color: Color(0xFF4B5563), fontSize: 13),
            ),
          ],
        ),
      );
    }

    // Separate by status: live → scheduled → ended
    final live = sessions.where((s) => s.isLive).toList();
    final upcoming = sessions.where((s) => s.isScheduled).toList();
    final ended = sessions.where((s) => s.isEnded).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (live.isNotEmpty) ...[
          _sectionHeader('مباشر الآن', const Color(0xFFDC2626)),
          const SizedBox(height: 8),
          ...live.map((s) => _SessionCard(session: s, isEnrolled: isEnrolled)),
          const SizedBox(height: 20),
        ],
        if (upcoming.isNotEmpty) ...[
          _sectionHeader('جلسات قادمة', const Color(0xFF2563EB)),
          const SizedBox(height: 8),
          ...upcoming
              .map((s) => _SessionCard(session: s, isEnrolled: isEnrolled)),
          const SizedBox(height: 20),
        ],
        if (ended.isNotEmpty) ...[
          _sectionHeader('جلسات سابقة', const Color(0xFF6B7280)),
          const SizedBox(height: 8),
          ...ended
              .map((s) => _SessionCard(session: s, isEnrolled: isEnrolled)),
        ],
      ],
    );
  }

  Widget _sectionHeader(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

// ── Session Card ──────────────────────────────────────────────────────────────

class _SessionCard extends StatefulWidget {
  final LiveSession session;
  final bool isEnrolled;
  const _SessionCard({required this.session, required this.isEnrolled});

  @override
  State<_SessionCard> createState() => _SessionCardState();
}

class _SessionCardState extends State<_SessionCard> {
  bool _fetchingUrl = false;

  Future<void> _handleTap() async {
    if (widget.session.isLive) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StudentLiveView(
            courseId: widget.session.courseId,
            sessionTitle: widget.session.title,
          ),
        ),
      );
      return;
    }

    if (!widget.session.isEnded || widget.session.recordingUrl == null) return;

    setState(() => _fetchingUrl = true);
    try {
      final signedUrl = await Supabase.instance.client.storage
          .from('recordings')
          .createSignedUrl(widget.session.recordingUrl!, 3600);
      if (!mounted) return;
      final launched = await launchUrl(
        Uri.parse(signedUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        showAppToast(context,
            message: 'تعذّر فتح رابط التسجيل', type: ToastType.error);
      }
    } catch (_) {
      if (mounted) {
        showAppToast(context,
            message: 'تعذّر تحميل رابط التسجيل', type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _fetchingUrl = false);
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final isToday =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    final timeStr = '$hour:$min';
    if (isToday) return 'اليوم — $timeStr';
    const monthNames = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
    ];
    return '${dt.day} ${monthNames[dt.month - 1]} — $timeStr';
  }

  Color _iconBg() {
    if (widget.session.isLive) return const Color(0xFF7F1D1D);
    if (widget.session.isEnded) return const Color(0xFF1F2937);
    return const Color(0xFF1E3A8A);
  }

  Color _iconColor() {
    if (widget.session.isLive) return const Color(0xFFFCA5A5);
    if (widget.session.isEnded) return const Color(0xFF6B7280);
    return const Color(0xFF93C5FD);
  }

  IconData _icon() {
    if (widget.session.isLive) return Icons.live_tv;
    if (widget.session.isEnded) return Icons.play_circle_outline;
    return Icons.event_outlined;
  }

  Widget _statusBadge() {
    if (widget.session.isLive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFDC2626),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, color: Colors.white, size: 6),
            SizedBox(width: 4),
            Text('مباشر',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }
    if (widget.session.isScheduled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF1E3A8A),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text('مجدول',
            style: TextStyle(
                color: Color(0xFF93C5FD),
                fontSize: 11,
                fontWeight: FontWeight.w500)),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text('انتهى',
          style: TextStyle(color: Color(0xFF6B7280), fontSize: 11)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLive = widget.session.isLive;
    final isEnded = widget.session.isEnded;
    final hasRecording = widget.session.recordingUrl != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isLive ? const Color(0xFF1F1010) : const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLive
              ? const Color(0xFFDC2626).withValues(alpha: 0.5)
              : const Color(0xFF334155),
        ),
      ),
      child: Semantics(
        identifier: 'online_course_view_btn_session_card',
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: widget.isEnrolled && (isLive || (isEnded && hasRecording))
                ? _handleTap
                : null,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Status icon — spinner while fetching signed URL
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _iconBg(),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _fetchingUrl
                      ? const Padding(
                          padding: EdgeInsets.all(10),
                          child: CircularProgressIndicator(
                              color: Colors.white54, strokeWidth: 2),
                        )
                      : Icon(_icon(), color: _iconColor(), size: 22),
                ),
                const SizedBox(width: 12),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.session.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(
                          isLive
                              ? widget.session.startedAt
                              : isEnded
                                  ? widget.session.endedAt
                                  : widget.session.scheduledAt,
                        ),
                        style: const TextStyle(
                            color: Color(0xFF6B7280), fontSize: 12),
                      ),
                      if (isEnded && widget.session.durationMinutes != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${widget.session.durationMinutes} دقيقة',
                          style: const TextStyle(
                              color: Color(0xFF4B5563), fontSize: 11),
                        ),
                      ],
                    ],
                  ),
                ),

                // Right badge + recording indicator
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _statusBadge(),
                    if (isEnded && hasRecording) ...[
                      const SizedBox(height: 6),
                      const Row(
                        children: [
                          Icon(Icons.fiber_manual_record,
                              color: Color(0xFF4B5563), size: 8),
                          SizedBox(width: 4),
                          Text('تسجيل',
                              style: TextStyle(
                                  color: Color(0xFF4B5563), fontSize: 11)),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }
}
