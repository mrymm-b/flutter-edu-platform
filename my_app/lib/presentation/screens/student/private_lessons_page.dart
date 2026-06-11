import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_tokens.dart';
import '../../../domain/models/teacher_availability.dart';
import '../../providers/private_lessons_provider.dart';
import '../../providers/subjects_provider.dart';
import '../../providers/teacher_provider.dart';
import '../../../presentation/widgets/atmosphere_background.dart';
import '../../../presentation/widgets/glass_card.dart';
import 'booking_calendar_page.dart';

class PrivateLessonsPage extends ConsumerStatefulWidget {
  const PrivateLessonsPage({super.key});

  @override
  ConsumerState<PrivateLessonsPage> createState() =>
      _PrivateLessonsPageState();
}

class _PrivateLessonsPageState extends ConsumerState<PrivateLessonsPage> {
  String? _selectedSubjectId;
  String? _selectedSubjectName;
  List<TeacherAvailability> _allAvailability = [];
  bool _loadingAll = true;

  @override
  void initState() {
    super.initState();
    _loadAllTeachers();
  }

  Future<void> _loadAllTeachers() async {
    try {
      final subjects = await ref.read(subjectsProvider.future);
      final List<TeacherAvailability> all = [];
      for (final subject in subjects) {
        final slots =
            await ref.read(teacherAvailabilityProvider(subject.id).future);
        all.addAll(slots);
      }
      if (mounted) {
        setState(() {
          _allAvailability = all;
          _loadingAll = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingAll = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Tok.of(context);
    final subjectsAsync = ref.watch(subjectsProvider);

    final availabilityAsync = _selectedSubjectId != null
        ? ref.watch(teacherAvailabilityProvider(_selectedSubjectId!))
        : null;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: AtmosphereBackground(
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────────────────
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppTokens.screenPad, 16, AppTokens.screenPad, 0),
                  child: Row(
                    children: [
                      // Back button
                      Semantics(
                        label: 'رجوع',
                        identifier: 'private_lessons_btn_back',
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: t.isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : t.bg2,
                              borderRadius:
                                  BorderRadius.circular(AppTokens.rSm),
                              border: Border.all(color: t.line),
                            ),
                            child: Icon(Icons.arrow_back_ios_new,
                                color: t.ink2, size: 17),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Title + subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'دروس خصوصية',
                              style: TextStyle(
                                fontSize: AppTokens.tsAppBar,
                                fontWeight: FontWeight.w700,
                                color: t.ink,
                              ),
                            ),
                            Text('احجز درس خاص مع المعلم',
                                style: TextStyle(
                                    fontSize: 12, color: t.muted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Subject filter chips ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppTokens.screenPad, 14, AppTokens.screenPad, 0),
                child: subjectsAsync.when(
                  loading: () => const SizedBox(
                      height: 36, child: LinearProgressIndicator()),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (subjects) => SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: subjects.length + 1,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: 7),
                      itemBuilder: (_, i) {
                        final isAll = i == 0;
                        final subject = isAll ? null : subjects[i - 1];
                        final isSelected = isAll
                            ? _selectedSubjectId == null
                            : _selectedSubjectId == subject!.id;
                        final label =
                            isAll ? 'الكل' : subject!.displayName;

                        return Semantics(
                          identifier: isAll
                              ? 'private_lessons_chip_all'
                              : 'private_lessons_chip_filter_$i',
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _selectedSubjectId =
                                  isAll ? null : subject!.id;
                              _selectedSubjectName =
                                  isAll ? null : subject!.displayName;
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 140),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 7),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? t.accentFg
                                    : (t.isDark
                                        ? Colors.white
                                            .withValues(alpha: 0.06)
                                        : t.bg2),
                                borderRadius: BorderRadius.circular(
                                    AppTokens.rPill),
                                border: Border.all(
                                  color:
                                      isSelected ? t.accentFg : t.line,
                                ),
                              ),
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : t.muted,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // ── Teachers list ────────────────────────────────────────────
              Expanded(
                child: _selectedSubjectId == null
                    ? _buildTeacherList(t, _allAvailability, _loadingAll)
                    : availabilityAsync!.when(
                        loading: () => Center(
                            child: CircularProgressIndicator(
                                color: t.accentFg)),
                        error: (_, __) => Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline,
                                  size: 48, color: t.muted),
                              const SizedBox(height: 8),
                              Text('حدث خطأ في تحميل البيانات',
                                  style: TextStyle(color: t.muted)),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () => ref.invalidate(
                                    teacherAvailabilityProvider(
                                        _selectedSubjectId!)),
                                child: const Text('إعادة المحاولة'),
                              ),
                            ],
                          ),
                        ),
                        data: (slots) =>
                            _buildTeacherList(t, slots, false),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeacherList(
      Tok t, List<TeacherAvailability> slots, bool loading) {
    if (loading) {
      return Center(
          child: CircularProgressIndicator(color: t.accentFg));
    }

    // Group slots by teacher
    final Map<String, List<TeacherAvailability>> byTeacher = {};
    for (final slot in slots) {
      byTeacher.putIfAbsent(slot.teacherId, () => []).add(slot);
    }

    if (byTeacher.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: t.accentTint,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.event_busy_outlined,
                  size: 38, color: t.accentFg),
            ),
            const SizedBox(height: 14),
            Text(
              'لا يوجد معلمون متاحون',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: t.ink),
            ),
          ],
        ),
      );
    }

    final teacherIds = byTeacher.keys.toList();
    return ListView.separated(
      padding: const EdgeInsets.all(AppTokens.screenPad),
      itemCount: teacherIds.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: AppTokens.cardGap),
      itemBuilder: (context, index) {
        final teacherId = teacherIds[index];
        final teacherSlots = byTeacher[teacherId]!;
        return _TeacherCard(
          teacherId: teacherId,
          subjectId: _selectedSubjectId ?? teacherSlots.first.subjectId,
          pricePerHour: teacherSlots.first.pricePerHour,
          availableDays:
              teacherSlots.map((s) => s.dayNameAr).toSet().join('، '),
          subjectName: _selectedSubjectName ?? '',
          index: index,
          t: t,
        );
      },
    );
  }
}

// ── Teacher Card ──────────────────────────────────────────────────────────────

class _TeacherCard extends ConsumerWidget {
  final String teacherId;
  final String subjectId;
  final double pricePerHour;
  final String availableDays;
  final String subjectName;
  final int index;
  final Tok t;

  const _TeacherCard({
    required this.teacherId,
    required this.subjectId,
    required this.pricePerHour,
    required this.availableDays,
    required this.subjectName,
    required this.index,
    required this.t,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teacherName =
        ref.watch(studentNameProvider(teacherId)).valueOrNull ?? '...';

    final priceLabel =
        '${pricePerHour.toStringAsFixed(pricePerHour.truncateToDouble() == pricePerHour ? 0 : 2)} د.ب/ساعة';

    return GlassCard(
      padding: EdgeInsets.zero,
      radius: AppTokens.rLg,
      child: Column(
        children: [
          // ── Info ──────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 15, 15, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar tile — 48×48, initial letter
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: t.accentTint,
                    borderRadius: BorderRadius.circular(AppTokens.rSm),
                  ),
                  child: Center(
                    child: Text(
                      teacherName.isNotEmpty ? teacherName[0] : '؟',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: t.accentFg,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: t.accentTint,
                              borderRadius:
                                  BorderRadius.circular(AppTokens.rPill),
                            ),
                            child: Text('معلم',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: t.accentFg,
                                    fontWeight: FontWeight.w700)),
                          ),
                          if (subjectName.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                subjectName,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: t.accentFg,
                                    fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Name — heavy
                      Text(
                        teacherName,
                        style: TextStyle(
                          fontSize: AppTokens.tsCardT,
                          fontWeight: FontWeight.w800,
                          color: t.ink,
                          height: 1.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),

                      // Meta row — price + days
                      Row(
                        children: [
                          Icon(Icons.payments_outlined,
                              size: 13, color: t.faint),
                          const SizedBox(width: 4),
                          Text(
                            priceLabel,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: t.accentFg,
                            ),
                          ),
                          if (availableDays.isNotEmpty) ...[
                            const SizedBox(width: 10),
                            Icon(Icons.calendar_today_outlined,
                                size: 13, color: t.faint),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                availableDays,
                                style: TextStyle(
                                    fontSize: 11.5, color: t.faint),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Container(height: 1, color: t.line),

          // ── Action ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Semantics(
              identifier: 'private_lessons_btn_book_$index',
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookingCalendarPage(
                      subject: subjectName,
                      teacherName: teacherName,
                      teacherId: teacherId,
                      subjectId: subjectId,
                      pricePerHour: pricePerHour,
                    ),
                  ),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: t.accentFg,
                    borderRadius: BorderRadius.circular(AppTokens.rSm),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_month_rounded,
                          size: 16, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        'احجز الآن',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
