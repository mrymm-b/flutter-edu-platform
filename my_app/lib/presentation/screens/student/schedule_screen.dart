import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/app_tokens.dart';
import '../../../core/utils/toast.dart';
import '../../../domain/models/schedule_item.dart';
import '../../providers/schedule_provider.dart';
import '../../providers/messages_provider.dart';
import '../../../presentation/widgets/atmosphere_background.dart';
import '../../../presentation/widgets/glass_card.dart';
import 'home_page.dart';
import 'my_courses.dart';
import 'chat.dart';
import 'profile.dart';

// Pixels per minute — controls the visual height of each period slot
const double _kMinPx = 1.4;

// View mode toggle
enum _ViewMode { periods, timeline }
const _kViewKey = 'schedule_view_v1';

// School days in natural Arabic order (Sun → Thu) for pill tabs
const _kDays = [7, 1, 2, 3, 4]; // Sun=7, Mon=1 … Thu=4

const _kFullDay = <int, String>{
  7: 'الأحد', 1: 'الاثنين', 2: 'الثلاثاء',
  3: 'الأربعاء', 4: 'الخميس',
};
const _kShortDay = <int, String>{
  7: 'أحد', 1: 'اثن', 2: 'ثلا', 3: 'أرب', 4: 'خمي',
};


int _toMin(String hhmm) {
  final p = hhmm.split(':');
  if (p.length != 2) return 7 * 60;
  return (int.tryParse(p[0]) ?? 7) * 60 + (int.tryParse(p[1]) ?? 0);
}

// Arabic digit conversion: "07:15" → "٧:١٥ ص"
String _arNum(int n) => n.toString()
    .split('')
    .map((c) => '٠١٢٣٤٥٦٧٨٩'[int.parse(c)])
    .join();

String _arabicTime(String hhmm) {
  if (hhmm.isEmpty) return '';
  final p = hhmm.split(':');
  final h = int.tryParse(p[0]) ?? 0;
  final m = int.tryParse(p.length > 1 ? p[1] : '0') ?? 0;
  final h12 = h == 0 ? 12 : h > 12 ? h - 12 : h;
  return '${_arNum(h12)}:${_arNum(m).padLeft(2, '٠')} ${h < 12 ? 'ص' : 'م'}';
}

// ── Screen ─────────────────────────────────────────────────────────────────────
class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  // Selected day pill — default to today if a school day, else Sunday
  late int _selectedDay;

  // View mode — الحصص is default
  _ViewMode _viewMode = _ViewMode.periods;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now().weekday;
    _selectedDay = _kDays.contains(today) ? today : 7;
    // Restore saved view preference
    SharedPreferences.getInstance().then((prefs) {
      final saved = prefs.getString(_kViewKey);
      if (saved == 'timeline' && mounted) {
        setState(() => _viewMode = _ViewMode.timeline);
      }
    });
    _timer = Timer.periodic(
      const Duration(minutes: 1),
      (_) {
        if (mounted) setState(() => _now = DateTime.now());
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _showAddSheet(Tok t) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.40),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.of(ctx).size.height * 0.10,
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: _MultiAddSheet(
          t: t,
          defaultDay: _selectedDay,
          onSave: (items) {
            ref.read(scheduleProvider.notifier).addMany(items);
            Navigator.pop(ctx);
            final subjects = items.map((e) => e.subject).toSet().length;
            showAppToast(
              context,
              message: subjects == 1
                  ? 'تمت إضافة ${items.length} حصة للجدول'
                  : 'تمت إضافة $subjects مواد (${items.length} حصة) للجدول',
            );
          },
        ),
      ),
    );
  }

  void _confirmDelete(ScheduleItem item, Tok t) {
    showDialog<void>(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: t.card,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Text('حذف الحصة',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: t.ink)),
          content: Text('تريد تحذف "${item.subject}"؟',
              style: TextStyle(color: t.muted)),
          actions: [
            Semantics(
              identifier: 'schedule_dialog_btn_cancel_delete',
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('إلغاء',
                    style: TextStyle(color: t.muted)),
              ),
            ),
            Semantics(
              identifier: 'schedule_dialog_btn_confirm_delete',
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  ref.read(scheduleProvider.notifier).remove(item.id);
                  showAppToast(context, message: 'تم حذف الحصة');
                },
                child: const Text('حذف',
                    style: TextStyle(color: Color(0xFFDC2626))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── View mode ────────────────────────────────────────────────────────────────

  void _setView(_ViewMode mode) {
    if (_viewMode == mode) return;
    setState(() => _viewMode = mode);
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setString(
          _kViewKey, mode == _ViewMode.timeline ? 'timeline' : 'periods'),
    );
  }

  Widget _buildViewToggle(Tok t) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: t.isDark
            ? Colors.white.withValues(alpha: 0.06)
            : t.bg2,
        borderRadius: BorderRadius.circular(AppTokens.rMd),
        border: Border.all(color: t.line),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(child: _segTab('الحصص', _ViewMode.periods,
              Icons.format_list_bulleted_rounded,
              Icons.format_list_bulleted_rounded, t)),
          Expanded(child: _segTab('الوقت', _ViewMode.timeline,
              Icons.access_time_rounded, Icons.access_time_outlined, t)),
        ],
      ),
    );
  }

  Widget _segTab(String label, _ViewMode mode,
      IconData activeIcon, IconData inactiveIcon, Tok t) {
    final isActive = _viewMode == mode;
    return Semantics(
      identifier: mode == _ViewMode.periods
          ? 'schedule_btn_view_periods'
          : 'schedule_btn_view_timeline',
      child: GestureDetector(
        onTap: () => _setView(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          decoration: BoxDecoration(
            color: isActive
                ? (t.isDark ? t.accentFg.withValues(alpha: 0.20) : t.accentFg)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTokens.rMd - 2),
            boxShadow: isActive && !t.isDark
                ? [BoxShadow(
                    color: t.accentFg.withValues(alpha: 0.18),
                    blurRadius: 6, offset: const Offset(0, 2))]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isActive ? activeIcon : inactiveIcon,
                size: 15,
                color: isActive
                    ? (t.isDark ? t.accentFg : Colors.white)
                    : t.muted,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive
                      ? (t.isDark ? t.accentFg : Colors.white)
                      : t.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Period-row builder ───────────────────────────────────────────────────────

  bool _isNowInPeriod(_Period p) {
    final nowMin = _now.hour * 60 + _now.minute;
    return nowMin >= _toMin(p.start) && nowMin < _toMin(p.end);
  }

  // Range-based match: item belongs to the period whose window contains its start time.
  // Handles both new items (exact period times) and legacy items (custom times).
  ScheduleItem? _itemForPeriod(List<ScheduleItem> dayItems, _Period period) {
    final pStart = _toMin(period.start);
    final pEnd = _toMin(period.end);
    return dayItems
        .where((s) {
          final sMin = _toMin(s.time);
          return sMin >= pStart && sMin < pEnd;
        })
        .firstOrNull;
  }

  Widget _buildPeriodRow(
      _Period period, List<ScheduleItem> dayItems, bool isToday, Tok t) {
    final durMin = _toMin(period.end) - _toMin(period.start);
    final rowH = (durMin * _kMinPx).clamp(32.0, double.infinity);
    final isNow = isToday && _isNowInPeriod(period);

    ScheduleItem? item;
    if (!period.isBreak) {
      item = _itemForPeriod(dayItems, period);
    }

    return SizedBox(
      height: rowH,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Start-time label ─────────────────────────────────────
          SizedBox(
            width: 52,
            child: Padding(
              padding: const EdgeInsets.only(top: 4, right: 4),
              child: Text(
                _arabicTime(period.start),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: isNow ? FontWeight.w700 : FontWeight.w500,
                  color: isNow ? t.accentFg : t.ink2,
                ),
              ),
            ),
          ),
          // ── Timeline line ─────────────────────────────────────────
          Container(
            width: 2,
            decoration: BoxDecoration(
              color: isNow ? t.accentFg : t.line,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(width: 8),
          // ── Period block ──────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: period.isBreak
                  ? _buildBreakBlock(period, isNow, t)
                  : _buildSubjectBlock(period, item, isNow, rowH - 4, t),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakBlock(_Period period, bool isNow, Tok t) {
    return Container(
      decoration: BoxDecoration(
        color: t.isDark
            ? const Color(0xFF451A03).withValues(alpha: 0.35)
            : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isNow ? const Color(0xFFF59E0B) : const Color(0xFFFDE68A),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.coffee_rounded, size: 11, color: Color(0xFFD97706)),
          const SizedBox(width: 6),
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              period.label,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFFD97706),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Spacer(),
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              '${_arabicTime(period.start)} – ${_arabicTime(period.end)}',
              style: TextStyle(
                fontSize: 9,
                color: const Color(0xFFD97706).withValues(alpha: 0.65),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectBlock(
      _Period period, ScheduleItem? item, bool isNow, double blockH, Tok t) {
    if (item == null) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isNow
                ? t.accentLine
                : (t.isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFE5E7EB)),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Text(
            period.label,
            style: TextStyle(
              fontSize: 10.5,
              color: t.faint,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      );
    }

    final bg = t.isDark ? t.accentFg.withValues(alpha: 0.12) : t.accentTint;
    final fg = t.isDark ? t.ink : t.accentFg;
    final barColor = t.isDark ? t.accentFg.withValues(alpha: 0.75) : t.accentFg;

    // Use ClipRRect + Row so the accent bar never triggers the
    // non-uniform Border + borderRadius Flutter assertion.
    return GestureDetector(
      onLongPress: () => _confirmDelete(item, t),
      onTap: () => showAppToast(
        context,
        message: '${_arabicTime(period.start)} – ${_arabicTime(period.end)}',
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left accent bar
            Container(
              width: isNow ? 4.5 : 3.0,
              color: barColor,
            ),
            // Card body
            Expanded(
              child: Container(
                color: isNow
                    ? bg.withValues(alpha: t.isDark ? 0.22 : 1.0)
                    : bg,
                padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.subject,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: t.isDark ? t.ink : fg,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (blockH > 44) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              period.label,
                              style: TextStyle(
                                fontSize: 10,
                                color: t.isDark
                                    ? t.muted
                                    : fg.withValues(alpha: 0.65),
                              ),
                            ),
                            if (isNow) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: fg.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'الآن',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: fg,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── View: timeline (الوقت) ───────────────────────────────────────────────────

  Widget _buildTimelineView(
      List<ScheduleItem> dayItems, bool isToday, Tok t) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppTokens.screenPad, 4, AppTokens.screenPad, 24),
      child: Column(
        children: [
          for (final period in _kSchoolPeriods)
            _buildPeriodRow(period, dayItems, isToday, t),
          // End-of-school-day marker
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Row(
              children: [
                SizedBox(
                  width: 52,
                  child: Text(
                    _arabicTime('13:45'),
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                        color: t.ink2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                    child:
                        Divider(color: t.line, height: 1, thickness: 1)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── View: period list (الحصص) ────────────────────────────────────────────────

  Widget _buildPeriodsListView(
      List<ScheduleItem> dayItems, bool isToday, Tok t) {
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
          AppTokens.screenPad, 8, AppTokens.screenPad, 24),
      itemCount: _kSchoolPeriods.length,
      separatorBuilder: (_, __) => const SizedBox(height: 5),
      itemBuilder: (ctx, i) {
        final period = _kSchoolPeriods[i];
        final isNow = isToday && _isNowInPeriod(period);
        if (period.isBreak) {
          return _buildPeriodListBreak(period, isNow, t);
        }
        final item = _itemForPeriod(dayItems, period);
        return _buildPeriodListCard(period, item, isNow, t);
      },
    );
  }

  Widget _buildPeriodListCard(
      _Period period, ScheduleItem? item, bool isNow, Tok t) {
    if (item != null) {
      return GestureDetector(
        onLongPress: () => _confirmDelete(item, t),
        child: Container(
          decoration: BoxDecoration(
            color: t.isDark
                ? Colors.white.withValues(alpha: isNow ? 0.08 : 0.05)
                : (isNow ? t.accentTint : t.bg2),
            borderRadius: BorderRadius.circular(AppTokens.rMd),
            border: Border.all(
              color: isNow ? t.accentLine : t.line,
              width: isNow ? 1.5 : 0.75,
            ),
            boxShadow: isNow
                ? [
                    BoxShadow(
                      color: t.accentFg.withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    period.name,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: t.muted,
                    ),
                  ),
                  const Spacer(),
                  if (isNow)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: t.accentFg.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'الآن',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: t.accentFg,
                        ),
                      ),
                    )
                  else
                    Text(
                      '${_arabicTime(period.start)} – ${_arabicTime(period.end)}',
                      style: TextStyle(fontSize: 10, color: t.faint),
                    ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                item.subject,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: t.ink,
                  height: 1.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    }

    // Empty — small card with light border so it's clearly bounded
    return Container(
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTokens.rMd),
        border: Border.all(
          color: isNow
              ? t.accentLine
              : (t.isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : t.line),
          width: 0.75,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            Text(
              period.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isNow ? t.accentFg : t.muted,
              ),
            ),
            const Spacer(),
            Text(
              'لا توجد مادة',
              style: TextStyle(
                fontSize: 11,
                color: t.faint,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Break — minimal divider; visually secondary to subject cards
  Widget _buildPeriodListBreak(_Period period, bool isNow, Tok t) {
    final dividerColor = t.isDark
        ? Colors.white.withValues(alpha: 0.08)
        : t.line;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
              child: Divider(
                  color: dividerColor, height: 1, thickness: 0.75)),
          const SizedBox(width: 8),
          Icon(Icons.coffee_rounded, size: 10, color: t.faint),
          const SizedBox(width: 4),
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              '${period.label} · ${_arabicTime(period.start)} – ${_arabicTime(period.end)}',
              style: TextStyle(fontSize: 10, color: t.faint),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
              child: Divider(
                  color: dividerColor, height: 1, thickness: 0.75)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Tok.of(context);
    final all = ref.watch(scheduleProvider);
    final today = _now.weekday;
    final isToday = _selectedDay == today;

    final dayItems = all
        .where((s) => s.dayOfWeek == _selectedDay)
        .toList()
      ..sort((a, b) => _toMin(a.time).compareTo(_toMin(b.time)));

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        bottomNavigationBar: _BottomNav(active: 3, context: context),
        body: AtmosphereBackground(
          child: Column(
            children: [

              // ── Header ──────────────────────────────────────────────────────
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppTokens.screenPad, 16, AppTokens.screenPad, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'جدولي الدراسي',
                              style: TextStyle(
                                fontSize: AppTokens.tsH1,
                                fontWeight: FontWeight.w700,
                                color: t.ink,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          Semantics(
                            identifier: 'schedule_btn_add',
                            label: 'إضافة حصة',
                            child: GestureDetector(
                              onTap: () => _showAddSheet(t),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: t.accentFg,
                                  borderRadius:
                                      BorderRadius.circular(AppTokens.rSm),
                                ),
                                child: const Icon(
                                  Icons.add_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildViewToggle(t),
                    ],
                  ),
                ),
              ),

              // ── Day-pill selector ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppTokens.screenPad, 14, AppTokens.screenPad, 0),
                child: Row(
                  children: _kDays.map((d) {
                    final isSelected = _selectedDay == d;
                    final isTodayDay = d == today;
                    return Expanded(
                      child: Semantics(
                        identifier: 'schedule_chip_day_$d',
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedDay = d),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? t.accentFg
                                  : (isTodayDay
                                      ? t.accentTint
                                      : (t.isDark
                                          ? Colors.white.withValues(alpha: 0.05)
                                          : t.bg2)),
                              borderRadius:
                                  BorderRadius.circular(AppTokens.rSm),
                              border: Border.all(
                                color: isSelected
                                    ? t.accentFg
                                    : (isTodayDay ? t.accentLine : t.line),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _kShortDay[d]!,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? Colors.white
                                        : (isTodayDay ? t.accentFg : t.muted),
                                  ),
                                ),
                                if (isTodayDay) ...[
                                  const SizedBox(height: 3),
                                  Container(
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.white.withValues(alpha: 0.6)
                                          : t.accentFg,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 4),

              // Day label row
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.screenPad, vertical: 10),
                child: Row(
                  children: [
                    Text(
                      _kFullDay[_selectedDay]!,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: t.ink),
                    ),
                    if (isToday) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: t.accentTint,
                          borderRadius: BorderRadius.circular(AppTokens.rPill),
                        ),
                        child: Text('اليوم',
                            style: TextStyle(
                                fontSize: 10,
                                color: t.accentFg,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                    const Spacer(),
                    if (dayItems.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.touch_app_rounded,
                              size: 12, color: t.muted),
                          const SizedBox(width: 4),
                          Text(
                            'اضغط مطولاً على المادة لحذفها',
                            style: TextStyle(fontSize: 11, color: t.muted),
                          ),
                        ],
                      )
                    else
                      Text(
                        '${dayItems.length} ${_label(dayItems.length)}',
                        style: TextStyle(fontSize: 12, color: t.faint),
                      ),
                  ],
                ),
              ),

              // ── Timetable (mode-aware) ───────────────────────────────────
              Expanded(
                child: all.isEmpty
                    ? _emptyDayState(t, true)
                    : (_viewMode == _ViewMode.periods
                        ? _buildPeriodsListView(dayItems, isToday, t)
                        : _buildTimelineView(dayItems, isToday, t)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _label(int n) {
    if (n == 0) return 'حصص';
    if (n == 1) return 'حصة';
    if (n == 2) return 'حصتان';
    return 'حصص';
  }

  Widget _emptyDayState(Tok t, bool hasNoScheduleAtAll) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: t.accentTint,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.calendar_month_outlined,
                  size: 34, color: t.accentFg),
            ),
            const SizedBox(height: 18),
            Text(
              hasNoScheduleAtAll ? 'جدولك الدراسي فارغ' : 'يوم ${_kFullDay[_selectedDay]!} فارغ',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: t.ink),
            ),
            const SizedBox(height: 6),
            Text(
              hasNoScheduleAtAll
                  ? 'أضف موادك الدراسية وأوقاتها'
                  : 'لا توجد حصص في هذا اليوم',
              style: TextStyle(fontSize: 13, color: t.muted),
              textAlign: TextAlign.center,
            ),
            if (hasNoScheduleAtAll) ...[
              const SizedBox(height: 22),
              Semantics(
                identifier: 'schedule_btn_add_first',
                child: GestureDetector(
                  onTap: () => _showAddSheet(t),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: t.accentFg,
                      borderRadius: BorderRadius.circular(AppTokens.rMd),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_rounded,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 6),
                        const Text('إضافة أول حصة',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            )),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Subject entry data ─────────────────────────────────────────────────────────
class _SubjectEntry {
  final TextEditingController ctrl = TextEditingController();
  Set<int> selectedDays  = <int>{};
  int?     selectedPeriod;            // index into _kSchoolPeriods
  bool     hasSubjectError = false;
  bool     hasDayError     = false;
  bool     hasPeriodError  = false;

  void dispose() => ctrl.dispose();
}

const _kChipDays = [7, 1, 2, 3, 4]; // Sun → Thu

// ── Bahrain school period definitions ──────────────────────────────────────────
class _Period {
  final String name;    // "الحصة الأولى"
  final String label;   // short chip label "الأولى"
  final String start;   // "07:15"
  final String end;     // "08:05"
  final bool isBreak;
  const _Period(this.name, this.label, this.start, this.end,
      {this.isBreak = false});
  String get timeRange => '${_arabicTime(start)} – ${_arabicTime(end)}';
}

const _kSchoolPeriods = [
  _Period('الطابور الصباحي', 'طابور',   '07:00', '07:15', isBreak: true),
  _Period('الحصة الأولى',   'الأولى',   '07:15', '08:05'),
  _Period('الحصة الثانية',  'الثانية',  '08:05', '08:55'),
  _Period('الفسحة الأولى',  'فسحة ١',   '08:55', '09:30', isBreak: true),
  _Period('الحصة الثالثة',  'الثالثة',  '09:30', '10:20'),
  _Period('الحصة الرابعة',  'الرابعة',  '10:20', '11:10'),
  _Period('الحصة الخامسة',  'الخامسة',  '11:10', '11:55'),
  _Period('الفسحة الثانية', 'فسحة ٢',   '11:55', '12:15', isBreak: true),
  _Period('الحصة السادسة',  'السادسة',  '12:15', '13:00'),
  _Period('الحصة السابعة',  'السابعة',  '13:00', '13:45'),
];


// ── Multi-subject add sheet ────────────────────────────────────────────────────
class _MultiAddSheet extends ConsumerStatefulWidget {
  final Tok t;
  final int defaultDay;
  final void Function(List<ScheduleItem>) onSave;

  const _MultiAddSheet({
    required this.t,
    required this.defaultDay,
    required this.onSave,
  });

  @override
  ConsumerState<_MultiAddSheet> createState() => _MultiAddSheetState();
}

class _MultiAddSheetState extends ConsumerState<_MultiAddSheet> {
  late final List<_SubjectEntry> _entries;
  final _scrollCtrl = ScrollController();
  String? _overlapError;
  int?    _overlapErrorEntry;

  @override
  void initState() {
    super.initState();
    final entry = _SubjectEntry();
    entry.selectedDays = {widget.defaultDay};
    _entries = [entry];
  }

  @override
  void dispose() {
    for (final e in _entries) { e.dispose(); }
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _addEntry() {
    setState(() { _entries.add(_SubjectEntry()); _overlapError = null; });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _removeEntry(int i) {
    _entries[i].dispose();
    setState(() { _entries.removeAt(i); _overlapError = null; });
  }

  // Returns minutes for a "HH:MM" string
  static int _min(String hhmm) {
    final p = hhmm.split(':');
    return (int.tryParse(p[0]) ?? 0) * 60 + (int.tryParse(p.length > 1 ? p[1] : '0') ?? 0);
  }

  static bool _overlaps(int s1, int e1, int s2, int e2) => s1 < e2 && s2 < e1;

  void _save() {
    // ── 1. Inline subject-name validation ─────────────────────────────────────
    bool hasEmpty = false;
    for (final e in _entries) {
      if (e.ctrl.text.trim().isEmpty) {
        e.hasSubjectError = true;
        hasEmpty = true;
      }
    }
    if (hasEmpty) {
      setState(() {});
      return;
    }

    // ── 2. Day selection check ────────────────────────────────────────────────
    bool hasDayErr = false;
    for (final e in _entries) {
      if (e.selectedDays.isEmpty) {
        e.hasDayError = true;
        hasDayErr = true;
      }
    }
    if (hasDayErr) { setState(() {}); return; }

    // ── 3. Period selection check ─────────────────────────────────────────────
    bool hasPeriodErr = false;
    for (final e in _entries) {
      if (e.selectedPeriod == null) {
        e.hasPeriodError = true;
        hasPeriodErr = true;
      }
    }
    if (hasPeriodErr) { setState(() {}); return; }

    // ── 4. Overlap check against existing + within this batch ─────────────────
    // Read live provider state here — not a snapshot captured at sheet-open
    // time — so deleted items are never considered in conflict detection.
    final existingItems = ref.read(scheduleProvider);
    final ts = DateTime.now().millisecondsSinceEpoch;
    final items = <ScheduleItem>[];

    for (int i = 0; i < _entries.length; i++) {
      final e = _entries[i];
      final subject = e.ctrl.text.trim();
      final period = _kSchoolPeriods[e.selectedPeriod!];
      final sm = _min(period.start);
      final em = _min(period.end);

      for (final day in e.selectedDays) {
        for (final ex in existingItems) {
          if (ex.dayOfWeek != day) continue;
          final xs = _min(ex.time);
          final xe = ex.endTime.isEmpty ? xs + 60 : _min(ex.endTime);
          if (_overlaps(sm, em, xs, xe)) {
            setState(() {
              _overlapError = 'مادة "$subject" تتعارض مع مادة "${ex.subject}"';
              _overlapErrorEntry = i;
            });
            return;
          }
        }
        for (final prev in items) {
          if (prev.dayOfWeek != day) continue;
          final ps = _min(prev.time);
          final pe = prev.endTime.isEmpty ? ps + 60 : _min(prev.endTime);
          if (_overlaps(sm, em, ps, pe)) {
            setState(() {
              _overlapError = 'مادة "$subject" تتعارض مع مادة "${prev.subject}"';
              _overlapErrorEntry = i;
            });
            return;
          }
        }

        items.add(ScheduleItem(
          id: '${ts}_${i}_$day',
          dayOfWeek: day,
          time: period.start,
          endTime: period.end,
          subject: subject,
        ));
      }
    }
    widget.onSave(items);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    // Only count slots where a period is also selected
    final totalSlots = _entries.fold<int>(
        0, (s, e) => s + (e.selectedPeriod != null ? e.selectedDays.length : 0));

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: BoxDecoration(
          color: t.card,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
          border: t.isDark ? Border.all(color: t.line) : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            // ── Sheet header ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36, height: 4,
                      decoration: BoxDecoration(
                        color: t.line2,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text('إضافة حصص',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: t.ink)),
                      ),
                      if (_entries.length > 1)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: t.accentTint,
                            borderRadius: BorderRadius.circular(AppTokens.rPill),
                          ),
                          child: Text('${_entries.length} مواد',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: t.accentFg)),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            Container(height: 1, color: t.line),

            // ── Entries ──────────────────────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                controller: _scrollCtrl,
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 0; i < _entries.length; i++) ...[
                      if (i > 0) const SizedBox(height: 8),
                      _EntryCard(
                        index: i,
                        entry: _entries[i],
                        t: t,
                        canDelete: _entries.length > 1,
                        overlapError: (_overlapErrorEntry == i) ? _overlapError : null,
                        onDelete: () => _removeEntry(i),
                        onRebuild: () => setState(() {
                          _overlapError = null;
                          _overlapErrorEntry = null;
                        }),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ── Footer ──────────────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: t.card,
                border: Border(top: BorderSide(color: t.line)),
              ),
              padding: EdgeInsets.fromLTRB(
                  16, 10, 16, 12 + MediaQuery.of(context).padding.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Sticky conflict summary — always visible without scrolling
                  AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    child: _overlapError != null
                        ? Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 9),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius:
                                  BorderRadius.circular(AppTokens.rMd),
                              border:
                                  Border.all(color: const Color(0xFFFCA5A5)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded,
                                    color: Color(0xFFDC2626), size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _overlapError!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF991B1B),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),

                  Row(
                    children: [
                      Semantics(
                        identifier: 'schedule_btn_add_another_subject',
                        child: TextButton.icon(
                          onPressed: _addEntry,
                          icon: Icon(Icons.add_rounded, size: 15, color: t.muted),
                          label: Text('مادة أخرى',
                              style: TextStyle(
                                  color: t.muted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500)),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Semantics(
                          identifier: 'schedule_btn_save_all',
                          child: PrimaryButton(
                            label: totalSlots == 0
                                ? 'حفظ الكل'
                                : 'حفظ الكل · $totalSlots حصة',
                            semanticsId: 'schedule_save_inner',
                            onPressed: _overlapError != null ? null : _save,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Entry card ─────────────────────────────────────────────────────────────────
class _EntryCard extends StatelessWidget {
  final int index;
  final _SubjectEntry entry;
  final Tok t;
  final bool canDelete;
  final String? overlapError;
  final VoidCallback onDelete;
  final VoidCallback onRebuild;

  const _EntryCard({
    required this.index,
    required this.entry,
    required this.t,
    required this.canDelete,
    this.overlapError,
    required this.onDelete,
    required this.onRebuild,
  });

  @override
  Widget build(BuildContext context) {
    final hasConflict = overlapError != null;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: hasConflict
            ? (t.isDark
                ? const Color(0xFF450A0A).withValues(alpha: 0.45)
                : const Color(0xFFFFF5F5))
            : (t.isDark ? Colors.white.withValues(alpha: 0.04) : t.bg2),
        borderRadius: BorderRadius.circular(AppTokens.rMd),
        border: Border.all(
          color: hasConflict ? const Color(0xFFEF4444) : t.line,
          width: hasConflict ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Subject name row ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 0),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                    color: hasConflict
                        ? const Color(0xFFEF4444)
                        : t.accentTint,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: hasConflict
                        ? const Icon(Icons.priority_high_rounded,
                            size: 13, color: Colors.white)
                        : Text('${index + 1}',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: t.accentFg)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Semantics(
                    identifier: 'schedule_field_subject_$index',
                    child: TextField(
                      controller: entry.ctrl,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600, color: t.ink),
                      onChanged: (_) => onRebuild(),
                      decoration: InputDecoration(
                        hintText: 'اسم المادة  (رياضيات، فيزياء...)',
                        hintStyle: TextStyle(
                            color: t.faint, fontSize: 13, fontWeight: FontWeight.normal),
                        errorText: (entry.hasSubjectError &&
                                entry.ctrl.text.trim().isEmpty)
                            ? 'أدخل اسم المادة'
                            : null,
                        errorStyle:
                            const TextStyle(fontSize: 11, color: Color(0xFFDC2626)),
                        border: InputBorder.none,
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: (entry.hasSubjectError &&
                                    entry.ctrl.text.trim().isEmpty)
                                ? const Color(0xFFDC2626)
                                : t.line2,
                          ),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: (entry.hasSubjectError &&
                                    entry.ctrl.text.trim().isEmpty)
                                ? const Color(0xFFDC2626)
                                : t.accentLine,
                            width: 1.5,
                          ),
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.only(bottom: 6),
                      ),
                    ),
                  ),
                ),
                if (canDelete)
                  GestureDetector(
                    onTap: onDelete,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4, right: 2),
                      child: Container(
                        width: 26, height: 26,
                        decoration: BoxDecoration(
                          color: t.isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : t.bg2,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: t.line),
                        ),
                        child: Icon(Icons.close_rounded, color: t.muted, size: 14),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
            child: Divider(height: 1, color: t.line),
          ),

          // ── Day chips ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              children: [
                Text('اختر الأيام',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: (entry.hasDayError && entry.selectedDays.isEmpty)
                            ? const Color(0xFFDC2626)
                            : t.ink2)),
                if (entry.hasDayError && entry.selectedDays.isEmpty) ...[
                  const SizedBox(width: 6),
                  const Text('— اختر يومًا على الأقل',
                      style: TextStyle(fontSize: 11, color: Color(0xFFDC2626))),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
            child: Row(
              children: _kChipDays.map((d) {
                final sel = entry.selectedDays.contains(d);
                final showDayError = entry.hasDayError && entry.selectedDays.isEmpty;
                return Expanded(
                  child: Semantics(
                    identifier: 'schedule_chip_day_$d',
                    child: GestureDetector(
                      onTap: () {
                        if (sel) {
                          entry.selectedDays.remove(d);
                        } else {
                          entry.selectedDays.add(d);
                          entry.hasDayError = false;
                        }
                        onRebuild();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 140),
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        decoration: BoxDecoration(
                          color: sel
                              ? t.accentFg
                              : showDayError
                                  ? const Color(0xFFFEE2E2)
                                  : (t.isDark
                                      ? Colors.white.withValues(alpha: 0.04)
                                      : t.card),
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                            color: sel
                                ? t.accentFg
                                : showDayError
                                    ? const Color(0xFFFCA5A5)
                                    : t.line,
                          ),
                        ),
                        child: Center(
                          child: Text(_kShortDay[d]!,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: sel
                                    ? Colors.white
                                    : showDayError
                                        ? const Color(0xFFDC2626)
                                        : t.muted,
                              )),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Divider(height: 1, color: t.line),
          ),

          // ── Period grid ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
            child: Row(
              children: [
                Text('اختر الحصة',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: entry.hasPeriodError ? const Color(0xFFDC2626) : t.ink2)),
                if (entry.hasPeriodError) ...[
                  const SizedBox(width: 6),
                  const Text('— اختر حصة دراسية',
                      style: TextStyle(fontSize: 11, color: Color(0xFFDC2626))),
                ],
              ],
            ),
          ),
          _PeriodGrid(
            selected: entry.selectedPeriod,
            hasError: entry.hasPeriodError,
            t: t,
            onSelect: (idx) {
              entry.selectedPeriod = idx;
              entry.hasPeriodError = false;
              onRebuild();
            },
          ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

// ── Period selection grid (3 × 3) ──────────────────────────────────────────────
class _PeriodGrid extends StatelessWidget {
  final int? selected;
  final bool hasError;
  final Tok t;
  final void Function(int) onSelect;

  const _PeriodGrid({
    required this.selected,
    required this.hasError,
    required this.t,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
          childAspectRatio: 2.1,
        ),
        itemCount: _kSchoolPeriods.length,
        itemBuilder: (_, idx) {
          final p   = _kSchoolPeriods[idx];
          final sel = selected == idx;

          if (p.isBreak) {
            return Container(
              decoration: BoxDecoration(
                color: t.isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(AppTokens.rSm),
                border: Border.all(
                    color: t.isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFFFED7AA)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(p.label,
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFF97316))),
                  const SizedBox(height: 2),
                  Text(p.timeRange,
                      style: const TextStyle(
                          fontSize: 9, color: Color(0xFFEA580C))),
                ],
              ),
            );
          }

          return GestureDetector(
            onTap: () => onSelect(idx),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 130),
              decoration: BoxDecoration(
                color: sel
                    ? t.accentFg
                    : (t.isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : t.card),
                borderRadius: BorderRadius.circular(AppTokens.rSm),
                border: Border.all(
                  color: sel
                      ? t.accentFg
                      : (hasError && selected == null
                          ? const Color(0xFFFCA5A5)
                          : t.line),
                  width: sel ? 1.5 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(p.label,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: sel ? Colors.white : t.ink)),
                  const SizedBox(height: 2),
                  Text(p.timeRange,
                      style: TextStyle(
                          fontSize: 9.5,
                          color: sel
                              ? Colors.white.withValues(alpha: 0.82)
                              : t.muted)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Bottom Nav ─────────────────────────────────────────────────────────────────
class _BottomNav extends ConsumerWidget {
  final int active;
  final BuildContext context;
  const _BottomNav({required this.active, required this.context});

  @override
  Widget build(BuildContext _, WidgetRef ref) {
    final t = Tok.of(context);
    final unread = ref
            .watch(myConversationsProvider)
            .valueOrNull
            ?.fold<int>(0, (sum, c) => sum + c.unreadCountStudent) ??
        0;

    return ThemedBottomNavShell(
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Semantics(
                  identifier: 'nav_home',
                  child: _item(Icons.home_rounded, 'الرئيسية', 0, t, () {
                    if (active != 0) {
                      Navigator.pushReplacement(context,
                          MaterialPageRoute(builder: (_) => const HomePage()));
                    }
                  })),
              Semantics(
                  identifier: 'nav_messages',
                  child: _chatItem(unread, t)),
              Semantics(
                  identifier: 'nav_my_courses',
                  child: _item(Icons.book_rounded, 'دوراتي', 2, t, () {
                    if (active != 2) {
                      Navigator.pushReplacement(context,
                          MaterialPageRoute(builder: (_) => const MyCourses()));
                    }
                  }, isCenter: true)),
              Semantics(
                  identifier: 'nav_schedule',
                  child: _item(Icons.calendar_month_rounded, 'جدولي', 3, t, () {})),
              Semantics(
                  identifier: 'nav_profile',
                  child: _item(Icons.person_rounded, 'حسابي', 4, t, () {
                    if (active != 4) {
                      Navigator.pushReplacement(context,
                          MaterialPageRoute(builder: (_) => const Profile()));
                    }
                  })),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chatItem(int unread, Tok t) {
    final isActive = active == 1;
    return GestureDetector(
      onTap: () {
        if (active != 1) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const Chat()));
        }
      },
      child: _navContent(
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(Icons.chat_bubble_rounded,
                color: isActive ? t.accentFg : t.faint, size: 21),
            if (unread > 0)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(
                      color: Color(0xFFEF4444), shape: BoxShape.circle),
                ),
              ),
          ],
        ),
        label: 'الرسائل',
        isActive: isActive,
        t: t,
      ),
    );
  }

  Widget _item(
    IconData icon,
    String label,
    int index,
    Tok t,
    VoidCallback onTap, {
    bool isCenter = false,
  }) {
    final isActive = active == index;
    final iconSize = isCenter ? 24.0 : 21.0;
    return GestureDetector(
      onTap: onTap,
      child: _navContent(
        icon: Icon(icon, color: isActive ? t.accentFg : t.faint, size: iconSize),
        label: label,
        isActive: isActive,
        t: t,
      ),
    );
  }

  Widget _navContent({
    required Widget icon,
    required String label,
    required bool isActive,
    required Tok t,
  }) =>
      AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? t.accentFg.withValues(alpha: 0.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTokens.rSm),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                  fontSize: 10,
                  color: isActive ? t.accentFg : t.faint,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                )),
          ],
        ),
      );
}

