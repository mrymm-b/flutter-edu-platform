import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/app_tokens.dart';
import '../../../core/utils/toast.dart';
import '../../providers/auth_provider.dart';
import '../../providers/private_lessons_provider.dart';
import '../../../presentation/widgets/atmosphere_background.dart';

class BookingCalendarPage extends ConsumerStatefulWidget {
  final String subject;
  final String teacherName;
  final String teacherId;
  final String subjectId;
  final double pricePerHour;

  const BookingCalendarPage({
    super.key,
    required this.subject,
    required this.teacherName,
    required this.teacherId,
    required this.subjectId,
    required this.pricePerHour,
  });

  @override
  ConsumerState<BookingCalendarPage> createState() =>
      _BookingCalendarPageState();
}

class _BookingCalendarPageState extends ConsumerState<BookingCalendarPage> {
  String? selectedMode;
  DateTime? selectedDate;
  String? selectedTime;
  int? selectedHours;
  bool _isSaving = false;

  late final List<DateTime> _days;

  static const _dayAbbr = ['أحد', 'اثن', 'ثلا', 'أرب', 'خمي', 'جمع', 'سبت'];
  static const _dayFull = [
    'الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت',
  ];
  static const _monthNames = [
    '', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
  ];

  final List<String> _times = [
    '8:00 ص',  '9:00 ص',  '10:00 ص',
    '11:00 ص', '12:00 م', '1:00 م',
    '2:00 م',  '3:00 م',  '4:00 م',
    '5:00 م',
  ];

  final List<int> _durations = [1, 2, 3];

  @override
  void initState() {
    super.initState();
    _days = List.generate(14, (i) => DateTime.now().add(Duration(days: i)));
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  String _toDbTime(String display) {
    final parts = display.split(' ');
    final hm = parts[0].split(':');
    int hour = int.parse(hm[0]);
    final min = hm[1];
    if (parts[1] == 'م' && hour != 12) hour += 12;
    if (parts[1] == 'ص' && hour == 12) hour = 0;
    return '${hour.toString().padLeft(2, '0')}:$min:00';
  }

  String _addHours(String t, int h) {
    final p = t.split(':');
    return '${(int.parse(p[0]) + h).toString().padLeft(2, '0')}:${p[1]}:${p[2]}';
  }

  String _fmtDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  String _hoursLabel(int h) =>
      h == 1 ? 'ساعة' : h == 2 ? 'ساعتان' : '$h ساعات';

  bool get _ready =>
      selectedMode != null &&
      selectedDate != null &&
      selectedTime != null &&
      selectedHours != null;

  void _selectMode(String mode) => setState(() {
        selectedMode = mode;
        selectedDate = null;
        selectedTime = null;
        selectedHours = null;
      });

  Future<void> _saveBooking() async {
    if (!_ready) return;
    final user = ref.read(authProvider).user;
    if (user == null) return;

    setState(() => _isSaving = true);
    try {
      final start = _toDbTime(selectedTime!);
      final dateStr = _fmtDate(selectedDate!);

      final existing = await Supabase.instance.client
          .from('private_lesson_bookings')
          .select('id')
          .eq('teacher_id', widget.teacherId)
          .eq('booking_date', dateStr)
          .eq('start_time', start)
          .neq('status', 'cancelled');

      if ((existing as List).isNotEmpty) {
        if (mounted) {
          showAppToast(context,
              message: 'هذا الوقت محجوز، اختر وقتاً آخر',
              type: ToastType.warning);
        }
        setState(() => _isSaving = false);
        return;
      }

      await Supabase.instance.client.from('private_lesson_bookings').insert({
        'student_id': user.id,
        'teacher_id': widget.teacherId,
        'subject_id': widget.subjectId,
        'booking_date': dateStr,
        'start_time': start,
        'end_time': _addHours(start, selectedHours!),
        'duration_hours': selectedHours,
        'price_per_hour': widget.pricePerHour,
        'total_price': selectedHours! * widget.pricePerHour,
        'status': 'pending',
        'notes': selectedMode,
      });
      ref.invalidate(myPrivateLessonBookingsProvider);
      if (mounted) {
        showAppToast(context, message: 'تم إرسال طلب الحجز بنجاح');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        showAppToast(context,
            message: 'فشل الحجز: $e', type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Root ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t = Tok.of(context);
    final totalPrice =
        selectedHours != null ? selectedHours! * widget.pricePerHour : null;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: AtmosphereBackground(
          child: Column(
            children: [
              _buildHeader(t),
              Expanded(child: _buildBody(t)),
              _buildFooter(t, totalPrice),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header — back + avatar + title + price badge ─────────────────────────────

  Widget _buildHeader(Tok t) {
    final priceStr = widget.pricePerHour.toStringAsFixed(
        widget.pricePerHour.truncateToDouble() == widget.pricePerHour ? 0 : 1);
    final initial =
        widget.teacherName.isNotEmpty ? widget.teacherName[0] : '؟';

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppTokens.screenPad, 14, AppTokens.screenPad, 0),
        child: Row(
          children: [
            // Back
            Semantics(
              label: 'رجوع',
              identifier: 'booking_btn_back',
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: t.isDark
                        ? Colors.white.withValues(alpha: 0.07)
                        : t.bg2,
                    borderRadius: BorderRadius.circular(AppTokens.rSm),
                    border: Border.all(color: t.line),
                  ),
                  child: Icon(Icons.arrow_back_ios_new,
                      color: t.ink2, size: 16),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Teacher avatar
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: t.accentTint,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(initial,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: t.accentFg)),
              ),
            ),
            const SizedBox(width: 10),

            // Title + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('حجز درس خصوصي',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: t.ink)),
                  Text(
                    '${widget.teacherName}  ·  ${widget.subject}',
                    style: TextStyle(fontSize: 11, color: t.muted),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Price-per-hour badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: t.accentTint,
                borderRadius: BorderRadius.circular(AppTokens.rSm),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(priceStr,
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: t.accentFg,
                          height: 1.1)),
                  Text('د.ب/ساعة',
                      style: TextStyle(fontSize: 9, color: t.faint)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Body — flowing sections, no card boxes ────────────────────────────────────

  Widget _buildBody(Tok t) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          AppTokens.screenPad, 20, AppTokens.screenPad, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── نوع الدرس — compact segmented ─────────────────────────────
          _label(t, 'نوع الدرس'),
          const SizedBox(height: 8),
          _buildModeSegmented(t),

          // ── التاريخ ───────────────────────────────────────────────────
          _show(selectedMode != null, _buildDateSection(t)),

          // ── الوقت — hero section ──────────────────────────────────────
          _show(selectedDate != null, _buildTimeSection(t)),

          // ── المدة ────────────────────────────────────────────────────
          _show(selectedTime != null, _buildDurationSection(t)),

          // ── ملخص خفيف ────────────────────────────────────────────────
          _show(_ready, _buildInlineSummary(t)),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _label(Tok t, String text) => Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: t.faint,
          letterSpacing: 0.6,
        ),
      );

  Widget _show(bool visible, Widget child) => AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        child: visible ? child : const SizedBox.shrink(),
      );

  // ── Mode — segmented pill control ─────────────────────────────────────────────

  Widget _buildModeSegmented(Tok t) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: t.isDark
            ? Colors.white.withValues(alpha: 0.06)
            : t.bg2,
        borderRadius: BorderRadius.circular(AppTokens.rMd),
        border: Border.all(color: t.line),
      ),
      child: Row(
        children: [
          _modeSegment(t, 'حضوري', Icons.location_on_rounded, solid: false),
          Container(width: 1, color: t.line),
          _modeSegment(t, 'أونلاين', Icons.videocam_rounded, solid: true),
        ],
      ),
    );
  }

  Widget _modeSegment(Tok t, String mode, IconData icon,
      {required bool solid}) {
    final sel = selectedMode == mode;
    final Color bg = sel
        ? (solid ? t.accentFg : t.accentTint)
        : Colors.transparent;
    final Color fg = sel ? (solid ? Colors.white : t.accentFg) : t.muted;
    final border = sel && !solid
        ? const BorderRadius.only(
            topRight: Radius.circular(11), bottomRight: Radius.circular(11))
        : sel && solid
            ? const BorderRadius.only(
                topLeft: Radius.circular(11), bottomLeft: Radius.circular(11))
            : BorderRadius.zero;

    return Expanded(
      child: Semantics(
        identifier: 'booking_btn_mode_$mode',
        child: GestureDetector(
          onTap: () => _selectMode(mode),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(color: bg, borderRadius: border),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: fg, size: 16),
                const SizedBox(width: 6),
                Text(mode,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: fg)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Date section ─────────────────────────────────────────────────────────────

  Widget _buildDateSection(Tok t) {
    final today = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 22),
        _label(t, 'التاريخ'),
        const SizedBox(height: 8),
        SizedBox(
          height: 62,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _days.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (_, i) {
              final day = _days[i];
              final isSel = selectedDate?.day == day.day &&
                  selectedDate?.month == day.month;
              final isToday =
                  day.day == today.day && day.month == today.month;
              final abbr = _dayAbbr[day.weekday % 7];

              return Semantics(
                identifier: 'booking_chip_day_$i',
                child: GestureDetector(
                  onTap: () => setState(() {
                    selectedDate = day;
                    selectedTime = null;
                    selectedHours = null;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 48,
                    decoration: BoxDecoration(
                      color: isSel
                          ? t.accentFg
                          : isToday
                              ? t.accentTint
                              : (t.isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : t.bg2),
                      borderRadius:
                          BorderRadius.circular(AppTokens.rSm),
                      border: Border.all(
                        color: isSel
                            ? t.accentFg
                            : isToday
                                ? t.accentLine
                                : t.line,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(abbr,
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: isSel
                                    ? Colors.white.withValues(alpha: 0.8)
                                    : isToday
                                        ? t.accentFg
                                        : t.faint)),
                        const SizedBox(height: 2),
                        Text('${day.day}',
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: isSel
                                    ? Colors.white
                                    : isToday
                                        ? t.accentFg
                                        : t.ink)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Time section — hero: 3-col grid, larger tiles ─────────────────────────────

  Widget _buildTimeSection(Tok t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 22),
        _label(t, 'الوقت'),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 2.4,
          ),
          itemCount: _times.length,
          itemBuilder: (_, i) {
            final time = _times[i];
            final isSel = selectedTime == time;
            return Semantics(
              identifier: 'booking_chip_time_$i',
              child: GestureDetector(
                onTap: () => setState(() {
                  selectedTime = time;
                  selectedHours = null;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: isSel
                        ? t.accentFg
                        : (t.isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : t.bg2),
                    borderRadius: BorderRadius.circular(AppTokens.rSm),
                    border: Border.all(
                        color: isSel ? t.accentFg : t.line),
                  ),
                  child: Center(
                    child: Text(time,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSel ? Colors.white : t.ink2)),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ── Duration section — small inline pills ─────────────────────────────────────

  Widget _buildDurationSection(Tok t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 22),
        _label(t, 'المدة'),
        const SizedBox(height: 8),
        Row(
          children: [
            for (int i = 0; i < _durations.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(child: _durationPill(t, _durations[i])),
            ],
          ],
        ),
      ],
    );
  }

  Widget _durationPill(Tok t, int hours) {
    final isSel = selectedHours == hours;
    final total = hours * widget.pricePerHour;
    final totalStr =
        total.toStringAsFixed(total.truncateToDouble() == total ? 0 : 1);

    return Semantics(
      identifier: 'booking_btn_duration_$hours',
      child: GestureDetector(
        onTap: () => setState(() => selectedHours = hours),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: isSel
                ? t.accentFg
                : (t.isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : t.bg2),
            borderRadius: BorderRadius.circular(AppTokens.rSm),
            border:
                Border.all(color: isSel ? t.accentFg : t.line),
          ),
          child: Column(
            children: [
              Text(_hoursLabel(hours),
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isSel ? Colors.white : t.ink)),
              const SizedBox(height: 2),
              Text('$totalStr د.ب',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isSel
                          ? Colors.white.withValues(alpha: 0.8)
                          : t.accentFg)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Summary — clean rows, appears after all selections ───────────────────────

  Widget _buildInlineSummary(Tok t) {
    if (!_ready) return const SizedBox.shrink();
    final dayLabel =
        '${_dayFull[selectedDate!.weekday % 7]}  ${selectedDate!.day} ${_monthNames[selectedDate!.month]}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 22),
        Divider(color: t.line, height: 1),
        const SizedBox(height: 14),
        // Header row
        Row(
          children: [
            Text('ملخص الحجز',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: t.ink)),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: t.accentTint,
                borderRadius:
                    BorderRadius.circular(AppTokens.rPill),
              ),
              child: Text(selectedMode!,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: t.accentFg)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _sumRow(t, 'اليوم', dayLabel),
        _sumRow(t, 'الوقت', selectedTime!),
        _sumRow(t, 'المدة', _hoursLabel(selectedHours!), isLast: true),
      ],
    );
  }

  Widget _sumRow(Tok t, String label, String value,
      {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 7),
      child: Row(
        children: [
          Text(label,
              style: TextStyle(fontSize: 12.5, color: t.muted)),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: t.ink)),
        ],
      ),
    );
  }

  // ── Sticky footer — price on top row, full-width button below ────────────────

  Widget _buildFooter(Tok t, double? totalPrice) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
            AppTokens.screenPad, 12, AppTokens.screenPad, 14),
        decoration: BoxDecoration(
          color: t.bg2,
          border: Border(top: BorderSide(color: t.line)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Price row — slides in when duration is selected
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              child: totalPrice != null
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('الإجمالي',
                              style: TextStyle(
                                  fontSize: 13, color: t.muted)),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                totalPrice.toStringAsFixed(
                                    totalPrice.truncateToDouble() ==
                                            totalPrice
                                        ? 0
                                        : 1),
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  color: t.accentFg,
                                  height: 1,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                    bottom: 4, right: 4),
                                child: Text(' د.ب',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: t.accentFg)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            // Full-width confirm button
            Semantics(
              identifier: 'booking_btn_confirm',
              child: GestureDetector(
                onTap: (_ready && !_isSaving) ? _saveBooking : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: _ready
                        ? t.accentFg
                        : (t.isDark
                            ? Colors.white.withValues(alpha: 0.07)
                            : const Color(0xFFEEEEF5)),
                    borderRadius: BorderRadius.circular(AppTokens.rMd),
                  ),
                  child: Center(
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            _ready
                                ? 'تأكيد الحجز'
                                : 'أكمل الاختيارات أولاً',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _ready ? Colors.white : t.faint,
                            ),
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
